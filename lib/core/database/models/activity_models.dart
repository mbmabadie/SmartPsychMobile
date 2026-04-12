// lib/core/models/activity_models.dart - مُصحح بالكامل

import 'package:flutter/material.dart';

enum ActivityIntensity { low, moderate, high }
enum MoodImpact { positive, neutral, negative }

class DailyActivity {
  final int? id;
  final String date; // YYYY-MM-DD format
  final int totalSteps;
  final double distance; // المسافة الإجمالية بالكيلومترات
  final Duration? duration; // مدة النشاط الإجمالية
  final double caloriesBurned; // السعرات المحروقة
  final int activeMinutes; // الدقائق النشطة
  final double averageSpeed; // متوسط السرعة km/h - KEEP THIS FOR DATABASE COMPATIBILITY
  final int floorsClimbed; // الطوابق المتسلقة
  final Map<ActivityType, Duration> activityBreakdown; // تفصيل الأنشطة
  final Map<ActivityType, double> activityCalories; // السعرات لكل نشاط
  final double intensityScore; // معدل الكثافة (0.0 - 1.0)
  final int sedentaryMinutes; // دقائق عدم الحركة
  final String? activityType; // نوع النشاط الرئيسي
  final double fitnessScore; // نقاط اللياقة
  final int goalSteps; // ✅ هدف الخطوات لهذا اليوم
  final double goalDistance; // ✅ هدف المسافة لهذا اليوم
  final double goalCalories; // ✅ هدف السعرات لهذا اليوم
  final DateTime createdAt;
  final DateTime updatedAt;

