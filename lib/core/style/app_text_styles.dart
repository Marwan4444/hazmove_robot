import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ─── AppBar ───
  static TextStyle appBarTitle({required bool isDark}) => TextStyle(
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      );

  // ─── Section Titles ───
  static TextStyle sectionTitle({required Color accentColor}) => TextStyle(
        color: accentColor,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      );

  // ─── Body ───
  static TextStyle body({required bool isDark}) => TextStyle(
        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        fontSize: 16,
      );

  // ─── Caption ───
  static TextStyle caption({required bool isDark}) => TextStyle(
        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        fontSize: 11,
      );

  // ─── Button ───
  static const TextStyle buttonBold = TextStyle(
    fontWeight: FontWeight.bold,
  );
}
