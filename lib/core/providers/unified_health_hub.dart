// lib/core/providers/unified_health_hub.dart
// Unified Health Hub - المركز الصحي الموحد
// يجمع بيانات من Phone/Sleep/Activity ويرسل إشعارات ورؤى ذكية

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'phone_usage_provider.dart';
import 'sleep_tracking_provider.dart';
import 'activity_tracking_provider.dart';
import 'insights_provider.dart';
import 'notification_provider.dart';
import 'base/base_state.dart';
import 'base/base_provider.dart';
import '../services/notification_service.dart';
import '../services/insights_service.dart';
import '../database/repositories/settings_repository.dart';

/// Unified Health Data - البيانات الصحية الموحدة
@immutable
class UnifiedHealthData {
  // ===== بيانات النوم =====
  final double todaySleepHours;
  final double sleepQualityScore;
  final bool isCurrentlySleeping;
  final int sleepInterruptions;

  // ===== بيانات النشاط =====
  final int todaySteps;
  final double todayDistance;
  final int activeMinutes;
  final double caloriesBurned;

  // ===== بيانات استخدام الهاتف =====
  final Duration todayPhoneUsage;
  final int todayPhonePickups;
  final double phoneWellnessScore;
  final Duration nightPhoneUsage;

  // ===== بيانات استخدام التطبيق =====
  final DateTime? lastAppOpen;
  final int daysSinceLastOpen;
  final int consecutiveDaysStreak;
  final bool isActiveToday;
  final DateTime? lastNotificationSent;

  // ===== النتائج الكلية =====
  final DateTime lastUpdated;
  final double overallHealthScore;
  final String healthGrade;
  final bool needsAttention;

  const UnifiedHealthData({
    // Sleep
    this.todaySleepHours = 0.0,
    this.sleepQualityScore = 0.0,
    this.isCurrentlySleeping = false,
    this.sleepInterruptions = 0,

    // Activity
    this.todaySteps = 0,
    this.todayDistance = 0.0,
    this.activeMinutes = 0,
    this.caloriesBurned = 0.0,

    // Phone Usage
    this.todayPhoneUsage = const Duration(),
    this.todayPhonePickups = 0,
    this.phoneWellnessScore = 0.0,
    this.nightPhoneUsage = const Duration(),

    // App Usage
    this.lastAppOpen,
    this.daysSinceLastOpen = 0,
    this.consecutiveDaysStreak = 0,
    this.isActiveToday = false,
    this.lastNotificationSent,

    // Overall
    required this.lastUpdated,
    this.overallHealthScore = 0.0,
    this.healthGrade = 'غير محدد',
    this.needsAttention = false,
  });

  // ===== خصائص محسوبة =====

  bool get hasAnyData =>
      todaySteps > 0 ||
          todaySleepHours > 0 ||
          todayPhoneUsage.inSeconds > 0;

  bool get isHealthy => overallHealthScore >= 0.7;

  bool get isVeryHealthy => overallHealthScore >= 0.85;

  bool get needsMotivation =>
      daysSinceLastOpen >= 1 ||
          (todaySteps < 3000 && DateTime.now().hour >= 16);

  bool get hasGoodSleep =>
      todaySleepHours >= 7 && todaySleepHours <= 9 && sleepQualityScore >= 7;

  bool get hasGoodActivity => todaySteps >= 8000;

  bool get hasHealthyPhoneUsage =>
      todayPhoneUsage.inHours <= 4 && todayPhonePickups <= 60;

  String get sleepStatus {
    if (isCurrentlySleeping) return 'نائم الآن 😴';
    if (todaySleepHours == 0) return 'لم ينم بعد';
    if (todaySleepHours < 6) return 'نوم قصير ⚠️';
    if (todaySleepHours >= 7 && todaySleepHours <= 9) return 'نوم مثالي ✅';
    if (todaySleepHours > 9) return 'نوم طويل 😴';
    return 'نوم جيد';
  }

  String get activityStatus {
    if (todaySteps >= 10000) return 'نشاط ممتاز 🏆';
    if (todaySteps >= 7500) return 'نشاط جيد جداً 💪';
    if (todaySteps >= 5000) return 'نشاط جيد 👍';
    if (todaySteps >= 2000) return 'نشاط منخفض ⚠️';
    if (todaySteps > 0) return 'نشاط قليل جداً 😴';
    return 'لا نشاط';
  }

  String get phoneUsageStatus {
    final hours = todayPhoneUsage.inHours;
    if (hours <= 2) return 'استخدام ممتاز 🌟';
    if (hours <= 4) return 'استخدام متوازن ✅';
    if (hours <= 6) return 'استخدام مرتفع ⚠️';
    return 'استخدام مفرط 🚨';
  }

  String get streakEmoji {
    if (consecutiveDaysStreak >= 30) return '🔥🔥🔥';
    if (consecutiveDaysStreak >= 14) return '🔥🔥';
    if (consecutiveDaysStreak >= 7) return '🔥';
    if (consecutiveDaysStreak >= 3) return '⭐';
    return '💪';
  }

