// lib/core/providers/sleep_tracking_state.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../database/models/environmental_conditions.dart';
import '../database/models/sleep_models.dart';
import 'base/base_state.dart';

enum SleepState {
  awake('مستيقظ'),
  falling('يدخل في النوم'),
  sleeping('نائم'),
  restless('نوم متقطع'),
  waking('يستيقظ');

  const SleepState(this.displayName);
  final String displayName;

  String get emoji {
    switch (this) {
      case SleepState.awake:
        return '😊';
      case SleepState.falling:
        return '😴';
      case SleepState.sleeping:
        return '💤';
      case SleepState.restless:
        return '😖';
      case SleepState.waking:
        return '🌅';
    }
  }
}

/// حالة نظام تتبع النوم
@immutable
class SleepTrackingState extends BaseState with EquatableMixin {
  // ============ Sentinel value للـ nullable parameters ============
  static const _undefined = Object();

  // ============ حالة النظام ============

  /// هل التتبع التلقائي نشط
  final bool isAutoTrackingActive;

  /// هل نحن حالياً في نافذة النوم الزمنية
  final bool isInSleepWindow;

  /// حالة النوم الحالية
  final SleepState currentSleepState;

  /// درجة الثقة في كشف النوم (0.0 - 1.0)
  final double sleepDetectionConfidence;

  // ============ إعدادات النافذة الزمنية ============

  /// وقت بداية نافذة النوم
  final TimeOfDay sleepWindowStart;

  /// وقت نهاية نافذة النوم
  final TimeOfDay sleepWindowEnd;

  /// هل النافذة التكيفية مفعلة (تتعلم من عاداتك)
  final bool adaptiveWindowEnabled;

  // ============ الجلسة الحالية ============

  /// جلسة النوم الحالية (إن وجدت)
  final SleepSession? currentSession;

  /// الجلسات الحديثة (آخر 30 يوم)
  final List<SleepSession> recentSessions;

  /// الجلسات التي تحتاج تأكيد المستخدم
  final List<SleepSession> pendingConfirmations;

  // ============ البيانات البيئية ============

  /// الظروف البيئية الحالية
  final EnvironmentalConditions? currentEnvironment;

  /// سجل الظروف البيئية
  final List<EnvironmentalConditions> environmentHistory;

  /// درجة جودة البيئة (0.0 - 1.0)
  final double environmentalQualityScore;

  // ============ الإحصائيات ============

  /// متوسط مدة النوم
  final Duration averageSleepDuration;

  /// متوسط درجة الجودة
  final double averageQualityScore;

  /// هدف النوم بالساعات
  final int sleepGoalHours;

  /// هل تم تحقيق الهدف الليلة الماضية
  final bool goalAchievedLastNight;

  /// عدد الأيام المتتالية لتحقيق الهدف
  final int consecutiveGoalDays;

  // ============ تكامل مع الأنظمة الأخرى ============

  /// استخدام الهاتف خلال النوم (بالدقائق)
  final int phoneUsageDuringSleep;

  /// عدد مرات الانقطاع الليلي
  final int nightInterruptions;

  /// التطبيقات المزعجة للنوم
  final List<String> sleepDisruptingApps;

  // ============ الفلترة والعرض ============

  /// نطاق التاريخ المحدد للفلترة
  final DateTimeRange? selectedDateRange;

  /// نوع العرض (يومي، أسبوعي، شهري)
  final String viewMode;

  SleepTrackingState({
    // Base state
    super.loadingState = LoadingState.idle,
    super.error,
    super.lastUpdated,
    super.hasData = false,
    super.successMessage,

    // Sleep tracking specific
    this.isAutoTrackingActive = false,
    this.isInSleepWindow = false,
    this.currentSleepState = SleepState.awake,
    this.sleepDetectionConfidence = 0.0,

    // Sleep window settings
    this.sleepWindowStart = const TimeOfDay(hour: 21, minute: 0),
    this.sleepWindowEnd = const TimeOfDay(hour: 7, minute: 0),
    this.adaptiveWindowEnabled = true,

    // Current session
    this.currentSession,
    this.recentSessions = const [],
    this.pendingConfirmations = const [],

    // Environmental data
    this.currentEnvironment,
    this.environmentHistory = const [],
    this.environmentalQualityScore = 0.0,

    // Statistics
    this.averageSleepDuration = const Duration(hours: 8),
    this.averageQualityScore = 0.0,
    this.sleepGoalHours = 8,
    this.goalAchievedLastNight = false,
    this.consecutiveGoalDays = 0,

    // Integration data
    this.phoneUsageDuringSleep = 0,
    this.nightInterruptions = 0,
    this.sleepDisruptingApps = const [],

    // Filtering and view
    this.selectedDateRange,
    this.viewMode = 'daily',
  });

