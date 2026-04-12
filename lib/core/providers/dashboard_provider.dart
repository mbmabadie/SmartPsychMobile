// lib/core/providers/dashboard_provider.dart - Updated for SimpleMeal
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../database/repositories/phone_usage_repository.dart';
import '../database/repositories/sleep_repository.dart';
import '../database/repositories/activity_repository.dart';
import '../database/repositories/insights_repository.dart';
import '../database/models/simple_meal.dart'; // ✅ Added import
import '../services/app_usage_service.dart';
import '../services/insights_service.dart';
import 'base/base_state.dart';
import 'base/base_provider.dart';
import 'statistics_provider.dart';

/// Chart Data Point Model
@immutable
class ChartDataPoint {
  final double x;
  final double y;
  final String label;
  final DateTime date;
  final String? unit;
  final Color? color;
  final Map<String, dynamic>? metadata;

  const ChartDataPoint({
    required this.x,
    required this.y,
    required this.label,
    required this.date,
    this.unit,
    this.color,
    this.metadata,
  });

  String get formattedValue {
    if (unit != null) {
      return '${y.toStringAsFixed(1)} $unit';
    }
    return y.toStringAsFixed(1);
  }

  @override
  String toString() {
    return 'ChartDataPoint($label: $formattedValue on ${date.day}/${date.month})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChartDataPoint &&
        other.x == x &&
        other.y == y &&
        other.date == date;
  }

  @override
  int get hashCode => Object.hash(x, y, date);
}

/// Dashboard Stats Model
@immutable
class DashboardStats {
  final double wellnessScore;
  final Map<String, DashboardMetric> metrics;
  final List<DashboardInsight> insights;
  final List<DashboardTrend> trends;
  final DateTime lastUpdated;
  final bool hasRealData;

  const DashboardStats({
    required this.wellnessScore,
    required this.metrics,
    required this.insights,
    required this.trends,
    required this.lastUpdated,
    required this.hasRealData,
  });

  factory DashboardStats.empty() {
    return DashboardStats(
      wellnessScore: 0.0,
      metrics: {},
      insights: [],
      trends: [],
      lastUpdated: DateTime.now(),
      hasRealData: false,
    );
  }

  DashboardStats copyWith({
    double? wellnessScore,
    Map<String, DashboardMetric>? metrics,
    List<DashboardInsight>? insights,
    List<DashboardTrend>? trends,
    DateTime? lastUpdated,
    bool? hasRealData,
  }) {
    return DashboardStats(
      wellnessScore: wellnessScore ?? this.wellnessScore,
      metrics: metrics ?? this.metrics,
      insights: insights ?? this.insights,
      trends: trends ?? this.trends,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      hasRealData: hasRealData ?? this.hasRealData,
    );
  }

  String get wellnessGrade {
    if (wellnessScore >= 0.9) return 'ممتاز';
    if (wellnessScore >= 0.8) return 'جيد جداً';
    if (wellnessScore >= 0.7) return 'جيد';
    if (wellnessScore >= 0.6) return 'مقبول';
    if (wellnessScore >= 0.5) return 'يحتاج تحسين';
    return 'ضعيف';
  }

  Color get wellnessColor {
    if (wellnessScore >= 0.8) return Colors.green;
    if (wellnessScore >= 0.6) return Colors.orange;
    return Colors.red;
  }
}

/// Dashboard Metric Model
@immutable
class DashboardMetric {
  final String id;
  final String title;
  final dynamic value;
  final String unit;
  final IconData icon;
  final Color color;
  final DashboardTrend? trend;
  final bool isRealData;
  final DateTime lastUpdated;

  const DashboardMetric({
    required this.id,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    this.trend,
    required this.isRealData,
    required this.lastUpdated,
  });

  String get formattedValue {
    if (value is double) {
      return (value as double).toStringAsFixed(1);
    } else if (value is Duration) {
      final duration = value as Duration;
      if (duration.inHours > 0) {
        return '${duration.inHours}:${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}';
      }
      return '${duration.inMinutes}';
    }
    return value.toString();
  }

  String get displayValue => '$formattedValue $unit';
}

/// Dashboard Insight Model
@immutable
class DashboardInsight {
  final String id;
  final String title;
  final String message;
  final String category;
  final IconData icon;
  final Color color;
  final InsightPriority priority;
  final bool isActionable;
  final List<String> actionSteps;
  final DateTime createdAt;

