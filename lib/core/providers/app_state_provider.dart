// lib/core/providers/app_state_provider.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../services/background_service.dart';
import 'base/base_state.dart';
import 'base/base_provider.dart';
import '../database/models/common_models.dart';
import '../services/background_service.dart';
import '../database/repositories/settings_repository.dart';

/// App State Error class - حل جذري منظم
@immutable
class AppStateError {
  final String message;
  final String code;
  final Map<String, dynamic> details;
  final DateTime timestamp;
  final StackTrace? stackTrace;

  AppStateError({
    required this.message,
    required this.code,
    this.details = const {},
    DateTime? timestamp,
    this.stackTrace,
  }) : timestamp = timestamp ?? _currentTime;

  static DateTime get _currentTime => DateTime.now();

  AppStateError copyWith({
    String? message,
    String? code,
    Map<String, dynamic>? details,
    DateTime? timestamp,
    StackTrace? stackTrace,
  }) {
    return AppStateError(
      message: message ?? this.message,
      code: code ?? this.code,
      details: details ?? this.details,
      timestamp: timestamp ?? this.timestamp,
      stackTrace: stackTrace ?? this.stackTrace,
    );
  }

  // Factory constructors للاستخدام السهل
  factory AppStateError.permission(String message) {
    return AppStateError(
      message: message,
      code: 'permission_error',
    );
  }

  factory AppStateError.network(String message) {
    return AppStateError(
      message: message,
      code: 'network_error',
    );
  }

  factory AppStateError.data(String message) {
    return AppStateError(
      message: message,
      code: 'data_error',
    );
  }

  @override
  String toString() {
    return 'AppStateError(message: $message, code: $code, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppStateError &&
        other.message == message &&
        other.code == code &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => Object.hash(message, code, timestamp);
}

/// App state class - فئة حالة التطبيق
@immutable
class AppState extends BaseState {
  final bool isInitialized;
  final User? currentUser;
  final AppSettings appSettings;
  final List<ConnectivityResult> connectivity;
  final bool isOffline;
  final List<Permission> grantedPermissions;
  final List<Permission> deniedPermissions;
  final AppTheme currentTheme;
  final Locale currentLocale;
  final DeviceInfo deviceInfo;
  final PackageInfo packageInfo;
  final bool isBackgroundServiceRunning;
  final String appVersion;
  final String buildNumber;
  final bool isFirstLaunch;
  final DateTime? lastSyncTime;
  final Map<String, dynamic> featureFlags;
  final AppStateError? appError;

  // إضافة متغيرات لفصل حالات التحديث في الخلفية
  final DateTime? lastConnectivityUpdate;
  final DateTime? lastPermissionUpdate;
  final DateTime? lastServiceStatusUpdate;

