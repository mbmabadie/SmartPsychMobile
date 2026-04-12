// lib/core/services/step_counting_engine.dart - المحرك المحسن للبيانات الحقيقية

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../database/models/activity_models.dart';
import '../database/repositories/activity_repository.dart';

class StepCountingEngine {
  static final StepCountingEngine _instance = StepCountingEngine._internal();
  factory StepCountingEngine() => _instance;
  StepCountingEngine._internal();

  static StepCountingEngine get instance => _instance;

  // Repository للحفظ في قاعدة البيانات
  final ActivityRepository _repository = ActivityRepository();

  // متغيرات عد الخطوات
  int _totalSteps = 0;
  int _sessionSteps = 0;
  DateTime _lastResetTime = DateTime.now();
  DateTime _sessionStartTime = DateTime.now();

  // مخازن البيانات
  final List<AccelerometerEvent> _accelerometerBuffer = [];
  final List<double> _magnitudeBuffer = [];
  final List<DateTime> _stepTimestamps = [];
  final List<ActivityPeriod> _activityPeriods = []; // فترات النشاط المختلفة

  // معاملات الخوارزمية المحسنة
  static const int _bufferSize = 100; // 5 ثواني عند 20Hz
  static const double _stepThresholdMin = 0.3;
  static const double _stepThresholdMax = 4.0;
  static const int _minTimeBetweenStepsMs = 150;
  static const int _maxTimeBetweenStepsMs = 3000;
  static const double _gravityFilter = 9.81;

  // عوامل المعايرة
  double _sensitivity = 1.0;
  double _userHeight = 170.0;
  double _userWeight = 70.0;
  double _strideLength = 0.0;

  // تتبع الحالة
  DateTime? _lastStepTime;
  double _lastMagnitude = 0.0;
  bool _isPeakDetected = false;
  double _baselineMovement = 0.0;

  // كشف النشاط المحسن
  ActivityType _currentActivity = ActivityType.still;
  ActivityType _previousActivity = ActivityType.still;
  DateTime _lastActivityUpdate = DateTime.now();
  double _activityConfidence = 0.0;

  // إحصائيات متقدمة
  int _falsPositives = 0;
  int _confirmedSteps = 0;
  double _averageStepInterval = 0.0;
  List<double> _stepIntervals = [];

  // Timer للحفظ التلقائي
  Timer? _autoSaveTimer;

  // Getters
  int get totalSteps => _totalSteps;
  int get todaySteps => _calculateTodaySteps();
  int get sessionSteps => _sessionSteps;
  ActivityType get currentActivity => _currentActivity;
  double get stepFrequency => _calculateStepFrequency();
  double get sensitivity => _sensitivity;
  double get activityConfidence => _activityConfidence;
  double get averageStepInterval => _averageStepInterval;

  // تهيئة المحرك المحسن
  void initialize({
    double? userHeight,
    double? userWeight,
    double? sensitivity,
  }) {
    if (userHeight != null) {
      _userHeight = userHeight;
      _strideLength = _calculateStrideLength(userHeight);
    }
    if (userWeight != null) _userWeight = userWeight;
    if (sensitivity != null) _sensitivity = sensitivity;

    _resetDailyCounterIfNeeded();
    _startAutoSave();

    debugPrint('🚶 تهيئة محرك عد الخطوات المحسن - الطول: ${_userHeight}cm, الوزن: ${_userWeight}kg');
  }

