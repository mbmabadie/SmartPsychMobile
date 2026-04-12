// lib/core/services/enhanced_background_service.dart - ✅ النسخة المدمجة الكاملة النهائية
import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:pedometer/pedometer.dart';
import 'package:light/light.dart';
import 'package:permission_handler/permission_handler.dart';

import 'notification_service.dart';
import '../database/database_helper.dart';

/// ════════════════════════════════════════════════════════════
/// BackgroundService - خدمة خلفية محسّنة ومدمجة بالكامل
/// Document 4 + Document 5 Merged
/// ════════════════════════════════════════════════════════════
class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  static BackgroundService get instance => _instance;

  bool _isInitialized = false;
  bool _isRunning = false;

  // ✅ NEW from Document 5
  Timer? _healthCheckTimer;
  Timer? _saveTimer;

  /// تهيئة الخدمة المحسنة مع جميع المكونات
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      debugPrint('🚀 تهيئة الخدمة المحسنة للعمل المستمر...');

      // 1. تهيئة WorkManager للمهام المجدولة
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );

      // 2. تهيئة Flutter Background Service
      await _initializeBackgroundService();

      // 3. جدولة جميع المهام الضرورية
      await _scheduleAllCriticalTasks();

      _isInitialized = true;
      debugPrint('✅ تم تهيئة الخدمة المحسنة بنجاح');
      return true;

    } catch (e) {
      debugPrint('❌ خطأ في تهيئة الخدمة المحسنة: $e');
      return false;
    }
  }

  /// تهيئة خدمة الخلفية للعمل المستمر
  Future<void> _initializeBackgroundService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        autoStart: true,
        onStart: onStart,
        isForegroundMode: true,
        autoStartOnBoot: true,
        notificationChannelId: 'smart_psych_background',
        initialNotificationTitle: 'Smart Psych نشط',
        initialNotificationContent: 'تتبع مستمر للصحة والنشاط',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [
          AndroidForegroundType.health,
          AndroidForegroundType.dataSync,
          AndroidForegroundType.location,
        ],
      ),
    );
  }

  /// جدولة جميع المهام الحرجة للعمل المستمر
  Future<void> _scheduleAllCriticalTasks() async {
    // ✅ NEW Task 1: Service Health Check
    await Workmanager().registerPeriodicTask(
      'service_health_check',
      'service_health_check',
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
        requiresCharging: false,
      ),
      initialDelay: const Duration(minutes: 1),
    );

    // Task 2: مهمة التتبع المستمر - كل 5 دقائق
    await Workmanager().registerPeriodicTask(
      'health_tracking_continuous',
      'health_tracking_continuous',
      frequency: const Duration(minutes: 15),
      inputData: {'actual_interval_minutes': 5},
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
        requiresCharging: false,
      ),
      initialDelay: const Duration(seconds: 10),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(seconds: 15),
    );

    // Task 3: مهمة تتبع الخطوات المستمر
    await Workmanager().registerPeriodicTask(
      'step_tracking_realtime',
      'step_tracking_realtime',
      frequency: const Duration(minutes: 15),
      inputData: {'interval_minutes': 2},
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
      ),
    );

    // Task 4: مهمة تتبع الموقع المستمر
    await Workmanager().registerPeriodicTask(
      'location_tracking_continuous',
      'location_tracking_continuous',
      frequency: const Duration(minutes: 15),
      inputData: {'interval_minutes': 5},
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
    );

    // Task 5: مهمة الحساسات والبيئة - كل دقيقة
    await Workmanager().registerPeriodicTask(
      'sensors_environment_tracking',
      'sensors_environment_tracking',
      frequency: const Duration(minutes: 15),
      inputData: {'interval_minutes': 1},
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
    );

    // Task 6: مهمة النوم التلقائي - كل 3 دقائق في الليل
    await Workmanager().registerPeriodicTask(
      'sleep_detection_auto',
      'sleep_detection_auto',
      frequency: const Duration(minutes: 15),
      inputData: {'interval_minutes': 3},
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
    );

    // Task 7: مهمة الإشعارات الذكية - حسب الجدولة
    await Workmanager().registerPeriodicTask(
      'smart_notifications_scheduler',
      'smart_notifications_scheduler',
      frequency: const Duration(minutes: 30),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
    );

    // Task 8: مهمة فحص عدم الاستخدام - كل 6 ساعات
    await Workmanager().registerPeriodicTask(
      'app_usage_monitor',
      'app_usage_monitor',
      frequency: const Duration(hours: 6),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
    );

    // Task 9: مهمة تنظيف البيانات - يوميا
    await Workmanager().registerPeriodicTask(
      'data_cleanup_daily',
      'data_cleanup_daily',
      frequency: const Duration(days: 1),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
    );

    debugPrint('✅ تم جدولة 9 مهام حرجة');
  }

  /// بدء الخدمة المحسنة
  Future<bool> start() async {
    if (_isRunning) return true;

    try {
      if (!_isInitialized) {
        await initialize();
      }

      final service = FlutterBackgroundService();
      service.startService();

      // ✅ NEW: Start Timers
      _startHealthCheckTimer();
      _startSaveTimer();

      _isRunning = true;

      // تسجيل بدء الخدمة
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('background_service_running', true);
      await prefs.setInt('service_start_time', DateTime.now().millisecondsSinceEpoch);
      await prefs.setInt('last_app_usage', DateTime.now().millisecondsSinceEpoch);

      debugPrint('✅ تم بدء الخدمة المحسنة للعمل المستمر');
      return true;

    } catch (e) {
      debugPrint('❌ فشل في بدء الخدمة المحسنة: $e');
      return false;
    }
  }

  /// ✅ NEW: Health Check Timer (كل 5 دقائق)
  void _startHealthCheckTimer() {
    _healthCheckTimer?.cancel();

    _healthCheckTimer = Timer.periodic(
      const Duration(minutes: 5),
          (timer) async {
        await _performHealthCheck();
      },
    );

    debugPrint('✅ [HealthCheck] Timer نشط (كل 5 دقائق)');
  }

  Future<void> _performHealthCheck() async {
    try {
      debugPrint('🏥 [HealthCheck] جاري الفحص...');

      final prefs = await SharedPreferences.getInstance();
      final lastStepUpdate = prefs.getInt('last_step_update') ?? 0;
      final steps = prefs.getInt('steps_today') ?? 0;

      final timeSinceUpdate = DateTime.now().millisecondsSinceEpoch - lastStepUpdate;
      if (timeSinceUpdate > 5 * 60 * 1000) {
        debugPrint('⚠️ [HealthCheck] الخطوات متجمدة - آخر تحديث منذ ${timeSinceUpdate ~/ 1000}s');
      }

      debugPrint('✅ [HealthCheck] الخطوات: $steps');

      await prefs.setInt('last_health_check', DateTime.now().millisecondsSinceEpoch);
      await prefs.setInt('last_health_check_steps', steps);

    } catch (e) {
      debugPrint('❌ [HealthCheck] خطأ: $e');
    }
  }

  /// ✅ NEW: Save Timer (كل دقيقة)
  void _startSaveTimer() {
    _saveTimer?.cancel();

    _saveTimer = Timer.periodic(
      const Duration(minutes: 1),
          (timer) async {
        await _performSave();
      },
    );

    debugPrint('✅ [SaveTimer] نشط (كل دقيقة)');
  }

  Future<void> _performSave() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final steps = prefs.getInt('steps_today') ?? 0;

      await prefs.setInt('bg_saved_steps', steps);
      await prefs.setInt('bg_last_save_time', DateTime.now().millisecondsSinceEpoch);

      if (steps % 100 == 0 && steps > 0) {
        debugPrint('💾 [SaveTimer] حفظ: $steps خطوة');
      }
    } catch (e) {
      debugPrint('❌ [SaveTimer] خطأ: $e');
    }
  }

  /// إيقاف الخدمة
  Future<void> stop() async {
    try {
      final service = FlutterBackgroundService();
      service.invoke('stop');

      // ✅ Stop Timers
      _healthCheckTimer?.cancel();
      _saveTimer?.cancel();

      // إلغاء جميع المهام
      await Workmanager().cancelAll();

      _isRunning = false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('background_service_running', false);

      debugPrint('⏹️ تم إيقاف الخدمة المحسنة');
    } catch (e) {
      debugPrint('❌ خطأ في إيقاف الخدمة: $e');
    }
  }

  /// الحصول على حالة الخدمة التفصيلية
  Future<Map<String, dynamic>> getDetailedStatus() async {
    try {
      final service = FlutterBackgroundService();
      final isServiceRunning = await service.isRunning();

      final prefs = await SharedPreferences.getInstance();
      final startTime = prefs.getInt('service_start_time') ?? 0;
      final lastAppUsage = prefs.getInt('last_app_usage') ?? 0;
      final lastHealthSync = prefs.getInt('last_health_sync') ?? 0;
      final totalStepsToday = prefs.getInt('total_steps_today') ?? 0;
      final lastLocationUpdate = prefs.getInt('last_location_update') ?? 0;

      return {
        'is_running': _isRunning && isServiceRunning,
        'is_initialized': _isInitialized,
        'start_time': startTime > 0 ? DateTime.fromMillisecondsSinceEpoch(startTime) : null,
        'uptime_hours': startTime > 0
            ? DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(startTime)).inHours
            : 0,
        'last_app_usage': lastAppUsage > 0 ? DateTime.fromMillisecondsSinceEpoch(lastAppUsage) : null,
        'days_since_last_usage': lastAppUsage > 0
            ? DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(lastAppUsage)).inDays
            : 0,
        'health_tracking_active': lastHealthSync > 0 &&
            DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(lastHealthSync)).inMinutes < 10,
        'steps_today': totalStepsToday,
        'location_tracking_active': lastLocationUpdate > 0 &&
            DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(lastLocationUpdate)).inMinutes < 10,
        'background_tasks_scheduled': 9,
      };
    } catch (e) {
      return {'is_running': false, 'error': e.toString()};
    }
  }

  bool get isInitialized => _isInitialized;
  bool get isRunning => _isRunning;
}

