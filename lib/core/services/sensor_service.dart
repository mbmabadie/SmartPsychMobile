// lib/core/services/sensor_service_fixed.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:light/light.dart';
import 'package:permission_handler/permission_handler.dart';

import '../database/models/activity_models.dart';
import '../database/models/common_models.dart';
import '../database/models/environmental_conditions.dart';
import '../database/models/sleep_models.dart';
import '../database/repositories/settings_repository.dart';
import '../providers/sleep_tracking_provider.dart';
import 'step_counting_engine.dart';

class SensorService {
  static final SensorService _instance = SensorService._internal();
  factory SensorService() => _instance;
  SensorService._internal();

  static SensorService get instance => _instance;

  final SettingsRepository _settingsRepo = SettingsRepository();
  final StepCountingEngine _stepCounter = StepCountingEngine.instance;

  // Stream Controllers
  final StreamController<SensorData> _sensorDataController =
  StreamController<SensorData>.broadcast();
  final StreamController<EnvironmentalConditions> _environmentalController =
  StreamController<EnvironmentalConditions>.broadcast();

  // Subscriptions
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<int>? _lightSubscription;
  Timer? _processingTimer;

  // State variables
  bool _isListening = false;
  bool _isInitialized = false;
  DateTime? _lastSensorUpdate;

  // Data buffers
  final List<AccelerometerEvent> _accelerometerBuffer = [];
  final List<GyroscopeEvent> _gyroscopeBuffer = [];
  final List<int> _lightBuffer = [];

  // Configuration constants
  static const int _bufferSize = 50;
  static const Duration _updateInterval = Duration(seconds: 5);

  // Getters
  Stream<SensorData> get sensorDataStream => _sensorDataController.stream;
  Stream<EnvironmentalConditions> get environmentalStream => _environmentalController.stream;
  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  StepCountingEngine get stepCounter => _stepCounter;

