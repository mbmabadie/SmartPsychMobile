// lib/shared/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App Theme Configuration - تكوين مظاهر التطبيق
class AppTheme {
  // ==========================================
  // Color Palette - لوحة الألوان
  // ==========================================

  // Primary Colors - الألوان الأساسية
  static const Color primaryColor = Color(0xFF6366F1); // Indigo
  static const Color primaryLight = Color(0xFF8B87FF);
  static const Color primaryDark = Color(0xFF4F46E5);

  // Secondary Colors - الألوان الثانوية
  static const Color secondaryColor = Color(0xFF10B981); // Emerald
  static const Color secondaryLight = Color(0xFF34D399);
  static const Color secondaryDark = Color(0xFF059669);

  // Accent Colors - الألوان المميزة
  static const Color accentColor = Color(0xFFF59E0B); // Amber
  static const Color accentLight = Color(0xFFFBBF24);
  static const Color accentDark = Color(0xFFD97706);

  // Health Category Colors - ألوان فئات الصحة
  static const Color sleepColor = Color(0xFF8B5CF6); // Purple
  static const Color activityColor = Color(0xFF06B6D4); // Cyan
  static const Color nutritionColor = Color(0xFF84CC16); // Lime
  static const Color phoneUsageColor = Color(0xFFEC4899); // Pink

  // Status Colors - ألوان الحالة
  static const Color successColor = Color(0xFF22C55E); // Green
  static const Color warningColor = Color(0xFFEAB308); // Yellow
  static const Color errorColor = Color(0xFFEF4444); // Red
  static const Color infoColor = Color(0xFF3B82F6); // Blue

