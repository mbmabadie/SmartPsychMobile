// lib/core/providers/enhanced_location_provider.dart
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../database/models/activity_models.dart';
import '../database/repositories/location_repository.dart';
import '../services/location_service.dart';

/// حالات التحميل المختلفة
enum LocationLoadingState {
  idle,
  loading,
  refreshing,
  error
}

/// نوع الفلترة للبيانات
enum LocationFilterType {
  all,
  today,
  yesterday,
  week,
  month,
  custom
}

/// حالة بيانات المواقع المحسنة
class LocationState {
  final List<LocationVisit> visits;
  final List<Map<String, dynamic>> frequentPlaces;
  final Map<String, LocationVisit?> savedPlaces;
  final Map<String, dynamic> analytics;
  final List<Map<String, dynamic>> insights;
  final LocationLoadingState loadingState;
  final String? error;
  final bool isTracking;
  final LocationVisit? currentVisit;
  final LocationFilterType filterType;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const LocationState({
    this.visits = const [],
    this.frequentPlaces = const [],
    this.savedPlaces = const {},
    this.analytics = const {},
    this.insights = const [],
    this.loadingState = LocationLoadingState.idle,
    this.error,
    this.isTracking = false,
    this.currentVisit,
    this.filterType = LocationFilterType.today,
    this.customStartDate,
    this.customEndDate,
  });

  LocationState copyWith({
    List<LocationVisit>? visits,
    List<Map<String, dynamic>>? frequentPlaces,
    Map<String, LocationVisit?>? savedPlaces,
    Map<String, dynamic>? analytics,
    List<Map<String, dynamic>>? insights,
    LocationLoadingState? loadingState,
    String? error,
    bool? isTracking,
    LocationVisit? currentVisit,
    LocationFilterType? filterType,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) {
    return LocationState(
      visits: visits ?? this.visits,
      frequentPlaces: frequentPlaces ?? this.frequentPlaces,
      savedPlaces: savedPlaces ?? this.savedPlaces,
      analytics: analytics ?? this.analytics,
      insights: insights ?? this.insights,
      loadingState: loadingState ?? this.loadingState,
      error: error,
      isTracking: isTracking ?? this.isTracking,
      currentVisit: currentVisit,
      filterType: filterType ?? this.filterType,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
    );
  }
}

/// Provider محسن لإدارة بيانات المواقع - يعتمد كلياً على LocationService
class LocationProvider extends ChangeNotifier {
  final LocationRepository _repository = LocationRepository();
  final LocationService _locationService = LocationService.instance;

  LocationState _state = const LocationState();
  LocationState get state => _state;

  // Getters للوصول السريع للبيانات
  List<LocationVisit> get visits => _state.visits;
  List<Map<String, dynamic>> get frequentPlaces => _state.frequentPlaces;
  Map<String, LocationVisit?> get savedPlaces => _state.savedPlaces;
  Map<String, dynamic> get analytics => _state.analytics;
  List<Map<String, dynamic>> get insights => _state.insights;
  bool get isLoading => _state.loadingState == LocationLoadingState.loading;
  bool get isRefreshing => _state.loadingState == LocationLoadingState.refreshing;
  bool get hasError => _state.error != null;
  String? get error => _state.error;
  bool get isTracking => _state.isTracking;
  LocationVisit? get currentVisit => _state.currentVisit;

