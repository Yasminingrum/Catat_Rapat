import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  // Display (Plus Jakarta Sans)
  static TextStyle displayXl({Color c = AppColors.textPrimary, FontWeight w = FontWeight.w800}) =>
      TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 48, fontWeight: w, color: c, height: 1.25, letterSpacing: -0.5);
  static TextStyle displayLg({Color c = AppColors.textPrimary, FontWeight w = FontWeight.w700}) =>
      TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 24, fontWeight: w, color: c, height: 1.25);
  static TextStyle displayMd({Color c = AppColors.textPrimary, FontWeight w = FontWeight.w700}) =>
      TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 20, fontWeight: w, color: c, height: 1.3);
  static TextStyle displaySm({Color c = AppColors.textPrimary, FontWeight w = FontWeight.w700}) =>
      TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 18, fontWeight: w, color: c, height: 1.3);
  static TextStyle displayXs({Color c = AppColors.textPrimary, FontWeight w = FontWeight.w600}) =>
      TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 16, fontWeight: w, color: c, height: 1.4);

  // Body (Inter)
  static TextStyle bodyLg({Color c = AppColors.textPrimary, FontWeight w = FontWeight.w400}) =>
      TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: w, color: c, height: 1.5);
  static TextStyle bodyMd({Color c = AppColors.textPrimary, FontWeight w = FontWeight.w400}) =>
      TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: w, color: c, height: 1.5);
  static TextStyle bodySm({Color c = AppColors.textPrimary, FontWeight w = FontWeight.w400}) =>
      TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: w, color: c, height: 1.5);
  static TextStyle label({Color c = AppColors.textSecondary, FontWeight w = FontWeight.w600}) =>
      TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: w, color: c, letterSpacing: 0.8);
  static TextStyle caption({Color c = AppColors.textTertiary, FontWeight w = FontWeight.w400}) =>
      TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: w, color: c);
}