  // Neutral Colors - الألوان المحايدة
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);

  // Dark Theme Colors - ألوان المظهر المظلم
  static const Color backgroundColorDark = Color(0xFF0F0F0F);
  static const Color surfaceColorDark = Color(0xFF1A1A1A);
  static const Color cardColorDark = Color(0xFF262626);

  // Text Colors - ألوان النص
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFFD1D5DB);

  // Border Colors - ألوان الحدود
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color borderColorDark = Color(0xFF374151);

  // ==========================================
  // Typography - الطباعة
  // ==========================================

  static const String primaryFontFamily = 'Cairo';
  static const String secondaryFontFamily = 'Inter';

  // Font Weights
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;

  // ==========================================
  // Spacing & Sizing - التباعد والأحجام
  // ==========================================

  // Spacing Scale
  static const double spacing2 = 2.0;
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  static const double spacing64 = 64.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  // Elevation
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;

  // ==========================================
  // Light Theme - المظهر الفاتح
  // ==========================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        primaryContainer: primaryLight,
        secondary: secondaryColor,
        secondaryContainer: secondaryLight,
        tertiary: accentColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
        outline: borderColor,
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontFamily: primaryFontFamily,
          fontSize: 20,
          fontWeight: semiBold,
          color: textPrimary,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: elevationLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing8,
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: elevationLow,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontFamily: primaryFontFamily,
            fontSize: 16,
            fontWeight: semiBold,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing16,
            vertical: spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: const TextStyle(
            fontFamily: primaryFontFamily,
            fontSize: 14,
            fontWeight: medium,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(
            horizontal: spacing20,
            vertical: spacing16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontFamily: primaryFontFamily,
            fontSize: 14,
            fontWeight: medium,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing16,
        ),
        labelStyle: const TextStyle(
          fontFamily: primaryFontFamily,
          fontSize: 14,
          color: textSecondary,
        ),
        hintStyle: const TextStyle(
          fontFamily: primaryFontFamily,
          fontSize: 14,
          color: textTertiary,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: elevationMedium,
        selectedLabelStyle: TextStyle(
          fontFamily: primaryFontFamily,
          fontSize: 12,
          fontWeight: medium,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: primaryFontFamily,
          fontSize: 12,
          fontWeight: regular,
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: elevationMedium,
        shape: CircleBorder(),
      ),

      // Text Theme
      textTheme: _buildTextTheme(Brightness.light),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: textSecondary,
        size: 24,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: backgroundColor,
        deleteIconColor: textSecondary,
        disabledColor: borderColor,
        selectedColor: primaryLight,
        secondarySelectedColor: secondaryLight,
        padding: const EdgeInsets.symmetric(
          horizontal: spacing12,
          vertical: spacing8,
        ),
        labelStyle: const TextStyle(
          fontFamily: primaryFontFamily,
          fontSize: 12,
          fontWeight: medium,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: primaryFontFamily,
          fontSize: 12,
          fontWeight: medium,
          color: Colors.white,
        ),
        brightness: Brightness.light,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        elevation: elevationHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: primaryFontFamily,
          fontSize: 20,
          fontWeight: semiBold,
          color: textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: primaryFontFamily,
          fontSize: 16,
          fontWeight: regular,
          color: textSecondary,
          height: 1.5,
        ),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryLight;
          }
          return Colors.grey.shade300;
        }),
      ),
    );
  }

  // ==========================================
  // Dark Theme - المظهر المظلم
  // ==========================================

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        primaryContainer: primaryDark,
        secondary: secondaryColor,
        secondaryContainer: secondaryDark,
        tertiary: accentColor,
        surface: surfaceColorDark,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryDark,
        onError: Colors.white,
        outline: borderColorDark,
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColorDark,
        foregroundColor: textPrimaryDark,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          fontFamily: primaryFontFamily,
          fontSize: 20,
          fontWeight: semiBold,
          color: textPrimaryDark,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: cardColorDark,
        elevation: elevationLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing8,
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: elevationLow,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontFamily: primaryFontFamily,
            fontSize: 16,
            fontWeight: semiBold,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing16,
            vertical: spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: const TextStyle(
            fontFamily: primaryFontFamily,
            fontSize: 14,
            fontWeight: medium,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColorDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: borderColorDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: borderColorDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing16,
        ),
        labelStyle: const TextStyle(
          fontFamily: primaryFontFamily,
          fontSize: 14,
          color: textSecondaryDark,
        ),
        hintStyle: TextStyle(
          fontFamily: primaryFontFamily,
          fontSize: 14,
          color: textSecondaryDark.withOpacity(0.7),
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColorDark,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: elevationMedium,
        selectedLabelStyle: TextStyle(
          fontFamily: primaryFontFamily,
          fontSize: 12,
          fontWeight: medium,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: primaryFontFamily,
          fontSize: 12,
          fontWeight: regular,
        ),
      ),

      // Text Theme
      textTheme: _buildTextTheme(Brightness.dark),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: borderColorDark,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: textSecondaryDark,
        size: 24,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColorDark,
        elevation: elevationHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: primaryFontFamily,
          fontSize: 20,
          fontWeight: semiBold,
          color: textPrimaryDark,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: primaryFontFamily,
          fontSize: 16,
          fontWeight: regular,
          color: textSecondaryDark,
          height: 1.5,
        ),
      ),
    );
  }

  // ==========================================
  // Text Theme Builder - بناء نظام النصوص
  // ==========================================

  static TextTheme _buildTextTheme(Brightness brightness) {
    final Color textColor = brightness == Brightness.light
        ? textPrimary
        : textPrimaryDark;
    final Color secondaryTextColor = brightness == Brightness.light
        ? textSecondary
        : textSecondaryDark;

    return TextTheme(
      // Display Styles
      displayLarge: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 32,
        fontWeight: bold,
        color: textColor,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 28,
        fontWeight: bold,
        color: textColor,
        height: 1.3,
      ),
      displaySmall: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 24,
        fontWeight: semiBold,
        color: textColor,
        height: 1.3,
      ),

      // Headline Styles
      headlineLarge: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 22,
        fontWeight: semiBold,
        color: textColor,
        height: 1.4,
      ),
      headlineMedium: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 20,
        fontWeight: semiBold,
        color: textColor,
        height: 1.4,
      ),
      headlineSmall: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 18,
        fontWeight: medium,
        color: textColor,
        height: 1.4,
      ),

      // Title Styles
      titleLarge: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 16,
        fontWeight: semiBold,
        color: textColor,
        height: 1.5,
      ),
      titleMedium: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 14,
        fontWeight: medium,
        color: textColor,
        height: 1.5,
      ),
      titleSmall: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 12,
        fontWeight: medium,
        color: secondaryTextColor,
        height: 1.5,
      ),

      // Body Styles
      bodyLarge: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 16,
        fontWeight: regular,
        color: textColor,
        height: 1.6,
      ),
      bodyMedium: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 14,
        fontWeight: regular,
        color: textColor,
        height: 1.6,
      ),
      bodySmall: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 12,
        fontWeight: regular,
        color: secondaryTextColor,
        height: 1.5,
      ),

      // Label Styles
      labelLarge: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 14,
        fontWeight: medium,
        color: textColor,
        height: 1.4,
      ),
      labelMedium: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 12,
        fontWeight: medium,
        color: secondaryTextColor,
        height: 1.4,
      ),
      labelSmall: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 10,
        fontWeight: medium,
        color: secondaryTextColor,
        height: 1.4,
      ),
    );
  }

  // ==========================================
  // Custom Colors - ألوان مخصصة
  // ==========================================

  /// الحصول على لون حسب فئة الصحة
  static Color getHealthCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'sleep':
        return sleepColor;
      case 'activity':
        return activityColor;
      case 'nutrition':
        return nutritionColor;
      case 'phone_usage':
        return phoneUsageColor;
      default:
        return primaryColor;
    }
  }

  /// الحصول على لون حسب نوع الحالة
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'good':
      case 'excellent':
        return successColor;
      case 'warning':
      case 'moderate':
        return warningColor;
      case 'error':
      case 'poor':
      case 'bad':
        return errorColor;
      case 'info':
      case 'neutral':
      default:
        return infoColor;
    }
  }

  /// الحصول على gradients مخصصة
  static LinearGradient getPrimaryGradient() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primaryColor, primaryDark],
    );
  }

  static LinearGradient getSecondaryGradient() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [secondaryColor, secondaryDark],
    );
  }

  static LinearGradient getHealthGradient(String category) {
    final color = getHealthCategoryColor(category);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [color, color.withOpacity(0.7)],
    );
  }
}

