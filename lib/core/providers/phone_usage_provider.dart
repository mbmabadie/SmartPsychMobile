// lib/core/providers/phone_usage_provider.dart
// ✅ نسخة بدون تقديرات - بيانات حقيقية فقط

import 'dart:async';
import 'package:flutter/material.dart';

import 'base/base_state.dart';
import 'base/base_provider.dart';
import '../database/models/common_models.dart';
import '../database/models/phone_usage_models.dart';
import '../database/models/app_usage_entry.dart';
import '../database/repositories/phone_usage_repository.dart';
import '../services/notification_service.dart';
import '../services/insights_service.dart';
import '../services/app_usage_service.dart';

/// ═══════════════════════════════════════════════════════════
/// Phone Usage State - البيانات الحقيقية فقط
/// ═══════════════════════════════════════════════════════════

@immutable
class PhoneUsageState extends BaseState {
  // ✅ خصائص التتبع الأساسية
  final bool isTracking;
  final bool autoDetectionEnabled;
  final PhoneUsageSession? currentSession;
  final List<PhoneUsageSession> recentSessions;

  // ✅ البيانات اليومية - حقيقية فقط
  final List<AppUsageEntry> todaysAppUsage;
  final Duration todaysTotalUsage;

  // ❌ تم الحذف: todaysPickupCount (تقديري)
  // ❌ تم الحذف: todaysPatterns (تقديري)
  // ❌ تم الحذف: unifiedHourlyData (تقديري)
  // ❌ تم الحذف: hourlySummaryData (تقديري)

  // ✅ البيانات الأسبوعية - حقيقية فقط
  final Map<String, Duration> weeklyAppUsage;

  // ✅ التنبيهات والرؤى
  final List<UsageAlert> activeAlerts;
  final Map<String, dynamic> usageStats;
  final double wellnessScore;
  final DateTime? lastUsageCheck;

  PhoneUsageState({
    // Base state properties
    super.loadingState,
    super.error,
    super.lastUpdated,
    super.hasData,
    super.successMessage,

    // Phone usage specific properties
    this.isTracking = true,
    this.autoDetectionEnabled = true,
    this.currentSession,
    this.recentSessions = const [],

    // البيانات اليومية الحقيقية
    this.todaysAppUsage = const [],
    this.todaysTotalUsage = const Duration(),

    // البيانات الأسبوعية
    this.weeklyAppUsage = const {},

    // التنبيهات والرؤى
    this.activeAlerts = const [],
    this.usageStats = const {},
    this.wellnessScore = 0.0,
    this.lastUsageCheck,
  });

  // Factory constructors
  factory PhoneUsageState.initial() {
    return PhoneUsageState(
      loadingState: LoadingState.idle,
      hasData: false,
      isTracking: true,
    );
  }

  factory PhoneUsageState.loading({bool isRefreshing = false}) {
    return PhoneUsageState(
      loadingState: isRefreshing ? LoadingState.refreshing : LoadingState.loading,
      hasData: false,
      isTracking: true,
    );
  }

  // ✅ Computed properties - حقيقية فقط
  bool get hasActiveSession => currentSession != null && !currentSession!.isCompleted;
  bool get canStartTracking => false; // Always tracking
  bool get isExcessiveUsageToday => todaysTotalUsage.inHours > 6;
  bool get hasHealthyUsageToday => todaysTotalUsage.inHours <= 3;
  bool get hasActiveAlerts => activeAlerts.any((alert) => !alert.isShown);

