// lib/core/database/models/sleep_session.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'sleep_confidence.dart';

/// جلسة النوم - نموذج محسّن مع جميع الخصائص المطلوبة
/// ✅ مع تتبع التعديلات على الأوقات
@immutable
class SleepSession {
  // ============================================
  // الخصائص الأساسية (Existing Properties)
  // ============================================
  final int? id;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration? duration;
  final double? qualityScore; // من 1 إلى 10 (deprecated - استخدم overallSleepQuality)
  final String sleepType; // 'manual' أو 'automatic'
  final String? notes;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ============================================
  // الخصائص الجديدة (New Properties)
  // ============================================

  /// مستوى ثقة الكشف التلقائي (0-1)
  final double detectionConfidence;

  /// عدد الانقطاعات/الاستيقاظات الكلي
  final int totalInterruptions;

  /// عدد مرات فتح/استخدام الهاتف
  final int phoneActivations;

  /// أطول فترة نوم عميق متواصل
  final Duration? longestDeepSleepDuration;

  /// تقييم استقرار البيئة المحيطة (0-10)
  final double environmentStabilityScore;

  /// تقييم جودة الإضاءة (0-10)
  final double lightQualityScore;

  /// تقييم جودة الضجيج (0-10)
  final double noiseQualityScore;

  /// التقييم العام لجودة النوم (0-10)
  final double overallSleepQuality;

  /// كفاءة النوم (نسبة النوم الفعلي للوقت في السرير) (0-1)
  final double sleepEfficiency;

  /// عمر المستخدم وقت النوم
  final int? userAgeAtSleep;

  /// حالة تأكيد المستخدم
  final String userConfirmationStatus; // pending, confirmed, rejected, modified

  /// تقييم المستخدم الشخصي (1-10)
  final int? userRating;

  /// هدف ساعات النوم حسب العمر
  final double? sleepGoalHours;

  /// نسبة تحقيق الهدف (0-1+)
  final double goalAchievement;

  // ════════════════════════════════════════════════════════════
  // 🆕 نظام التصنيف الذكي - Smart Classification System
  // ════════════════════════════════════════════════════════════

  /// مستوى الثقة في تصنيف الجلسة
  final SleepConfidence confidence;

  /// هل كان هناك نشاط قبل النوم (استخدام هاتف، خطوات، حركة)
  final bool hasPreSleepActivity;

  /// آخر وقت استخدام للهاتف قبل النوم
  final DateTime? lastPhoneUsage;

  /// آخر عدد خطوات مسجل قبل النوم
  final int? lastStepsCount;

  /// هل أكد المستخدم الجلسة يدوياً
  final bool userConfirmedSleep;

  /// وقت التأكيد من المستخدم
  final DateTime? confirmationTime;

  // ════════════════════════════════════════════════════════════
  // 🆕 تتبع تعديلات الأوقات - Time Modification Tracking
  // ════════════════════════════════════════════════════════════

  /// وقت البداية الأصلي (قبل التعديل)
  final DateTime? originalStartTime;

  /// وقت النهاية الأصلي (قبل التعديل)
  final DateTime? originalEndTime;

  /// هل تم تعديل الأوقات من قبل المستخدم
  final bool wasTimeModified;

  // ============================================
  // Constructor
  // ============================================
  const SleepSession({
    this.id,
    required this.startTime,
    this.endTime,
    this.duration,
    this.qualityScore,
    this.sleepType = 'automatic',
    this.notes,
    this.isCompleted = false,
    required this.createdAt,
    DateTime? updatedAt,
    // New properties with defaults
    this.detectionConfidence = 0.8,
    this.totalInterruptions = 0,
    this.phoneActivations = 0,
    this.longestDeepSleepDuration,
    this.environmentStabilityScore = 0.0,
    this.lightQualityScore = 0.0,
    this.noiseQualityScore = 0.0,
    this.overallSleepQuality = 0.0,
    this.sleepEfficiency = 0.0,
    this.userAgeAtSleep,
    this.userConfirmationStatus = 'pending',
    this.userRating,
    this.sleepGoalHours,
    this.goalAchievement = 0.0,
    // ✅ إضافات نظام التصنيف الذكي
    this.confidence = SleepConfidence.uncertain,
    this.hasPreSleepActivity = false,
    this.lastPhoneUsage,
    this.lastStepsCount,
    this.userConfirmedSleep = false,
    this.confirmationTime,
    // ✅ إضافات تتبع التعديلات
    this.originalStartTime,
    this.originalEndTime,
    this.wasTimeModified = false,
  }) : updatedAt = updatedAt ?? createdAt;