  const DailyActivity({
    this.id,
    required this.date,
    required this.totalSteps,
    required this.distance,
    this.duration,
    required this.caloriesBurned,
    required this.activeMinutes,
    this.averageSpeed = 0.0, // KEEP DEFAULT VALUE
    this.floorsClimbed = 0,
    this.activityBreakdown = const {},
    this.activityCalories = const {},
    this.intensityScore = 0.0,
    this.sedentaryMinutes = 0,
    this.activityType,
    this.fitnessScore = 0.0,
    this.goalSteps = 10000, // ✅ قيمة افتراضية
    this.goalDistance = 8.0, // ✅ قيمة افتراضية
    this.goalCalories = 500.0, // ✅ قيمة افتراضية
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyActivity.fromMap(Map<String, dynamic> map) {
    // Parse activity breakdown with safe JSON handling
    Map<ActivityType, Duration> breakdown = {};
    if (map['activity_breakdown'] != null) {
      try {
        final breakdownData = map['activity_breakdown'] is String
            ? {} // إذا كان string فارغ، استخدم map فارغ
            : Map<String, dynamic>.from(map['activity_breakdown'] as Map);

        for (final entry in breakdownData.entries) {
          final activityType = ActivityType.values.firstWhere(
                (e) => e.name == entry.key,
            orElse: () => ActivityType.other,
          );
          breakdown[activityType] = Duration(milliseconds: entry.value as int);
        }
      } catch (e) {
        debugPrint('خطأ في تحليل activity_breakdown: $e');
      }
    }

    // Parse activity calories with safe JSON handling
    Map<ActivityType, double> calories = {};
    if (map['activity_calories'] != null) {
      try {
        final caloriesData = map['activity_calories'] is String
            ? {} // إذا كان string فارغ، استخدم map فارغ
            : Map<String, dynamic>.from(map['activity_calories'] as Map);

        for (final entry in caloriesData.entries) {
          final activityType = ActivityType.values.firstWhere(
                (e) => e.name == entry.key,
            orElse: () => ActivityType.other,
          );
          calories[activityType] = (entry.value as num).toDouble();
        }
      } catch (e) {
        debugPrint('خطأ في تحليل activity_calories: $e');
      }
    }

    return DailyActivity(
      id: map['id'] as int?,
      date: map['date'] as String? ?? '',
      totalSteps: map['total_steps'] as int? ?? 0,
      distance: (map['distance'] as num?)?.toDouble() ?? 0.0,
      duration: map['duration'] != null
          ? Duration(seconds: map['duration'] as int) // تغيير من milliseconds إلى seconds
          : null,
      caloriesBurned: (map['calories_burned'] as num?)?.toDouble() ?? 0.0,
      activeMinutes: map['active_minutes'] as int? ?? 0,
      averageSpeed: (map['average_speed'] as num?)?.toDouble() ?? 0.0, // KEEP THIS
      floorsClimbed: map['floors_climbed'] as int? ?? 0,
      activityBreakdown: breakdown,
      activityCalories: calories,
      intensityScore: (map['intensity_score'] as num?)?.toDouble() ?? 0.0,
      sedentaryMinutes: map['sedentary_minutes'] as int? ?? 0,
      activityType: map['activity_type'] as String?,
      fitnessScore: (map['fitness_score'] as num?)?.toDouble() ?? 0.0,
      goalSteps: map['goal_steps'] as int? ?? 10000, // ✅ قراءة الهدف
      goalDistance: (map['goal_distance'] as num?)?.toDouble() ?? 8.0, // ✅ قراءة الهدف
      goalCalories: (map['goal_calories'] as num?)?.toDouble() ?? 500.0, // ✅ قراءة الهدف
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updated_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    // Convert activity breakdown to JSON string for database storage
    String breakdownJson = '{}';
    if (activityBreakdown.isNotEmpty) {
      try {
        final breakdownMap = <String, dynamic>{};
        for (final entry in activityBreakdown.entries) {
          breakdownMap[entry.key.name] = entry.value.inSeconds; // تغيير إلى seconds
        }
        breakdownJson = breakdownMap.toString(); // استخدام toString بدلاً من JSON
      } catch (e) {
        debugPrint('خطأ في تحويل activity_breakdown: $e');
      }
    }

    // Convert activity calories to JSON string for database storage
    String caloriesJson = '{}';
    if (activityCalories.isNotEmpty) {
      try {
        final caloriesMap = <String, dynamic>{};
        for (final entry in activityCalories.entries) {
          caloriesMap[entry.key.name] = entry.value;
        }
        caloriesJson = caloriesMap.toString(); // استخدام toString بدلاً من JSON
      } catch (e) {
        debugPrint('خطأ في تحويل activity_calories: $e');
      }
    }

    return {
      if (id != null) 'id': id,
      'date': date,
      'total_steps': totalSteps,
      'distance': distance,
      'duration': duration?.inSeconds, // تغيير إلى seconds
      'calories_burned': caloriesBurned,
      'active_minutes': activeMinutes,
      'average_speed': averageSpeed, // KEEP THIS FOR DATABASE COMPATIBILITY
      'floors_climbed': floorsClimbed,
      'activity_breakdown': breakdownJson,
      'activity_calories': caloriesJson,
      'intensity_score': intensityScore,
      'sedentary_minutes': sedentaryMinutes,
      'activity_type': activityType ?? 'general',
      'fitness_score': fitnessScore,
      'goal_steps': goalSteps, // ✅ حفظ الهدف
      'goal_distance': goalDistance, // ✅ حفظ الهدف
      'goal_calories': goalCalories, // ✅ حفظ الهدف
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  DailyActivity copyWith({
    int? id,
    String? date,
    int? totalSteps,
    double? distance,
    Duration? duration,
    double? caloriesBurned,
    int? activeMinutes,
    double? averageSpeed, // KEEP THIS
    int? floorsClimbed,
    Map<ActivityType, Duration>? activityBreakdown,
    Map<ActivityType, double>? activityCalories,
    double? intensityScore,
    int? sedentaryMinutes,
    String? activityType,
    double? fitnessScore,
    int? goalSteps, // ✅ جديد
    double? goalDistance, // ✅ جديد
    double? goalCalories, // ✅ جديد
    DateTime? updatedAt,
  }) {
    return DailyActivity(
      id: id ?? this.id,
      date: date ?? this.date,
      totalSteps: totalSteps ?? this.totalSteps,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      averageSpeed: averageSpeed ?? this.averageSpeed, // KEEP THIS
      floorsClimbed: floorsClimbed ?? this.floorsClimbed,
      activityBreakdown: activityBreakdown ?? this.activityBreakdown,
      activityCalories: activityCalories ?? this.activityCalories,
      intensityScore: intensityScore ?? this.intensityScore,
      sedentaryMinutes: sedentaryMinutes ?? this.sedentaryMinutes,
      activityType: activityType ?? this.activityType,
      fitnessScore: fitnessScore ?? this.fitnessScore,
      goalSteps: goalSteps ?? this.goalSteps, // ✅ جديد
      goalDistance: goalDistance ?? this.goalDistance, // ✅ جديد
      goalCalories: goalCalories ?? this.goalCalories, // ✅ جديد
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Computed properties - نفس الكود الموجود مع بعض التحسينات
  String get formattedDistance => distance > 0 ? '${distance.toStringAsFixed(2)} كم' : '0 كم';

  String get formattedDuration {
    if (duration == null || duration!.inSeconds == 0) return '0 دقيقة';
    final hours = duration!.inHours;
    final minutes = duration!.inMinutes.remainder(60);
    return hours > 0 ? '${hours}س ${minutes}د' : '${minutes}د';
  }

  String get formattedCalories => caloriesBurned > 0 ? '${caloriesBurned.round()} سعرة' : '0 سعرة';

  String get formattedSpeed => averageSpeed > 0 ? '${averageSpeed.toStringAsFixed(1)} كم/س' : '0 كم/س';

  // Activity level based on WHO recommendations
  String get activityLevel {
    if (totalSteps >= 12000 && activeMinutes >= 75) return 'نشط جداً';
    if (totalSteps >= 10000 && activeMinutes >= 60) return 'نشط';
    if (totalSteps >= 7500 && activeMinutes >= 30) return 'معتدل النشاط';
    if (totalSteps >= 5000 && activeMinutes >= 15) return 'قليل النشاط';
    if (totalSteps >= 2000) return 'نشاط محدود';
    return 'خامل';
  }

  // Health status based on activity
  HealthStatus get healthStatus {
    final stepsGood = totalSteps >= 8000;
    final activeTimeGood = activeMinutes >= 30;
    final sedentaryOk = sedentaryMinutes <= 480; // 8 hours max

    if (stepsGood && activeTimeGood && sedentaryOk) return HealthStatus.excellent;
    if ((stepsGood && activeTimeGood) || (stepsGood && sedentaryOk)) return HealthStatus.good;
    if (stepsGood || activeTimeGood) return HealthStatus.fair;
    return HealthStatus.poor;
  }

  // Calories per step (average)
  double get caloriesPerStep => totalSteps > 0 ? caloriesBurned / totalSteps : 0.0;

  // Steps per minute (when active)
  double get stepsPerActiveMinute => activeMinutes > 0 ? totalSteps / activeMinutes : 0.0;

  // Most active activity type
  ActivityType? get mostActiveActivity {
    if (activityBreakdown.isEmpty) return null;

    var maxDuration = Duration.zero;
    ActivityType? mostActive;

    for (final entry in activityBreakdown.entries) {
      if (entry.value > maxDuration) {
        maxDuration = entry.value;
        mostActive = entry.key;
      }
    }

    return mostActive;
  }

  // Total active time (sum of all activities except still/unknown)
  Duration get totalActiveTime {
    return activityBreakdown.entries
        .where((entry) => entry.key != ActivityType.still && entry.key != ActivityType.unknown)
        .fold(Duration.zero, (total, entry) => total + entry.value);
  }

  // Activity diversity score (how many different activities)
  double get activityDiversityScore {
    final activeTypes = activityBreakdown.entries
        .where((entry) => entry.value.inMinutes > 5) // At least 5 minutes
        .length;
    return activeTypes > 0 ? (activeTypes / ActivityType.values.length).clamp(0.0, 1.0) : 0.0;
  }

  // Sedentary ratio
  double get sedentaryRatio {
    final totalMinutes = const Duration(hours: 24).inMinutes;
    return totalMinutes > 0 ? sedentaryMinutes / totalMinutes : 0.0;
  }

  // Is this a weekend day?
  bool get isWeekend {
    try {
      final dateTime = DateTime.parse(date);
      return dateTime.weekday == DateTime.saturday || dateTime.weekday == DateTime.sunday;
    } catch (e) {
      return false;
    }
  }

  // Compare with targets
  bool meetsStepsTarget([int target = 10000]) => totalSteps >= target;
  bool meetsActiveTarget([int target = 30]) => activeMinutes >= target;
  bool meetsDistanceTarget([double target = 5.0]) => distance >= target;
  bool meetsCaloriesTarget([double target = 300.0]) => caloriesBurned >= target;

  // Progress towards targets (0.0 - 1.0+)
  double stepsProgress([int target = 10000]) => target > 0 ? totalSteps / target : 0.0;
  double activeProgress([int target = 30]) => target > 0 ? activeMinutes / target : 0.0;
  double distanceProgress([double target = 5.0]) => target > 0 ? distance / target : 0.0;
  double caloriesProgress([double target = 300.0]) => target > 0 ? caloriesBurned / target : 0.0;

  // Activity summary text
  String get activitySummary {
    if (totalSteps == 0 && activeMinutes == 0) {
      return 'لم يتم تسجيل أي نشاط اليوم';
    }

    final parts = <String>[];
    if (totalSteps > 0) parts.add('$totalSteps خطوة');
    if (activeMinutes > 0) parts.add('$activeMinutes دقيقة نشطة');
    if (distance > 0) parts.add(formattedDistance);
    if (caloriesBurned > 0) parts.add(formattedCalories);

    return parts.join(' • ');
  }

  // Recommendations based on activity
  List<String> get recommendations {
    final recommendations = <String>[];

    if (totalSteps < 5000) {
      recommendations.add('حاول المشي أكثر - اهدف لـ 10,000 خطوة يومياً');
    } else if (totalSteps < 8000) {
      recommendations.add('تقدم جيد! حاول زيادة الخطوات تدريجياً');
    }

    if (activeMinutes < 30) {
      recommendations.add('احتاج 30 دقيقة نشاط يومياً على الأقل');
    }

    if (sedentaryMinutes > 480) {
      recommendations.add('حاول تقليل وقت الجلوس - قم بحركات كل ساعة');
    }

    if (intensityScore < 0.5) {
      recommendations.add('جرب إضافة أنشطة أكثر كثافة كالجري أو السباحة');
    }

    if (recommendations.isEmpty) {
      recommendations.add('ممتاز! حافظ على هذا المستوى من النشاط');
    }

    return recommendations;
  }

  @override
  String toString() {
    return 'DailyActivity($date: $totalSteps steps, $formattedDistance, $activeMinutes active min, level: $activityLevel)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyActivity &&
        other.id == id &&
        other.date == date;
  }

  @override
  int get hashCode => Object.hash(id, date);
}

/// Health Status enum - تقييم الحالة الصحية
enum HealthStatus {
  excellent('ممتاز'),
  good('جيد'),
  fair('مقبول'),
  poor('ضعيف');

  const HealthStatus(this.displayName);
  final String displayName;

  @override
  String toString() => displayName;

  Color get color {
    switch (this) {
      case HealthStatus.excellent:
        return const Color(0xFF4CAF50); // Green
      case HealthStatus.good:
        return const Color(0xFF8BC34A); // Light Green
      case HealthStatus.fair:
        return const Color(0xFFFF9800); // Orange
      case HealthStatus.poor:
        return const Color(0xFFF44336); // Red
    }
  }

  IconData get icon {
    switch (this) {
      case HealthStatus.excellent:
        return Icons.sentiment_very_satisfied;
      case HealthStatus.good:
        return Icons.sentiment_satisfied;
      case HealthStatus.fair:
        return Icons.sentiment_neutral;
      case HealthStatus.poor:
        return Icons.sentiment_dissatisfied;
    }
  }
}

/// Activity Type enum - أنواع الأنشطة
enum ActivityType {
  general('عام'),
  walking('المشي'),
  running('الجري'),
  cycling('ركوب الدراجة'),
  driving('القيادة'),
  still('ساكن'),
  unknown('غير معروف'),
  other('أخرى'),
  swimming('السباحة'),
  yoga('اليوغا'),
  weightLifting('رفع الأثقال'),
  dancing('الرقص'),
  climbing('التسلق');

  const ActivityType(this.displayName);
  final String displayName;

  @override
  String toString() => displayName;

  // Activity intensity (METs - Metabolic Equivalent of Task)
  double get mets {
    switch (this) {
      case ActivityType.general:
        return 3.0;
      case ActivityType.walking:
        return 3.5;
      case ActivityType.running:
        return 8.0;
      case ActivityType.cycling:
        return 6.0;
      case ActivityType.swimming:
        return 7.0;
      case ActivityType.weightLifting:
        return 5.0;
      case ActivityType.dancing:
        return 4.5;
      case ActivityType.climbing:
        return 8.5;
      case ActivityType.yoga:
        return 2.5;
      case ActivityType.still:
      case ActivityType.driving:
        return 1.5;
      case ActivityType.unknown:
      case ActivityType.other:
      default:
        return 3.0;
    }
  }

  // Activity category
  ActivityCategory get category {
    switch (this) {
      case ActivityType.general:
        return ActivityCategory.general;
      case ActivityType.walking:
      case ActivityType.running:
        return ActivityCategory.cardio;
      case ActivityType.cycling:
      case ActivityType.swimming:
        return ActivityCategory.cardio;
      case ActivityType.weightLifting:
        return ActivityCategory.strength;
      case ActivityType.yoga:
        return ActivityCategory.flexibility;
      case ActivityType.dancing:
        return ActivityCategory.cardio;
      case ActivityType.climbing:
        return ActivityCategory.strength;
      case ActivityType.still:
      case ActivityType.driving:
        return ActivityCategory.sedentary;
      case ActivityType.unknown:
      case ActivityType.other:
      default:
        return ActivityCategory.general;
    }
  }

  // Icon for UI
  IconData get icon {
    switch (this) {
      case ActivityType.general:
        return Icons.sports;
      case ActivityType.walking:
        return Icons.directions_walk;
      case ActivityType.running:
        return Icons.directions_run;
      case ActivityType.cycling:
        return Icons.directions_bike;
      case ActivityType.driving:
        return Icons.directions_car;
      case ActivityType.swimming:
        return Icons.pool;
      case ActivityType.yoga:
        return Icons.self_improvement;
      case ActivityType.weightLifting:
        return Icons.fitness_center;
      case ActivityType.dancing:
        return Icons.music_note;
      case ActivityType.climbing:
        return Icons.terrain;
      case ActivityType.still:
        return Icons.hotel;
      case ActivityType.unknown:
      case ActivityType.other:
      default:
        return Icons.sports;
    }
  }
}

/// Activity Category enum - تصنيفات الأنشطة
enum ActivityCategory {
  cardio('كارديو'),
  strength('قوة'),
  flexibility('مرونة'),
  balance('توازن'),
  sedentary('خامل'),
  general('عام');

  const ActivityCategory(this.displayName);
  final String displayName;

  @override
  String toString() => displayName;
}

class ActivitySession {
  final int? id;
  final int? dailyActivityId;
  final ActivityType activityType;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration? duration;
  final double distance;
  final double caloriesBurned;
  final int steps;
  final String date; // YYYY-MM-DD format
  final String? notes;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ActivitySession({
    this.id,
    this.dailyActivityId,
    required this.activityType,
    required this.startTime,
    this.endTime,
    this.duration,
    this.distance = 0.0,
    this.caloriesBurned = 0.0,
    this.steps = 0,
    required this.date,
    this.notes,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ActivitySession.fromMap(Map<String, dynamic> map) {
    return ActivitySession(
      id: map['id'] as int?,
      dailyActivityId: map['daily_activity_id'] as int?,
      activityType: ActivityType.values.firstWhere(
            (e) => e.name == map['activity_type'],
        orElse: () => ActivityType.other,
      ),
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
      endTime: map['end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int)
          : null,
      duration: map['duration'] != null
          ? Duration(seconds: map['duration'] as int) // تغيير إلى seconds
          : null,
      distance: (map['distance_meters'] as num?)?.toDouble() ?? 0.0,
      caloriesBurned: (map['calories_burned'] as num?)?.toDouble() ?? 0.0,
      steps: map['steps'] as int? ?? 0,
      date: map['date'] as String? ?? _formatDateFromTimestamp(map['start_time'] as int),
      notes: map['notes'] as String?,
      isCompleted: (map['is_completed'] as int?) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updated_at'] as int? ?? map['created_at'] as int,
      ),
    );
  }

  static String _formatDateFromTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'daily_activity_id': dailyActivityId,
      'activity_type': activityType.name,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'duration': duration?.inSeconds, // تغيير إلى seconds
      'distance_meters': distance,
      'calories_burned': caloriesBurned,
      'steps': steps,
      'date': date,
      'notes': notes,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  ActivitySession copyWith({
    int? id,
    int? dailyActivityId,
    ActivityType? activityType,
    DateTime? startTime,
    DateTime? endTime,
    Duration? duration,
    double? distance,
    double? caloriesBurned,
    int? steps,
    String? date,
    String? notes,
    bool? isCompleted,
    DateTime? updatedAt,
  }) {
    return ActivitySession(
      id: id ?? this.id,
      dailyActivityId: dailyActivityId ?? this.dailyActivityId,
      activityType: activityType ?? this.activityType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      distance: distance ?? this.distance,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      steps: steps ?? this.steps,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Computed properties
  String get formattedDuration {
    if (duration == null || duration!.inSeconds == 0) return '0د';
    final hours = duration!.inHours;
    final minutes = duration!.inMinutes.remainder(60);
    return hours > 0 ? '${hours}س ${minutes}د' : '${minutes}د';
  }

  String get formattedDistance => distance > 0 ? '${distance.toStringAsFixed(2)} كم' : '0 كم';
  String get formattedCalories => caloriesBurned > 0 ? '${caloriesBurned.round()} سعرة' : '0 سعرة';

  @override
  String toString() {
    return 'ActivitySession(type: $activityType, duration: $formattedDuration, completed: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActivitySession &&
        other.id == id &&
        other.startTime == startTime &&
        other.activityType == activityType;
  }

  @override
  int get hashCode => Object.hash(id, startTime, activityType);
}

class LocationVisit {
  final int? id;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final String? placeName;
  final String? placeType;
  final String? placeCategory;
  final MoodImpact? moodImpact;
  final DateTime arrivalTime;
  final DateTime? departureTime;
  final Duration? duration;
  final int visitFrequency;
  final bool isHome;
  final bool isWork;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LocationVisit({
    this.id,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.placeName,
    this.placeType,
    this.placeCategory,
    this.moodImpact,
    required this.arrivalTime,
    this.departureTime,
    this.duration,
    this.visitFrequency = 1,
    this.isHome = false,
    this.isWork = false,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LocationVisit.fromMap(Map<String, dynamic> map) {
    return LocationVisit(
      id: map['id'] as int?,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      accuracy: map['accuracy'] != null ? (map['accuracy'] as num).toDouble() : null,
      altitude: map['altitude'] != null ? (map['altitude'] as num).toDouble() : null,
      placeName: map['place_name'] as String?,
      placeType: map['place_type'] as String?,
      placeCategory: map['place_category'] as String?,
      moodImpact: map['mood_impact'] != null
          ? MoodImpact.values.firstWhere((e) => e.name == map['mood_impact'])
          : null,
      arrivalTime: DateTime.fromMillisecondsSinceEpoch(map['arrival_time'] as int),
      departureTime: map['departure_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['departure_time'] as int)
          : null,
      duration: map['duration'] != null
          ? Duration(seconds: map['duration'] as int)
          : null,
      visitFrequency: map['visit_frequency'] as int? ?? 1,
      isHome: (map['is_home'] as int?) == 1,
      isWork: (map['is_work'] as int?) == 1,
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'place_name': placeName,
      'place_type': placeType,
      'place_category': placeCategory,
      'mood_impact': moodImpact?.name,
      'arrival_time': arrivalTime.millisecondsSinceEpoch,
      'departure_time': departureTime?.millisecondsSinceEpoch,
      'duration': duration?.inSeconds,
      'visit_frequency': visitFrequency,
      'is_home': isHome ? 1 : 0,
      'is_work': isWork ? 1 : 0,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  LocationVisit copyWith({
    int? id,
    double? latitude,
    double? longitude,
    double? accuracy,
    double? altitude,
    String? placeName,
    String? placeType,
    String? placeCategory,
    MoodImpact? moodImpact,
    DateTime? arrivalTime,
    DateTime? departureTime,
    Duration? duration,
    int? visitFrequency,
    bool? isHome,
    bool? isWork,
    String? notes,
    DateTime? updatedAt,
  }) {
    return LocationVisit(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      placeName: placeName ?? this.placeName,
      placeType: placeType ?? this.placeType,
      placeCategory: placeCategory ?? this.placeCategory,
      moodImpact: moodImpact ?? this.moodImpact,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      departureTime: departureTime ?? this.departureTime,
      duration: duration ?? this.duration,
      visitFrequency: visitFrequency ?? this.visitFrequency,
      isHome: isHome ?? this.isHome,
      isWork: isWork ?? this.isWork,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'LocationVisit(place: $placeName, coords: ($latitude, $longitude), visits: $visitFrequency)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationVisit &&
        other.id == id &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(id, latitude, longitude);
}