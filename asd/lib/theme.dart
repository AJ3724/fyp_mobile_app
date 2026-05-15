import 'package:flutter/material.dart';

class AppColors {
  static const Color primary      = Color(0xFF0A4A2A);
  static const Color medium       = Color(0xFF1A7A44);
  static const Color light        = Color(0xFF2ECC71);
  static const Color pale         = Color(0xFF6EE0A0);
  static const Color lightest     = Color(0xFFA8D5B8);

  static const Color background   = Color(0xFFF4F7F5);
  static const Color surface      = Color(0xFFFFFFFF);
  static const Color surfaceAlt   = Color(0xFFEAF5EE);
  static const Color border       = Color(0xFFD0E8D8);

  static const Color textPrimary  = Color(0xFF0A2E1A);
  static const Color textSub      = Color(0xFF3A6B4A);
  static const Color textMuted    = Color(0xFF7AAA8A);

  static const Color goodBg       = Color(0xFFD6F0E0);
  static const Color goodText     = Color(0xFF0A4A2A);
  static const Color acceptBg     = Color(0xFFFFF8DC);
  static const Color acceptText   = Color(0xFF6B4D00);
  static const Color dangerBg     = Color(0xFFFFF3E0);
  static const Color dangerText   = Color(0xFF7A4000);
  static const Color dangerColor  = Color(0xFFFF8C00);
  static const Color spoiledBg    = Color(0xFFFFEAEA);
  static const Color spoiledText  = Color(0xFF7A0000);
  static const Color spoiledColor = Color(0xFFE53935);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      surface: AppColors.surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.lightest,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontSize: 10),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
    ),
  );
}