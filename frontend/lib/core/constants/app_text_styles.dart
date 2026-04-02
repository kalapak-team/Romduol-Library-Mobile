import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // --- Display ---
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'NotoSerifKhmer',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
    height: 1.4,
  );

  // --- Headlines ---
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'NotoSerifKhmer',
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
    height: 1.4,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: 'NotoSansKhmer',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
    height: 1.4,
  );

  // --- Titles ---
  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'NotoSansKhmer',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
    height: 1.4,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'NotoSansKhmer',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
    height: 1.4,
  );

  // --- Additional sizes ---
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: 'NotoSansKhmer',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
    height: 1.4,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'NotoSerifKhmer',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
    height: 1.3,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: 'NotoSansKhmer',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
    letterSpacing: 0.4,
  );

  // --- Body ---
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'NotoSansKhmer',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textMid,
    height: 1.6,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'NotoSansKhmer',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textMid,
    height: 1.6,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'NotoSansKhmer',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textLight,
    height: 1.5,
  );

  // --- Labels ---
  static const TextStyle labelLarge = TextStyle(
    fontFamily: 'NotoSansKhmer',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'NotoSansKhmer',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textLight,
    letterSpacing: 0.3,
  );

  // --- Specific UI ---
  static const TextStyle buttonText = TextStyle(
    fontFamily: 'NotoSansKhmer',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static const TextStyle appBarTitle = TextStyle(
    fontFamily: 'NotoSerifKhmer',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: 'NotoSansKhmer',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
    height: 1.3,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'NotoSansKhmer',
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textLight,
  );
}
