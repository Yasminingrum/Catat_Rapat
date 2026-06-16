import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/meeting_model.dart';
import '../models/user_model.dart';

const _audioContentTypes = {
  'wav': 'audio/wav',
  'mp3': 'audio/mpeg',
  'm4a': 'audio/mp4',
  'ogg': 'audio/ogg',
};

/// Wrapper untuk Supabase — Auth, Database, Storage.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get _client => Supabase.instance.client;

  // ─── Auth ──────────────────────────────────────────────────

  Future<AuthResponse> signInWithEmail(String email, String password) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<AuthResponse> signUpWithEmail(String email, String password,
      {required String name}) async {
    final res = await _client.auth.signUp(
      email: email, password: password,
      data: {'name': name},
    );
    return res;
  }

  Future<bool> signInWithGoogle() => _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.catatrapat://login-callback/',
      );

  /// Memverifikasi kode OTP 6-digit yang dikirim ke email saat registrasi.
  Future<AuthResponse> verifySignupOtp(String email, String token) =>
      _client.auth.verifyOTP(type: OtpType.signup, email: email, token: token);

  /// Mengirim ulang kode OTP verifikasi signup ke email.
  Future<void> resendSignupOtp(String email) =>
      _client.auth.resend(type: OtpType.signup, email: email);

  /// Mengirim kode OTP reset password (recovery) ke email.
  Future<void> resetPasswordForEmail(String email) =>
      _client.auth.resetPasswordForEmail(email);

  /// Memverifikasi kode OTP recovery 6-digit, membuat sesi sementara
  /// yang dipakai untuk mengganti password.
  Future<AuthResponse> verifyRecoveryOtp(String email, String token) =>
      _client.auth.verifyOTP(type: OtpType.recovery, email: email, token: token);

  /// Mengganti password akun pada sesi yang sedang aktif.
  Future<void> updateUserPassword(String password) =>
      _client.auth.updateUser(UserAttributes(password: password));

  Future<void> signOut() => _client.auth.signOut();

  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateStream => _client.auth.onAuthStateChange;

  // ─── Meetings ─────────────────────────────────────────────

  Future<List<Meeting>> getMeetings() async {
    final res = await _client
        .from('meetings')
        .select('*, participants(*)')
        .order('created_at', ascending: false);
    return (res as List).map((j) => Meeting.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<Meeting> getMeeting(String id) async {
    final res = await _client.from('meetings').select('*, participants(*)').eq('id', id).single();
    return Meeting.fromJson(res);
  }

  Future<Meeting> createMeeting({required String title, String? agenda}) async {
    final userId = currentUser?.id ?? '';
    final now = DateTime.now();
    final res = await _client.from('meetings').insert({
      'user_id': userId,
      'title': title,
      'agenda': agenda,
      'status': 'draft',
      'date': '${now.day} ${_monthName(now.month)} ${now.year}',
      'time': '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}',
    }).select().single();
    return Meeting.fromJson(res);
  }

  Future<void> updateMeeting(String id, Map<String, dynamic> data) =>
      _client.from('meetings').update(data).eq('id', id);

  Future<void> deleteMeeting(String id) =>
      _client.from('meetings').delete().eq('id', id);

  Future<void> deleteAllMeetings() async {
    final uid = currentUser?.id;
    if (uid == null) return;
    await _client.from('meetings').delete().eq('user_id', uid);
  }

  // ─── Notula ────────────────────────────────────────────────

  Future<Notula?> getNotula(String meetingId) async {
    try {
      final res = await _client.from('notulas').select().eq('meeting_id', meetingId).single();
      return Notula.fromJson(res);
    } catch (_) { return null; }
  }

  Future<void> saveNotula(String meetingId, Notula notula) async {
    final existing = await _client.from('notulas').select('id').eq('meeting_id', meetingId).maybeSingle();
    if (existing != null) {
      await _client.from('notulas').update(notula.toJson()).eq('meeting_id', meetingId);
    } else {
      await _client.from('notulas').insert({...notula.toJson(), 'meeting_id': meetingId});
    }
  }

  // ─── Storage ───────────────────────────────────────────────

  /// Mengunggah audio rapat ke storage privat `recordings`.
  /// Mengembalikan path penyimpanan (bukan URL publik — bucket privat).
  ///
  /// Path harus berbentuk `audio/{userId}/...` agar sesuai policy RLS
  /// storage (`(storage.foldername(name))[2] = auth.uid()`).
  Future<String> uploadAudio(String meetingId, String filePath) async {
    final userId = currentUser?.id ?? '';
    final ext = filePath.split(RegExp(r'[\\/]')).last.split('.').last.toLowerCase();
    final path = 'audio/$userId/$meetingId.$ext';
    await _client.storage.from('recordings').upload(
          path,
          File(filePath),
          fileOptions: FileOptions(
            upsert: true,
            contentType: _audioContentTypes[ext],
          ),
        );
    return path;
  }

  /// Membuat signed URL sementara untuk memutar audio dari storage privat.
  Future<String> getAudioUrl(String path, {int expiresInSeconds = 3600}) =>
      _client.storage.from('recordings').createSignedUrl(path, expiresInSeconds);

  // ─── Transcript ────────────────────────────────────────────

  Future<void> saveTranscript(String meetingId, List<TranscriptLine> lines) async {
    await _client.from('transcript_lines').delete().eq('meeting_id', meetingId);
    if (lines.isEmpty) return;
    await _client.from('transcript_lines').insert(lines.asMap().entries.map((e) => {
          'meeting_id': meetingId,
          'timestamp': e.value.timestamp,
          'speaker_id': e.value.speakerId,
          'speaker': e.value.speaker,
          'text': e.value.text,
          'seq': e.key,
        }).toList());
  }

  Future<List<TranscriptLine>> getTranscript(String meetingId) async {
    final res = await _client
        .from('transcript_lines')
        .select()
        .eq('meeting_id', meetingId)
        .order('seq');
    return (res as List).map((j) => TranscriptLine.fromJson(j as Map<String, dynamic>)).toList();
  }

  // ─── Participants ──────────────────────────────────────────

  Future<void> saveParticipants(String meetingId, List<Participant> participants) async {
    await _client.from('participants').delete().eq('meeting_id', meetingId);
    if (participants.isEmpty) return;
    await _client.from('participants').insert(participants.map((p) => {
          'meeting_id': meetingId,
          'speaker_id': p.id,
          'label': p.label,
          'name': p.name,
        }).toList());
  }

  // ─── User ──────────────────────────────────────────────────

  Future<AppUser?> getUserProfile() async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    try {
      final res = await _client.from('profiles').select().eq('id', uid).single();
      return AppUser.fromJson(res);
    } catch (_) { return null; }
  }

  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final uid = currentUser?.id;
    if (uid == null) return;
    await _client.from('profiles').update(data).eq('id', uid);
  }

  /// Menghapus semua data pengguna lalu sign out.
  /// Catatan: auth user di Supabase hanya bisa dihapus via server/admin.
  /// Di sisi client, data di-wipe dan sesi dihentikan.
  Future<void> deleteAccount() async {
    final uid = currentUser?.id;
    if (uid == null) return;
    await _client.from('meetings').delete().eq('user_id', uid);
    await _client.from('profiles').delete().eq('id', uid);
    await _client.auth.signOut();
  }

  /// Mengubah alamat email akun. Supabase mengirim tautan konfirmasi ke
  /// email baru sebelum perubahan benar-benar diterapkan.
  Future<void> updateUserEmail(String email) =>
      _client.auth.updateUser(UserAttributes(email: email));

  /// Menambah pemakaian token AI (dalam menit) bulan ini untuk pengguna saat ini.
  Future<void> consumeTokens(int minutes) async {
    final uid = currentUser?.id;
    if (uid == null || minutes <= 0) return;
    final res = await _client.from('profiles').select('token_used').eq('id', uid).single();
    final used = (res['token_used'] as int? ?? 0) + minutes;
    await _client.from('profiles').update({'token_used': used}).eq('id', uid);
  }

  String _monthName(int m) => ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agt','Sep','Okt','Nov','Des'][m-1];
}
