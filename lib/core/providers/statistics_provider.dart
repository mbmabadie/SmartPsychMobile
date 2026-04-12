// lib/core/providers/statistics_provider.dart
// ✅ نسخة بدون pickups - بيانات حقيقية فقط

import 'dart:async';
import 'package:flutter/foundation.dart';

import '../database/repositories/activity_repository.dart';
import '../database/repositories/phone_usage_repository.dart';
import '../database/repositories/sleep_repository.dart';
import 'base/base_state.dart';
import 'base/base_provider.dart';

import 'activity_tracking_provider.dart';
import 'phone_usage_provider.dart';
import 'sleep_tracking_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Enums
// ═══════════════════════════════════════════════════════════════════════════

enum StatisticsPeriod {
  day,
  week,
  month,
  year;

  int get days {
    switch (this) {
      case StatisticsPeriod.day:
        return 1;
      case StatisticsPeriod.week:
        return 7;
      case StatisticsPeriod.month:
        return 30;
      case StatisticsPeriod.year:
        return 365;
    }
  }

  String get displayName {
    switch (this) {
      case StatisticsPeriod.day:
        return 'يومي';
      case StatisticsPeriod.week:
        return 'أسبوعي';
      case StatisticsPeriod.month:
        return 'شهري';
      case StatisticsPeriod.year:
        return 'سنوي';
    }
  }
}

enum StatisticsCategory {
  sleep,
  phoneUsage,
  activity;