  // ============================================
  // Named Constructors
  // ============================================

  /// تحويل من Map إلى SleepSession
  factory SleepSession.fromMap(Map<String, dynamic> map) {
    return SleepSession(
      id: map['id'] as int?,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
      endTime: map['end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int)
          : null,
      duration: map['duration'] != null
          ? Duration(seconds: map['duration'] as int)
          : null,
      qualityScore: (map['quality_score'] as num?)?.toDouble(),
      sleepType: map['sleep_type'] as String? ?? 'automatic',
      notes: map['notes'] as String?,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updated_at'] as int? ?? map['created_at'] as int,
      ),
      // New properties
      detectionConfidence: (map['detection_confidence'] as num?)?.toDouble() ?? 0.8,
      totalInterruptions: map['total_interruptions'] as int? ?? 0,
      phoneActivations: map['phone_activations'] as int? ?? 0,
      longestDeepSleepDuration: map['longest_deep_sleep_duration'] != null
          ? Duration(seconds: map['longest_deep_sleep_duration'] as int)
          : null,
      environmentStabilityScore: (map['environment_stability_score'] as num?)?.toDouble() ?? 0.0,
      lightQualityScore: (map['light_quality_score'] as num?)?.toDouble() ?? 0.0,
      noiseQualityScore: (map['noise_quality_score'] as num?)?.toDouble() ?? 0.0,
      overallSleepQuality: (map['overall_sleep_quality'] as num?)?.toDouble() ?? 0.0,
      sleepEfficiency: (map['sleep_efficiency'] as num?)?.toDouble() ?? 0.0,
      userAgeAtSleep: map['user_age_at_sleep'] as int?,
      userConfirmationStatus: map['user_confirmation_status'] as String? ?? 'pending',
      userRating: map['user_rating'] as int?,
      sleepGoalHours: (map['sleep_goal_hours'] as num?)?.toDouble(),
      goalAchievement: (map['goal_achievement'] as num?)?.toDouble() ?? 0.0,
      // ✅ حقول التصنيف الذكي
      confidence: SleepConfidence.fromString(
        map['confidence'] as String? ?? 'uncertain',
      ),
      hasPreSleepActivity: (map['has_pre_sleep_activity'] as int? ?? 0) == 1,
      lastPhoneUsage: map['last_phone_usage'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_phone_usage'] as int)
          : null,
      lastStepsCount: map['last_steps_count'] as int?,
      userConfirmedSleep: (map['user_confirmed_sleep'] as int? ?? 0) == 1,
      confirmationTime: map['confirmation_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['confirmation_time'] as int)
          : null,
      // ✅ حقول تتبع التعديلات
      originalStartTime: map['original_start_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['original_start_time'] as int)
          : null,
      originalEndTime: map['original_end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['original_end_time'] as int)
          : null,
      wasTimeModified: (map['was_time_modified'] as int? ?? 0) == 1,
    );
  }

  /// تحويل من JSON string إلى SleepSession
  factory SleepSession.fromJson(String jsonString) {
    return SleepSession.fromMap(json.decode(jsonString) as Map<String, dynamic>);
  }

  // ============================================
  // دوال التحويل (Conversion Methods)
  // ============================================

  /// تحويل إلى Map للحفظ في قاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'duration': duration?.inSeconds,
      'quality_score': qualityScore,
      'sleep_type': sleepType,
      'notes': notes,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      // New properties
      'detection_confidence': detectionConfidence,
      'total_interruptions': totalInterruptions,
      'phone_activations': phoneActivations,
      'longest_deep_sleep_duration': longestDeepSleepDuration?.inSeconds,
      'environment_stability_score': environmentStabilityScore,
      'light_quality_score': lightQualityScore,
      'noise_quality_score': noiseQualityScore,
      'overall_sleep_quality': overallSleepQuality,
      'sleep_efficiency': sleepEfficiency,
      'user_age_at_sleep': userAgeAtSleep,
      'user_confirmation_status': userConfirmationStatus,
      'user_rating': userRating,
      'sleep_goal_hours': sleepGoalHours,
      'goal_achievement': goalAchievement,
      // ✅ حقول التصنيف الذكي
      'confidence': confidence.toDbString(),
      'has_pre_sleep_activity': hasPreSleepActivity ? 1 : 0,
      'last_phone_usage': lastPhoneUsage?.millisecondsSinceEpoch,
      'last_steps_count': lastStepsCount,
      'user_confirmed_sleep': userConfirmedSleep ? 1 : 0,
      'confirmation_time': confirmationTime?.millisecondsSinceEpoch,
      // ✅ حقول تتبع التعديلات
      'original_start_time': originalStartTime?.millisecondsSinceEpoch,
      'original_end_time': originalEndTime?.millisecondsSinceEpoch,
      'was_time_modified': wasTimeModified ? 1 : 0,
    };
  }

  /// تحويل إلى JSON string
  String toJson() => json.encode(toMap());

  // ============================================
  // Computed Properties (Getters)
  // ============================================

  /// مدة النوم الفعلية
  Duration get actualSleepDuration {
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    // إذا لم ينتهِ النوم بعد، احسب حتى الآن
    return DateTime.now().difference(startTime);
  }

  /// الوقت منذ بداية النوم حتى الآن
  Duration get timeSinceStart => DateTime.now().difference(startTime);

  /// هل جلسة النوم نشطة (لم تنتهِ بعد)
  bool get isActive => endTime == null;

  /// هل تم تأكيد الجلسة من المستخدم
  bool get isConfirmed => userConfirmationStatus == 'confirmed';

  /// هل في انتظار التأكيد
  bool get isPending => userConfirmationStatus == 'pending';

  /// هل تم رفض الجلسة
  bool get isRejected => userConfirmationStatus == 'rejected';

  /// هل تم تعديل الجلسة
  bool get isModified => userConfirmationStatus == 'modified';

  /// تنسيق المدة بشكل قابل للقراءة (مثل: "7h 23m")
  String get formattedDuration {
    final dur = duration ?? actualSleepDuration;
    final hours = dur.inHours;
    final minutes = dur.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  /// تحويل overall_sleep_quality إلى تقدير نصي
  String get sleepQualityGrade {
    if (overallSleepQuality >= 9.0) return 'ممتاز';
    if (overallSleepQuality >= 7.0) return 'جيد جداً';
    if (overallSleepQuality >= 5.0) return 'جيد';
    if (overallSleepQuality >= 3.0) return 'مقبول';
    return 'ضعيف';
  }

  /// تقييم البيئة المحيطة (متوسط الإضاءة والضجيج)
  String get environmentQualityGrade {
    final avgScore = (lightQualityScore + noiseQualityScore) / 2;
    if (avgScore >= 9.0) return 'ممتاز';
    if (avgScore >= 7.0) return 'جيد جداً';
    if (avgScore >= 5.0) return 'جيد';
    if (avgScore >= 3.0) return 'مقبول';
    return 'ضعيف';
  }

  /// هل توجد انقطاعات
  bool get hasInterruptions => totalInterruptions > 0;

  /// هل تم استخدام الهاتف
  bool get hasPhoneUsage => phoneActivations > 0;

  /// هل تم تحقيق الهدف
  bool get isGoalAchieved => goalAchievement >= 1.0;

  /// مستوى الانقطاعات (قليل، متوسط، كثير)
  String get interruptionLevel {
    if (totalInterruptions == 0) return 'لا يوجد';
    if (totalInterruptions <= 2) return 'قليل';
    if (totalInterruptions <= 5) return 'متوسط';
    return 'كثير';
  }

  /// مستوى استخدام الهاتف
  String get phoneUsageLevel {
    if (phoneActivations == 0) return 'لا يوجد';
    if (phoneActivations <= 2) return 'قليل';
    if (phoneActivations <= 5) return 'متوسط';
    return 'كثير';
  }

  // ✅ Getters للتصنيف الذكي

  /// هل الجلسة تُحسب في الإحصائيات
  bool get countsInStats => confidence.countsInStats;

  /// هل تحتاج تأكيد من المستخدم
  bool get needsUserConfirmation => confidence.needsConfirmation && !userConfirmedSleep;

  /// الوصف الكامل للجلسة
  String get confidenceDescription =>
      '${confidence.emoji} ${confidence.displayName}';

  // ✅ Getters لتتبع التعديلات

  /// نسبة الخطأ في وقت البداية (بالدقائق)
  double? get startTimeErrorMinutes {
    if (originalStartTime == null || !wasTimeModified) return null;
    return startTime.difference(originalStartTime!).inMinutes.abs().toDouble();
  }

  /// نسبة الخطأ في وقت النهاية (بالدقائق)
  double? get endTimeErrorMinutes {
    if (originalEndTime == null || !wasTimeModified || endTime == null) return null;
    return endTime!.difference(originalEndTime!).inMinutes.abs().toDouble();
  }

  /// إجمالي الخطأ في المدة (بالدقائق)
  double? get totalDurationErrorMinutes {
    if (!wasTimeModified || originalStartTime == null) return null;

    final originalDuration = (originalEndTime ?? endTime)!.difference(originalStartTime!);
    final currentDuration = (endTime ?? DateTime.now()).difference(startTime);

    return (currentDuration.inMinutes - originalDuration.inMinutes).abs().toDouble();
  }

  /// نسبة الخطأ في وقت البداية (%)
  double? get startTimeErrorPercentage {
    if (startTimeErrorMinutes == null) return null;
    final totalMinutes = actualSleepDuration.inMinutes;
    if (totalMinutes == 0) return 0.0;
    return (startTimeErrorMinutes! / totalMinutes) * 100;
  }

  /// نسبة الخطأ في وقت النهاية (%)
  double? get endTimeErrorPercentage {
    if (endTimeErrorMinutes == null) return null;
    final totalMinutes = actualSleepDuration.inMinutes;
    if (totalMinutes == 0) return 0.0;
    return (endTimeErrorMinutes! / totalMinutes) * 100;
  }

  // ============================================
  // دوال حساب الإحصائيات
  // ============================================

  /// حساب كفاءة النوم
  /// المعادلة: (مدة النوم الفعلية - وقت الانقطاعات) / الوقت الكلي في السرير
  double calculateSleepEfficiency({int avgInterruptionMinutes = 5}) {
    if (endTime == null) return 0.0;

    final totalTimeInBed = endTime!.difference(startTime).inMinutes;
    if (totalTimeInBed <= 0) return 0.0;

    final interruptionTime = totalInterruptions * avgInterruptionMinutes;
    final actualSleepTime = totalTimeInBed - interruptionTime;

    final efficiency = (actualSleepTime / totalTimeInBed).clamp(0.0, 1.0);
    return efficiency;
  }

  /// حساب جودة النوم الإجمالية
  /// المعادلة: (durationScore × 0.30) + (interruptionScore × 0.25) +
  ///           (environmentScore × 0.25) + (phoneUsageScore × 0.20)
  double calculateOverallQuality() {
    final durationScore = _getDurationScore();
    final interruptionScore = _getInterruptionScore();
    final environmentScore = (lightQualityScore + noiseQualityScore) / 2;
    final phoneUsageScore = _getPhoneUsageScore();

    final overallQuality = (durationScore * 0.30) +
        (interruptionScore * 0.25) +
        (environmentScore * 0.25) +
        (phoneUsageScore * 0.20);

    return overallQuality.clamp(0.0, 10.0);
  }

  /// حساب نسبة تحقيق الهدف
  double calculateGoalAchievement() {
    if (sleepGoalHours == null || sleepGoalHours! <= 0) return 0.0;

    final actualHours = actualSleepDuration.inMinutes / 60.0;
    final achievement = actualHours / sleepGoalHours!;

    return achievement;
  }

  /// حساب تقييم جودة الإضاءة بناءً على المعدل
  double calculateLightQualityScore(double averageLightLevel) {
    if (averageLightLevel <= 5) return 10.0;
    if (averageLightLevel <= 10) return 9.0;
    if (averageLightLevel <= 20) return 7.0;
    if (averageLightLevel <= 50) return 5.0;
    return 3.0;
  }

  /// حساب تقييم جودة الضجيج بناءً على المعدل
  double calculateNoiseQualityScore(double averageNoiseLevel) {
    if (averageNoiseLevel <= 30) return 10.0;
    if (averageNoiseLevel <= 40) return 8.0;
    if (averageNoiseLevel <= 50) return 6.0;
    if (averageNoiseLevel <= 60) return 4.0;
    return 2.0;
  }

  /// حساب استقرار البيئة بناءً على التقلبات
  /// كلما قل التقلب كان أفضل
  double calculateEnvironmentStability({
    required double lightVariance,
    required double noiseVariance,
  }) {
    // تطبيع التقلبات (افترض أن التقلب العالي = 100)
    final normalizedLightVar = (1.0 - (lightVariance / 100).clamp(0.0, 1.0));
    final normalizedNoiseVar = (1.0 - (noiseVariance / 100).clamp(0.0, 1.0));

    // المتوسط المرجح
    final stability = (normalizedLightVar * 0.5 + normalizedNoiseVar * 0.5) * 10;

    return stability.clamp(0.0, 10.0);
  }

  // ============================================
  // دوال مساعدة خاصة (Private Helpers)
  // ============================================

  /// حساب نقاط المدة مقارنة بالهدف
  double _getDurationScore() {
    if (sleepGoalHours == null) {
      // استخدام 8 ساعات كهدف افتراضي
      return _scoreDurationAgainstGoal(8.0);
    }
    return _scoreDurationAgainstGoal(sleepGoalHours!);
  }

  double _scoreDurationAgainstGoal(double goalHours) {
    final actualHours = actualSleepDuration.inMinutes / 60.0;
    final difference = (actualHours - goalHours).abs();

    // أفضل نتيجة عند تحقيق الهدف تماماً
    if (difference <= 0.5) return 10.0;
    if (difference <= 1.0) return 9.0;
    if (difference <= 1.5) return 7.5;
    if (difference <= 2.0) return 6.0;
    if (difference <= 3.0) return 4.0;
    return 2.0;
  }

  /// حساب نقاط الانقطاعات
  double _getInterruptionScore() {
    if (totalInterruptions == 0) return 10.0;
    if (totalInterruptions <= 2) return 8.0;
    if (totalInterruptions <= 4) return 6.0;
    if (totalInterruptions <= 7) return 4.0;
    return 2.0;
  }

  /// حساب نقاط استخدام الهاتف
  double _getPhoneUsageScore() {
    if (phoneActivations == 0) return 10.0;
    if (phoneActivations == 1) return 8.0;
    if (phoneActivations <= 3) return 6.0;
    if (phoneActivations <= 5) return 4.0;
    return 2.0;
  }

  // ============================================
  // دالة copyWith
  // ============================================

  /// إنشاء نسخة جديدة مع تعديل بعض الخصائص
  SleepSession copyWith({
    int? id,
    DateTime? startTime,
    DateTime? endTime,
    Duration? duration,
    double? qualityScore,
    String? sleepType,
    String? notes,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? detectionConfidence,
    int? totalInterruptions,
    int? phoneActivations,
    Duration? longestDeepSleepDuration,
    double? environmentStabilityScore,
    double? lightQualityScore,
    double? noiseQualityScore,
    double? overallSleepQuality,
    double? sleepEfficiency,
    int? userAgeAtSleep,
    String? userConfirmationStatus,
    int? userRating,
    double? sleepGoalHours,
    double? goalAchievement,
    // ✅ إضافات التصنيف الذكي
    SleepConfidence? confidence,
    bool? hasPreSleepActivity,
    DateTime? lastPhoneUsage,
    int? lastStepsCount,
    bool? userConfirmedSleep,
    DateTime? confirmationTime,
    // ✅ إضافات تتبع التعديلات
    DateTime? originalStartTime,
    DateTime? originalEndTime,
    bool? wasTimeModified,
  }) {
    return SleepSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      qualityScore: qualityScore ?? this.qualityScore,
      sleepType: sleepType ?? this.sleepType,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      detectionConfidence: detectionConfidence ?? this.detectionConfidence,
      totalInterruptions: totalInterruptions ?? this.totalInterruptions,
      phoneActivations: phoneActivations ?? this.phoneActivations,
      longestDeepSleepDuration: longestDeepSleepDuration ?? this.longestDeepSleepDuration,
      environmentStabilityScore: environmentStabilityScore ?? this.environmentStabilityScore,
      lightQualityScore: lightQualityScore ?? this.lightQualityScore,
      noiseQualityScore: noiseQualityScore ?? this.noiseQualityScore,
      overallSleepQuality: overallSleepQuality ?? this.overallSleepQuality,
      sleepEfficiency: sleepEfficiency ?? this.sleepEfficiency,
      userAgeAtSleep: userAgeAtSleep ?? this.userAgeAtSleep,
      userConfirmationStatus: userConfirmationStatus ?? this.userConfirmationStatus,
      userRating: userRating ?? this.userRating,
      sleepGoalHours: sleepGoalHours ?? this.sleepGoalHours,
      goalAchievement: goalAchievement ?? this.goalAchievement,
      // ✅ التصنيف الذكي
      confidence: confidence ?? this.confidence,
      hasPreSleepActivity: hasPreSleepActivity ?? this.hasPreSleepActivity,
      lastPhoneUsage: lastPhoneUsage ?? this.lastPhoneUsage,
      lastStepsCount: lastStepsCount ?? this.lastStepsCount,
      userConfirmedSleep: userConfirmedSleep ?? this.userConfirmedSleep,
      confirmationTime: confirmationTime ?? this.confirmationTime,
      // ✅ تتبع التعديلات
      originalStartTime: originalStartTime ?? this.originalStartTime,
      originalEndTime: originalEndTime ?? this.originalEndTime,
      wasTimeModified: wasTimeModified ?? this.wasTimeModified,
    );
  }

  // ============================================
  // دوال Validation
  // ============================================

  /// التحقق من صحة البيانات
  bool isValid() {
    return getValidationErrors().isEmpty;
  }

  /// الحصول على قائمة بالأخطاء إن وجدت
  List<String> getValidationErrors() {
    final errors = <String>[];

    // التحقق من وجود start_time
    if (startTime == null) {
      errors.add('وقت البداية مطلوب');
    }

    // التحقق من أن end_time بعد start_time
    if (endTime != null && endTime!.isBefore(startTime)) {
      errors.add('وقت النهاية يجب أن يكون بعد وقت البداية');
    }

    // التحقق من نطاق quality scores
    if (lightQualityScore < 0 || lightQualityScore > 10) {
      errors.add('تقييم الإضاءة يجب أن يكون بين 0-10');
    }
    if (noiseQualityScore < 0 || noiseQualityScore > 10) {
      errors.add('تقييم الضجيج يجب أن يكون بين 0-10');
    }
    if (overallSleepQuality < 0 || overallSleepQuality > 10) {
      errors.add('التقييم العام يجب أن يكون بين 0-10');
    }
    if (environmentStabilityScore < 0 || environmentStabilityScore > 10) {
      errors.add('تقييم استقرار البيئة يجب أن يكون بين 0-10');
    }

    // التحقق من نطاق sleep_efficiency
    if (sleepEfficiency < 0 || sleepEfficiency > 1) {
      errors.add('كفاءة النوم يجب أن تكون بين 0-1');
    }

    // التحقق من نطاق user_rating
    if (userRating != null && (userRating! < 1 || userRating! > 10)) {
      errors.add('تقييم المستخدم يجب أن يكون بين 1-10');
    }

    // التحقق من نطاق detection_confidence
    if (detectionConfidence < 0 || detectionConfidence > 1) {
      errors.add('مستوى ثقة الكشف يجب أن يكون بين 0-1');
    }

    // التحقق من القيم السالبة
    if (totalInterruptions < 0) {
      errors.add('عدد الانقطاعات لا يمكن أن يكون سالباً');
    }
    if (phoneActivations < 0) {
      errors.add('عدد مرات استخدام الهاتف لا يمكن أن يكون سالباً');
    }

    return errors;
  }

  // ============================================
  // toString & Equality
  // ============================================

  @override
  String toString() {
    return 'SleepSession('
        'id: $id, '
        'start: ${startTime.toString()}, '
        'duration: $formattedDuration, '
        'quality: ${overallSleepQuality.toStringAsFixed(1)}/10, '
        'status: $userConfirmationStatus, '
        'confidence: ${confidence.displayName}, '
        'interruptions: $totalInterruptions, '
        'phone: $phoneActivations, '
        'modified: $wasTimeModified'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SleepSession && other.id == id && id != null;
  }

  @override
  int get hashCode => id?.hashCode ?? startTime.hashCode;
}