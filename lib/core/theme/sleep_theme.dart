// lib/core/theme/sleep_theme.dart

import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';

class SleepColors {
  // استخدام ألوان التطبيق الموحدة
  static const Color primary = AppColors.primary;              // #1197CC
  static const Color primaryLight = AppColors.primaryLight;    // #56B5DB
  static const Color primaryVariant = AppColors.primaryVariant;// #28A1D1
  static const Color primarySurface = AppColors.primarySurface;// #DDF0F8

  // Status Colors
  static const Color success = AppColors.success;
  static const Color warning = AppColors.warning;
  static const Color error = AppColors.error;
  static const Color info = AppColors.info;

  // Background Colors
  static const Color background = AppColors.backgroundLight;
  static const Color card = AppColors.card;
  static const Color cardLight = AppColors.cardLight;
  static const Color cardDark = AppColors.cardDark;

  // Text Colors
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;
  static const Color textHint = AppColors.textMuted;
  static const Color textLight = AppColors.textLight;

  // Sleep Phase Colors - بدرجات الأزرق الموحدة
  static const Color deepSleep = AppColors.primary;        // #1197CC
  static const Color lightSleep = AppColors.primaryLight;   // #56B5DB
  static const Color awake = AppColors.warning;             // #FF9800
  static const Color rem = AppColors.primaryVariant;        // #28A1D1

  // Environment Quality Colors
  static const Color qualityExcellent = AppColors.success;
  static const Color qualityGood = AppColors.info;
  static const Color qualityFair = AppColors.warning;
  static const Color qualityPoor = AppColors.error;

  // Gradients - بالألوان الموحدة
  static const LinearGradient sleepingGradient = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient awakeGradient = LinearGradient(
    colors: [AppColors.warning, AppColors.secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient qualityGradient = LinearGradient(
    colors: [AppColors.success, AppColors.info],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Helper Methods
  static Color getPrimaryWithOpacity(double opacity) {
    return AppColors.getPrimaryWithOpacity(opacity);
  }

  static Color lighten(Color color, [double amount = 0.1]) {
    return AppColors.lighten(color, amount);
  }

  static Color darken(Color color, [double amount = 0.1]) {
    return AppColors.darken(color, amount);
  }
}

class SleepTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Tajawal',

      colorScheme: ColorScheme.light(
        primary: SleepColors.primary,
        secondary: SleepColors.info,
        background: SleepColors.background,
        surface: SleepColors.card,
        error: SleepColors.error,
        onPrimary: AppColors.textLight,
        onSecondary: AppColors.textLight,
        onBackground: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
      ),

      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: SleepColors.card,
      ),

      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: SleepColors.background,
        foregroundColor: SleepColors.textPrimary,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: SleepColors.textPrimary,
        ),
      ),

      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: SleepColors.textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: SleepColors.textPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: SleepColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: SleepColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: SleepColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: SleepColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: SleepColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SleepColors.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SleepColors.primary,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: SleepColors.primary, width: 2),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: SleepColors.primary,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: SleepColors.primarySurface,
        selectedColor: SleepColors.primary,
        disabledColor: SleepColors.textHint.withOpacity(0.1),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: TextStyle(fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: SleepColors.primary,
        inactiveTrackColor: SleepColors.primarySurface,
        thumbColor: SleepColors.primary,
        overlayColor: SleepColors.getPrimaryWithOpacity(0.2),
        trackHeight: 4,
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Tajawal',

      colorScheme: ColorScheme.dark(
        primary: SleepColors.primaryLight,
        secondary: SleepColors.info,
        background: AppColors.backgroundDark,
        surface: SleepColors.cardDark,
        error: SleepColors.error,
      ),

      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: SleepColors.cardDark,
      ),

      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: Colors.white,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}