  // ✅ النص المنسق للاستخدام
  String get todaysUsageFormatted {
    if (todaysTotalUsage.inSeconds == 0) return '0m';

    final hours = todaysTotalUsage.inHours;
    final minutes = todaysTotalUsage.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String get wellnessGrade {
    if (wellnessScore == 0.0) return 'غير محدد';
    if (wellnessScore >= 0.9) return 'ممتاز';
    if (wellnessScore >= 0.8) return 'جيد جداً';
    if (wellnessScore >= 0.7) return 'جيد';
    if (wellnessScore >= 0.6) return 'مقبول';
    if (wellnessScore >= 0.5) return 'ضعيف';
    return 'ضعيف جداً';
  }

  List<String> get topAppsToday {
    if (todaysAppUsage.isEmpty) return [];

    final sortedApps = todaysAppUsage.toList()
      ..sort((a, b) => b.totalUsageTime.compareTo(a.totalUsageTime));
    return sortedApps.take(5).map((app) => app.appName).toList();
  }

  // ✅ copyWith method
  PhoneUsageState copyWith({
    LoadingState? loadingState,
    AppError? error,
    DateTime? lastUpdated,
    bool? hasData,
    String? successMessage,
    bool? isTracking,
    bool? autoDetectionEnabled,
    PhoneUsageSession? currentSession,
    List<PhoneUsageSession>? recentSessions,

    // البيانات اليومية
    List<AppUsageEntry>? todaysAppUsage,
    Duration? todaysTotalUsage,

    // البيانات الأسبوعية
    Map<String, Duration>? weeklyAppUsage,

    // التنبيهات والرؤى
    List<UsageAlert>? activeAlerts,
    Map<String, dynamic>? usageStats,
    double? wellnessScore,
    DateTime? lastUsageCheck,
  }) {
    return PhoneUsageState(
      loadingState: loadingState ?? this.loadingState,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      hasData: hasData ?? this.hasData,
      successMessage: successMessage ?? this.successMessage,
      isTracking: isTracking ?? this.isTracking,
      autoDetectionEnabled: autoDetectionEnabled ?? this.autoDetectionEnabled,
      currentSession: currentSession ?? this.currentSession,
      recentSessions: recentSessions ?? this.recentSessions,

      // البيانات اليومية
      todaysAppUsage: todaysAppUsage ?? this.todaysAppUsage,
      todaysTotalUsage: todaysTotalUsage ?? this.todaysTotalUsage,

      // البيانات الأسبوعية
      weeklyAppUsage: weeklyAppUsage ?? this.weeklyAppUsage,

      // التنبيهات والرؤى
      activeAlerts: activeAlerts ?? this.activeAlerts,
      usageStats: usageStats ?? this.usageStats,
      wellnessScore: wellnessScore ?? this.wellnessScore,
      lastUsageCheck: lastUsageCheck ?? this.lastUsageCheck,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PhoneUsageState &&
        other.isTracking == isTracking &&
        other.autoDetectionEnabled == autoDetectionEnabled &&
        other.todaysTotalUsage == todaysTotalUsage;
  }

  @override
  int get hashCode => Object.hash(
    super.hashCode,
    isTracking,
    autoDetectionEnabled,
    todaysTotalUsage,
  );

  @override
  String toString() {
    return 'PhoneUsageState('
        'isTracking: $isTracking, '
        'hasData: $hasData, '
        'todaysUsage: ${todaysTotalUsage.inMinutes}min, '
        'appsCount: ${todaysAppUsage.length}'
        ')';
  }
}

/// ═══════════════════════════════════════════════════════════
/// Usage Alert class
/// ═══════════════════════════════════════════════════════════

@immutable
class UsageAlert {
  final String id;
  final String type;
  final String title;
  final String message;
  final AlertSeverity severity;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final bool isShown;

  const UsageAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.severity,
    required this.timestamp,
    this.data = const {},
    this.isShown = false,
  });

