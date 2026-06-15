import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/verify_email_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/riwayat_screen.dart';
import '../../features/meeting/screens/mulai_rapat_screen.dart';
import '../../features/recording/screens/recording_screen.dart';
import '../../features/recording/screens/processing_screen.dart';
import '../../features/recording/screens/assign_speaker_screen.dart';
import '../../features/notula/screens/notula_screen.dart';
import '../../features/notula/screens/edit_notula_screen.dart';
import '../../features/notula/screens/transcript_screen.dart';
import '../../features/notula/screens/audio_player_screen.dart';
import '../../features/profil/screens/profil_screen.dart';
import '../../features/profil/screens/upgrade_screen.dart';
import '../providers/auth_provider.dart';

/// Memberi tahu [GoRouter] untuk mengevaluasi ulang `redirect` saat status
/// login berubah, tanpa membuat ulang seluruh instance [GoRouter].
///
/// Catatan: [appRouterProvider] sengaja TIDAK `ref.watch(authProvider)`.
/// Mem-watch provider yang sering berubah akan membuat [Provider] ini
/// rebuild dan mengembalikan instance [GoRouter] baru — instance baru
/// selalu mulai dari `initialLocation`, sehingga navigasi pengguna
/// (mis. dari `/profil`) ter-reset balik ke `/onboarding`.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen(authProvider, (prev, next) {
      if (prev?.isAuthenticated != next.isAuthenticated) notifyListeners();
    });
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authListenable = _AuthListenable(ref);
  ref.onDispose(authListenable.dispose);

  return GoRouter(
    initialLocation: '/onboarding',
    debugLogDiagnostics: false,
    refreshListenable: authListenable,
    redirect: (context, state) {
      final isLoggedIn = ref.read(authProvider).isAuthenticated;
      final loc = state.matchedLocation;

      if (!isLoggedIn) {
        final isPublicRoute = ['/login', '/register', '/forgot-password', '/verify-email', '/reset-password', '/onboarding']
            .any((r) => loc.startsWith(r));
        return isPublicRoute ? null : '/login';
      }

      // Sudah login — jangan biarkan terjebak di onboarding/login/register/verify-email/reset-password.
      final isEntryRoute = ['/login', '/register', '/verify-email', '/reset-password', '/onboarding']
          .any((r) => loc.startsWith(r));
      return isEntryRoute ? '/home' : null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: '/verify-email', builder: (_, s) {
        final e = s.extra as Map<String, dynamic>? ?? {};
        return VerifyEmailScreen(email: e['email'] as String? ?? '');
      }),
      GoRoute(path: '/reset-password', builder: (_, s) {
        final e = s.extra as Map<String, dynamic>? ?? {};
        return ResetPasswordScreen(email: e['email'] as String? ?? '');
      }),

      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/riwayat', builder: (_, __) => const RiwayatScreen()),
      GoRoute(path: '/profil', builder: (_, __) => const ProfilScreen()),
      GoRoute(path: '/upgrade', builder: (_, __) => const UpgradeScreen()),

      GoRoute(path: '/mulai-rapat', builder: (_, __) => const MulaiRapatScreen()),
      GoRoute(path: '/recording', builder: (_, s) {
        final e = s.extra as Map<String, dynamic>? ?? {};
        return RecordingScreen(title: e['title'] ?? 'Rapat Baru', agenda: e['agenda']);
      }),
      GoRoute(path: '/processing', builder: (_, s) {
        final e = s.extra as Map<String, dynamic>? ?? {};
        return ProcessingScreen(
          title: e['title'] ?? 'Rapat Baru',
          agenda: e['agenda'],
          fileName: e['fileName'],
          filePath: e['filePath'],
          durationSeconds: e['durationSeconds'],
        );
      }),
      GoRoute(path: '/assign-speaker', builder: (_, s) {
        final e = s.extra as Map<String, dynamic>? ?? {};
        return AssignSpeakerScreen(
          title: e['title'] ?? 'Rapat Baru',
          duration: e['duration'],
          meetingId: e['meetingId'],
        );
      }),

      GoRoute(path: '/rapat/:id', builder: (_, s) => NotulaScreen(meetingId: s.pathParameters['id']!)),
      GoRoute(path: '/rapat/:id/edit-notula', builder: (_, s) => EditNotulaScreen(meetingId: s.pathParameters['id']!)),
      GoRoute(path: '/rapat/:id/transcript', builder: (_, s) => TranscriptScreen(meetingId: s.pathParameters['id']!)),
      GoRoute(path: '/rapat/:id/audio', builder: (_, s) => AudioPlayerScreen(meetingId: s.pathParameters['id']!)),
    ],
  );
});
