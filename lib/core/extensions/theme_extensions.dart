import 'package:flutter/material.dart';
import '../style/app_colors.dart';

extension ThemeContext on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  
  List<Color> get scaffoldGradient => isDarkMode
      ? [AppColors.darkScaffoldStart, AppColors.darkScaffoldMid, AppColors.darkScaffoldEnd]
      : [AppColors.lightScaffoldStart, AppColors.lightScaffoldEnd];
      
  Color get cardBg => isDarkMode ? AppColors.darkCardBg : AppColors.lightCardBg;
  
  Color get cardBorder => isDarkMode ? AppColors.darkCardBorder : AppColors.lightCardBorder;
  
  Color get textPrimary => isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  
  Color get textSecondary => isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  
  Color get textHint => isDarkMode ? AppColors.darkTextHint : AppColors.lightTextHint;
  
  Color get accentPrimary => isDarkMode ? AppColors.darkAccentPrimary : AppColors.lightAccentPrimary;
  
  Color get accentSecondary => isDarkMode ? AppColors.darkAccentSecondary : AppColors.lightAccentSecondary;
  
  Color get accentGreen => isDarkMode ? AppColors.darkAccentGreen : AppColors.lightAccentGreen;
  
  Color get appBarBg => isDarkMode ? AppColors.darkScaffoldStart.withOpacity(0.8) : AppColors.lightScaffoldStart.withOpacity(0.8);
  
  Color get dialogBg => isDarkMode ? AppColors.darkCardBg : AppColors.lightCardBg;
  
  Color get dividerColor => isDarkMode ? AppColors.darkDivider : AppColors.lightDivider;
}