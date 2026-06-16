import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

/// String antarmuka aplikasi (chrome UI) dalam Bahasa Indonesia & Inggris.
///
/// Catatan: konten hasil notula (ringkasan, keputusan, tindak lanjut, dan
/// file ekspor PDF/DOCX/TXT) selalu Bahasa Indonesia — pengaturan bahasa
/// di sini hanya memengaruhi tampilan aplikasi.
class AppStrings {
  const AppStrings(this.language);
  final AppLanguage language;

  bool get _id => language == AppLanguage.indonesia;
  String _t(String id, String en) => _id ? id : en;

  // ── Umum ─────────────────────────────────────────────────
  String get commonCancel => _t('Batal', 'Cancel');
  String get commonSave => _t('Simpan', 'Save');
  String get commonDelete => _t('Hapus', 'Delete');
  String get commonClose => _t('Tutup', 'Close');
  String get commonConfirm => _t('Konfirmasi', 'Confirm');
  String get commonError => _t('Error', 'Error');
  String get commonLoadFailed => _t('Gagal memuat', 'Failed to load');
  String get commonSearch => _t('Cari', 'Search');

  // ── Navigasi Bawah ──────────────────────────────────────
  String get navHome => _t('Beranda', 'Home');
  String get navMeetings => _t('Rapat', 'Meetings');
  String get navProfile => _t('Profil', 'Profile');

  // ── Beranda ─────────────────────────────────────────────
  String homeGreeting(String name) => _t('Halo, $name! 👋', 'Hi, $name! 👋');
  String get homeSubtitle => _t('Siap mencatat rapat hari ini?', 'Ready to take meeting notes today?');
  String get homeStatTotal => _t('Total Rapat', 'Total Meetings');
  String get homeStatOngoing => _t('Berlangsung', 'Ongoing');
  String get homeStatNotula => _t('Notula Dibuat', 'Minutes Created');
  String get homeRecentMeetings => _t('Rapat Terbaru', 'Recent Meetings');
  String get homeSeeAll => _t('Lihat Semua', 'See All');
  String get homeQuickActionTitle => _t('Mulai Rapat Baru', 'Start New Meeting');
  String get homeQuickActionSubtitle => _t('Rekam & buat notula otomatis', 'Record & generate minutes automatically');
  String get homeQuickActionButton => _t('Mulai Sekarang', 'Start Now');
  String get homeEmptyTitle => _t('Belum ada rapat tercatat', 'No meetings recorded yet');
  String get homeEmptySubtitle => _t('Mulai rapat pertama Anda sekarang!', 'Start your first meeting now!');

  // ── Riwayat ─────────────────────────────────────────────
  String get riwayatTitle => _t('Riwayat Rapat', 'Meeting History');
  String get riwayatSearchHint => _t('Cari rapat...', 'Search meetings...');
  String get riwayatFilterAll => _t('Semua', 'All');
  String riwayatFilterStarred(int count) => _t('★ Berbintang ($count)', '★ Starred ($count)');
  String get riwayatFilterDone => _t('Selesai', 'Done');
  String get riwayatFilterInProgress => _t('Proses', 'In Progress');
  String get riwayatEmptyTitle => _t('Belum ada rapat tercatat', 'No meetings recorded yet');
  String get riwayatEmptySearchTitle => _t('Tidak ada rapat ditemukan', 'No meetings found');
  String get riwayatEmptySearchSubtitle => _t('Coba kata kunci lain', 'Try a different keyword');
  String get riwayatDeleteTitle => _t('Hapus Rapat?', 'Delete Meeting?');
  String riwayatDeleteContent(String title) =>
      _t('"$title" akan dihapus permanen beserta transkripsi dan notulanya.',
          '"$title" will be permanently deleted along with its transcript and minutes.');
  String get riwayatStar => _t('Tandai Bintang', 'Add Star');
  String get riwayatUnstar => _t('Hapus Bintang', 'Remove Star');
  String get riwayatDeleteMeeting => _t('Hapus Rapat', 'Delete Meeting');
  String riwayatParticipants(int count) => _t('$count peserta', '$count participants');
  String get riwayatStatusInProgress => _t('Proses', 'In Progress');
  String get riwayatStatusDone => _t('Selesai', 'Done');