// ═══════════════════════════════════════════════════════════════
// Isolate Entry Points
// ═══════════════════════════════════════════════════════════════

/// معالج WorkManager الرئيسي
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('🔄 تنفيذ مهمة خلفية: $task');

    try {
      await _updateServiceActivity();

      switch (task) {
        case 'service_health_check':  // ✅ NEW
          return await _performServiceHealthCheck();
        case 'health_tracking_continuous':
          return await _performContinuousHealthTracking(inputData);
        case 'step_tracking_realtime':
          return await _performRealtimeStepTracking(inputData);
        case 'location_tracking_continuous':
          return await _performContinuousLocationTracking(inputData);
        case 'sensors_environment_tracking':
          return await _performSensorsEnvironmentTracking(inputData);
        case 'sleep_detection_auto':
          return await _performAutoSleepDetection(inputData);
        case 'smart_notifications_scheduler':
          return await _performSmartNotifications();
        case 'app_usage_monitor':
          return await _checkAppUsageAndNotify();
        case 'data_cleanup_daily':
          return await _performDailyDataCleanup();
        default:
          debugPrint('❓ مهمة غير معروفة: $task');
          return false;
      }
    } catch (e) {
      debugPrint('❌ خطأ في المهمة $task: $e');
      return false;
    }
  });
}

/// تحديث آخر نشاط للخدمة
Future<void> _updateServiceActivity() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_service_activity', DateTime.now().millisecondsSinceEpoch);
  } catch (e) {
    debugPrint('❌ خطأ في تحديث نشاط الخدمة: $e');
  }
}

// ═══════════════════════════════════════════════════════════════
// Task Handlers
// ═══════════════════════════════════════════════════════════════

