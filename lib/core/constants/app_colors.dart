import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary
  static const primary       = Color(0xFF4F46E5);
  static const primaryLight  = Color(0xFFEEF2FF);
  static const primaryBorder = Color(0xFF818CF8);

  // Semantic
  static const success      = Color(0xFF10B981);
  static const successLight = Color(0xFFECFDF5);
  static const warning      = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFEF3C7);
  static const error        = Color(0xFFEF4444);
  static const errorLight   = Color(0xFFFEE2E2);

  // Neutral
  static const background    = Color(0xFFF8FAFC);
  static const surface       = Color(0xFFFFFFFF);
  static const borderLight   = Color(0x0F0F172A);
  static const borderMedium  = Color(0x1E0F172A);
  static const textPrimary   = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textTertiary  = Color(0xFF94A3B8);
  static const textDisabled  = Color(0xFFCBD5E1);
  static const divider       = Color(0xFFE2E8F0);

  // Speaker
  static const speaker1   = Color(0xFF4F46E5);
  static const speaker1Bg = Color(0xFFEEF2FF);
  static const speaker2   = Color(0xFF8B5CF6);
  static const speaker2Bg = Color(0xFFF5F3FF);
  static const speaker3   = Color(0xFF10B981);
  static const speaker3Bg = Color(0xFFECFDF5);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
  );
  static const LinearGradient quickActionGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
  );

  static Color speakerColor(int index) =>
      [speaker1, speaker2, speaker3][index.clamp(0, 2)];
  static Color speakerBg(int index) =>
      [speaker1Bg, speaker2Bg, speaker3Bg][index.clamp(0, 2)];
}
