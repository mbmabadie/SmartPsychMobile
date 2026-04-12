// lib/core/services/unified_tracking_service.dart - مع حفظ في Database

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../database/repositories/activity_repository.dart';
import '../services/user_settings_service.dart';

class UnifiedTrackingService {
  static final UnifiedTrackingService _instance = UnifiedTrackingService._internal();
  static UnifiedTrackingService get instance => _instance;

  UnifiedTrackingService._internal();

  // ✅ إضافة ActivityRepository
  final ActivityRepository _activityRepo = ActivityRepository();
  final UserSettingsService _userSettings = UserSettingsService.instance; // ✅ إضافة

  bool _isInitialized = false;
  bool _isTracking = false;
  bool get isInitialized => _isInitialized;
  bool get isTracking => _isTracking;

  final _dataStreamController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get dataStream => _dataStreamController.stream;

  int _currentSteps = 0;
  double _currentDistance = 0.0;
  double _currentCalories = 0.0;

  StreamSubscription<StepCount>? _stepCountSubscription;
  int _systemSteps = 0;
  int _baselineSteps = 0;
  String _currentDate = '';
  bool _pedometerActive = false;

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  bool _sensorsActive = false;
  int _sensorSteps = 0;
  int _sensorBaseline = 0;
  DateTime? _lastStepTime;

  Timer? _syncTimer;
  Timer? _databaseSyncTimer; // ← جديد للـ database
  DateTime? _lastUpdate;
  DateTime? _lastDatabaseSync; // ← تتبع آخر حفظ في database

  int _lastBroadcastedSteps = -1;

  Future<bool> initialize() async {
    if (_isInitialized) {
      debugPrint('⚠️ [UnifiedService] الخدمة مُهيأة مسبقاً');
      return true;
    }

    try {
      debugPrint('🚀 [UnifiedService] بدء التهيئة...');

      final activityGranted = await Permission.activityRecognition.isGranted;
      final sensorsGranted = await Permission.sensors.isGranted;

      debugPrint('📱 [UnifiedService] Activity: $activityGranted, Sensors: $sensorsGranted');

      if (!activityGranted || !sensorsGranted) {
        debugPrint('❌ [UnifiedService] الأذونات مفقودة');
        return false;
      }

      _currentDate = _formatDate(DateTime.now());
      await _loadSavedData();

      _isInitialized = true;
      debugPrint('✅ [UnifiedService] تم التهيئة');
      return true;

    } catch (e) {
      debugPrint('❌ [UnifiedService] خطأ في التهيئة: $e');
      return false;
    }
  }

  Future<bool> startTracking() async {
    debugPrint('📱 [UnifiedService] startTracking() called');

    if (!_isInitialized) await initialize();
    if (_isTracking) {
      debugPrint('⚠️ [UnifiedService] التتبع نشط مسبقاً');
      return true;
    }

    try {
      debugPrint('▶️ [UnifiedService] بدء التتبع...');

      _broadcastCurrentData();

      await _startPedometer();
      await _startSensors();
      _startPeriodicSync();
      _startDatabaseSync(); // ← بدء الحفظ في database

      _isTracking = true;
      debugPrint('✅ [UnifiedService] التتبع نشط');
      return true;
    } catch (e) {
      debugPrint('❌ [UnifiedService] خطأ في بدء التتبع: $e');
      return false;
    }
  }

  Future<void> _startPedometer() async {
    try {
      _stepCountSubscription?.cancel();
      _pedometerActive = true;

      _stepCountSubscription = Pedometer.stepCountStream.listen(
            (StepCount event) async {
          _systemSteps = event.steps;

          final today = _formatDate(DateTime.now());
          if (today != _currentDate) {
            debugPrint('🆕 [Pedometer] يوم جديد!');

            // ✅ حفظ بيانات اليوم السابق في database قبل التصفير
            await _saveToDatabaseFinal();

            _currentDate = today;
            _baselineSteps = _systemSteps;
            _sensorBaseline = _sensorSteps;
            _currentSteps = 0;
            _currentDistance = 0.0;
            _currentCalories = 0.0;
            _lastBroadcastedSteps = -1;
            _lastDatabaseSync = null;
            await _saveData();
            await _saveBaseline();
            _broadcastCurrentData();
            return;
          }

          if (_baselineSteps == 0) {
            final prefs = await SharedPreferences.getInstance();
            _baselineSteps = prefs.getInt('baseline_steps_$_currentDate') ?? 0;

            if (_baselineSteps == 0) {
              _baselineSteps = _systemSteps;
              debugPrint('📍 [Pedometer] Baseline جديد: $_baselineSteps');
              await _saveBaseline();
            }
          }

          final stepsToday = (_systemSteps - _baselineSteps).clamp(0, 999999);

          _currentSteps = stepsToday;
          _currentDistance = _currentSteps * 0.000762;
          _currentCalories = _currentSteps * 0.04;
          _lastUpdate = DateTime.now();

          final shouldBroadcast = stepsToday != _lastBroadcastedSteps;

          if (shouldBroadcast) {
            _lastBroadcastedSteps = stepsToday;
            _broadcastCurrentData();
            await _saveData();

            if (_currentSteps % 10 == 0 || _currentSteps < 10) {
              debugPrint('🚶 [Pedometer→Stream] خطوات: $_currentSteps');
            }
          }
        },
        onError: (error) {
          debugPrint('❌ [Pedometer] خطأ: $error');
          _pedometerActive = false;
        },
      );

      debugPrint('✅ [Pedometer] نشط');
    } catch (e) {
      debugPrint('❌ [Pedometer] خطأ في البدء: $e');
    }
  }