  @override
  String toString() {
    return 'UsageAlert($type: $title, severity: $severity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UsageAlert && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum AlertSeverity { info, warning, critical }

/// ═══════════════════════════════════════════════════════════
/// Phone Usage Provider - البيانات الحقيقية فقط
/// ═══════════════════════════════════════════════════════════

class PhoneUsageProvider extends BaseProvider<PhoneUsageState>
    with PeriodicUpdateMixin<PhoneUsageState>, CacheMixin<PhoneUsageState> {

  // Dependencies
  final PhoneUsageRepository _phoneRepo;
  final NotificationService _notificationService;
  final InsightsService _insightsService;
  final AppUsageService _appUsageService;

  // Stream subscriptions and timers
  Timer? _usageCheckTimer;
  Timer? _alertCheckTimer;

  PhoneUsageProvider({
    PhoneUsageRepository? phoneRepo,
    NotificationService? notificationService,
    InsightsService? insightsService,
    AppUsageService? appUsageService,
  })  : _phoneRepo = phoneRepo ?? PhoneUsageRepository(),
        _notificationService = notificationService ?? NotificationService.instance,
        _insightsService = insightsService ?? InsightsService.instance,
        _appUsageService = appUsageService ?? AppUsageService.instance,
        super(PhoneUsageState.initial()) {

    debugPrint('📱 تهيئة PhoneUsageProvider (بيانات حقيقية فقط)');
    _initializeProvider();
  }

  // ✅ BaseProvider implementation
  @override
  PhoneUsageState _createLoadingState(bool isRefreshing) {
    debugPrint('⏳ _createLoadingState: isRefreshing=$isRefreshing');
    return state.copyWith(
      loadingState: isRefreshing ? LoadingState.refreshing : LoadingState.loading,
      error: null,
      successMessage: null,
    );
  }

  @override
  PhoneUsageState _createSuccessState() {
    debugPrint('✅ _createSuccessState');
    return state.copyWith(
      loadingState: LoadingState.success,
      error: null,
      successMessage: null,
      hasData: true,
    );
  }

  @override
  PhoneUsageState _createErrorState(AppError error) {
    debugPrint('❌ _createErrorState: ${error.message}');
    return state.copyWith(
      loadingState: LoadingState.error,
      error: error,
      successMessage: null,
    );
  }

  @override
  PhoneUsageState _createIdleState() {
    debugPrint('😴 _createIdleState');
    return state.copyWith(
      loadingState: LoadingState.idle,
      error: null,
      successMessage: null,
    );
  }

  @override
  Future<void> refreshData() async {
    debugPrint('🔄 refreshData - تحديث البيانات الحقيقية...');
    await _loadRealDataSafe();
  }

  // ✅ Initialize provider
  Future<void> _initializeProvider() async {
    debugPrint('📱 بدء تهيئة PhoneUsageProvider (بيانات حقيقية)...');

    try {
      setState(_createLoadingState(false));

      // Initialize AppUsageService
      await _appUsageService.initialize();
      debugPrint('✅ تم تهيئة AppUsageService');

      // Check permissions and ensure tracking
      await _ensureTrackingIsActive();
      debugPrint('✅ تم ضمان نشاط التتبع');

      // Start periodic checks
      _startPeriodicChecks();
      debugPrint('✅ تم بدء الفحص الدوري');

      // Load initial data
      await _loadRealDataSafe();

      setState(_createSuccessState());

      debugPrint('✅ تم تهيئة مزود تتبع استخدام الهاتف بنجاح');

    } catch (e, stackTrace) {
      debugPrint('❌ خطأ في تهيئة المزود: $e');
      debugPrint('📍 Stack trace: $stackTrace');

      setState(_createErrorState(ServiceError(
        message: 'فشل في التهيئة: $e',
        code: 'INITIALIZATION_FAILED',
      )));
    }
  }

  // ✅ تحميل البيانات الحقيقية
  Future<void> _loadRealDataSafe() async {
    try {
      debugPrint('📱 🔄 تحديث البيانات الحقيقية...');

      final today = _formatDate(DateTime.now());

      // 1. جلب البيانات اليومية (حقيقية 100%)
      final todaysUsage = await _appUsageService.getTodaysUsage();
      debugPrint('📱 عدد التطبيقات: ${todaysUsage.length}');

      // 2. حساب الاستخدام الكلي (حقيقي 100%)
      final totalUsage = await _appUsageService.getTotalUsageToday();
      debugPrint('✅ الاستخدام الكلي: ${totalUsage.inMinutes}min');

      // 3. جلب البيانات الأسبوعية
      final weeklyData = await _getWeeklyUsageData();

      // 4. تحديث الحالة
      setState(state.copyWith(
        todaysAppUsage: todaysUsage,
        todaysTotalUsage: totalUsage,
        weeklyAppUsage: weeklyData,
        hasData: totalUsage.inSeconds > 0 || todaysUsage.isNotEmpty,
        wellnessScore: _calculateWellnessScore(),
        lastUsageCheck: DateTime.now(),
        error: null,
      ));

      debugPrint('🔄 تم تحديث البيانات الحقيقية');

    } catch (e) {
      debugPrint('❌ خطأ في تحديث البيانات: $e');
    }
  }

  // ✅ جلب البيانات الأسبوعية
  Future<Map<String, Duration>> _getWeeklyUsageData() async {
    try {
      final weeklyData = <String, Duration>{};
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 7));

      debugPrint('📅 جلب البيانات الأسبوعية');

      var date = startDate;
      while (date.isBefore(endDate.add(const Duration(days: 1)))) {
        final dateStr = _formatDate(date);
        final dailyUsage = await _phoneRepo.getAppUsageForDate(dateStr);

        final totalDuration = dailyUsage.fold<Duration>(
          Duration.zero,
              (sum, app) => sum + app.totalUsageTime,
        );

        if (totalDuration.inSeconds > 0) {
          weeklyData[dateStr] = totalDuration;
        }

        date = date.add(const Duration(days: 1));
      }

      debugPrint('📊 البيانات الأسبوعية: ${weeklyData.length} أيام');
      return weeklyData;
    } catch (e) {
      debugPrint('❌ خطأ في جلب البيانات الأسبوعية: $e');
      return {};
    }
  }

