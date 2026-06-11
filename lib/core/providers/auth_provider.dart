import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';

// ── Auth State ────────────────────────────────────────────────

class AuthState {
  const AuthState({this.user, this.isLoading = false, this.error});
  final AppUser? user;
  final bool isLoading;
  final String? error;

  bool get isAuthenticated => user != null;

  AuthState copyWith({AppUser? user, bool? isLoading, String? error}) =>
      AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
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
    state = state.copyWith(isLoading: true, error: null);
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
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _supa.signUpWithEmail(email, password, name: name);
      if (res.user != null) {
        await _loadProfile();
        state = state.copyWith(isLoading: false);
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Registrasi gagal');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final opened = await _supa.signInWithGoogle();
      state = state.copyWith(
          isLoading: false,
          error: opened ? null : 'Tidak dapat membuka halaman login Google');
      return opened;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
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
}

// ── Providers ─────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

final currentUserProvider = Provider<AppUser?>((ref) => ref.watch(authProvider).user);