  Future<void> _startSensors() async {
    try {
      _accelerometerSubscription?.cancel();

      final prefs = await SharedPreferences.getInstance();
      _sensorBaseline = prefs.getInt('sensor_baseline_$_currentDate') ?? 0;
      _sensorSteps = prefs.getInt('sensor_steps_$_currentDate') ?? 0;

      debugPrint('📂 [Sensors] تحميل: steps=$_sensorSteps, baseline=$_sensorBaseline');

      double threshold = 12.0;
      int stepCounter = _sensorSteps;

      _sensorsActive = true;

      _accelerometerSubscription = accelerometerEventStream().listen(
            (AccelerometerEvent event) async {
          final magnitude = (event.x * event.x + event.y * event.y + event.z * event.z).abs();

          if (magnitude > threshold) {
            final now = DateTime.now();
            if (_lastStepTime == null || now.difference(_lastStepTime!).inMilliseconds > 300) {
              stepCounter++;
              _lastStepTime = now;
              _sensorSteps = stepCounter;

              // استخدام Sensors فقط إذا Pedometer فشل
              if (!_pedometerActive && _systemSteps == 0) {
                _currentSteps = _sensorSteps - _sensorBaseline;
                _currentDistance = _currentSteps * 0.000762;
                _currentCalories = _currentSteps * 0.04;
                _lastUpdate = DateTime.now();
                _sensorsActive = true;

                _broadcastCurrentData();
                await _saveData();
                await prefs.setInt('sensor_steps_$_currentDate', _sensorSteps);

                if (_currentSteps % 10 == 0) {
                  debugPrint('📱 [Sensors→Backup] خطوات: $_currentSteps');
                }
              }
            }
          }
        },
        onError: (error) {
          debugPrint('❌ [Sensors] خطأ: $error');
          _sensorsActive = false;
        },
      );

      if (_sensorBaseline == 0 && _sensorSteps > 0) {
        _sensorBaseline = _sensorSteps;
        await prefs.setInt('sensor_baseline_$_currentDate', _sensorBaseline);
        debugPrint('📍 [Sensors] Baseline جديد: $_sensorBaseline');
      }

      debugPrint('✅ [Sensors] نشط كـ backup');
    } catch (e) {
      debugPrint('❌ [Sensors] خطأ في البدء: $e');
    }
  }

