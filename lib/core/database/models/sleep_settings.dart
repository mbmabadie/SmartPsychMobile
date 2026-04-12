// lib/core/database/models/sleep_settings.dart
import 'package:flutter/material.dart';

/// نموذج إعدادات النوم
class SleepSettings {
  // ================================
  // النافذة الزمنية للنوم
  // ================================

  /// ساعة بداية النافذة الزمنية
  final int sleepWindowStartHour;

  /// دقيقة بداية النافذة الزمنية
  final int sleepWindowStartMinute;

  /// ساعة نهاية النافذة الزمنية
  final int sleepWindowEndHour;

  /// دقيقة نهاية النافذة الزمنية
  final int sleepWindowEndMinute;

  /// تفعيل النافذة الزمنية التكيفية
  final bool adaptiveWindowEnabled;

  // ================================
  // أهداف النوم
  // ================================

  /// عدد ساعات النوم المستهدفة
  final int sleepGoalHours;

  /// عدد دقائق النوم المستهدفة (إضافية)
  final int sleepGoalMinutes;

  // ================================
  // عتبات الكشف
  // ================================

  /// عتبة مستوى الضوء (lux)
  final double sleepLightThreshold;

  /// عتبة مستوى الضوضاء (dB)
  final double sleepNoiseThreshold;

  /// عتبة شدة الحركة
  final double sleepMovementThreshold;

  /// الحد الأدنى لمدة النوم (بالدقائق)
  final int minimumSleepDuration;

  /// الحد الأقصى لمدة النوم (بالدقائق)
  final int maximumSleepDuration;

  // ================================
  // التنبيهات والإشعارات
  // ================================

  /// تفعيل إشعارات النوم
  final bool notificationsEnabled;

  /// تفعيل تذكير وقت النوم
  final bool bedtimeReminderEnabled;

  /// وقت تذكير النوم قبل الموعد (بالدقائق)
  final int bedtimeReminderMinutesBefore;

  /// تفعيل تنبيه الاستيقاظ
  final bool wakeUpAlertEnabled;

  /// تفعيل تنبيهات تأكيد الجلسات
  final bool sessionConfirmationAlertsEnabled;

  // ================================
  // الرصد والتتبع
  // ================================

  /// تفعيل رصد استخدام الهاتف
  final bool phoneUsageTrackingEnabled;

  /// تفعيل رصد البيئة المحيطة
  final bool environmentalTrackingEnabled;

  /// تفعيل رصد الحركة
  final bool movementTrackingEnabled;

  /// تفعيل رصد الصوت
  final bool soundTrackingEnabled;

  /// تفعيل رصد الضوء
  final bool lightTrackingEnabled;

  /// معدل أخذ عينات البيانات البيئية (بالثواني)
  final int environmentalSamplingRate;

  // ================================
  // الخصوصية والبيانات
  // ================================

  /// تفعيل النسخ الاحتياطي التلقائي
  final bool autoBackupEnabled;

  /// تفعيل المزامنة السحابية
  final bool cloudSyncEnabled;

  /// عدد الأيام للاحتفاظ بالبيانات
  final int dataRetentionDays;

  /// تفعيل وضع الخصوصية (تقليل جمع البيانات)
  final bool privacyModeEnabled;

  // ================================
  // التحليلات والتقارير
  // ================================

  /// تفعيل التحليل التلقائي
  final bool autoAnalysisEnabled;

  /// تفعيل التقارير الأسبوعية
  final bool weeklyReportsEnabled;

  /// يوم إرسال التقرير الأسبوعي (0=الأحد، 6=السبت)
  final int weeklyReportDay;

  /// تفعيل التقارير الشهرية
  final bool monthlyReportsEnabled;

  /// تفعيل الاقتراحات الذكية
  final bool smartSuggestionsEnabled;

  // ================================
  // واجهة المستخدم
  // ================================

  /// تفعيل الوضع الداكن التلقائي
  final bool autoDarkModeEnabled;

  /// وحدة عرض الوقت (12 أو 24 ساعة)
  final int timeFormat;

  /// اللغة المفضلة
  final String preferredLanguage;

  /// عرض نصائح النوم
  final bool showSleepTips;

  // ================================
  // إعدادات متقدمة
  // ================================

  /// تفعيل وضع عدم الإزعاج التلقائي
  final bool autoDoNotDisturbEnabled;

  /// تفعيل وضع الطيران التلقائي
  final bool autoAirplaneModeEnabled;

  /// تفعيل تقليل السطوع التلقائي
  final bool autoBrightnessReductionEnabled;

