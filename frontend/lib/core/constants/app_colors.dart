import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // --- Angkor Sunset Palette ---
  static const Color primary = Color(0xFFC8502A);
  static const Color primaryDark = Color(0xFF9E3B1A);
  static const Color accent = Color(0xFFE8A44A);
  static const Color accentLight = Color(0xFFF5D08C);
  static const Color background = Color(0xFFFDF6EE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFFFF9F2);
  static const Color textDark = Color(0xFF2C1A0E);
  static const Color textMid = Color(0xFF5C3D2E);
  static const Color textLight = Color(0xFF9C7A6B);
  static const Color border = Color(0xFFE8D5C4);
  static const Color success = Color(0xFF4CAF82);
  static const Color error = Color(0xFFD94F4F);
  static const Color info = Color(0xFF4A7FC1);

  // Derived / utility
  static const Color primaryWithOpacity12 = Color(0x1FC8502A);
  static const Color shadowColor = Color(0x14000000);
  static const Color divider = Color(0xFFEADDD2);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient coverGradient = LinearGradient(
    colors: [Colors.transparent, Color(0xCC2C1A0E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