  // ── Profil & Pengaturan ──────────────────────────────────
  String get profilTitle => _t('Profil & Pengaturan', 'Profile & Settings');
  String get profilSectionAccount => _t('AKUN & KEAMANAN', 'ACCOUNT & SECURITY');
  String get profilChangeName => _t('Ganti Nama', 'Change Name');
  String get profilChangeEmail => _t('Ganti Email', 'Change Email');
  String get profilChangePassword => _t('Ganti Password', 'Change Password');
  String get profilDeleteAccount => _t('Hapus Akun', 'Delete Account');
  String get profilSectionPreferences => _t('PREFERENSI APLIKASI', 'APP PREFERENCES');
  String get profilLanguage => _t('Bahasa', 'Language');
  String get profilLanguagePickerTitle => _t('Pengaturan Bahasa', 'Language Settings');
  String get profilExportFormat => _t('Format Ekspor Default', 'Default Export Format');
  String get profilRecordingQuality => _t('Kualitas Rekaman', 'Recording Quality');
  String get profilSectionNotifications => _t('NOTIFIKASI', 'NOTIFICATIONS');
  String get profilNotifActionReminder => _t('Reminder Action Item', 'Action Item Reminders');
  String get profilNotifSummaryReady => _t('Notifikasi Ringkasan Selesai', 'Summary Ready Notifications');
  String get profilSectionStorage => _t('PENYIMPANAN & DATA', 'STORAGE & DATA');
  String get profilRetention => _t('Retensi Rekaman', 'Recording Retention');
  String get profilDeleteAllData => _t('Hapus Semua Data Rapat', 'Delete All Meeting Data');
  String get profilSectionSubscription => _t('LANGGANAN', 'SUBSCRIPTION');
  String get profilActive => _t('Aktif', 'Active');
  String get profilTokenRemaining => _t('Token AI tersisa', 'AI Tokens Remaining');
  String get profilResetDate => _t('Reset tanggal 1 setiap bulan', 'Resets on the 1st of every month');
  String get profilUpgrade => _t('⚡ Upgrade ke Premium', '⚡ Upgrade to Premium');
  String get profilLogout => _t('Keluar', 'Log Out');
  String get profilPlanFree => _t('Paket Gratis', 'Free Plan');
  String get profilPlanPro => _t('Paket Pro', 'Pro Plan');
  String get profilPlanBusiness => _t('Paket Business', 'Business Plan');
  String get profilDefaultUser => _t('Pengguna', 'User');

  // ── Dialog edit nama/email ───────────────────────────────
  String get profilChangeNameTitle => _t('Ganti Nama', 'Change Name');
  String get profilFullNameHint => _t('Nama lengkap', 'Full name');
  String get profilChangeEmailTitle => _t('Ganti Email', 'Change Email');
  String get profilNewEmailHint => _t('Alamat email baru', 'New email address');
  String get profilEmailConfirmNotice =>
      _t('Tautan konfirmasi akan dikirim ke email baru.', 'A confirmation link will be sent to the new email.');
  String get profilInvalidEmail => _t('Email tidak valid', 'Invalid email');
  String get profilSend => _t('Kirim', 'Send');
  String get profilNameUpdated => _t('Nama berhasil diperbarui', 'Name updated successfully');
  String get profilNameUpdateFailed => _t('Gagal memperbarui nama', 'Failed to update name');
  String get profilEmailConfirmSent => _t('Tautan konfirmasi telah dikirim ke email baru', 'A confirmation link has been sent to the new email');
  String get profilEmailUpdateFailed => _t('Gagal mengubah email', 'Failed to update email');

  // ── Dialog ganti password ────────────────────────────────
  String get profilChangePasswordTitle => _t('Ganti Password', 'Change Password');
  String get profilPasswordUpdated => _t('Password berhasil diperbarui', 'Password updated successfully');
  String get profilPasswordUpdateFailed => _t('Gagal memperbarui password', 'Failed to update password');

  // ── Onboarding ───────────────────────────────────────────
  String get onboardingSkip => _t('Lewati', 'Skip');
  String get onboardingStart => _t('Mulai Sekarang ✨', 'Get Started ✨');
  String get onboardingNext => _t('Lanjut →', 'Next →');
  String get onboardingTitle1 => _t('Rekam Otomatis', 'Automatic Recording');
  String get onboardingDesc1 => _t(
      'Letakkan HP di meja rapat. CatatRapat merekam dan mentranskripsikan percakapan secara otomatis dalam Bahasa Indonesia.',
      'Place your phone on the meeting table. CatatRapat automatically records and transcribes the conversation in Indonesian.');
  String get onboardingTitle2 => _t('AI Susun Notula', 'AI Drafts Minutes');
  String get onboardingDesc2 => _t(
      'AI kami merangkum hasil diskusi, mendeteksi keputusan, dan menyusun action item lengkap dengan PIC dan tenggat waktu.',
      'Our AI summarizes the discussion, detects decisions, and compiles action items complete with owners and deadlines.');
  String get onboardingTitle3 => _t('Ekspor & Bagikan', 'Export & Share');
  String get onboardingDesc3 => _t(
      'Unduh notula sebagai PDF, DOCX, atau TXT. Bagikan langsung via WhatsApp, Email, atau link khusus.',
      'Download minutes as PDF, DOCX, or TXT. Share directly via WhatsApp, Email, or a dedicated link.');

