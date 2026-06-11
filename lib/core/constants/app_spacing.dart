import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 24.0;
  static const double xxl  = 32.0;
  static const double xxxl = 40.0;
  static const double xxxxl = 48.0;
  static const double bottomSafe = 96.0;
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 24);
  static const EdgeInsets cardPadding   = EdgeInsets.all(16);
}

abstract final class AppRadius {
  static const BorderRadius sm   = BorderRadius.all(Radius.circular(8));
  static const BorderRadius md   = BorderRadius.all(Radius.circular(12));
  static const BorderRadius lg   = BorderRadius.all(Radius.circular(16));
  static const BorderRadius xl   = BorderRadius.all(Radius.circular(24));
  static const BorderRadius full = BorderRadius.all(Radius.circular(9999));
}

abstract final class AppShadows {
  static const List<BoxShadow> sm = [BoxShadow(color: Color(0x0D000000), offset: Offset(0,1), blurRadius: 2)];
  static const List<BoxShadow> md = [BoxShadow(color: Color(0x1A000000), offset: Offset(0,4), blurRadius: 6)];
  static const List<BoxShadow> buttonPrimary = [BoxShadow(color: Color(0x4D4F46E5), offset: Offset(0,4), blurRadius: 16)];
  static const List<BoxShadow> buttonSuccess = [BoxShadow(color: Color(0x4D10B981), offset: Offset(0,6), blurRadius: 20)];
  static const List<BoxShadow> card = [BoxShadow(color: Color(0x0F000000), offset: Offset(0,1), blurRadius: 3)];
}
