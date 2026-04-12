// lib/core/models/common_models.dart
import 'package:flutter/material.dart';
import 'package:smart_psych/core/database/models/phone_usage_models.dart';
import 'package:smart_psych/core/database/models/sleep_models.dart';
import '../../services/insights_service.dart';
import 'activity_models.dart';
import 'nutrition_models.dart';

/// Enums - التعدادات
enum SettingValueType { string, int, double, bool, json }
enum AppTheme { light, dark, system }

/// App Notification class - فئة إشعارات التطبيق
class AppNotification {
  final int? id;
  final String title;
  final String body;
  final String type;
  final String? category;
  final Map<String, dynamic>? data;
  final DateTime? scheduledTime;
  final DateTime? sentTime;
  final bool isSent;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    this.id,
    required this.title,
    required this.body,
    required this.type,
    this.category,
    this.data,
    this.scheduledTime,
    this.sentTime,
    this.isSent = false,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as int?,
      title: map['title'] as String,
      body: map['body'] as String,
      type: map['type'] as String,
      category: map['category'] as String?,
      data: map['data'] != null
          ? Map<String, dynamic>.from(map['data'] as Map)
          : null,
      scheduledTime: map['scheduled_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['scheduled_time'] as int)
          : null,
      sentTime: map['sent_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['sent_time'] as int)
          : null,
      isSent: (map['is_sent'] as int?) == 1,
      isRead: (map['is_read'] as int?) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'category': category,
      'data': data,
      'scheduled_time': scheduledTime?.millisecondsSinceEpoch,
      'sent_time': sentTime?.millisecondsSinceEpoch,
      'is_sent': isSent ? 1 : 0,
      'is_read': isRead ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  AppNotification copyWith({
    int? id,
    String? title,
    String? body,
    String? type,
    String? category,
    Map<String, dynamic>? data,
    DateTime? scheduledTime,
    DateTime? sentTime,
    bool? isSent,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      category: category ?? this.category,
      data: data ?? this.data,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      sentTime: sentTime ?? this.sentTime,
      isSent: isSent ?? this.isSent,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  @override
  String toString() {
    return 'AppNotification(type: $type, title: $title, sent: $isSent, read: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppNotification &&
        other.id == id &&
        other.type == type &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(id, type, createdAt);
}

/// App Settings class - فئة إعدادات التطبيق
class AppSettings {
  final int? id;
  final String key;
  final dynamic value;
  final SettingValueType valueType;
  final DateTime createdAt;
  final DateTime updatedAt;

  // إضافة خصائص جديدة للإعدادات
  final AppTheme theme;
  final Locale locale;
  final bool notificationsEnabled;
  final bool backgroundServiceEnabled;
  final Map<String, dynamic> customSettings;

  const AppSettings({
    this.id,
    required this.key,
    required this.value,
    required this.valueType,
    required this.createdAt,
    required this.updatedAt,
    this.theme = AppTheme.system,
    this.locale = const Locale('ar', 'SA'),
    this.notificationsEnabled = true,
    this.backgroundServiceEnabled = true,
    this.customSettings = const {},
  });

  /// Factory constructor للإعدادات الافتراضية
  factory AppSettings.initial() {
    final now = DateTime.now();
    return AppSettings(
      id: null,
      key: 'app_main_settings',
      value: 'initial',
      valueType: SettingValueType.string,
      createdAt: now,
      updatedAt: now,
      theme: AppTheme.system,
      locale: const Locale('ar', 'SA'),
      notificationsEnabled: true,
      backgroundServiceEnabled: true,
      customSettings: const {},
    );
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    final valueType = SettingValueType.values.firstWhere(
          (e) => e.name == map['value_type'],
      orElse: () => SettingValueType.string,
    );

    dynamic parsedValue = map['value'];
    switch (valueType) {
      case SettingValueType.int:
        parsedValue = int.tryParse(map['value'].toString()) ?? 0;
        break;
      case SettingValueType.double:
        parsedValue = double.tryParse(map['value'].toString()) ?? 0.0;
        break;
      case SettingValueType.bool:
        parsedValue = map['value'].toString().toLowerCase() == 'true';
        break;
      case SettingValueType.json:
      // Handle JSON parsing if needed
        break;
      case SettingValueType.string:
      default:
        parsedValue = map['value'].toString();
        break;
    }

    return AppSettings(
      id: map['id'] as int?,
      key: map['key'] as String,
      value: parsedValue,
      valueType: valueType,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      theme: AppTheme.values.firstWhere(
            (e) => e.name == (map['theme'] ?? 'system'),
        orElse: () => AppTheme.system,
      ),
      locale: Locale(
          map['locale_code'] ?? 'ar',
          map['country_code'] ?? 'SA'
      ),
      notificationsEnabled: (map['notifications_enabled'] as int?) == 1,
      backgroundServiceEnabled: (map['background_service_enabled'] as int?) == 1,
      customSettings: map['custom_settings'] != null
          ? Map<String, dynamic>.from(map['custom_settings'] as Map)
          : {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'key': key,
      'value': value.toString(),
      'value_type': valueType.name,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'theme': theme.name,
      'locale_code': locale.languageCode,
      'country_code': locale.countryCode,
      'notifications_enabled': notificationsEnabled ? 1 : 0,
      'background_service_enabled': backgroundServiceEnabled ? 1 : 0,
      'custom_settings': customSettings,
    };
  }

  AppSettings copyWith({
    int? id,
    String? key,
    dynamic value,
    SettingValueType? valueType,
    DateTime? updatedAt,
    AppTheme? theme,
    Locale? locale,
    bool? notificationsEnabled,
    bool? backgroundServiceEnabled,
    Map<String, dynamic>? customSettings,
  }) {
    return AppSettings(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
      valueType: valueType ?? this.valueType,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      theme: theme ?? this.theme,
      locale: locale ?? this.locale,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      backgroundServiceEnabled: backgroundServiceEnabled ?? this.backgroundServiceEnabled,
      customSettings: customSettings ?? this.customSettings,
    );
  }

  @override
  String toString() {
    return 'AppSettings(key: $key, value: $value, type: $valueType, theme: $theme, locale: $locale)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.id == id &&
        other.key == key &&
        other.theme == theme &&
        other.locale == locale;
  }

  @override
  int get hashCode => Object.hash(id, key, theme, locale);
}

/// Sensor Data class - فئة بيانات الحساسات
class SensorData {
  final int? id;
  final String sensorType;
  final DateTime timestamp;
  final double? valueX;
  final double? valueY;
  final double? valueZ;
  final int? accuracy;
  final bool processed;
  final DateTime createdAt;

  const SensorData({
    this.id,
    required this.sensorType,
    required this.timestamp,
    this.valueX,
    this.valueY,
    this.valueZ,
    this.accuracy,
    this.processed = false,
    required this.createdAt,
  });

  factory SensorData.fromMap(Map<String, dynamic> map) {
    return SensorData(
      id: map['id'] as int?,
      sensorType: map['sensor_type'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      valueX: map['value_x'] != null ? (map['value_x'] as num).toDouble() : null,
      valueY: map['value_y'] != null ? (map['value_y'] as num).toDouble() : null,
      valueZ: map['value_z'] != null ? (map['value_z'] as num).toDouble() : null,
      accuracy: map['accuracy'] as int?,
      processed: (map['processed'] as int?) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sensor_type': sensorType,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'value_x': valueX,
      'value_y': valueY,
      'value_z': valueZ,
      'accuracy': accuracy,
      'processed': processed ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  SensorData copyWith({
    int? id,
    String? sensorType,
    DateTime? timestamp,
    double? valueX,
    double? valueY,
    double? valueZ,
    int? accuracy,
    bool? processed,
  }) {
    return SensorData(
      id: id ?? this.id,
      sensorType: sensorType ?? this.sensorType,
      timestamp: timestamp ?? this.timestamp,
      valueX: valueX ?? this.valueX,
      valueY: valueY ?? this.valueY,
      valueZ: valueZ ?? this.valueZ,
      accuracy: accuracy ?? this.accuracy,
      processed: processed ?? this.processed,
      createdAt: createdAt,
    );
  }

  @override
  String toString() {
    return 'SensorData(type: $sensorType, timestamp: $timestamp, values: ($valueX, $valueY, $valueZ))';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SensorData &&
        other.id == id &&
        other.sensorType == sensorType &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => Object.hash(id, sensorType, timestamp);
}

/// Daily Summary class - فئة الملخص اليومي
// في DailySummary class - إصلاح totalSleepTime

/// Daily Summary class - فئة الملخص اليومي
class DailySummary {
  final String date;
  final SleepSession? sleepSession;
  final PhoneUsageSession? phoneUsage;
  final DailyActivity? activity;
  final List<Meal> meals;
  final WeightEntry? weightEntry;
  final List<Insight> insights;
  final List<LocationVisit> locationVisits;

  const DailySummary({
    required this.date,
    this.sleepSession,
    this.phoneUsage,
    this.activity,
    this.meals = const [],
    this.weightEntry,
    this.insights = const [],
    this.locationVisits = const [],
  });

  // حسابات مجمعة - مع إصلاح Duration
  double get totalCaloriesConsumed => meals.fold(0.0, (sum, meal) => sum + meal.totalCalories);
  double get totalCaloriesBurned => activity?.caloriesBurned ?? 0.0;
  double get calorieBalance => totalCaloriesConsumed - totalCaloriesBurned;

  // ✅ إصلاح totalSleepTime
  Object get totalSleepTime => sleepSession?.duration ?? const Duration();
  Duration get totalPhoneUsage => phoneUsage?.totalUsageTime ?? const Duration();

  int get totalSteps => activity?.totalSteps ?? 0;

  int get positiveInsights => insights.where((i) => i.insightType == InsightType.positive).length;
  int get negativeInsights => insights.where((i) => i.insightType == InsightType.negative).length;
  int get neutralInsights => insights.where((i) => i.insightType == InsightType.neutral).length;

  // Overall wellness score calculation
  double get wellnessScore {
    double sleepScore = 0.0;
    double phoneScore = 0.0;
    double activityScore = 0.0;
    double nutritionScore = 0.0;

    // Sleep score (0-1)
    if (sleepSession?.duration != null) {
      final hours = sleepSession!.duration!;
      sleepScore = hours >= Duration(hours: 7) && hours <= Duration(hours: 9) ? 1.0 :
      hours >= Duration(hours: 6) && hours <= Duration(hours: 10) ? 0.7 : 0.3;
    }

    // Phone usage score (0-1) - less is better
    if (phoneUsage != null) {
      final hours = phoneUsage!.totalUsageTime.inHours;
      phoneScore = hours <= 2 ? 1.0 :
      hours <= 4 ? 0.7 :
      hours <= 6 ? 0.5 : 0.2;
    }

    // Activity score (0-1)
    if (activity != null) {
      activityScore = (activity!.totalSteps / 10000).clamp(0.0, 1.0);
    }

    // Nutrition score (0-1)
    if (meals.isNotEmpty) {
      nutritionScore = meals.length >= 3 ? 1.0 :
      meals.length == 2 ? 0.7 : 0.4;
    }

    // Weighted average
    return (sleepScore * 0.3 + phoneScore * 0.2 + activityScore * 0.3 + nutritionScore * 0.2).clamp(0.0, 1.0);
  }

  @override
  String toString() {
    return 'DailySummary(date: $date, sleep: ${totalSleepTime}h, steps: $totalSteps, wellness: ${(wellnessScore * 100).round()}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailySummary && other.date == date;
  }

  @override
  int get hashCode => date.hashCode;
}

/// ملخص يومي بسيط للنشاط (للمخططات فقط)
class ActivityDailySummary {  // ✅ اسم فريد
  final DateTime date;
  final int totalSteps;
  final double distance;
  final double calories;
  final int activeMinutes;

  ActivityDailySummary({
    required this.date,
    required this.totalSteps,
    required this.distance,
    required this.calories,
    required this.activeMinutes,
  });
}


/// ملخص يومي بسيط لاستخدام الهاتف (للمخططات)
class PhoneDailySummary {
  final DateTime date;
  final Duration totalUsageTime;
  final int totalPickups;

  PhoneDailySummary({
    required this.date,
    required this.totalUsageTime,
    required this.totalPickups,
  });
}

/// Period Stats class - فئة الإحصائيات للفترات
class PeriodStats {
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;

  // إحصائيات النوم
  final Duration avgSleepDuration;
  final double avgSleepQuality;
  final int totalSleepSessions;

  // إحصائيات الهاتف
  final Duration avgPhoneUsage;
  final int avgPhonePickups;
  final Duration avgNightUsage;

  // إحصائيات النشاط
  final int avgSteps;
  final double avgDistance;
  final double avgCaloriesBurned;

  // إحصائيات التغذية
  final double avgCaloriesConsumed;
  final int avgMealsPerDay;
  final double? weightChange;

  // إحصائيات المواقع
  final int totalLocationVisits;
  final int uniqueLocations;

  // إحصائيات الرؤى
  final int totalInsights;
  final int positiveInsights;
  final int negativeInsights;

  const PeriodStats({
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.avgSleepDuration,
    required this.avgSleepQuality,
    required this.totalSleepSessions,
    required this.avgPhoneUsage,
    required this.avgPhonePickups,
    required this.avgNightUsage,
    required this.avgSteps,
    required this.avgDistance,
    required this.avgCaloriesBurned,
    required this.avgCaloriesConsumed,
    required this.avgMealsPerDay,
    this.weightChange,
    required this.totalLocationVisits,
    required this.uniqueLocations,
    required this.totalInsights,
    required this.positiveInsights,
    required this.negativeInsights,
  });

  // Computed properties
  double get positiveInsightRatio => totalInsights > 0 ? positiveInsights / totalInsights : 0.0;
  double get negativeInsightRatio => totalInsights > 0 ? negativeInsights / totalInsights : 0.0;

  double get overallWellnessScore {
    double sleepScore = avgSleepQuality * 0.3;
    double activityScore = (avgSteps / 10000).clamp(0.0, 1.0) * 0.3;
    double phoneScore = (1.0 - (avgPhoneUsage.inHours / 12).clamp(0.0, 1.0)) * 0.2;
    double insightScore = positiveInsightRatio * 0.2;

    return (sleepScore + activityScore + phoneScore + insightScore).clamp(0.0, 1.0);
  }

  String get wellnessGrade {
    final score = overallWellnessScore;
    if (score >= 0.9) return 'ممتاز';
    if (score >= 0.8) return 'جيد جداً';
    if (score >= 0.7) return 'جيد';
    if (score >= 0.6) return 'مقبول';
    if (score >= 0.5) return 'ضعيف';
    return 'ضعيف جداً';
  }

  @override
  String toString() {
    return 'PeriodStats(${startDate.day}/${startDate.month} - ${endDate.day}/${endDate.month}, wellness: ${(overallWellnessScore * 100).round()}% - $wellnessGrade)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PeriodStats &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => Object.hash(startDate, endDate);
}

/// User class - فئة المستخدم
@immutable
class User {
  final String id;
  final String name;
  final String? email;
  final String? avatar;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final Map<String, dynamic> preferences;
  final UserSettings userSettings;

  const User({
    required this.id,
    required this.name,
    this.email,
    this.avatar,
    required this.createdAt,
    required this.lastActiveAt,
    this.preferences = const {},
    this.userSettings = const UserSettings(),
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
    DateTime? lastActiveAt,
    Map<String, dynamic>? preferences,
    UserSettings? userSettings,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      preferences: preferences ?? this.preferences,
      userSettings: userSettings ?? this.userSettings,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.name == name &&
        other.email == email;
  }

  @override
  int get hashCode => Object.hash(id, name, email);
}

/// User Settings class - فئة إعدادات المستخدم
@immutable
class UserSettings {
  final bool enableSleepTracking;
  final bool enablePhoneMonitoring;
  final bool enableActivityTracking;
  final bool enableLocationTracking;
  final bool enableNotifications;
  final int dailyStepsGoal;
  final int dailySleepGoal; // in hours
  final int maxPhoneUsageGoal; // in hours

  const UserSettings({
    this.enableSleepTracking = true,
    this.enablePhoneMonitoring = true,
    this.enableActivityTracking = true,
    this.enableLocationTracking = true,
    this.enableNotifications = true,
    this.dailyStepsGoal = 10000,
    this.dailySleepGoal = 8,
    this.maxPhoneUsageGoal = 4,
  });

  UserSettings copyWith({
    bool? enableSleepTracking,
    bool? enablePhoneMonitoring,
    bool? enableActivityTracking,
    bool? enableLocationTracking,
    bool? enableNotifications,
    int? dailyStepsGoal,
    int? dailySleepGoal,
    int? maxPhoneUsageGoal,
  }) {
    return UserSettings(
      enableSleepTracking: enableSleepTracking ?? this.enableSleepTracking,
      enablePhoneMonitoring: enablePhoneMonitoring ?? this.enablePhoneMonitoring,
      enableActivityTracking: enableActivityTracking ?? this.enableActivityTracking,
      enableLocationTracking: enableLocationTracking ?? this.enableLocationTracking,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      dailyStepsGoal: dailyStepsGoal ?? this.dailyStepsGoal,
      dailySleepGoal: dailySleepGoal ?? this.dailySleepGoal,
      maxPhoneUsageGoal: maxPhoneUsageGoal ?? this.maxPhoneUsageGoal,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserSettings &&
        other.enableSleepTracking == enableSleepTracking &&
        other.enablePhoneMonitoring == enablePhoneMonitoring &&
        other.enableActivityTracking == enableActivityTracking &&
        other.enableLocationTracking == enableLocationTracking &&
        other.dailyStepsGoal == dailyStepsGoal &&
        other.dailySleepGoal == dailySleepGoal &&
        other.maxPhoneUsageGoal == maxPhoneUsageGoal;
  }

  @override
  int get hashCode => Object.hash(
    enableSleepTracking,
    enablePhoneMonitoring,
    enableActivityTracking,
    enableLocationTracking,
    dailyStepsGoal,
    dailySleepGoal,
    maxPhoneUsageGoal,
  );
}

/// App Configuration class - فئة تكوين التطبيق
@immutable
class AppConfiguration {
  final String apiBaseUrl;
  final String appVersion;
  final bool debugMode;
  final Map<String, bool> featureFlags;
  final Duration cacheExpiration;
  final int maxRetryAttempts;

  const AppConfiguration({
    this.apiBaseUrl = 'https://api.smartpsych.com',
    this.appVersion = '1.0.0',
    this.debugMode = false,
    this.featureFlags = const {},
    this.cacheExpiration = const Duration(minutes: 10),
    this.maxRetryAttempts = 3,
  });

  bool isFeatureEnabled(String feature) {
    return featureFlags[feature] ?? false;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppConfiguration &&
        other.apiBaseUrl == apiBaseUrl &&
        other.appVersion == appVersion &&
        other.debugMode == debugMode;
  }

  @override
  int get hashCode => Object.hash(apiBaseUrl, appVersion, debugMode);
}