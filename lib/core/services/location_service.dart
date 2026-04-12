// lib/core/services/enhanced_location_service.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../database/models/common_models.dart';
import '../database/models/activity_models.dart';
import '../database/repositories/location_repository.dart';
import '../database/repositories/settings_repository.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  static LocationService get instance => _instance;

  final LocationRepository _locationRepo = LocationRepository();
  final SettingsRepository _settingsRepo = SettingsRepository();

  // Stream controllers
  final StreamController<Position> _positionController = StreamController<Position>.broadcast();
  final StreamController<LocationVisit> _visitController = StreamController<LocationVisit>.broadcast();
  final StreamController<Map<String, dynamic>> _dailyPatternController = StreamController<Map<String, dynamic>>.broadcast();

  // Subscriptions and state
  StreamSubscription<Position>? _positionSubscription;
  Position? _lastKnownPosition;
  LocationVisit? _currentVisit;
  bool _isTracking = false;
  Timer? _locationUpdateTimer;
  Timer? _visitValidationTimer;

  // Enhanced configuration
  static const double _minDistanceForNewVisit = 80.0;
  static const Duration _minStayDuration = Duration(minutes: 10);
  static const Duration _maxLocationAge = Duration(minutes: 3);
  static const double _accuracyThreshold = 50.0;
  static const int _maxRetries = 5;
  static const Duration _visitValidationInterval = Duration(minutes: 2);

  // Position buffer for smoothing
  final List<Position> _positionBuffer = [];
  static const int _bufferSize = 5;

  // ✅ إضافة flag لمعرفة إذا كان Geocoding يعمل
  bool _geocodingAvailable = true;

  // Getters
  Stream<Position> get positionStream => _positionController.stream;
  Stream<LocationVisit> get visitStream => _visitController.stream;
  Stream<Map<String, dynamic>> get dailyPatternStream => _dailyPatternController.stream;
  bool get isTracking => _isTracking;
  Position? get lastKnownPosition => _lastKnownPosition;
  LocationVisit? get currentVisit => _currentVisit;

  // Initialize enhanced location service
  Future<bool> initialize() async {
    try {
      debugPrint('🔧 تهيئة خدمة المواقع المحسنة...');

      // Check location services and permissions
      if (!await _checkLocationServicesAndPermissions()) {
        return false;
      }

      // Load last known position
      await _loadLastKnownPosition();

      // Setup validation timer
      _setupVisitValidationTimer();

      // ✅ اختبار Geocoding
      await _testGeocodingAvailability();

      debugPrint('✅ تم تهيئة خدمة المواقع المحسنة بنجاح');
      return true;

    } catch (e) {
      debugPrint('❌ خطأ في تهيئة خدمة المواقع المحسنة: $e');
      return false;
    }
  }

  // ✅ اختبار توفر Geocoding
  Future<void> _testGeocodingAvailability() async {
    try {
      // اختبار بسيط بإحداثيات عشوائية
      await placemarkFromCoordinates(0.0, 0.0).timeout(
        const Duration(seconds: 3),
      );
      _geocodingAvailable = true;
      debugPrint('✅ Geocoding API متاح');
    } catch (e) {
      _geocodingAvailable = false;
      debugPrint('⚠️ Geocoding API غير متاح - سيتم استخدام معلومات افتراضية');
    }
  }

  // Enhanced location services and permissions check
  Future<bool> _checkLocationServicesAndPermissions() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ خدمة المواقع غير مفعلة');
        return false;
      }

      // Check permissions with enhanced logic
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ أذونات الموقع مرفوضة نهائياً');
        return false;
      }

      if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
        debugPrint('❌ أذونات الموقع غير كافية');
        return false;
      }

      debugPrint('✅ تم التحقق من أذونات الموقع بنجاح');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في فحص أذونات الموقع: $e');
      return false;
    }
  }

  // Load last known position from settings
  Future<void> _loadLastKnownPosition() async {
    try {
      final lastLat = await _settingsRepo.getSetting<double>('last_latitude', 0.0);
      final lastLng = await _settingsRepo.getSetting<double>('last_longitude', 0.0);
      final lastTime = await _settingsRepo.getSetting<int>('last_position_time', 0);

      if (lastLat != 0.0 && lastLng != 0.0 && lastTime != null) {
        final lastPositionTime = DateTime.fromMillisecondsSinceEpoch(lastTime);

        // Only use if less than 1 hour old
        if (DateTime.now().difference(lastPositionTime).inHours < 1) {
          debugPrint('📍 تم استرجاع آخر موقع محفوظ');
        }
      }

      // Also try to get system's last known position
      try {
        final systemLastPosition = await Geolocator.getLastKnownPosition(
          forceAndroidLocationManager: true,
        );
        if (systemLastPosition != null) {
          _lastKnownPosition = systemLastPosition;
          debugPrint('📍 آخر موقع من النظام: ${systemLastPosition.latitude}, ${systemLastPosition.longitude}');
        }
      } catch (e) {
        debugPrint('⚠️ لم يتم العثور على آخر موقع من النظام: $e');
      }

    } catch (e) {
      debugPrint('❌ خطأ في استرجاع آخر موقع: $e');
    }
  }

  // Setup visit validation timer
  void _setupVisitValidationTimer() {
    _visitValidationTimer = Timer.periodic(_visitValidationInterval, (timer) async {
      if (_currentVisit != null) {
        await _validateCurrentVisit();
      }
    });
  }

  // Validate current visit
  Future<void> _validateCurrentVisit() async {
    if (_currentVisit == null || _lastKnownPosition == null) return;

    try {
      final distance = Geolocator.distanceBetween(
        _currentVisit!.latitude,
        _currentVisit!.longitude,
        _lastKnownPosition!.latitude,
        _lastKnownPosition!.longitude,
      );

      // If moved away significantly, end current visit
      if (distance > _minDistanceForNewVisit * 1.5) {
        debugPrint('🚶 المستخدم ابتعد عن الموقع الحالي');
        await _endCurrentVisit();
      }
    } catch (e) {
      debugPrint('❌ خطأ في التحقق من الزيارة الحالية: $e');
    }
  }

  // Enhanced location tracking start
  Future<bool> startLocationTracking() async {
    if (_isTracking) {
      debugPrint('⚠️ تتبع المواقع يعمل بالفعل');
      return true;
    }

    try {
      debugPrint('🚀 بدء تتبع المواقع المحسن...');

      // Final check for services and permissions
      if (!await _checkLocationServicesAndPermissions()) {
        debugPrint('❌ فشل في فحص أذونات الموقع');
        return false;
      }

      // Get initial position immediately
      try {
        final initialPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );

        if (initialPosition != null) {
          debugPrint('📍 موقع أولي: ${initialPosition.latitude}, ${initialPosition.longitude}');
          await _handleEnhancedPositionUpdate(initialPosition);
        }
      } catch (e) {
        debugPrint('⚠️ فشل في الحصول على موقع أولي: $e');
      }

      // Enhanced location settings
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        timeLimit: Duration(seconds: 30),
      );

      // Start position stream with error handling
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
            (position) async {
          debugPrint('📍 موقع جديد من الـ stream: ${position.latitude}, ${position.longitude}');
          await _handleEnhancedPositionUpdate(position);
        },
        onError: (error) {
          debugPrint('❌ خطأ في stream الموقع: $error');
          _scheduleLocationRestart();
        },
        onDone: () {
          debugPrint('🔚 انتهى stream الموقع');
          _scheduleLocationRestart();
        },
      );

      // Start enhanced backup timer
      _startEnhancedLocationUpdateTimer();

      _isTracking = true;
      debugPrint('✅ بدأ تتبع المواقع المحسن بنجاح');

      // Generate initial daily pattern
      await _generateDailyPattern();

      return true;

    } catch (e) {
      debugPrint('❌ خطأ في بدء تتبع المواقع: $e');
      await stopLocationTracking();
      return false;
    }
  }

  // Enhanced position update handling
  Future<void> _handleEnhancedPositionUpdate(Position position) async {
    try {
      // Add to position buffer for smoothing
      _positionBuffer.add(position);
      if (_positionBuffer.length > _bufferSize) {
        _positionBuffer.removeAt(0);
      }

      // Use smoothed position if buffer is full
      final smoothedPosition = _getSmoothPosition();
      _lastKnownPosition = smoothedPosition ?? position;

      // Emit position update
      _positionController.add(_lastKnownPosition!);

      debugPrint('📍 موقع محسن: ${_lastKnownPosition!.latitude.toStringAsFixed(6)}, ${_lastKnownPosition!.longitude.toStringAsFixed(6)} (±${_lastKnownPosition!.accuracy.round()}m)');

      // Save position
      await _saveLastKnownPosition(_lastKnownPosition!);

      // Enhanced visit tracking
      await _handleEnhancedVisitTracking(_lastKnownPosition!);

      // Update daily pattern
      await _updateDailyPattern();

    } catch (e) {
      debugPrint('❌ خطأ في معالجة تحديث الموقع المحسن: $e');
    }
  }

  // Get smooth position from buffer
  Position? _getSmoothPosition() {
    if (_positionBuffer.length < 3) return null;

    // Calculate weighted average of recent positions
    double totalLat = 0, totalLng = 0, totalWeight = 0;

    for (int i = 0; i < _positionBuffer.length; i++) {
      final pos = _positionBuffer[i];
      final weight = 1.0 / (pos.accuracy + 1.0);

      totalLat += pos.latitude * weight;
      totalLng += pos.longitude * weight;
      totalWeight += weight;
    }

    if (totalWeight == 0) return null;

    final avgLat = totalLat / totalWeight;
    final avgLng = totalLng / totalWeight;
    final latestPos = _positionBuffer.last;

    return Position(
      longitude: avgLng,
      latitude: avgLat,
      timestamp: latestPos.timestamp,
      accuracy: latestPos.accuracy,
      altitude: latestPos.altitude,
      altitudeAccuracy: latestPos.altitudeAccuracy,
      heading: latestPos.heading,
      headingAccuracy: latestPos.headingAccuracy,
      speed: latestPos.speed,
      speedAccuracy: latestPos.speedAccuracy,
    );
  }

  // Enhanced visit tracking
  Future<void> _handleEnhancedVisitTracking(Position position) async {
    try {
      if (_currentVisit == null) {
        // Check if we're at a known location
        final similarLocation = await _locationRepo.findSimilarLocation(
          position.latitude,
          position.longitude,
          radiusMeters: _minDistanceForNewVisit,
        );

        await _startEnhancedVisit(position, similarLocation);
      } else {
        // Check if still in same location
        final distance = Geolocator.distanceBetween(
          _currentVisit!.latitude,
          _currentVisit!.longitude,
          position.latitude,
          position.longitude,
        );

        if (distance > _minDistanceForNewVisit) {
          // Moved to new location
          await _endCurrentVisit();

          // Check for new location
          final similarLocation = await _locationRepo.findSimilarLocation(
            position.latitude,
            position.longitude,
            radiusMeters: _minDistanceForNewVisit,
          );

          await _startEnhancedVisit(position, similarLocation);
        } else {
          // Still in same location, update position if more accurate
          if (position.accuracy < (_currentVisit!.accuracy ?? double.infinity)) {
            _currentVisit = _currentVisit!.copyWith(
              latitude: position.latitude,
              longitude: position.longitude,
              accuracy: position.accuracy,
              altitude: position.altitude,
              updatedAt: DateTime.now(),
            );
          }
        }
      }

    } catch (e) {
      debugPrint('❌ خطأ في معالجة تتبع الزيارات المحسن: $e');
    }
  }

  // Enhanced visit start
  Future<void> _startEnhancedVisit(Position position, LocationVisit? similarLocation) async {
    try {
      debugPrint('🏁 بدء زيارة محسنة للموقع');

      // Get enhanced place information
      final placeInfo = await _getEnhancedPlaceInfo(position);

      _currentVisit = LocationVisit(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        placeName: similarLocation?.placeName ?? placeInfo.name,
        placeType: similarLocation?.placeType ?? placeInfo.type,
        placeCategory: similarLocation?.placeCategory ?? placeInfo.category,
        moodImpact: similarLocation?.moodImpact ?? placeInfo.moodImpact,
        arrivalTime: DateTime.now(),
        visitFrequency: similarLocation != null ? similarLocation.visitFrequency + 1 : 1,
        isHome: similarLocation?.isHome ?? placeInfo.isHome,
        isWork: similarLocation?.isWork ?? placeInfo.isWork,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      debugPrint('📍 زيارة محسنة جديدة: ${_currentVisit!.placeName ?? 'موقع غير معروف'}');

    } catch (e) {
      debugPrint('❌ خطأ في بدء زيارة محسنة جديدة: $e');
    }
  }

  // ✅ Enhanced place information retrieval - مُصلح
  Future<PlaceInfo> _getEnhancedPlaceInfo(Position position) async {
    // إذا كان Geocoding غير متاح، استخدم معلومات افتراضية
    if (!_geocodingAvailable) {
      return _getDefaultPlaceInfo(position);
    }

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(
        const Duration(seconds: 5), // ✅ timeout أقصر
        onTimeout: () {
          debugPrint('⚠️ Geocoding timeout - استخدام معلومات افتراضية');
          _geocodingAvailable = false; // ✅ تعطيل Geocoding للمرات القادمة
          return <Placemark>[];
        },
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        return PlaceInfo(
          name: _extractEnhancedPlaceName(place),
          type: await _classifyEnhancedPlaceType(place, position),
          category: await _classifyEnhancedPlaceCategory(place, position),
          moodImpact: await _assessEnhancedMoodImpact(place, position),
          isHome: await _isEnhancedHomeLocation(position),
          isWork: await _isEnhancedWorkLocation(position),
          address: _formatEnhancedAddress(place),
        );
      }

    } catch (e) {
      // ✅ لا نطبع الخطأ الكامل لتجنب spam في الـ logs
      if (e.toString().contains('PERMISSION_DENIED') || e.toString().contains('403')) {
        debugPrint('⚠️ Geocoding API غير مفعل - استخدام معلومات افتراضية');
        _geocodingAvailable = false; // ✅ تعطيل للمرات القادمة
      } else {
        debugPrint('⚠️ خطأ في Geocoding: ${e.runtimeType}');
      }
    }

    // ✅ استخدام معلومات افتراضية
    return _getDefaultPlaceInfo(position);
  }

  // ✅ معلومات افتراضية للموقع
  PlaceInfo _getDefaultPlaceInfo(Position position) {
    return PlaceInfo(
      name: 'موقع (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})',
      type: _classifyByTimePattern(),
      category: 'neutral',
      moodImpact: MoodImpact.neutral,
      isHome: false,
      isWork: false,
      address: 'لا توجد معلومات عنوان',
    );
  }

  // Enhanced place name extraction
  String? _extractEnhancedPlaceName(Placemark place) {
    final candidates = [
      place.name,
      place.thoroughfare,
      place.subLocality,
      place.locality,
    ].where((name) => name != null && name.isNotEmpty && name.length > 2);

    return candidates.isNotEmpty ? candidates.first : null;
  }

  // Enhanced place type classification with time context
  Future<String> _classifyEnhancedPlaceType(Placemark place, Position position) async {
    final keywords = [
      place.name?.toLowerCase() ?? '',
      place.subLocality?.toLowerCase() ?? '',
      place.thoroughfare?.toLowerCase() ?? '',
    ].join(' ');

    // Enhanced Arabic/English keywords
    final classifications = {
      'home': ['منزل', 'بيت', 'سكن', 'فيلا', 'شقة', 'home', 'house', 'residence', 'apartment', 'villa'],
      'work': ['عمل', 'مكتب', 'شركة', 'مؤسسة', 'work', 'office', 'company', 'business', 'corporate'],
      'shopping': ['تسوق', 'مول', 'سوق', 'محل', 'متجر', 'mall', 'shop', 'store', 'market', 'center'],
      'food': ['مطعم', 'مقهى', 'كافيه', 'restaurant', 'cafe', 'coffee', 'dining'],
      'healthcare': ['مستشفى', 'عيادة', 'طبي', 'صحي', 'hospital', 'clinic', 'medical', 'health'],
      'education': ['مدرسة', 'جامعة', 'كلية', 'معهد', 'school', 'university', 'college', 'institute'],
      'worship': ['مسجد', 'كنيسة', 'معبد', 'mosque', 'church', 'temple'],
      'recreation': ['حديقة', 'نادي', 'ملعب', 'منتزه', 'park', 'gym', 'club', 'sports', 'recreation'],
      'transport': ['مطار', 'محطة', 'airport', 'station', 'transport', 'bus', 'train'],
    };

    for (final entry in classifications.entries) {
      for (final keyword in entry.value) {
        if (keywords.contains(keyword)) {
          return entry.key;
        }
      }
    }

    // Time-based classification fallback
    return _classifyByTimePattern();
  }

  // Classify place type by time patterns
  String _classifyByTimePattern() {
    final hour = DateTime.now().hour;
    final isWeekend = DateTime.now().weekday >= 6;

    if (hour >= 22 || hour <= 6) return 'home';
    if (!isWeekend && hour >= 8 && hour <= 17) return 'work';
    if (hour >= 11 && hour <= 14) return 'food';
    if (hour >= 18 && hour <= 22) return 'recreation';

    return 'other';
  }

  // Enhanced category classification
  Future<String> _classifyEnhancedPlaceCategory(Placemark place, Position position) async {
    final type = await _classifyEnhancedPlaceType(place, position);

    switch (type) {
      case 'home':
      case 'recreation':
      case 'food':
        return 'positive';
      case 'healthcare':
        return 'negative';
      case 'work':
      case 'education':
      case 'worship':
      case 'transport':
      case 'shopping':
      default:
        return 'neutral';
    }
  }

  // Enhanced mood impact assessment
  Future<MoodImpact> _assessEnhancedMoodImpact(Placemark place, Position position) async {
    final category = await _classifyEnhancedPlaceCategory(place, position);

    switch (category) {
      case 'positive':
        return MoodImpact.positive;
      case 'negative':
        return MoodImpact.negative;
      case 'neutral':
      default:
        return MoodImpact.neutral;
    }
  }

  // Enhanced home location detection
  Future<bool> _isEnhancedHomeLocation(Position position) async {
    try {
      final homeLat = await _settingsRepo.getSetting<double>('home_latitude', 0.0);
      final homeLng = await _settingsRepo.getSetting<double>('home_longitude', 0.0);

      if (homeLat == 0.0 && homeLng == 0.0) {
        return await _autoDetectHome(position);
      }

      final distance = Geolocator.distanceBetween(
          homeLat!, homeLng!, position.latitude, position.longitude);

      return distance <= _minDistanceForNewVisit;

    } catch (e) {
      return false;
    }
  }

  // Auto-detect home location
  Future<bool> _autoDetectHome(Position position) async {
    try {
      final hour = DateTime.now().hour;

      // Likely home if between 10 PM and 8 AM
      if (hour >= 22 || hour <= 8) {
        final visits = await _locationRepo.findSimilarLocation(
          position.latitude,
          position.longitude,
          radiusMeters: _minDistanceForNewVisit * 2,
        );

        return (visits?.visitFrequency ?? 0) > 5;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // Enhanced work location detection
  Future<bool> _isEnhancedWorkLocation(Position position) async {
    try {
      final workLat = await _settingsRepo.getSetting<double>('work_latitude', 0.0);
      final workLng = await _settingsRepo.getSetting<double>('work_longitude', 0.0);

      if (workLat == 0.0 && workLng == 0.0) {
        return await _autoDetectWork(position);
      }

      final distance = Geolocator.distanceBetween(
          workLat!, workLng!, position.latitude, position.longitude);

      return distance <= _minDistanceForNewVisit;

    } catch (e) {
      return false;
    }
  }

  // Auto-detect work location
  Future<bool> _autoDetectWork(Position position) async {
    try {
      final hour = DateTime.now().hour;
      final isWeekday = DateTime.now().weekday < 6;

      if (isWeekday && hour >= 8 && hour <= 18) {
        final visits = await _locationRepo.findSimilarLocation(
          position.latitude,
          position.longitude,
          radiusMeters: _minDistanceForNewVisit * 2,
        );

        return (visits?.visitFrequency ?? 0) > 3;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // Enhanced address formatting
  String _formatEnhancedAddress(Placemark place) {
    final parts = <String>[];

    if (place.name?.isNotEmpty == true && place.name != place.thoroughfare) {
      parts.add(place.name!);
    }
    if (place.thoroughfare?.isNotEmpty == true) parts.add(place.thoroughfare!);
    if (place.subLocality?.isNotEmpty == true) parts.add(place.subLocality!);
    if (place.locality?.isNotEmpty == true) parts.add(place.locality!);

    return parts.isNotEmpty ? parts.join(', ') : 'عنوان غير معروف';
  }

  // Enhanced backup timer
  void _startEnhancedLocationUpdateTimer() {
    _locationUpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (_isTracking) {
        try {
          final position = await _getCurrentPositionWithEnhancedRetry();
          if (position != null) {
            await _handleEnhancedPositionUpdate(position);
          }
        } catch (e) {
          debugPrint('⚠️ خطأ في التحديث الدوري المحسن للموقع: $e');
        }
      }
    });
  }

  // Enhanced position retry logic
  Future<Position?> _getCurrentPositionWithEnhancedRetry({int maxRetries = 5}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10 + (i * 5)),
        );

        if (position.accuracy <= _accuracyThreshold * (1 + i * 0.5)) {
          return position;
        } else if (i == maxRetries - 1) {
          debugPrint('⚠️ دقة منخفضة مقبولة: ${position.accuracy}m');
          return position;
        }

      } catch (e) {
        debugPrint('⚠️ محاولة ${i + 1} فشلت: $e');
        if (i < maxRetries - 1) {
          await Future.delayed(Duration(seconds: 2 * (i + 1)));
        }
      }
    }

    return null;
  }

  // Schedule location restart with exponential backoff
  void _scheduleLocationRestart() {
    Timer(const Duration(seconds: 30), () async {
      if (_isTracking && _positionSubscription == null) {
        debugPrint('🔄 إعادة تشغيل تتبع المواقع...');
        await startLocationTracking();
      }
    });
  }

  // Generate daily movement pattern
  Future<void> _generateDailyPattern() async {
    try {
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final pattern = await _locationRepo.getDailyMovementPattern(dateStr);

      _dailyPatternController.add({
        'date': dateStr,
        'pattern': pattern,
        'total_locations': pattern.length,
        'current_location': _currentVisit?.placeName ?? 'غير معروف',
        'generated_at': DateTime.now().toIso8601String(),
      });

    } catch (e) {
      debugPrint('❌ خطأ في إنشاء نمط الحركة اليومي: $e');
    }
  }

  // Update daily pattern
  Future<void> _updateDailyPattern() async {
    if (DateTime.now().minute % 10 == 0) {
      await _generateDailyPattern();
    }
  }

  // End current visit with enhanced logic
  Future<void> _endCurrentVisit() async {
    if (_currentVisit == null) return;

    try {
      final now = DateTime.now();
      final duration = now.difference(_currentVisit!.arrivalTime);

      if (duration >= _minStayDuration) {
        final completedVisit = _currentVisit!.copyWith(
          departureTime: now,
          duration: duration,
          updatedAt: now,
        );

        final existingSimilar = await _locationRepo.findSimilarLocation(
          completedVisit.latitude,
          completedVisit.longitude,
          radiusMeters: _minDistanceForNewVisit,
        );

        if (existingSimilar != null) {
          await _locationRepo.updateVisitFrequency(
            existingSimilar.id!,
            existingSimilar.visitFrequency + 1,
          );

          if (completedVisit.placeName != null && existingSimilar.placeName == null) {
            await _locationRepo.updateLocationDetails(
              existingSimilar.id!,
              placeName: completedVisit.placeName,
              placeType: completedVisit.placeType,
            );
          }
        } else {
          final visitId = await _locationRepo.insertLocationVisit(completedVisit);
          if (visitId != null) {
            debugPrint('💾 تم حفظ زيارة جديدة بمعرف: $visitId');
          }
        }

        _visitController.add(completedVisit);

        debugPrint('💾 تم حفظ الزيارة المحسنة: ${completedVisit.placeName ?? 'موقع غير معروف'} (${duration.inMinutes} دقيقة)');

        await _generateDailyPattern();

      } else {
        debugPrint('⏭️ زيارة قصيرة تم تجاهلها: ${duration.inMinutes} دقيقة');
      }

      _currentVisit = null;

    } catch (e) {
      debugPrint('❌ خطأ في إنهاء الزيارة المحسنة: $e');
      _currentVisit = null;
    }
  }

  // Enhanced position saving
  Future<void> _saveLastKnownPosition(Position position) async {
    try {
      await _settingsRepo.setSetting('last_latitude', position.latitude, SettingValueType.double);
      await _settingsRepo.setSetting('last_longitude', position.longitude, SettingValueType.double);
      await _settingsRepo.setSetting('last_accuracy', position.accuracy, SettingValueType.double);
      await _settingsRepo.setSetting('last_position_time', DateTime.now().millisecondsSinceEpoch, SettingValueType.int);
    } catch (e) {
      debugPrint('❌ خطأ في حفظ آخر موقع محسن: $e');
    }
  }

  // Stop enhanced location tracking
  Future<void> stopLocationTracking() async {
    if (!_isTracking) return;

    try {
      debugPrint('⏹️ إيقاف تتبع المواقع المحسن...');

      // End current visit if exists
      if (_currentVisit != null) {
        await _endCurrentVisit();
      }

      // Cancel all subscriptions and timers
      await _positionSubscription?.cancel();
      _positionSubscription = null;

      _locationUpdateTimer?.cancel();
      _locationUpdateTimer = null;

      _visitValidationTimer?.cancel();
      _visitValidationTimer = null;

      // Clear position buffer
      _positionBuffer.clear();

      _isTracking = false;
      debugPrint('✅ تم إيقاف تتبع المواقع المحسن');

    } catch (e) {
      debugPrint('❌ خطأ في إيقاف تتبع المواقع المحسن: $e');
    }
  }

  // Get current position (one-time with enhanced accuracy)
  Future<Position?> getCurrentPosition() async {
    try {
      if (!await _checkLocationServicesAndPermissions()) return null;
      return await _getCurrentPositionWithEnhancedRetry();
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على الموقع الحالي المحسن: $e');
      return null;
    }
  }

  // Enhanced location analytics
  Future<Map<String, dynamic>> getLocationAnalytics({
    required String startDate,
    required String endDate,
  }) async {
    try {
      // Get basic statistics
      final stats = await _locationRepo.getLocationStatistics(
        startDate: startDate,
        endDate: endDate,
      );

      // Get most visited places
      final topPlaces = await _locationRepo.getMostVisitedPlaces(limit: 10);

      // Get movement patterns
      final patterns = <Map<String, dynamic>>[];
      final visits = await _locationRepo.getLocationVisitsForDateRange(startDate, endDate);

      // Group by date
      final visitsByDate = <String, List<LocationVisit>>{};
      for (final visit in visits) {
        final dateKey = visit.arrivalTime.toIso8601String().split('T')[0];
        visitsByDate.putIfAbsent(dateKey, () => []).add(visit);
      }

      // Calculate daily patterns
      for (final entry in visitsByDate.entries) {
        final dailyVisits = entry.value;
        final totalTime = dailyVisits
            .where((v) => v.duration != null)
            .map((v) => v.duration!.inMinutes)
            .fold(0, (sum, duration) => sum + duration);

        patterns.add({
          'date': entry.key,
          'total_visits': dailyVisits.length,
          'total_time_minutes': totalTime,
          'unique_places': dailyVisits.map((v) => v.placeName).toSet().length,
          'most_visited_place': dailyVisits
              .fold<Map<String, int>>({}, (map, visit) {
            final name = visit.placeName ?? 'unknown';
            map[name] = (map[name] ?? 0) + 1;
            return map;
          })
              .entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key,
        });
      }

      return {
        ...stats,
        'top_places': topPlaces,
        'daily_patterns': patterns,
        'analysis_period': {
          'start': startDate,
          'end': endDate,
          'days': DateTime.parse(endDate).difference(DateTime.parse(startDate)).inDays,
        },
        'insights': await _generateLocationInsights(visits),
      };

    } catch (e) {
      debugPrint('❌ خطأ في تحليل المواقع: $e');
      return {};
    }
  }

  // Generate location insights
  Future<List<Map<String, dynamic>>> _generateLocationInsights(List<LocationVisit> visits) async {
    final insights = <Map<String, dynamic>>[];

    try {
      if (visits.isEmpty) {
        insights.add({
          'type': 'no_data',
          'title': 'لا توجد بيانات كافية',
          'description': 'ابدأ بتتبع مواقعك للحصول على رؤى مفيدة',
          'icon': 'info',
        });
        return insights;
      }

      // Most visited place insight
      final placeFrequency = <String, int>{};
      for (final visit in visits) {
        final name = visit.placeName ?? 'موقع غير معروف';
        placeFrequency[name] = (placeFrequency[name] ?? 0) + 1;
      }

      if (placeFrequency.isNotEmpty) {
        final mostVisited = placeFrequency.entries.reduce((a, b) => a.value > b.value ? a : b);
        insights.add({
          'type': 'most_visited',
          'title': 'المكان الأكثر زيارة',
          'description': 'تزور ${mostVisited.key} بمعدل ${mostVisited.value} مرة',
          'value': mostVisited.value,
          'place': mostVisited.key,
          'icon': 'location_on',
        });
      }

      // Time analysis
      final totalTime = visits
          .where((v) => v.duration != null)
          .map((v) => v.duration!.inMinutes)
          .fold(0, (sum, duration) => sum + duration);

      if (totalTime > 0) {
        insights.add({
          'type': 'time_analysis',
          'title': 'إجمالي الوقت المتتبع',
          'description': 'تم تتبع ${(totalTime / 60).toStringAsFixed(1)} ساعة من تحركاتك',
          'value': totalTime,
          'icon': 'schedule',
        });
      }

      // New places discovery
      final recentVisits = visits.where((v) => v.visitFrequency == 1).length;
      if (recentVisits > 0) {
        insights.add({
          'type': 'exploration',
          'title': 'استكشاف أماكن جديدة',
          'description': 'اكتشفت $recentVisits مكان جديد مؤخراً',
          'value': recentVisits,
          'icon': 'explore',
        });
      }

      // Routine analysis
      final homeVisits = visits.where((v) => v.isHome).length;
      final workVisits = visits.where((v) => v.isWork).length;

      if (homeVisits > 0 || workVisits > 0) {
        final routinePercentage = ((homeVisits + workVisits) / visits.length * 100).round();
        insights.add({
          'type': 'routine',
          'title': 'نسبة الروتين اليومي',
          'description': '$routinePercentage% من وقتك في البيت والعمل',
          'value': routinePercentage,
          'icon': 'home_work',
        });
      }

    } catch (e) {
      debugPrint('❌ خطأ في إنشاء الرؤى: $e');
    }

    return insights;
  }

  // Set enhanced home location
  Future<bool> setHomeLocation(double latitude, double longitude, {String? name}) async {
    try {
      await _settingsRepo.setSetting('home_latitude', latitude, SettingValueType.double);
      await _settingsRepo.setSetting('home_longitude', longitude, SettingValueType.double);

      if (name != null) {
        await _settingsRepo.setSetting('home_name', name, SettingValueType.string);
      }

      await _updateNearbyVisitsAsHome(latitude, longitude);

      debugPrint('✅ تم حفظ موقع المنزل المحسن: $latitude, $longitude');
      return true;

    } catch (e) {
      debugPrint('❌ خطأ في حفظ موقع المنزل المحسن: $e');
      return false;
    }
  }

  // Set enhanced work location
  Future<bool> setWorkLocation(double latitude, double longitude, {String? name}) async {
    try {
      await _settingsRepo.setSetting('work_latitude', latitude, SettingValueType.double);
      await _settingsRepo.setSetting('work_longitude', longitude, SettingValueType.double);

      if (name != null) {
        await _settingsRepo.setSetting('work_name', name, SettingValueType.string);
      }

      await _updateNearbyVisitsAsWork(latitude, longitude);

      debugPrint('✅ تم حفظ موقع العمل المحسن: $latitude, $longitude');
      return true;

    } catch (e) {
      debugPrint('❌ خطأ في حفظ موقع العمل المحسن: $e');
      return false;
    }
  }

  // Update nearby visits as home
  Future<void> _updateNearbyVisitsAsHome(double latitude, double longitude) async {
    try {
      final visits = await _locationRepo.getLocationVisitsForDateRange(
        DateTime.now().subtract(const Duration(days: 30)).toIso8601String().split('T')[0],
        DateTime.now().toIso8601String().split('T')[0],
      );

      for (final visit in visits) {
        final distance = Geolocator.distanceBetween(
          latitude, longitude, visit.latitude, visit.longitude,
        );

        if (distance <= _minDistanceForNewVisit && visit.id != null) {
          await _locationRepo.setAsHome(visit.id!);
        }
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحديث الزيارات القريبة كمنزل: $e');
    }
  }

  // Update nearby visits as work
  Future<void> _updateNearbyVisitsAsWork(double latitude, double longitude) async {
    try {
      final visits = await _locationRepo.getLocationVisitsForDateRange(
        DateTime.now().subtract(const Duration(days: 30)).toIso8601String().split('T')[0],
        DateTime.now().toIso8601String().split('T')[0],
      );

      for (final visit in visits) {
        final distance = Geolocator.distanceBetween(
          latitude, longitude, visit.latitude, visit.longitude,
        );

        if (distance <= _minDistanceForNewVisit && visit.id != null) {
          await _locationRepo.setAsWork(visit.id!);
        }
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحديث الزيارات القريبة كعمل: $e');
    }
  }

  // Get visits for specific date
  Future<List<LocationVisit>> getVisitsForDate(String date) async {
    try {
      return await _locationRepo.getLocationVisitsForDate(date);
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على زيارات التاريخ المحسن: $e');
      return [];
    }
  }

  // Get frequent locations with enhanced data
  Future<List<Map<String, dynamic>>> getFrequentLocations({int limit = 10}) async {
    try {
      return await _locationRepo.getMostVisitedPlaces(limit: limit);
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على المواقع المتكررة المحسن: $e');
      return [];
    }
  }

  // Get distance between two points
  double getDistanceBetween(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  // Calculate movement speed
  double? calculateSpeed(Position pos1, Position pos2) {
    try {
      final distance = getDistanceBetween(
        pos1.latitude, pos1.longitude,
        pos2.latitude, pos2.longitude,
      );

      final timeDiff = pos2.timestamp?.difference(pos1.timestamp ?? DateTime.now()).inSeconds ?? 0;

      if (timeDiff > 0) {
        return distance / timeDiff; // meters per second
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // اختبار تشخيصي للتتبع
  Future<void> debugLocationTracking() async {
    try {
      debugPrint('🔍 بدء تشخيص تتبع المواقع...');

      // فحص الأذونات
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      final permission = await Geolocator.checkPermission();
      debugPrint('📡 خدمة الموقع مفعلة: $serviceEnabled');
      debugPrint('🔐 إذن الموقع: $permission');

      // فحص Geocoding
      debugPrint('🗺️ Geocoding متاح: $_geocodingAvailable');

      // فحص الحصول على موقع واحد
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        debugPrint('📍 موقع اختبار: ${position.latitude}, ${position.longitude} (±${position.accuracy}m)');
      } catch (e) {
        debugPrint('❌ فشل في اختبار الموقع: $e');
      }

      // فحص قاعدة البيانات
      final dbStats = await _locationRepo.getDatabaseStats();
      debugPrint('💾 إحصائيات قاعدة البيانات: $dbStats');

      debugPrint('✅ انتهاء تشخيص تتبع المواقع');

    } catch (e) {
      debugPrint('❌ خطأ في تشخيص تتبع المواقع: $e');
    }
  }

  // فرض حفظ الموقع الحالي
  Future<bool> forceCurrentLocationSave({
    String? customPlaceName,
    String? customPlaceType,
  }) async {
    try {
      debugPrint('💾 فرض حفظ الموقع الحالي...');

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      // البحث عن موقع مشابه
      final similarLocation = await _locationRepo.findSimilarLocation(
        position.latitude,
        position.longitude,
        radiusMeters: 80.0,
      );

      // ✅ استخدام الاسم المخصص أو الحصول على اسم من Geocoding
      String placeName = customPlaceName ?? 'موقع محفوظ يدوياً';

      // فقط إذا لم يتم تحديد اسم مخصص وكان Geocoding متاح
      if (customPlaceName == null && _geocodingAvailable) {
        try {
          final placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          ).timeout(const Duration(seconds: 5));

          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            placeName = place.name ?? place.thoroughfare ?? place.locality ?? placeName;
          }
        } catch (e) {
          debugPrint('⚠️ فشل في الحصول على اسم المكان: $e');
        }
      }

      // ✅ استخدام النوع المخصص أو الافتراضي
      final placeType = customPlaceType ?? 'manual';

      debugPrint('📝 [LocationService] الاسم: $placeName');
      debugPrint('📂 [LocationService] النوع: $placeType');

      // إنشاء زيارة جديدة
      final visit = LocationVisit(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        placeName: placeName,           // ✅ الاسم المخصص
        placeType: placeType,            // ✅ النوع المخصص
        arrivalTime: DateTime.now(),
        visitFrequency: (similarLocation?.visitFrequency ?? 0) + 1,
        isHome: similarLocation?.isHome ?? false,
        isWork: similarLocation?.isWork ?? false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // حفظ في قاعدة البيانات
      final visitId = await _locationRepo.insertLocationVisit(visit);
      if (visitId != null) {
        debugPrint('✅ تم حفظ الموقع يدوياً بمعرف: $visitId');

        // ✅ إعادة تعيين الزيارة الحالية
        if (_currentVisit != null) {
          _currentVisit = null;
        }

        return true;
      }

      return false;

    } catch (e) {
      debugPrint('❌ خطأ في فرض حفظ الموقع: $e');
      return false;
    }
  }

  // Enhanced diagnostic information
  Future<Map<String, dynamic>> getDiagnosticInfo() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      final permission = await Geolocator.checkPermission();
      final dbStats = await _locationRepo.getDatabaseStats();

      return {
        'service_enabled': serviceEnabled,
        'permission': permission.toString(),
        'tracking_active': _isTracking,
        'geocoding_available': _geocodingAvailable, // ✅ إضافة
        'current_visit': _currentVisit?.toMap(),
        'last_position': {
          'latitude': _lastKnownPosition?.latitude,
          'longitude': _lastKnownPosition?.longitude,
          'accuracy': _lastKnownPosition?.accuracy,
          'timestamp': _lastKnownPosition?.timestamp?.toIso8601String(),
        },
        'buffer_size': _positionBuffer.length,
        'database_stats': dbStats,
        'timers_active': {
          'location_update': _locationUpdateTimer?.isActive ?? false,
          'visit_validation': _visitValidationTimer?.isActive ?? false,
        },
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Dispose enhanced service
  Future<void> dispose() async {
    try {
      await stopLocationTracking();
      await _positionController.close();
      await _visitController.close();
      await _dailyPatternController.close();
      debugPrint('✅ تم التخلص من خدمة المواقع المحسنة');
    } catch (e) {
      debugPrint('❌ خطأ في التخلص من خدمة المواقع المحسنة: $e');
    }
  }
}

// Enhanced place information class
class PlaceInfo {
  final String? name;
  final String? type;
  final String? category;
  final MoodImpact? moodImpact;
  final bool isHome;
  final bool isWork;
  final String? address;

  const PlaceInfo({
    this.name,
    this.type,
    this.category,
    this.moodImpact,
    this.isHome = false,
    this.isWork = false,
    this.address,
  });

  @override
  String toString() {
    return 'PlaceInfo(name: $name, type: $type, category: $category, home: $isHome, work: $isWork)';
  }
}