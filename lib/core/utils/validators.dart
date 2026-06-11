abstract final class Validators {
  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(v.trim())) return 'Format email tidak valid';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password wajib diisi';
    if (v.length < 8) return 'Password minimal 8 karakter';
    return null;
  }

  static String? required(String? v, [String field = 'Field ini']) {
    if (v == null || v.trim().isEmpty) return '$field wajib diisi';
    return null;
  }

  static String? confirmPassword(String? v, String original) {
    if (v != original) return 'Password tidak cocok';
    return null;
  }
}