  /// مستوى السطوع أثناء النوم (0-100)
  final int sleepBrightnessLevel;

  /// تفعيل الضوء الأحمر الليلي
  final bool redLightModeEnabled;

  const SleepSettings({
    // النافذة الزمنية
    this.sleepWindowStartHour = 21,
    this.sleepWindowStartMinute = 0,
    this.sleepWindowEndHour = 7,
    this.sleepWindowEndMinute = 0,
    this.adaptiveWindowEnabled = true,

    // الأهداف
    this.sleepGoalHours = 8,
    this.sleepGoalMinutes = 0,

    // العتبات
    this.sleepLightThreshold = 10.0,
    this.sleepNoiseThreshold = 40.0,
    this.sleepMovementThreshold = 0.1,
    this.minimumSleepDuration = 180, // 3 ساعات
    this.maximumSleepDuration = 720, // 12 ساعة

    // التنبيهات
    this.notificationsEnabled = true,
    this.bedtimeReminderEnabled = true,
    this.bedtimeReminderMinutesBefore = 30,
    this.wakeUpAlertEnabled = true,
    this.sessionConfirmationAlertsEnabled = true,

    // الرصد
    this.phoneUsageTrackingEnabled = true,
    this.environmentalTrackingEnabled = true,
    this.movementTrackingEnabled = true,
    this.soundTrackingEnabled = true,
    this.lightTrackingEnabled = true,
    this.environmentalSamplingRate = 60, // كل دقيقة

    // الخصوصية
    this.autoBackupEnabled = true,
    this.cloudSyncEnabled = false,
    this.dataRetentionDays = 90,
    this.privacyModeEnabled = false,

    // التحليلات
    this.autoAnalysisEnabled = true,
    this.weeklyReportsEnabled = true,
    this.weeklyReportDay = 1, // الإثنين
    this.monthlyReportsEnabled = true,
    this.smartSuggestionsEnabled = true,

    // واجهة المستخدم
    this.autoDarkModeEnabled = true,
    this.timeFormat = 24,
    this.preferredLanguage = 'ar',
    this.showSleepTips = true,

    // متقدمة
    this.autoDoNotDisturbEnabled = true,
    this.autoAirplaneModeEnabled = false,
    this.autoBrightnessReductionEnabled = true,
    this.sleepBrightnessLevel = 10,
    this.redLightModeEnabled = false,
  });

  // ================================
  // Getters المساعدة
  // ================================

  /// الحصول على وقت بداية النافذة كـ TimeOfDay
  TimeOfDay get sleepWindowStart => TimeOfDay(
    hour: sleepWindowStartHour,
    minute: sleepWindowStartMinute,
  );

  /// الحصول على وقت نهاية النافذة كـ TimeOfDay
  TimeOfDay get sleepWindowEnd => TimeOfDay(
    hour: sleepWindowEndHour,
    minute: sleepWindowEndMinute,
  );

  /// مدة النوم المستهدفة بالدقائق
  int get targetSleepMinutes => (sleepGoalHours * 60) + sleepGoalMinutes;

  /// مدة النوم المستهدفة كـ Duration
  Duration get targetSleepDuration => Duration(
    hours: sleepGoalHours,
    minutes: sleepGoalMinutes,
  );

  /// هل جميع ميزات التتبع مفعلة؟
  bool get isFullTrackingEnabled =>
      phoneUsageTrackingEnabled &&
          environmentalTrackingEnabled &&
          movementTrackingEnabled &&
          soundTrackingEnabled &&
          lightTrackingEnabled;

  /// هل أي من ميزات التتبع مفعلة؟
  bool get isAnyTrackingEnabled =>
      phoneUsageTrackingEnabled ||
          environmentalTrackingEnabled ||
          movementTrackingEnabled ||
          soundTrackingEnabled ||
          lightTrackingEnabled;

  // ================================
  // التحويل من/إلى Map
  // ================================

