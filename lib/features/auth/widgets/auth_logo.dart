import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: 72, height: 72,
    padding: const EdgeInsets.all(10),
    decoration: const BoxDecoration(color: AppColors.surface,
        borderRadius: AppRadius.lg, boxShadow: AppShadows.card),
    child: Image.asset('assets/images/catatrapat_icon_indigo.png'),
  );
}