  void _broadcastCurrentData() {
    if (!_dataStreamController.isClosed) {
      final data = {
        'steps': _currentSteps,
        'distance': _currentDistance,
        'calories': _currentCalories,
        'date': _currentDate,
        'last_update': _lastUpdate,
        'is_tracking': _isTracking,
        'primary_source': _pedometerActive ? 'pedometer' : (_sensorsActive ? 'sensors' : 'none'),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      _dataStreamController.add(data);
    }
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_isTracking) {
        await _saveData();
        _broadcastCurrentData();
      }
    });
    debugPrint('⏰ [Sync] بدأت المزامنة (كل 3 ثواني)');
  }

  // ✅ دالة جديدة - حفظ دوري في Database
  void _startDatabaseSync() {
    _databaseSyncTimer?.cancel();
    _databaseSyncTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_isTracking && _currentSteps > 0) {
        await _saveToDatabase();
      }
    });
    debugPrint('💾 [DB Sync] بدأت المزامنة مع Database (كل 30 ثانية)');
  }

  // ✅ دالة جديدة - حفظ في Database
  Future<void> _saveToDatabase() async {
    try {
      // تجنب الحفظ المتكرر
      if (_lastDatabaseSync != null &&
          DateTime.now().difference(_lastDatabaseSync!).inSeconds < 25) {
        return;
      }

      // ✅ أخذ الأهداف من UserSettingsService
      final goals = await _userSettings.getAllGoals();
      final goalSteps = goals['steps'] as int;
      final goalDistance = goals['distance'] as double;
      final goalCalories = goals['calories'] as double;

      await _activityRepo.upsertDailyActivity(
        date: _currentDate,
        totalSteps: _currentSteps,
        distance: _currentDistance,
        caloriesBurned: _currentCalories,
        activityType: 'general',
        intensityScore: _calculateIntensityScore(),
        goalSteps: goalSteps, // ✅ حفظ الهدف
        goalDistance: goalDistance, // ✅ حفظ الهدف
        goalCalories: goalCalories, // ✅ حفظ الهدف
      );

      _lastDatabaseSync = DateTime.now();
      debugPrint('💾 [DB] حفظ: $_currentDate → $_currentSteps/$goalSteps خطوات');
    } catch (e) {
      debugPrint('❌ [DB] خطأ في الحفظ: $e');
    }
  }

  // ✅ دالة جديدة - حفظ نهائي (نهاية اليوم أو إيقاف التتبع)
  Future<void> _saveToDatabaseFinal() async {
    try {
      if (_currentSteps == 0) return;

      // ✅ أخذ الأهداف من UserSettingsService
      final goals = await _userSettings.getAllGoals();
      final goalSteps = goals['steps'] as int;
      final goalDistance = goals['distance'] as double;
      final goalCalories = goals['calories'] as double;

      await _activityRepo.upsertDailyActivity(
        date: _currentDate,
        totalSteps: _currentSteps,
        distance: _currentDistance,
        caloriesBurned: _currentCalories,
        activityType: 'general',
        intensityScore: _calculateIntensityScore(),
        goalSteps: goalSteps, // ✅ حفظ الهدف
        goalDistance: goalDistance, // ✅ حفظ الهدف
        goalCalories: goalCalories, // ✅ حفظ الهدف
      );

      debugPrint('✅ [DB Final] حفظ نهائي: $_currentDate → $_currentSteps/$goalSteps خطوات');
    } catch (e) {
      debugPrint('❌ [DB Final] خطأ: $e');
    }
  }

  // ✅ دالة لحساب معدل الكثافة
  double _calculateIntensityScore() {
    // كثافة بسيطة بناءً على عدد الخطوات
    if (_currentSteps >= 15000) return 0.9;
    if (_currentSteps >= 10000) return 0.7;
    if (_currentSteps >= 7500) return 0.5;
    if (_currentSteps >= 5000) return 0.3;
    return 0.1;
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('steps_today', _currentSteps);
      await prefs.setDouble('distance_today', _currentDistance);
      await prefs.setDouble('calories_today', _currentCalories);
      await prefs.setString('steps_date', _currentDate);
      await prefs.setInt('last_step_update', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('❌ [Save] خطأ: $e');
    }
  }

  Future<void> _saveBaseline() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('baseline_steps_$_currentDate', _baselineSteps);
    } catch (e) {
      debugPrint('❌ [Save] خطأ في Baseline: $e');
    }
  }

  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDate = prefs.getString('steps_date') ?? '';

      if (savedDate == _currentDate) {
        _currentSteps = prefs.getInt('steps_today') ?? 0;
        _currentDistance = prefs.getDouble('distance_today') ?? 0.0;
        _currentCalories = prefs.getDouble('calories_today') ?? 0.0;
        _baselineSteps = prefs.getInt('baseline_steps_$_currentDate') ?? 0;
        _sensorSteps = prefs.getInt('sensor_steps_$_currentDate') ?? 0;
        _sensorBaseline = prefs.getInt('sensor_baseline_$_currentDate') ?? 0;

        debugPrint('📂 [Load] تم تحميل: $_currentSteps خطوة');
      } else {
        debugPrint('🆕 [Load] يوم جديد');
      }
    } catch (e) {
      debugPrint('❌ [Load] خطأ: $e');
    }
  }

  Future<Map<String, dynamic>> getTodayData() async {
    final today = _formatDate(DateTime.now());
    if (today != _currentDate) await _loadSavedData();

    return {
      'steps': _currentSteps,
      'distance': _currentDistance,
      'calories': _currentCalories,
      'date': _currentDate,
      'last_update': _lastUpdate,
      'is_tracking': _isTracking,
      'primary_source': _pedometerActive ? 'pedometer' : (_sensorsActive ? 'sensors' : 'none'),
    };
  }

  Future<Map<String, dynamic>> getStatus() async {
    return {
      'is_initialized': _isInitialized,
      'is_tracking': _isTracking,
      'pedometer_active': _pedometerActive,
      'sensors_active': _sensorsActive,
      'current_steps': _currentSteps,
      'system_steps': _systemSteps,
      'baseline_steps': _baselineSteps,
      'sensor_steps': _sensorSteps,
      'sensor_baseline': _sensorBaseline,
      'distance': _currentDistance,
      'calories': _currentCalories,
      'primary_source': _pedometerActive ? 'pedometer' : (_sensorsActive ? 'sensors' : 'none'),
      'last_update': _lastUpdate,
      'current_date': _currentDate,
      'last_db_sync': _lastDatabaseSync,
    };
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> stopTracking() async {
    // ✅ حفظ نهائي في database قبل الإيقاف
    await _saveToDatabaseFinal();

    _stepCountSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _syncTimer?.cancel();
    _databaseSyncTimer?.cancel(); // ← إيقاف timer الـ database
    await _saveData();
    _isTracking = false;
    debugPrint('⏹️ [Stop] تم إيقاف التتبع');
  }

  void dispose() {
    stopTracking();
    _dataStreamController.close();
    debugPrint('🗑️ [Dispose] تنظيف الخدمة');
  }
}