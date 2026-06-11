import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentIndex});
  final int currentIndex;

  @override
  Widget build(BuildContext context) => Container(
    height: 80,
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(top: BorderSide(color: AppColors.borderLight)),
      boxShadow: [BoxShadow(color: Color(0x0A000000), offset: Offset(0,-2), blurRadius: 8)],
    ),
    child: SafeArea(top: false, child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _NavBtn(icon: Icons.home_outlined, activeIcon: Icons.home_rounded,
            label: 'Home', isActive: currentIndex == 0, onTap: () => context.go('/home')),
        _NavBtn(icon: Icons.list_alt_outlined, activeIcon: Icons.list_alt_rounded,
            label: 'Rapat', isActive: currentIndex == 1, onTap: () => context.go('/riwayat')),
        _CenterFab(onTap: () => context.push('/mulai-rapat')),
        _NavBtn(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded,
            label: 'Profil', isActive: currentIndex == 2, onTap: () => context.go('/profil')),
      ],
    )),
  );
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({required this.icon, required this.activeIcon, required this.label,
      required this.isActive, required this.onTap});
  final IconData icon, activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textTertiary;
    return GestureDetector(
      onTap: onTap, behavior: HitTestBehavior.opaque,
      child: SizedBox(width: 64, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(isActive ? activeIcon : icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption(c: color,
            w: isActive ? FontWeight.w600 : FontWeight.w400)),
      ])),
    );
  }
}

class _CenterFab extends StatelessWidget {
  const _CenterFab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 52, height: 52,
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient,
          shape: BoxShape.circle, boxShadow: AppShadows.buttonPrimary),
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
    ),
  );
}
