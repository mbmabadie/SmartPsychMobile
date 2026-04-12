// lib/core/services/user_settings_service.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSettingsService {
  static final UserSettingsService _instance = UserSettingsService._internal();
  factory UserSettingsService() => _instance;
  UserSettingsService._internal();

  static UserSettingsService get instance => _instance;

  // ════════════════════════════════════════════════════════════
  // الأهداف الافتراضية (Default Goals)
  // ════════════════════════════════════════════════════════════

  static const int defaultStepsGoal = 10000;
  static const double defaultDistanceGoal = 8.0;
  static const double defaultCaloriesGoal = 500.0;
  static const int defaultActiveMinutesGoal = 30;

  // ════════════════════════════════════════════════════════════
  // مفاتيح الحفظ (Storage Keys)
  // ════════════════════════════════════════════════════════════

  static const String _keyStepsGoal = 'user_steps_goal';
  static const String _keyDistanceGoal = 'user_distance_goal';
  static const String _keyCaloriesGoal = 'user_calories_goal';
  static const String _keyActiveMinutesGoal = 'user_active_minutes_goal';

  // ════════════════════════════════════════════════════════════
  // قراءة الأهداف (Get Goals)
  // ════════════════════════════════════════════════════════════

  Future<int> getStepsGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyStepsGoal) ?? defaultStepsGoal;
    } catch (e) {
      debugPrint('❌ خطأ في قراءة هدف الخطوات: $e');
      return defaultStepsGoal;
    }
  }

  Future<double> getDistanceGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_keyDistanceGoal) ?? defaultDistanceGoal;
    } catch (e) {
      debugPrint('❌ خطأ في قراءة هدف المسافة: $e');
      return defaultDistanceGoal;
    }
  }

  Future<double> getCaloriesGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_keyCaloriesGoal) ?? defaultCaloriesGoal;
    } catch (e) {
      debugPrint('❌ خطأ في قراءة هدف السعرات: $e');
      return defaultCaloriesGoal;
    }
  }

  Future<int> getActiveMinutesGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyActiveMinutesGoal) ?? defaultActiveMinutesGoal;
    } catch (e) {
      debugPrint('❌ خطأ في قراءة هدف الدقائق النشطة: $e');
      return defaultActiveMinutesGoal;
    }
  }

  /// قراءة جميع الأهداف دفعة واحدة
  Future<Map<String, dynamic>> getAllGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'steps': prefs.getInt(_keyStepsGoal) ?? defaultStepsGoal,
        'distance': prefs.getDouble(_keyDistanceGoal) ?? defaultDistanceGoal,
        'calories': prefs.getDouble(_keyCaloriesGoal) ?? defaultCaloriesGoal,
        'active_minutes': prefs.getInt(_keyActiveMinutesGoal) ?? defaultActiveMinutesGoal,
      };
    } catch (e) {
      debugPrint('❌ خطأ في قراءة الأهداف: $e');
      return {
        'steps': defaultStepsGoal,
        'distance': defaultDistanceGoal,
        'calories': defaultCaloriesGoal,
        'active_minutes': defaultActiveMinutesGoal,
      };
    }
  }

  // ════════════════════════════════════════════════════════════
  // حفظ الأهداف (Save Goals)
  // ════════════════════════════════════════════════════════════

  Future<bool> setStepsGoal(int steps) async {
    try {
      if (steps < 1000 || steps > 100000) {
        debugPrint('⚠️ هدف الخطوات خارج النطاق المسموح: $steps');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setInt(_keyStepsGoal, steps);

      if (success) {
        debugPrint('✅ تم حفظ هدف الخطوات: $steps');
      }

      return success;
    } catch (e) {
      debugPrint('❌ خطأ في حفظ هدف الخطوات: $e');
      return false;
    }
  }

  Future<bool> setDistanceGoal(double distance) async {
    try {
      if (distance < 0.5 || distance > 100) {
        debugPrint('⚠️ هدف المسافة خارج النطاق المسموح: $distance');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setDouble(_keyDistanceGoal, distance);

      if (success) {
        debugPrint('✅ تم حفظ هدف المسافة: $distance كم');
      }

      return success;
    } catch (e) {
      debugPrint('❌ خطأ في حفظ هدف المسافة: $e');
      return false;
    }
  }

  Future<bool> setCaloriesGoal(double calories) async {
    try {
      if (calories < 50 || calories > 5000) {
        debugPrint('⚠️ هدف السعرات خارج النطاق المسموح: $calories');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setDouble(_keyCaloriesGoal, calories);

      if (success) {
        debugPrint('✅ تم حفظ هدف السعرات: $calories سعرة');
      }

      return success;
    } catch (e) {
      debugPrint('❌ خطأ في حفظ هدف السعرات: $e');
      return false;
    }
  }

  Future<bool> setActiveMinutesGoal(int minutes) async {
    try {
      if (minutes < 5 || minutes > 300) {
        debugPrint('⚠️ هدف الدقائق النشطة خارج النطاق المسموح: $minutes');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setInt(_keyActiveMinutesGoal, minutes);

      if (success) {
        debugPrint('✅ تم حفظ هدف الدقائق النشطة: $minutes دقيقة');
      }

      return success;
    } catch (e) {
      debugPrint('❌ خطأ في حفظ هدف الدقائق النشطة: $e');
      return false;
    }
  }

  /// حفظ جميع الأهداف دفعة واحدة
  Future<bool> setAllGoals({
    required int steps,
    required double distance,
    required double calories,
    required int activeMinutes,
  }) async {
    try {
      final results = await Future.wait([
        setStepsGoal(steps),
        setDistanceGoal(distance),
        setCaloriesGoal(calories),
        setActiveMinutesGoal(activeMinutes),
      ]);

      final allSuccess = results.every((r) => r == true);

      if (allSuccess) {
        debugPrint('✅ تم حفظ جميع الأهداف بنجاح');
      } else {
        debugPrint('⚠️ فشل حفظ بعض الأهداف');
      }

      return allSuccess;
    } catch (e) {
      debugPrint('❌ خطأ في حفظ الأهداف: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════
  // إعادة التعيين (Reset)
  // ════════════════════════════════════════════════════════════

  Future<bool> resetToDefaults() async {
    try {
      return await setAllGoals(
        steps: defaultStepsGoal,
        distance: defaultDistanceGoal,
        calories: defaultCaloriesGoal,
        activeMinutes: defaultActiveMinutesGoal,
      );
    } catch (e) {
      debugPrint('❌ خطأ في إعادة التعيين: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════
  // دوال مساعدة (Helper Functions)
  // ════════════════════════════════════════════════════════════

  /// حساب نسبة الإنجاز
  double calculateProgress(int currentSteps, int goalSteps) {
    if (goalSteps <= 0) return 0.0;
    return (currentSteps / goalSteps).clamp(0.0, 1.0);
  }

  /// هل تم تحقيق الهدف؟
  bool isGoalAchieved(int currentSteps, int goalSteps) {
    return currentSteps >= goalSteps;
  }

  /// الخطوات المتبقية لتحقيق الهدف
  int getRemainingSteps(int currentSteps, int goalSteps) {
    final remaining = goalSteps - currentSteps;
    return remaining > 0 ? remaining : 0;
  }

  /// تنسيق الهدف للعرض
  String formatGoal(dynamic value, String type) {
    switch (type) {
      case 'steps':
        return '${(value as int).toString()} خطوة';
      case 'distance':
        return '${(value as double).toStringAsFixed(1)} كم';
      case 'calories':
        return '${(value as double).toInt()} سعرة';
      case 'minutes':
        return '${(value as int).toString()} دقيقة';
      default:
        return value.toString();
    }
  }

  /// اقتراحات أهداف بناءً على المستوى
  Map<String, dynamic> getSuggestedGoals(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
      case 'مبتدئ':
        return {
          'steps': 5000,
          'distance': 4.0,
          'calories': 250.0,
          'active_minutes': 20,
        };

      case 'intermediate':
      case 'متوسط':
        return {
          'steps': 10000,
          'distance': 8.0,
          'calories': 500.0,
          'active_minutes': 30,
        };

      case 'advanced':
      case 'متقدم':
        return {
          'steps': 15000,
          'distance': 12.0,
          'calories': 750.0,
          'active_minutes': 60,
        };

      case 'athlete':
      case 'رياضي':
        return {
          'steps': 20000,
          'distance': 15.0,
          'calories': 1000.0,
          'active_minutes': 90,
        };

      default:
        return {
          'steps': defaultStepsGoal,
          'distance': defaultDistanceGoal,
          'calories': defaultCaloriesGoal,
          'active_minutes': defaultActiveMinutesGoal,
        };
    }
  }

  // ════════════════════════════════════════════════════════════
  // Validation
  // ════════════════════════════════════════════════════════════

  bool isValidStepsGoal(int steps) {
    return steps >= 1000 && steps <= 100000;
  }

  bool isValidDistanceGoal(double distance) {
    return distance >= 0.5 && distance <= 100;
  }

  bool isValidCaloriesGoal(double calories) {
    return calories >= 50 && calories <= 5000;
  }

  bool isValidActiveMinutesGoal(int minutes) {
    return minutes >= 5 && minutes <= 300;
  }

  /// التحقق من صحة جميع الأهداف
  Map<String, String> validateAllGoals({
    required int steps,
    required double distance,
    required double calories,
    required int activeMinutes,
  }) {
    final errors = <String, String>{};

    if (!isValidStepsGoal(steps)) {
      errors['steps'] = 'يجب أن يكون بين 1,000 و 100,000';
    }

    if (!isValidDistanceGoal(distance)) {
      errors['distance'] = 'يجب أن تكون بين 0.5 و 100 كم';
    }

    if (!isValidCaloriesGoal(calories)) {
      errors['calories'] = 'يجب أن تكون بين 50 و 5,000 سعرة';
    }

    if (!isValidActiveMinutesGoal(activeMinutes)) {
      errors['active_minutes'] = 'يجب أن تكون بين 5 و 300 دقيقة';
    }

    return errors;
  }
}