  const DashboardInsight({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.icon,
    required this.color,
    required this.priority,
    required this.isActionable,
    required this.actionSteps,
    required this.createdAt,
  });
}

/// Dashboard Trend Model
@immutable
class DashboardTrend {
  final String metricId;
  final TrendDirection direction;
  final double changePercent;
  final String period;
  final Color color;

  const DashboardTrend({
    required this.metricId,
    required this.direction,
    required this.changePercent,
    required this.period,
    required this.color,
  });

  String get formattedChange {
    final sign = changePercent >= 0 ? '+' : '';
    return '$sign${changePercent.toStringAsFixed(1)}%';
  }

  IconData get icon {
    switch (direction) {
      case TrendDirection.improving:
        return Icons.trending_up_rounded;
      case TrendDirection.declining:
        return Icons.trending_down_rounded;
      case TrendDirection.stable:
        return Icons.trending_flat_rounded;
    }
  }
}

enum InsightPriority { low, medium, high, critical }
enum TrendDirection { improving, declining, stable }

/// Dashboard State
class DashboardState extends BaseState {
  final DashboardStats stats;
  final StatisticsPeriod selectedPeriod;
  final bool isRefreshing;
  final Map<String, List<ChartDataPoint>> chartData;
  final DateTime? lastDataRefresh;

  DashboardState({
    super.loadingState,
    super.error,
    super.lastUpdated,
    super.hasData,
    super.successMessage,
    required this.stats,
    this.selectedPeriod = StatisticsPeriod.week,
    this.isRefreshing = false,
    this.chartData = const {},
    this.lastDataRefresh,
  });

  factory DashboardState.initial() {
    return DashboardState(
      loadingState: LoadingState.idle,
      hasData: false,
      stats: DashboardStats.empty(),
    );
  }

  DashboardState copyWith({
    LoadingState? loadingState,
    AppError? error,
    DateTime? lastUpdated,
    bool? hasData,
    String? successMessage,
    DashboardStats? stats,
    StatisticsPeriod? selectedPeriod,
    bool? isRefreshing,
    Map<String, List<ChartDataPoint>>? chartData,
    DateTime? lastDataRefresh,
  }) {
    return DashboardState(
      loadingState: loadingState ?? this.loadingState,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      hasData: hasData ?? this.hasData,
      successMessage: successMessage ?? this.successMessage,
      stats: stats ?? this.stats,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      chartData: chartData ?? this.chartData,
      lastDataRefresh: lastDataRefresh ?? this.lastDataRefresh,
    );
  }
}