  // بدء الحفظ التلقائي كل 30 دقيقة
  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      _saveCurrentData();
    });
  }

  // معالجة بيانات التسارع المحسنة
  void processAccelerometerData(AccelerometerEvent event) {
    try {
      // إضافة إلى المخزن
      _accelerometerBuffer.add(event);

      // المحافظة على حجم المخزن
      if (_accelerometerBuffer.length > _bufferSize) {
        _accelerometerBuffer.removeAt(0);
      }

      // حساب المقدار المفلتر
      final magnitude = _calculateAdvancedFilteredMagnitude(event);
      _magnitudeBuffer.add(magnitude);

      // المحافظة على مخزن المقدار
      if (_magnitudeBuffer.length > _bufferSize) {
        _magnitudeBuffer.removeAt(0);
      }

      // كشف الخطوات المحسن
      if (_magnitudeBuffer.length >= 5) {
        _detectStepAdvanced(magnitude);
      }

      // تحديث نوع النشاط كل 3 ثواني
      if (DateTime.now().difference(_lastActivityUpdate).inSeconds >= 3) {
        _updateActivityTypeAdvanced();
        _lastActivityUpdate = DateTime.now();
      }

      // حساب الخط الأساسي للحركة
      _updateBaselineMovement();

    } catch (e) {
      debugPrint('❌ خطأ في معالجة بيانات التسارع: $e');
    }
  }

  // حساب المقدار المفلتر المتقدم
  double _calculateAdvancedFilteredMagnitude(AccelerometerEvent event) {
    // حساب المقدار الكلي
    final totalMagnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

    // تطبيق مرشح عالي التمرير لإزالة الجاذبية
    final filteredMagnitude = (totalMagnitude - _gravityFilter).abs();

    // تطبيق مرشح تمرير منخفض لتنعيم الإشارة
    if (_magnitudeBuffer.isNotEmpty) {
      final alpha = 0.2; // عامل التنعيم
      final smoothed = alpha * filteredMagnitude + (1 - alpha) * _magnitudeBuffer.last;
      return smoothed;
    }

    return filteredMagnitude;
  }

  // كشف الخطوة المتقدم
  void _detectStepAdvanced(double currentMagnitude) {
    if (_magnitudeBuffer.length < 5) return;

    final now = DateTime.now();

    // التحقق من الوقت بين الخطوات
    if (_lastStepTime != null &&
        now.difference(_lastStepTime!).inMilliseconds < _minTimeBetweenStepsMs) {
      return;
    }

    // كشف القمة المتقدم
    if (_isValidPeakAdvanced(currentMagnitude)) {
      // التحقق من صحة نمط الخطوة
      if (_isValidStepPatternAdvanced() && _passesConfidenceCheck(currentMagnitude)) {
        _registerStepAdvanced(now, currentMagnitude);
      } else {
        _falsPositives++;
      }
    }
  }

  // كشف القمة المتقدم
  bool _isValidPeakAdvanced(double currentMagnitude) {
    final bufferLength = _magnitudeBuffer.length;
    if (bufferLength < 5) return false;

    final current = currentMagnitude;
    final prev1 = _magnitudeBuffer[bufferLength - 2];
    final prev2 = _magnitudeBuffer[bufferLength - 3];
    final next1 = bufferLength > 1 ? _magnitudeBuffer[bufferLength - 1] : current;

    // شروط القمة المحسنة
    bool isPeak = current > prev1 && prev1 > prev2;
    bool isWithinThreshold = current >= _stepThresholdMin * _sensitivity &&
        current <= _stepThresholdMax * _sensitivity;
    bool isAboveBaseline = current > _baselineMovement * 1.5;

    return isPeak && isWithinThreshold && isAboveBaseline;
  }

  // التحقق من صحة نمط الخطوة المتقدم
  bool _isValidStepPatternAdvanced() {
    if (_magnitudeBuffer.length < 20) return false;

    final recent = _magnitudeBuffer.sublist(_magnitudeBuffer.length - 20);

    // حساب التباين لكشف النشاط الإيقاعي
    final mean = recent.reduce((a, b) => a + b) / recent.length;
    final variance = recent.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / recent.length;

    // التحقق من الإيقاع
    final rhythmScore = _calculateRhythmScore(recent);

    // شروط النمط المحسنة
    bool hasVariance = variance > 0.01 && variance < 3.0;
    bool hasRhythm = rhythmScore > 0.3;
    bool notTooErratic = variance < mean * 2;

    return hasVariance && hasRhythm && notTooErratic;
  }

  // حساب نقاط الإيقاع
  double _calculateRhythmScore(List<double> data) {
    if (data.length < 10) return 0.0;

    // البحث عن أنماط دورية
    int peaks = 0;
    for (int i = 1; i < data.length - 1; i++) {
      if (data[i] > data[i-1] && data[i] > data[i+1]) {
        peaks++;
      }
    }

    // حساب انتظام المسافات بين القمم
    double rhythmScore = peaks / (data.length / 4); // متوقع حوالي 1 قمة كل 4 نقاط
    return rhythmScore.clamp(0.0, 1.0);
  }

  // فحص الثقة
  bool _passesConfidenceCheck(double magnitude) {
    // تطبيق machine learning بسيط للتحقق
    double confidence = 0.5;

    // زيادة الثقة بناء على التاريخ
    if (_confirmedSteps > 100) {
      confidence += 0.2;
    }

    // تقليل الثقة إذا كان هناك كثير من الإيجابيات الخاطئة
    if (_falsPositives > _confirmedSteps * 0.3) {
      confidence -= 0.3;
    }

    // فحص الاتساق مع الخطوات السابقة
    if (_stepIntervals.isNotEmpty) {
      final expectedInterval = _averageStepInterval;
      final actualInterval = _lastStepTime != null ?
      DateTime.now().difference(_lastStepTime!).inMilliseconds.toDouble() : 1000.0;

      final intervalDiff = (actualInterval - expectedInterval).abs();
      if (intervalDiff < expectedInterval * 0.5) {
        confidence += 0.2;
      }
    }

    return confidence > 0.6;
  }

  // تسجيل خطوة متقدم
  void _registerStepAdvanced(DateTime timestamp, double magnitude) {
    _totalSteps++;
    _sessionSteps++;
    _confirmedSteps++;
    _lastStepTime = timestamp;
    _stepTimestamps.add(timestamp);

    // حساب فترة الخطوة
    if (_stepIntervals.isNotEmpty) {
      final lastStep = _stepTimestamps[_stepTimestamps.length - 2];
      final interval = timestamp.difference(lastStep).inMilliseconds.toDouble();
      _stepIntervals.add(interval);

      // الاحتفاظ بآخر 50 فترة
      if (_stepIntervals.length > 50) {
        _stepIntervals.removeAt(0);
      }

      // حساب المتوسط
      _averageStepInterval = _stepIntervals.reduce((a, b) => a + b) / _stepIntervals.length;
    }

    // الاحتفاظ بآخر 1000 خطوة
    if (_stepTimestamps.length > 1000) {
      _stepTimestamps.removeAt(0);
    }

    debugPrint('👟 خطوة جديدة! الإجمالي: $_totalSteps (ثقة: ${magnitude.toStringAsFixed(2)})');
  }

  // تحديث نوع النشاط المتقدم
  void _updateActivityTypeAdvanced() {
    final frequency = _calculateStepFrequency();
    final intensity = _calculateMovementIntensityAdvanced();
    final consistency = _calculateMovementConsistency();

    ActivityType newActivity;
    double confidence = 0.5;

    if (frequency == 0 && intensity < 0.1) {
      newActivity = ActivityType.still;
      confidence = intensity < 0.05 ? 0.8 : 0.6;
    } else if (frequency > 0 && frequency <= 80 && intensity < 0.4) {
      newActivity = ActivityType.walking;
      confidence = (frequency > 40 && frequency < 70) ? 0.8 : 0.6;
    } else if (frequency > 80 && frequency <= 200 && intensity >= 0.4) {
      newActivity = ActivityType.running;
      confidence = (frequency > 100 && frequency < 180) ? 0.9 : 0.7;
    } else if (intensity > 0.6 && frequency > 150) {
      newActivity = ActivityType.running;
      confidence = 0.8;
    } else if (intensity > 0.3 && frequency < 40 && consistency < 0.3) {
      newActivity = ActivityType.driving; // أو cycling
      confidence = 0.6;
    } else {
      newActivity = ActivityType.general;
      confidence = 0.5;
    }

    // تطبيق مرشح زمني لتجنب التقلبات السريعة
    if (newActivity != _currentActivity) {
      if (confidence > _activityConfidence + 0.1 ||
          DateTime.now().difference(_lastActivityUpdate).inSeconds > 10) {

        _recordActivityChange(_currentActivity, newActivity);
        _previousActivity = _currentActivity;
        _currentActivity = newActivity;
        _activityConfidence = confidence;

        debugPrint('🏃 تغيير النشاط إلى: ${_getActivityName(newActivity)} (ثقة: ${(confidence * 100).round()}%)');
      }
    } else {
      _activityConfidence = (confidence + _activityConfidence) / 2; // تنعيم الثقة
    }
  }

  // حساب شدة الحركة المتقدمة
  double _calculateMovementIntensityAdvanced() {
    if (_magnitudeBuffer.length < 10) return 0.0;

    final recent = _magnitudeBuffer.sublist(_magnitudeBuffer.length - 10);

    // حساب الطاقة الإجمالية للإشارة
    final energy = recent.map((x) => x * x).reduce((a, b) => a + b);
    final normalizedEnergy = energy / recent.length;

    // حساب التباين
    final mean = recent.reduce((a, b) => a + b) / recent.length;
    final variance = recent.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / recent.length;

    // دمج الطاقة والتباين للحصول على مؤشر الشدة
    final intensity = (normalizedEnergy * 0.7 + variance * 0.3) / 3.0;

    return intensity.clamp(0.0, 1.0);
  }

  // حساب اتساق الحركة
  double _calculateMovementConsistency() {
    if (_stepIntervals.length < 5) return 0.0;

    final mean = _averageStepInterval;
    final deviations = _stepIntervals.map((x) => (x - mean).abs()).toList();
    final averageDeviation = deviations.reduce((a, b) => a + b) / deviations.length;

    // كلما قل الانحراف، زاد الاتساق
    final consistency = 1.0 - (averageDeviation / mean).clamp(0.0, 1.0);

    return consistency;
  }

  // تسجيل تغيير النشاط
  void _recordActivityChange(ActivityType from, ActivityType to) {
    final now = DateTime.now();

    if (_activityPeriods.isNotEmpty) {
      // إنهاء الفترة السابقة
      final lastPeriod = _activityPeriods.last;
      lastPeriod.endTime = now;
      lastPeriod.duration = now.difference(lastPeriod.startTime);
    }

    // بدء فترة جديدة
    _activityPeriods.add(ActivityPeriod(
      activityType: to,
      startTime: now,
      confidence: _activityConfidence,
    ));

    // الاحتفاظ بآخر 100 فترة
    if (_activityPeriods.length > 100) {
      _activityPeriods.removeAt(0);
    }
  }

  // تحديث الخط الأساسي للحركة
  void _updateBaselineMovement() {
    if (_magnitudeBuffer.length < 50) return;

    final recent = _magnitudeBuffer.sublist(_magnitudeBuffer.length - 50);
    final sorted = List<double>.from(recent)..sort();

    // استخدام النسبة المئوية العشرين كخط أساسي
    final percentile20Index = (sorted.length * 0.2).round();
    _baselineMovement = sorted[percentile20Index];
  }

  // حساب اليوم
  int _calculateTodaySteps() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final todayStepsCount = _stepTimestamps.where((timestamp) {
      return timestamp.isAfter(todayStart);
    }).length;

    return todayStepsCount;
  }

  // حساب تكرار الخطوات
  double _calculateStepFrequency() {
    if (_stepTimestamps.length < 2) return 0.0;

    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));

    final recentSteps = _stepTimestamps.where((timestamp) {
      return timestamp.isAfter(oneMinuteAgo);
    }).length;

    return recentSteps.toDouble();
  }

  // حساب المسافة بناءً على الخطوات وطول الخطوة المحسوب
  double calculateDistance(int steps) {
    final stepLengthM = _strideLength / 100.0; // تحويل من سم إلى متر
    return steps * stepLengthM / 1000.0; // المسافة بالكيلومتر
  }

  // حساب السعرات المحروقة بناءً على النشاط والوزن
  double calculateCalories(int steps, Duration? duration) {
    double caloriesPerStep;

    switch (_currentActivity) {
      case ActivityType.walking:
        caloriesPerStep = _userWeight * 0.04 / 1000; // ~0.04 سعرة لكل خطوة لكل كيلو
        break;
      case ActivityType.running:
        caloriesPerStep = _userWeight * 0.08 / 1000; // ~0.08 سعرة لكل خطوة لكل كيلو
        break;
      case ActivityType.cycling:
        caloriesPerStep = _userWeight * 0.06 / 1000; // تقدير للدراجة
        break;
      default:
        caloriesPerStep = _userWeight * 0.03 / 1000; // نشاط عام
    }

    double baseCalories = steps * caloriesPerStep;

    // تطبيق معامل الشدة
    final intensityMultiplier = 1.0 + (_calculateMovementIntensityAdvanced() * 0.5);

    return baseCalories * intensityMultiplier;
  }

  // حساب طول الخطوة بناءً على الطول
  double _calculateStrideLength(double height) {
    // صيغة محسنة لحساب طول الخطوة
    switch (_currentActivity) {
      case ActivityType.walking:
        return height * 0.43; // 43% من الطول للمشي
      case ActivityType.running:
        return height * 0.47; // 47% من الطول للجري
      default:
        return height * 0.45; // متوسط عام
    }
  }

  // الحصول على الوقت النشط
  Duration getActiveTime() {
    if (_activityPeriods.isEmpty) return Duration.zero;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    Duration totalActive = Duration.zero;

    for (final period in _activityPeriods) {
      if (period.startTime.isAfter(todayStart) && period.activityType != ActivityType.still) {
        final endTime = period.endTime ?? now;
        final duration = endTime.difference(period.startTime);

        // استبعاد الفترات القصيرة جداً (أقل من 30 ثانية)
        if (duration.inSeconds >= 30) {
          totalActive += duration;
        }
      }
    }

    return totalActive;
  }

  // إعادة تعيين العداد اليومي عند منتصف الليل
  void _resetDailyCounterIfNeeded() {
    final now = DateTime.now();
    final lastReset = DateTime(_lastResetTime.year, _lastResetTime.month, _lastResetTime.day);
    final today = DateTime(now.year, now.month, now.day);

    if (today.isAfter(lastReset)) {
      debugPrint('🔄 إعادة تعيين عداد الخطوات اليومي');

      // حفظ بيانات اليوم السابق قبل إعادة التعيين
      _saveCurrentData();

      _lastResetTime = now;
      _sessionStartTime = now;
      _sessionSteps = 0;

      // الاحتفاظ بالخطوات ولكن تنظيف البيانات القديمة
      final yesterday = today.subtract(const Duration(days: 1));
      _stepTimestamps.removeWhere((timestamp) => timestamp.isBefore(yesterday));
      _activityPeriods.removeWhere((period) => period.startTime.isBefore(yesterday));
    }
  }

  // الحصول على الإحصائيات المتقدمة
  Map<String, dynamic> getStatistics() {
    final todaySteps = _calculateTodaySteps();
    final todayDistance = calculateDistance(todaySteps);
    final activeTime = getActiveTime();
    final todayCalories = calculateCalories(todaySteps, activeTime);

    return {
      'total_steps_today': todaySteps,
      'session_steps': _sessionSteps,
      'total_distance_km': todayDistance,
      'total_calories': todayCalories,
      'active_time_minutes': activeTime.inMinutes,
      'current_activity': _getActivityName(_currentActivity),
      'activity_confidence': _activityConfidence,
      'step_frequency': stepFrequency,
      'movement_intensity': _calculateMovementIntensityAdvanced(),
      'movement_consistency': _calculateMovementConsistency(),
      'average_step_interval_ms': _averageStepInterval,
      'confirmed_steps': _confirmedSteps,
      'false_positives': _falsPositives,
      'accuracy_rate': _confirmedSteps > 0 ? (_confirmedSteps / (_confirmedSteps + _falsPositives)) : 0.0,
      'stride_length_cm': _strideLength,
      'user_height': _userHeight,
      'user_weight': _userWeight,
      'sensitivity': _sensitivity,
      'baseline_movement': _baselineMovement,
      'activity_periods_today': _getTodayActivityPeriods(),
    };
  }

  // الحصول على فترات النشاط اليوم
  List<Map<String, dynamic>> _getTodayActivityPeriods() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    return _activityPeriods
        .where((period) => period.startTime.isAfter(todayStart))
        .map((period) => period.toMap())
        .toList();
  }

  // معايرة الحساسية بناءً على ملاحظات المستخدم
  void calibrateSensitivity(int expectedSteps, int detectedSteps) {
    if (detectedSteps > 0 && expectedSteps > 0) {
      final ratio = expectedSteps / detectedSteps;
      final oldSensitivity = _sensitivity;

      // تطبيق تغيير تدريجي لتجنب التقلبات الكبيرة
      _sensitivity = (_sensitivity * 0.7) + (ratio * 0.3);
      _sensitivity = _sensitivity.clamp(0.3, 3.0);

      // تسجيل المعايرة
      debugPrint('🎯 معايرة الحساسية: $oldSensitivity -> $_sensitivity (نسبة: ${ratio.toStringAsFixed(2)})');

      // إعادة حساب الخط الأساسي بعد المعايرة
      _baselineMovement *= (oldSensitivity / _sensitivity);
    }
  }

  // حفظ البيانات الحالية
  Future<void> _saveCurrentData() async {
    try {
      final now = DateTime.now();
      final todayStr = _formatDate(now);

      // إنشاء سجل النشاط اليومي
      final dailyActivity = await _createDailyActivityRecord(todayStr, now);

      // حفظ في قاعدة البيانات
      await _repository.insertOrUpdateDailyActivity(dailyActivity);

      debugPrint('💾 تم حفظ البيانات: ${dailyActivity.totalSteps} خطوة، ${dailyActivity.distance.toStringAsFixed(2)} كم');

    } catch (e) {
      debugPrint('❌ خطأ في حفظ البيانات: $e');
    }
  }

  // إنشاء سجل النشاط اليومي
  Future<DailyActivity> _createDailyActivityRecord(String date, DateTime now) async {
    final todaySteps = _calculateTodaySteps();
    final todayDistance = calculateDistance(todaySteps);
    final activeTime = getActiveTime();
    final todayCalories = calculateCalories(todaySteps, activeTime);
    final intensity = _calculateMovementIntensityAdvanced();

    return DailyActivity(
      date: date,
      totalSteps: todaySteps,
      distance: todayDistance,
      caloriesBurned: todayCalories,
      activeMinutes: activeTime.inMinutes,
      duration: activeTime,
      activityType: _currentActivity.name,
      intensityScore: intensity,
      fitnessScore: _calculateDailyFitnessScore(todaySteps, activeTime.inMinutes, todayCalories),
      createdAt: now,
      updatedAt: now,
    );
  }

  // حساب نقاط اللياقة اليومية
  double _calculateDailyFitnessScore(int steps, int activeMinutes, double calories) {
    // النقاط بناءً على الخطوات (40%)
    double stepScore = (steps / 10000.0).clamp(0.0, 1.0);

    // النقاط بناءً على الوقت النشط (30%)
    double timeScore = (activeMinutes / 60.0).clamp(0.0, 1.0);

    // النقاط بناءً على السعرات (20%)
    double calorieScore = (calories / 500.0).clamp(0.0, 1.0);

    // النقاط بناءً على التنوع في الأنشطة (10%)
    double varietyScore = _calculateActivityVarietyScore();

    return (stepScore * 0.4) + (timeScore * 0.3) + (calorieScore * 0.2) + (varietyScore * 0.1);
  }

  // حساب نقاط تنوع الأنشطة
  double _calculateActivityVarietyScore() {
    final todayStart = DateTime.now().subtract(const Duration(days: 1));
    final todayActivities = _activityPeriods
        .where((period) => period.startTime.isAfter(todayStart))
        .map((period) => period.activityType)
        .toSet();

    // كلما زاد التنوع، زادت النقاط (حد أقصى 5 أنواع مختلفة)
    return (todayActivities.length / 5.0).clamp(0.0, 1.0);
  }

  // الحصول على تفصيل الأنشطة بالساعة
  Map<int, int> getTodayHourlySteps() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final hourlySteps = <int, int>{};
    for (int hour = 0; hour < 24; hour++) {
      hourlySteps[hour] = 0;
    }

    for (final timestamp in _stepTimestamps) {
      if (timestamp.isAfter(todayStart)) {
        final hour = timestamp.hour;
        hourlySteps[hour] = (hourlySteps[hour] ?? 0) + 1;
      }
    }

    return hourlySteps;
  }

  // تحليل أنماط النشاط
  Map<String, dynamic> analyzeActivityPatterns() {
    final hourlySteps = getTodayHourlySteps();
    final peakHours = <int>[];
    final quietHours = <int>[];

    // تحديد ساعات الذروة والهدوء
    final averageStepsPerHour = hourlySteps.values.reduce((a, b) => a + b) / 24;

    hourlySteps.forEach((hour, steps) {
      if (steps > averageStepsPerHour * 1.5) {
        peakHours.add(hour);
      } else if (steps < averageStepsPerHour * 0.3) {
        quietHours.add(hour);
      }
    });

    // تحليل النمط العام
    String activityPattern;
    if (peakHours.any((h) => h >= 6 && h <= 10)) {
      activityPattern = 'نشط صباحاً';
    } else if (peakHours.any((h) => h >= 17 && h <= 21)) {
      activityPattern = 'نشط مساءً';
    } else if (peakHours.any((h) => h >= 11 && h <= 16)) {
      activityPattern = 'نشط نهاراً';
    } else {
      activityPattern = 'نشاط متوزع';
    }

    return {
      'hourly_steps': hourlySteps,
      'peak_hours': peakHours,
      'quiet_hours': quietHours,
      'average_steps_per_hour': averageStepsPerHour.round(),
      'activity_pattern': activityPattern,
      'most_active_hour': hourlySteps.entries.reduce((a, b) => a.value > b.value ? a : b).key,
      'least_active_hour': hourlySteps.entries.reduce((a, b) => a.value < b.value ? a : b).key,
    };
  }

  // إعادة تعيين شامل
  void reset() {
    _totalSteps = 0;
    _sessionSteps = 0;
    _stepTimestamps.clear();
    _accelerometerBuffer.clear();
    _magnitudeBuffer.clear();
    _activityPeriods.clear();
    _stepIntervals.clear();
    _lastStepTime = null;
    _lastResetTime = DateTime.now();
    _sessionStartTime = DateTime.now();
    _falsPositives = 0;
    _confirmedSteps = 0;
    _averageStepInterval = 0.0;
    _baselineMovement = 0.0;
    _currentActivity = ActivityType.still;
    _activityConfidence = 0.0;

    debugPrint('🔄 تم إعادة تعيين محرك عد الخطوات شاملاً');
  }

  // تصدير البيانات
  Map<String, dynamic> exportData() {
    return {
      'total_steps': _totalSteps,
      'session_steps': _sessionSteps,
      'today_steps': _calculateTodaySteps(),
      'step_timestamps': _stepTimestamps.map((t) => t.millisecondsSinceEpoch).toList(),
      'activity_periods': _activityPeriods.map((p) => p.toMap()).toList(),
      'step_intervals': _stepIntervals,
      'user_height': _userHeight,
      'user_weight': _userWeight,
      'stride_length': _strideLength,
      'sensitivity': _sensitivity,
      'confirmed_steps': _confirmedSteps,
      'false_positives': _falsPositives,
      'average_step_interval': _averageStepInterval,
      'baseline_movement': _baselineMovement,
      'current_activity': _currentActivity.name,
      'activity_confidence': _activityConfidence,
      'last_reset': _lastResetTime.millisecondsSinceEpoch,
      'session_start': _sessionStartTime.millisecondsSinceEpoch,
      'statistics': getStatistics(),
      'hourly_breakdown': getTodayHourlySteps(),
      'activity_analysis': analyzeActivityPatterns(),
    };
  }

  // استيراد البيانات
  void importData(Map<String, dynamic> data) {
    try {
      _totalSteps = data['total_steps'] ?? 0;
      _sessionSteps = data['session_steps'] ?? 0;
      _userHeight = data['user_height'] ?? 170.0;
      _userWeight = data['user_weight'] ?? 70.0;
      _strideLength = data['stride_length'] ?? _calculateStrideLength(_userHeight);
      _sensitivity = data['sensitivity'] ?? 1.0;
      _confirmedSteps = data['confirmed_steps'] ?? 0;
      _falsPositives = data['false_positives'] ?? 0;
      _averageStepInterval = data['average_step_interval'] ?? 0.0;
      _baselineMovement = data['baseline_movement'] ?? 0.0;
      _activityConfidence = data['activity_confidence'] ?? 0.0;

      if (data['current_activity'] != null) {
        try {
          _currentActivity = ActivityType.values.firstWhere(
                (e) => e.name == data['current_activity'],
          );
        } catch (e) {
          _currentActivity = ActivityType.still;
        }
      }

      if (data['step_timestamps'] != null) {
        _stepTimestamps.clear();
        for (final timestamp in data['step_timestamps']) {
          _stepTimestamps.add(DateTime.fromMillisecondsSinceEpoch(timestamp));
        }
      }

      if (data['step_intervals'] != null) {
        _stepIntervals = List<double>.from(data['step_intervals']);
      }

      if (data['activity_periods'] != null) {
        _activityPeriods.clear();
        for (final periodData in data['activity_periods']) {
          _activityPeriods.add(ActivityPeriod.fromMap(periodData));
        }
      }

      if (data['last_reset'] != null) {
        _lastResetTime = DateTime.fromMillisecondsSinceEpoch(data['last_reset']);
      }

      if (data['session_start'] != null) {
        _sessionStartTime = DateTime.fromMillisecondsSinceEpoch(data['session_start']);
      }

      debugPrint('📥 تم استيراد بيانات عداد الخطوات المحسن');
    } catch (e) {
      debugPrint('❌ خطأ في استيراد البيانات: $e');
    }
  }

  // دوال مساعدة
  String _getActivityName(ActivityType activity) {
    switch (activity) {
      case ActivityType.still: return 'ثابت';
      case ActivityType.walking: return 'المشي';
      case ActivityType.running: return 'الجري';
      case ActivityType.cycling: return 'ركوب دراجة';
      case ActivityType.driving: return 'قيادة';
      case ActivityType.general: return 'نشاط عام';
      default: return 'غير محدد';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // تنظيف الموارد
  void dispose() {
    _autoSaveTimer?.cancel();
    debugPrint('🗑️ تم التخلص من محرك عد الخطوات');
  }
}

// كلاس فترة النشاط
class ActivityPeriod {
  final ActivityType activityType;
  final DateTime startTime;
  DateTime? endTime;
  Duration? duration;
  final double confidence;

  ActivityPeriod({
    required this.activityType,
    required this.startTime,
    this.endTime,
    this.duration,
    required this.confidence,
  });

  Map<String, dynamic> toMap() {
    return {
      'activity_type': activityType.name,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'duration_seconds': duration?.inSeconds,
      'confidence': confidence,
    };
  }

  factory ActivityPeriod.fromMap(Map<String, dynamic> map) {
    return ActivityPeriod(
      activityType: ActivityType.values.firstWhere(
            (e) => e.name == map['activity_type'],
        orElse: () => ActivityType.still,
      ),
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time']),
      endTime: map['end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['end_time'])
          : null,
      duration: map['duration_seconds'] != null
          ? Duration(seconds: map['duration_seconds'])
          : null,
      confidence: map['confidence'] ?? 0.0,
    );
  }
}