  /// تهيئة الحساسات مع طلب الصلاحيات
  Future<bool> initialize() async {
    if (_isInitialized) {
      debugPrint('✅ الحساسات مهيأة مسبقاً');
      return true;
    }

    try {
      debugPrint('🚀 بدء تهيئة الحساسات...');

      // 1. طلب الصلاحيات المطلوبة
      final permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        debugPrint('❌ لم يتم منح الصلاحيات المطلوبة');
        return false;
      }

      // 2. تهيئة عداد الخطوات
      await _initializeStepCounter();

      // 3. تهيئة الحساسات
      await _initializeSensors();

      _isInitialized = true;
      debugPrint('✅ تم تهيئة الحساسات بنجاح');
      return true;

    } catch (e) {
      debugPrint('❌ خطأ في تهيئة الحساسات: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// طلب الصلاحيات المطلوبة
  Future<bool> _requestPermissions() async {
    try {
      debugPrint('🔐 طلب صلاحيات الحساسات...');

      // صلاحيات أساسية
      final permissions = [
        Permission.sensors,
        Permission.activityRecognition,
      ];

      // طلب الصلاحيات
      Map<Permission, PermissionStatus> statuses = await permissions.request();

      bool allGranted = true;
      for (var permission in permissions) {
        final status = statuses[permission] ?? PermissionStatus.denied;
        debugPrint('📋 ${permission.toString()}: $status');

        if (!status.isGranted) {
          allGranted = false;
        }
      }

      if (allGranted) {
        debugPrint('✅ تم منح جميع الصلاحيات');
      } else {
        debugPrint('⚠️ لم يتم منح بعض الصلاحيات، سيتم المحاولة بالصلاحيات المتاحة');
      }

      return true; // نعود بـ true حتى مع عدم منح بعض الصلاحيات
    } catch (e) {
      debugPrint('❌ خطأ في طلب الصلاحيات: $e');
      return false;
    }
  }

  /// تهيئة عداد الخطوات
  Future<void> _initializeStepCounter() async {
    try {
      debugPrint('⚙️ تهيئة عداد الخطوات...');

      // تحميل إعدادات المستخدم
      final userHeight = await _settingsRepo.getSetting<double>('user_height', 170.0);
      final userWeight = await _settingsRepo.getSetting<double>('user_weight', 70.0);
      final sensitivity = await _settingsRepo.getSetting<double>('step_sensitivity', 1.0);

      // تهيئة عداد الخطوات
      _stepCounter.initialize(
        userHeight: userHeight,
        userWeight: userWeight,
        sensitivity: sensitivity,
      );

      debugPrint('✅ تم تهيئة عداد الخطوات');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة عداد الخطوات: $e');
    }
  }

  /// تهيئة الحساسات
  Future<void> _initializeSensors() async {
    try {
      debugPrint('📱 فحص توفر الحساسات...');

      // فحص Accelerometer
      bool hasAccelerometer = await _testAccelerometer();
      debugPrint('📊 Accelerometer متوفر: $hasAccelerometer');

      // فحص Gyroscope
      bool hasGyroscope = await _testGyroscope();
      debugPrint('🌀 Gyroscope متوفر: $hasGyroscope');

      if (!hasAccelerometer) {
        throw Exception('Accelerometer غير متوفر أو لا يعمل');
      }

      debugPrint('✅ تم فحص الحساسات بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة الحساسات: $e');
      rethrow;
    }
  }

  /// فحص توفر Accelerometer
  Future<bool> _testAccelerometer() async {
    try {
      final completer = Completer<bool>();
      StreamSubscription? subscription;

      // تعيين timeout
      Timer(const Duration(seconds: 3), () {
        if (!completer.isCompleted) {
          subscription?.cancel();
          completer.complete(false);
        }
      });

      subscription = accelerometerEventStream().listen(
            (AccelerometerEvent event) {
          if (!completer.isCompleted) {
            subscription?.cancel();
            debugPrint('📊 Accelerometer يعمل: x=${event.x.toStringAsFixed(2)}, y=${event.y.toStringAsFixed(2)}, z=${event.z.toStringAsFixed(2)}');
            completer.complete(true);
          }
        },
        onError: (error) {
          if (!completer.isCompleted) {
            subscription?.cancel();
            debugPrint('❌ خطأ في Accelerometer: $error');
            completer.complete(false);
          }
        },
      );

      return await completer.future;
    } catch (e) {
      debugPrint('❌ خطأ في فحص Accelerometer: $e');
      return false;
    }
  }

  /// فحص توفر Gyroscope
  Future<bool> _testGyroscope() async {
    try {
      final completer = Completer<bool>();
      StreamSubscription? subscription;

      Timer(const Duration(seconds: 2), () {
        if (!completer.isCompleted) {
          subscription?.cancel();
          completer.complete(false);
        }
      });

      subscription = gyroscopeEventStream().listen(
            (GyroscopeEvent event) {
          if (!completer.isCompleted) {
            subscription?.cancel();
            debugPrint('🌀 Gyroscope يعمل');
            completer.complete(true);
          }
        },
        onError: (error) {
          if (!completer.isCompleted) {
            subscription?.cancel();
            completer.complete(false);
          }
        },
      );

      return await completer.future;
    } catch (e) {
      debugPrint('⚠️ Gyroscope غير متوفر: $e');
      return false;
    }
  }

  /// بدء مراقبة الحساسات
  Future<bool> startListening() async {
    if (!_isInitialized) {
      debugPrint('❌ الحساسات غير مهيأة، جاري التهيئة...');
      final initialized = await initialize();
      if (!initialized) {
        return false;
      }
    }

    if (_isListening) {
      debugPrint('⚠️ مراقبة الحساسات نشطة بالفعل');
      return true;
    }

    try {
      debugPrint('🚀 بدء مراقبة الحساسات...');

      _clearBuffers();
      await _startAccelerometerMonitoring();
      await _startGyroscopeMonitoring();
      await _startLightMonitoring();
      _startProcessingTimer();

      _isListening = true;
      debugPrint('✅ تم بدء مراقبة الحساسات بنجاح');
      return true;

    } catch (e) {
      debugPrint('❌ خطأ في بدء مراقبة الحساسات: $e');
      await stopListening();
      return false;
    }
  }

  /// بدء مراقبة Accelerometer
  Future<void> _startAccelerometerMonitoring() async {
    try {
      debugPrint('📊 بدء مراقبة Accelerometer...');

      _accelerometerSubscription = accelerometerEventStream().listen(
            (AccelerometerEvent event) {
          _handleAccelerometerEvent(event);
        },
        onError: (e) {
          debugPrint('❌ خطأ في Accelerometer: $e');
          _restartAccelerometer();
        },
        onDone: () {
          debugPrint('🔚 انتهت مراقبة Accelerometer');
        },
      );

      debugPrint('✅ تم بدء مراقبة Accelerometer');
    } catch (e) {
      debugPrint('❌ فشل في بدء مراقبة Accelerometer: $e');
      rethrow;
    }
  }

  /// بدء مراقبة Gyroscope
  Future<void> _startGyroscopeMonitoring() async {
    try {
      debugPrint('🌀 بدء مراقبة Gyroscope...');

      _gyroscopeSubscription = gyroscopeEventStream().listen(
            (GyroscopeEvent event) {
          _handleGyroscopeEvent(event);
        },
        onError: (e) {
          debugPrint('⚠️ خطأ في Gyroscope (غير حرج): $e');
        },
        onDone: () {
          debugPrint('🔚 انتهت مراقبة Gyroscope');
        },
      );

      debugPrint('✅ تم بدء مراقبة Gyroscope');
    } catch (e) {
      debugPrint('⚠️ لا يمكن بدء مراقبة Gyroscope: $e');
      // لا نرمي خطأ لأن Gyroscope ليس حرجاً
    }
  }

  /// بدء مراقبة حساس الضوء
  Future<void> _startLightMonitoring() async {
    try {
      debugPrint('💡 بدء مراقبة حساس الضوء...');

      _lightSubscription = Light().lightSensorStream.listen(
            (int lightLevel) {
          _handleLightEvent(lightLevel);
        },
        onError: (e) {
          debugPrint('⚠️ خطأ في حساس الضوء (غير حرج): $e');
        },
        onDone: () {
          debugPrint('🔚 انتهت مراقبة حساس الضوء');
        },
      );

      debugPrint('✅ تم بدء مراقبة حساس الضوء');
    } catch (e) {
      debugPrint('⚠️ لا يمكن بدء مراقبة حساس الضوء: $e');
      // لا نرمي خطأ لأن حساس الضوء ليس حرجاً
    }
  }

  /// معالجة بيانات Accelerometer
  void _handleAccelerometerEvent(AccelerometerEvent event) {
    if (!_isListening) return;

    try {
      // إضافة للمخزن
      _accelerometerBuffer.add(event);
      if (_accelerometerBuffer.length > _bufferSize) {
        _accelerometerBuffer.removeAt(0);
      }

      // معالجة مع عداد الخطوات
      _stepCounter.processAccelerometerData(event);

      // إرسال بيانات الحساس
      _emitSensorData('accelerometer', event.x, event.y, event.z);

      // طباعة للتتبع (كل 20 قراءة)
      if (_accelerometerBuffer.length % 20 == 0) {
        final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
        debugPrint('📊 ACC: ${magnitude.toStringAsFixed(2)}, خطوات: ${_stepCounter.todaySteps}');
      }

    } catch (e) {
      debugPrint('❌ خطأ في معالجة Accelerometer: $e');
    }
  }

  /// معالجة بيانات Gyroscope
  void _handleGyroscopeEvent(GyroscopeEvent event) {
    if (!_isListening) return;

    try {
      _gyroscopeBuffer.add(event);
      if (_gyroscopeBuffer.length > _bufferSize) {
        _gyroscopeBuffer.removeAt(0);
      }

      _emitSensorData('gyroscope', event.x, event.y, event.z);
    } catch (e) {
      debugPrint('❌ خطأ في معالجة Gyroscope: $e');
    }
  }

  /// معالجة بيانات حساس الضوء
  void _handleLightEvent(int lightLevel) {
    if (!_isListening) return;

    try {
      _lightBuffer.add(lightLevel);
      if (_lightBuffer.length > _bufferSize) {
        _lightBuffer.removeAt(0);
      }

      _emitSensorData('light', lightLevel.toDouble(), null, null);
    } catch (e) {
      debugPrint('❌ خطأ في معالجة حساس الضوء: $e');
    }
  }

  /// إرسال بيانات الحساس
  void _emitSensorData(String sensorType, double? x, double? y, double? z) {
    try {
      final sensorData = SensorData(
        sensorType: sensorType,
        timestamp: DateTime.now(),
        valueX: x,
        valueY: y,
        valueZ: z,
        processed: false,
        createdAt: DateTime.now(),
      );

      if (!_sensorDataController.isClosed) {
        _sensorDataController.add(sensorData);
      }
    } catch (e) {
      debugPrint('❌ خطأ في إرسال بيانات الحساس: $e');
    }
  }

  /// بدء مؤقت المعالجة
  void _startProcessingTimer() {
    _processingTimer?.cancel();

    _processingTimer = Timer.periodic(_updateInterval, (timer) {
      if (_isListening) {
        _processEnvironmentalData();
        _printStepCounterStats();
      } else {
        timer.cancel();
      }
    });

    debugPrint('⏰ تم بدء مؤقت المعالجة');
  }

  /// طباعة إحصائيات عداد الخطوات
  void _printStepCounterStats() {
    try {
      final stats = _stepCounter.getStatistics();
      final todaySteps = stats['total_steps_today'] as int? ?? 0;
      final distance = (stats['total_distance_km'] as double? ?? 0.0);
      final calories = (stats['total_calories'] as double? ?? 0.0);
      final activity = stats['current_activity'] as String? ?? 'غير محدد';

      if (todaySteps > 0) {
        debugPrint('👟 خطوات: $todaySteps | مسافة: ${distance.toStringAsFixed(2)}km | سعرات: ${calories.round()} | نشاط: $activity');
      }
    } catch (e) {
      debugPrint('❌ خطأ في طباعة إحصائيات عداد الخطوات: $e');
    }
  }

  /// معالجة البيانات البيئية
  Future<void> _processEnvironmentalData() async {
    try {
      if (_accelerometerBuffer.isEmpty) return;

      final now = DateTime.now();
      if (_lastSensorUpdate != null &&
          now.difference(_lastSensorUpdate!) < _updateInterval) {
        return;
      }

      _lastSensorUpdate = now;

      final conditions = await _calculateEnvironmentalConditions();
      if (conditions != null && !_environmentalController.isClosed) {
        _environmentalController.add(conditions);
      }

    } catch (e) {
      debugPrint('❌ خطأ في معالجة البيانات البيئية: $e');
    }
  }


  String _getActivityTypeString(ActivityType activityType) {
    switch (activityType) {
      case ActivityType.still:
        return 'ثابت';
      case ActivityType.walking:
        return 'المشي';
      case ActivityType.running:
        return 'الجري';
      case ActivityType.cycling:
        return 'ركوب دراجة';
      case ActivityType.driving:
        return 'قيادة';
      case ActivityType.swimming:
        return 'السباحة';
      case ActivityType.yoga:
        return 'اليوغا';
      case ActivityType.weightLifting:
        return 'رفع الأثقال';
      case ActivityType.dancing:
        return 'الرقص';
      case ActivityType.climbing:
        return 'التسلق';
      case ActivityType.general:
        return 'نشاط عام';
      case ActivityType.unknown:
        return 'غير معروف';
      case ActivityType.other:
        return 'أخرى';
    }
  }

  Future<EnvironmentalConditions?> _calculateEnvironmentalConditions() async {
    try {
      final stepCounterStats = _stepCounter.getStatistics();
      final movementIntensity = stepCounterStats['movement_intensity'] as double? ?? 0.0;
      final currentActivity = _stepCounter.currentActivity;
      final stepCount = _stepCounter.todaySteps;
      final stepFrequency = _stepCounter.stepFrequency;
      final lightLevel = _calculateAverageLightLevel() ?? 0.0;
      final noiseLevel = 30.0; // افتراضي - يمكن تحديثه لاحقاً عند إضافة حساس الصوت

      return EnvironmentalConditions(
        timestamp: DateTime.now(),
        lightLevel: lightLevel,
        lightQuality: _evaluateLightQuality(lightLevel),
        noiseLevel: noiseLevel,
        noiseQuality: _evaluateNoiseQuality(noiseLevel),
        movementIntensity: movementIntensity,
        isOptimalForSleep: _checkIfOptimalForSleep(
          lightLevel: lightLevel,
          noiseLevel: noiseLevel,
          movementIntensity: movementIntensity,
        ),
        dataSource: DataSource.sensor,
        accuracy: 0.95,
        createdAt: DateTime.now(),
      );

    } catch (e) {
      debugPrint('❌ خطأ في حساب الظروف البيئية: $e');
      return null;
    }
  }

// دوال مساعدة للتقييم
  LightQuality _evaluateLightQuality(double lightLevel) {
    if (lightLevel <= 5) return LightQuality.optimal;
    if (lightLevel <= 15) return LightQuality.good;
    if (lightLevel <= 50) return LightQuality.fair;
    return LightQuality.poor;
  }

  NoiseQuality _evaluateNoiseQuality(double noiseLevel) {
    if (noiseLevel <= 30) return NoiseQuality.optimal;
    if (noiseLevel <= 40) return NoiseQuality.good;
    if (noiseLevel <= 60) return NoiseQuality.fair;
    return NoiseQuality.poor;
  }

  bool _checkIfOptimalForSleep({
    required double lightLevel,
    required double noiseLevel,
    required double movementIntensity,
  }) {
    return lightLevel <= 10 &&
        noiseLevel <= 40 &&
        movementIntensity <= 0.1;
  }



  /// حساب متوسط مستوى الضوء
  double? _calculateAverageLightLevel() {
    if (_lightBuffer.isEmpty) return null;
    final sum = _lightBuffer.reduce((a, b) => a + b);
    return (sum / _lightBuffer.length).toDouble();
  }

  /// إعادة تشغيل Accelerometer
  Future<void> _restartAccelerometer() async {
    try {
      debugPrint('🔄 إعادة تشغيل Accelerometer...');

      await Future.delayed(const Duration(seconds: 2));

      if (_isListening && _accelerometerSubscription == null) {
        await _startAccelerometerMonitoring();
      }
    } catch (e) {
      debugPrint('❌ فشل في إعادة تشغيل Accelerometer: $e');
    }
  }

  /// إيقاف مراقبة الحساسات
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      debugPrint('⏹️ إيقاف مراقبة الحساسات...');

      await _accelerometerSubscription?.cancel();
      await _gyroscopeSubscription?.cancel();
      await _lightSubscription?.cancel();

      _accelerometerSubscription = null;
      _gyroscopeSubscription = null;
      _lightSubscription = null;

      _processingTimer?.cancel();
      _processingTimer = null;

      _clearBuffers();
      _isListening = false;

      debugPrint('✅ تم إيقاف مراقبة الحساسات');
    } catch (e) {
      debugPrint('❌ خطأ في إيقاف مراقبة الحساسات: $e');
    }
  }