  /// ✅ تهيئة Provider - مبسطة ومعتمدة على LocationService
  Future<bool> initialize() async {
    try {
      debugPrint('🔧 تهيئة LocationProvider المُحسّن...');
      _updateState(loadingState: LocationLoadingState.loading);

      // 1. تهيئة خدمة المواقع
      final serviceInitialized = await _locationService.initialize();
      if (!serviceInitialized) {
        _updateState(
          loadingState: LocationLoadingState.error,
          error: 'فشل في تهيئة خدمة المواقع',
        );
        return false;
      }

      // 2. تحميل البيانات الموجودة من قاعدة البيانات
      await _loadInitialData();

      // 3. الاستماع لتحديثات LocationService
      _subscribeToLocationService();

      // 4. بدء التتبع التلقائي
      final trackingStarted = await _locationService.startLocationTracking();
      if (!trackingStarted) {
        debugPrint('⚠️ فشل في بدء التتبع التلقائي');
      }

      // 5. تحديث الحالة من LocationService
      _syncWithLocationService();

      _updateState(loadingState: LocationLoadingState.idle, error: null);
      debugPrint('✅ تم تهيئة LocationProvider بنجاح');

      return true;

    } catch (e) {
      debugPrint('❌ خطأ في تهيئة LocationProvider: $e');
      _updateState(
        loadingState: LocationLoadingState.error,
        error: 'خطأ في التهيئة: ${e.toString()}',
      );
      return false;
    }
  }

  /// ✅ الاستماع لتحديثات LocationService
  void _subscribeToLocationService() {
    // الاستماع للزيارات المكتملة (المحفوظة من LocationService)
    _locationService.visitStream.listen(
          (visit) {
        debugPrint('📥 زيارة مكتملة من LocationService: ${visit.placeName ?? 'مكان غير معروف'}');
        _onNewVisitCompleted(visit);
      },
      onError: (error) {
        debugPrint('❌ خطأ في visitStream: $error');
      },
    );

    // الاستماع لتحديثات المواقع (للحصول على currentVisit)
    _locationService.positionStream.listen(
          (position) {
        _syncWithLocationService();
      },
      onError: (error) {
        debugPrint('❌ خطأ في positionStream: $error');
      },
    );

    debugPrint('✅ تم الاشتراك في streams الخاصة بـ LocationService');
  }

  /// ✅ مزامنة الحالة مع LocationService
  void _syncWithLocationService() {
    final isTracking = _locationService.isTracking;
    final currentVisit = _locationService.currentVisit;

    if (isTracking != _state.isTracking || currentVisit != _state.currentVisit) {
      _updateState(
        isTracking: isTracking,
        currentVisit: currentVisit,
      );

      if (currentVisit != null) {
        debugPrint('📍 موقع حالي محدّث: ${currentVisit.placeName ?? 'غير معروف'}');
      }
    }
  }

  /// ✅ معالجة زيارة مكتملة من LocationService
  void _onNewVisitCompleted(LocationVisit visit) {
    try {
      // Visit محفوظ بالفعل من LocationService، نضيفه للقائمة فقط
      final updatedVisits = [visit, ..._state.visits];

      // إزالة التكرارات (بناءً على ID)
      final uniqueVisits = <int, LocationVisit>{};
      for (final v in updatedVisits) {
        if (v.id != null) {
          uniqueVisits[v.id!] = v;
        }
      }

      _updateState(visits: uniqueVisits.values.toList());

      // تحديث البيانات المتأثرة
      _loadAnalytics();
      _loadFrequentPlaces();

      debugPrint('✅ تمت إضافة زيارة مكتملة إلى القائمة');

    } catch (e) {
      debugPrint('❌ خطأ في معالجة زيارة مكتملة: $e');
    }
  }

  /// تحميل البيانات الأولية من قاعدة البيانات
  Future<void> _loadInitialData() async {
    try {
      await Future.wait([
        _loadVisitsForCurrentFilter(),
        _loadFrequentPlaces(),
        _loadSavedPlaces(),
        _loadAnalytics(),
        _loadInsights(),
      ]);

      debugPrint('✅ تم تحميل البيانات الأولية من قاعدة البيانات');
    } catch (e) {
      debugPrint('❌ خطأ في تحميل البيانات الأولية: $e');
      throw e;
    }
  }