  factory SleepTrackingState.initial() {
    return SleepTrackingState(
      loadingState: LoadingState.idle,
      hasData: false,
    );
  }

  // ============ Computed Properties ============

  /// هل لدينا جلسة نشطة حالياً
  bool get hasActiveSession =>
      currentSession != null && !currentSession!.isCompleted;

  /// هل لدينا تأكيدات معلقة
  bool get hasPendingConfirmations => pendingConfirmations.isNotEmpty;

  /// هل نقوم بالتتبع حالياً
  bool get isCurrentlyTracking => isAutoTrackingActive && hasActiveSession;

  /// هل البيئة مناسبة للنوم
  bool get isGoodSleepEnvironment => environmentalQualityScore > 0.7;

  /// هل حققنا الهدف هذا الأسبوع
  bool get weeklyGoalAchieved {
    if (recentSessions.isEmpty) return false;

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final weekSessions = recentSessions.where((session) {
      return session.startTime.isAfter(weekAgo) && session.isCompleted;
    }).toList();

    if (weekSessions.isEmpty) return false;

    final achievedDays = weekSessions.where((session) {
      final duration = session.duration ?? Duration.zero;
      return duration.inHours >= sleepGoalHours;
    }).length;

    return achievedDays >= 5; // 5 أيام من 7
  }

  /// النص الوصفي لحالة النوم
  String get sleepStateText {
    return currentSleepState.displayName;
  }

  /// النص الوصفي لدرجة الثقة
  String get confidenceText {
    if (sleepDetectionConfidence >= 0.9) return 'واثق جداً';
    if (sleepDetectionConfidence >= 0.7) return 'واثق';
    if (sleepDetectionConfidence >= 0.5) return 'متوسط الثقة';
    if (sleepDetectionConfidence >= 0.3) return 'ثقة منخفضة';
    return 'غير واثق';
  }

  /// مدة الجلسة الحالية مُنسقة
  String get currentSessionDuration {
    if (!hasActiveSession) return '0h 0m';
    final duration = DateTime.now().difference(currentSession!.startTime);
    return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
  }

  /// ملخص النوم الليلة الماضية
  String get lastNightSummary {
    if (recentSessions.isEmpty) return 'لا توجد بيانات';
    final lastSession = recentSessions.first;
    final duration = lastSession.duration ?? Duration.zero;
    return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
  }

  /// درجة جودة النوم الليلة الماضية
  String get lastNightQuality {
    if (recentSessions.isEmpty) return 'غير متوفر';
    final lastSession = recentSessions.first;
    final quality = lastSession.qualityScore ?? 0.0;

    if (quality >= 8.0) return 'ممتاز';
    if (quality >= 6.0) return 'جيد';
    if (quality >= 4.0) return 'متوسط';
    if (quality >= 2.0) return 'ضعيف';
    return 'سيء جداً';
  }

  /// النسبة المئوية لتحقيق هدف الأسبوع
  double get weeklyGoalProgress {
    if (recentSessions.isEmpty) return 0.0;

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final weekSessions = recentSessions.where((session) {
      return session.startTime.isAfter(weekAgo) && session.isCompleted;
    }).toList();

    if (weekSessions.isEmpty) return 0.0;

    final achievedDays = weekSessions.where((session) {
      final duration = session.duration ?? Duration.zero;
      return duration.inHours >= sleepGoalHours;
    }).length;

    return (achievedDays / 7).clamp(0.0, 1.0);
  }

  /// إجمالي ساعات النوم هذا الأسبوع
  Duration get weeklyTotalSleep {
    if (recentSessions.isEmpty) return Duration.zero;

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final weekSessions = recentSessions.where((session) {
      return session.startTime.isAfter(weekAgo) && session.isCompleted;
    }).toList();

    return weekSessions.fold<Duration>(
      Duration.zero,
          (total, session) => total + (session.duration ?? Duration.zero),
    );
  }

  /// متوسط جودة النوم هذا الأسبوع
  double get weeklyAverageQuality {
    if (recentSessions.isEmpty) return 0.0;

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final weekSessions = recentSessions.where((session) {
      return session.startTime.isAfter(weekAgo) &&
          session.isCompleted &&
          session.qualityScore != null;
    }).toList();

    if (weekSessions.isEmpty) return 0.0;

    final totalQuality = weekSessions.fold<double>(
      0.0,
          (total, session) => total + (session.qualityScore ?? 0.0),
    );

    return totalQuality / weekSessions.length;
  }

  // ============ CopyWith ============

