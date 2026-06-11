import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _slides = [
    (icon: Icons.mic_none_rounded, title: 'Rekam Otomatis',
     desc: 'Letakkan HP di meja rapat. CatatRapat merekam dan mentranskripsikan percakapan secara otomatis dalam Bahasa Indonesia.'),
    (icon: Icons.smart_toy_outlined, title: 'AI Susun Notula',
     desc: 'AI kami merangkum hasil diskusi, mendeteksi keputusan, dan menyusun action item lengkap dengan PIC dan tenggat waktu.'),
    (icon: Icons.ios_share_rounded, title: 'Ekspor & Bagikan',
     desc: 'Unduh notula sebagai PDF, DOCX, atau TXT. Bagikan langsung via WhatsApp, Email, atau link khusus.'),
  ];

  void _next() {
    if (_page < 2) {
      _ctrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      context.go('/login');
    }
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(child: Column(children: [
      AnimatedOpacity(opacity: _page < 2 ? 1 : 0, duration: const Duration(milliseconds: 200),
          child: Align(alignment: Alignment.topRight,
              child: TextButton(onPressed: () => context.go('/login'),
                  child: Text('Lewati', style: AppTextStyles.bodyMd(c: AppColors.textSecondary, w: FontWeight.w500))))),
      Expanded(child: PageView.builder(controller: _ctrl, itemCount: 3,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) => Padding(padding: AppSpacing.screenPadding,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 120, height: 120,
                  decoration: const BoxDecoration(color: AppColors.primaryLight, borderRadius: AppRadius.xl),
                  child: Icon(_slides[i].icon, size: 56, color: AppColors.primary)),
              const SizedBox(height: 40),
              Text(_slides[i].title, style: AppTextStyles.displayLg(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(_slides[i].desc, style: AppTextStyles.bodyMd(c: AppColors.textSecondary), textAlign: TextAlign.center),
            ])))),
      Row(mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == _page ? 24 : 8, height: 8,
            decoration: BoxDecoration(
                color: i == _page ? AppColors.primary : AppColors.divider,
                borderRadius: AppRadius.full)))),
      const SizedBox(height: 24),
      Padding(padding: AppSpacing.screenPadding, child: AppButton(
        label: _page == 2 ? 'Mulai Sekarang ✨' : 'Lanjut →',
        onPressed: _next,
        variant: _page == 2 ? AppButtonVariant.primary : AppButtonVariant.secondary)),
      const SizedBox(height: 24),
    ])),
  );
}
