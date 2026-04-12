// lib/core/providers/activity_tracking_state.dart - إصلاح مُباشر
import 'package:flutter/foundation.dart';
import '../database/models/common_models.dart';
import '../database/models/goal_type.dart';
import '../database/models/user_profile.dart';
import '../database/models/activity_models.dart';
import '../services/insights_service.dart';
import 'base/base_state.dart';

/// Activity Detection Result
@immutable
class ActivityDetectionResult {
  final ActivityType detectedActivity;
  final double confidence;
  final DateTime timestamp;
  final Map<String, dynamic> sensorData;
  final String reason;

  const ActivityDetectionResult({
    required this.detectedActivity,
    required this.confidence,
    required this.timestamp,
    this.sensorData = const {},
    this.reason = '',
  });

  bool get isHighConfidence => confidence > 0.8;
  bool get isMediumConfidence => confidence > 0.6;
  bool get isLowConfidence => confidence > 0.4;

  @override
  String toString() {
    return 'ActivityDetectionResult(activity: $detectedActivity, confidence: ${(confidence * 100).round()}%, reason: $reason)';
  }
}

/// Activity Goal
@immutable
class ActivityGoal {
  final String id;
  final String title;
  final ActivityType activityType;
  final GoalType goalType;
  final double targetValue;
  final String unit;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final double currentProgress;

  const ActivityGoal({
    required this.id,
    required this.title,
    required this.activityType,
    required this.goalType,
    required this.targetValue,
    required this.unit,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.currentProgress = 0.0,
  });

  double get progressPercentage => (currentProgress / targetValue).clamp(0.0, 1.0);
  bool get isCompleted => currentProgress >= targetValue;
  bool get isExpired => endDate != null && DateTime.now().isAfter(endDate!);

  String get formattedProgress {
    switch (goalType) {
      case GoalType.steps:
        return '${currentProgress.round()}/${targetValue.round()} خطوة';
      case GoalType.distance:
        return '${currentProgress.toStringAsFixed(2)}/${targetValue.toStringAsFixed(2)} كم';
      case GoalType.duration:
        final currentMin = (currentProgress / 60).round();
        final targetMin = (targetValue / 60).round();
        return '$currentMin/$targetMin دقيقة';
      case GoalType.calories:
        return '${currentProgress.round()}/${targetValue.round()} سعرة';
      case GoalType.meals:
        return '${currentProgress.round()}/${targetValue.round()} وجبة';
      case GoalType.breakfast:
        return currentProgress >= 1 ? 'تم تناول الإفطار' : 'لم يتم تناول الإفطار';
      case GoalType.lunch:
        return currentProgress >= 1 ? 'تم تناول الغداء' : 'لم يتم تناول الغداء';
      case GoalType.dinner:
        return currentProgress >= 1 ? 'تم تناول العشاء' : 'لم يتم تناول العشاء';
    }
  }

  @override
  String toString() {
    return 'ActivityGoal($title: $formattedProgress, ${(progressPercentage * 100).round()}%)';
  }
}

/// Activity Summary من البيانات الحقيقية
@immutable
class ActivitySummary {
  final String date;
  final int totalSteps;
  final double totalDistance;
  final Duration totalDuration;
  final double caloriesBurned;
  final Map<ActivityType, Duration> activityBreakdown;
  final List<String> completedGoals;
  final double intensityScore;
  final int activeMinutes;

  const ActivitySummary({
    required this.date,
    required this.totalSteps,
    required this.totalDistance,
    required this.totalDuration,
    required this.caloriesBurned,
    this.activityBreakdown = const {},
    this.completedGoals = const [],
    required this.intensityScore,
    required this.activeMinutes,
  });

  // دالة لإنشاء ملخص فارغ لأي تاريخ
  factory ActivitySummary.empty(String date) {
    return ActivitySummary(
      date: date,
      totalSteps: 0,
      totalDistance: 0.0,
      totalDuration: Duration.zero,
      caloriesBurned: 0.0,
      activityBreakdown: {},
      completedGoals: [],
      intensityScore: 0.0,
      activeMinutes: 0,
    );
  }

  // دالة لإنشاء ملخص فارغ لليوم الحالي
  factory ActivitySummary.emptyToday() {
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return ActivitySummary.empty(dateStr);
  }

  String get formattedDistance => '${totalDistance.toStringAsFixed(2)} كم';
  String get formattedDuration => '${totalDuration.inHours}h ${totalDuration.inMinutes.remainder(60)}m';
  String get formattedCalories => '${caloriesBurned.round()} سعرة';

  String get activityLevel {
    if (totalSteps >= 12000 && activeMinutes >= 60) return 'نشط جداً';
    if (totalSteps >= 8000 && activeMinutes >= 30) return 'نشط';
    if (totalSteps >= 5000 && activeMinutes >= 15) return 'معتدل';
    if (totalSteps >= 2000) return 'قليل النشاط';
    return 'خامل';
  }

  @override
  String toString() {
    return 'ActivitySummary($date: $totalSteps steps, $formattedDistance, $activityLevel)';
  }
}

/// Activity Tracking State - مع ضمان todaysSummary
class ActivityTrackingState extends BaseState {
  final bool isTracking;
  final bool autoDetectionEnabled;
  final ActivitySession? currentSession;
  final List<ActivitySession> recentSessions;
  final ActivityDetectionResult? lastDetection;
  final ActivitySummary todaysSummary; // ← لا يمكن أن يكون null
  final List<ActivityGoal> activeGoals;
  final List<DailyActivity> recentActivities;
  final Map<String, dynamic> activityStats;
  final double fitnessScore;
  final DateTime? lastActivityCheck;
  final bool hasHealthPermissions;
  final UserProfile? userProfile;
  final List<Insight>? insights;

