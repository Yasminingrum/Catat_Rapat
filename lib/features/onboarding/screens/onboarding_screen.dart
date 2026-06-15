import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/widgets/app_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  List<({IconData icon, String title, String desc})> _slides(AppStrings s) => [
    (icon: Icons.mic_none_rounded, title: s.onboardingTitle1, desc: s.onboardingDesc1),
    (icon: Icons.smart_toy_outlined, title: s.onboardingTitle2, desc: s.onboardingDesc2),
    (icon: Icons.ios_share_rounded, title: s.onboardingTitle3, desc: s.onboardingDesc3),
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
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final slides = _slides(s);
    return Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(child: Column(children: [
      AnimatedOpacity(opacity: _page < 2 ? 1 : 0, duration: const Duration(milliseconds: 200),
          child: Align(alignment: Alignment.topRight,
              child: TextButton(onPressed: () => context.go('/login'),
                  child: Text(s.onboardingSkip, style: AppTextStyles.bodyMd(c: AppColors.textSecondary, w: FontWeight.w500))))),
      Expanded(child: PageView.builder(controller: _ctrl, itemCount: 3,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) => Padding(padding: AppSpacing.screenPadding,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 120, height: 120,
                  decoration: const BoxDecoration(color: AppColors.primaryLight, borderRadius: AppRadius.xl),
                  child: Icon(slides[i].icon, size: 56, color: AppColors.primary)),
              const SizedBox(height: 40),
              Text(slides[i].title, style: AppTextStyles.displayLg(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(slides[i].desc, style: AppTextStyles.bodyMd(c: AppColors.textSecondary), textAlign: TextAlign.center),
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
        label: _page == 2 ? s.onboardingStart : s.onboardingNext,
        onPressed: _next,
        variant: _page == 2 ? AppButtonVariant.success : AppButtonVariant.primary)),
      const SizedBox(height: 24),
    ])),
  );
  }
}