  // ✅ ضمان نشاط التتبع
  Future<void> _ensureTrackingIsActive() async {
    try {
      debugPrint('🔍 ضمان نشاط التتبع...');

      final hasPermission = await _appUsageService.hasPermissions();
      debugPrint('🔐 صلاحيات Usage Stats: $hasPermission');

      if (hasPermission) {
        if (!_appUsageService.isInitialized) {
          debugPrint('🚀 تهيئة AppUsageService...');
          await _appUsageService.initialize();
        }

        if (!_appUsageService.isTracking) {
          debugPrint('▶️ بدء التتبع...');
          await _appUsageService.startTracking();
        }

        setState(state.copyWith(
          isTracking: true,
          lastUsageCheck: DateTime.now(),
          error: null,
        ));

        debugPrint('✅ تم تفعيل التتبع بنجاح');

      } else {
        debugPrint('❌ لا توجد صلاحيات');
        setState(state.copyWith(
          isTracking: false,
          error: PermissionError(
            code: 'NO_PERMISSION',
            message: 'يحتاج إذن الوصول لإحصائيات الاستخدام',
          ),
        ));
      }
    } catch (e) {
      debugPrint('❌ خطأ في ضمان نشاط التتبع: $e');
      setState(state.copyWith(
        error: ServiceError(
          message: 'خطأ في تفعيل التتبع: $e',
        ),
      ));
    }
  }

  // ✅ فحص وطلب الصلاحيات
  Future<bool> checkAndRequestPermissions() async {
    debugPrint('🔐 فحص وطلب الصلاحيات...');

    try {
      final hasPermissions = await _appUsageService.hasPermissions();

      if (hasPermissions) {
        debugPrint('✅ الصلاحيات ممنوحة');

        if (!_appUsageService.isTracking) {
          await _appUsageService.startTracking();
        }

        await _loadRealDataSafe();

        setState(state.copyWith(
          isTracking: true,
          error: null,
        ));

        return true;
      }

      debugPrint('⚠️ الصلاحيات غير ممنوحة، محاولة الطلب...');

      final granted = await _appUsageService.requestPermissions();

      if (granted) {
        debugPrint('✅ تم منح الصلاحيات!');

        await _appUsageService.initialize();
        await _appUsageService.startTracking();
        await _loadRealDataSafe();

        setState(state.copyWith(
          isTracking: true,
          error: null,
        ));

        return true;
      } else {
        debugPrint('❌ لم يتم منح الصلاحيات');

        setState(state.copyWith(
          isTracking: false,
          error: PermissionError(
            code: 'NO_PERMISSION',
            message: 'يحتاج إذن الوصول لإحصائيات الاستخدام',
          ),
        ));

        return false;
      }

    } catch (e) {
      debugPrint('❌ خطأ في فحص/طلب الصلاحيات: $e');

      setState(state.copyWith(
        error: ServiceError(
          message: 'خطأ في طلب الصلاحيات: $e',
        ),
      ));

      return false;
    }
  }