/// ✅ NEW: Service Health Check
Future<bool> _performServiceHealthCheck() async {
  try {
    debugPrint('🏥 [Task] Service Health Check...');

    final prefs = await SharedPreferences.getInstance();
    final lastStepUpdate = prefs.getInt('last_step_update') ?? 0;
    final steps = prefs.getInt('steps_today') ?? 0;

    final timeSinceUpdate = DateTime.now().millisecondsSinceEpoch - lastStepUpdate;
    if (timeSinceUpdate > 5 * 60 * 1000) {
      debugPrint('⚠️ [Task] الخدمة متجمدة');
    }

    debugPrint('✅ [Task] الخدمة تعمل: $steps خطوة');
    return true;
  } catch (e) {
    debugPrint('❌ [Task] خطأ في Health Check: $e');
    return false;
  }
}

Future<bool> _performContinuousHealthTracking(Map<String, dynamic>? inputData) async {
  try {
    debugPrint('💖 تتبع صحي مستمر...');

    final intervalMinutes = inputData?['actual_interval_minutes'] ?? 5;
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt('last_health_check') ?? 0;

    if (DateTime.now().millisecondsSinceEpoch - lastCheck < (intervalMinutes * 60 * 1000)) {
      return true;
    }

    await _performQuickHealthUpdate();
    await prefs.setInt('last_health_check', DateTime.now().millisecondsSinceEpoch);

    return true;
  } catch (e) {
    debugPrint('❌ خطأ في التتبع الصحي المستمر: $e');
    return false;
  }
}

Future<bool> _performRealtimeStepTracking(Map<String, dynamic>? inputData) async {
  try {
    debugPrint('👟 تتبع الخطوات في الوقت الفعلي...');

    final prefs = await SharedPreferences.getInstance();
    final lastStepCount = prefs.getInt('last_step_count') ?? 0;

    await _saveStepDataEnhanced(lastStepCount, DateTime.now());

    return true;
  } catch (e) {
    debugPrint('❌ خطأ في تتبع الخطوات: $e');
    return false;
  }
}

Future<bool> _performContinuousLocationTracking(Map<String, dynamic>? inputData) async {
  try {
    debugPrint('📍 تتبع الموقع المستمر...');

    final position = await _getCurrentLocationSafe();
    if (position != null) {
      await _saveLocationDataEnhanced(position);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_location_update', DateTime.now().millisecondsSinceEpoch);
    }

    return true;
  } catch (e) {
    debugPrint('❌ خطأ في تتبع الموقع: $e');
    return false;
  }
}

Future<bool> _performSensorsEnvironmentTracking(Map<String, dynamic>? inputData) async {
  try {
    debugPrint('📊 تتبع الحساسات والبيئة...');

    await _processCachedSensorData();
    await _analyzeEnvironmentalConditions();

    return true;
  } catch (e) {
    debugPrint('❌ خطأ في تتبع الحساسات: $e');
    return false;
  }
}

Future<bool> _performAutoSleepDetection(Map<String, dynamic>? inputData) async {
  try {
    if (!_isNightTime()) return true;

    debugPrint('😴 كشف النوم التلقائي...');

    final sleepDetected = await _performAdvancedSleepDetection();
    if (sleepDetected) {
      await _handleSleepDetection();
    }

    return true;
  } catch (e) {
    debugPrint('❌ خطأ في كشف النوم: $e');
    return false;
  }
}

Future<bool> _performSmartNotifications() async {
  try {
    debugPrint('📱 إرسال إشعارات ذكية...');

    await _sendContextualNotifications();
    await _checkDailyGoals();
    await _sendMotivationalNotifications();

    return true;
  } catch (e) {
    debugPrint('❌ خطأ في الإشعارات الذكية: $e');
    return false;
  }
}

Future<bool> _checkAppUsageAndNotify() async {
  try {
    debugPrint('👤 فحص استخدام التطبيق...');

    final prefs = await SharedPreferences.getInstance();
    final lastAppUsage = prefs.getInt('last_app_usage') ?? 0;

    if (lastAppUsage > 0) {
      final daysSinceLastUsage = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(lastAppUsage))
          .inDays;

      if (daysSinceLastUsage >= 3) {
        await _sendAppUnusedNotification(daysSinceLastUsage);
      } else if (daysSinceLastUsage >= 1) {
        await _sendDailyCheckInNotification();
      }
    }

    return true;
  } catch (e) {
    debugPrint('❌ خطأ في فحص الاستخدام: $e');
    return false;
  }
}

Future<bool> _performDailyDataCleanup() async {
  try {
    debugPrint('🧹 تنظيف البيانات اليومي...');

    final dbHelper = DatabaseHelper.instance;
    await dbHelper.cleanupOldData(daysToKeep: 90);

    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final oldKeys = keys.where((key) => key.contains('temp_') || key.contains('cache_'));
    for (final key in oldKeys) {
      await prefs.remove(key);
    }

    return true;
  } catch (e) {
    debugPrint('❌ خطأ في تنظيف البيانات: $e');
    return false;
  }
}

// ═══════════════════════════════════════════════════════════════
// Flutter Background Service Entry Point
// ═══════════════════════════════════════════════════════════════

