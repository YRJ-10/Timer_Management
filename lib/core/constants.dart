import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6200EE);
  static const Color secondary = Color(0xFFFFB84D);
  static const Color background = Color(0xFF121212); // Dark theme
  static const Color surface = Color(0xFF1E1E1E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color accent = Color(0xFFFF4081);
}

class AppStyles {
  static const TextStyle timerTextBig = TextStyle(
    fontSize: 80,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 2,
  );
  
  static const TextStyle timerTextMedium = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
}
