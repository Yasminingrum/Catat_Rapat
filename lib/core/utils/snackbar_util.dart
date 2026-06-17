import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

abstract final class SnackbarUtil {
  static void showSuccess(BuildContext context, String message) =>
      _showOnMessenger(ScaffoldMessenger.of(context), message, AppColors.success);

  static void showError(BuildContext context, String message) =>
      _showOnMessenger(ScaffoldMessenger.of(context), message, AppColors.error);

  static void showInfo(BuildContext context, String message) =>
      _showOnMessenger(ScaffoldMessenger.of(context), message, AppColors.primary);

  // Pakai setelah `await` — capture messenger sebelum async, lalu panggil ini.
  static void showSuccessOnMessenger(ScaffoldMessengerState m, String message) =>
      _showOnMessenger(m, message, AppColors.success);

  static void showErrorOnMessenger(ScaffoldMessengerState m, String message) =>
      _showOnMessenger(m, message, AppColors.error);

  static void showInfoOnMessenger(ScaffoldMessengerState m, String message) =>
      _showOnMessenger(m, message, AppColors.primary);

  static void _showOnMessenger(ScaffoldMessengerState messenger, String message, Color color) {
    messenger.showSnackBar(SnackBar(
      content: Text(message, style: AppTextStyles.bodyMd(c: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }
}
