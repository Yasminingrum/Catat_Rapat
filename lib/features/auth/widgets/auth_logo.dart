import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';

class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: 64, height: 64,
    decoration: const BoxDecoration(gradient: AppColors.primaryGradient,
        borderRadius: AppRadius.lg, boxShadow: AppShadows.buttonPrimary),
    child: Center(child: Text('CR', style: AppTextStyles.displayMd(c: Colors.white, w: FontWeight.w800))),
  );
}