/// Theme Extensions - ملحقات المظاهر
extension ThemeExtension on BuildContext {
  /// الحصول على نظام الألوان الحالي
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// الحصول على نظام النصوص الحالي
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// فحص إذا كان المظهر مظلم
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// الحصول على لون النص الأساسي
  Color get primaryTextColor => isDarkMode
      ? AppTheme.textPrimaryDark
      : AppTheme.textPrimary;

  /// الحصول على لون النص الثانوي
  Color get secondaryTextColor => isDarkMode
      ? AppTheme.textSecondaryDark
      : AppTheme.textSecondary;

  /// الحصول على لون الخلفية
  Color get backgroundColor => isDarkMode
      ? AppTheme.backgroundColorDark
      : AppTheme.backgroundColor;

  /// الحصول على لون السطح
  Color get surfaceColor => isDarkMode
      ? AppTheme.surfaceColorDark
      : AppTheme.surfaceColor;

  /// الحصول على لون البطاقة
  Color get cardColor => isDarkMode
      ? AppTheme.cardColorDark
      : AppTheme.cardColor;

  /// الحصول على لون الحدود
  Color get borderColor => isDarkMode
      ? AppTheme.borderColorDark
      : AppTheme.borderColor;
}

/// Custom Text Styles - أنماط نصوص مخصصة
class AppTextStyles {
  // ==========================================
  // Custom Text Styles - أنماط مخصصة
  // ==========================================

  /// نمط نص للعناوين الكبيرة مع تدرج
  static TextStyle gradientTitle({
    double fontSize = 24,
    FontWeight fontWeight = AppTheme.bold,
    required BuildContext context,
  }) {
    return TextStyle(
      fontFamily: AppTheme.primaryFontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      foreground: Paint()
        ..shader = AppTheme.getPrimaryGradient().createShader(
          const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
        ),
    );
  }

  /// نمط نص للأرقام الكبيرة
  static TextStyle bigNumber({
    Color? color,
    double fontSize = 32,
    FontWeight fontWeight = AppTheme.extraBold,
  }) {
    return TextStyle(
      fontFamily: AppTheme.secondaryFontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? AppTheme.primaryColor,
      letterSpacing: -1.0,
    );
  }