  UnifiedHealthData copyWith({
    double? todaySleepHours,
    double? sleepQualityScore,
    bool? isCurrentlySleeping,
    int? sleepInterruptions,
    int? todaySteps,
    double? todayDistance,
    int? activeMinutes,
    double? caloriesBurned,
    Duration? todayPhoneUsage,
    int? todayPhonePickups,
    double? phoneWellnessScore,
    Duration? nightPhoneUsage,
    DateTime? lastAppOpen,
    int? daysSinceLastOpen,
    int? consecutiveDaysStreak,
    bool? isActiveToday,
    DateTime? lastNotificationSent,
    DateTime? lastUpdated,
    double? overallHealthScore,
    String? healthGrade,
    bool? needsAttention,
  }) {
    return UnifiedHealthData(
      todaySleepHours: todaySleepHours ?? this.todaySleepHours,
      sleepQualityScore: sleepQualityScore ?? this.sleepQualityScore,
      isCurrentlySleeping: isCurrentlySleeping ?? this.isCurrentlySleeping,
      sleepInterruptions: sleepInterruptions ?? this.sleepInterruptions,
      todaySteps: todaySteps ?? this.todaySteps,
      todayDistance: todayDistance ?? this.todayDistance,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      todayPhoneUsage: todayPhoneUsage ?? this.todayPhoneUsage,
      todayPhonePickups: todayPhonePickups ?? this.todayPhonePickups,
      phoneWellnessScore: phoneWellnessScore ?? this.phoneWellnessScore,
      nightPhoneUsage: nightPhoneUsage ?? this.nightPhoneUsage,
      lastAppOpen: lastAppOpen ?? this.lastAppOpen,
      daysSinceLastOpen: daysSinceLastOpen ?? this.daysSinceLastOpen,
      consecutiveDaysStreak: consecutiveDaysStreak ?? this.consecutiveDaysStreak,
      isActiveToday: isActiveToday ?? this.isActiveToday,
      lastNotificationSent: lastNotificationSent ?? this.lastNotificationSent,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      overallHealthScore: overallHealthScore ?? this.overallHealthScore,
      healthGrade: healthGrade ?? this.healthGrade,
      needsAttention: needsAttention ?? this.needsAttention,
    );
  }

  @override
  String toString() {
    return 'UnifiedHealthData('
        'steps: $todaySteps, '
        'sleep: ${todaySleepHours.toStringAsFixed(1)}h, '
        'phone: ${todayPhoneUsage.inMinutes}min, '
        'score: ${(overallHealthScore * 100).round()}%, '
        'streak: $consecutiveDaysStreak, '
        'daysAway: $daysSinceLastOpen'
        ')';
  }
}

/// Unified Health Hub State - حالة المركز الصحي الموحد
class UnifiedHealthHubState extends BaseState {
  final UnifiedHealthData currentData;
  final List<UnifiedHealthData> last7Days;
  final bool isAutoSyncEnabled;
  final DateTime? lastSyncTime;
  final int totalSyncs;

  UnifiedHealthHubState({
    super.loadingState,
    super.error,
    super.lastUpdated,
    super.hasData,
    super.successMessage,
    required this.currentData,
    this.last7Days = const [],
    this.isAutoSyncEnabled = true,
    this.lastSyncTime,
    this.totalSyncs = 0,
  });

  factory UnifiedHealthHubState.initial() {
    return UnifiedHealthHubState(
      loadingState: LoadingState.idle,
      hasData: false,
      currentData: UnifiedHealthData(
        lastUpdated: DateTime.now(),
      ),
    );
  }

  // ===== خصائص محسوبة =====

  bool get hasHistoricalData => last7Days.isNotEmpty;

  bool get isHealthImproving => _calculateTrend() > 0;

  double get averageHealthScore {
    if (last7Days.isEmpty) return currentData.overallHealthScore;
    final sum = last7Days.fold<double>(
      0,
          (sum, data) => sum + data.overallHealthScore,
    );
    return sum / last7Days.length;
  }

  double _calculateTrend() {
    if (last7Days.length < 2) return 0.0;

    final recent = last7Days.take(3).fold<double>(
      0,
          (sum, d) => sum + d.overallHealthScore,
    ) / 3;

    final older = last7Days.skip(4).take(3).fold<double>(
      0,
          (sum, d) => sum + d.overallHealthScore,
    ) / 3;

    return recent - older;
  }

  UnifiedHealthHubState copyWith({
    LoadingState? loadingState,
    AppError? error,
    DateTime? lastUpdated,
    bool? hasData,
    String? successMessage,
    UnifiedHealthData? currentData,
    List<UnifiedHealthData>? last7Days,
    bool? isAutoSyncEnabled,
    DateTime? lastSyncTime,
    int? totalSyncs,
  }) {
    return UnifiedHealthHubState(
      loadingState: loadingState ?? this.loadingState,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      hasData: hasData ?? this.hasData,
      successMessage: successMessage ?? this.successMessage,
      currentData: currentData ?? this.currentData,
      last7Days: last7Days ?? this.last7Days,
      isAutoSyncEnabled: isAutoSyncEnabled ?? this.isAutoSyncEnabled,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      totalSyncs: totalSyncs ?? this.totalSyncs,
    );
  }
}

