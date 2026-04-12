// lib/core/providers/activity_tracking_provider.dart - ✅ النسخة المعدلة الكاملة

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/models/goal_type.dart';
import '../services/background_service.dart';
import '../services/insights_service.dart';
import '../services/unified_tracking_service.dart';
import '../services/user_settings_service.dart'; // ← جديد
import 'activity_tracking_state.dart';
import 'base/base_provider.dart';
import '../database/models/activity_models.dart';
import '../database/repositories/activity_repository.dart';
import '../services/notification_service.dart';
import '../services/health_service.dart';
import 'base/base_state.dart';

class ActivityTrackingError extends AppError {
  final String type;

  ActivityTrackingError({
    required String message,
    String? code,
    required this.type,
    super.originalError,
    super.stackTrace,
  }) : super(
    message: message,
    code: code ?? 'ACTIVITY_ERROR',
  );
}

class ActivityTrackingProvider extends BaseProvider<ActivityTrackingState>
    with PeriodicUpdateMixin<ActivityTrackingState> {

  final ActivityRepository _activityRepo;
  final UnifiedTrackingService _unifiedService;
  final BackgroundService _backgroundService;
  final NotificationService _notificationService;
  final InsightsService _insightsService;
  final HealthService _healthService;
  final UserSettingsService _userSettings; // ← جديد

  StreamSubscription<StepCount>? _pedometerSubscription;
  StreamSubscription<Map<String, dynamic>>? _unifiedServiceSubscription; // ✅ جديد للاستماع لـ UnifiedService
  int _systemSteps = 0;
  int _baselineSteps = 0;
  int _currentSteps = 0;
  double _currentDistance = 0.0;
  double _currentCalories = 0.0;
  String _currentDate = '';

  Timer? _goalsCheckTimer;
  Timer? _insightsTimer;
  Timer? _saveTimer;

  ActivityTrackingProvider({
    ActivityRepository? activityRepo,
    BackgroundService? backgroundService,
    NotificationService? notificationService,
    InsightsService? insightsService,
    HealthService? healthService,
    UserSettingsService? userSettings, // ← جديد
  })
      : _activityRepo = activityRepo ?? ActivityRepository(),
        _unifiedService = UnifiedTrackingService.instance,
        _backgroundService = backgroundService ?? BackgroundService.instance,
        _notificationService = notificationService ?? NotificationService.instance,
        _insightsService = insightsService ?? InsightsService.instance,
        _healthService = healthService ?? HealthService.instance,
        _userSettings = userSettings ?? UserSettingsService.instance, // ← جديد
        super(ActivityTrackingState.initial()) {

    debugPrint('🔧 تهيئة ActivityTrackingProvider');
    _initializeProviderImmediate();
  }

  @override
  ActivityTrackingState _createLoadingState(bool isRefreshing) {
    return state.copyWith(
      loadingState: isRefreshing ? LoadingState.refreshing : LoadingState.loading,
      error: null,
      successMessage: null,
    );
  }

  @override
  ActivityTrackingState _createSuccessState() {
    return state.copyWith(
      loadingState: LoadingState.success,
      error: null,
      hasData: true,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  ActivityTrackingState _createErrorState(AppError error) {
    return state.copyWith(
      loadingState: LoadingState.error,
      error: error,
      successMessage: null,
    );
  }

  @override
  ActivityTrackingState _createIdleState() {
    return state.copyWith(
      loadingState: LoadingState.idle,
      error: null,
      successMessage: null,
    );
  }

  @override
  Future<void> refreshData() async {
    debugPrint('🔄 تحديث البيانات...');
    await _loadInitialDatabaseData();
    await _generateTodayInsights();
    await refreshGoals(); // ← جديد
  }

  @override
  Future<void> performPeriodicUpdate() async {
    await _syncWithBackgroundService();
    await _refreshTodayActivity();
  }

  Future<void> _syncWithBackgroundService() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final bgSteps = prefs.getInt('bg_last_steps') ?? 0;
      final bgStepsTime = prefs.getInt('bg_last_steps_time') ?? 0;

      if (bgSteps > 0) {
        final updateTime = DateTime.fromMillisecondsSinceEpoch(bgStepsTime);
        final timeSince = DateTime.now().difference(updateTime);

        if (timeSince.inMinutes < 1) {
          debugPrint('🔄 مزامنة مع BackgroundService: $bgSteps خطوة');
        }
      }

    } catch (e) {
      debugPrint('❌ خطأ في المزامنة مع BackgroundService: $e');
    }
  }

  Future<void> _refreshTodayActivity() async {
    try {
      debugPrint('🔄 تحديث نشاط اليوم...');

      final todayStr = _formatDate(DateTime.now());
      final todayActivity = await _activityRepo.getDailyActivityForDate(todayStr);

      if (todayActivity != null) {
        if (todayActivity.totalSteps > _currentSteps) {
          _currentSteps = todayActivity.totalSteps;
          _currentDistance = todayActivity.distance;
          _currentCalories = todayActivity.caloriesBurned;
          _updateUI();
          debugPrint('📊 تم تحديث البيانات من قاعدة البيانات: $_currentSteps خطوة');
        }
      }

      final todaySessions = await _activityRepo.getActivitySessionsByDate(todayStr);

      setState(state.copyWith(
        recentSessions: todaySessions,
        lastUpdated: DateTime.now(),
      ));

    } catch (e) {
      debugPrint('❌ خطأ في تحديث نشاط اليوم: $e');
    }
  }

  Future<void> _initializeProviderImmediate() async {
    try {
      debugPrint('🚀 بدء التهيئة الفورية...');

      _currentDate = _formatDate(DateTime.now());

      await _loadSavedData();

      if (_currentSteps > 0) {
        debugPrint('📂 وُجدت بيانات محفوظة: $_currentSteps خطوة');
        _updateUI();
      } else {
        await _createInitialTodaySummary();
      }

      await _startDirectPedometerListening();
      unawaited(_ensureUnifiedServiceRunning());
      unawaited(_listenToUnifiedService()); // ✅ جديد - استماع لـ UnifiedService stream
      unawaited(_initializeBackground());
      _startPeriodicSaving();

      debugPrint('✅ تم إنشاء الواجهة الأولية بنجاح');

    } catch (e) {
      debugPrint('❌ خطأ في التهيئة الفورية: $e');
      _createEmergencyState();
    }
  }

  Future<void> _ensureUnifiedServiceRunning() async {
    try {
      debugPrint('🔄 تشغيل UnifiedService للخلفية...');

      if (!_unifiedService.isInitialized) {
        await _unifiedService.initialize();
      }

      if (!_unifiedService.isTracking) {
        final started = await _unifiedService.startTracking();
        debugPrint('📱 UnifiedService (للخلفية): ${started ? "نشط ✅" : "متوقف ❌"}');
      }

    } catch (e) {
      debugPrint('❌ خطأ في UnifiedService: $e');
    }
  }

  // ✅ دالة جديدة - الاستماع لـ UnifiedService stream (بالإضافة للـ Pedometer)
  Future<void> _listenToUnifiedService() async {
    try {
      debugPrint('🎧 بدء الاستماع لـ UnifiedService stream...');

      await _unifiedServiceSubscription?.cancel();

      _unifiedServiceSubscription = _unifiedService.dataStream.listen(
            (data) {
          final steps = data['steps'] as int? ?? 0;
          final distance = data['distance'] as double? ?? 0.0;
          final calories = data['calories'] as double? ?? 0.0;
          final date = data['date'] as String? ?? '';
          final isTracking = data['is_tracking'] as bool? ?? false;

          // تحديث البيانات إذا كانت من UnifiedService أحدث
          if (date == _currentDate && isTracking && steps > _currentSteps) {
            debugPrint('📡 [UnifiedService Stream] تحديث: $steps خطوة (أحدث من Pedometer)');
            _currentSteps = steps;
            _currentDistance = distance;
            _currentCalories = calories;
            _updateUI();
          }
        },
        onError: (error) {
          debugPrint('❌ [UnifiedService Stream] خطأ: $error');
        },
        cancelOnError: false,
      );

      debugPrint('✅ الاستماع لـ UnifiedService stream نشط (backup للـ Pedometer)');

    } catch (e) {
      debugPrint('❌ خطأ في الاستماع للـ UnifiedService stream: $e');
    }
  }

  Future<void> _startDirectPedometerListening() async {
    try {
      debugPrint('🎯 بدء Pedometer للواجهة...');

      final status = await Permission.activityRecognition.status;
      debugPrint('🔐 حالة إذن Activity Recognition: $status');

      if (!status.isGranted) {
        debugPrint('⚠️ الإذن غير ممنوح! سأطلبه...');
        final result = await Permission.activityRecognition.request();
        if (!result.isGranted) {
          debugPrint('❌ فشل الحصول على الإذن!');
          return;
        }
      }

      await _pedometerSubscription?.cancel();

      final prefs = await SharedPreferences.getInstance();
      _currentDate = _formatDate(DateTime.now());
      _baselineSteps = prefs.getInt('baseline_steps_$_currentDate') ?? 0;

      debugPrint('📍 Baseline المحمل: $_baselineSteps');

      _pedometerSubscription = Pedometer.stepCountStream.listen(
            (StepCount event) async {
          _systemSteps = event.steps;

          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━');
          debugPrint('📱 [PEDOMETER EVENT]');
          debugPrint('   System Steps: $_systemSteps');
          debugPrint('   Baseline: $_baselineSteps');
          debugPrint('   Current Date: $_currentDate');

          final today = _formatDate(DateTime.now());
          if (today != _currentDate) {
            debugPrint('🆕 يوم جديد! إعادة تعيين...');
            _currentDate = today;
            _baselineSteps = _systemSteps;
            _currentSteps = 0;
            _currentDistance = 0.0;
            _currentCalories = 0.0;
            await _saveBaseline();
            await _saveCurrentData();
            _updateUI();
            return;
          }

          if (_baselineSteps == 0) {
            final loadedBaseline = prefs.getInt('baseline_steps_$_currentDate') ?? 0;

            if (loadedBaseline == 0) {
              _baselineSteps = _systemSteps;
              await prefs.setInt('baseline_steps_$_currentDate', _baselineSteps);
              debugPrint('📍 Baseline جديد: $_baselineSteps');
            } else {
              _baselineSteps = loadedBaseline;
              debugPrint('📍 Baseline محمل: $_baselineSteps');
            }
          }

          final newSteps = (_systemSteps - _baselineSteps).clamp(0, 999999);

          debugPrint('🧮 الحساب: $_systemSteps - $_baselineSteps = $newSteps');

          _currentSteps = newSteps;
          _currentDistance = _currentSteps * 0.000762;
          _currentCalories = _currentSteps * 0.04;
          _updateUI();

          if (_currentSteps % 10 == 0 || _currentSteps < 10) {
            await _saveCurrentData();
            debugPrint('💾 تم الحفظ: $_currentSteps');
          }

          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━');
        },
        onError: (error) {
          debugPrint('❌ [Pedometer] خطأ: $error');
        },
        cancelOnError: false,
      );

      debugPrint('✅ Pedometer للواجهة نشط ومستعد للتحديث');

    } catch (e, stack) {
      debugPrint('❌ خطأ في بدء Pedometer: $e');
      debugPrint('Stack: $stack');
    }
  }

  DateTime? _lastUIUpdate;

  void _updateUI() {
    try {
      final now = DateTime.now();

      if (_lastUIUpdate != null &&
          now.difference(_lastUIUpdate!).inMilliseconds < 500) {
        return;
      }
      _lastUIUpdate = now;

      final summary = ActivitySummary(
        date: _currentDate,
        totalSteps: _currentSteps,
        totalDistance: _currentDistance,
        totalDuration: Duration(minutes: (_currentSteps / 100).round()),
        caloriesBurned: _currentCalories,
        activityBreakdown: {},
        completedGoals: _createCompletedGoalsFromData(
            _currentSteps,
            _currentDistance,
            _currentCalories
        ),
        intensityScore: _calculateIntensityScore(_currentSteps),
        activeMinutes: (_currentSteps / 100).round(),
      );

      final updatedGoals = _updateGoalsWithNewData(state.activeGoals, summary);

      setState(state.copyWith(
        todaysSummary: summary,
        activeGoals: updatedGoals,
        lastUpdated: DateTime.now(),
        hasData: true,
        isTracking: true,
      ));

      debugPrint('🖥️ [UI UPDATED] الخطوات: $_currentSteps');

    } catch (e) {
      debugPrint('❌ خطأ في تحديث UI: $e');
    }
  }

  Future<void> _saveCurrentData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setInt('steps_today', _currentSteps);
      await prefs.setDouble('distance_today', _currentDistance);
      await prefs.setDouble('calories_today', _currentCalories);
      await prefs.setString('steps_date', _currentDate);
      await prefs.setInt('system_steps', _systemSteps);
      await prefs.setInt('baseline_steps_$_currentDate', _baselineSteps);

      final lastDbSave = prefs.getInt('last_db_save_steps') ?? 0;
      final lastDbSaveTime = prefs.getInt('last_db_save_time') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      final stepsDiff = (_currentSteps - lastDbSave).abs();
      final timeDiff = now - lastDbSaveTime;
      final fiveMinutes = 5 * 60 * 1000;

      bool shouldSaveToDb = false;
      String reason = '';

      if (stepsDiff >= 100) {
        shouldSaveToDb = true;
        reason = 'فرق 100 خطوة';
      } else if (timeDiff >= fiveMinutes && _currentSteps > 0) {
        shouldSaveToDb = true;
        reason = 'مرت 5 دقائق';
      } else if (_currentSteps > 0 && lastDbSave == 0) {
        shouldSaveToDb = true;
        reason = 'أول حفظ';
      }

      if (shouldSaveToDb) {
        await _saveToDatabase();
        await prefs.setInt('last_db_save_steps', _currentSteps);
        await prefs.setInt('last_db_save_time', now);
        debugPrint('💾 تم الحفظ في قاعدة البيانات: $_currentSteps خطوة ($reason)');
      }

    } catch (e, stack) {
      debugPrint('❌ خطأ في الحفظ: $e');
      debugPrint('Stack: $stack');
    }
  }

  Future<void> _saveToDatabase() async {
    try {
      await _activityRepo.upsertDailyActivity(
        date: _currentDate,
        totalSteps: _currentSteps,
        distance: _currentDistance,
        caloriesBurned: _currentCalories,
        activityType: 'walking',
        intensityScore: _calculateIntensityScore(_currentSteps),
      );

      debugPrint('✅ تم حفظ $_currentSteps خطوة في قاعدة البيانات');

    } catch (e, stack) {
      debugPrint('❌ خطأ في الحفظ لقاعدة البيانات: $e');
      debugPrint('Stack: $stack');
    }
  }

  Future<void> _saveBaseline() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('baseline_steps_$_currentDate', _baselineSteps);
      debugPrint('💾 تم حفظ Baseline: $_baselineSteps');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ Baseline: $e');
    }
  }

  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDate = prefs.getString('steps_date') ?? '';

      debugPrint('🔍 تحميل البيانات المحفوظة...');
      debugPrint('   - التاريخ المحفوظ: $savedDate');
      debugPrint('   - التاريخ الحالي: $_currentDate');

      if (savedDate == _currentDate) {
        _currentSteps = prefs.getInt('steps_today') ?? 0;
        _currentDistance = prefs.getDouble('distance_today') ?? 0.0;
        _currentCalories = prefs.getDouble('calories_today') ?? 0.0;
        _baselineSteps = prefs.getInt('baseline_steps_$_currentDate') ?? 0;
        _systemSteps = prefs.getInt('system_steps') ?? 0;

        debugPrint('📂 تم تحميل البيانات المحفوظة:');
        debugPrint('   - خطوات: $_currentSteps');
        debugPrint('   - Baseline: $_baselineSteps');
        debugPrint('   - System: $_systemSteps');
      } else {
        debugPrint('🆕 يوم جديد - لا توجد بيانات محفوظة');
        _currentSteps = 0;
        _currentDistance = 0.0;
        _currentCalories = 0.0;
        _baselineSteps = 0;
        _systemSteps = 0;
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل البيانات: $e');
    }
  }

  void _startPeriodicSaving() {
    _saveTimer?.cancel();
    _saveTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!isDisposed && _currentSteps > 0) {
        await _saveCurrentData();
      }
    });
    debugPrint('⏰ بدأ الحفظ الدوري (كل 10 ثواني)');
  }

  double _calculateIntensityScore(int steps) {
    if (steps < 2000) return 0.2;
    if (steps < 5000) return 0.4;
    if (steps < 8000) return 0.6;
    if (steps < 10000) return 0.8;
    return 1.0;
  }

  // ✅ النسخة المعدلة - async
  Future<List<String>> _createCompletedGoalsFromDataAsync(int steps, double distance, double calories) async {
    final stepsGoal = await _userSettings.getStepsGoal();
    final distanceGoal = await _userSettings.getDistanceGoal();
    final caloriesGoal = await _userSettings.getCaloriesGoal();

    final completed = <String>[];
    if (steps >= stepsGoal) completed.add('daily_steps');
    if (distance >= distanceGoal) completed.add('daily_distance');
    if (calories >= caloriesGoal) completed.add('daily_calories');
    return completed;
  }

  // النسخة القديمة - للتوافق
  List<String> _createCompletedGoalsFromData(int steps, double distance, double calories) {
    final completed = <String>[];
    if (steps >= 10000) completed.add('daily_steps');
    if (distance >= 8.0) completed.add('daily_distance');
    if (calories >= 500) completed.add('daily_calories');
    return completed;
  }

  List<ActivityGoal> _updateGoalsWithNewData(List<ActivityGoal> currentGoals, ActivitySummary summary) {
    return currentGoals.map((goal) {
      double newProgress = 0.0;

      switch (goal.goalType) {
        case GoalType.steps:
          newProgress = summary.totalSteps.toDouble();
          break;
        case GoalType.distance:
          newProgress = summary.totalDistance;
          break;
        case GoalType.calories:
          newProgress = summary.caloriesBurned;
          break;
        case GoalType.duration:
          newProgress = summary.totalDuration.inSeconds.toDouble();
          break;
        default:
          newProgress = goal.currentProgress;
      }

      return ActivityGoal(
        id: goal.id,
        title: goal.title,
        activityType: goal.activityType,
        goalType: goal.goalType,
        targetValue: goal.targetValue,
        unit: goal.unit,
        startDate: goal.startDate,
        endDate: goal.endDate,
        isActive: goal.isActive,
        currentProgress: newProgress,
      );
    }).toList();
  }

  // ✅ معدّلة - async
  Future<void> _createInitialTodaySummary() async {
    final initialSummary = ActivitySummary(
      date: _currentDate,
      totalSteps: _currentSteps,
      totalDistance: _currentDistance,
      totalDuration: Duration(minutes: (_currentSteps / 100).round()),
      caloriesBurned: _currentCalories,
      activityBreakdown: {},
      completedGoals: _createCompletedGoalsFromData(_currentSteps, _currentDistance, _currentCalories),
      intensityScore: _calculateIntensityScore(_currentSteps),
      activeMinutes: (_currentSteps / 100).round(),
    );

    final initialGoals = await _createRealGoalsAsync(initialSummary); // ← async

    setState(ActivityTrackingState(
      loadingState: LoadingState.success,
      hasData: true,
      todaysSummary: initialSummary,
      activeGoals: initialGoals,
      recentSessions: [],
      recentActivities: [],
      activityStats: {},
      fitnessScore: 0.0,
      isTracking: true,
      hasHealthPermissions: true,
      lastUpdated: DateTime.now(),
      successMessage: 'تم إنشاء البيانات الأولية',
    ));

    debugPrint('✅ تم إنشاء ملخص أولي: $_currentSteps خطوة');
  }
  Future<void> _initializeBackground() async {
    try {
      debugPrint('🔄 بدء التهيئة في الخلفية...');
      await _loadInitialDatabaseData();
      await _initializeServices();
      await _generateTodayInsights();
      _startInsightsTimer();
      debugPrint('✅ تمت التهيئة في الخلفية بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في التهيئة الخلفية: $e');
    }
  }

  Future<void> _initializeServices() async {
    try {
      final insightsInitialized = await _insightsService.initialize();
      debugPrint('📱 حالة الخدمات: Insights=$insightsInitialized');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة الخدمات: $e');
    }
  }

  Future<void> _loadInitialDatabaseData() async {
    try {
      debugPrint('🔍 تحميل البيانات من قاعدة البيانات...');

      final todayStr = _formatDate(DateTime.now());
      final todaySessions = await _activityRepo.getActivitySessionsByDate(todayStr);
      final recentActivities = await _activityRepo.getDailyActivitiesInPeriod(
        startDate: DateTime.now().subtract(const Duration(days: 29)),
        endDate: DateTime.now(),
      );

      setState(state.copyWith(
        recentSessions: todaySessions,
        recentActivities: recentActivities,
        hasData: true,
        lastUpdated: DateTime.now(),
      ));

      debugPrint('✅ تم تحميل ${recentActivities.length} يوم من البيانات التاريخية');

    } catch (e) {
      debugPrint('❌ خطأ في تحميل البيانات: $e');
    }
  }

  void _createEmergencyState() {
    final emergencySummary = _createEmptySummary(_currentDate);

    setState(ActivityTrackingState(
      loadingState: LoadingState.success,
      hasData: true,
      todaysSummary: emergencySummary,
      activeGoals: _createRealGoals(emergencySummary),
      recentSessions: [],
      recentActivities: [],
      activityStats: {},
      fitnessScore: 0.0,
      isTracking: false,
      hasHealthPermissions: false,
      lastUpdated: DateTime.now(),
      error: ActivityTrackingError(
        message: 'تم تشغيل الوضع الأساسي',
        code: 'EMERGENCY_MODE',
        type: 'system',
      ),
    ));

    debugPrint('🚨 تم تفعيل حالة الطوارئ');
  }

  Future<void> startActivityTracking() async {
    if (state.isTracking) {
      debugPrint('التتبع نشط بالفعل');
      return;
    }

    await _startDirectPedometerListening();

    setState(state.copyWith(
      isTracking: true,
      lastActivityCheck: DateTime.now(),
      successMessage: 'تم بدء التتبع بنجاح',
    ));
  }

  Future<void> stopActivityTracking() async {
    await _pedometerSubscription?.cancel();
    await _saveCurrentData();

    setState(state.copyWith(
      isTracking: false,
      successMessage: 'تم إيقاف التتبع',
    ));
  }

  void _startInsightsTimer() {
    _insightsTimer?.cancel();
    _insightsTimer = Timer.periodic(const Duration(hours: 1), (timer) async {
      if (!isDisposed) {
        await _generateTodayInsights();
      }
    });
  }

  Future<void> _checkGoalsProgress() async {
    try {
      final summary = state.todaysSummary;
      final newlyCompleted = <String>[];

      for (final goal in state.activeGoals) {
        if (!goal.isCompleted) {
          bool isCompleted = false;

          switch (goal.goalType) {
            case GoalType.steps:
              isCompleted = summary.totalSteps >= goal.targetValue;
              break;
            case GoalType.distance:
              isCompleted = summary.totalDistance >= goal.targetValue;
              break;
            case GoalType.calories:
              isCompleted = summary.caloriesBurned >= goal.targetValue;
              break;
            case GoalType.duration:
              isCompleted = summary.totalDuration.inMinutes >= goal.targetValue;
              break;
            default:
              break;
          }

          if (isCompleted) {
            newlyCompleted.add(goal.id);

            await _notificationService.showNotification(
              id: 3100 + goal.id.hashCode,
              title: 'تهانينا! تم إنجاز الهدف',
              body: 'لقد حققت هدف: ${goal.title}',
              channelId: NotificationService.channelInsights,
              payload: {
                'type': 'goal_completed',
                'goal_id': goal.id,
              },
            );
          }
        }
      }

      if (newlyCompleted.isNotEmpty) {
        debugPrint('✅ تم إنجاز ${newlyCompleted.length} هدف');
      }

    } catch (e) {
      debugPrint('❌ خطأ في فحص الأهداف: $e');
    }
  }

  Future<void> _generateTodayInsights() async {
    try {
      debugPrint('💡 [Activity] توليد رؤى النشاط فقط...');

      final insights = await _insightsService.generateActivityOnlyInsights(_currentDate);

      if (insights.isNotEmpty) {
        setState(state.copyWith(insights: insights));
        debugPrint('✅ [Activity] تم إنتاج ${insights.length} رؤية للنشاط');
      } else {
        debugPrint('⚠️ [Activity] لا توجد رؤى جديدة');
      }
    } catch (e) {
      debugPrint('❌ خطأ في إنتاج رؤى النشاط: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRealHistoricalData({int days = 7}) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days - 1));
      final data = <Map<String, dynamic>>[];

      for (int i = 0; i < days; i++) {
        final date = startDate.add(Duration(days: i));
        final dateStr = _formatDate(date);
        final isToday = dateStr == _currentDate;

        int steps = 0;
        double distance = 0.0;
        double calories = 0.0;

        if (isToday) {
          steps = _currentSteps;
          distance = _currentDistance;
          calories = _currentCalories;
        } else {
          final activity = await _activityRepo.getDailyActivityForDate(dateStr);
          if (activity != null) {
            steps = activity.totalSteps;
            distance = activity.distance;
            calories = activity.caloriesBurned;
          }
        }

        data.add({
          'date': dateStr,
          'day_name': _getDayName(date.weekday),
          'steps': steps,
          'distance': distance,
          'calories': calories,
          'is_today': isToday,
          'has_real_data': steps > 0,
        });
      }

      return data;
    } catch (e) {
      debugPrint('❌ خطأ في البيانات التاريخية: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRealWeeklyChartData() async {
    return await getRealHistoricalData(days: 7);
  }

  Future<List<Map<String, dynamic>>> getRealMonthlyChartData() async {
    return await getRealHistoricalData(days: 30);
  }

  // ════════════════════════════════════════════════════════════
  // ✅ دوال الأهداف المعدّلة
  // ════════════════════════════════════════════════════════════

  /// النسخة الجديدة - async - تستخدم UserSettings
  Future<List<ActivityGoal>> _createRealGoalsAsync(ActivitySummary summary) async {
    final stepsGoal = await _userSettings.getStepsGoal();
    final distanceGoal = await _userSettings.getDistanceGoal();
    final caloriesGoal = await _userSettings.getCaloriesGoal();

    return [
      ActivityGoal(
        id: 'daily_steps',
        title: 'خطوات يومية',
        activityType: ActivityType.walking,
        goalType: GoalType.steps,
        targetValue: stepsGoal.toDouble(),
        unit: 'خطوة',
        startDate: DateTime.now(),
        currentProgress: summary.totalSteps.toDouble(),
      ),
      ActivityGoal(
        id: 'daily_distance',
        title: 'المسافة اليومية',
        activityType: ActivityType.walking,
        goalType: GoalType.distance,
        targetValue: distanceGoal,
        unit: 'كم',
        startDate: DateTime.now(),
        currentProgress: summary.totalDistance,
      ),
      ActivityGoal(
        id: 'daily_calories',
        title: 'حرق السعرات',
        activityType: ActivityType.general,
        goalType: GoalType.calories,
        targetValue: caloriesGoal,
        unit: 'سعرة',
        startDate: DateTime.now(),
        currentProgress: summary.caloriesBurned,
      ),
    ];
  }

  /// النسخة القديمة - sync - للتوافق
  List<ActivityGoal> _createRealGoals(ActivitySummary summary) {
    return [
      ActivityGoal(
        id: 'daily_steps',
        title: 'خطوات يومية',
        activityType: ActivityType.walking,
        goalType: GoalType.steps,
        targetValue: 10000,
        unit: 'خطوة',
        startDate: DateTime.now(),
        currentProgress: summary.totalSteps.toDouble(),
      ),
      ActivityGoal(
        id: 'daily_distance',
        title: 'المسافة اليومية',
        activityType: ActivityType.walking,
        goalType: GoalType.distance,
        targetValue: 8,
        unit: 'كم',
        startDate: DateTime.now(),
        currentProgress: summary.totalDistance,
      ),
      ActivityGoal(
        id: 'daily_calories',
        title: 'حرق السعرات',
        activityType: ActivityType.general,
        goalType: GoalType.calories,
        targetValue: 500,
        unit: 'سعرة',
        startDate: DateTime.now(),
        currentProgress: summary.caloriesBurned,
      ),
    ];
  }

  /// ✅ تحديث الأهداف من الإعدادات
  Future<void> refreshGoals() async {
    try {
      final summary = state.todaysSummary;
      final newGoals = await _createRealGoalsAsync(summary);

      setState(state.copyWith(
        activeGoals: newGoals,
      ));

      debugPrint('✅ تم تحديث الأهداف من الإعدادات');
    } catch (e) {
      debugPrint('❌ خطأ في تحديث الأهداف: $e');
    }
  }

  /// ✅ تحديث هدف واحد
  Future<bool> updateSingleGoal(String goalType, dynamic value) async {
    try {
      bool success = false;

      switch (goalType) {
        case 'steps':
          success = await _userSettings.setStepsGoal(value as int);
          break;
        case 'distance':
          success = await _userSettings.setDistanceGoal(value as double);
          break;
        case 'calories':
          success = await _userSettings.setCaloriesGoal(value as double);
          break;
      }

      if (success) {
        await refreshGoals();
      }

      return success;
    } catch (e) {
      debugPrint('❌ خطأ في تحديث الهدف: $e');
      return false;
    }
  }

  /// ✅ قراءة الأهداف الحالية
  Future<Map<String, dynamic>> getCurrentGoals() async {
    return await _userSettings.getAllGoals();
  }

  ActivitySummary _createEmptySummary(String date) {
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getDayName(int weekday) {
    const days = ['', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    return days[weekday];
  }

  Future<int> getYesterdaySteps() async {
    try {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStr = _formatDate(yesterday);

      for (final activity in state.recentActivities) {
        if (activity.date == yesterdayStr) {
          return activity.totalSteps;
        }
      }

      final yesterdayActivity = await _activityRepo.getDailyActivityForDate(yesterdayStr);
      return yesterdayActivity?.totalSteps ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<int> getWeeklySteps() async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      int totalSteps = _currentSteps;

      for (int i = 0; i < now.weekday - 1; i++) {
        final day = weekStart.add(Duration(days: i));
        final dayStr = _formatDate(day);

        bool found = false;
        for (final activity in state.recentActivities) {
          if (activity.date == dayStr) {
            totalSteps += activity.totalSteps;
            found = true;
            break;
          }
        }

        if (!found) {
          final dayActivity = await _activityRepo.getDailyActivityForDate(dayStr);
          if (dayActivity != null) {
            totalSteps += dayActivity.totalSteps;
          }
        }
      }

      return totalSteps;
    } catch (e) {
      return 0;
    }
  }

  /// ✅ النسخة الجديدة - async
  Future<int> calculateGoalProgressAsync() async {
    final stepsGoal = await _userSettings.getStepsGoal();
    return ((_currentSteps / stepsGoal) * 100).round().clamp(0, 100);
  }

  /// النسخة القديمة - للتوافق
  int calculateGoalProgress() {
    const stepGoal = 10000;
    return ((_currentSteps / stepGoal) * 100).round().clamp(0, 100);
  }

  Map<String, dynamic> getQuickStats() {
    return {
      'today_steps': _currentSteps,
      'today_distance': _currentDistance,
      'today_calories': _currentCalories,
      'goal_progress': calculateGoalProgress(),
      'is_tracking': state.isTracking,
      'has_data': true,
      'active_minutes': (_currentSteps / 100).round(),
    };
  }

  @override
  void dispose() {
    debugPrint('🗑️ تنظيف ActivityTrackingProvider');

    _saveCurrentData();

    _pedometerSubscription?.cancel();
    _unifiedServiceSubscription?.cancel(); // ✅ جديد - إلغاء stream subscription
    _goalsCheckTimer?.cancel();
    _insightsTimer?.cancel();
    _saveTimer?.cancel();

    super.dispose();
  }
}