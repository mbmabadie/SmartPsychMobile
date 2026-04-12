// lib/providers/activity_type_stat.dart

import '../database/models/activity_models.dart';

class ActivityTypeStat {
  final ActivityType activityType;
  final int sessionCount;
  final Duration totalDuration;
  final Duration avgDuration;
  final double totalDistance;
  final double totalCalories;
  final int totalSteps;

  const ActivityTypeStat({
    required this.activityType,
    required this.sessionCount,
    required this.totalDuration,
    required this.avgDuration,
    required this.totalDistance,
    required this.totalCalories,
    required this.totalSteps,
  });

  String get formattedTotalDuration {
    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes.remainder(60);
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }

  String get formattedAvgDuration {
    final hours = avgDuration.inHours;
    final minutes = avgDuration.inMinutes.remainder(60);
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }

  String get formattedTotalDistance => '${totalDistance.toStringAsFixed(2)} كم';
  String get formattedTotalCalories => '${totalCalories.round()} سعرة';

  double get avgCaloriesPerSession => sessionCount > 0 ? totalCalories / sessionCount : 0.0;
  double get avgDistancePerSession => sessionCount > 0 ? totalDistance / sessionCount : 0.0;
  int get avgStepsPerSession => sessionCount > 0 ? (totalSteps / sessionCount).round() : 0;

  // نسبة من إجمالي الوقت
  double get durationRatio => totalDuration.inMinutes / (totalDuration.inMinutes > 0 ? totalDuration.inMinutes : 1);

  // كثافة النشاط (سعرات لكل دقيقة)
  double get intensityScore {
    final minutes = totalDuration.inMinutes;
    return minutes > 0 ? totalCalories / minutes : 0.0;
  }

  // تقييم الأداء
  String get performanceLevel {
    final avgCals = avgCaloriesPerSession;
    if (avgCals >= 300) return 'ممتاز';
    if (avgCals >= 200) return 'جيد جداً';
    if (avgCals >= 100) return 'جيد';
    if (avgCals >= 50) return 'متوسط';
    return 'منخفض';
  }

  Map<String, dynamic> toMap() {
    return {
      'activity_type': activityType.name,
      'session_count': sessionCount,
      'total_duration_minutes': totalDuration.inMinutes,
      'avg_duration_minutes': avgDuration.inMinutes,
      'total_distance': totalDistance,
      'total_calories': totalCalories,
      'total_steps': totalSteps,
      'avg_calories_per_session': avgCaloriesPerSession,
      'avg_distance_per_session': avgDistancePerSession,
      'avg_steps_per_session': avgStepsPerSession,
      'intensity_score': intensityScore,
      'performance_level': performanceLevel,
    };
  }

  factory ActivityTypeStat.fromMap(Map<String, dynamic> map) {
    return ActivityTypeStat(
      activityType: ActivityType.values.firstWhere(
            (e) => e.name == map['activity_type'],
        orElse: () => ActivityType.general,
      ),
      sessionCount: map['session_count'] as int,
      totalDuration: Duration(minutes: map['total_duration_minutes'] as int),
      avgDuration: Duration(minutes: map['avg_duration_minutes'] as int),
      totalDistance: (map['total_distance'] as num).toDouble(),
      totalCalories: (map['total_calories'] as num).toDouble(),
      totalSteps: map['total_steps'] as int,
    );
  }

  @override
  String toString() {
    return 'ActivityTypeStat($activityType: $sessionCount sessions, $formattedTotalDuration total, ${formattedTotalCalories})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActivityTypeStat &&
        other.activityType == activityType &&
        other.sessionCount == sessionCount;
  }

  @override
  int get hashCode => Object.hash(activityType, sessionCount);
}