  /// تحديث اسم مكان مع تحديث جميع الزيارات المشابهة
  Future<bool> updatePlaceName(int visitId, String newName) async {
    try {
      debugPrint('📝 تحديث اسم المكان: $newName');

      // العثور على الزيارة المحددة
      final targetVisit = _state.visits.firstWhere((v) => v.id == visitId);

      // تحديث اسم المكان في قاعدة البيانات
      final success = await _repository.updateLocationDetails(
        visitId,
        placeName: newName,
      );

      if (success) {
        // تحديث جميع الزيارات المشابهة (في نطاق 100 متر)
        await _updateSimilarLocationsName(targetVisit, newName);

        // تحديث الزيارات في الحالة المحلية
        final updatedVisits = _state.visits.map((visit) {
          // تحديث الزيارة المستهدفة
          if (visit.id == visitId) {
            return visit.copyWith(placeName: newName);
          }

          // تحديث الزيارات المشابهة
          final distance = _locationService.getDistanceBetween(
            visit.latitude,
            visit.longitude,
            targetVisit.latitude,
            targetVisit.longitude,
          );

          if (distance <= 100.0) {
            return visit.copyWith(placeName: newName);
          }

          return visit;
        }).toList();

        // تحديث الزيارة الحالية إذا كانت مشابهة
        LocationVisit? updatedCurrentVisit = _state.currentVisit;
        if (_state.currentVisit != null) {
          final currentDistance = _locationService.getDistanceBetween(
            _state.currentVisit!.latitude,
            _state.currentVisit!.longitude,
            targetVisit.latitude,
            targetVisit.longitude,
          );

          if (currentDistance <= 100.0) {
            updatedCurrentVisit = _state.currentVisit!.copyWith(placeName: newName);
          }
        }

        _updateState(
          visits: updatedVisits,
          currentVisit: updatedCurrentVisit,
        );

        // إعادة تحميل البيانات المتأثرة
        await _loadFrequentPlaces();

        debugPrint('✅ تم تحديث اسم المكان بنجاح');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ خطأ في تحديث اسم المكان: $e');
      _updateState(error: 'خطأ في تحديث اسم المكان: ${e.toString()}');
      return false;
    }
  }

  /// تحديث الأماكن المشابهة بنفس الاسم
  Future<void> _updateSimilarLocationsName(
      LocationVisit targetVisit, String newName) async {
    try {
      final allVisits = await _repository.getLocationVisitsForDateRange(
        DateTime.now().subtract(const Duration(days: 365)).toIso8601String().split('T')[0],
        DateTime.now().toIso8601String().split('T')[0],
      );

      for (final visit in allVisits) {
        if (visit.id != targetVisit.id) {
          final distance = _locationService.getDistanceBetween(
            visit.latitude,
            visit.longitude,
            targetVisit.latitude,
            targetVisit.longitude,
          );

          // تحديث الزيارات في نطاق 100 متر
          if (distance <= 100.0) {
            await _repository.updateLocationDetails(
              visit.id!,
              placeName: newName,
            );
          }
        }
      }

      debugPrint('✅ تم تحديث الأماكن المشابهة');
    } catch (e) {
      debugPrint('❌ خطأ في تحديث الأماكن المشابهة: $e');
    }
  }

  /// فتح الموقع في Google Maps
  Future<void> openLocationInGoogleMaps(
      double latitude,
      double longitude, {
        String? placeName,
      }) async {
    try {
      final String googleMapsUrl =
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
      final Uri googleMapsUri = Uri.parse(googleMapsUrl);

      debugPrint('🗺️ فتح الموقع في خرائط Google: $latitude, $longitude');

      if (await canLaunchUrl(googleMapsUri)) {
        await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
        debugPrint('✅ تم فتح خرائط Google بنجاح');
      } else {
        // في حالة فشل فتح الخرائط، مشاركة الموقع
        final locationText =
            'الموقع: $latitude,$longitude${placeName != null ? ' - $placeName' : ''}';
        await Share.share(locationText);
        debugPrint('📤 تم مشاركة الموقع كنص');
      }
    } catch (e) {
      debugPrint('❌ خطأ في فتح خرائط Google: $e');

      // محاولة مشاركة الموقع كبديل
      try {
        final locationText =
            'الموقع: $latitude,$longitude${placeName != null ? ' - $placeName' : ''}';
        await Share.share(locationText);
      } catch (shareError) {
        debugPrint('❌ خطأ في مشاركة الموقع: $shareError');
        _updateState(error: 'فشل في فتح خرائط Google');
      }
    }
  }

  /// إعادة تحميل جميع البيانات
  Future<void> refresh() async {
    _updateState(loadingState: LocationLoadingState.refreshing);

    try {
      // مزامنة مع LocationService
      _syncWithLocationService();

      // تحميل البيانات من قاعدة البيانات
      await _loadInitialData();

      _updateState(loadingState: LocationLoadingState.idle, error: null);
      debugPrint('✅ تم تحديث البيانات');
    } catch (e) {
      debugPrint('❌ خطأ في تحديث البيانات: $e');
      _updateState(
        loadingState: LocationLoadingState.error,
        error: 'خطأ في التحديث: ${e.toString()}',
      );
    }
  }

  /// تغيير نوع الفلترة
  Future<void> changeFilter(
      LocationFilterType filterType, {
        DateTime? startDate,
        DateTime? endDate,
      }) async {
    _updateState(
      filterType: filterType,
      customStartDate: startDate,
      customEndDate: endDate,
      loadingState: LocationLoadingState.loading,
    );

    try {
      await _loadVisitsForCurrentFilter();
      await _loadAnalytics();
      _updateState(loadingState: LocationLoadingState.idle, error: null);
      debugPrint('✅ تم تطبيق الفلتر: $filterType');
    } catch (e) {
      debugPrint('❌ خطأ في تطبيق الفلتر: $e');
      _updateState(
        loadingState: LocationLoadingState.error,
        error: 'خطأ في تطبيق الفلتر: ${e.toString()}',
      );
    }
  }

  /// تحميل الزيارات حسب الفلتر الحالي
  Future<void> _loadVisitsForCurrentFilter() async {
    List<LocationVisit> visits = [];

    try {
      switch (_state.filterType) {
        case LocationFilterType.today:
          final today = DateTime.now();
          final dateStr =
              '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          visits = await _repository.getLocationVisitsForDate(dateStr);
          break;

        case LocationFilterType.yesterday:
          final yesterday = DateTime.now().subtract(const Duration(days: 1));
          final dateStr =
              '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
          visits = await _repository.getLocationVisitsForDate(dateStr);
          break;

        case LocationFilterType.week:
          final now = DateTime.now();
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          final startDate =
              '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
          final endDate =
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
          visits = await _repository.getLocationVisitsForDateRange(
              startDate, endDate);
          break;

        case LocationFilterType.month:
          final now = DateTime.now();
          final monthStart = DateTime(now.year, now.month, 1);
          final startDate =
              '${monthStart.year}-${monthStart.month.toString().padLeft(2, '0')}-${monthStart.day.toString().padLeft(2, '0')}';
          final endDate =
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
          visits = await _repository.getLocationVisitsForDateRange(
              startDate, endDate);
          break;

        case LocationFilterType.custom:
          if (_state.customStartDate != null && _state.customEndDate != null) {
            final startDate =
                '${_state.customStartDate!.year}-${_state.customStartDate!.month.toString().padLeft(2, '0')}-${_state.customStartDate!.day.toString().padLeft(2, '0')}';
            final endDate =
                '${_state.customEndDate!.year}-${_state.customEndDate!.month.toString().padLeft(2, '0')}-${_state.customEndDate!.day.toString().padLeft(2, '0')}';
            visits = await _repository.getLocationVisitsForDateRange(
                startDate, endDate);
          }
          break;

        case LocationFilterType.all:
          final now = DateTime.now();
          final monthsBack = now.subtract(const Duration(days: 90));
          final startDate =
              '${monthsBack.year}-${monthsBack.month.toString().padLeft(2, '0')}-${monthsBack.day.toString().padLeft(2, '0')}';
          final endDate =
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
          visits = await _repository.getLocationVisitsForDateRange(
              startDate, endDate);
          break;
      }

      _updateState(visits: visits);
      debugPrint('✅ تم تحميل ${visits.length} زيارة');
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الزيارات: $e');
    }
  }

  /// تحميل الأماكن المتكررة
  Future<void> _loadFrequentPlaces() async {
    try {
      final frequentPlaces = await _repository.getMostVisitedPlaces(limit: 15);
      _updateState(frequentPlaces: frequentPlaces);
      debugPrint('✅ تم تحميل ${frequentPlaces.length} مكان متكرر');
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الأماكن المتكررة: $e');
    }
  }

  /// تحميل الأماكن المحفوظة (البيت والعمل)
  Future<void> _loadSavedPlaces() async {
    try {
      final savedPlaces = await _repository.getSavedPlaces();
      _updateState(savedPlaces: savedPlaces);
      debugPrint('✅ تم تحميل الأماكن المحفوظة');
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الأماكن المحفوظة: $e');
    }
  }

  /// تحميل التحليلات والإحصائيات
  Future<void> _loadAnalytics() async {
    try {
      final dates = _getDateRangeForFilter();
      final analytics = await _locationService.getLocationAnalytics(
        startDate: dates['start']!,
        endDate: dates['end']!,
      );
      _updateState(analytics: analytics);
      debugPrint('✅ تم تحميل التحليلات');
    } catch (e) {
      debugPrint('❌ خطأ في تحميل التحليلات: $e');
    }
  }

  /// تحميل الرؤى الذكية
  Future<void> _loadInsights() async {
    try {
      final dates = _getDateRangeForFilter();
      final analytics = await _locationService.getLocationAnalytics(
        startDate: dates['start']!,
        endDate: dates['end']!,
      );
      final insights =
          analytics['insights'] as List<Map<String, dynamic>>? ?? [];
      _updateState(insights: insights);
      debugPrint('✅ تم تحميل ${insights.length} رؤية');
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الرؤى: $e');
    }
  }

  /// الحصول على نطاق التواريخ للفلتر الحالي
  Map<String, String> _getDateRangeForFilter() {
    final now = DateTime.now();

    switch (_state.filterType) {
      case LocationFilterType.today:
        final dateStr =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        return {'start': dateStr, 'end': dateStr};

      case LocationFilterType.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        final dateStr =
            '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
        return {'start': dateStr, 'end': dateStr};

      case LocationFilterType.week:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final startDate =
            '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
        final endDate =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        return {'start': startDate, 'end': endDate};

      case LocationFilterType.month:
        final monthStart = DateTime(now.year, now.month, 1);
        final startDate =
            '${monthStart.year}-${monthStart.month.toString().padLeft(2, '0')}-${monthStart.day.toString().padLeft(2, '0')}';
        final endDate =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        return {'start': startDate, 'end': endDate};

      case LocationFilterType.custom:
        if (_state.customStartDate != null && _state.customEndDate != null) {
          final startDate =
              '${_state.customStartDate!.year}-${_state.customStartDate!.month.toString().padLeft(2, '0')}-${_state.customStartDate!.day.toString().padLeft(2, '0')}';
          final endDate =
              '${_state.customEndDate!.year}-${_state.customEndDate!.month.toString().padLeft(2, '0')}-${_state.customEndDate!.day.toString().padLeft(2, '0')}';
          return {'start': startDate, 'end': endDate};
        }
        break;

      case LocationFilterType.all:
        final monthsBack = now.subtract(const Duration(days: 90));
        final startDate =
            '${monthsBack.year}-${monthsBack.month.toString().padLeft(2, '0')}-${monthsBack.day.toString().padLeft(2, '0')}';
        final endDate =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        return {'start': startDate, 'end': endDate};
    }

    // Default fallback
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return {'start': dateStr, 'end': dateStr};
  }

  /// إحصائيات سريعة للواجهة
  Map<String, dynamic> getQuickStats() {
    final visits = _state.visits;

    // حساب عدد الزيارات الكلي
    final totalVisits = visits.length;

    // حساب عدد الأماكن الفريدة
    final uniquePlaces = visits
        .map((v) =>
    '${v.latitude.toStringAsFixed(4)},${v.longitude.toStringAsFixed(4)}')
        .toSet()
        .length;

    // حساب إجمالي الوقت
    final totalTime = visits
        .where((v) => v.duration != null)
        .map((v) => v.duration!.inMinutes)
        .fold(0, (sum, duration) => sum + duration);

    final homeVisits = visits.where((v) => v.isHome).length;
    final workVisits = visits.where((v) => v.isWork).length;

    return {
      'total_visits': totalVisits,
      'unique_places': uniquePlaces,
      'total_time_hours': totalTime / 60.0,
      'home_visits': homeVisits,
      'work_visits': workVisits,
      'avg_visit_duration_minutes':
      totalVisits > 0 ? totalTime / totalVisits : 0,
      'filter_type': _state.filterType.toString().split('.').last,
      'current_location': _state.currentVisit?.placeName ?? 'غير محدد',
      'is_tracking': _state.isTracking,
    };
  }

  /// تحديث الحالة وإشعار المستمعين
  void _updateState({
    List<LocationVisit>? visits,
    List<Map<String, dynamic>>? frequentPlaces,
    Map<String, LocationVisit?>? savedPlaces,
    Map<String, dynamic>? analytics,
    List<Map<String, dynamic>>? insights,
    LocationLoadingState? loadingState,
    String? error,
    bool? isTracking,
    LocationVisit? currentVisit,
    LocationFilterType? filterType,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) {
    _state = _state.copyWith(
      visits: visits,
      frequentPlaces: frequentPlaces,
      savedPlaces: savedPlaces,
      analytics: analytics,
      insights: insights,
      loadingState: loadingState,
      error: error,
      isTracking: isTracking,
      currentVisit: currentVisit,
      filterType: filterType,
      customStartDate: customStartDate,
      customEndDate: customEndDate,
    );

    notifyListeners();
  }

  /// تعيين مكان كمنزل
  Future<bool> setAsHome(int visitId) async {
    try {
      final success = await _repository.setAsHome(visitId);

      if (success) {
        await _loadSavedPlaces();
        await _loadFrequentPlaces();
        debugPrint('✅ تم تعيين المكان كمنزل');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ خطأ في تعيين المكان كمنزل: $e');
      _updateState(error: 'خطأ في تعيين المكان كمنزل: ${e.toString()}');
      return false;
    }
  }

  /// تعيين مكان كعمل
  Future<bool> setAsWork(int visitId) async {
    try {
      final success = await _repository.setAsWork(visitId);

      if (success) {
        await _loadSavedPlaces();
        await _loadFrequentPlaces();
        debugPrint('✅ تم تعيين المكان كعمل');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ خطأ في تعيين المكان كعمل: $e');
      _updateState(error: 'خطأ في تعيين المكان كعمل: ${e.toString()}');
      return false;
    }
  }

  /// حذف زيارة
  Future<bool> deleteVisit(int visitId) async {
    try {
      final success = await _repository.deleteLocationVisit(visitId);

      if (success) {
        final updatedVisits =
        _state.visits.where((visit) => visit.id != visitId).toList();
        _updateState(visits: updatedVisits);

        _loadFrequentPlaces();
        _loadAnalytics();
        debugPrint('✅ تم حذف الزيارة');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ خطأ في حذف الزيارة: $e');
      _updateState(error: 'خطأ في حذف الزيارة: ${e.toString()}');
      return false;
    }
  }

  /// مسح الأخطاء
  void clearError() {
    if (_state.error != null) {
      _updateState(error: null);
    }
  }

  @override
  void dispose() {
    debugPrint('🗑️ تدمير LocationProvider');
    super.dispose();
  }
}