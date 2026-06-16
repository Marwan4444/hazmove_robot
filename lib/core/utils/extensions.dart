import 'package:flutter/material.dart';

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

extension DoubleExtension on double {
  double clampTo(double min, double max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }
}

extension IntExtension on int {
  int clampTo(int min, int max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }
}

extension ColorExtension on Color {
  Color withOpacity(double opacity) {
    return Color.fromARGB(
      (opacity * 255).round(),
      red,
      green,
      blue,
    );
  }
}

extension ContextExtension on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  
  void showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Theme.of(this).colorScheme.primary,
      ),
    );
  }
  
  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }
}
