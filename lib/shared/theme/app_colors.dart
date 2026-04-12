// lib/shared/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Colors - الألوان الأساسية الجديدة
  static const Color primary = Color(0xFF1197CC);        // اللون الأساسي الجديد
  static const Color primaryVariant = Color(0xFF28A1D1); // درجة أفتح
  static const Color primaryLight = Color(0xFF56B5DB);    // درجة أفتح أكثر
  static const Color primarySurface = Color(0xFFDDF0F8);  // سطح فاتح جداً

  // الألوان الثانوية (الأصفر يبقى كما هو للتباين)
  static const Color secondary = Color(0xFFFFC800);      // أصفر ذهبي
  static const Color accent = Color(0xFF011F37);         // أزرق غامق

  // Status Colors - ألوان الحالة
  static const Color success = Color(0xFF4CAF50);        // أخضر للنجاح
  static const Color warning = Color(0xFFFF9800);        // برتقالي للتحذير
  static const Color error = Color(0xFFE53E3E);          // أحمر للخطأ
  static const Color info = Color(0xFF28A1D1);           // الأزرق الجديد للمعلومات

  // Background Colors - ألوان الخلفية
  static const Color backgroundLight = Color(0xFFFAFAFA); // خلفية فاتحة
  static const Color backgroundDark = Color(0xFF011F37);  // خلفية غامقة

  // Surface Colors - ألوان السطوح
  static const Color surface = Color(0xFFFFFFFF);         // سطح أبيض
  static const Color surfaceLight = Color(0xFFDDF0F8);    // سطح فاتح جديد
  static const Color surfaceDark = Color(0xFF1E1E1E);     // سطح غامق
  static const Color onSurfaceLight = Color(0xFF1197CC);  // نص على سطح فاتح
  static const Color onSurfaceDark = Color(0xFFDDF0F8);   // نص على سطح غامق

  // Text Colors - ألوان النص
  static const Color textPrimary = Color(0xFF212121);     // نص أساسي
  static const Color textSecondary = Color(0xFF757575);   // نص ثانوي
  static const Color textLight = Color(0xFFFFFFFF);       // نص فاتح
  static const Color textDark = Color(0xFF000000);        // نص غامق
  static const Color textMuted = Color(0xFF9E9E9E);       // نص باهت
  static const Color textOnPrimary = Color(0xFFFFFFFF);   // نص على اللون الأساسي

  // Border Colors - ألوان الحدود
  static const Color border = Color(0xFFE0E0E0);          // حدود عادية
  static const Color borderLight = Color(0xFFDDF0F8);     // حدود فاتحة جديدة
  static const Color borderPrimary = Color(0xFF56B5DB);   // حدود بالأزرق الجديد
  static const Color borderDark = Color(0xFF424242);      // حدود غامقة
  static const Color divider = Color(0xFFDDF0F8);         // خط فاصل جديد

  // Shadow Colors - ألوان الظلال
  static const Color shadowLight = Color(0x1A1197CC);     // ظل فاتح بالأزرق الجديد
  static const Color shadowDark = Color(0x4D1197CC);      // ظل غامق بالأزرق الجديد

  // Card Colors - ألوان البطاقات
  static const Color card = Color(0xFFFFFFFF);            // بطاقة أساسية
  static const Color cardLight = Color(0xFFDDF0F8);       // بطاقة فاتحة جديدة
  static const Color cardDark = Color(0xFF2D2D2D);        // بطاقة غامقة
  static const Color cardElevated = Color(0xFFFFFBFF);    // بطاقة مرفوعة

  // Input Colors - ألوان الإدخال
  static const Color inputFill = Color(0xFFDDF0F8);       // خلفية إدخال جديدة
  static const Color inputFillLight = Color(0xFFDDF0F8);  // خلفية إدخال فاتحة
  static const Color inputFillDark = Color(0xFF3D3D3D);   // خلفية إدخال غامقة
  static const Color inputBorder = Color(0xFF56B5DB);     // حدود إدخال جديدة
  static const Color inputFocused = Color(0xFF1197CC);    // إدخال مُركز عليه

  // Activity Colors - ألوان الأنشطة (محدثة بالدرجات الجديدة)
  static const Color walking = Color(0xFF56B5DB);         // مشي
  static const Color running = Color(0xFF28A1D1);         // جري
  static const Color cycling = Color(0xFF1197CC);         // دراجة
  static const Color swimming = Color(0xFFDDF0F8);        // سباحة
  static const Color workout = Color(0xFF56B5DB);         // تمرين

  // Nutrition Colors - ألوان التغذية (بعضها محدث)
  static const Color protein = Color(0xFF28A1D1);         // بروتين
  static const Color carbs = Color(0xFFFF9800);           // كربوهيدرات
  static const Color fat = Color(0xFFFFC107);             // دهون
  static const Color fiber = Color(0xFF56B5DB);           // ألياف
  static const Color water = Color(0xFF1197CC);           // ماء

  // Health Colors - ألوان الصحة (محدثة)
  static const Color heartRate = Color(0xFF28A1D1);       // معدل القلب
  static const Color bloodPressure = Color(0xFF1197CC);   // ضغط الدم
  static const Color temperature = Color(0xFF56B5DB);     // درجة الحرارة
  static const Color weight = Color(0xFF795548);          // الوزن

  // Mood Colors - ألوان المزاج (محدثة)
  static const Color calm = Color(0xFFDDF0F8);            // هادئ
  static const Color energy = Color(0xFF28A1D1);          // نشط
  static const Color focus = Color(0xFF1197CC);           // تركيز
  static const Color rest = Color(0xFF56B5DB);            // راحة

  // الألوان مع درجات الشفافية
  static Color get primaryWithOpacity10 => primary.withOpacity(0.1);
  static Color get primaryWithOpacity20 => primary.withOpacity(0.2);
  static Color get primaryWithOpacity30 => primary.withOpacity(0.3);
  static Color get primaryWithOpacity50 => primary.withOpacity(0.5);
  static Color get primaryWithOpacity70 => primary.withOpacity(0.7);
  static Color get primaryWithOpacity90 => primary.withOpacity(0.9);

  static Color get primaryVariantWithOpacity10 => primaryVariant.withOpacity(0.1);
  static Color get primaryVariantWithOpacity20 => primaryVariant.withOpacity(0.2);
  static Color get primaryVariantWithOpacity30 => primaryVariant.withOpacity(0.3);
  static Color get primaryVariantWithOpacity50 => primaryVariant.withOpacity(0.5);
  static Color get primaryVariantWithOpacity70 => primaryVariant.withOpacity(0.7);
  static Color get primaryVariantWithOpacity90 => primaryVariant.withOpacity(0.9);

  static Color get primaryLightWithOpacity10 => primaryLight.withOpacity(0.1);
  static Color get primaryLightWithOpacity20 => primaryLight.withOpacity(0.2);
  static Color get primaryLightWithOpacity30 => primaryLight.withOpacity(0.3);
  static Color get primaryLightWithOpacity50 => primaryLight.withOpacity(0.5);
  static Color get primaryLightWithOpacity70 => primaryLight.withOpacity(0.7);
  static Color get primaryLightWithOpacity90 => primaryLight.withOpacity(0.9);

  static Color get primarySurfaceWithOpacity10 => primarySurface.withOpacity(0.1);
  static Color get primarySurfaceWithOpacity20 => primarySurface.withOpacity(0.2);
  static Color get primarySurfaceWithOpacity30 => primarySurface.withOpacity(0.3);
  static Color get primarySurfaceWithOpacity50 => primarySurface.withOpacity(0.5);
  static Color get primarySurfaceWithOpacity70 => primarySurface.withOpacity(0.7);
  static Color get primarySurfaceWithOpacity90 => primarySurface.withOpacity(0.9);

  // Utility Methods - الطرق المساعدة

  /// Get activity color by type
  static Color getActivityColor(String activityType) {
    switch (activityType.toLowerCase()) {
      case 'walking':
        return walking;
      case 'running':
        return running;
      case 'cycling':
        return cycling;
      case 'swimming':
        return swimming;
      case 'workout':
        return workout;
      default:
        return primary;
    }
  }

  /// Get nutrition color by type
  static Color getNutritionColor(String nutritionType) {
    switch (nutritionType.toLowerCase()) {
      case 'protein':
        return protein;
      case 'carbs':
      case 'carbohydrates':
        return carbs;
      case 'fat':
      case 'fats':
        return fat;
      case 'fiber':
        return fiber;
      case 'water':
        return water;
      default:
        return primary;
    }
  }

  /// Get health color by type
  static Color getHealthColor(String healthType) {
    switch (healthType.toLowerCase()) {
      case 'heart_rate':
      case 'heartrate':
        return heartRate;
      case 'blood_pressure':
      case 'bloodpressure':
        return bloodPressure;
      case 'temperature':
        return temperature;
      case 'weight':
        return weight;
      default:
        return info;
    }
  }

  /// Get mood color by type
  static Color getMoodColor(String moodType) {
    switch (moodType.toLowerCase()) {
      case 'calm':
      case 'relaxed':
        return calm;
      case 'energy':
      case 'energetic':
        return energy;
      case 'focus':
      case 'focused':
        return focus;
      case 'rest':
      case 'tired':
        return rest;
      default:
        return primary;
    }
  }

  /// Create color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  /// Get primary color with specific opacity
  static Color getPrimaryWithOpacity(double opacity) {
    return primary.withOpacity(opacity.clamp(0.0, 1.0));
  }

  /// Get primary variant with specific opacity
  static Color getPrimaryVariantWithOpacity(double opacity) {
    return primaryVariant.withOpacity(opacity.clamp(0.0, 1.0));
  }

  /// Get primary light with specific opacity
  static Color getPrimaryLightWithOpacity(double opacity) {
    return primaryLight.withOpacity(opacity.clamp(0.0, 1.0));
  }

  /// Get primary surface with specific opacity
  static Color getPrimarySurfaceWithOpacity(double opacity) {
    return primarySurface.withOpacity(opacity.clamp(0.0, 1.0));
  }

  /// Lighten a color
  static Color lighten(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Darken a color
  static Color darken(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Check if color is light or dark
  static bool isLightColor(Color color) {
    return color.computeLuminance() > 0.5;
  }

  /// Get contrasting text color
  static Color getContrastingTextColor(Color backgroundColor) {
    return isLightColor(backgroundColor) ? textDark : textLight;
  }
}