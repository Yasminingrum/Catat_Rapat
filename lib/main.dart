import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Inisialisasi Supabase
  // Nilai diisi via --dart-define (lihat .env.example untuk referensi)
  // authFlowType: implicit agar verifikasi OTP (signup, recovery, email
  // change) bekerja tanpa deep link. PKCE mengikat token ke code_challenge
  // sehingga verifyOTP gagal memvalidasi kode yang dikirim via email.
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    publishableKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );

  // Inisialisasi notifikasi lokal & minta izin sejak awal
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermission();

  runApp(
    const ProviderScope(
      child: CatatRapatApp(),
    ),
  );
}

class CatatRapatApp extends ConsumerWidget {
  const CatatRapatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'CatatRapat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