  /// تنظيف المخازن
  void _clearBuffers() {
    _accelerometerBuffer.clear();
    _gyroscopeBuffer.clear();
    _lightBuffer.clear();
  }

  /// الحصول على الظروف الحالية
  Future<EnvironmentalConditions?> getCurrentConditions() async {
    if (!_isListening) {
      debugPrint('⚠️ الحساسات غير نشطة');
      return null;
    }
    return await _calculateEnvironmentalConditions();
  }

  /// الحصول على إحصائيات النشاط
  Map<String, dynamic> getActivityStatistics() {
    return _stepCounter.getStatistics();
  }

  /// معايرة عداد الخطوات
  Future<void> calibrateStepCounter(int expectedSteps, int detectedSteps) async {
    _stepCounter.calibrateSensitivity(expectedSteps, detectedSteps);

    final newSensitivity = _stepCounter.sensitivity;
    await _settingsRepo.setSetting('step_sensitivity', newSensitivity, SettingValueType.double);

    debugPrint('⚙️ تم تحديث حساسية عداد الخطوات: $newSensitivity');
  }

  /// تحديث ملف المستخدم
  Future<void> updateUserProfile(double height, double weight) async {
    _stepCounter.initialize(userHeight: height, userWeight: weight);

    await _settingsRepo.setSetting('user_height', height, SettingValueType.double);
    await _settingsRepo.setSetting('user_weight', weight, SettingValueType.double);

    debugPrint('👤 تم تحديث ملف المستخدم: الطول=$height, الوزن=$weight');
  }