  AppState({
    // Base state properties
    super.loadingState,
    super.error,
    super.lastUpdated,
    super.hasData,
    super.successMessage,

    // App-specific properties
    this.isInitialized = false,
    this.currentUser,
    AppSettings? appSettings,
    this.connectivity = const [ConnectivityResult.none],
    this.isOffline = true,
    this.grantedPermissions = const [],
    this.deniedPermissions = const [],
    this.currentTheme = AppTheme.system,
    this.currentLocale = const Locale('ar', 'SA'),
    this.deviceInfo = const DeviceInfo.unknown(),
    this.packageInfo = const PackageInfo.unknown(),
    this.isBackgroundServiceRunning = false,
    this.appVersion = '1.0.0',
    this.buildNumber = '1',
    this.isFirstLaunch = false,
    this.lastSyncTime,
    this.featureFlags = const {},
    this.appError,

    // Background update timestamps
    this.lastConnectivityUpdate,
    this.lastPermissionUpdate,
    this.lastServiceStatusUpdate,
  }) : appSettings = appSettings ?? AppSettings(
    key: 'default',
    value: 'default',
    valueType: SettingValueType.string,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  // Factory constructors
  factory AppState.initial() {
    return AppState(
      loadingState: LoadingState.idle,
      hasData: false,
    );
  }

  factory AppState.loading() {
    return AppState(
      loadingState: LoadingState.loading,
      hasData: false,
    );
  }

  factory AppState.initialized({
    required AppSettings appSettings,
    required List<ConnectivityResult> connectivity,
    required List<Permission> grantedPermissions,
    required List<Permission> deniedPermissions,
    required DeviceInfo deviceInfo,
    required PackageInfo packageInfo,
    bool isBackgroundServiceRunning = false,
    bool isFirstLaunch = false,
    DateTime? lastSyncTime,
    Map<String, dynamic> featureFlags = const {},
  }) {
    return AppState(
      loadingState: LoadingState.success,
      hasData: true,
      isInitialized: true,
      appSettings: appSettings,
      connectivity: connectivity,
      isOffline: !connectivity.any((result) => result != ConnectivityResult.none),
      grantedPermissions: grantedPermissions,
      deniedPermissions: deniedPermissions,
      deviceInfo: deviceInfo,
      packageInfo: packageInfo,
      isBackgroundServiceRunning: isBackgroundServiceRunning,
      appVersion: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
      isFirstLaunch: isFirstLaunch,
      lastSyncTime: lastSyncTime,
      featureFlags: featureFlags,
      lastConnectivityUpdate: DateTime.now(),
      lastPermissionUpdate: DateTime.now(),
      lastServiceStatusUpdate: DateTime.now(),
    );
  }

  // Computed properties
  bool get isOnline => !isOffline;
  bool get hasInternetConnection => connectivity.any((result) => result != ConnectivityResult.none);
  bool get isWifiConnected => connectivity.contains(ConnectivityResult.wifi);
  bool get isMobileConnected => connectivity.contains(ConnectivityResult.mobile);
  bool get allPermissionsGranted => deniedPermissions.isEmpty;
  bool get hasEssentialPermissions => grantedPermissions.any((p) => _essentialPermissions.contains(p));
  bool get isDarkTheme => currentTheme == AppTheme.dark;
  bool get isLightTheme => currentTheme == AppTheme.light;
  bool get isSystemTheme => currentTheme == AppTheme.system;
  bool get isArabicLocale => currentLocale.languageCode == 'ar';
  String get fullVersion => '$appVersion+$buildNumber';

  // Essential permissions list
  static const List<Permission> _essentialPermissions = [
    Permission.sensors,
    Permission.notification,
    Permission.activityRecognition,
  ];

  // copyWith method with background update support
  AppState copyWith({
    LoadingState? loadingState,
    AppError? error,
    AppStateError? appError,
    DateTime? lastUpdated,
    bool? hasData,
    String? successMessage,
    bool? isInitialized,
    User? currentUser,
    AppSettings? appSettings,
    List<ConnectivityResult>? connectivity,
    bool? isOffline,
    List<Permission>? grantedPermissions,
    List<Permission>? deniedPermissions,
    AppTheme? currentTheme,
    Locale? currentLocale,
    DeviceInfo? deviceInfo,
    PackageInfo? packageInfo,
    bool? isBackgroundServiceRunning,
    String? appVersion,
    String? buildNumber,
    bool? isFirstLaunch,
    DateTime? lastSyncTime,
    Map<String, dynamic>? featureFlags,
    DateTime? lastConnectivityUpdate,
    DateTime? lastPermissionUpdate,
    DateTime? lastServiceStatusUpdate,

    // مؤشر لتحديد نوع التحديث
    bool isBackgroundUpdate = false,
  }) {
    return AppState(
      // إذا كان background update، لا نغير الـ loading state
      loadingState: isBackgroundUpdate
          ? this.loadingState
          : (loadingState ?? this.loadingState),
      error: error ?? this.error,
      appError: appError ?? this.appError,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      hasData: hasData ?? this.hasData,
      successMessage: isBackgroundUpdate ? null : successMessage,
      isInitialized: isInitialized ?? this.isInitialized,
      currentUser: currentUser ?? this.currentUser,
      appSettings: appSettings ?? this.appSettings,
      connectivity: connectivity ?? this.connectivity,
      isOffline: isOffline ?? this.isOffline,
      grantedPermissions: grantedPermissions ?? this.grantedPermissions,
      deniedPermissions: deniedPermissions ?? this.deniedPermissions,
      currentTheme: currentTheme ?? this.currentTheme,
      currentLocale: currentLocale ?? this.currentLocale,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      packageInfo: packageInfo ?? this.packageInfo,
      isBackgroundServiceRunning: isBackgroundServiceRunning ?? this.isBackgroundServiceRunning,
      appVersion: appVersion ?? this.appVersion,
      buildNumber: buildNumber ?? this.buildNumber,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      featureFlags: featureFlags ?? this.featureFlags,
      lastConnectivityUpdate: lastConnectivityUpdate ?? this.lastConnectivityUpdate,
      lastPermissionUpdate: lastPermissionUpdate ?? this.lastPermissionUpdate,
      lastServiceStatusUpdate: lastServiceStatusUpdate ?? this.lastServiceStatusUpdate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppState &&
        other.isInitialized == isInitialized &&
        other.currentTheme == currentTheme &&
        other.currentLocale == currentLocale &&
        other.isOffline == isOffline;
  }

  @override
  int get hashCode => Object.hash(
    isInitialized,
    currentTheme,
    currentLocale,
    isOffline,
  );
}

@immutable
class User {
  final String id;
  final String name;
  final String? email;
  final String? avatar;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final Map<String, dynamic> preferences;

  const User({
    required this.id,
    required this.name,
    this.email,
    this.avatar,
    required this.createdAt,
    required this.lastActiveAt,
    this.preferences = const {},
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    Map<String, dynamic>? preferences,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      preferences: preferences ?? this.preferences,
    );
  }
}

@immutable
class DeviceInfo {
  final String platform;
  final String model;
  final String version;
  final String identifier;
  final bool isPhysicalDevice;

  const DeviceInfo({
    required this.platform,
    required this.model,
    required this.version,
    required this.identifier,
    required this.isPhysicalDevice,
  });

  const DeviceInfo.unknown()
      : platform = 'unknown',
        model = 'unknown',
        version = 'unknown',
        identifier = 'unknown',
        isPhysicalDevice = true;
}

@immutable
class PackageInfo {
  final String appName;
  final String packageName;
  final String version;
  final String buildNumber;

  const PackageInfo({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
  });

  const PackageInfo.unknown()
      : appName = 'Smart Psych',
        packageName = 'com.example.smart_psych',
        version = '1.0.0',
        buildNumber = '1';
}

/// AppStateProvider class
class AppStateProvider extends BaseProvider<AppState>
    with PeriodicUpdateMixin<AppState>, CacheMixin<AppState> {

  // Dependencies
  final SettingsRepository _settingsRepo;
  final BackgroundService _backgroundService;

  // Stream subscriptions
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _syncTimer;
  Timer? _backgroundStatusTimer;

  AppStateProvider({
    SettingsRepository? settingsRepo,
    BackgroundService? backgroundService,
  })  : _settingsRepo = settingsRepo ?? SettingsRepository(),
        _backgroundService = backgroundService ?? BackgroundService.instance,
        super(AppState.loading()) {

    debugPrint('🚀 تهيئة AppStateProvider - الإصدار الجديد V2');
    debugPrint('⚡ تشغيل التهيئة المباشرة الجديدة...');

    // تهيئة مستمعات الخلفية أولاً
    _initializeBackgroundListeners();

    // تهيئة مباشرة مع scheduleMicrotask
    scheduleMicrotask(() {
      debugPrint('🔥 تنفيذ scheduleMicrotask V2...');
      _performInitialization();
    });

    debugPrint('✅ انتهى Constructor V2 مع جدولة التهيئة');
  }

  /// تنفيذ التهيئة مباشرة
  void _performInitialization() async {
    debugPrint('🎯 بدء _performInitialization...');

    try {
      debugPrint('🚀 استدعاء initializeApp مباشرة...');
      await initializeApp();
      debugPrint('✅ تمت التهيئة المباشرة بنجاح');
    } catch (error, stackTrace) {
      debugPrint('❌ فشلت التهيئة المباشرة: $error');
      debugPrint('📍 Stack trace: $stackTrace');

      // تحديث الحالة مع الخطأ
      setState(state.copyWith(
        appError: AppStateError(
          message: 'فشل في التهيئة المباشرة: ${error.toString()}',
          code: 'direct_initialization_failed',
        ),
        loadingState: LoadingState.error,
      ));
    }
  }

  // Initialize app
  Future<void> initializeApp() async {
    debugPrint('🔄 ===== بدء تهيئة التطبيق (للاستخدام الخارجي) =====');

    // استدعاء التهيئة المباشرة
    await _performDirectInitialization();
  }

  /// التهيئة المباشرة بدون executeWithLoading - الإصدار الجديد V2
  Future<void> _performDirectInitialization() async {
    debugPrint('🚀 بدء التهيئة المباشرة V2...');

    try {
      // تحديث الحالة إلى loading
      setState(state.copyWith(
        loadingState: LoadingState.loading,
        appError: null,
      ));

      debugPrint('📱 الخطوة 1 V2: تحميل إعدادات التطبيق...');
      final appSettings = await _loadAppSettings();
      debugPrint('✅ تم تحميل إعدادات التطبيق بنجاح V2');

      debugPrint('📱 الخطوة 2 V2: الحصول على معلومات الجهاز...');
      final deviceInfo = await _getDeviceInfo();
      debugPrint('✅ تم الحصول على معلومات الجهاز V2: ${deviceInfo.platform} ${deviceInfo.model}');

      debugPrint('📱 الخطوة 3 V2: الحصول على معلومات التطبيق...');
      final packageInfo = await _getPackageInfo();
      debugPrint('✅ تم الحصول على معلومات التطبيق V2: ${packageInfo.appName} v${packageInfo.version}');

      debugPrint('📱 الخطوة 4 V2: فحص حالة الاتصال...');
      final connectivity = await _checkConnectivity();
      debugPrint('✅ تم فحص الاتصال V2: $connectivity');

      debugPrint('📱 الخطوة 5 V2: فحص وطلب الأذونات الأساسية...');
      final (grantedPermissions, deniedPermissions) = await _requestEssentialPermissions();
      debugPrint('✅ تم فحص الأذونات V2: ${grantedPermissions.length} ممنوح، ${deniedPermissions.length} مرفوض');

      debugPrint('📱 الخطوة 6 V2: التحقق من أول تشغيل...');
      final isFirstLaunch = await _checkFirstLaunch();
      debugPrint('✅ حالة أول تشغيل V2: ${isFirstLaunch ? 'نعم' : 'لا'}');

      debugPrint('📱 الخطوة 7 V2: الحصول على وقت آخر مزامنة...');
      final lastSyncTime = await _getLastSyncTime();
      debugPrint('✅ آخر مزامنة V2: ${lastSyncTime?.toString() ?? 'لم تتم من قبل'}');

      debugPrint('📱 الخطوة 8 V2: تحميل إعدادات الميزات...');
      final featureFlags = await _loadFeatureFlags();
      debugPrint('✅ تم تحميل ${featureFlags.length} إعداد ميزة V2');

      debugPrint('📱 الخطوة 9 V2: تهيئة خدمة الخلفية...');
      bool isBackgroundServiceRunning = false;
      try {
        await _backgroundService.initialize();
        isBackgroundServiceRunning = true;
        debugPrint('✅ تم تشغيل خدمة الخلفية بنجاح V2');
      } catch (e) {
        debugPrint('⚠️ فشل في تشغيل خدمة الخلفية V2: $e');
        debugPrint('📋 سيتم المتابعة بدون خدمة الخلفية V2');
      }

      debugPrint('📱 الخطوة 10 V2: تحديث حالة التطبيق...');
      setState(AppState.initialized(
        appSettings: appSettings,
        connectivity: connectivity,
        grantedPermissions: grantedPermissions,
        deniedPermissions: deniedPermissions,
        deviceInfo: deviceInfo,
        packageInfo: packageInfo,
        isBackgroundServiceRunning: isBackgroundServiceRunning,
        isFirstLaunch: isFirstLaunch,
        lastSyncTime: lastSyncTime,
        featureFlags: featureFlags,
      ));
      debugPrint('✅ تم تحديث حالة التطبيق بنجاح V2');
      debugPrint('📊 الحالة الجديدة V2: isInitialized=${state.isInitialized}');

      debugPrint('📱 الخطوة 11 V2: إنهاء إعدادات أول تشغيل...');
      if (isFirstLaunch) {
        await _markFirstLaunchCompleted();
        debugPrint('✅ تم تحديد أول تشغيل كمكتمل V2');
      }

      debugPrint('🎉 ===== تم إكمال التهيئة المباشرة V2 بنجاح =====');

    } catch (error, stackTrace) {
      debugPrint('❌ ===== خطأ حرج في التهيئة المباشرة V2 =====');
      debugPrint('❌ الخطأ V2: $error');
      debugPrint('📍 Stack trace V2: $stackTrace');

      // تحديث الحالة مع الخطأ
      setState(state.copyWith(
        appError: AppStateError(
          message: 'فشل في التهيئة المباشرة V2: ${error.toString()}',
          code: 'direct_initialization_failed_v2',
        ),
        loadingState: LoadingState.error,
      ));

      debugPrint('❌ تم تحديث الحالة مع الخطأ V2');

      // إعادة رمي الخطأ للمعالجة في مستوى أعلى
      rethrow;
    }
  }

  // =================== BACKGROUND UPDATE METHODS ===================

  /// تحديث حالة الاتصال في الخلفية
  void _updateConnectivityInBackground(List<ConnectivityResult> results) {
    if (isDisposed) return;

    final isOffline = !results.any((result) => result != ConnectivityResult.none);

    // تحديث في الخلفية بدون تغيير loading state
    setState(state.copyWith(
      connectivity: results,
      isOffline: isOffline,
      lastConnectivityUpdate: DateTime.now(),
      isBackgroundUpdate: true,
    ));

    debugPrint('🌐 تحديث الاتصال في الخلفية: ${isOffline ? 'منقطع' : 'متصل'}');
  }

  /// تحديث حالة الأذونات في الخلفية
  void _updatePermissionsInBackground() async {
    if (isDisposed) return;

    try {
      final (granted, denied) = await _requestEssentialPermissions();

      setState(state.copyWith(
        grantedPermissions: granted,
        deniedPermissions: denied,
        lastPermissionUpdate: DateTime.now(),
        isBackgroundUpdate: true,
      ));

      debugPrint('🔐 تحديث الأذونات في الخلفية: ${granted.length} ممنوح');
    } catch (e) {
      debugPrint('⚠️ فشل في تحديث الأذونات في الخلفية: $e');
    }
  }

  /// تحديث حالة خدمة الخلفية
  void _updateBackgroundServiceStatus() async {
    if (isDisposed) return;

    try {
      final serviceStatus = await _backgroundService.getDetailedStatus();
      final isRunning = serviceStatus['is_running'] ?? false;

      setState(state.copyWith(
        isBackgroundServiceRunning: isRunning,
        lastServiceStatusUpdate: DateTime.now(),
        isBackgroundUpdate: true,
      ));

      debugPrint('⚙️ تحديث حالة الخدمة في الخلفية: ${isRunning ? 'نشطة' : 'متوقفة'}');
    } catch (e) {
      debugPrint('⚠️ فشل في تحديث حالة الخدمة: $e');
    }
  }

  /// تهيئة مستمعات التحديث في الخلفية
  void _initializeBackgroundListeners() {
    // مستمع تغيرات الاتصال
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen(_updateConnectivityInBackground);

    // مؤقت فحص حالة الخدمة كل دقيقة
    _backgroundStatusTimer = Timer.periodic(
      const Duration(minutes: 1),
          (_) => _updateBackgroundServiceStatus(),
    );

    // مؤقت المزامنة الدورية
    _syncTimer = Timer.periodic(
      const Duration(minutes: 15),
          (timer) {
        if (!isDisposed && state.isOnline) {
          _performBackgroundSync();
        }
      },
    );

    debugPrint('🎧 تم تهيئة مستمعات التحديث في الخلفية');
  }

  // =================== USER INTERACTION METHODS ===================

  /// إكمال إعداد الأذونات والانتقال للتطبيق - المطلوب لـ PermissionsScreen
  Future<void> completePermissions() async {
    await executeWithLoading(() async {
      debugPrint('🔐 إكمال إعداد الأذونات...');

      // 1. فحص الأذونات الحالية
      final (grantedPermissions, deniedPermissions) = await _requestEssentialPermissions();

      // 2. تحديث حالة الأذونات
      setState(state.copyWith(
        grantedPermissions: grantedPermissions,
        deniedPermissions: deniedPermissions,
        lastPermissionUpdate: DateTime.now(),
      ));

      // 3. تحديث إعدادات أن الأذونات تم إكمالها
      await _settingsRepo.setSetting('permissions_completed', true, SettingValueType.bool);

      // 4. حفظ حالة الأذونات
      await _savePermissionsState(grantedPermissions, deniedPermissions);

      debugPrint('✅ تم إكمال إعداد الأذونات');
    });
  }

  /// فحص ما إذا كانت الأذونات مكتملة - المطلوب لـ PermissionsScreen
  Future<bool> arePermissionsCompleted() async {
    try {
      final completed = await _settingsRepo.getSetting<bool>('permissions_completed', false);
      return completed ?? false;
    } catch (e) {
      debugPrint('⚠️ فشل في فحص حالة الأذونات: $e');
      return false;
    }
  }

  /// إعادة تعيين حالة الأذونات - المطلوب لـ PermissionsScreen
  Future<void> resetPermissions() async {
    await executeWithLoading(() async {
      await _settingsRepo.setSetting('permissions_completed', false, SettingValueType.bool);
      await _settingsRepo.deleteSetting('granted_permissions');
      await _settingsRepo.deleteSetting('denied_permissions');

      setState(state.copyWith(
        grantedPermissions: [],
        deniedPermissions: [],
        lastPermissionUpdate: DateTime.now(),
      ));

      debugPrint('🔄 تم إعادة تعيين حالة الأذونات');
    });
  }

  /// تحديث إذن واحد - المطلوب لـ PermissionsScreen
  Future<void> updateSinglePermission(Permission permission) async {
    try {
      final status = await permission.status;
      final currentGranted = List<Permission>.from(state.grantedPermissions);
      final currentDenied = List<Permission>.from(state.deniedPermissions);

      // إزالة الإذن من القوائم الحالية
      currentGranted.remove(permission);
      currentDenied.remove(permission);

      // إضافة للقائمة المناسبة
      if (status.isGranted) {
        currentGranted.add(permission);
      } else {
        currentDenied.add(permission);
      }

      // تحديث الحالة (هذا user interaction وليس background update)
      setState(state.copyWith(
        grantedPermissions: currentGranted,
        deniedPermissions: currentDenied,
        lastPermissionUpdate: DateTime.now(),
      ));

      // حفظ التحديث
      await _savePermissionsState(currentGranted, currentDenied);

      debugPrint('🔄 تم تحديث إذن $permission إلى: $status');
    } catch (e) {
      debugPrint('⚠️ فشل في تحديث الإذن $permission: $e');
    }
  }

  /// طلب إذن واحد مع المعالجة - المطلوب لـ PermissionsScreen
  Future<bool> requestSinglePermission(Permission permission) async {
    try {
      debugPrint('📱 طلب إذن: $permission');

      final status = await permission.request();
      await updateSinglePermission(permission);

      final success = status.isGranted;
      setState(state.copyWith(
        successMessage: success
            ? 'تم منح الإذن بنجاح'
            : 'تم رفض الإذن',
      ));

      return success;
    } catch (e) {
      debugPrint('❌ فشل في طلب الإذن $permission: $e');
      setState(state.copyWith(appError: AppStateError.permission(
        'فشل في طلب الإذن',
      )));
      return false;
    }
  }

  /// فحص جميع الأذونات الأساسية - المطلوب لـ PermissionsScreen
  Future<bool> checkAllEssentialPermissions() async {
    try {
      for (final permission in AppState._essentialPermissions) {
        final status = await permission.status;
        if (!status.isGranted) {
          debugPrint('⚠️ الإذن الأساسي غير ممنوح: $permission');
          return false;
        }
      }
      debugPrint('✅ جميع الأذونات الأساسية ممنوحة');
      return true;
    } catch (e) {
      debugPrint('❌ فشل في فحص الأذونات الأساسية: $e');
      return false;
    }
  }

  /// إنشاء تقرير الأذونات - المطلوب لـ PermissionsScreen
  Map<String, dynamic> getPermissionsReport() {
    final grantedCount = state.grantedPermissions.length;
    final deniedCount = state.deniedPermissions.length;
    final totalCount = grantedCount + deniedCount;

    return {
      'total_permissions': totalCount,
      'granted_count': grantedCount,
      'denied_count': deniedCount,
      'completion_percentage': totalCount > 0 ? (grantedCount / totalCount * 100).round() : 0,
      'all_essential_granted': state.hasEssentialPermissions,
      'granted_permissions': state.grantedPermissions.map((p) => p.toString()).toList(),
      'denied_permissions': state.deniedPermissions.map((p) => p.toString()).toList(),
      'is_ready_to_use': state.hasEssentialPermissions,
      'last_update': state.lastPermissionUpdate?.toIso8601String(),
    };
  }

  // Update app settings
  Future<void> updateSettings(AppSettings newSettings) async {
    await executeWithLoading(() async {
      await _settingsRepo.saveAppSettings(newSettings);
      setState(state.copyWith(
        appSettings: newSettings,
        successMessage: 'تم حفظ الإعدادات بنجاح',
      ));
      debugPrint('✅ تم تحديث إعدادات التطبيق');
    });
  }

  // Switch theme
  Future<void> switchTheme(AppTheme theme) async {
    setState(state.copyWith(
      currentTheme: theme,
      successMessage: 'تم تغيير المظهر',
    ));

    // حفظ في الإعدادات
    await _settingsRepo.setSetting('app_theme', theme.toString(), SettingValueType.string);
    debugPrint('🎨 تم تغيير المظهر إلى: $theme');
  }

  // Change language
  Future<void> changeLanguage(Locale locale) async {
    setState(state.copyWith(
      currentLocale: locale,
      successMessage: 'تم تغيير اللغة',
    ));

    // حفظ في الإعدادات
    await _settingsRepo.setSetting('app_locale', '${locale.languageCode}_${locale.countryCode}', SettingValueType.string);
    debugPrint('🌐 تم تغيير اللغة إلى: ${locale.languageCode}');
  }

  // Request permissions
  Future<void> requestPermissions() async {
    await executeWithLoading(() async {
      final (granted, denied) = await _requestEssentialPermissions();
      setState(state.copyWith(
        grantedPermissions: granted,
        deniedPermissions: denied,
        lastPermissionUpdate: DateTime.now(),
        successMessage: denied.isEmpty
            ? 'تم منح جميع الأذونات'
            : 'تم منح ${granted.length} من ${granted.length + denied.length} أذونات',
      ));
    });
  }

  // Export all data
  Future<String?> exportAllData() async {
    return await executeWithResult(() async {
      debugPrint('📤 تصدير جميع البيانات...');
      await Future.delayed(const Duration(seconds: 2));
      return '/storage/emulated/0/smart_psych_export.json';
    });
  }

  // Reset app
  Future<void> resetApp() async {
    await executeWithLoading(() async {
      await _settingsRepo.clearAllSettings();
      await _backgroundService.stop();

      setState(AppState.initial());

      debugPrint('🔄 تم إعادة تعيين التطبيق');
    });
  }

  // Refresh app state - هذا للتحديث اليدوي من المستخدم
  Future<void> refreshAppState() async {
    await executeWithLoading(() async {
      final connectivity = await _checkConnectivity();
      final serviceStatus = await _backgroundService.getDetailedStatus();

      setState(state.copyWith(
        connectivity: connectivity,
        isOffline: !connectivity.any((result) => result != ConnectivityResult.none),
        isBackgroundServiceRunning: serviceStatus['is_running'] ?? false,
        lastConnectivityUpdate: DateTime.now(),
        lastServiceStatusUpdate: DateTime.now(),
        lastUpdated: DateTime.now(),
      ));

      debugPrint('🔄 تم تحديث حالة التطبيق يدوياً');
    }, useRefreshing: true);
  }

  // تسجيل الدخول/إنشاء مستخدم جديد
  Future<void> setCurrentUser(User user) async {
    setState(state.copyWith(
      currentUser: user,
      successMessage: 'تم تسجيل الدخول بنجاح',
    ));

    // حفظ معرف المستخدم
    await _settingsRepo.setSetting('current_user_id', user.id, SettingValueType.string);

    debugPrint('👤 تم تعيين المستخدم الحالي: ${user.name}');
  }

  // تسجيل الخروج
  Future<void> logout() async {
    await executeWithLoading(() async {
      // مسح بيانات المستخدم
      await _settingsRepo.deleteSetting('current_user_id');

      // إيقاف الخدمات
      await _backgroundService.stop();

      setState(state.copyWith(
        currentUser: null,
        isBackgroundServiceRunning: false,
        successMessage: 'تم تسجيل الخروج',
      ));

      debugPrint('👋 تم تسجيل خروج المستخدم');
    });
  }

  // =================== PRIVATE HELPER METHODS ===================

  Future<AppSettings> _loadAppSettings() async {
    try {
      return await _settingsRepo.getAppSettings();
    } catch (e) {
      debugPrint('⚠️ فشل في تحميل الإعدادات، استخدام الإعدادات الافتراضية');
      return AppSettings(
        key: 'default',
        value: 'default',
        valueType: SettingValueType.string,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  Future<DeviceInfo> _getDeviceInfo() async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        return DeviceInfo(
          platform: 'Android',
          model: '${androidInfo.brand} ${androidInfo.model}',
          version: 'Android ${androidInfo.version.release}',
          identifier: androidInfo.id,
          isPhysicalDevice: androidInfo.isPhysicalDevice,
        );
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        return DeviceInfo(
          platform: 'iOS',
          model: iosInfo.model,
          version: 'iOS ${iosInfo.systemVersion}',
          identifier: iosInfo.identifierForVendor ?? 'unknown',
          isPhysicalDevice: iosInfo.isPhysicalDevice,
        );
      }
    } catch (e) {
      debugPrint('⚠️ فشل في الحصول على معلومات الجهاز: $e');
    }

    return const DeviceInfo.unknown();
  }

  Future<PackageInfo> _getPackageInfo() async {
    try {
      // في التطبيق الحقيقي، استخدم package_info_plus
      return const PackageInfo(
        appName: 'Smart Psych',
        packageName: 'com.example.smart_psych',
        version: '1.0.0',
        buildNumber: '1',
      );
    } catch (e) {
      debugPrint('⚠️ فشل في الحصول على معلومات التطبيق: $e');
      return const PackageInfo.unknown();
    }
  }

  Future<List<ConnectivityResult>> _checkConnectivity() async {
    try {
      return await Connectivity().checkConnectivity();
    } catch (e) {
      debugPrint('⚠️ فشل في فحص الاتصال: $e');
      return [ConnectivityResult.none];
    }
  }

  Future<(List<Permission>, List<Permission>)> _requestEssentialPermissions() async {
    final granted = <Permission>[];
    final denied = <Permission>[];

    for (final permission in AppState._essentialPermissions) {
      try {
        final status = await permission.status;
        if (status.isGranted) {
          granted.add(permission);
        } else {
          denied.add(permission);
        }
      } catch (e) {
        debugPrint('⚠️ فشل في فحص إذن $permission: $e');
        denied.add(permission);
      }
    }

    debugPrint('✅ ممنوح: ${granted.length}, مرفوض: ${denied.length}');
    return (granted, denied);
  }

  Future<bool> _checkFirstLaunch() async {
    try {
      final isFirstLaunch = await _settingsRepo.getSetting<bool>('is_first_launch', true);
      return isFirstLaunch ?? true;
    } catch (e) {
      debugPrint('⚠️ فشل في فحص أول تشغيل: $e');
      return false;
    }
  }

  Future<void> _markFirstLaunchCompleted() async {
    try {
      await _settingsRepo.setSetting('is_first_launch', false, SettingValueType.bool);
    } catch (e) {
      debugPrint('⚠️ فشل في تحديد أول تشغيل كمكتمل: $e');
    }
  }

  Future<DateTime?> _getLastSyncTime() async {
    try {
      final timestamp = await _settingsRepo.getSetting<int>('last_sync_time', 0);
      return timestamp != null && timestamp > 0
          ? DateTime.fromMillisecondsSinceEpoch(timestamp)
          : null;
    } catch (e) {
      debugPrint('⚠️ فشل في الحصول على وقت آخر مزامنة: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> _loadFeatureFlags() async {
    try {
      return {
        'ai_insights': true,
        'advanced_analytics': true,
        'export_data': true,
        'dark_mode': true,
        'location_tracking': true,
        'background_sync': true,
      };
    } catch (e) {
      debugPrint('⚠️ فشل في تحميل إعدادات الميزات: $e');
      return {};
    }
  }

  /// حفظ حالة الأذونات - المطلوب لـ PermissionsScreen
  Future<void> _savePermissionsState(
      List<Permission> granted,
      List<Permission> denied,
      ) async {
    try {
      // تحويل الأذونات إلى قائمة نصوص
      final grantedStrings = granted.map((p) => p.toString()).toList();
      final deniedStrings = denied.map((p) => p.toString()).toList();

      // حفظ في قاعدة البيانات
      await _settingsRepo.setSetting(
        'granted_permissions',
        grantedStrings.join(','),
        SettingValueType.string,
      );

      await _settingsRepo.setSetting(
        'denied_permissions',
        deniedStrings.join(','),
        SettingValueType.string,
      );

      debugPrint('💾 تم حفظ حالة الأذونات');
    } catch (e) {
      debugPrint('⚠️ فشل في حفظ حالة الأذونات: $e');
    }
  }

  Future<void> _performBackgroundSync() async {
    try {
      debugPrint('🔄 بدء المزامنة الدورية...');

      // Update last sync time
      await _settingsRepo.setSetting(
        'last_sync_time',
        DateTime.now().millisecondsSinceEpoch,
        SettingValueType.int,
      );

      // تحديث في الخلفية
      setState(state.copyWith(
        lastSyncTime: DateTime.now(),
        isBackgroundUpdate: true,
      ));

      debugPrint('✅ تمت المزامنة الدورية بنجاح');
    } catch (e) {
      debugPrint('⚠️ فشل في المزامنة الدورية: $e');
    }
  }

  // =================== ADDITIONAL FEATURES ===================

  /// التحقق من التحديثات
  Future<bool> checkForUpdates() async {
    return await executeWithResult(() async {
      debugPrint('🔍 فحص التحديثات...');

      // محاكاة فحص التحديثات
      await Future.delayed(const Duration(seconds: 2));

      // في التطبيق الحقيقي، ستتصل بخادم للتحقق من التحديثات
      final hasUpdate = false; // محاكاة عدم وجود تحديث

      setState(state.copyWith(
        successMessage: hasUpdate
            ? 'يتوفر تحديث جديد'
            : 'التطبيق محدث إلى أحدث إصدار',
      ));

      return hasUpdate;
    }) ?? false;
  }

  /// تنظيف الذاكرة المؤقتة
  @override
  Future<void> clearCache() async {
    await executeWithLoading(() async {
      debugPrint('🧹 تنظيف الذاكرة المؤقتة...');

      // محاكاة تنظيف الذاكرة المؤقتة
      await Future.delayed(const Duration(seconds: 1));

      // إعادة تحميل البيانات الأساسية
      await refreshAppState();

      setState(state.copyWith(
        successMessage: 'تم تنظيف الذاكرة المؤقتة',
      ));

      debugPrint('✅ تم تنظيف الذاكرة المؤقتة');
    });
  }

  /// تفعيل/إلغاء تفعيل الميزات
  Future<void> toggleFeatureFlag(String featureName, bool enabled) async {
    final updatedFlags = Map<String, dynamic>.from(state.featureFlags);
    updatedFlags[featureName] = enabled;

    setState(state.copyWith(
      featureFlags: updatedFlags,
      successMessage: enabled
          ? 'تم تفعيل الميزة'
          : 'تم إلغاء تفعيل الميزة',
    ));

    // حفظ في الإعدادات
    await _settingsRepo.setSetting(
      'feature_$featureName',
      enabled,
      SettingValueType.bool,
    );

    debugPrint('🔧 تم ${enabled ? 'تفعيل' : 'إلغاء'} ميزة: $featureName');
  }

  /// الحصول على حالة ميزة معينة
  bool isFeatureEnabled(String featureName) {
    return state.featureFlags[featureName] ?? false;
  }

  /// مزامنة البيانات يدوياً
  Future<void> manualSync() async {
    if (state.isOffline) {
      setState(state.copyWith(
        appError: AppStateError.network(
          'لا يمكن المزامنة بدون اتصال بالإنترنت',
        ),
      ));
      return;
    }

    await executeWithLoading(() async {
      debugPrint('🔄 بدء المزامنة اليدوية...');

      // محاكاة المزامنة
      await Future.delayed(const Duration(seconds: 3));

      // تحديث وقت آخر مزامنة
      final now = DateTime.now();
      await _settingsRepo.setSetting(
        'last_sync_time',
        now.millisecondsSinceEpoch,
        SettingValueType.int,
      );

      setState(state.copyWith(
        lastSyncTime: now,
        successMessage: 'تم إكمال المزامنة بنجاح',
      ));

      debugPrint('✅ تم إكمال المزامنة اليدوية');
    });
  }

  /// تصدير إعدادات التطبيق
  Future<Map<String, dynamic>> exportAppSettings() async {
    return await executeWithResult(() async {
      debugPrint('📤 تصدير إعدادات التطبيق...');

      final settings = {
        'app_version': state.appVersion,
        'build_number': state.buildNumber,
        'theme': state.currentTheme.toString(),
        'locale': '${state.currentLocale.languageCode}_${state.currentLocale.countryCode}',
        'permissions_completed': await arePermissionsCompleted(),
        'granted_permissions': state.grantedPermissions.map((p) => p.toString()).toList(),
        'feature_flags': state.featureFlags,
        'device_info': {
          'platform': state.deviceInfo.platform,
          'model': state.deviceInfo.model,
          'version': state.deviceInfo.version,
        },
        'export_time': DateTime.now().toIso8601String(),
        'connectivity_last_update': state.lastConnectivityUpdate?.toIso8601String(),
        'permissions_last_update': state.lastPermissionUpdate?.toIso8601String(),
        'service_last_update': state.lastServiceStatusUpdate?.toIso8601String(),
      };

      setState(state.copyWith(
        successMessage: 'تم تصدير الإعدادات بنجاح',
      ));

      return settings;
    }) ?? {};
  }

  /// استيراد إعدادات التطبيق
  Future<void> importAppSettings(Map<String, dynamic> settings) async {
    await executeWithLoading(() async {
      debugPrint('📥 استيراد إعدادات التطبيق...');

      try {
        // استيراد المظهر
        if (settings.containsKey('theme')) {
          final themeString = settings['theme'] as String;
          final theme = AppTheme.values.firstWhere(
                (t) => t.toString() == themeString,
            orElse: () => AppTheme.system,
          );
          await switchTheme(theme);
        }

        // استيراد اللغة
        if (settings.containsKey('locale')) {
          final localeString = settings['locale'] as String;
          final parts = localeString.split('_');
          if (parts.length == 2) {
            final locale = Locale(parts[0], parts[1]);
            await changeLanguage(locale);
          }
        }

        // استيراد أعلام الميزات
        if (settings.containsKey('feature_flags')) {
          final flags = settings['feature_flags'] as Map<String, dynamic>;
          for (final entry in flags.entries) {
            if (entry.value is bool) {
              await toggleFeatureFlag(entry.key, entry.value);
            }
          }
        }

        setState(state.copyWith(
          successMessage: 'تم استيراد الإعدادات بنجاح',
        ));

        debugPrint('✅ تم استيراد إعدادات التطبيق');
      } catch (e) {
        debugPrint('❌ فشل في استيراد الإعدادات: $e');
        throw AppStateError.data(
          'فشل في استيراد الإعدادات',
        );
      }
    });
  }

  /// الحصول على إحصائيات الاستخدام
  Map<String, dynamic> getUsageStatistics() {
    return {
      'app_initialized': state.isInitialized,
      'first_launch': state.isFirstLaunch,
      'background_service_running': state.isBackgroundServiceRunning,
      'connectivity_status': state.connectivity.map((c) => c.name).toList(),
      'permissions_granted': state.grantedPermissions.length,
      'permissions_denied': state.deniedPermissions.length,
      'current_theme': state.currentTheme.name,
      'current_language': state.currentLocale.languageCode,
      'last_sync': state.lastSyncTime?.toIso8601String(),
      'feature_flags_enabled': state.featureFlags.values.where((v) => v == true).length,
      'last_connectivity_update': state.lastConnectivityUpdate?.toIso8601String(),
      'last_permission_update': state.lastPermissionUpdate?.toIso8601String(),
      'last_service_update': state.lastServiceStatusUpdate?.toIso8601String(),
    };
  }

  /// تحديث معلومات المستخدم
  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    if (state.currentUser == null) return;

    await executeWithLoading(() async {
      final updatedPreferences = Map<String, dynamic>.from(state.currentUser!.preferences);
      updatedPreferences.addAll(updates);

      final updatedUser = state.currentUser!.copyWith(
        preferences: updatedPreferences,
        lastActiveAt: DateTime.now(),
      );

      setState(state.copyWith(
        currentUser: updatedUser,
        successMessage: 'تم تحديث الملف الشخصي',
      ));

      debugPrint('👤 تم تحديث معلومات المستخدم');
    });
  }

  /// فحص الحالة الصحية للتطبيق
  Map<String, dynamic> getAppHealthStatus() {
    final healthScore = _calculateHealthScore();

    return {
      'overall_health': healthScore,
      'status': healthScore >= 80 ? 'excellent' :
      healthScore >= 60 ? 'good' :
      healthScore >= 40 ? 'fair' : 'poor',
      'issues': _getHealthIssues(),
      'recommendations': _getHealthRecommendations(),
      'last_check': DateTime.now().toIso8601String(),
      'background_updates': {
        'connectivity_working': state.lastConnectivityUpdate != null,
        'permissions_monitoring': state.lastPermissionUpdate != null,
        'service_monitoring': state.lastServiceStatusUpdate != null,
      },
    };
  }

  int _calculateHealthScore() {
    int score = 0;

    // التهيئة (20 نقطة)
    if (state.isInitialized) score += 20;

    // الأذونات الأساسية (30 نقطة)
    if (state.hasEssentialPermissions) score += 30;

    // الاتصال بالإنترنت (20 نقطة)
    if (state.isOnline) score += 20;

    // خدمة الخلفية (15 نقطة)
    if (state.isBackgroundServiceRunning) score += 15;

    // عدم وجود أخطاء (15 نقطة)
    if (state.appError == null) score += 15;

    return score;
  }

  List<String> _getHealthIssues() {
    final issues = <String>[];

    if (!state.isInitialized) {
      issues.add('التطبيق غير مهيأ بالكامل');
    }

    if (!state.hasEssentialPermissions) {
      issues.add('الأذونات الأساسية غير ممنوحة');
    }

    if (state.isOffline) {
      issues.add('لا يوجد اتصال بالإنترنت');
    }

    if (!state.isBackgroundServiceRunning) {
      issues.add('خدمة الخلفية غير نشطة');
    }

    if (state.appError != null) {
      issues.add('يوجد خطأ: ${state.appError!.message}');
    }

    // فحص صحة التحديثات في الخلفية
    final now = DateTime.now();
    if (state.lastConnectivityUpdate == null ||
        now.difference(state.lastConnectivityUpdate!).inMinutes > 5) {
      issues.add('مراقبة الاتصال قد تكون معطلة');
    }

    return issues;
  }

  List<String> _getHealthRecommendations() {
    final recommendations = <String>[];

    if (!state.hasEssentialPermissions) {
      recommendations.add('منح الأذونات الأساسية للتطبيق');
    }

    if (state.isOffline) {
      recommendations.add('التحقق من اتصال الإنترنت');
    }

    if (state.lastSyncTime == null ||
        DateTime.now().difference(state.lastSyncTime!).inHours > 24) {
      recommendations.add('تنفيذ مزامنة للبيانات');
    }

    if (state.deniedPermissions.isNotEmpty) {
      recommendations.add('مراجعة الأذونات المرفوضة');
    }

    // تحقق من صحة التحديثات في الخلفية
    if (state.lastConnectivityUpdate == null) {
      recommendations.add('إعادة تشغيل مراقب الاتصال');
    }

    return recommendations;
  }

  /// إعادة تشغيل مستمعات الخلفية
  Future<void> restartBackgroundListeners() async {
    debugPrint('🔄 إعادة تشغيل مستمعات الخلفية...');

    // إيقاف المستمعات الحالية
    await _connectivitySubscription?.cancel();
    _backgroundStatusTimer?.cancel();

    // إعادة تشغيلها
    _initializeBackgroundListeners();

    setState(state.copyWith(
      successMessage: 'تم إعادة تشغيل مستمعات الخلفية',
    ));

    debugPrint('✅ تم إعادة تشغيل مستمعات الخلفية');
  }

  // =================== BASE PROVIDER IMPLEMENTATION ===================

  @override
  Future<void> refreshData() async {
    await refreshAppState();
  }

  @override
  AppState _createLoadingState(bool isRefreshing) {
    return state.copyWith(
      loadingState: isRefreshing ? LoadingState.refreshing : LoadingState.loading,
      appError: null,
      successMessage: null,
    );
  }

  @override
  AppState _createSuccessState({String? message}) {
    return state.copyWith(
      loadingState: LoadingState.success,
      appError: null,
      successMessage: message,
      hasData: true,
    );
  }

  @override
  AppState _createErrorState(AppError error) {
    final simpleError = AppStateError(
      message: error.message,
      code: error.code ?? "",
    );

    return state.copyWith(
      loadingState: LoadingState.error,
      appError: simpleError,
      successMessage: null,
    );
  }

  @override
  AppState _createIdleState() {
    return state.copyWith(
      loadingState: LoadingState.idle,
      appError: null,
      successMessage: null,
    );
  }

  // PeriodicUpdateMixin implementation
  @override
  Future<void> performPeriodicUpdate() async {
    // للتحديثات الدورية، نستخدم الطرق المخصصة للخلفية
    _updateBackgroundServiceStatus();
    _updatePermissionsInBackground();
  }

  @override
  void dispose() {
    debugPrint('🗑️ تنظيف AppStateProvider');
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    _backgroundStatusTimer?.cancel();
    super.dispose();
  }
}