// lib/core/providers/base/base_provider.dart
// Base Provider Class - الفئة الأساسية لجميع المزودات

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'base_state.dart';

/// Base provider class - الفئة الأساسية لجميع المزودات
abstract class BaseProvider<T extends BaseState> extends ChangeNotifier {
  T _state;

  BaseProvider(this._state);

  /// Current state getter - محصل الحالة الحالية
  T get state => _state;

  /// Protected state setter - محدد الحالة المحمي
  @protected
  void setState(T newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  /// Safe state update with error handling - تحديث آمن للحالة مع معالجة الأخطاء
  @protected
  Future<void> safeStateUpdate(Future<T> Function() updateFunction) async {
    try {
      final newState = await updateFunction();
      setState(newState);
    } catch (error, stackTrace) {
      debugPrint('❌ خطأ في تحديث الحالة: $error');
      final appError = _mapErrorToAppError(error, stackTrace);
      setState(_createErrorState(appError));
    }
  }

  /// Execute operation with loading states - تنفيذ عملية مع حالات التحميل
  @protected
  Future<void> executeWithLoading(
      Future<void> Function() operation, {
        bool useRefreshing = false,
      }) async {
    setState(_createLoadingState(useRefreshing));

    try {
      await operation();
      setState(_createSuccessState());
    } catch (error, stackTrace) {
      debugPrint('❌ خطأ في تنفيذ العملية: $error');
      final appError = _mapErrorToAppError(error, stackTrace);
      setState(_createErrorState(appError));
    }
  }

  /// Execute operation with result handling - تنفيذ عملية مع معالجة النتيجة
  @protected
  Future<R?> executeWithResult<R>(
      Future<R> Function() operation, {
        bool updateStateOnError = true,
        bool showLoading = true,
      }) async {
    if (showLoading) {
      setState(_createLoadingState(false));
    }

    try {
      final result = await operation();
      if (showLoading) {
        setState(_createSuccessState());
      }
      return result;
    } catch (error, stackTrace) {
      debugPrint('❌ خطأ في تنفيذ العملية مع النتيجة: $error');
      if (updateStateOnError) {
        final appError = _mapErrorToAppError(error, stackTrace);
        setState(_createErrorState(appError));
      }
      return null;
    }
  }

  /// Retry mechanism for failed operations - آلية إعادة المحاولة للعمليات الفاشلة
  @protected
  Future<void> retryOperation(
      Future<void> Function() operation, {
        int maxRetries = 3,
        Duration delayBetweenRetries = const Duration(seconds: 2),
      }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        await operation();
        return; // Success, exit retry loop
      } catch (error, stackTrace) {
        attempts++;
        debugPrint('❌ محاولة $attempts من $maxRetries فشلت: $error');

        if (attempts >= maxRetries) {
          // Final attempt failed, set error state
          final appError = _mapErrorToAppError(error, stackTrace);
          setState(_createErrorState(appError));
          return;
        }

        // Wait before next attempt
        await Future.delayed(delayBetweenRetries);
      }
    }
  }

  /// Clear error state - مسح حالة الخطأ
  void clearError() {
    if (state.hasError) {
      setState(_createSuccessState());
    }
  }

  /// Clear success message - مسح رسالة النجاح
  void clearSuccessMessage() {
    if (state.hasSuccess) {
      setState(_createIdleState());
    }
  }

  /// Force refresh data - فرض تحديث البيانات
  Future<void> refresh() async {
    await executeWithLoading(() => refreshData(), useRefreshing: true);
  }

  /// Abstract method to refresh data - دالة مجردة لتحديث البيانات
  @protected
  Future<void> refreshData();

  /// Abstract methods for state creation - دوال مجردة لإنشاء الحالات
  @protected
  T _createLoadingState(bool isRefreshing);

  @protected
  T _createSuccessState();

  @protected
  T _createErrorState(AppError error);

  @protected
  T _createIdleState();

  /// Map generic errors to AppError types - تحويل الأخطاء العامة إلى أنواع AppError
  AppError _mapErrorToAppError(dynamic error, StackTrace stackTrace) {
    if (error is AppError) {
      return error;
    }

    // Map common error types
    if (error is TimeoutException) {
      return NetworkError(
        message: 'انتهت مهلة الاتصال',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is FormatException) {
      return ValidationError(
        message: 'تنسيق البيانات غير صحيح',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Check error message for specific patterns
    final errorMessage = error.toString().toLowerCase();

    if (errorMessage.contains('network') ||
        errorMessage.contains('connection') ||
        errorMessage.contains('internet')) {
      return NetworkError(
        message: error.toString(),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (errorMessage.contains('permission') ||
        errorMessage.contains('denied')) {
      return PermissionError(
        message: error.toString(),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (errorMessage.contains('database') ||
        errorMessage.contains('sql')) {
      return DatabaseError(
        message: error.toString(),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Default to service error
    return ServiceError(
      message: error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Dispose resources - تنظيف الموارد
  @override
  void dispose() {
    debugPrint('🗑️ تنظيف مزود: ${runtimeType.toString()}');
    super.dispose();
  }

  /// Get provider name for debugging - الحصول على اسم المزود للتصحيح
  @protected
  String get providerName => runtimeType.toString();

  /// Log state changes for debugging - تسجيل تغييرات الحالة للتصحيح
  @protected
  void logStateChange(T oldState, T newState) {
    if (kDebugMode) {
      debugPrint(
          '🔄 [$providerName] State Changed:\n'
              '   من: ${oldState.loadingState}\n'
              '   إلى: ${newState.loadingState}\n'
              '   وقت: ${DateTime.now()}'
      );
    }
  }

  /// Enhanced setState with logging - محدد حالة محسن مع التسجيل
  @protected
  void setStateWithLogging(T newState) {
    final oldState = _state;
    setState(newState);
    logStateChange(oldState, newState);
  }

  /// Batch multiple state updates - تجميع تحديثات الحالة المتعددة
  @protected
  void batchStateUpdates(List<T Function(T)> updates) {
    T currentState = _state;

    for (final update in updates) {
      currentState = update(currentState);
    }

    setState(currentState);
  }

  /// Check if provider is disposed - فحص إذا كان المزود قد تم التخلص منه
  bool get isDisposed => !hasListeners;

  /// Safe notification that checks if disposed - إشعار آمن يفحص إذا كان تم التخلص منه
  @protected
  void safeNotifyListeners() {
    if (!isDisposed) {
      notifyListeners();
    }
  }
}

/// Mixin for providers that need periodic updates - خليط للمزودات التي تحتاج تحديثات دورية
mixin PeriodicUpdateMixin<T extends BaseState> on BaseProvider<T> {
  Timer? _periodicTimer;
  Duration _updateInterval = const Duration(minutes: 5);

  /// Start periodic updates - بدء التحديثات الدورية
  void startPeriodicUpdates({Duration? interval}) {
    if (interval != null) {
      _updateInterval = interval;
    }

    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(_updateInterval, (timer) {
      if (!isDisposed) {
        performPeriodicUpdate();
      } else {
        timer.cancel();
      }
    });

    debugPrint('📅 تم بدء التحديثات الدورية كل ${_updateInterval.inMinutes} دقيقة');
  }

  /// Stop periodic updates - إيقاف التحديثات الدورية
  void stopPeriodicUpdates() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    debugPrint('⏹️ تم إيقاف التحديثات الدورية');
  }

  /// Abstract method for periodic update logic - دالة مجردة لمنطق التحديث الدوري
  @protected
  Future<void> performPeriodicUpdate();

  @override
  void dispose() {
    stopPeriodicUpdates();
    super.dispose();
  }
}

/// Mixin for providers that support caching - خليط للمزودات التي تدعم التخزين المؤقت
mixin CacheMixin<T extends BaseState> on BaseProvider<T> {
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  Duration _cacheExpiry = const Duration(minutes: 10);

  /// Set cache expiry duration - تحديد مدة انتهاء صلاحية التخزين المؤقت
  void setCacheExpiry(Duration duration) {
    _cacheExpiry = duration;
  }

  /// Cache data with key - تخزين البيانات مؤقتاً مع مفتاح
  void cacheData(String key, dynamic data) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
  }

  /// Get cached data if valid - الحصول على البيانات المخزنة مؤقتاً إذا كانت صالحة
  dynamic getCachedData(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return null;

    final isExpired = DateTime.now().difference(timestamp) > _cacheExpiry;
    if (isExpired) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
      return null;
    }

    return _cache[key];
  }

  /// Clear all cache - مسح جميع البيانات المخزنة مؤقتاً
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    debugPrint('🗑️ تم مسح جميع البيانات المخزنة مؤقتاً');
  }

  /// Clear expired cache entries - مسح البيانات المنتهية الصلاحية
  void clearExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _cacheExpiry) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      debugPrint('🗑️ تم مسح ${expiredKeys.length} عنصر منتهي الصلاحية من التخزين المؤقت');
    }
  }

  @override
  void dispose() {
    clearCache();
    super.dispose();
  }
}