// lib/core/providers/base/base_state.dart
// Base State Classes - القواعد المشتركة لجميع الحالات

import 'package:flutter/foundation.dart';

/// Loading states enum - حالات التحميل
enum LoadingState {
  idle,     // في الراحة
  loading,  // يحمل
  success,  // نجح
  error,    // خطأ
  refreshing, // يحديث
}

/// Base error class - فئة الأخطاء الأساسية
@immutable
abstract class AppError {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  // ✅ تصحيح: إزالة const وإنشاء constructor عادي
  AppError({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'AppError(code: $code, message: $message)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is AppError &&
              runtimeType == other.runtimeType &&
              message == other.message &&
              code == other.code;

  @override
  int get hashCode => message.hashCode ^ code.hashCode;
}

/// Specific error types - أنواع الأخطاء المحددة
class NetworkError extends AppError {
  NetworkError({
    required super.message,
    String? code,
    super.originalError,
    super.stackTrace,
    super.timestamp,
  }) : super(
    code: code ?? 'network_error',
  );
}

class DatabaseError extends AppError {
  DatabaseError({
    required super.message,
    String? code,
    super.originalError,
    super.stackTrace,
    super.timestamp,
  }) : super(
    code: code ?? 'database_error',
  );
}

class PermissionError extends AppError {
  PermissionError({
    required super.message,
    String? code,
    super.originalError,
    super.stackTrace,
    super.timestamp,
  }) : super(
    code: code ?? 'permission_error',
  );
}

class ServiceError extends AppError {
  ServiceError({
    required super.message,
    String? code,
    super.originalError,
    super.stackTrace,
    super.timestamp,
  }) : super(
    code: code ?? 'service_error',
  );
}

class ValidationError extends AppError {
  ValidationError({
    required super.message,
    String? code,
    super.originalError,
    super.stackTrace,
    super.timestamp,
  }) : super(
    code: code ?? 'validation_error',
  );
}

/// Base state class - الفئة الأساسية لجميع الحالات
@immutable
abstract class BaseState {
  final LoadingState loadingState;
  final AppError? error;
  final DateTime lastUpdated;
  final bool hasData;
  final String? successMessage;

  // ✅ تصحيح: إزالة const وإنشاء constructor عادي
  BaseState({
    this.loadingState = LoadingState.idle,
    this.error,
    DateTime? lastUpdated,
    this.hasData = false,
    this.successMessage,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  // Computed properties - الخصائص المحسوبة
  bool get isIdle => loadingState == LoadingState.idle;
  bool get isLoading => loadingState == LoadingState.loading;
  bool get isRefreshing => loadingState == LoadingState.refreshing;
  bool get isSuccess => loadingState == LoadingState.success;
  bool get isError => loadingState == LoadingState.error;
  bool get hasError => error != null;
  bool get hasSuccess => successMessage != null;

  // Check specific error types - فحص أنواع الأخطاء المحددة
  bool get isNetworkError => error is NetworkError;
  bool get isDatabaseError => error is DatabaseError;
  bool get isPermissionError => error is PermissionError;
  bool get isServiceError => error is ServiceError;
  bool get isValidationError => error is ValidationError;

  // Error messages in Arabic - رسائل الأخطاء بالعربية
  String get errorMessage {
    if (error == null) return '';

    switch (error.runtimeType) {
      case NetworkError:
        return 'خطأ في الاتصال بالإنترنت. تحقق من اتصالك وحاول مرة أخرى.';
      case DatabaseError:
        return 'خطأ في قاعدة البيانات. حاول مرة أخرى.';
      case PermissionError:
        return 'يتطلب إذن للوصول لهذه الميزة. اذهب للإعدادات لتفعيل الأذونات.';
      case ServiceError:
        return 'خطأ في الخدمة. حاول مرة أخرى لاحقاً.';
      case ValidationError:
        return error!.message; // Use original message for validation
      default:
        return error!.message.isNotEmpty
            ? error!.message
            : 'حدث خطأ غير متوقع. حاول مرة أخرى.';
    }
  }

  // Time since last update - الوقت منذ آخر تحديث
  Duration get timeSinceLastUpdate => DateTime.now().difference(lastUpdated);

  bool get isDataStale => timeSinceLastUpdate.inMinutes > 5; // Data older than 5 minutes

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is BaseState &&
              runtimeType == other.runtimeType &&
              loadingState == other.loadingState &&
              error == other.error &&
              hasData == other.hasData &&
              successMessage == other.successMessage;

  @override
  int get hashCode =>
      loadingState.hashCode ^
      error.hashCode ^
      hasData.hashCode ^
      successMessage.hashCode;

  @override
  String toString() {
    return '$runtimeType('
        'loadingState: $loadingState, '
        'hasError: $hasError, '
        'hasData: $hasData, '
        'lastUpdated: $lastUpdated'
        ')';
  }
}

/// Mixin for states that support pagination - خليط للحالات التي تدعم التصفح
mixin PaginationMixin on BaseState {
  int get currentPage => 1;
  int get totalPages => 1;
  bool get hasNextPage => currentPage < totalPages;
  bool get hasPreviousPage => currentPage > 1;
  bool get isFirstPage => currentPage == 1;
  bool get isLastPage => currentPage == totalPages;
}

/// Mixin for states that support filtering - خليط للحالات التي تدعم التصفية
mixin FilterMixin on BaseState {
  Map<String, dynamic> get activeFilters => {};
  bool get hasActiveFilters => activeFilters.isNotEmpty;
  int get filterCount => activeFilters.length;
}

/// Mixin for states that support search - خليط للحالات التي تدعم البحث
mixin SearchMixin on BaseState {
  String get searchQuery => '';
  bool get isSearching => searchQuery.isNotEmpty;
  bool get hasSearchResults => isSearching && hasData;
}

/// Helper class for creating common state transitions - فئة مساعدة لإنشاء انتقالات الحالة الشائعة
class StateTransitions {
  static T toLoading<T extends BaseState>(T currentState) {
    // This would need to be implemented per state type
    throw UnimplementedError('Implement in specific state classes');
  }

  static T toError<T extends BaseState>(T currentState, AppError error) {
    // This would need to be implemented per state type
    throw UnimplementedError('Implement in specific state classes');
  }

  static T toSuccess<T extends BaseState>(T currentState, {String? message}) {
    // This would need to be implemented per state type
    throw UnimplementedError('Implement in specific state classes');
  }
}

/// State factory for creating common states - مصنع الحالات لإنشاء الحالات الشائعة
abstract class StateFactory<T extends BaseState> {
  T get initial;
  T loading();
  T error(AppError error);
  T success({String? message});
}