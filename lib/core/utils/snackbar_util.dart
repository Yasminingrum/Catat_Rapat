import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

abstract final class SnackbarUtil {
  static void showSuccess(BuildContext context, String message) =>
      _show(context, message, AppColors.success);

  static void showError(BuildContext context, String message) =>
      _show(context, message, AppColors.error);

  static void showInfo(BuildContext context, String message) =>
      _show(context, message, AppColors.primary);

  static void _show(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: AppTextStyles.bodyMd(c: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }
}