  Map<String, dynamic> toMap() {
    return {
      // النافذة الزمنية
      'sleep_window_start_hour': sleepWindowStartHour,
      'sleep_window_start_minute': sleepWindowStartMinute,
      'sleep_window_end_hour': sleepWindowEndHour,
      'sleep_window_end_minute': sleepWindowEndMinute,
      'adaptive_window_enabled': adaptiveWindowEnabled ? 1 : 0,

      // الأهداف
      'sleep_goal_hours': sleepGoalHours,
      'sleep_goal_minutes': sleepGoalMinutes,

      // العتبات
      'sleep_light_threshold': sleepLightThreshold,
      'sleep_noise_threshold': sleepNoiseThreshold,
      'sleep_movement_threshold': sleepMovementThreshold,
      'minimum_sleep_duration': minimumSleepDuration,
      'maximum_sleep_duration': maximumSleepDuration,

      // التنبيهات
      'notifications_enabled': notificationsEnabled ? 1 : 0,
      'bedtime_reminder_enabled': bedtimeReminderEnabled ? 1 : 0,
      'bedtime_reminder_minutes_before': bedtimeReminderMinutesBefore,
      'wake_up_alert_enabled': wakeUpAlertEnabled ? 1 : 0,
      'session_confirmation_alerts_enabled': sessionConfirmationAlertsEnabled ? 1 : 0,

      // الرصد
      'phone_usage_tracking_enabled': phoneUsageTrackingEnabled ? 1 : 0,
      'environmental_tracking_enabled': environmentalTrackingEnabled ? 1 : 0,
      'movement_tracking_enabled': movementTrackingEnabled ? 1 : 0,
      'sound_tracking_enabled': soundTrackingEnabled ? 1 : 0,
      'light_tracking_enabled': lightTrackingEnabled ? 1 : 0,
      'environmental_sampling_rate': environmentalSamplingRate,

      // الخصوصية
      'auto_backup_enabled': autoBackupEnabled ? 1 : 0,
      'cloud_sync_enabled': cloudSyncEnabled ? 1 : 0,
      'data_retention_days': dataRetentionDays,
      'privacy_mode_enabled': privacyModeEnabled ? 1 : 0,

      // التحليلات
      'auto_analysis_enabled': autoAnalysisEnabled ? 1 : 0,
      'weekly_reports_enabled': weeklyReportsEnabled ? 1 : 0,
      'weekly_report_day': weeklyReportDay,
      'monthly_reports_enabled': monthlyReportsEnabled ? 1 : 0,
      'smart_suggestions_enabled': smartSuggestionsEnabled ? 1 : 0,

      // واجهة المستخدم
      'auto_dark_mode_enabled': autoDarkModeEnabled ? 1 : 0,
      'time_format': timeFormat,
      'preferred_language': preferredLanguage,
      'show_sleep_tips': showSleepTips ? 1 : 0,

      // متقدمة
      'auto_do_not_disturb_enabled': autoDoNotDisturbEnabled ? 1 : 0,
      'auto_airplane_mode_enabled': autoAirplaneModeEnabled ? 1 : 0,
      'auto_brightness_reduction_enabled': autoBrightnessReductionEnabled ? 1 : 0,
      'sleep_brightness_level': sleepBrightnessLevel,
      'red_light_mode_enabled': redLightModeEnabled ? 1 : 0,
    };
  }