/// Dashboard Provider
class DashboardProvider extends BaseProvider<DashboardState>
    with PeriodicUpdateMixin<DashboardState> {

  // Repositories for real data
  final PhoneUsageRepository _phoneRepo;
  final SleepRepository _sleepRepo;
  final ActivityRepository _activityRepo;
  final InsightsRepository _insightsRepo;

  // Services
  final AppUsageService _appUsageService;
  final InsightsService _insightsService;

  DashboardProvider({
    PhoneUsageRepository? phoneRepo,
    SleepRepository? sleepRepo,
    ActivityRepository? activityRepo,
    InsightsRepository? insightsRepo,
    AppUsageService? appUsageService,
    InsightsService? insightsService,
  })  : _phoneRepo = phoneRepo ?? PhoneUsageRepository(),
        _sleepRepo = sleepRepo ?? SleepRepository(),
        _activityRepo = activityRepo ?? ActivityRepository(),
        _insightsRepo = insightsRepo ?? InsightsRepository(),
        _appUsageService = appUsageService ?? AppUsageService.instance,
        _insightsService = insightsService ?? InsightsService.instance,
        super(DashboardState.initial()) {

    debugPrint('📊 تهيئة DashboardProvider مع البيانات الحقيقية...');
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    await executeWithLoading(() async {
      await _loadRealDashboardData();

      // Start periodic updates every 5 minutes
      startPeriodicUpdates(interval: const Duration(minutes: 5));

      setState(state.copyWith(
        hasData: true,
        lastDataRefresh: DateTime.now(),
      ));

      debugPrint('✅ تم تهيئة Dashboard مع البيانات الحقيقية');
    });
  }

  // ================================
  // Real Data Loading Methods
  // ================================

  Future<void> _loadRealDashboardData() async {
    try {
      debugPrint('🔄 تحميل البيانات الحقيقية للداشبورد...');

      final today = _formatDate(DateTime.now());

      // Load real data from all sources
      final realMetrics = await _loadRealMetrics(today);
      final realInsights = await _loadRealInsights(today);
      final realTrends = await _calculateRealTrends();
      final wellnessScore = _calculateRealWellnessScore(realMetrics);
      final chartData = await _loadRealChartData();

      final stats = DashboardStats(
        wellnessScore: wellnessScore,
        metrics: realMetrics,
        insights: realInsights,
        trends: realTrends,
        lastUpdated: DateTime.now(),
        hasRealData: true,
      );

      setState(state.copyWith(
        stats: stats,
        chartData: chartData,
      ));

      debugPrint('✅ تم تحميل البيانات الحقيقية: ${realMetrics.length} مقاييس، ${realInsights.length} رؤى');

    } catch (e) {
      debugPrint('❌ خطأ في تحميل البيانات الحقيقية: $e');
      rethrow;
    }
  }

  Future<Map<String, DashboardMetric>> _loadRealMetrics(String date) async {
    final metrics = <String, DashboardMetric>{};
    final now = DateTime.now();

    try {
      // Real Sleep Data
      final sleepSessions = await _sleepRepo.getSleepSessionsForDate(date);
      if (sleepSessions.isNotEmpty) {
        final session = sleepSessions.first;
        final sleepHours = session.duration?.inHours.toDouble() ?? 0.0;
        final sleepMinutes = session.duration?.inMinutes.remainder(60) ?? 0;

        metrics['sleep_duration'] = DashboardMetric(
          id: 'sleep_duration',
          title: 'مدة النوم',
          value: sleepHours + (sleepMinutes / 60.0),
          unit: 'ساعات',
          icon: Icons.bedtime_rounded,
          color: Colors.purple,
          isRealData: true,
          lastUpdated: now,
        );

        if (session.qualityScore != null) {
          metrics['sleep_quality'] = DashboardMetric(
            id: 'sleep_quality',
            title: 'جودة النوم',
            value: (session.qualityScore! * 100).round(),
            unit: '%',
            icon: Icons.stars_rounded,
            color: Colors.amber,
            isRealData: true,
            lastUpdated: now,
          );
        }
      }

      // Real Phone Usage Data
      final phoneUsage = await _phoneRepo.getPhoneUsageForDate(date);
      if (phoneUsage != null) {
        final usageHours = phoneUsage.totalUsageTime.inHours.toDouble();
        final usageMinutes = phoneUsage.totalUsageTime.inMinutes.remainder(60);

        metrics['phone_usage'] = DashboardMetric(
          id: 'phone_usage',
          title: 'استخدام الهاتف',
          value: usageHours + (usageMinutes / 60.0),
          unit: 'ساعات',
          icon: Icons.phone_android_rounded,
          color: Colors.blue,
          isRealData: true,
          lastUpdated: now,
        );

        metrics['phone_pickups'] = DashboardMetric(
          id: 'phone_pickups',
          title: 'مرات فتح الهاتف',
          value: phoneUsage.totalPickups,
          unit: 'مرة',
          icon: Icons.touch_app_rounded,
          color: Colors.orange,
          isRealData: true,
          lastUpdated: now,
        );

        if (phoneUsage.nightUsageDuration.inMinutes > 0) {
          metrics['night_usage'] = DashboardMetric(
            id: 'night_usage',
            title: 'الاستخدام الليلي',
            value: phoneUsage.nightUsageDuration.inMinutes,
            unit: 'دقيقة',
            icon: Icons.nightlight_round,
            color: Colors.indigo,
            isRealData: true,
            lastUpdated: now,
          );
        }
      }

      // Real Activity Data
      final activity = await _activityRepo.getDailyActivityForDate(date);
      if (activity != null) {
        metrics['steps'] = DashboardMetric(
          id: 'steps',
          title: 'الخطوات',
          value: activity.totalSteps,
          unit: 'خطوة',
          icon: Icons.directions_run_rounded,
          color: Colors.green,
          isRealData: true,
          lastUpdated: now,
        );

        if (activity.distance > 0) {
          metrics['distance'] = DashboardMetric(
            id: 'distance',
            title: 'المسافة',
            value: (activity.distance / 1000), // Convert to km
            unit: 'كم',
            icon: Icons.straighten_rounded,
            color: Colors.teal,
            isRealData: true,
            lastUpdated: now,
          );
        }

        if (activity.caloriesBurned > 0) {
          metrics['calories_burned'] = DashboardMetric(
            id: 'calories_burned',
            title: 'السعرات المحروقة',
            value: activity.caloriesBurned.round(),
            unit: 'سعرة',
            icon: Icons.local_fire_department_rounded,
            color: Colors.red,
            isRealData: true,
            lastUpdated: now,
          );
        }
      }


      debugPrint('📊 تم تحميل ${metrics.length} مقياس حقيقي');
      return metrics;

    } catch (e) {
      debugPrint('❌ خطأ في تحميل المقاييس الحقيقية: $e');
      return {};
    }
  }

  Future<List<DashboardInsight>> _loadRealInsights(String date) async {
    try {
      final insights = <DashboardInsight>[];

      // Load real insights from database
      final dbInsights = await _insightsRepo.getInsightsForDate(date);

      for (final insight in dbInsights.take(5)) {
        // ✅ Fixed: Create unique ID without using insight.id (doesn't exist)
        final uniqueId = _insightsRepo.createUniqueId(insight);

        insights.add(DashboardInsight(
          id: uniqueId, // ✅ Use createUniqueId method
          title: insight.title,
          message: insight.message,
          category: insight.category,
          icon: _getInsightIcon(insight.category),
          color: _getInsightColor(insight.category),
          priority: _mapInsightPriority(insight.confidenceScore),
          isActionable: insight.metadata?.isNotEmpty ?? false, // ✅ Fixed: Use metadata instead of relatedData
          actionSteps: _generateActionSteps(insight.category),
          createdAt: insight.createdAt,
        ));
      }

      // Generate real-time insights based on current data
      await _generateRealTimeInsights(insights, date);

      debugPrint('💡 تم تحميل ${insights.length} رؤية حقيقية');
      return insights;

    } catch (e) {
      debugPrint('❌ خطأ في تحميل الرؤى الحقيقية: $e');
      return [];
    }
  }

  Future<void> _generateRealTimeInsights(List<DashboardInsight> insights, String date) async {
    try {
      // Phone usage insight
      final phoneUsage = await _phoneRepo.getPhoneUsageForDate(date);
      if (phoneUsage != null) {
        final usageHours = phoneUsage.totalUsageTime.inHours;

        if (usageHours > 8) {
          insights.add(DashboardInsight(
            id: 'phone_excessive_${DateTime.now().millisecondsSinceEpoch}',
            title: 'استخدام مفرط للهاتف',
            message: 'استخدمت الهاتف ${usageHours} ساعات اليوم. حاول تقليل الوقت للحفاظ على صحتك النفسية.',
            category: 'phone_usage',
            icon: Icons.warning_rounded,
            color: Colors.red,
            priority: InsightPriority.high,
            isActionable: true,
            actionSteps: [
              'ضع حدود زمنية للتطبيقات',
              'استخدم وضع عدم الإزعاج',
              'خذ استراحات منتظمة من الشاشة'
            ],
            createdAt: DateTime.now(),
          ));
        } else if (usageHours < 2) {
          insights.add(DashboardInsight(
            id: 'phone_good_${DateTime.now().millisecondsSinceEpoch}',
            title: 'استخدام متوازن للهاتف',
            message: 'أحسنت! استخدامك للهاتف اليوم متوازن ومناسب.',
            category: 'phone_usage',
            icon: Icons.check_circle_rounded,
            color: Colors.green,
            priority: InsightPriority.medium,
            isActionable: false,
            actionSteps: [],
            createdAt: DateTime.now(),
          ));
        }
      }

      // Activity insight
      final activity = await _activityRepo.getDailyActivityForDate(date);
      if (activity != null) {
        if (activity.totalSteps >= 10000) {
          insights.add(DashboardInsight(
            id: 'steps_goal_${DateTime.now().millisecondsSinceEpoch}',
            title: 'هدف الخطوات محقق!',
            message: 'تهانينا! حققت هدف 10,000 خطوة اليوم. استمر في هذا النشاط الرائع.',
            category: 'activity',
            icon: Icons.emoji_events_rounded,
            color: Colors.amber,
            priority: InsightPriority.medium,
            isActionable: false,
            actionSteps: [],
            createdAt: DateTime.now(),
          ));
        } else if (activity.totalSteps < 5000) {
          insights.add(DashboardInsight(
            id: 'steps_low_${DateTime.now().millisecondsSinceEpoch}',
            title: 'نشاط قليل اليوم',
            message: 'مشيت ${activity.totalSteps} خطوة فقط. حاول إضافة المزيد من الحركة.',
            category: 'activity',
            icon: Icons.directions_walk_rounded,
            color: Colors.orange,
            priority: InsightPriority.medium,
            isActionable: true,
            actionSteps: [
              'امش 15 دقيقة إضافية',
              'اصعد الدرج بدلاً من المصعد',
              'خذ استراحة للمشي كل ساعة'
            ],
            createdAt: DateTime.now(),
          ));
        }
      }


    } catch (e) {
      debugPrint('❌ خطأ في توليد الرؤى الفورية: $e');
    }
  }

  Future<List<DashboardTrend>> _calculateRealTrends() async {
    final trends = <DashboardTrend>[];

    try {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      // Calculate phone usage trend
      final todayUsage = await _phoneRepo.getPhoneUsageForDate(_formatDate(today));
      final yesterdayUsage = await _phoneRepo.getPhoneUsageForDate(_formatDate(yesterday));

      if (todayUsage != null && yesterdayUsage != null) {
        final todayMinutes = todayUsage.totalUsageTime.inMinutes.toDouble();
        final yesterdayMinutes = yesterdayUsage.totalUsageTime.inMinutes.toDouble();

        if (yesterdayMinutes > 0) {
          final changePercent = ((todayMinutes - yesterdayMinutes) / yesterdayMinutes) * 100;

          trends.add(DashboardTrend(
            metricId: 'phone_usage',
            direction: changePercent > 5 ? TrendDirection.declining :
            changePercent < -5 ? TrendDirection.improving : TrendDirection.stable,
            changePercent: changePercent.abs(),
            period: 'يومي',
            color: changePercent > 5 ? Colors.red :
            changePercent < -5 ? Colors.green : Colors.orange,
          ));
        }
      }

      // Calculate activity trend
      final todayActivity = await _activityRepo.getDailyActivityForDate(_formatDate(today));
      final yesterdayActivity = await _activityRepo.getDailyActivityForDate(_formatDate(yesterday));

      if (todayActivity != null && yesterdayActivity != null) {
        final todaySteps = todayActivity.totalSteps.toDouble();
        final yesterdaySteps = yesterdayActivity.totalSteps.toDouble();

        if (yesterdaySteps > 0) {
          final changePercent = ((todaySteps - yesterdaySteps) / yesterdaySteps) * 100;

          trends.add(DashboardTrend(
            metricId: 'steps',
            direction: changePercent > 5 ? TrendDirection.improving :
            changePercent < -5 ? TrendDirection.declining : TrendDirection.stable,
            changePercent: changePercent.abs(),
            period: 'يومي',
            color: changePercent > 5 ? Colors.green :
            changePercent < -5 ? Colors.red : Colors.orange,
          ));
        }
      }

      debugPrint('📈 تم حساب ${trends.length} اتجاه حقيقي');
      return trends;

    } catch (e) {
      debugPrint('❌ خطأ في حساب الاتجاهات: $e');
      return [];
    }
  }

  double _calculateRealWellnessScore(Map<String, DashboardMetric> metrics) {
    double score = 0.0;
    int factors = 0;

    // Sleep factor (30%)
    final sleepDuration = metrics['sleep_duration'];
    if (sleepDuration != null) {
      final hours = sleepDuration.value as double;
      if (hours >= 7 && hours <= 9) {
        score += 0.3;
      } else if (hours >= 6 && hours <= 10) {
        score += 0.2;
      } else {
        score += 0.1;
      }
      factors++;
    }

    // Phone usage factor (25%) - less is better
    final phoneUsage = metrics['phone_usage'];
    if (phoneUsage != null) {
      final hours = phoneUsage.value as double;
      if (hours <= 3) {
        score += 0.25;
      } else if (hours <= 5) {
        score += 0.15;
      } else if (hours <= 7) {
        score += 0.1;
      }
      factors++;
    }

    // Activity factor (25%)
    final steps = metrics['steps'];
    if (steps != null) {
      final stepCount = steps.value as int;
      if (stepCount >= 10000) {
        score += 0.25;
      } else if (stepCount >= 7500) {
        score += 0.2;
      } else if (stepCount >= 5000) {
        score += 0.15;
      } else {
        score += 0.1;
      }
      factors++;
    }

    // Nutrition factor (20%) - updated for SimpleMeal
    final mealsCount = metrics['meals_count'];
    if (mealsCount != null) {
      final meals = mealsCount.value as int;
      if (meals >= 4) { // 4+ meals is ideal
        score += 0.2;
      } else if (meals >= 3) { // 3 main meals
        score += 0.15;
      } else if (meals >= 2) {
        score += 0.1;
      } else {
        score += 0.05;
      }
      factors++;
    }

    // Bonus: Main meals coverage
    final hasBreakfast = metrics['breakfast_status'] != null;
    final hasLunch = metrics['lunch_status'] != null;
    final hasDinner = metrics['dinner_status'] != null;

    if (hasBreakfast && hasLunch && hasDinner) {
      score += 0.05; // Bonus for complete meal pattern
    }

    // Normalize score based on available factors
    if (factors > 0) {
      final maxPossibleScore = (factors * 0.25) + (hasBreakfast && hasLunch && hasDinner ? 0.05 : 0);
      score = score / maxPossibleScore;
    }

    return score.clamp(0.0, 1.0);
  }

  Future<Map<String, List<ChartDataPoint>>> _loadRealChartData() async {
    final chartData = <String, List<ChartDataPoint>>{};

    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: state.selectedPeriod.days));

      // Load phone usage chart data
      chartData['phone_usage'] = await _loadPhoneUsageChartData(startDate, endDate);

      // Load activity chart data
      chartData['activity'] = await _loadActivityChartData(startDate, endDate);

      // Load sleep chart data
      chartData['sleep'] = await _loadSleepChartData(startDate, endDate);

      debugPrint('📊 تم تحميل بيانات الرسوم البيانية الحقيقية');
      return chartData;

    } catch (e) {
      debugPrint('❌ خطأ في تحميل بيانات الرسوم البيانية: $e');
      return {};
    }
  }

  Future<List<ChartDataPoint>> _loadPhoneUsageChartData(DateTime startDate, DateTime endDate) async {
    final dataPoints = <ChartDataPoint>[];

    var currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    while (currentDate.isBefore(end.add(const Duration(days: 1)))) {
      final dateStr = _formatDate(currentDate);
      final usage = await _phoneRepo.getPhoneUsageForDate(dateStr);

      if (usage != null) {
        dataPoints.add(ChartDataPoint(
          x: dataPoints.length.toDouble(),
          y: usage.totalUsageTime.inMinutes / 60.0, // Convert to hours
          label: '${currentDate.day}/${currentDate.month}',
          date: currentDate,
          unit: 'ساعات',
        ));
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return dataPoints;
  }

  Future<List<ChartDataPoint>> _loadActivityChartData(DateTime startDate, DateTime endDate) async {
    final dataPoints = <ChartDataPoint>[];

    var currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    while (currentDate.isBefore(end.add(const Duration(days: 1)))) {
      final dateStr = _formatDate(currentDate);
      final activity = await _activityRepo.getDailyActivityForDate(dateStr);

      if (activity != null) {
        dataPoints.add(ChartDataPoint(
          x: dataPoints.length.toDouble(),
          y: activity.totalSteps.toDouble(),
          label: '${currentDate.day}/${currentDate.month}',
          date: currentDate,
          unit: 'خطوة',
        ));
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return dataPoints;
  }

  Future<List<ChartDataPoint>> _loadSleepChartData(DateTime startDate, DateTime endDate) async {
    final dataPoints = <ChartDataPoint>[];

    var currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    while (currentDate.isBefore(end.add(const Duration(days: 1)))) {
      final dateStr = _formatDate(currentDate);
      final sessions = await _sleepRepo.getSleepSessionsForDate(dateStr);

      if (sessions.isNotEmpty && sessions.first.duration != null) {
        dataPoints.add(ChartDataPoint(
          x: dataPoints.length.toDouble(),
          y: sessions.first.duration!.inMinutes / 60.0, // Convert to hours
          label: '${currentDate.day}/${currentDate.month}',
          date: currentDate,
          unit: 'ساعات',
        ));
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return dataPoints;
  }
  // ================================
  // Public Methods
  // ================================

  Future<void> refreshDashboard() async {
    setState(state.copyWith(isRefreshing: true));

    try {
      await _loadRealDashboardData();

      setState(state.copyWith(
        isRefreshing: false,
        lastDataRefresh: DateTime.now(),
        successMessage: 'تم تحديث البيانات بنجاح',
      ));

    } catch (e) {
      setState(state.copyWith(
        isRefreshing: false,
        // Note: Commented out error creation as AppError might not have .unknown constructor
        // error: AppError.unknown('فشل في تحديث البيانات: $e'),
      ));
    }
  }

  Future<void> changePeriod(StatisticsPeriod period) async {
    setState(state.copyWith(selectedPeriod: period));

    // Reload chart data for new period
    final chartData = await _loadRealChartData();
    setState(state.copyWith(chartData: chartData));
  }

  List<ChartDataPoint> getChartDataForMetric(String metricId) {
    return state.chartData[metricId] ?? [];
  }

  DashboardMetric? getMetric(String metricId) {
    return state.stats.metrics[metricId];
  }

  List<DashboardInsight> getInsightsByCategory(String category) {
    return state.stats.insights.where((insight) => insight.category == category).toList();
  }
  // ================================
  // Helper Methods
  // ================================

  IconData _getInsightIcon(String category) {
    switch (category) {
      case 'sleep':
        return Icons.bedtime_rounded;
      case 'phone_usage':
        return Icons.phone_android_rounded;
      case 'activity':
        return Icons.directions_run_rounded;
      case 'nutrition':
        return Icons.restaurant_rounded;
      default:
        return Icons.lightbulb_rounded;
    }
  }

  Color _getInsightColor(String category) {
    switch (category) {
      case 'sleep':
        return Colors.purple;
      case 'phone_usage':
        return Colors.blue;
      case 'activity':
        return Colors.green;
      case 'nutrition':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  InsightPriority _mapInsightPriority(double confidenceScore) {
    if (confidenceScore >= 0.8) return InsightPriority.high;
    if (confidenceScore >= 0.6) return InsightPriority.medium;
    return InsightPriority.low;
  }

  List<String> _generateActionSteps(String category) {
    switch (category) {
      case 'sleep':
        return ['حسّن بيئة النوم', 'حافظ على جدول نوم ثابت', 'تجنب الكافيين مساءً'];
      case 'phone_usage':
        return ['ضع حدود زمنية', 'استخدم وضع عدم الإزعاج', 'خذ استراحات منتظمة'];
      case 'activity':
        return ['امش 30 دقيقة يومياً', 'اصعد الدرج', 'مارس تمارين بسيطة'];
      case 'nutrition':
        return ['تناول وجبات منتظمة', 'سجل وجباتك يومياً', 'تناول 3 وجبات رئيسية'];
      default:
        return ['اتبع نصائح الصحة العامة'];
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // ================================
  // BaseProvider Implementation
  // ================================

  @override
  Future<void> refreshData() async {
    await refreshDashboard();
  }

  @override
  DashboardState _createLoadingState(bool isRefreshing) {
    return state.copyWith(
      loadingState: isRefreshing ? LoadingState.refreshing : LoadingState.loading,
      error: null,
    );
  }

  @override
  DashboardState _createSuccessState({String? message}) {
    return state.copyWith(
      loadingState: LoadingState.success,
      error: null,
      successMessage: message,
    );
  }

  @override
  DashboardState _createErrorState(AppError error) {
    return state.copyWith(
      loadingState: LoadingState.error,
      error: error,
    );
  }

  @override
  DashboardState _createIdleState() {
    return state.copyWith(
      loadingState: LoadingState.idle,
      error: null,
    );
  }

  @override
  Future<void> performPeriodicUpdate() async {
    // Only update if we're not currently refreshing
    if (!state.isRefreshing) {
      debugPrint('🔄 تحديث دوري للداشبورد...');
      await _loadRealDashboardData();
    }
  }

  @override
  void dispose() {
    debugPrint('🗑️ تنظيف DashboardProvider');
    super.dispose();
  }
}