/// الخدمة المستمرة الرئيسية
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  debugPrint('🚀 بدء الخدمة المستمرة المحسنة');

  StreamSubscription<StepCount>? stepSubscription;
  StreamSubscription<AccelerometerEvent>? accelerometerSubscription;
  StreamSubscription<int>? lightSubscription;

  Timer? healthTimer;
  Timer? locationTimer;
  Timer? notificationTimer;
  Timer? sleepDetectionTimer;

  int lastStepCount = 0;
  Position? lastPosition;
  DateTime lastHealthUpdate = DateTime.now();
  bool isSleepDetectionActive = false;

  try {
    final prefs = await SharedPreferences.getInstance();
    lastStepCount = prefs.getInt('last_step_count') ?? 0;

    // 1. تتبع الخطوات المستمر
    stepSubscription = Pedometer.stepCountStream.listen(
          (StepCount event) async {
        try {
          final newSteps = event.steps;
          final now = DateTime.now();

          if (newSteps != lastStepCount) {
            await _saveStepDataEnhanced(newSteps, now);
            lastStepCount = newSteps;
            await prefs.setInt('last_step_count', newSteps);
            await prefs.setInt('total_steps_today', newSteps);

            // أخبر ActivityProvider
            await prefs.setInt('bg_last_steps', newSteps);
            await prefs.setInt('bg_last_steps_time', now.millisecondsSinceEpoch);
            await prefs.setInt('last_step_update', now.millisecondsSinceEpoch);

            debugPrint('👟 خطوات محدثة: $newSteps');
            await _updateServiceNotification(service, 'steps', newSteps);
            await _checkStepMilestones(newSteps);
          }
        } catch (e) {
          debugPrint('❌ خطأ في معالجة الخطوات: $e');
        }
      },
      onError: (error) => debugPrint('❌ خطأ في stream الخطوات: $error'),
    );

    // 2. تتبع الحركة
    accelerometerSubscription = accelerometerEventStream().listen(
          (AccelerometerEvent event) async {
        try {
          await _processMovementDataEnhanced(event);

          if (_isNightTime() && !isSleepDetectionActive) {
            await _detectSleepConditions(event);
          }
        } catch (e) {
          debugPrint('❌ خطأ في معالجة الحركة: $e');
        }
      },
      onError: (error) => debugPrint('❌ خطأ في accelerometer: $error'),
    );

    // 3. تتبع البيئة
    try {
      lightSubscription = Light().lightSensorStream.listen(
            (int lightLevel) async {
          try {
            await _processEnvironmentalData(lightLevel);

            if (_isNightTime()) {
              await _analyzeSleepEnvironment(lightLevel);
            }
          } catch (e) {
            debugPrint('❌ خطأ في معالجة الضوء: $e');
          }
        },
        onError: (error) => debugPrint('❌ خطأ في حساس الضوء: $error'),
      );
    } catch (e) {
      debugPrint('⚠️ حساس الضوء غير متوفر: $e');
    }

    // 4. تتبع الموقع
    locationTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      try {
        final newPosition = await _getCurrentLocationSafe();
        if (newPosition != null) {
          lastPosition = newPosition;
          await _saveLocationDataEnhanced(newPosition);
          await prefs.setInt('last_location_update', DateTime.now().millisecondsSinceEpoch);
          debugPrint('📍 موقع محدث');
        }
      } catch (e) {
        debugPrint('❌ خطأ في تتبع الموقع: $e');
      }
    });

    // 5. حفظ البيانات الصحية
    healthTimer = Timer.periodic(const Duration(minutes: 3), (timer) async {
      try {
        await _savePeriodicHealthData();
        await _analyzeHealthTrends();
        await prefs.setInt('last_health_sync', DateTime.now().millisecondsSinceEpoch);
        debugPrint('💖 تحديث البيانات الصحية');
      } catch (e) {
        debugPrint('❌ خطأ في البيانات الصحية: $e');
      }
    });

    // 6. كشف النوم
    sleepDetectionTimer = Timer.periodic(const Duration(minutes: 2), (timer) async {
      try {
        if (_isNightTime()) {
          final sleepDetected = await _performAdvancedSleepDetection();
          if (sleepDetected && !isSleepDetectionActive) {
            await _startSleepSession();
            isSleepDetectionActive = true;
          }
        } else if (_isDayTime() && isSleepDetectionActive) {
          final wakeDetected = await _detectWakeUp();
          if (wakeDetected) {
            await _endSleepSession();
            isSleepDetectionActive = false;
          }
        }
      } catch (e) {
        debugPrint('❌ خطأ في كشف النوم: $e');
      }
    });

    // 7. إشعارات ذكية
    notificationTimer = Timer.periodic(const Duration(minutes: 30), (timer) async {
      try {
        await _sendContextualNotifications();
        debugPrint('📱 فحص الإشعارات الذكية');
      } catch (e) {
        debugPrint('❌ خطأ في الإشعارات: $e');
      }
    });

    // 8. الاستماع لأوامر التحكم
    service.on('stop').listen((event) async {
      debugPrint('⏹️ إيقاف الخدمة...');

      await stepSubscription?.cancel();
      await accelerometerSubscription?.cancel();
      await lightSubscription?.cancel();

      healthTimer?.cancel();
      locationTimer?.cancel();
      notificationTimer?.cancel();
      sleepDetectionTimer?.cancel();

      await _savePeriodicHealthData();
      service.stopSelf();
    });

    debugPrint('✅ جميع مكونات الخدمة المحسنة تعمل');

  } catch (e) {
    debugPrint('❌ خطأ في الخدمة المستمرة: $e');
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  debugPrint('📱 iOS background processing');

  try {
    await _performQuickHealthUpdate();
    await _savePeriodicHealthData();
    return true;
  } catch (e) {
    debugPrint('❌ خطأ في iOS background: $e');
    return false;
  }
}

// ═══════════════════════════════════════════════════════════════
// Helper Functions
// ═══════════════════════════════════════════════════════════════