  factory SleepSettings.fromMap(Map<String, dynamic> map) {
    return SleepSettings(
      // النافذة الزمنية
      sleepWindowStartHour: _parseInt(map['sleep_window_start_hour'], 21),
      sleepWindowStartMinute: _parseInt(map['sleep_window_start_minute'], 0),
      sleepWindowEndHour: _parseInt(map['sleep_window_end_hour'], 7),
      sleepWindowEndMinute: _parseInt(map['sleep_window_end_minute'], 0),
      adaptiveWindowEnabled: _parseBool(map['adaptive_window_enabled'], true),

      // الأهداف
      sleepGoalHours: _parseInt(map['sleep_goal_hours'], 8),
      sleepGoalMinutes: _parseInt(map['sleep_goal_minutes'], 0),

      // العتبات
      sleepLightThreshold: _parseDouble(map['sleep_light_threshold'], 10.0),
      sleepNoiseThreshold: _parseDouble(map['sleep_noise_threshold'], 40.0),
      sleepMovementThreshold: _parseDouble(map['sleep_movement_threshold'], 0.1),
      minimumSleepDuration: _parseInt(map['minimum_sleep_duration'], 180),
      maximumSleepDuration: _parseInt(map['maximum_sleep_duration'], 720),

      // التنبيهات
      notificationsEnabled: _parseBool(map['notifications_enabled'], true),
      bedtimeReminderEnabled: _parseBool(map['bedtime_reminder_enabled'], true),
      bedtimeReminderMinutesBefore: _parseInt(map['bedtime_reminder_minutes_before'], 30),
      wakeUpAlertEnabled: _parseBool(map['wake_up_alert_enabled'], true),
      sessionConfirmationAlertsEnabled: _parseBool(map['session_confirmation_alerts_enabled'], true),

      // الرصد
      phoneUsageTrackingEnabled: _parseBool(map['phone_usage_tracking_enabled'], true),
      environmentalTrackingEnabled: _parseBool(map['environmental_tracking_enabled'], true),
      movementTrackingEnabled: _parseBool(map['movement_tracking_enabled'], true),
      soundTrackingEnabled: _parseBool(map['sound_tracking_enabled'], true),
      lightTrackingEnabled: _parseBool(map['light_tracking_enabled'], true),
      environmentalSamplingRate: _parseInt(map['environmental_sampling_rate'], 60),

      // الخصوصية
      autoBackupEnabled: _parseBool(map['auto_backup_enabled'], true),
      cloudSyncEnabled: _parseBool(map['cloud_sync_enabled'], false),
      dataRetentionDays: _parseInt(map['data_retention_days'], 90),
      privacyModeEnabled: _parseBool(map['privacy_mode_enabled'], false),

      // التحليلات
      autoAnalysisEnabled: _parseBool(map['auto_analysis_enabled'], true),
      weeklyReportsEnabled: _parseBool(map['weekly_reports_enabled'], true),
      weeklyReportDay: _parseInt(map['weekly_report_day'], 1),
      monthlyReportsEnabled: _parseBool(map['monthly_reports_enabled'], true),
      smartSuggestionsEnabled: _parseBool(map['smart_suggestions_enabled'], true),

      // واجهة المستخدم
      autoDarkModeEnabled: _parseBool(map['auto_dark_mode_enabled'], true),
      timeFormat: _parseInt(map['time_format'], 24),
      preferredLanguage: map['preferred_language']?.toString() ?? 'ar',
      showSleepTips: _parseBool(map['show_sleep_tips'], true),

      // متقدمة
      autoDoNotDisturbEnabled: _parseBool(map['auto_do_not_disturb_enabled'], true),
      autoAirplaneModeEnabled: _parseBool(map['auto_airplane_mode_enabled'], false),
      autoBrightnessReductionEnabled: _parseBool(map['auto_brightness_reduction_enabled'], true),
      sleepBrightnessLevel: _parseInt(map['sleep_brightness_level'], 10),
      redLightModeEnabled: _parseBool(map['red_light_mode_enabled'], false),
    );
  }

  // ================================
  // دوال المساعدة للتحويل
  // ================================