  /// التخلص من الموارد
  Future<void> dispose() async {
    try {
      await stopListening();

      if (!_sensorDataController.isClosed) {
        await _sensorDataController.close();
      }

      if (!_environmentalController.isClosed) {
        await _environmentalController.close();
      }

      debugPrint('🗑️ تم التخلص من خدمة الحساسات');
    } catch (e) {
      debugPrint('❌ خطأ في التخلص من خدمة الحساسات: $e');
    }
  }

  /// إعادة تعيين عداد الخطوات
  void resetStepCounter() {
    _stepCounter.reset();
    debugPrint('🔄 تم إعادة تعيين عداد الخطوات');
  }

  /// فحص حالة النظام
  Map<String, dynamic> getSystemStatus() {
    return {
      'is_initialized': _isInitialized,
      'is_listening': _isListening,
      'accelerometer_active': _accelerometerSubscription != null,
      'gyroscope_active': _gyroscopeSubscription != null,
      'light_sensor_active': _lightSubscription != null,
      'step_counter_stats': _stepCounter.getStatistics(),
      'buffer_sizes': {
        'accelerometer': _accelerometerBuffer.length,
        'gyroscope': _gyroscopeBuffer.length,
        'light': _lightBuffer.length,
      },
      'last_sensor_update': _lastSensorUpdate?.toIso8601String(),
    };
  }
}