Future<void> _saveStepDataEnhanced(int steps, DateTime timestamp) async {
  try {
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;

    final today = _formatDate(timestamp);
    final distance = steps * 0.0007;
    final calories = steps / 20.0;

    await db.insert('daily_activity', {
      'date': today,
      'total_steps': steps,
      'distance': distance,
      'calories': calories,
      'activity_type': 'walking',
      'intensity_score': _calculateIntensityScore(steps),
      'updated_at': timestamp.millisecondsSinceEpoch,
      'created_at': timestamp.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('steps_today', steps);
    await prefs.setDouble('distance_today', distance);
    await prefs.setDouble('calories_today', calories);

  } catch (e) {
    debugPrint('❌ خطأ في حفظ بيانات الخطوات: $e');
  }
}

double _calculateIntensityScore(int steps) {
  if (steps < 2000) return 0.2;
  if (steps < 5000) return 0.4;
  if (steps < 8000) return 0.6;
  if (steps < 10000) return 0.8;
  return 1.0;
}

Future<void> _saveLocationDataEnhanced(Position position) async {
  try {
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;

    await db.insert('location_visits', {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'altitude': position.altitude,
      'arrival_time': DateTime.now().millisecondsSinceEpoch,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });

    await _analyzeLocationContext(position);

  } catch (e) {
    debugPrint('❌ خطأ في حفظ بيانات الموقع: $e');
  }
}

Future<void> _analyzeLocationContext(Position position) async {
  try {
    final prefs = await SharedPreferences.getInstance();

    final homeLat = prefs.getDouble('home_latitude') ?? 0.0;
    final homeLng = prefs.getDouble('home_longitude') ?? 0.0;

    if (homeLat != 0.0 && homeLng != 0.0) {
      final distance = Geolocator.distanceBetween(
          homeLat, homeLng, position.latitude, position.longitude);

      if (distance < 100) {
        await prefs.setString('current_location_context', 'home');
      } else {
        await prefs.setString('current_location_context', 'away');
      }
    }
  } catch (e) {
    debugPrint('❌ خطأ في تحليل سياق الموقع: $e');
  }
}

Future<void> _processMovementDataEnhanced(AccelerometerEvent event) async {
  try {
    final magnitude = (event.x * event.x + event.y * event.y + event.z * event.z);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('last_movement_intensity', magnitude);
    await prefs.setInt('last_movement_time', DateTime.now().millisecondsSinceEpoch);

    // أخبر SleepProvider
    await prefs.setDouble('bg_last_movement', magnitude);
    await prefs.setInt('bg_last_movement_time', DateTime.now().millisecondsSinceEpoch);

    await _analyzeMovementPattern(magnitude);

  } catch (e) {
    debugPrint('❌ خطأ في معالجة بيانات الحركة: $e');
  }
}

Future<void> _analyzeMovementPattern(double magnitude) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final movements = prefs.getStringList('recent_movements') ?? [];

    movements.add('${magnitude.toStringAsFixed(2)}-${DateTime.now().millisecondsSinceEpoch}');

    if (movements.length > 20) {
      movements.removeAt(0);
    }

    await prefs.setStringList('recent_movements', movements);

    String activityType = 'still';
    if (magnitude > 15) {
      activityType = 'running';
    } else if (magnitude > 5) {
      activityType = 'walking';
    }

    await prefs.setString('current_activity', activityType);

  } catch (e) {
    debugPrint('❌ خطأ في تحليل نمط الحركة: $e');
  }
}

Future<void> _processEnvironmentalData(int lightLevel) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_light_level', lightLevel);
    await prefs.setInt('last_environmental_update', DateTime.now().millisecondsSinceEpoch);

    // أخبر SleepProvider
    await prefs.setInt('bg_last_light', lightLevel);
    await prefs.setInt('bg_last_light_time', DateTime.now().millisecondsSinceEpoch);

    if (lightLevel < 10 && _isNightTime()) {
      await prefs.setBool('sleep_friendly_environment', true);
    } else {
      await prefs.setBool('sleep_friendly_environment', false);
    }

  } catch (e) {
    debugPrint('❌ خطأ في معالجة البيانات البيئية: $e');
  }
}

Future<void> _detectSleepConditions(AccelerometerEvent event) async {
  try {
    final magnitude = (event.x * event.x + event.y * event.y + event.z * event.z);
    final prefs = await SharedPreferences.getInstance();

    if (magnitude < 2.0) {
      final stillCount = prefs.getInt('still_count') ?? 0;
      await prefs.setInt('still_count', stillCount + 1);

      if (stillCount > 300) {
        await prefs.setBool('possible_sleep_detected', true);
      }
    } else {
      await prefs.setInt('still_count', 0);
      await prefs.setBool('possible_sleep_detected', false);
    }

  } catch (e) {
    debugPrint('❌ خطأ في كشف حالات النوم: $e');
  }
}

Future<void> _analyzeSleepEnvironment(int lightLevel) async {
  try {
    final prefs = await SharedPreferences.getInstance();

    int sleepScore = 0;

    if (lightLevel < 5) sleepScore += 30;
    else if (lightLevel < 15) sleepScore += 20;

    final currentActivity = prefs.getString('current_activity') ?? 'still';
    if (currentActivity == 'still') sleepScore += 40;

    final locationContext = prefs.getString('current_location_context') ?? '';
    if (locationContext == 'home') sleepScore += 30;

    await prefs.setInt('sleep_environment_score', sleepScore);

  } catch (e) {
    debugPrint('❌ خطأ في تحليل بيئة النوم: $e');
  }
}

Future<Position?> _getCurrentLocationSafe() async {
  try {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 10),
    );
  } catch (e) {
    debugPrint('❌ خطأ في الحصول على الموقع: $e');
    return null;
  }
}