  static int _parseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    if (value is double) return value.toInt();
    return defaultValue;
  }

  static double _parseDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static bool _parseBool(dynamic value, bool defaultValue) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return defaultValue;
  }

  // ================================
  // copyWith
  // ================================

  SleepSettings copyWith({
    int? sleepWindowStartHour,
    int? sleepWindowStartMinute,
    int? sleepWindowEndHour,
    int? sleepWindowEndMinute,
    bool? adaptiveWindowEnabled,
    int? sleepGoalHours,
    int? sleepGoalMinutes,
    double? sleepLightThreshold,
    double? sleepNoiseThreshold,
    double? sleepMovementThreshold,
    int? minimumSleepDuration,
    int? maximumSleepDuration,
    bool? notificationsEnabled,
    bool? bedtimeReminderEnabled,
    int? bedtimeReminderMinutesBefore,
    bool? wakeUpAlertEnabled,
    bool? sessionConfirmationAlertsEnabled,
    bool? phoneUsageTrackingEnabled,
    bool? environmentalTrackingEnabled,
    bool? movementTrackingEnabled,
    bool? soundTrackingEnabled,
    bool? lightTrackingEnabled,
    int? environmentalSamplingRate,
    bool? autoBackupEnabled,
    bool? cloudSyncEnabled,
    int? dataRetentionDays,
    bool? privacyModeEnabled,
    bool? autoAnalysisEnabled,
    bool? weeklyReportsEnabled,
    int? weeklyReportDay,
    bool? monthlyReportsEnabled,
    bool? smartSuggestionsEnabled,
    bool? autoDarkModeEnabled,
    int? timeFormat,
    String? preferredLanguage,
    bool? showSleepTips,
    bool? autoDoNotDisturbEnabled,
    bool? autoAirplaneModeEnabled,
    bool? autoBrightnessReductionEnabled,
    int? sleepBrightnessLevel,
    bool? redLightModeEnabled,
  }) {
    return SleepSettings(
      sleepWindowStartHour: sleepWindowStartHour ?? this.sleepWindowStartHour,
      sleepWindowStartMinute: sleepWindowStartMinute ?? this.sleepWindowStartMinute,
      sleepWindowEndHour: sleepWindowEndHour ?? this.sleepWindowEndHour,
      sleepWindowEndMinute: sleepWindowEndMinute ?? this.sleepWindowEndMinute,
      adaptiveWindowEnabled: adaptiveWindowEnabled ?? this.adaptiveWindowEnabled,
      sleepGoalHours: sleepGoalHours ?? this.sleepGoalHours,
      sleepGoalMinutes: sleepGoalMinutes ?? this.sleepGoalMinutes,
      sleepLightThreshold: sleepLightThreshold ?? this.sleepLightThreshold,
      sleepNoiseThreshold: sleepNoiseThreshold ?? this.sleepNoiseThreshold,
      sleepMovementThreshold: sleepMovementThreshold ?? this.sleepMovementThreshold,
      minimumSleepDuration: minimumSleepDuration ?? this.minimumSleepDuration,
      maximumSleepDuration: maximumSleepDuration ?? this.maximumSleepDuration,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      bedtimeReminderEnabled: bedtimeReminderEnabled ?? this.bedtimeReminderEnabled,
      bedtimeReminderMinutesBefore: bedtimeReminderMinutesBefore ?? this.bedtimeReminderMinutesBefore,
      wakeUpAlertEnabled: wakeUpAlertEnabled ?? this.wakeUpAlertEnabled,
      sessionConfirmationAlertsEnabled: sessionConfirmationAlertsEnabled ?? this.sessionConfirmationAlertsEnabled,
      phoneUsageTrackingEnabled: phoneUsageTrackingEnabled ?? this.phoneUsageTrackingEnabled,
      environmentalTrackingEnabled: environmentalTrackingEnabled ?? this.environmentalTrackingEnabled,
      movementTrackingEnabled: movementTrackingEnabled ?? this.movementTrackingEnabled,
      soundTrackingEnabled: soundTrackingEnabled ?? this.soundTrackingEnabled,
      lightTrackingEnabled: lightTrackingEnabled ?? this.lightTrackingEnabled,
      environmentalSamplingRate: environmentalSamplingRate ?? this.environmentalSamplingRate,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      cloudSyncEnabled: cloudSyncEnabled ?? this.cloudSyncEnabled,
      dataRetentionDays: dataRetentionDays ?? this.dataRetentionDays,
      privacyModeEnabled: privacyModeEnabled ?? this.privacyModeEnabled,
      autoAnalysisEnabled: autoAnalysisEnabled ?? this.autoAnalysisEnabled,
      weeklyReportsEnabled: weeklyReportsEnabled ?? this.weeklyReportsEnabled,
      weeklyReportDay: weeklyReportDay ?? this.weeklyReportDay,
      monthlyReportsEnabled: monthlyReportsEnabled ?? this.monthlyReportsEnabled,
      smartSuggestionsEnabled: smartSuggestionsEnabled ?? this.smartSuggestionsEnabled,
      autoDarkModeEnabled: autoDarkModeEnabled ?? this.autoDarkModeEnabled,
      timeFormat: timeFormat ?? this.timeFormat,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      showSleepTips: showSleepTips ?? this.showSleepTips,
      autoDoNotDisturbEnabled: autoDoNotDisturbEnabled ?? this.autoDoNotDisturbEnabled,
      autoAirplaneModeEnabled: autoAirplaneModeEnabled ?? this.autoAirplaneModeEnabled,
      autoBrightnessReductionEnabled: autoBrightnessReductionEnabled ?? this.autoBrightnessReductionEnabled,
      sleepBrightnessLevel: sleepBrightnessLevel ?? this.sleepBrightnessLevel,
      redLightModeEnabled: redLightModeEnabled ?? this.redLightModeEnabled,
    );
  }

  @override
  String toString() {
    return 'SleepSettings(goal: ${sleepGoalHours}h${sleepGoalMinutes}m, '
        'window: ${sleepWindowStart.format(null as BuildContext)} - ${sleepWindowEnd.format(null as BuildContext)}, '
        'tracking: ${isFullTrackingEnabled ? "Full" : "Partial"})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SleepSettings &&
        other.sleepWindowStartHour == sleepWindowStartHour &&
        other.sleepWindowStartMinute == sleepWindowStartMinute &&
        other.sleepWindowEndHour == sleepWindowEndHour &&
        other.sleepWindowEndMinute == sleepWindowEndMinute &&
        other.sleepGoalHours == sleepGoalHours &&
        other.sleepGoalMinutes == sleepGoalMinutes;
  }

  @override
  int get hashCode {
    return Object.hash(
      sleepWindowStartHour,
      sleepWindowStartMinute,
      sleepWindowEndHour,
      sleepWindowEndMinute,
      sleepGoalHours,
      sleepGoalMinutes,
    );
  }
}