  ActivityTrackingState({
    super.loadingState,
    super.error,
    super.lastUpdated,
    super.hasData,
    super.successMessage,
    this.isTracking = false,
    this.autoDetectionEnabled = true,
    this.currentSession,
    this.recentSessions = const [],
    this.lastDetection,
    ActivitySummary? todaysSummary, // مؤقتاً nullable لتمرير null
    this.activeGoals = const [],
    this.recentActivities = const [],
    this.activityStats = const {},
    this.fitnessScore = 0.0,
    this.lastActivityCheck,
    this.hasHealthPermissions = false,
    this.userProfile,
    this.insights,
  }) : todaysSummary = todaysSummary ?? ActivitySummary.emptyToday(); // ← هنا الضمانة!

  // Factory method مُحدث
  factory ActivityTrackingState.initial() {
    return ActivityTrackingState(
      loadingState: LoadingState.success, // ← تغيير من idle إلى success
      hasData: true, // ← تغيير إلى true لأن لدينا بيانات (حتى لو فارغة)
      todaysSummary: ActivitySummary.emptyToday(), // ← ملخص فارغ لليوم
      insights: null,
    );
  }

  factory ActivityTrackingState.loading({bool isRefreshing = false}) {
    return ActivityTrackingState(
      loadingState: isRefreshing ? LoadingState.refreshing : LoadingState.loading,
      hasData: false,
      todaysSummary: ActivitySummary.emptyToday(), // ← حتى في Loading
      insights: null,
    );
  }

  bool get hasActiveSession => currentSession != null && !currentSession!.isCompleted;
  bool get canStartTracking => !isTracking;
  bool get hasActiveGoals => activeGoals.any((goal) => goal.isActive);
  bool get hasCompletedGoalsToday => activeGoals.any((goal) => goal.isCompleted);

  // خصائص الرؤى
  bool get hasInsights => insights != null && insights!.isNotEmpty;
  int get insightsCount => insights?.length ?? 0;
  List<Insight> get positiveInsights => insights?.where((i) => i.insightType == InsightType.positive).toList() ?? [];
  List<Insight> get negativeInsights => insights?.where((i) => i.insightType == InsightType.negative).toList() ?? [];
  List<Insight> get neutralInsights => insights?.where((i) => i.insightType == InsightType.neutral).toList() ?? [];

  bool get isHealthy {
    final steps = todaysSummary.totalSteps;
    return steps >= 8000;
  }

  String get todaysSteps => '${todaysSummary.totalSteps}';
  String get todaysDistance => todaysSummary.formattedDistance;
  String get todaysCalories => todaysSummary.formattedCalories;

  String get fitnessGrade {
    if (fitnessScore >= 0.9) return 'ممتاز';
    if (fitnessScore >= 0.8) return 'جيد جداً';
    if (fitnessScore >= 0.7) return 'جيد';
    if (fitnessScore >= 0.6) return 'مقبول';
    if (fitnessScore >= 0.5) return 'ضعيف';
    return 'ضعيف جداً';
  }

  List<ActivityGoal> get completedGoals => activeGoals.where((goal) => goal.isCompleted).toList();
  List<ActivityGoal> get pendingGoals => activeGoals.where((goal) => !goal.isCompleted && goal.isActive).toList();

  ActivityTrackingState copyWith({
    LoadingState? loadingState,
    AppError? error,
    DateTime? lastUpdated,
    bool? hasData,
    String? successMessage,
    bool? isTracking,
    bool? autoDetectionEnabled,
    ActivitySession? currentSession,
    List<ActivitySession>? recentSessions,
    ActivityDetectionResult? lastDetection,
    ActivitySummary? todaysSummary,
    List<ActivityGoal>? activeGoals,
    List<DailyActivity>? recentActivities,
    Map<String, dynamic>? activityStats,
    double? fitnessScore,
    DateTime? lastActivityCheck,
    bool? hasHealthPermissions,
    UserProfile? userProfile,
    List<Insight>? insights,
  }) {
    return ActivityTrackingState(
      loadingState: loadingState ?? this.loadingState,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      hasData: hasData ?? this.hasData,
      successMessage: successMessage ?? this.successMessage,
      isTracking: isTracking ?? this.isTracking,
      autoDetectionEnabled: autoDetectionEnabled ?? this.autoDetectionEnabled,
      currentSession: currentSession ?? this.currentSession,
      recentSessions: recentSessions ?? this.recentSessions,
      lastDetection: lastDetection ?? this.lastDetection,
      todaysSummary: todaysSummary ?? this.todaysSummary, // ← هنا سيأخذ القيمة الموجودة أو الجديدة
      activeGoals: activeGoals ?? this.activeGoals,
      recentActivities: recentActivities ?? this.recentActivities,
      activityStats: activityStats ?? this.activityStats,
      fitnessScore: fitnessScore ?? this.fitnessScore,
      lastActivityCheck: lastActivityCheck ?? this.lastActivityCheck,
      hasHealthPermissions: hasHealthPermissions ?? this.hasHealthPermissions,
      userProfile: userProfile ?? this.userProfile,
      insights: insights ?? this.insights,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActivityTrackingState &&
        other.isTracking == isTracking &&
        other.autoDetectionEnabled == autoDetectionEnabled &&
        other.currentSession == currentSession &&
        other.fitnessScore == fitnessScore &&
        other.insightsCount == insightsCount;
  }

  @override
  int get hashCode => Object.hash(
    super.hashCode,
    isTracking,
    autoDetectionEnabled,
    currentSession,
    fitnessScore,
    insightsCount,
  );
}