/// Unified Health Hub Provider - مزود المركز الصحي الموحد
class UnifiedHealthHubProvider extends BaseProvider<UnifiedHealthHubState>
    with PeriodicUpdateMixin<UnifiedHealthHubState> {

  // ===== Dependencies - الاعتماديات =====
  final PhoneUsageProvider phoneProvider;
  final SleepTrackingProvider sleepProvider;
  final ActivityTrackingProvider activityProvider;
  final InsightsTrackingProvider? insightsProvider;
  final NotificationTrackingProvider? notificationProvider;

  // ===== Services - الخدمات =====
  final NotificationService _notificationService = NotificationService.instance;
  final InsightsService _insightsService = InsightsService.instance;
  final SettingsRepository _settingsRepo = SettingsRepository();

  // ===== Timers - المؤقتات =====
  Timer? _syncTimer;
  Timer? _duolingoCheckTimer;
  Timer? _insightsGenerationTimer;

  UnifiedHealthHubProvider({
    required this.phoneProvider,
    required this.sleepProvider,
    required this.activityProvider,
    this.insightsProvider,
    this.notificationProvider,
  }) : super(UnifiedHealthHubState.initial()) {
    debugPrint('🌟 [UnifiedHub] بدء التهيئة...');
    _initialize();
  }

  // ================================
  // BaseProvider Overrides
  // ================================

  @override
  UnifiedHealthHubState _createLoadingState(bool isRefreshing) {
    return state.copyWith(
      loadingState: isRefreshing ? LoadingState.refreshing : LoadingState.loading,
      error: null,
      successMessage: null,
    );
  }

  @override
  UnifiedHealthHubState _createSuccessState() {
    return state.copyWith(
      loadingState: LoadingState.success,
      error: null,
      hasData: true,
    );
  }

  @override
  UnifiedHealthHubState _createErrorState(AppError error) {
    return state.copyWith(
      loadingState: LoadingState.error,
      error: error,
      successMessage: null,
    );
  }

  @override
  UnifiedHealthHubState _createIdleState() {
    return state.copyWith(
      loadingState: LoadingState.idle,
      error: null,
      successMessage: null,
    );
  }

  @override
  Future<void> refreshData() async {
    await forceSync();
  }

  @override
  Future<void> performPeriodicUpdate() async {
    await _performUnifiedSync();
  }

  // ================================
  // Initialization - التهيئة
  // ================================

  Future<void> _initialize() async {
    try {
      debugPrint('🌟 [UnifiedHub] بدء تهيئة المركز الصحي الموحد...');

      // تحديث الحالة يدوياً (بدون executeWithLoading)
      setState(state.copyWith(
        loadingState: LoadingState.loading,
        error: null,
      ));

      // تهيئة الخدمات
      await _notificationService.initialize();
      await _insightsService.initialize();

      // تحديث وقت فتح التطبيق
      await _updateLastAppOpen();

      // ✅ انتظر التهيئة تخلص (مش البيانات!)
      debugPrint('⏳ [UnifiedHub] انتظار PhoneUsageProvider...');

      int attempts = 0;
      while (attempts < 20 &&
          phoneProvider.state.loadingState != LoadingState.success) {
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
      }

      if (phoneProvider.state.loadingState == LoadingState.success) {
        debugPrint('✅ [UnifiedHub] PhoneUsageProvider جاهز!');
      } else {
        debugPrint('⚠️ [UnifiedHub] PhoneUsageProvider: timeout');
      }

      // أول مزامنة (الآن PhoneUsageProvider جاهز!)
      await _performUnifiedSync();

      // بدء المؤقتات الدورية
      _startPeriodicSync();
      _startDuolingoChecks();
      _startInsightsGeneration();

      // النجاح
      setState(state.copyWith(
        loadingState: LoadingState.success,
        error: null,
        hasData: true,
        isAutoSyncEnabled: true,
        lastUpdated: DateTime.now(),
      ));

      debugPrint('✅ [UnifiedHub] تم تهيئة المركز الصحي الموحد بنجاح');
      debugPrint('   📊 البيانات الحالية: ${state.currentData}');

    } catch (e, stack) {
      debugPrint('❌ [UnifiedHub] خطأ في التهيئة: $e');
      debugPrint('Stack: $stack');

      // حالة الخطأ
      setState(state.copyWith(
        loadingState: LoadingState.error,
        error: ServiceError(
          message: 'فشل في تهيئة المركز الصحي: $e',
          originalError: e,
          stackTrace: stack,
        ),
      ));
    }
  }

  // ================================
  // Core Sync - المزامنة الأساسية
  // ================================

  Future<void> _performUnifiedSync() async {
    try {
      debugPrint('🔄 [UnifiedHub] بدء المزامنة الموحدة...');

      // 1️⃣ جمع البيانات من جميع المصادر
      final phoneData = _collectPhoneData();
      final sleepData = _collectSleepData();
      final activityData = _collectActivityData();
      final appUsageData = await _collectAppUsageData();

      debugPrint('   📱 Phone: ${phoneData['usage_minutes']}min, ${phoneData['pickups']} pickups');
      debugPrint('   😴 Sleep: ${sleepData['hours']}h, quality: ${sleepData['quality']}');
      debugPrint('   🏃 Activity: ${activityData['steps']} steps');
      debugPrint('   📲 App: streak ${appUsageData['streak']}, away ${appUsageData['days_away']} days');

      // 2️⃣ حساب النتيجة الكلية
      final overallScore = _calculateOverallHealthScore(
        phoneData,
        sleepData,
        activityData,
      );

      final healthGrade = _getHealthGrade(overallScore);

      // 3️⃣ إنشاء البيانات الموحدة
      final unifiedData = UnifiedHealthData(
        // Sleep
        todaySleepHours: sleepData['hours'] as double,
        sleepQualityScore: sleepData['quality'] as double,
        isCurrentlySleeping: sleepData['is_sleeping'] as bool,
        sleepInterruptions: sleepData['interruptions'] as int,

        // Activity
        todaySteps: activityData['steps'] as int,
        todayDistance: activityData['distance'] as double,
        activeMinutes: activityData['active_minutes'] as int,
        caloriesBurned: activityData['calories'] as double,

        // Phone
        todayPhoneUsage: Duration(minutes: phoneData['usage_minutes'] as int),
    //    todayPhonePickups: phoneData['pickups'] as int,
        phoneWellnessScore: phoneData['wellness'] as double,
        nightPhoneUsage: Duration(minutes: phoneData['night_usage_minutes'] as int),

        // App Usage
        lastAppOpen: appUsageData['last_open'] as DateTime?,
        daysSinceLastOpen: appUsageData['days_away'] as int,
        consecutiveDaysStreak: appUsageData['streak'] as int,
        isActiveToday: appUsageData['active_today'] as bool,
        lastNotificationSent: appUsageData['last_notification'] as DateTime?,

        // Overall
        lastUpdated: DateTime.now(),
        overallHealthScore: overallScore,
        healthGrade: healthGrade,
        needsAttention: appUsageData['days_away'] as int > 0,
      );

      // 4️⃣ حفظ في التاريخ
      final updatedHistory = [
        unifiedData,
        ...state.last7Days.take(6),
      ].toList();

      // 5️⃣ تحديث الحالة
      setState(state.copyWith(
        currentData: unifiedData,
        last7Days: updatedHistory,
        lastSyncTime: DateTime.now(),
        totalSyncs: state.totalSyncs + 1,
        hasData: unifiedData.hasAnyData,
      ));

      debugPrint('✅ [UnifiedHub] مزامنة ناجحة');
      debugPrint('   🎯 النتيجة الكلية: ${(overallScore * 100).round()}% ($healthGrade)');
      debugPrint('   📊 Syncs: ${state.totalSyncs}');

      // 6️⃣ التحقق من الإشعارات والرؤى
      await _checkDuolingoNotifications(unifiedData);
      await _generateSmartInsights(unifiedData);

    } catch (e, stack) {
      debugPrint('❌ [UnifiedHub] خطأ في المزامنة: $e');
      debugPrint('📍 Stack: $stack');
    }
  }

  // ================================
  // Data Collection - جمع البيانات
  // ================================

  Map<String, dynamic> _collectPhoneData() {
    try {
      // ✅ استخدم البيانات الحقيقية من الكاش مباشرة
      final todayUsage = phoneProvider.state.todaysTotalUsage;
      final appsCount = phoneProvider.state.todaysAppUsage.length;

      debugPrint('📱 [Hub] بيانات من State (حقيقية فقط):');
      debugPrint('   - todaysTotalUsage: ${todayUsage.inMinutes}min');
      debugPrint('   - apps_count: $appsCount');

      return {
        'usage_minutes': todayUsage.inMinutes,
        'wellness': phoneProvider.state.wellnessScore,
        'night_usage_minutes': 0, // ❌ غير متاح بدون hourly data
        'apps_count': appsCount,
      };
    } catch (e, stack) {
      debugPrint('❌ خطأ في جمع بيانات الهاتف: $e');
      return {
        'usage_minutes': 0,
        'wellness': 0.0,
        'night_usage_minutes': 0,
        'apps_count': 0,
      };
    }
  }

  Map<String, dynamic> _collectSleepData() {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      double totalHours = 0.0;
      double avgQuality = 0.0;
      int interruptions = 0;
      int sessionCount = 0;

      // ✅ 1. الجلسة النشطة (إذا موجودة)
      if (sleepProvider.state.hasActiveSession) {
        final session = sleepProvider.state.currentSession!;
        final sessionStart = DateTime(
          session.startTime.year,
          session.startTime.month,
          session.startTime.day,
        );

        // تأكد إن الجلسة بدأت اليوم
        if (sessionStart == today) {
          final duration = now.difference(session.startTime);
          totalHours += duration.inMinutes / 60.0;
          interruptions += session.totalInterruptions;
          sessionCount++;

          if (session.qualityScore != null) {
            avgQuality += session.qualityScore!;
          }
        }
      }

      // ✅ 2. الجلسات المكتملة لليوم
      for (final session in sleepProvider.state.recentSessions) {
        final sessionStart = DateTime(
          session.startTime.year,
          session.startTime.month,
          session.startTime.day,
        );

        if (sessionStart == today && session.isCompleted) {
          if (session.duration != null) {
            totalHours += session.duration!.inMinutes / 60.0;
          }
          if (session.qualityScore != null) {
            avgQuality += session.qualityScore!;
          }
          interruptions += session.totalInterruptions;
          sessionCount++;
        }
      }

      // ✅ 3. جلسات pending لليوم
      for (final session in sleepProvider.state.pendingConfirmations) {
        final sessionStart = DateTime(
          session.startTime.year,
          session.startTime.month,
          session.startTime.day,
        );

        if (sessionStart == today) {
          if (session.duration != null) {
            totalHours += session.duration!.inMinutes / 60.0;
          }
          if (session.qualityScore != null) {
            avgQuality += session.qualityScore!;
          }
          interruptions += session.totalInterruptions;
          sessionCount++;
        }
      }

      // ✅ 4. حساب متوسط الجودة
      if (sessionCount > 0 && avgQuality > 0) {
        avgQuality = avgQuality / sessionCount;
      }

      debugPrint('💤 بيانات النوم لليوم:');
      debugPrint('   - مجموع الساعات: ${totalHours.toStringAsFixed(1)}h');
      debugPrint('   - عدد الجلسات: $sessionCount');
      debugPrint('   - متوسط الجودة: ${avgQuality.toStringAsFixed(1)}');
      debugPrint('   - المقاطعات: $interruptions');

      return {
        'hours': totalHours,
        'quality': avgQuality,
        'is_sleeping': sleepProvider.state.hasActiveSession,
        'interruptions': interruptions,
      };

    } catch (e) {
      debugPrint('❌ خطأ في جمع بيانات النوم: $e');
      return {
        'hours': 0.0,
        'quality': 0.0,
        'is_sleeping': false,
        'interruptions': 0,
      };
    }
  }

  Map<String, dynamic> _collectActivityData() {
    try {
      final stats = activityProvider.getQuickStats();

      return {
        'steps': stats['today_steps'] as int? ?? 0,
        'distance': stats['today_distance'] as double? ?? 0.0,
        'active_minutes': stats['active_minutes'] as int? ?? 0,
        'calories': stats['today_calories'] as double? ?? 0.0,
      };
    } catch (e) {
      debugPrint('❌ خطأ في جمع بيانات النشاط: $e');
      return {
        'steps': 0,
        'distance': 0.0,
        'active_minutes': 0,
        'calories': 0.0,
      };
    }
  }

  Future<Map<String, dynamic>> _collectAppUsageData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final lastOpen = prefs.getInt('last_app_open');
      final lastOpenDate = lastOpen != null
          ? DateTime.fromMillisecondsSinceEpoch(lastOpen)
          : null;

      final streak = prefs.getInt('consecutive_days_streak') ?? 0;
      final lastNotif = prefs.getInt('last_duolingo_notification');
      final lastNotifDate = lastNotif != null
          ? DateTime.fromMillisecondsSinceEpoch(lastNotif)
          : null;

      // حساب أيام الغياب
      int daysAway = 0;
      if (lastOpenDate != null) {
        final now = DateTime.now();
        final lastOpenDay = DateTime(lastOpenDate.year, lastOpenDate.month, lastOpenDate.day);
        final today = DateTime(now.year, now.month, now.day);
        daysAway = today.difference(lastOpenDay).inDays;
      }

      // هل نشط اليوم؟
      bool activeToday = false;
      if (lastOpenDate != null) {
        final now = DateTime.now();
        final lastOpenDay = DateTime(lastOpenDate.year, lastOpenDate.month, lastOpenDate.day);
        final today = DateTime(now.year, now.month, now.day);
        activeToday = lastOpenDay == today;
      }

      return {
        'last_open': lastOpenDate,
        'days_away': daysAway,
        'streak': streak,
        'active_today': activeToday,
        'last_notification': lastNotifDate,
      };

    } catch (e) {
      debugPrint('❌ خطأ في جمع بيانات استخدام التطبيق: $e');
      return {
        'last_open': null,
        'days_away': 0,
        'streak': 0,
        'active_today': false,
        'last_notification': null,
      };
    }
  }

  // ================================
  // Health Score Calculation - حساب النتيجة الصحية
  // ================================

  double _calculateOverallHealthScore(
      Map<String, dynamic> phoneData,
      Map<String, dynamic> sleepData,
      Map<String, dynamic> activityData,
      ) {
    double score = 0.0;

    // 1️⃣ النشاط (40%)
    final steps = activityData['steps'] as int;
    if (steps >= 10000) {
      score += 0.40;
    } else if (steps >= 7500) {
      score += 0.30;
    } else if (steps >= 5000) {
      score += 0.20;
    } else if (steps >= 2000) {
      score += 0.10;
    } else if (steps > 0) {
      score += 0.05;
    }

    // 2️⃣ النوم (35%)
    final sleepHours = sleepData['hours'] as double;
    if (sleepHours >= 7 && sleepHours <= 9) {
      score += 0.35; // مثالي
    } else if (sleepHours >= 6 && sleepHours < 7) {
      score += 0.25; // جيد
    } else if (sleepHours >= 5 && sleepHours < 6) {
      score += 0.15; // مقبول
    } else if (sleepHours > 0 && sleepHours < 5) {
      score += 0.08; // قليل
    } else if (sleepHours > 9) {
      score += 0.20; // كثير
    }

    // 3️⃣ استخدام الهاتف (25%)
    final phoneWellness = phoneData['wellness'] as double;
    score += phoneWellness * 0.25;

    return score.clamp(0.0, 1.0);
  }

  String _getHealthGrade(double score) {
    if (score >= 0.90) return 'ممتاز 🏆';
    if (score >= 0.80) return 'جيد جداً ⭐';
    if (score >= 0.70) return 'جيد ✅';
    if (score >= 0.60) return 'مقبول 👍';
    if (score >= 0.50) return 'يحتاج تحسين ⚠️';
    return 'ضعيف ❌';
  }

  // ================================
  // Duolingo Notifications - إشعارات Duolingo
  // ================================

  Future<void> _checkDuolingoNotifications(UnifiedHealthData data) async {
    try {
      // التحقق من آخر إشعار
      final lastNotif = data.lastNotificationSent;
      if (lastNotif != null) {
        final hoursSinceLastNotif = DateTime.now().difference(lastNotif).inHours;
        if (hoursSinceLastNotif < 12) {
          // لا نرسل إشعارات متكررة
          return;
        }
      }

      debugPrint('🔔 [Duolingo] فحص الإشعارات...');
      debugPrint('   Days away: ${data.daysSinceLastOpen}');
      debugPrint('   Streak: ${data.consecutiveDaysStreak}');

      // ✅ 1. إشعارات Duolingo حسب الأيام
      if (data.daysSinceLastOpen > 0) {
        await _notificationService.sendDuolingoReminder(
          daysAway: data.daysSinceLastOpen,
          currentStreak: data.consecutiveDaysStreak,
        );
      }

      // ✅ 2. دفعة نشاط إذا الخطوات منخفضة بعد الظهر
      final hour = DateTime.now().hour;
      if (hour >= 16 && data.todaySteps < 7000) {
        await _notificationService.sendActivityBoost(
          currentSteps: data.todaySteps,
          targetSteps: 10000,
        );
      }

      // ✅ 3. احتفال بالـ streak
      final milestoneDays = [3, 7, 14, 30, 60, 90, 100];
      if (milestoneDays.contains(data.consecutiveDaysStreak)) {
        await _notificationService.sendStreakCelebration(
          streakDays: data.consecutiveDaysStreak,
        );
      }

      // ✅ 4. رسالة تحفيزية سياقية
      if (data.isVeryHealthy) {
        await _notificationService.sendContextualMotivation(
          context: 'perfect_day',
          data: {
            'steps': data.todaySteps,
            'sleep_hours': data.todaySleepHours,
            'phone_hours': data.todayPhoneUsage.inHours,
          },
        );
      } else if (data.todaySteps < 3000 && hour >= 16) {
        await _notificationService.sendContextualMotivation(
          context: 'low_activity_warning',
          data: {'steps': data.todaySteps},
        );
      }

      debugPrint('✅ [Duolingo] تم فحص وإرسال الإشعارات');

    } catch (e) {
      debugPrint('❌ خطأ في فحص إشعارات Duolingo: $e');
    }
  }

  // ================================
  // Smart Insights - الرؤى الذكية
  // ================================

  Future<void> _generateSmartInsights(UnifiedHealthData data) async {
    try {
      debugPrint('💡 [Insights] توليد الرؤى الذكية...');

      // توليد رؤى يومية (الموجود مسبقاً)
      final date = _formatDate(DateTime.now());
      final dailyInsights = await _insightsService.generateDailyInsights(date);
      debugPrint('   💡 رؤى يومية: ${dailyInsights.length}');

      // ✅ 1. مقارنة مع الأمس
      if (state.last7Days.isNotEmpty) {
        final yesterday = state.last7Days.first;

        final todayMap = {
          'steps': data.todaySteps,
          'sleep_hours': data.todaySleepHours,
          'phone_minutes': data.todayPhoneUsage.inMinutes,
          'health_score': data.overallHealthScore,
        };

        final yesterdayMap = {
          'steps': yesterday.todaySteps,
          'sleep_hours': yesterday.todaySleepHours,
          'phone_minutes': yesterday.todayPhoneUsage.inMinutes,
          'health_score': yesterday.overallHealthScore,
        };

        final comparison = await _insightsService.generateComparisonInsight(
          todayMap,
          yesterdayMap,
        );

        if (comparison != null) {
          debugPrint('   📊 مقارنة: $comparison');
        }
      }

      // ✅ 2. كشف الاتجاهات الأسبوعية
      if (state.last7Days.length >= 3) {
        final weekData = state.last7Days.map((day) => {
          'steps': day.todaySteps,
          'sleep_hours': day.todaySleepHours,
          'phone_minutes': day.todayPhoneUsage.inMinutes,
          'health_score': day.overallHealthScore,
        }).toList();

        final trends = await _insightsService.detectTrends(weekData);

        if (trends != null) {
          debugPrint('   📈 اتجاهات: $trends');
        }
      }

      // ✅ 3. رؤية تحفيزية
      final todayMap = {
        'steps': data.todaySteps,
        'sleep_hours': data.todaySleepHours,
        'phone_minutes': data.todayPhoneUsage.inMinutes,
        'health_score': data.overallHealthScore,
      };

      final motivation = await _insightsService.generateMotivationalInsight(
        todayMap,
      );

      if (motivation != null) {
        debugPrint('   💪 تحفيز: $motivation');
      }

      // ✅ 4. تنبؤ بالأداء المستقبلي
      if (state.last7Days.length >= 5) {
        final historicalData = state.last7Days.map((day) => {
          'steps': day.todaySteps,
          'sleep_hours': day.todaySleepHours,
          'phone_minutes': day.todayPhoneUsage.inMinutes,
          'health_score': day.overallHealthScore,
        }).toList();

        final prediction = await _insightsService.predictFuturePerformance(
          historicalData,
        );

        if (prediction != null) {
          debugPrint('   🔮 تنبؤ: $prediction');
        }
      }

      debugPrint('✅ [Insights] تم توليد جميع الرؤى الذكية');

    } catch (e) {
      debugPrint('❌ خطأ في توليد الرؤى: $e');
    }
  }

  // ================================
  // Periodic Tasks - المهام الدورية
  // ================================

  void _startPeriodicSync() {
    _syncTimer?.cancel();

    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (!isDisposed && state.isAutoSyncEnabled) {
        debugPrint('⏰ [UnifiedHub] مزامنة دورية (5 دقائق)');
        await _performUnifiedSync();
      }
    });

    debugPrint('⏰ [UnifiedHub] تم بدء المزامنة الدورية (كل 5 دقائق)');
  }

  void _startDuolingoChecks() {
    _duolingoCheckTimer?.cancel();

    _duolingoCheckTimer = Timer.periodic(const Duration(hours: 1), (timer) async {
      if (!isDisposed && state.isAutoSyncEnabled) {
        debugPrint('⏰ [Duolingo] فحص دوري (ساعة واحدة)');
        await _checkDuolingoNotifications(state.currentData);
      }
    });

    debugPrint('⏰ [Duolingo] تم بدء الفحص الدوري (كل ساعة)');
  }

  void _startInsightsGeneration() {
    _insightsGenerationTimer?.cancel();

    _insightsGenerationTimer = Timer.periodic(const Duration(hours: 6), (timer) async {
      if (!isDisposed && state.isAutoSyncEnabled) {
        debugPrint('⏰ [Insights] توليد دوري (6 ساعات)');
        await _generateSmartInsights(state.currentData);
      }
    });

    debugPrint('⏰ [Insights] تم بدء التوليد الدوري (كل 6 ساعات)');
  }

  // ================================
  // App Usage Tracking - تتبع استخدام التطبيق
  // ================================

  Future<void> _updateLastAppOpen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      // حفظ وقت الفتح
      await prefs.setInt('last_app_open', now.millisecondsSinceEpoch);

      // تحديث الـ streak
      await _updateStreak(prefs, now);

      debugPrint('📲 [App Usage] تم تحديث وقت فتح التطبيق');

    } catch (e) {
      debugPrint('❌ خطأ في تحديث وقت فتح التطبيق: $e');
    }
  }

  Future<void> _updateStreak(SharedPreferences prefs, DateTime now) async {
    try {
      final lastOpen = prefs.getInt('last_app_open');
      if (lastOpen == null) {
        // أول مرة
        await prefs.setInt('consecutive_days_streak', 1);
        return;
      }

      final lastOpenDate = DateTime.fromMillisecondsSinceEpoch(lastOpen);
      final lastOpenDay = DateTime(lastOpenDate.year, lastOpenDate.month, lastOpenDate.day);
      final today = DateTime(now.year, now.month, now.day);

      final daysDiff = today.difference(lastOpenDay).inDays;

      if (daysDiff == 0) {
        // نفس اليوم، لا تغيير
        return;
      } else if (daysDiff == 1) {
        // اليوم التالي، زيادة الـ streak
        final currentStreak = prefs.getInt('consecutive_days_streak') ?? 0;
        await prefs.setInt('consecutive_days_streak', currentStreak + 1);
        debugPrint('🔥 [Streak] زيادة: ${currentStreak + 1} يوم');
      } else {
        // انقطاع، إعادة تعيين
        await prefs.setInt('consecutive_days_streak', 1);
        debugPrint('💔 [Streak] إعادة تعيين بعد $daysDiff يوم');
      }

    } catch (e) {
      debugPrint('❌ خطأ في تحديث الـ streak: $e');
    }
  }

  // ================================
  // Public Methods - الدوال العامة
  // ================================

  /// مزامنة يدوية فورية
  Future<void> forceSync() async {
    try {
      debugPrint('🔄 [UnifiedHub] مزامنة يدوية...');

      setState(state.copyWith(
        loadingState: LoadingState.loading,
        error: null,
      ));

      await _performUnifiedSync();

      setState(state.copyWith(
        loadingState: LoadingState.success,
        error: null,
        successMessage: 'تم تحديث جميع البيانات',
        lastUpdated: DateTime.now(),
      ));

    } catch (e, stack) {
      debugPrint('❌ [UnifiedHub] خطأ في المزامنة اليدوية: $e');

      setState(state.copyWith(
        loadingState: LoadingState.error,
        error: ServiceError(
          message: 'فشل في المزامنة: $e',
          originalError: e,
          stackTrace: stack,
        ),
      ));
    }
  }

  /// الحصول على البيانات الحالية
  UnifiedHealthData getCurrentData() => state.currentData;

  /// الحصول على ملخص صحي
  Map<String, dynamic> getHealthSummary() {
    final data = state.currentData;

    return {
      'overall_score': data.overallHealthScore,
      'health_grade': data.healthGrade,
      'is_healthy': data.isHealthy,
      'is_very_healthy': data.isVeryHealthy,
      'needs_attention': data.needsAttention,

      'sleep_hours': data.todaySleepHours,
      'sleep_status': data.sleepStatus,
      'sleep_quality': data.sleepQualityScore,

      'steps': data.todaySteps,
      'activity_status': data.activityStatus,
      'distance_km': data.todayDistance,
      'calories': data.caloriesBurned,

      'phone_usage_hours': data.todayPhoneUsage.inHours,
      'phone_usage_minutes': data.todayPhoneUsage.inMinutes,
      'phone_status': data.phoneUsageStatus,
      'phone_pickups': data.todayPhonePickups,

      'streak': data.consecutiveDaysStreak,
      'streak_emoji': data.streakEmoji,
      'days_away': data.daysSinceLastOpen,

      'last_updated': data.lastUpdated.toIso8601String(),
      'total_syncs': state.totalSyncs,
    };
  }

  /// الحصول على إحصائيات الأسبوع
  Map<String, dynamic> getWeeklySummary() {
    if (!state.hasHistoricalData) {
      return {
        'has_data': false,
        'message': 'لا توجد بيانات تاريخية كافية',
      };
    }

    final avgScore = state.averageHealthScore;
    final trend = state.isHealthImproving ? 'تحسن' : 'ثابت';

    final avgSteps = state.last7Days.fold<int>(
      0,
          (sum, d) => sum + d.todaySteps,
    ) ~/ state.last7Days.length;

    final avgSleep = state.last7Days.fold<double>(
      0,
          (sum, d) => sum + d.todaySleepHours,
    ) / state.last7Days.length;

    return {
      'has_data': true,
      'days_count': state.last7Days.length,
      'average_score': avgScore,
      'average_grade': _getHealthGrade(avgScore),
      'trend': trend,
      'is_improving': state.isHealthImproving,
      'average_steps': avgSteps,
      'average_sleep_hours': avgSleep,
    };
  }

  /// تفعيل/إلغاء المزامنة التلقائية
  Future<void> toggleAutoSync(bool enabled) async {
    setState(state.copyWith(isAutoSyncEnabled: enabled));

    if (enabled) {
      _startPeriodicSync();
      _startDuolingoChecks();
      _startInsightsGeneration();
      debugPrint('✅ [UnifiedHub] تم تفعيل المزامنة التلقائية');
    } else {
      _syncTimer?.cancel();
      _duolingoCheckTimer?.cancel();
      _insightsGenerationTimer?.cancel();
      debugPrint('⏸️ [UnifiedHub] تم إيقاف المزامنة التلقائية');
    }
  }

  // ================================
  // Helper Methods - دوال مساعدة
  // ================================

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    debugPrint('🗑️ [UnifiedHub] تنظيف المركز الصحي الموحد');
    _syncTimer?.cancel();
    _duolingoCheckTimer?.cancel();
    _insightsGenerationTimer?.cancel();
    super.dispose();
  }
}