  // ── Autentikasi ──────────────────────────────────────────
  String get authLoginTitle => _t('Masuk ke CatatRapat', 'Sign in to CatatRapat');
  String get authTagline => _t('Pencatat Otomatis Berbasis AI', 'AI-Powered Automatic Meeting Notes');
  String get authTaglineFull => _t('CatatRapat — Pencatat Otomatis AI', 'CatatRapat — AI Automatic Meeting Notes');
  String get authEmailLabel => _t('Email', 'Email');
  String get authPasswordLabel => _t('Password', 'Password');
  String get authForgotPassword => _t('Lupa password?', 'Forgot password?');
  String get authLoginButton => _t('Masuk', 'Sign In');
  String get authOrContinueWith => _t('atau lanjutkan dengan', 'or continue with');
  String get authGoogleSignIn => _t('Masuk dengan Google', 'Sign in with Google');
  String get authNoAccount => _t('Belum punya akun? ', "Don't have an account? ");
  String get authRegisterNow => _t('DAFTAR SEKARANG', 'REGISTER NOW');
  String get authLoginFailed => _t('Login gagal', 'Login failed');
  String get authLoginGoogleFailed => _t('Login Google gagal', 'Google login failed');

  String get authRegisterTitle => _t('Daftar Akun', 'Create Account');
  String get authFullNameLabel => _t('Nama Lengkap', 'Full Name');
  String get authFullNameHint => _t('Nama depan belakang', 'First and last name');
  String get authFieldNama => _t('Nama', 'Name');
  String get authCreatePasswordHint => _t('Buat password', 'Create a password');
  String get authConfirmPasswordLabel => _t('Ulangi Password', 'Confirm Password');
  String get authConfirmPasswordHint => _t('Ulangi password', 'Re-enter password');
  String get authRegisterButton => _t('Daftar Sekarang', 'Register Now');
  String get authHaveAccount => _t('Sudah punya akun? ', 'Already have an account? ');
  String get authLoginNow => _t('MASUK', 'SIGN IN');
  String get authRegisterFailed => _t('Registrasi gagal', 'Registration failed');

  String get authForgotPasswordTitle => _t('Lupa Password?', 'Forgot Password?');
  String get authForgotPasswordBody => _t(
      'Masukkan alamat email terdaftar dan kami akan mengirimkan kode OTP untuk reset password.',
      'Enter your registered email address and we will send you an OTP code to reset your password.');
  String get authResetPasswordButton => _t('Reset Password', 'Reset Password');
  String get authResetPasswordSendFailed => _t('Gagal mengirim kode reset password', 'Failed to send password reset code');

  // ── Reset Password (OTP) ──────────────────────────────────
  String get authResetPasswordTitle => _t('Reset Password', 'Reset Password');
  String authResetPasswordBody(String email) => _t(
      'Kami telah mengirim kode verifikasi 6 digit ke $email. Masukkan kode tersebut beserta password baru Anda.',
      'We sent a 6-digit verification code to $email. Enter it below along with your new password.');
  String get authNewPasswordLabel => _t('Password Baru', 'New Password');
  String get authResetPasswordFailed => _t('Reset password gagal', 'Password reset failed');

  // ── Verifikasi Email (OTP) ────────────────────────────────
  String get authVerifyTitle => _t('Verifikasi Email', 'Verify Email');
  String authVerifyBody(String email) => _t(
      'Kami telah mengirim kode verifikasi 6 digit ke $email. Masukkan kode tersebut untuk mengaktifkan akun Anda.',
      'We sent a 6-digit verification code to $email. Enter it below to activate your account.');
  String get authVerifyCodeLabel => _t('Kode Verifikasi', 'Verification Code');
  String get authVerifyCodeHint => _t('123456', '123456');
  String get authVerifyButton => _t('Verifikasi', 'Verify');
  String get authVerifyFailed => _t('Verifikasi gagal', 'Verification failed');
  String get authVerifyResend => _t('Kirim ulang kode', 'Resend code');
  String authVerifyResendCooldown(int seconds) => _t('Kirim ulang dalam ${seconds}d', 'Resend in ${seconds}s');
  String get authVerifyCodeResent => _t('Kode verifikasi baru telah dikirim', 'A new verification code has been sent');
  String get authVerifyResendFailed => _t('Gagal mengirim ulang kode', 'Failed to resend code');

