import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';

// ── Auth State ────────────────────────────────────────────────

class AuthState {
  const AuthState({this.user, this.isLoading = false, this.error, this.message, this.pendingVerificationEmail});
  final AppUser? user;
  final bool isLoading;
  final String? error;
  final String? message;
  final String? pendingVerificationEmail;

  bool get isAuthenticated => user != null;

  AuthState copyWith({AppUser? user, bool? isLoading, String? error, String? message, String? pendingVerificationEmail}) =>
      AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        message: message,
        pendingVerificationEmail: pendingVerificationEmail,
      );
}

// ── Auth Notifier ─────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  final _supa = SupabaseService.instance;

  void _init() {
    // Cek sesi aktif
    final user = _supa.currentUser;
    if (user != null) {
      _loadProfile();
    }
    // Listen perubahan auth
    _supa.authStateStream.listen((event) {
      if (event.event == AuthChangeEvent.signedOut) {
        state = const AuthState();
      } else if (event.event == AuthChangeEvent.signedIn) {
        _loadProfile();
      }
    });
  }

  Future<void> _loadProfile() async {
    final profile = await _supa.getUserProfile();
    if (profile != null) {
      state = state.copyWith(user: profile);
    }
  }

  /// Memuat ulang profil pengguna (mis. setelah pemakaian token berubah).
  Future<void> refreshProfile() => _loadProfile();

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null, message: null);
    try {
      final res = await _supa.signInWithEmail(email, password);
      if (res.user != null) {
        await _loadProfile();
        state = state.copyWith(isLoading: false);
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Login gagal');
      return false;
    } catch (e) {
      if (e is AuthException && e.code == 'email_not_confirmed') {
        // Email belum diverifikasi — arahkan pengguna ke layar kode OTP.
        state = state.copyWith(isLoading: false, error: _mapAuthError(e), pendingVerificationEmail: email);
        return false;
      }
      state = state.copyWith(isLoading: false, error: _mapAuthError(e));
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null, message: null);
    try {
      final res = await _supa.signUpWithEmail(email, password, name: name);
      if (res.user == null) {
        state = state.copyWith(isLoading: false, error: 'Registrasi gagal');
        return false;
      }
      if (res.session != null) {
        // Konfirmasi email tidak diwajibkan — sesi langsung aktif.
        await _loadProfile();
        state = state.copyWith(isLoading: false);
        return true;
      }
      // Akun berhasil dibuat tapi menunggu verifikasi kode OTP (belum ada sesi).
      state = state.copyWith(
          isLoading: false,
          message: 'Registrasi berhasil! Masukkan kode verifikasi yang dikirim ke email Anda.',
          pendingVerificationEmail: email);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _mapAuthError(e));
      return false;
    }
  }

  /// Memverifikasi kode OTP 6-digit yang dikirim ke email saat registrasi.
  /// Jika berhasil, sesi langsung aktif (router akan redirect ke /home).
  Future<bool> verifyEmailOtp(String email, String token) async {
    state = state.copyWith(isLoading: true, error: null, message: null);
    try {
      final res = await _supa.verifySignupOtp(email, token);
      if (res.user != null) {
        await _loadProfile();
        state = state.copyWith(isLoading: false);
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Kode verifikasi tidak valid');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _mapAuthError(e));
      return false;
    }
  }

  /// Mengirim ulang kode OTP verifikasi signup ke email.
  Future<bool> resendEmailOtp(String email) async {
    try {
      await _supa.resendSignupOtp(email);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Mengirim kode OTP reset password ke email.
  Future<bool> sendPasswordResetOtp(String email) async {
    state = state.copyWith(isLoading: true, error: null, message: null);
    try {
      await _supa.resetPasswordForEmail(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _mapAuthError(e));
      return false;
    }
  }

  /// Mengirim ulang kode OTP reset password ke email.
  Future<bool> resendPasswordResetOtp(String email) async {
    try {
      await _supa.resetPasswordForEmail(email);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Memverifikasi kode OTP recovery lalu mengganti ke password baru.
  /// Jika berhasil, sesi recovery menjadi sesi aktif (router akan redirect ke /home).
  Future<bool> resetPasswordWithOtp(String email, String token, String newPassword) async {
    state = state.copyWith(isLoading: true, error: null, message: null);
    try {
      final res = await _supa.verifyRecoveryOtp(email, token);
      if (res.user == null) {
        state = state.copyWith(isLoading: false, error: 'Kode verifikasi tidak valid');
        return false;
      }
      await _supa.updateUserPassword(newPassword);
      await _loadProfile();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _mapAuthError(e));
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null, message: null);
    try {
      final opened = await _supa.signInWithGoogle();
      state = state.copyWith(
          isLoading: false,
          error: opened ? null : 'Tidak dapat membuka halaman login Google');
      return opened;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _mapAuthError(e));
      return false;
    }
  }

  /// Mengubah pesan error Supabase menjadi pesan Bahasa Indonesia yang
  /// lebih mudah dipahami pengguna.
  String _mapAuthError(Object e) {
    if (e is AuthException) {
      switch (e.code) {
        case 'email_not_confirmed':
          return 'Email belum diverifikasi. Masukkan kode verifikasi yang '
              'dikirim ke email Anda sebelum masuk.';
        case 'invalid_credentials':
          return 'Email atau password salah.';
        case 'user_already_exists':
        case 'email_exists':
          return 'Email sudah terdaftar. Silakan masuk atau gunakan email lain.';
        case 'weak_password':
          return 'Password terlalu lemah. Gunakan minimal 6 karakter.';
        case 'otp_expired':
        case 'otp_disabled':
          return 'Kode verifikasi salah atau sudah kadaluarsa. Silakan kirim ulang.';
        case 'over_email_send_rate_limit':
        case 'over_request_rate_limit':
          return 'Terlalu banyak percobaan. Coba lagi beberapa menit lagi.';
      }
      return e.message;
    }
    return e.toString();
  }

  Future<void> logout() async {
    await _supa.signOut();
    state = const AuthState();
  }

  Future<bool> updateProfile({String? name}) async {
    try {
      if (name != null) await _supa.updateUserProfile({'name': name});
      await _loadProfile();
      return true;
    } catch (_) { return false; }
  }

  /// Mengirim permintaan ganti email. Supabase akan mengirim tautan
  /// konfirmasi ke alamat email baru.
  Future<bool> updateEmail(String email) async {
    try {
      await _supa.updateUserEmail(email);
      return true;
    } catch (_) { return false; }
  }

  /// Mengganti password akun pengguna yang sedang login.
  Future<bool> changePassword(String newPassword) async {
    try {
      await _supa.updateUserPassword(newPassword);
      return true;
    } catch (_) { return false; }
  }
}

// ── Providers ─────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

final currentUserProvider = Provider<AppUser?>((ref) => ref.watch(authProvider).user);