  SleepTrackingState copyWith({
    LoadingState? loadingState,
    AppError? error,
    DateTime? lastUpdated,
    bool? hasData,
    String? successMessage,
    bool? isAutoTrackingActive,
    bool? isInSleepWindow,
    SleepState? currentSleepState,
    double? sleepDetectionConfidence,
    TimeOfDay? sleepWindowStart,
    TimeOfDay? sleepWindowEnd,
    bool? adaptiveWindowEnabled,
    Object? currentSession = _undefined,
    List<SleepSession>? recentSessions,
    List<SleepSession>? pendingConfirmations,
    Object? currentEnvironment = _undefined,
    List<EnvironmentalConditions>? environmentHistory,
    double? environmentalQualityScore,
    Duration? averageSleepDuration,
    double? averageQualityScore,
    int? sleepGoalHours,
    bool? goalAchievedLastNight,
    int? consecutiveGoalDays,
    int? phoneUsageDuringSleep,
    int? nightInterruptions,
    List<String>? sleepDisruptingApps,
    Object? selectedDateRange = _undefined,
    String? viewMode,
  }) {
    // ✅ Debug للـ currentSession parameter
    debugPrint('🔧 [copyWith] currentSession parameter: ${currentSession == _undefined ? "UNDEFINED" : currentSession.runtimeType}');
    debugPrint('🔧 [copyWith] this.currentSession: ${this.currentSession?.id}');

    final newCurrentSession = currentSession == _undefined
        ? this.currentSession
        : currentSession as SleepSession?;

    debugPrint('🔧 [copyWith] newCurrentSession: ${newCurrentSession?.id}');

    return SleepTrackingState(
      loadingState: loadingState ?? this.loadingState,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      hasData: hasData ?? this.hasData,
      successMessage: successMessage ?? this.successMessage,
      isAutoTrackingActive: isAutoTrackingActive ?? this.isAutoTrackingActive,
      isInSleepWindow: isInSleepWindow ?? this.isInSleepWindow,
      currentSleepState: currentSleepState ?? this.currentSleepState,
      sleepDetectionConfidence: sleepDetectionConfidence ?? this.sleepDetectionConfidence,
      sleepWindowStart: sleepWindowStart ?? this.sleepWindowStart,
      sleepWindowEnd: sleepWindowEnd ?? this.sleepWindowEnd,
      adaptiveWindowEnabled: adaptiveWindowEnabled ?? this.adaptiveWindowEnabled,
      currentSession: newCurrentSession,
      recentSessions: recentSessions ?? this.recentSessions,
      pendingConfirmations: pendingConfirmations ?? this.pendingConfirmations,
      currentEnvironment: currentEnvironment == _undefined
          ? this.currentEnvironment
          : currentEnvironment as EnvironmentalConditions?,
      environmentHistory: environmentHistory ?? this.environmentHistory,
      environmentalQualityScore: environmentalQualityScore ?? this.environmentalQualityScore,
      averageSleepDuration: averageSleepDuration ?? this.averageSleepDuration,
      averageQualityScore: averageQualityScore ?? this.averageQualityScore,
      sleepGoalHours: sleepGoalHours ?? this.sleepGoalHours,
      goalAchievedLastNight: goalAchievedLastNight ?? this.goalAchievedLastNight,
      consecutiveGoalDays: consecutiveGoalDays ?? this.consecutiveGoalDays,
      phoneUsageDuringSleep: phoneUsageDuringSleep ?? this.phoneUsageDuringSleep,
      nightInterruptions: nightInterruptions ?? this.nightInterruptions,
      sleepDisruptingApps: sleepDisruptingApps ?? this.sleepDisruptingApps,
      selectedDateRange: selectedDateRange == _undefined
          ? this.selectedDateRange
          : selectedDateRange as DateTimeRange?,
      viewMode: viewMode ?? this.viewMode,
    );
  }

  @override
  String toString() {
    return 'SleepTrackingState('
        'autoTracking: $isAutoTrackingActive, '
        'sleepState: $currentSleepState, '
        'confidence: ${(sleepDetectionConfidence * 100).round()}%, '
        'hasActiveSession: $hasActiveSession, '
        'pendingConfirmations: ${pendingConfirmations.length}, '
        'recentSessions: ${recentSessions.length}'
        ')';
  }

  // ✅ استخدم EquatableMixin بدلاً من تعريف == و hashCode يدوياً
  @override
  List<Object?> get props => [
    loadingState,
    error,
    lastUpdated,
    hasData,
    successMessage,
    isAutoTrackingActive,
    isInSleepWindow,
    currentSleepState,
    sleepDetectionConfidence,
    sleepWindowStart,
    sleepWindowEnd,
    adaptiveWindowEnabled,
    currentSession, // ✅ هلق بيقارن currentSession صح!
    recentSessions,
    pendingConfirmations,
    currentEnvironment,
    environmentHistory,
    environmentalQualityScore,
    averageSleepDuration,
    averageQualityScore,
    sleepGoalHours,
    goalAchievedLastNight,
    consecutiveGoalDays,
    phoneUsageDuringSleep,
    nightInterruptions,
    sleepDisruptingApps,
    selectedDateRange,
    viewMode,
  ];
}