  // ── Validasi Form ────────────────────────────────────────
  String get validationEmailRequired => _t('Email wajib diisi', 'Email is required');
  String get validationEmailInvalid => _t('Format email tidak valid', 'Invalid email format');
  String get validationPasswordRequired => _t('Password wajib diisi', 'Password is required');
  String get validationPasswordMinLength => _t('Password minimal 8 karakter', 'Password must be at least 8 characters');
  String validationFieldRequired(String field) => _t('$field wajib diisi', '$field is required');
  String get validationPasswordMismatch => _t('Password tidak cocok', 'Passwords do not match');
  String get validationOtpRequired => _t('Kode verifikasi wajib diisi', 'Verification code is required');
  String get validationOtpInvalid => _t('Kode verifikasi harus 6 digit', 'Verification code must be 6 digits');

  String? Function(String?) get validateEmail => (v) {
        if (v == null || v.trim().isEmpty) return validationEmailRequired;
        if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(v.trim())) return validationEmailInvalid;
        return null;
      };

  String? Function(String?) get validatePassword => (v) {
        if (v == null || v.isEmpty) return validationPasswordRequired;
        if (v.length < 8) return validationPasswordMinLength;
        return null;
      };

  String? Function(String?) validateRequired(String field) => (v) {
        if (v == null || v.trim().isEmpty) return validationFieldRequired(field);
        return null;
      };

  String? Function(String?) validateConfirmPassword(String original) => (v) {
        if (v != original) return validationPasswordMismatch;
        return null;
      };

  String? Function(String?) get validateOtpCode => (v) {
        if (v == null || v.trim().isEmpty) return validationOtpRequired;
        if (!RegExp(r'^\d{6}$').hasMatch(v.trim())) return validationOtpInvalid;
        return null;
      };

  // ── Mulai Rapat ──────────────────────────────────────────
  String get mulaiRapatTitle => _t('Mulai Rapat Baru', 'Start New Meeting');
  String get mulaiRapatFileSizeError => _t('Ukuran file maksimal 500 MB', 'Maximum file size is 500 MB');
  String get mulaiRapatTitleLabel => _t('Judul Rapat', 'Meeting Title');
  String get mulaiRapatTitleHint => _t('Contoh: Audit Proses PT Untung Terus', 'Example: PT Untung Terus Process Audit');
  String get mulaiRapatTitleRequired => _t('Judul rapat wajib diisi', 'Meeting title is required');
  String get mulaiRapatAgendaLabel => _t('Agenda (opsional)', 'Agenda (optional)');
  String get mulaiRapatAgendaHint => _t(
      '1. Review temuan audit Q1\n2. Klarifikasi akuntansi piutang\n3. ...',
      '1. Review Q1 audit findings\n2. Clarify receivables accounting\n3. ...');
  String get mulaiRapatTokenRemaining => _t('Sisa token bulan ini', 'Tokens remaining this month');
  String mulaiRapatTokenMinutes(int minutes) => _t('$minutes menit', '$minutes minutes');
  String get mulaiRapatFreeTier => _t('Free tier', 'Free tier');
  String get mulaiRapatModeLabel => _t('MODE REKAM', 'RECORDING MODE');
  String get mulaiRapatStartRecording => _t('Mulai Rekam', 'Start Recording');
  String get mulaiRapatUploadProcess => _t('Upload & Proses', 'Upload & Process');
  String get mulaiRapatFileReady => _t('File siap diproses', 'File ready to process');
  String get mulaiRapatChooseFile => _t('Pilih file audio', 'Choose audio file');
  String get mulaiRapatFileFormats => _t('MP3, M4A, WAV, OGG · Maks 500 MB', 'MP3, M4A, WAV, OGG · Max 500 MB');
  String get mulaiRapatBrowseFile => _t('Browse File', 'Browse File');
  String get mulaiRapatProcessingNote => _t(
      'File akan diproses AI untuk transkripsi.\nDurasi proses ≈ 30% dari durasi audio.',
      'The file will be processed by AI for transcription.\nProcessing takes ≈ 30% of the audio duration.');

  // ── Rekaman ──────────────────────────────────────────────
  String get recordingMicPermission => _t('Izin mikrofon diperlukan untuk merekam', 'Microphone permission is required to record');
  String get recordingPaused => _t('DIJEDA', 'PAUSED');
  String get recordingRec => _t('REC', 'REC');
  String get recordingQualityGood => _t('Bagus', 'Good');
  String get recordingQualityMedium => _t('Sedang', 'Medium');
  String get recordingQualityPoor => _t('Lemah', 'Weak');
  String get recordingAudioQuality => _t('Kualitas Audio', 'Audio Quality');
  String get recordingLowQualityTip => _t('💡 Dekati mikrofon atau kurangi noise di ruangan', '💡 Move closer to the microphone or reduce room noise');
  String get recordingLiveTranscriptTitle => _t('Transkripsi Berjalan', 'Live Transcript');
  String get recordingActive => _t('Aktif', 'Active');
  String get recordingInactive => _t('Nonaktif', 'Inactive');
  String get recordingWaitingForVoice => _t('Menunggu suara untuk ditranskripsi...', 'Waiting for audio to transcribe...');
  String get recordingLiveUnavailable => _t(
      'Transkripsi live tidak tersedia. Notula tetap akan dibuat setelah rekaman selesai.',
      'Live transcription is unavailable. Minutes will still be generated after the recording ends.');
  String get recordingPauseOrDoneHint => _t('Jeda atau selesai untuk tambah peserta', 'Pause or finish to add participants');
  String get recordingStopDialogTitle => _t('Hentikan rekaman?', 'Stop recording?');
  String get recordingStopDialogBody => _t('Rekaman akan dihentikan dan tidak tersimpan.', 'The recording will be stopped and not saved.');
  String get recordingContinue => _t('Lanjutkan Rekam', 'Continue Recording');
  String get recordingStop => _t('Hentikan', 'Stop');

  // ── Assign Speaker (dipertahankan untuk recording_screen) ───
  String assignSpeakerVoiceLabel(int index) => _t('Suara $index', 'Voice $index');

  // ── Add Participants ────────────────────────────────────────
  String get addParticipantsTitle => _t('Peserta Rapat', 'Meeting Participants');
  String get addParticipantsSubtitle => _t('Tambahkan nama-nama peserta rapat ini', 'Add the names of the meeting participants');
  String get addParticipantsHint => _t('Nama peserta...', 'Participant name...');
  String get addParticipantsAdd => _t('+ Tambah peserta', '+ Add participant');
  String get addParticipantsSave => _t('Simpan Peserta', 'Save Participants');
  String get addParticipantsSkip => _t('Lewati', 'Skip');
  String addParticipantsSaveError(Object e) => _t('Gagal menyimpan: $e', 'Failed to save: $e');

  // ── Processing ───────────────────────────────────────────
  String get processingTitle => _t('Memproses Rapat', 'Processing Meeting');
  String get processingStageUpload => _t('Mengunggah file', 'Uploading file');
  String get processingStageAnalyze => _t('Menganalisis audio', 'Analyzing audio');
  String get processingStageDetectSpeaker => _t('Mendeteksi speaker', 'Detecting speakers');
  String get processingStageTranscribe => _t('Membuat transkripsi', 'Generating transcript');
  String get processingStatusUploading => _t('Mengunggah file...', 'Uploading file...');
  String get processingStatusAnalyzing => _t('Menganalisis audio...', 'Analyzing audio...');
  String get processingStatusDetecting => _t('Mendeteksi speaker...', 'Detecting speakers...');
  String get processingStatusTranscribing => _t('Membuat transkripsi...', 'Generating transcript...');
  String get processingStatusDone => _t('Selesai! ✓', 'Done! ✓');
  String get processingSubtitleDone => _t('Selesai', 'Done');
  String get processingSubtitleUploading => _t('Menyimpan rapat & mengunggah audio', 'Saving meeting & uploading audio');
  String get processingSubtitleAnalyzing => _t('AI sedang menganalisis audio, proses ini bisa memakan waktu', 'AI is analyzing the audio, this may take a while');
  String get processingSubtitleFinalizing => _t('Menyusun ringkasan dan action item', 'Compiling summary and action items');
  String get processingFileAudio => _t('FILE AUDIO', 'AUDIO FILE');
  String get processingCancel => _t('Batalkan', 'Cancel');
  String get processingErrorTitle => _t('Pemrosesan Gagal', 'Processing Failed');
  String get processingRetry => _t('Coba Lagi', 'Try Again');
  String get processingErrorInvalidApiKey => _t(
      'API key layanan AI tidak valid atau kedaluwarsa. Hubungi admin untuk memeriksa konfigurasi.',
      'The AI service API key is invalid or has expired. Contact the admin to check the configuration.');
  String get processingErrorRateLimit => _t(
      'Layanan AI sedang sibuk atau kuota bulanan telah tercapai. Silakan coba lagi beberapa saat lagi.',
      'The AI service is busy or the monthly quota has been reached. Please try again shortly.');
  String get processingErrorNoConnection => _t(
      'Tidak dapat terhubung ke layanan AI. Periksa koneksi internet Anda dan coba lagi.',
      'Could not connect to the AI service. Check your internet connection and try again.');
  String processingErrorGeneric(int status) => _t(
      'Layanan AI mengembalikan kesalahan ($status). Silakan coba lagi.',
      'The AI service returned an error ($status). Please try again.');

  // ── Notula ───────────────────────────────────────────────
  String get notulaSummaryTitle => _t('Ringkasan', 'Summary');
  String get notulaSummaryEmpty => _t('Belum ada ringkasan.', 'No summary yet.');
  String get notulaDecisionsTitle => _t('Keputusan', 'Decisions');
  String get notulaDecisionsEmpty => _t('Belum ada keputusan tercatat.', 'No decisions recorded yet.');
  String get notulaActionItemTitle => _t('Action Item', 'Action Items');
  String get notulaActionItemSubtitle => _t('Centang untuk memasukkan ke dalam notula', 'Check to include in the minutes');
  String get notulaActionItemEmpty => _t('Belum ada tindak lanjut tercatat.', 'No follow-ups recorded yet.');
  String get notulaListenAudio => _t('Dengar Rekaman Audio', 'Listen to Audio Recording');
  String get notulaViewTranscript => _t('Lihat Transkripsi Lengkap', 'View Full Transcript');
  String get notulaEditAndShare => _t('EDIT DAN BAGIKAN NOTULA', 'EDIT AND SHARE MINUTES');
  String get notulaEditButton => _t('Edit Notula', 'Edit Minutes');

  // ── Edit Notula ──────────────────────────────────────────
  String get editNotulaHeaderLabel => _t('NOTULA RAPAT', 'MEETING MINUTES');
  String get editNotulaShare => _t('Bagikan', 'Share');
  String get editNotulaSummaryLabel => _t('RINGKASAN', 'SUMMARY');
  String get editNotulaDecisionsLabel => _t('KEPUTUSAN', 'DECISIONS');
  String get editNotulaAddDecision => _t('+ Tambah keputusan baru...', '+ Add new decision...');
  String get editNotulaActionItemsLabel => _t('TINDAK LANJUT', 'ACTION ITEMS');
  String get editNotulaActionDescHint => _t('Deskripsi tindak lanjut', 'Action item description');
  String get editNotulaPicLabel => _t('PIC', 'ASSIGNEE');
  String get editNotulaNameHint => _t('Nama...', 'Name...');
  String get editNotulaDeadlineLabel => _t('TENGGAT', 'DEADLINE');
  String get editNotulaDateHint => _t('Tanggal...', 'Date...');
  String get editNotulaAddActionItem => _t('+ Tambah tindak lanjut baru...', '+ Add new action item...');
  String get editNotulaCancel => _t('Batal', 'Cancel');
  String get editNotulaSave => _t('Simpan', 'Save');
  String get editNotulaSavedSuccess => _t('Notula berhasil disimpan', 'Minutes saved successfully');
  String get editNotulaReadyExport => _t('Siap Ekspor', 'Ready to Export');
  String get editNotulaDraft => _t('Draft', 'Draft');
  String get editNotulaDateLabel => _t('TANGGAL', 'DATE');
  String get editNotulaTimeLabel => _t('WAKTU', 'TIME');
  String get editNotulaDurationLabel => _t('DURASI', 'DURATION');
  String get editNotulaParticipantsLabel => _t('PESERTA', 'PARTICIPANTS');

  // ── Transkripsi ──────────────────────────────────────────
  String get transcriptTitle => _t('Transkripsi Lengkap', 'Full Transcript');
  String get transcriptAllSpeakers => _t('Semua', 'All');
  String get transcriptEmpty => _t('Transkripsi masih kosong', 'Transcript is still empty');
  String transcriptError(Object error) => _t('Error: $error', 'Error: $error');
  String get transcriptEditParticipants => _t('Edit Peserta Rapat', 'Edit Meeting Participants');

  // ── Audio Player ─────────────────────────────────────────
  String get audioPlayerHeaderLabel => _t('REKAMAN AUDIO', 'AUDIO RECORDING');
  String get audioPlayerNotAvailable => _t('Rekaman audio tidak tersedia untuk rapat ini.', 'Audio recording is not available for this meeting.');
  String audioPlayerLoadError(Object error) => _t('Gagal memuat audio: $error', 'Failed to load audio: $error');
  String get audioPlayerSkipHint => _t('Tekan tombol untuk loncat ±15 detik', 'Tap the buttons to skip ±15 seconds');
  String get audioPlayerUnavailableTitle => _t('Rekaman Audio Tidak Tersedia', 'Audio Recording Not Available');

  // ── Bagikan Notula ───────────────────────────────────────
  String get bagikanNotulaTitle => _t('Bagikan Notula', 'Share Minutes');
  String get bagikanNotulaLinkCopied => _t('Link disalin ke clipboard', 'Link copied to clipboard');
  String get bagikanNotulaOrShareVia => _t('Atau bagikan melalui', 'Or share via');
  String bagikanNotulaEmailSubject(String title) => _t('Notula Rapat: $title', 'Meeting Minutes: $title');
  String bagikanNotulaEmailBody(String title, String link) => _t(
      'Berikut tautan notula rapat "$title":\n$link',
      'Here is the link to the meeting minutes for "$title":\n$link');
  String get bagikanNotulaEmailError => _t('Tidak dapat membuka aplikasi email', 'Could not open email app');
  String bagikanNotulaWhatsappText(String title, String link) =>
      _t('Notula Rapat: $title\n$link', 'Meeting Minutes: $title\n$link');
  String get bagikanNotulaWhatsappError => _t('Tidak dapat membuka WhatsApp', 'Could not open WhatsApp');
  String get bagikanNotulaChannelEmail => _t('Email', 'Email');
  String get bagikanNotulaChannelWhatsapp => 'WhatsApp';
  String get bagikanNotulaChannelCopyLink => _t('Salin Link', 'Copy Link');

  // ── Unduh Notula ─────────────────────────────────────────
  String get unduhNotulaTitle => _t('Unduh Notula', 'Download Minutes');
  String unduhNotulaError(Object error) => _t('Gagal mengunduh notula: $error', 'Failed to download minutes: $error');
  String get unduhNotulaDefaultBadge => _t('Default', 'Default');
  String get unduhNotulaRecommendedBadge => _t('Disarankan', 'Recommended');
  String get unduhNotulaPdfSubtitle => _t('Siap cetak, tanda tangan digital', 'Ready to print, digital signature');
  String get unduhNotulaDocxSubtitle => _t('Microsoft Word, bisa diedit lanjut', 'Microsoft Word, further editable');
  String get unduhNotulaTxtSubtitle => _t('Teks polos, ukuran file kecil', 'Plain text, small file size');

  // ── Hapus Data & Akun ────────────────────────────────────
  String get profilDeleteAllDataTitle => _t('Hapus Semua Data Rapat?', 'Delete All Meeting Data?');
  String get profilDeleteAllDataBody => _t(
      'Semua rapat, transkripsi, dan notula akan dihapus permanen. Tindakan ini tidak dapat dibatalkan.',
      'All meetings, transcripts, and minutes will be permanently deleted. This action cannot be undone.');
  String get profilDeleteAllDataSuccess => _t('Semua data rapat berhasil dihapus', 'All meeting data deleted successfully');
  String get profilDeleteAllDataFailed => _t('Gagal menghapus data rapat', 'Failed to delete meeting data');

  String get profilDeleteAccountTitle => _t('Hapus Akun?', 'Delete Account?');
  String get profilDeleteAccountBody => _t(
      'Akun dan seluruh data Anda akan dihapus permanen, termasuk semua rapat, transkripsi, dan notula. Tindakan ini tidak dapat dibatalkan.',
      'Your account and all data will be permanently deleted, including all meetings, transcripts, and minutes. This action cannot be undone.');
  String get profilDeleteAccountFailed => _t('Gagal menghapus akun', 'Failed to delete account');

  // ── Upgrade ──────────────────────────────────────────────
  String get upgradeBadge => 'CatatRapat Premium';
  String get upgradeHeadline => _t('Rapatmu Lebih\nProduktif', 'Your Meetings,\nMore Productive');
  String get upgradeSubtitle => _t('Rekam, transkripsi, dan buat notula tanpa batas', 'Record, transcribe, and generate minutes without limits');
  String get upgradeChoosePlan => _t('PILIH PAKET', 'CHOOSE PLAN');
  String get upgradeMonthly => _t('Bulanan', 'Monthly');
  String get upgradeYearly => _t('Tahunan', 'Yearly');
  String get upgradePerMonth => _t('/bulan', '/month');
  String get upgradeSaveBadge => _t('Hemat 41%', 'Save 41%');
  String get upgradeBilledYearly => _t('Ditagih Rp 348.000/tahun', 'Billed Rp 348.000/year');
  String get upgradePremiumFeaturesLabel => _t('FITUR PREMIUM', 'PREMIUM FEATURES');
  String get upgradeFreeTierLabel => _t('FREE TIER KAMU', 'YOUR FREE TIER');
  String get upgradeTestimonial => _t(
      '"Notulanya langsung jadi setelah rapat selesai. Hemat 2 jam per minggu buat tim kami!"',
      '"The minutes are ready right after the meeting ends. Saves our team 2 hours a week!"');
  String get upgradeTestimonialRole => _t('Manajer Proyek', 'Project Manager');
  String upgradeCtaStart(String priceLabel) => _t('Mulai $priceLabel/bulan', 'Start $priceLabel/month');
  String get upgradeCtaFootnote => _t('Batalkan kapan saja · Tanpa biaya tersembunyi', 'Cancel anytime · No hidden fees');
  String get upgradePaymentUnavailable => _t('Pembayaran belum tersedia di versi ini.', 'Payment is not available in this version yet.');

  String get upgradeFeatureRecordingTitle => _t('Rekaman Unlimited', 'Unlimited Recording');
  String get upgradeFeatureRecordingSubtitle => _t('Tidak ada batas durasi rekaman', 'No limit on recording duration');
  String get upgradeFeatureNotulaTitle => _t('Notula AI Otomatis', 'Automatic AI Minutes');
  String get upgradeFeatureNotulaSubtitle => _t('Generate notula tak terbatas', 'Generate unlimited minutes');
  String get upgradeFeatureParticipantsTitle => _t('Peserta Unlimited', 'Unlimited Participants');
  String get upgradeFeatureParticipantsSubtitle => _t('Identifikasi hingga 10 pembicara', 'Identify up to 10 speakers');
  String get upgradeFeatureHistoryTitle => _t('Riwayat Selamanya', 'Forever History');
  String get upgradeFeatureHistorySubtitle => _t('Simpan semua rapat tanpa batas waktu', 'Save all meetings with no time limit');
  String get upgradeFeatureAccuracyTitle => _t('Prioritas Akurasi', 'Accuracy Priority');
  String get upgradeFeatureAccuracySubtitle => _t('Model AI terbaik untuk transkripsi', 'Best AI model for transcription');
  String get upgradeFeatureEncryptionTitle => _t('Enkripsi End-to-End', 'End-to-End Encryption');
  String get upgradeFeatureEncryptionSubtitle => _t('Keamanan data rapat terjamin', 'Meeting data security guaranteed');

  String get upgradeFreeMinutes => _t('847 menit/bulan', '847 minutes/month');
  String get upgradeFreeSpeakers => _t('Maksimal 3 pembicara', 'Maximum 3 speakers');
  String get upgradeFreeHistory => _t('Riwayat 30 hari', '30-day history');
  String get upgradeFreeModel => _t('Model AI standar', 'Standard AI model');

  // ── Pengaturan: label opsi ────────────────────────────────
  String recordingQualityLabel(RecordingQuality q) => switch (q) {
    RecordingQuality.standard => _t('Standar (16 kHz)', 'Standard (16 kHz)'),
    RecordingQuality.high => _t('Tinggi (32 kHz)', 'High (32 kHz)'),
    RecordingQuality.veryHigh => _t('Sangat Tinggi (48 kHz)', 'Very High (48 kHz)'),
  };

  String retentionPeriodLabel(RetentionPeriod r) => switch (r) {
    RetentionPeriod.days30 => _t('30 hari', '30 days'),
    RetentionPeriod.days90 => _t('90 hari', '90 days'),
    RetentionPeriod.year1 => _t('1 tahun', '1 year'),
    RetentionPeriod.forever => _t('Selamanya', 'Forever'),
  };
}

final appStringsProvider = Provider<AppStrings>(
    (ref) => AppStrings(ref.watch(settingsProvider).language));