  /// نمط نص للتسميات الصغيرة
  static TextStyle caption({
    Color? color,
    double fontSize = 12,
    FontWeight fontWeight = AppTheme.medium,
  }) {
    return TextStyle(
      fontFamily: AppTheme.primaryFontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? AppTheme.textSecondary,
      letterSpacing: 0.5,
    );
  }

  /// نمط نص للحالة (نجاح، تحذير، خطأ)
  static TextStyle status(String status, {double fontSize = 14}) {
    return TextStyle(
      fontFamily: AppTheme.primaryFontFamily,
      fontSize: fontSize,
      fontWeight: AppTheme.semiBold,
      color: AppTheme.getStatusColor(status),
    );
  }
}

/// Custom Decorations - زخارف مخصصة
class AppDecorations {
  // ==========================================
  // Box Decorations - زخارف الصناديق
  // ==========================================

  /// زخرفة بطاقة أساسية
  static BoxDecoration card({
    Color? color,
    bool isDark = false,
    double radius = AppTheme.radiusMedium,
    double elevation = AppTheme.elevationLow,
  }) {
    return BoxDecoration(
      color: color ?? (isDark ? AppTheme.cardColorDark : AppTheme.cardColor),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
          blurRadius: elevation * 2,
          offset: Offset(0, elevation),
        ),
      ],
    );
  }

  /// زخرفة مع تدرج
  static BoxDecoration gradient({
    required Gradient gradient,
    double radius = AppTheme.radiusMedium,
  }) {
    return BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  /// زخرفة حدود
  static BoxDecoration bordered({
    Color? borderColor,
    Color? backgroundColor,
    bool isDark = false,
    double radius = AppTheme.radiusMedium,
    double borderWidth = 1.0,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? (isDark ? AppTheme.cardColorDark : AppTheme.cardColor),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? (isDark ? AppTheme.borderColorDark : AppTheme.borderColor),
        width: borderWidth,
      ),
    );
  }

  /// زخرفة للحالات الخاصة
  static BoxDecoration status(String status, {
    double radius = AppTheme.radiusSmall,
    double opacity = 0.1,
  }) {
    final color = AppTheme.getStatusColor(status);
    return BoxDecoration(
      color: color.withOpacity(opacity),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: color.withOpacity(0.3),
        width: 1,
      ),
    );
  }
}

/// Animation Curves and Durations - منحنيات ومدد الرسوم المتحركة
class AppAnimations {
  // ==========================================
  // Animation Durations - مدد الرسوم المتحركة
  // ==========================================

  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);

  // ==========================================
  // Animation Curves - منحنيات الرسوم المتحركة
  // ==========================================

  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve bounce = Curves.bounceOut;
  static const Curve elastic = Curves.elasticOut;

  // ==========================================
  // Custom Curves - منحنيات مخصصة
  // ==========================================

  static const Curve smoothCurve = Curves.fastOutSlowIn;
  static const Curve sharpCurve = Curves.easeInOutCubic;
}

/// Responsive Design Helpers - مساعدات التصميم المتجاوب
class AppResponsive {
  // ==========================================
  // Breakpoints - نقاط الكسر
  // ==========================================

  static const double mobileBreakpoint = 768;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  // ==========================================
  // Screen Type Detection - كشف نوع الشاشة
  // ==========================================

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  // ==========================================
  // Responsive Values - قيم متجاوبة
  // ==========================================

  static double getResponsivePadding(BuildContext context) {
    if (isMobile(context)) return AppTheme.spacing16;
    if (isTablet(context)) return AppTheme.spacing24;
    return AppTheme.spacing32;
  }

  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    if (isMobile(context)) return baseFontSize;
    if (isTablet(context)) return baseFontSize * 1.1;
    return baseFontSize * 1.2;
  }

  static int getCrossAxisCount(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    return 3;
  }
}

/// Health Category Types - أنواع فئات الصحة
enum HealthCategory {
  sleep,
  activity,
  nutrition,
  phoneUsage,
}

/// Status Types - أنواع الحالة
enum StatusType {
  success,
  warning,
  error,
  info,
  neutral,
}