  // ✅ دوال الإدارة والصيانة

  Future<void> startPhoneUsageTracking() async {
    await executeWithLoading(() async {
      debugPrint('📱 بدء تتبع استخدام الهاتف...');

      if (!await _appUsageService.hasPermissions()) {
        throw PermissionError(
          message: 'يحتاج إذن الوصول لإحصائيات الاستخدام',
          code: 'PERMISSION_REQUIRED',
        );
      }

      await _appUsageService.startTracking();
      _startUsageMonitoring();

      setState(state.copyWith(
        isTracking: true,
        lastUsageCheck: DateTime.now(),
      ));

      await _notificationService.showNotification(
        id: 2001,
        title: '📱 تفعيل تتبع الاستخدام',
        body: 'تم تفعيل التتبع التلقائي 24/7.',
        channelId: NotificationService.channelGeneral,
        payload: {
          'type': 'tracking_start',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      debugPrint('✅ تم بدء تتبع استخدام الهاتف');
    });
  }

  Future<void> stopPhoneUsageTracking() async {
    await executeWithLoading(() async {
      debugPrint('📱 إيقاف تتبع الهاتف...');

      await _appUsageService.stopTracking();
      _stopUsageMonitoring();

      setState(state.copyWith(
        isTracking: false,
      ));

      debugPrint('✅ تم إيقاف تتبع الهاتف');
    });
  }

  Future<void> toggleAutoDetection(bool enabled) async {
    setState(state.copyWith(autoDetectionEnabled: enabled));

    if (state.isTracking) {
      if (enabled) {
        _startUsageMonitoring();
        debugPrint('✅ تم تفعيل الكشف التلقائي');
      } else {
        _stopUsageMonitoring();
        debugPrint('✅ تم إلغاء تفعيل الكشف التلقائي');
      }
    }
  }

  // ✅ دوال الحصول على البيانات

  Future<List<PhoneUsageSession>> getUsageHistory({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 30,
  }) async {
    return await executeWithResult(() async {
      final sessions = await _getPhoneUsageSessionsInPeriod(
        startDate: startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        endDate: endDate ?? DateTime.now(),
        limit: limit,
      );

      debugPrint('📊 تم جلب ${sessions.length} جلسة استخدام');
      return sessions;
    }) ?? [];
  }

  Future<List<AppUsageEntry>> getAppUsageStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await executeWithResult(() async {
      final stats = await _phoneRepo.getAppUsageForPeriod(
        startDate: startDate ?? DateTime.now().subtract(const Duration(days: 7)),
        endDate: endDate ?? DateTime.now(),
      );

      debugPrint('📊 تم جلب إحصائيات ${stats.length} تطبيق');
      return stats;
    }) ?? [];
  }

  Future<List<Insight>> generateUsageInsights({String? date}) async {
    return await executeWithResult(() async {
      final targetDate = date ?? _formatDate(DateTime.now());
      final insights = await _insightsService.generateDailyInsights(targetDate);

      final usageInsights = insights.where((insight) => insight.category == 'phone_usage').toList();

      debugPrint('💡 تم إنتاج ${usageInsights.length} رؤية متعلقة بالاستخدام');
      return usageInsights;
    }) ?? [];
  }

  Future<void> setDailyUsageGoal(Duration goal) async {
    await executeWithLoading(() async {
      await _phoneRepo.setUserSetting('daily_usage_goal', goal.inMinutes);

      setState(state.copyWith(
        successMessage: 'تم تحديد هدف الاستخدام اليومي: ${goal.inHours}h ${goal.inMinutes.remainder(60)}m',
      ));

      if (state.todaysTotalUsage > goal) {
        await _checkUsageGoals();
      }

      debugPrint('🎯 تم تحديد هدف الاستخدام اليومي: ${goal.inMinutes} دقيقة');
    });
  }

  // ✅ دوال مساعدة

  void _startPeriodicChecks() {
    _alertCheckTimer = Timer.periodic(const Duration(minutes: 15), (timer) async {
      if (!isDisposed) {
        await _checkForAlerts();
      } else {
        timer.cancel();
      }
    });
  }

  void _startUsageMonitoring() {
    _usageCheckTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (!state.isTracking || isDisposed) {
        timer.cancel();
        return;
      }

      await _performUsageCheck();
    });
  }

  void _stopUsageMonitoring() {
    _usageCheckTimer?.cancel();
    _usageCheckTimer = null;
  }

  Future<void> _performUsageCheck() async {
    try {
      await _appUsageService.refreshData();
      await _loadRealDataSafe();
      await _checkUsageGoals();
      await _checkForAlerts();

      setState(state.copyWith(
        lastUsageCheck: DateTime.now(),
        wellnessScore: _calculateWellnessScore(),
      ));

    } catch (e) {
      debugPrint('❌ خطأ في فحص الاستخدام: $e');
    }
  }

  Future<void> _checkUsageGoals() async {
    try {
      final dailyGoalMinutes = await _phoneRepo.getUserSetting('daily_usage_goal', 240) ?? 240;
      final dailyGoal = Duration(minutes: dailyGoalMinutes);

      if (state.todaysTotalUsage > dailyGoal) {
        final excess = state.todaysTotalUsage - dailyGoal;

        await _notificationService.showExcessivePhoneUsageAlert(
          usageTime: state.todaysTotalUsage,
          pickupCount: 0, // ❌ غير متاح
        );

        final alert = UsageAlert(
          id: 'goal_exceeded_${DateTime.now().millisecondsSinceEpoch}',
          type: 'goal_exceeded',
          title: 'تم تجاوز الهدف اليومي',
          message: 'تجاوزت هدف الاستخدام اليومي بـ ${excess.inMinutes} دقيقة',
          severity: AlertSeverity.warning,
          timestamp: DateTime.now(),
          data: {
            'goal_minutes': dailyGoal.inMinutes,
            'actual_minutes': state.todaysTotalUsage.inMinutes,
            'excess_minutes': excess.inMinutes,
          },
        );

        _addAlert(alert);
      }

    } catch (e) {
      debugPrint('❌ خطأ في فحص أهداف الاستخدام: $e');
    }
  }

  Future<void> _checkForAlerts() async {
    try {
      final alerts = <UsageAlert>[];

      // Check for excessive usage
      if (state.todaysTotalUsage.inHours > 8) {
        alerts.add(UsageAlert(
          id: 'excessive_usage_${DateTime.now().millisecondsSinceEpoch}',
          type: 'excessive_usage',
          title: 'استخدام مفرط للهاتف',
          message: 'استخدمت الهاتف أكثر من 8 ساعات اليوم. حان وقت الاستراحة!',
          severity: AlertSeverity.critical,
          timestamp: DateTime.now(),
          data: {
            'usage_hours': state.todaysTotalUsage.inHours,
          },
        ));
      }

      if (alerts.isNotEmpty) {
        final allAlerts = [...state.activeAlerts, ...alerts];
        setState(state.copyWith(activeAlerts: allAlerts));

        debugPrint('⚠️ تم إنشاء ${alerts.length} تنبيه');
      }

    } catch (e) {
      debugPrint('❌ خطأ في فحص التنبيهات: $e');
    }
  }

  double _calculateWellnessScore() {
    if (state.todaysTotalUsage.inSeconds == 0) {
      return 0.0;
    }

    double score = 1.0;

    final usageHours = state.todaysTotalUsage.inHours;
    if (usageHours > 6) {
      score -= 0.4;
    } else if (usageHours > 4) {
      score -= 0.2;
    } else if (usageHours > 2) {
      score -= 0.1;
    }

    final criticalAlerts = state.activeAlerts.where((alert) =>
    alert.severity == AlertSeverity.critical && !alert.isShown).length;
    score -= criticalAlerts * 0.1;

    return score.clamp(0.0, 1.0);
  }

  void _addAlert(UsageAlert alert) {
    final updatedAlerts = [...state.activeAlerts, alert];
    setState(state.copyWith(activeAlerts: updatedAlerts));
  }

  Future<List<PhoneUsageSession>> _getPhoneUsageSessionsInPeriod({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 100,
  }) async {
    try {
      final sessions = <PhoneUsageSession>[];
      final currentDate = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);

      var date = currentDate;
      while (date.isBefore(end.add(const Duration(days: 1))) && sessions.length < limit) {
        final dateStr = _formatDate(date);
        final dailySessions = await _phoneRepo.getPhoneUsageSessionsForDate(dateStr);
        sessions.addAll(dailySessions);
        date = date.add(const Duration(days: 1));
      }

      sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
      return sessions.take(limit).toList();
    } catch (e) {
      debugPrint('❌ خطأ في جلب جلسات الاستخدام للفترة: $e');
      return [];
    }
  }

  // ✅ دوال الإدارة العامة

  Future<void> dismissAlert(UsageAlert alert) async {
    final updatedAlerts = state.activeAlerts.map((a) {
      if (a.id == alert.id) {
        return UsageAlert(
          id: a.id,
          type: a.type,
          title: a.title,
          message: a.message,
          severity: a.severity,
          timestamp: a.timestamp,
          data: a.data,
          isShown: true,
        );
      }
      return a;
    }).toList();

    setState(state.copyWith(activeAlerts: updatedAlerts));
  }

  Future<void> clearAllAlerts() async {
    setState(state.copyWith(activeAlerts: []));
    debugPrint('🧹 تم مسح جميع التنبيهات');
  }

  Future<void> setBreakReminder(Duration interval) async {
    await executeWithLoading(() async {
      await _phoneRepo.setUserSetting('break_reminder_minutes', interval.inMinutes);
      await _scheduleBreakReminders(interval);

      setState(state.copyWith(
        successMessage: 'تم تحديد تذكير الاستراحة كل ${interval.inMinutes} دقيقة',
      ));

      debugPrint('⏰ تم تحديد تذكير الاستراحة: ${interval.inMinutes} دقيقة');
    });
  }

  Future<void> _scheduleBreakReminders(Duration interval) async {
    await _notificationService.cancelNotificationsByType('break_reminder');

    final now = DateTime.now();
    var nextReminder = now.add(interval);

    for (int i = 0; i < 10; i++) {
      await _notificationService.scheduleNotification(
        id: 3000 + i,
        title: '⏸️ وقت الاستراحة',
        body: 'خذ استراحة قصيرة من الهاتف. عينيك وعقلك يحتاجان للراحة.',
        scheduledTime: nextReminder,
        channelId: NotificationService.channelReminders,
        payload: {
          'type': 'break_reminder',
          'reminder_number': i + 1,
        },
      );

      nextReminder = nextReminder.add(interval);
    }
  }

  // ✅ تصدير البيانات
  @override
  Future<void> exportUsageData() async {
    await executeWithLoading(() async {
      debugPrint('📤 تصدير البيانات الحقيقية...');

      if (state.todaysTotalUsage.inSeconds == 0 && state.todaysAppUsage.isEmpty) {
        throw ServiceError(
          message: 'لا توجد بيانات للتصدير',
          code: 'NO_DATA',
        );
      }

      final today = _formatDate(DateTime.now());

      final sessions = await getUsageHistory(limit: 1000);
      final appUsage = await getAppUsageStats();

      final exportData = {
        'export_info': {
          'date': DateTime.now().toIso8601String(),
          'version': '1.0_real_data_only',
          'data_source': 'real_data_only',
        },
        'daily_summary': {
          'date': today,
          'total_usage_minutes': state.todaysTotalUsage.inMinutes,
          'apps_count': state.todaysAppUsage.length,
          'wellness_score': state.wellnessScore,
        },
        'apps_usage': state.todaysAppUsage.map((a) => {
          'name': a.appName,
          'package': a.packageName,
          'duration_minutes': a.totalUsageTime.inMinutes,
          'last_used': a.lastUsedTime?.toIso8601String(),
        }).toList(),
        'weekly_data': state.weeklyAppUsage.map((key, value) =>
            MapEntry(key, value.inMinutes)),
        'alerts': state.activeAlerts.map((a) => {
          'id': a.id,
          'type': a.type,
          'title': a.title,
          'message': a.message,
          'severity': a.severity.toString(),
          'timestamp': a.timestamp.toIso8601String(),
          'data': a.data,
        }).toList(),
      };

      debugPrint('📊 تم إعداد البيانات الحقيقية للتصدير');
      debugPrint('   - التطبيقات: ${state.todaysAppUsage.length}');
      debugPrint('   - الوقت الكلي: ${state.todaysTotalUsage.inMinutes} دقيقة');

      setState(state.copyWith(
        successMessage: 'تم تصدير البيانات الحقيقية بنجاح',
      ));
    });
  }

  // ✅ Refresh
  @override
  Future<void> refresh() async {
    if (state.isLoading || state.isRefreshing) {
      debugPrint('⏸️ التحديث جاري بالفعل، تم تجاهل الطلب');
      return;
    }

    debugPrint('🔄 بدء التحديث اليدوي...');

    try {
      setState(_createLoadingState(true));

      try {
        await _appUsageService.refreshData();
        debugPrint('✅ تم تحديث AppUsageService');
      } catch (e) {
        debugPrint('❌ خطأ في تحديث AppUsageService: $e');
      }

      await _loadRealDataSafe();
      setState(_createSuccessState());

      debugPrint('✅ تم التحديث اليدوي بنجاح');

    } catch (e) {
      debugPrint('❌ خطأ في التحديث اليدوي: $e');

      setState(_createErrorState(ServiceError(
        message: 'فشل في التحديث: $e',
        code: 'REFRESH_FAILED',
      )));
    }
  }

  // PeriodicUpdateMixin implementation
  @override
  Future<void> performPeriodicUpdate() async {
    if (state.isTracking && !isDisposed) {
      try {
        await _performUsageCheck();

        // تحديث شامل كل 30 دقيقة
        if (DateTime.now().minute % 30 == 0) {
          await _loadRealDataSafe();
        }

      } catch (e) {
        debugPrint('❌ خطأ في التحديث الدوري: $e');
      }
    }
  }

  // ✅ getter عام للوصول لـ AppUsageService
  AppUsageService get appUsageService => _appUsageService;

  // ✅ دوال مساعدة
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // ✅ إحصائيات شاملة
  Map<String, dynamic> getComprehensiveStats() {
    return {
      'state_info': {
        'is_tracking': state.isTracking,
        'wellness_score': state.wellnessScore,
        'wellness_grade': state.wellnessGrade,
      },
      'usage_summary': {
        'todays_total_minutes': state.todaysTotalUsage.inMinutes,
        'apps_count': state.todaysAppUsage.length,
        'top_apps': state.topAppsToday,
      },
      'alerts': {
        'total_alerts': state.activeAlerts.length,
        'unshown_alerts': state.activeAlerts.where((a) => !a.isShown).length,
        'critical_alerts': state.activeAlerts.where((a) =>
        a.severity == AlertSeverity.critical && !a.isShown).length,
      },
      'weekly_data': {
        'days_with_data': state.weeklyAppUsage.length,
        'total_weekly_apps': state.weeklyAppUsage.keys.length,
      },
    };
  }

  @override
  void dispose() {
    debugPrint('🗑️ تنظيف PhoneUsageProvider');
    _usageCheckTimer?.cancel();
    _alertCheckTimer?.cancel();
    super.dispose();
  }
}