Future<void> _savePeriodicHealthData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    final stepsToday = prefs.getInt('steps_today') ?? 0;
    final distanceToday = prefs.getDouble('distance_today') ?? 0.0;
    final caloriesToday = prefs.getDouble('calories_today') ?? 0.0;
    final currentActivity = prefs.getString('current_activity') ?? 'still';
    final sleepScore = prefs.getInt('sleep_environment_score') ?? 0;

    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;

    final tableExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='health_snapshots'");

    if (tableExists.isEmpty) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS health_snapshots (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          timestamp INTEGER NOT NULL,
          steps INTEGER DEFAULT 0,
          distance REAL DEFAULT 0.0,
          calories REAL DEFAULT 0.0,
          activity TEXT,
          sleep_score INTEGER DEFAULT 0,
          created_at INTEGER NOT NULL
        )
      ''');
    }

    await db.insert('health_snapshots', {
      'timestamp': now.millisecondsSinceEpoch,
      'steps': stepsToday,
      'distance': distanceToday,
      'calories': caloriesToday,
      'activity': currentActivity,
      'sleep_score': sleepScore,
      'created_at': now.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

  } catch (e) {
    debugPrint('❌ خطأ في حفظ البيانات الصحية: $e');
  }
}

Future<void> _analyzeHealthTrends() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final stepsToday = prefs.getInt('steps_today') ?? 0;

    final yesterdaySteps = prefs.getInt('yesterday_steps') ?? 0;
    final improvement = stepsToday - yesterdaySteps;

    await prefs.setInt('steps_improvement', improvement);

    final weeklySteps = prefs.getStringList('weekly_steps') ?? [];
    weeklySteps.add(stepsToday.toString());

    if (weeklySteps.length > 7) {
      weeklySteps.removeAt(0);
    }

    await prefs.setStringList('weekly_steps', weeklySteps);

  } catch (e) {
    debugPrint('❌ خطأ في تحليل الاتجاهات: $e');
  }
}

Future<void> _performQuickHealthUpdate() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_health_update', DateTime.now().millisecondsSinceEpoch);

    final stepsToday = prefs.getInt('steps_today') ?? 0;
    final targetSteps = 8000;

    final progress = (stepsToday / targetSteps * 100).clamp(0, 100);
    await prefs.setDouble('daily_progress', progress.toDouble());

  } catch (e) {
    debugPrint('❌ خطأ في التحديث السريع: $e');
  }
}

Future<bool> _performAdvancedSleepDetection() async {
  try {
    final prefs = await SharedPreferences.getInstance();

    final possibleSleep = prefs.getBool('possible_sleep_detected') ?? false;
    final sleepEnvironmentScore = prefs.getInt('sleep_environment_score') ?? 0;
    final lightLevel = prefs.getInt('current_light_level') ?? 100;
    final locationContext = prefs.getString('current_location_context') ?? '';

    int sleepIndicators = 0;

    if (possibleSleep) sleepIndicators += 3;
    if (sleepEnvironmentScore > 70) sleepIndicators += 2;
    if (lightLevel < 10) sleepIndicators += 2;
    if (locationContext == 'home') sleepIndicators += 2;
    if (_isNightTime()) sleepIndicators += 1;

    return sleepIndicators >= 5;

  } catch (e) {
    debugPrint('❌ خطأ في كشف النوم المتقدم: $e');
    return false;
  }
}

Future<bool> _detectWakeUp() async {
  try {
    final prefs = await SharedPreferences.getInstance();

    final lastMovementIntensity = prefs.getDouble('last_movement_intensity') ?? 0.0;
    final lightLevel = prefs.getInt('current_light_level') ?? 0;
    final currentActivity = prefs.getString('current_activity') ?? 'still';

    int wakeIndicators = 0;

    if (lastMovementIntensity > 10) wakeIndicators += 2;
    if (lightLevel > 50) wakeIndicators += 2;
    if (currentActivity != 'still') wakeIndicators += 2;
    if (_isDayTime()) wakeIndicators += 1;

    return wakeIndicators >= 4;

  } catch (e) {
    debugPrint('❌ خطأ في كشف الاستيقاظ: $e');
    return false;
  }
}

// ═══════════════════════════════════════════════════════════════
// Sleep Session Management - ✅ مع فحص 12 ساعة
// ═══════════════════════════════════════════════════════════════

Future<void> _startSleepSession() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    final existingSessionId = prefs.getInt('active_sleep_session_id');

    if (existingSessionId != null) {
      final createdAt = prefs.getInt('active_session_created_at');
      final startTime = prefs.getInt('sleep_start_time');

      debugPrint('⚠️ جلسة نشطة موجودة: ID=$existingSessionId');

      if (createdAt != null) {
        final created = DateTime.fromMillisecondsSinceEpoch(createdAt);
        final age = now.difference(created);

        debugPrint('📅 تاريخ الإنشاء: ${_formatDateTime(created)}');
        debugPrint('⏱️ العمر: ${age.inHours}h ${age.inMinutes % 60}m');

        if (age.inHours < 12) {
          debugPrint('✅ جلسة مستمرة (< 12 ساعة)');
          return;
        } else {
          debugPrint('⚠️ جلسة قديمة جداً (${age.inHours}h)');
          final start = startTime != null
              ? DateTime.fromMillisecondsSinceEpoch(startTime)
              : created;
          await _endOldSession(existingSessionId, start, now);
        }
      } else if (startTime != null) {
        final start = DateTime.fromMillisecondsSinceEpoch(startTime);
        final age = now.difference(start);
        if (age.inHours < 12) {
          debugPrint('✅ جلسة مستمرة');
          return;
        } else {
          await _endOldSession(existingSessionId, start, now);
        }
      } else {
        debugPrint('❌ بيانات تالفة');
        await _cleanupBrokenSession(existingSessionId);
      }
    }

    await _createNewSession(prefs, now);

  } catch (e) {
    debugPrint('❌ خطأ في بدء جلسة النوم: $e');
  }
}

Future<void> _endOldSession(int sessionId, DateTime start, DateTime end) async {
  try {
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;

    final duration = end.difference(start);
    final hours = duration.inMinutes / 60.0;

    await db.update(
      'sleep_sessions',
      {
        'end_time': end.millisecondsSinceEpoch,
        'duration': duration.inMilliseconds,
        'is_completed': 1,
        'quality_score': _calculateSleepQuality(hours),
        'updated_at': end.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_sleep_session_id');
    await prefs.remove('sleep_start_time');
    await prefs.setBool('is_sleeping', false);

    debugPrint('✅ تم إنهاء الجلسة القديمة: ID=$sessionId (${hours.toStringAsFixed(1)}h)');

  } catch (e) {
    debugPrint('❌ خطأ في إنهاء الجلسة القديمة: $e');
  }
}

Future<void> _createNewSession(SharedPreferences prefs, DateTime now) async {
  try {
    await prefs.setInt('sleep_start_time', now.millisecondsSinceEpoch);
    await prefs.setBool('is_sleeping', true);
    await prefs.setInt('active_session_created_at', now.millisecondsSinceEpoch);

    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;

    final sessionId = await db.insert('sleep_sessions', {
      'start_time': now.millisecondsSinceEpoch,
      'is_completed': 0,
      'sleep_type': 'automatic',
      'created_at': now.millisecondsSinceEpoch,
      'updated_at': now.millisecondsSinceEpoch,
    });

    await prefs.setInt('active_sleep_session_id', sessionId);
    await prefs.setBool('bg_sleep_detected', true);
    await prefs.setInt('bg_sleep_detected_time', now.millisecondsSinceEpoch);

    debugPrint('😴 بدء جلسة نوم جديدة: ${now.hour}:${now.minute}');
    debugPrint('💾 Session ID: $sessionId');

    await _sendSleepStartNotification();

  } catch (e) {
    debugPrint('❌ خطأ في إنشاء جلسة جديدة: $e');
  }
}

Future<void> _endSleepSession() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final sleepStartTime = prefs.getInt('sleep_start_time');
    final sessionId = prefs.getInt('active_sleep_session_id');

    if (sleepStartTime != null) {
      final start = DateTime.fromMillisecondsSinceEpoch(sleepStartTime);
      final sleepDuration = now.difference(start);
      final sleepHours = sleepDuration.inMinutes / 60;

      if (sessionId != null) {
        final dbHelper = DatabaseHelper.instance;
        final db = await dbHelper.database;

        await db.update(
          'sleep_sessions',
          {
            'end_time': now.millisecondsSinceEpoch,
            'duration': sleepDuration.inMilliseconds,
            'is_completed': 1,
            'quality_score': _calculateSleepQuality(sleepHours),
            'updated_at': now.millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [sessionId],
        );
      }

      await prefs.remove('active_sleep_session_id');
      await prefs.setBool('bg_wake_detected', true);
      await prefs.setInt('bg_wake_detected_time', now.millisecondsSinceEpoch);

      await _sendSleepEndNotification(sleepHours);

      await prefs.remove('sleep_start_time');
      await prefs.setBool('is_sleeping', false);

      debugPrint('🌅 انتهت جلسة النوم: ${sleepHours.toStringAsFixed(1)} ساعة');
    }
  } catch (e) {
    debugPrint('❌ خطأ في إنهاء جلسة النوم: $e');
  }
}

Future<void> _cleanupBrokenSession(int sessionId) async {
  try {
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;

    await db.delete('sleep_sessions', where: 'id = ?', whereArgs: [sessionId]);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_sleep_session_id');
    await prefs.remove('active_session_created_at');
    await prefs.remove('sleep_start_time');
    await prefs.setBool('is_sleeping', false);

    debugPrint('🗑️ تم حذف الجلسة التالفة: ID=$sessionId');
  } catch (e) {
    debugPrint('❌ خطأ في التنظيف: $e');
  }
}

double _calculateSleepQuality(double duration) {
  if (duration >= 7.0 && duration <= 9.0) return 9.0;
  if (duration >= 6.0 && duration <= 10.0) return 7.0;
  if (duration >= 5.0 && duration <= 11.0) return 5.0;
  return 3.0;
}

// ═══════════════════════════════════════════════════════════════
// Additional Helper Functions
// ═══════════════════════════════════════════════════════════════

Future<void> _processCachedSensorData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final movements = prefs.getStringList('recent_movements') ?? [];
    if (movements.isNotEmpty) {
      await _analyzeActivityPatterns(movements);
    }
  } catch (e) {
    debugPrint('❌ خطأ في معالجة البيانات المخزنة: $e');
  }
}

Future<void> _analyzeActivityPatterns(List<String> movements) async {
  try {
    int stillPeriods = 0;
    int activePeriods = 0;

    for (final movement in movements) {
      final parts = movement.split('-');
      if (parts.length == 2) {
        final magnitude = double.tryParse(parts[0]) ?? 0.0;
        if (magnitude < 2.0) {
          stillPeriods++;
        } else {
          activePeriods++;
        }
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('still_periods', stillPeriods);
    await prefs.setInt('active_periods', activePeriods);

  } catch (e) {
    debugPrint('❌ خطأ في تحليل أنماط النشاط: $e');
  }
}

Future<void> _analyzeEnvironmentalConditions() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final lightLevel = prefs.getInt('current_light_level') ?? 50;

    String environmentState = 'normal';
    if (lightLevel < 10) {
      environmentState = 'dark';
    } else if (lightLevel > 500) {
      environmentState = 'bright';
    }

    await prefs.setString('environment_state', environmentState);

  } catch (e) {
    debugPrint('❌ خطأ في تحليل الظروف البيئية: $e');
  }
}

Future<void> _handleSleepDetection() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final isSleeping = prefs.getBool('is_sleeping') ?? false;

    if (!isSleeping) {
      await _startSleepSession();
    }

  } catch (e) {
    debugPrint('❌ خطأ في معالجة كشف النوم: $e');
  }
}

Future<void> _sendContextualNotifications() async {
  try {
    final hour = DateTime.now().hour;

    if (hour == 8) {
      await _sendMorningMotivationNotification();
    } else if (hour == 12) {
      await _sendLunchReminderNotification();
    } else if (hour == 18) {
      await _sendEveningActivityNotification();
    } else if (hour == 22) {
      await _sendBedtimeReminderNotification();
    }

  } catch (e) {
    debugPrint('❌ خطأ في الإشعارات السياقية: $e');
  }
}

Future<void> _checkDailyGoals() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final stepsToday = prefs.getInt('steps_today') ?? 0;
    final targetSteps = 8000;

    if (stepsToday >= targetSteps) {
      final lastGoalNotification = prefs.getInt('last_goal_notification') ?? 0;
      final today = DateTime.now().day;

      if (DateTime.fromMillisecondsSinceEpoch(lastGoalNotification).day != today) {
        await _sendGoalAchievedNotification(stepsToday);
        await prefs.setInt('last_goal_notification', DateTime.now().millisecondsSinceEpoch);
      }
    }

  } catch (e) {
    debugPrint('❌ خطأ في فحص الأهداف: $e');
  }
}

Future<void> _sendMotivationalNotifications() async {
  try {
    final messages = [
      'استمر في التقدم! كل خطوة تحسب',
      'صحتك أولوية - امش قليلاً اليوم',
      'هدفك قريب، لا تتوقف الآن',
      'الرياضة اليومية تحسن المزاج',
    ];

    final randomMessage = messages[DateTime.now().minute % messages.length];
    await _sendNotification('تحفيز يومي', randomMessage);

  } catch (e) {
    debugPrint('❌ خطأ في إرسال إشعارات التحفيز: $e');
  }
}

// ═══════════════════════════════════════════════════════════════
// Notification Functions
// ═══════════════════════════════════════════════════════════════

Future<void> _checkStepMilestones(int steps) async {
  try {
    final milestones = [2000, 5000, 8000, 10000, 12000, 15000];

    for (final milestone in milestones) {
      if (steps == milestone) {
        await _sendStepMilestoneNotification(milestone);
        break;
      }
    }
  } catch (e) {
    debugPrint('❌ خطأ في فحص إنجازات الخطوات: $e');
  }
}

Future<void> _sendStepMilestoneNotification(int steps) async {
  String message;
  switch (steps) {
    case 2000:
      message = 'بداية رائعة! وصلت لـ 2000 خطوة';
      break;
    case 5000:
      message = 'نصف الطريق! 5000 خطوة محققة';
      break;
    case 8000:
      message = 'ممتاز! 8000 خطوة - هدف صحي رائع';
      break;
    case 10000:
      message = 'هدف الـ 10000 خطوة محقق! أحسنت';
      break;
    case 12000:
      message = 'إنجاز فوق العادة! 12000 خطوة';
      break;
    case 15000:
      message = 'نشاط استثنائي! 15000 خطوة اليوم';
      break;
    default:
      message = 'إنجاز رائع في الخطوات!';
  }

  await _sendNotification('🎯 إنجاز جديد', message);
}

Future<void> _sendSleepStartNotification() async {
  await _sendNotification(
      '😴 وقت النوم',
      'تم اكتشاف بداية النوم. نوماً هنيئاً!'
  );
}

Future<void> _sendSleepEndNotification(double hours) async {
  final hoursInt = hours.floor();
  final minutes = ((hours - hoursInt) * 60).round();

  String message;
  if (hours >= 7 && hours <= 9) {
    message = 'صباح الخير! نمت ${hoursInt}س ${minutes}د - مدة مثالية';
  } else if (hours < 6) {
    message = 'صباح الخير! نمت ${hoursInt}س ${minutes}د - حاول النوم مبكراً الليلة';
  } else {
    message = 'صباح الخير! نمت ${hoursInt}س ${minutes}د - كيف تشعر اليوم؟';
  }

  await _sendNotification('☀️ صباح الخير', message);
}

Future<void> _sendMorningMotivationNotification() async {
  final messages = [
    'صباح الخير! ابدأ يومك بنشاط وحيوية',
    'يوم جديد، فرص جديدة للتحسن',
    'صباح مليء بالطاقة الإيجابية',
    'ابدأ بخطوة صغيرة نحو هدفك',
  ];

  final message = messages[DateTime.now().day % messages.length];
  await _sendNotification('🌅 صباح الخير', message);
}

Future<void> _sendLunchReminderNotification() async {
  await _sendNotification(
      '🍽️ وقت الغداء',
      'لا تنس وجبة صحية ومتوازنة'
  );
}

Future<void> _sendEveningActivityNotification() async {
  final prefs = await SharedPreferences.getInstance();
  final stepsToday = prefs.getInt('steps_today') ?? 0;

  if (stepsToday < 6000) {
    await _sendNotification(
        '🚶‍♂️ وقت الحركة',
        'مساء رائع للمشي وزيادة نشاطك اليومي'
    );
  }
}

Future<void> _sendBedtimeReminderNotification() async {
  await _sendNotification(
      '🌙 وقت الاستعداد للنوم',
      'ابدأ بالاسترخاء لنوم صحي ومريح'
  );
}

Future<void> _sendGoalAchievedNotification(int steps) async {
  await _sendNotification(
      '🏆 هدف محقق!',
      'رائع! حققت ${steps} خطوة اليوم'
  );
}

Future<void> _sendAppUnusedNotification(int days) async {
  String message;
  if (days == 3) {
    message = 'نفتقدك! لم نراك منذ 3 أيام. كيف حالك؟';
  } else if (days <= 7) {
    message = 'تذكير ودي - مضى ${days} أيام. صحتك مهمة!';
  } else {
    message = 'عودة قوية! وقت طويل - دعنا نبدأ من جديد';
  }

  await _sendNotification('👋 نفتقدك', message);
}

Future<void> _sendDailyCheckInNotification() async {
  await _sendNotification(
      '📝 تسجيل يومي',
      'كيف مزاجك اليوم؟ سجل حالتك معنا'
  );
}

Future<void> _sendNotification(String title, String message) async {
  try {
    final notificationService = NotificationService.instance;
    await notificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: message,
      channelId: 'smart_psych_background',
    );
  } catch (e) {
    debugPrint('❌ خطأ في إرسال الإشعار: $e');
  }
}

Future<void> _updateServiceNotification(ServiceInstance service, String type, dynamic value) async {
  try {
    final notificationService = NotificationService.instance;

    if (type == 'steps' && value is int) {
      final distance = (value * 0.0007).toStringAsFixed(1);
      final calories = (value / 20.0).round();

      await notificationService.showBackgroundServiceNotification(
        id: 888,
        title: 'Smart Psych نشط',
        body: '$value خطوة • ${distance} كم • $calories سعرة',
      );
    }

  } catch (e) {
    debugPrint('❌ خطأ في تحديث إشعار الخدمة: $e');
  }
}

// ═══════════════════════════════════════════════════════════════
// Utility Functions
// ═══════════════════════════════════════════════════════════════

bool _isNightTime() {
  final hour = DateTime.now().hour;
  return hour >= 22 || hour <= 6;
}

bool _isDayTime() {
  final hour = DateTime.now().hour;
  return hour >= 7 && hour <= 21;
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _formatDateTime(DateTime dt) {
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}