  String get displayName {
    switch (this) {
      case StatisticsCategory.sleep:
        return 'النوم';
      case StatisticsCategory.phoneUsage:
        return 'استخدام الهاتف';
      case StatisticsCategory.activity:
        return 'النشاط';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// State
// ═══════════════════════════════════════════════════════════════════════════

class StatisticsState extends BaseState {
  final StatisticsPeriod selectedPeriod;
  final StatisticsCategory selectedCategory;
  final Map<String, dynamic> sleepStats;
  final Map<String, dynamic> activityStats;
  final Map<String, dynamic> phoneStats;
  final List<Map<String, dynamic>> chartData;

  StatisticsState({
    super.loadingState,
    super.error,
    super.lastUpdated,
    super.hasData,
    super.successMessage,
    this.selectedPeriod = StatisticsPeriod.week,
    this.selectedCategory = StatisticsCategory.sleep,
    this.sleepStats = const {},
    this.activityStats = const {},
    this.phoneStats = const {},
    this.chartData = const [],
  });

  factory StatisticsState.initial() {
    return StatisticsState(
      loadingState: LoadingState.idle,
      hasData: false,
    );
  }

  StatisticsState copyWith({
    LoadingState? loadingState,
    AppError? error,
    DateTime? lastUpdated,
    bool? hasData,
    String? successMessage,
    StatisticsPeriod? selectedPeriod,
    StatisticsCategory? selectedCategory,
    Map<String, dynamic>? sleepStats,
    Map<String, dynamic>? activityStats,
    Map<String, dynamic>? phoneStats,
    List<Map<String, dynamic>>? chartData,
  }) {
    return StatisticsState(
      loadingState: loadingState ?? this.loadingState,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      hasData: hasData ?? this.hasData,
      successMessage: successMessage ?? this.successMessage,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      sleepStats: sleepStats ?? this.sleepStats,
      activityStats: activityStats ?? this.activityStats,
      phoneStats: phoneStats ?? this.phoneStats,
      chartData: chartData ?? this.chartData,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Provider
// ═══════════════════════════════════════════════════════════════════════════

class StatisticsProvider extends BaseProvider<StatisticsState> {
  // Repositories للبيانات التاريخية
  final ActivityRepository _activityRepo;
  final PhoneUsageRepository _phoneRepo;
  final SleepRepository _sleepRepo;

  // ⭐ الـ Providers للبيانات الحالية
  final ActivityTrackingProvider? activityProvider;
  final PhoneUsageProvider? phoneUsageProvider;
  final SleepTrackingProvider? sleepProvider;

  // ✅ متغيرات مؤقتة لحفظ البيانات قبل setState
  Map<String, dynamic> _tempActivityStats = {};
  Map<String, dynamic> _tempSleepStats = {};
  Map<String, dynamic> _tempPhoneStats = {};
  List<Map<String, dynamic>> _tempChartData = [];

  StatisticsProvider({
    ActivityRepository? activityRepo,
    PhoneUsageRepository? phoneRepo,
    SleepRepository? sleepRepo,
    this.activityProvider,
    this.phoneUsageProvider,
    this.sleepProvider,
  })  : _activityRepo = activityRepo ?? ActivityRepository(),
        _phoneRepo = phoneRepo ?? PhoneUsageRepository(),
        _sleepRepo = sleepRepo ?? SleepRepository(),
        super(StatisticsState.initial()) {
    debugPrint('📊 تهيئة StatisticsProvider (بيانات حقيقية فقط)');
    _initializeProvider();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BaseProvider Overrides
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  StatisticsState _createLoadingState(bool isRefreshing) {
    return state.copyWith(
      loadingState: isRefreshing ? LoadingState.refreshing : LoadingState.loading,
      error: null,
    );
  }

  @override
  StatisticsState _createSuccessState() {
    return state.copyWith(
      loadingState: LoadingState.success,
      error: null,
      hasData: true,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  StatisticsState _createErrorState(AppError error) {
    return state.copyWith(
      loadingState: LoadingState.error,
      error: error,
    );
  }

  @override
  StatisticsState _createIdleState() {
    return state.copyWith(
      loadingState: LoadingState.idle,
      error: null,
    );
  }

  @override
  Future<void> refreshData() async {
    try {
      debugPrint('🔄 تحديث البيانات...');

      setState(state.copyWith(
        loadingState: LoadingState.refreshing,
        error: null,
      ));

      await _loadAllStats();

      setState(state.copyWith(
        loadingState: LoadingState.success,
        error: null,
        lastUpdated: DateTime.now(),
      ));
    } catch (e, stack) {
      debugPrint('❌ خطأ في تحديث البيانات: $e');

      setState(state.copyWith(
        loadingState: LoadingState.error,
        error: ServiceError(
          message: 'فشل في تحديث البيانات: $e',
          originalError: e,
          stackTrace: stack,
        ),
      ));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ⭐ Initialization
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _initializeProvider() async {
    try {
      debugPrint('📊 بدء تهيئة StatisticsProvider...');

      setState(state.copyWith(
        loadingState: LoadingState.loading,
        error: null,
      ));

      await _loadAllStats();

      setState(state.copyWith(
        loadingState: LoadingState.success,
        error: null,
        hasData: true,
        lastUpdated: DateTime.now(),
      ));

      debugPrint('✅ تمت تهيئة StatisticsProvider بنجاح');
    } catch (e, stack) {
      debugPrint('❌ خطأ في تهيئة StatisticsProvider: $e');
      debugPrint('Stack: $stack');

      setState(state.copyWith(
        loadingState: LoadingState.error,
        error: ServiceError(
          message: 'فشل في تحميل الإحصائيات: $e',
          originalError: e,
          stackTrace: stack,
        ),
      ));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ⭐ تحميل جميع الإحصائيات - SINGLE setState
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _loadAllStats() async {
    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📊 تحميل جميع الإحصائيات (بيانات حقيقية)...');

      final dates = _getDateRange(state.selectedPeriod);
      debugPrint('   الفترة: ${_formatDate(dates['start']!)} → ${_formatDate(dates['end']!)}');

      // تحميل جميع الإحصائيات بالتوازي (بدون setState)
      await Future.wait([
        _loadActivityStats(dates['start']!, dates['end']!),
        _loadSleepStats(dates['start']!, dates['end']!),
        _loadPhoneStats(dates['start']!, dates['end']!),
      ]);

      debugPrint('🔍 [BEFORE generateChartData]:');
      debugPrint('   - _tempActivityStats: $_tempActivityStats');
      debugPrint('   - _tempSleepStats: $_tempSleepStats');
      debugPrint('   - _tempPhoneStats: $_tempPhoneStats');

      // تحميل بيانات المخطط (بدون setState)
      await _generateChartData();

      debugPrint('🔍 [AFTER generateChartData]:');
      debugPrint('   - _tempChartData length: ${_tempChartData.length}');

      // ✅ setState مرة وحدة فقط مع كل البيانات!
      setState(state.copyWith(
        activityStats: _tempActivityStats,
        sleepStats: _tempSleepStats,
        phoneStats: _tempPhoneStats,
        chartData: _tempChartData,
        hasData: true,
        lastUpdated: DateTime.now(),
      ));

      debugPrint('🔍 [AFTER setState]:');
      debugPrint('   - state.activityStats: ${state.activityStats}');
      debugPrint('   - state.sleepStats: ${state.sleepStats}');
      debugPrint('   - state.phoneStats: ${state.phoneStats}');
      debugPrint('   - state.chartData length: ${state.chartData.length}');

      debugPrint('✅ تم تحميل جميع الإحصائيات بنجاح');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    } catch (e, stack) {
      debugPrint('❌ خطأ في تحميل الإحصائيات: $e');
      debugPrint('Stack: $stack');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ⭐ إحصائيات النشاط - NO setState
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _loadActivityStats(DateTime startDate, DateTime endDate) async {
    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🏃 [Activity Stats] جلب البيانات يوم بيوم...');
      debugPrint('   الفترة: ${_formatDate(startDate)} → ${_formatDate(endDate)}');

      var currentDate = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);
      final today = _formatDate(DateTime.now());

      int totalSteps = 0;
      double totalDistance = 0.0;
      double totalCalories = 0.0;
      int activeDays = 0;

      while (currentDate.isBefore(end.add(const Duration(days: 1)))) {
        final dateStr = _formatDate(currentDate);
        final isToday = dateStr == today;

        if (isToday && activityProvider != null) {
          final quickStats = activityProvider!.getQuickStats();
          final todaySteps = quickStats['today_steps'] as int? ?? 0;
          final todayDistance = quickStats['today_distance'] as double? ?? 0.0;
          final todayCalories = quickStats['today_calories'] as double? ?? 0.0;

          totalSteps += todaySteps;
          totalDistance += todayDistance;
          totalCalories += todayCalories;
          if (todaySteps > 0) activeDays++;

          debugPrint('   📅 $dateStr (اليوم): $todaySteps خطوة');
        } else {
          final activity = await _activityRepo.getDailyActivityForDate(dateStr);
          if (activity != null) {
            totalSteps += activity.totalSteps;
            totalDistance += activity.distance;
            totalCalories += activity.caloriesBurned;
            if (activity.totalSteps > 0) activeDays++;

            debugPrint('   📅 $dateStr: ${activity.totalSteps} خطوة');
          }
        }

        currentDate = currentDate.add(const Duration(days: 1));
      }

      final days = endDate.difference(startDate).inDays + 1;
      final avgDailySteps = days > 0 ? (totalSteps / days).round() : 0;

      // ✅ حفظ محلي بدون setState
      _tempActivityStats = {
        'total_steps': totalSteps,
        'avg_daily_steps': avgDailySteps,
        'total_distance': totalDistance,
        'total_calories': totalCalories,
        'active_days': activeDays,
        'period_days': days,
        'today_steps': 0,
        'score': _calculateActivityScore(totalSteps, avgDailySteps, activeDays),
        'has_data': totalSteps > 0,
      };

      debugPrint('   ✅ تم حفظ activityStats محلياً: $_tempActivityStats');
      debugPrint('   ✅ النتيجة النهائية:');
      debugPrint('      - مجموع الخطوات: $totalSteps');
      debugPrint('      - معدل يومي: $avgDailySteps خطوة');
      debugPrint('      - أيام نشطة: $activeDays من $days يوم');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    } catch (e, stack) {
      debugPrint('❌ [Activity Stats] خطأ: $e');
      debugPrint('Stack: $stack');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ⭐ إحصائيات النوم - NO setState
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _loadSleepStats(DateTime startDate, DateTime endDate) async {
    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('😴 [Sleep Stats] جلب البيانات يوم بيوم...');
      debugPrint('   الفترة: ${_formatDate(startDate)} → ${_formatDate(endDate)}');

      var currentDate = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);
      final today = _formatDate(DateTime.now());

      int totalMinutes = 0;
      int totalSessions = 0;
      double totalQualityScore = 0.0;
      int qualityCount = 0;

      while (currentDate.isBefore(end.add(const Duration(days: 1)))) {
        final dateStr = _formatDate(currentDate);
        final isToday = dateStr == today;

        if (isToday && sleepProvider != null && sleepProvider!.state.hasActiveSession) {
          final session = sleepProvider!.state.currentSession;
          if (session != null) {
            final duration = DateTime.now().difference(session.startTime);
            totalMinutes += duration.inMinutes;
            totalSessions++;

            debugPrint('   📅 $dateStr (جلسة نشطة): ${duration.inHours}h ${duration.inMinutes % 60}m');
          }
        } else {
          final sessions = await _sleepRepo.getSleepSessionsForDate(dateStr);
          for (final session in sessions) {
            if (session.isCompleted && session.duration != null && session.duration!.inMinutes > 30) {
              totalMinutes += session.duration!.inMinutes;
              totalSessions++;

              if (session.qualityScore != null && session.qualityScore! > 0) {
                totalQualityScore += session.qualityScore!;
                qualityCount++;
              }

              debugPrint('   📅 $dateStr: ${(session.duration!.inMinutes / 60.0).toStringAsFixed(1)}h');
            }
          }
        }

        currentDate = currentDate.add(const Duration(days: 1));
      }

      final avgDurationMinutes = totalSessions > 0 ? totalMinutes / totalSessions : 0.0;
      final avgDurationHours = avgDurationMinutes / 60.0;
      final avgQualityScore = qualityCount > 0 ? totalQualityScore / qualityCount : 0.0;

      // ✅ حفظ محلي بدون setState
      _tempSleepStats = {
        'total_sessions': totalSessions,
        'completed_sessions': totalSessions,
        'avg_duration_hours': avgDurationHours,
        'avg_duration_minutes': avgDurationMinutes,
        'avg_quality_score': avgQualityScore,
        'total_hours': totalMinutes / 60.0,
        'has_active_session': sleepProvider?.state.hasActiveSession ?? false,
        'score': _calculateSleepScore(avgDurationHours, avgQualityScore, totalSessions),
        'has_data': totalSessions > 0,
      };

      debugPrint('   ✅ تم حفظ sleepStats محلياً: $_tempSleepStats');
      debugPrint('   ✅ النتيجة النهائية:');
      debugPrint('      - جلسات مكتملة: $totalSessions');
      debugPrint('      - مجموع الدقائق: $totalMinutes');
      debugPrint('      - معدل المدة: ${avgDurationHours.toStringAsFixed(1)} ساعة');
      debugPrint('      - معدل الجودة: ${avgQualityScore.toStringAsFixed(1)}/10');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    } catch (e, stack) {
      debugPrint('❌ [Sleep Stats] خطأ: $e');
      debugPrint('Stack: $stack');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ⭐ إحصائيات الهاتف - NO setState - بدون Pickups
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _loadPhoneStats(DateTime startDate, DateTime endDate) async {
    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📱 [Phone Stats] جلب البيانات (بدون pickups)...');
      debugPrint('   الفترة: ${_formatDate(startDate)} → ${_formatDate(endDate)}');

      var currentDate = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);
      final today = _formatDate(DateTime.now());

      int totalUsageSeconds = 0;

      while (currentDate.isBefore(end.add(const Duration(days: 1)))) {
        final dateStr = _formatDate(currentDate);
        final isToday = dateStr == today;

        if (isToday && phoneUsageProvider != null) {
          final todayUsage = phoneUsageProvider!.state.todaysTotalUsage;
          final seconds = todayUsage.inSeconds;

          totalUsageSeconds += seconds;

          debugPrint('   📅 $dateStr (اليوم): ${(seconds / 3600).toStringAsFixed(1)}h');
        } else {
          final appUsageList = await _phoneRepo.getAppUsageForDate(dateStr);

          int dailySeconds = 0;
          for (final app in appUsageList) {
            dailySeconds += app.totalUsageTime.inSeconds;
          }

          totalUsageSeconds += dailySeconds;

          if (dailySeconds > 0) {
            debugPrint('   📅 $dateStr: ${(dailySeconds / 3600).toStringAsFixed(1)}h');
          }
        }

        currentDate = currentDate.add(const Duration(days: 1));
      }

      final totalUsageHours = totalUsageSeconds / 3600;
      final days = endDate.difference(startDate).inDays + 1;
      final avgDailyUsageHours = days > 0 ? totalUsageHours / days : 0.0;

      // ✅ حفظ محلي بدون setState - بدون pickups
      _tempPhoneStats = {
        'total_usage_hours': totalUsageHours,
        'avg_daily_usage_hours': avgDailyUsageHours,
        'period_days': days,
        'today_usage_hours': 0.0,
        'score': _calculatePhoneScore(avgDailyUsageHours),
        'has_data': totalUsageSeconds > 0,
      };

      debugPrint('   ✅ تم حفظ phoneStats محلياً: $_tempPhoneStats');
      debugPrint('   ✅ النتيجة النهائية:');
      debugPrint('      - مجموع الاستخدام: ${totalUsageHours.toStringAsFixed(1)} ساعة');
      debugPrint('      - معدل يومي: ${avgDailyUsageHours.toStringAsFixed(1)} ساعة');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    } catch (e, stack) {
      debugPrint('❌ [Phone Stats] خطأ: $e');
      debugPrint('Stack: $stack');
    }
  }

  double _calculateActivityScore(int totalSteps, int avgSteps, int activeDays) {
    double score = 0.0;

    // نقاط الخطوات اليومية (50%)
    if (avgSteps >= 10000) {
      score += 0.5;
    } else if (avgSteps >= 7500) {
      score += 0.4;
    } else if (avgSteps >= 5000) {
      score += 0.3;
    } else if (avgSteps >= 2500) {
      score += 0.2;
    } else {
      score += 0.1;
    }

    // نقاط الأيام النشطة (50%)
    final periodDays = state.selectedPeriod.days;
    if (periodDays > 0) {
      final activeRatio = activeDays / periodDays;
      score += activeRatio * 0.5;
    }

    return score.clamp(0.0, 1.0);
  }

  double _calculateSleepScore(double avgHours, double avgQuality, int totalSessions) {
    double score = 0.0;

    // نقاط المدة (60%)
    if (avgHours >= 7 && avgHours <= 9) {
      score += 0.6;
    } else if (avgHours >= 6 && avgHours <= 10) {
      score += 0.4;
    } else if (avgHours >= 5) {
      score += 0.2;
    }

    // نقاط الجودة (40%)
    score += (avgQuality / 10.0) * 0.4;

    return score.clamp(0.0, 1.0);
  }

  double _calculatePhoneScore(double avgDailyHours) {
    // كلما قل الاستخدام، كانت النتيجة أفضل
    if (avgDailyHours <= 2) {
      return 1.0;
    } else if (avgDailyHours <= 4) {
      return 0.8;
    } else if (avgDailyHours <= 6) {
      return 0.6;
    } else if (avgDailyHours <= 8) {
      return 0.4;
    } else {
      return 0.2;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ⭐ توليد بيانات المخطط - NO setState
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _generateChartData() async {
    try {
      debugPrint('📊 توليد بيانات المخطط...');

      final dates = _getDateRange(state.selectedPeriod);
      final chartData = <Map<String, dynamic>>[];

      switch (state.selectedCategory) {
        case StatisticsCategory.sleep:
          chartData.addAll(await _getSleepChartData(dates['start']!, dates['end']!));
          break;
        case StatisticsCategory.phoneUsage:
          chartData.addAll(await _getPhoneChartData(dates['start']!, dates['end']!));
          break;
        case StatisticsCategory.activity:
          chartData.addAll(await _getActivityChartData(dates['start']!, dates['end']!));
          break;
      }

      // ✅ حفظ محلي بدون setState
      _tempChartData = chartData;

      debugPrint('✅ تم توليد ${chartData.length} نقطة للمخطط (محفوظة محلياً)');
    } catch (e) {
      debugPrint('❌ خطأ في توليد بيانات المخطط: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getSleepChartData(
      DateTime startDate,
      DateTime endDate,
      ) async {
    final data = <Map<String, dynamic>>[];

    var currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    while (currentDate.isBefore(end.add(const Duration(days: 1)))) {
      final dateStr = _formatDate(currentDate);
      final isToday = dateStr == _formatDate(DateTime.now());

      double hours = 0.0;

      if (isToday && sleepProvider != null && sleepProvider!.state.hasActiveSession) {
        final session = sleepProvider!.state.currentSession;
        if (session != null) {
          final duration = DateTime.now().difference(session.startTime);
          hours = duration.inMinutes / 60.0;
        }
      } else {
        final sessions = await _sleepRepo.getSleepSessionsForDate(dateStr);
        if (sessions.isNotEmpty && sessions.first.duration != null) {
          hours = sessions.first.duration!.inMinutes / 60.0;
        }
      }

      data.add({
        'date': dateStr,
        'value': hours,
        'label': _getDayLabel(currentDate),
        'is_today': isToday,
      });

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return data;
  }

  Future<List<Map<String, dynamic>>> _getPhoneChartData(
      DateTime startDate,
      DateTime endDate,
      ) async {
    final data = <Map<String, dynamic>>[];

    var currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    while (currentDate.isBefore(end.add(const Duration(days: 1)))) {
      final dateStr = _formatDate(currentDate);
      final isToday = dateStr == _formatDate(DateTime.now());

      double hours = 0.0;

      if (isToday && phoneUsageProvider != null) {
        final todayUsage = phoneUsageProvider!.state.todaysTotalUsage;
        hours = todayUsage.inSeconds / 3600.0;
      } else {
        final appUsageList = await _phoneRepo.getAppUsageForDate(dateStr);

        int totalSeconds = 0;
        for (final app in appUsageList) {
          totalSeconds += app.totalUsageTime.inSeconds;
        }

        hours = totalSeconds / 3600.0;
      }

      data.add({
        'date': dateStr,
        'value': hours,
        'label': _getDayLabel(currentDate),
        'is_today': isToday,
      });

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return data;
  }

  Future<List<Map<String, dynamic>>> _getActivityChartData(
      DateTime startDate,
      DateTime endDate,
      ) async {
    final data = <Map<String, dynamic>>[];

    var currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    while (currentDate.isBefore(end.add(const Duration(days: 1)))) {
      final dateStr = _formatDate(currentDate);
      final isToday = dateStr == _formatDate(DateTime.now());

      int steps = 0;

      if (isToday && activityProvider != null) {
        final quickStats = activityProvider!.getQuickStats();
        steps = quickStats['today_steps'] as int? ?? 0;
      } else {
        final activity = await _activityRepo.getDailyActivityForDate(dateStr);
        if (activity != null) {
          steps = activity.totalSteps;
        }
      }

      data.add({
        'date': dateStr,
        'value': steps.toDouble(),
        'label': _getDayLabel(currentDate),
        'is_today': isToday,
      });

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return data;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // دوال عامة
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> changePeriod(StatisticsPeriod period) async {
    setState(state.copyWith(selectedPeriod: period));
    await _loadAllStats();
  }

  Future<void> changeCategory(StatisticsCategory category) async {
    setState(state.copyWith(selectedCategory: category));
    await _generateChartData();

    // Update chart data only
    setState(state.copyWith(chartData: _tempChartData));
  }

  Map<String, DateTime> _getDateRange(StatisticsPeriod period) {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    DateTime start;
    switch (period) {
      case StatisticsPeriod.day:
        start = DateTime(now.year, now.month, now.day);
        break;
      case StatisticsPeriod.week:
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        break;
      case StatisticsPeriod.month:
        start = DateTime(now.year, now.month, 1);
        break;
      case StatisticsPeriod.year:
        start = DateTime(now.year, 1, 1);
        break;
    }

    return {'start': start, 'end': end};
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getDayLabel(DateTime date) {
    switch (state.selectedPeriod) {
      case StatisticsPeriod.day:
        return '${date.hour}:00';
      case StatisticsPeriod.week:
        const days = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
        return days[date.weekday % 7];
      case StatisticsPeriod.month:
        return '${date.day}';
      case StatisticsPeriod.year:
        const months = [
          'يناير',
          'فبراير',
          'مارس',
          'أبريل',
          'مايو',
          'يونيو',
          'يوليو',
          'أغسطس',
          'سبتمبر',
          'أكتوبر',
          'نوفمبر',
          'ديسمبر'
        ];
        return months[date.month - 1];
    }
  }

  @override
  void dispose() {
    debugPrint('🗑️ تنظيف StatisticsProvider');
    super.dispose();
  }
}