import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary, primaryContainer: AppColors.primaryLight,
      surface: AppColors.surface, error: AppColors.error,
      onPrimary: Colors.white, onSurface: AppColors.textPrimary,
    ),
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Inter',
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface, elevation: 0, scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: AppTextStyles.displayMd(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: const OutlineInputBorder(borderRadius: AppRadius.md, borderSide: BorderSide(color: AppColors.borderMedium)),
      enabledBorder: const OutlineInputBorder(borderRadius: AppRadius.md, borderSide: BorderSide(color: AppColors.borderMedium)),
      focusedBorder: const OutlineInputBorder(borderRadius: AppRadius.md, borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
      errorBorder: const OutlineInputBorder(borderRadius: AppRadius.md, borderSide: BorderSide(color: AppColors.error)),
      hintStyle: AppTextStyles.bodyMd(c: AppColors.textDisabled),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary, foregroundColor: Colors.white,
      elevation: 0, shadowColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
      textStyle: AppTextStyles.displayXs(c: Colors.white, w: FontWeight.w600),
    )),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.textPrimary,
      side: const BorderSide(color: AppColors.borderMedium),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
    )),
    dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1, space: 1),
  );
}
