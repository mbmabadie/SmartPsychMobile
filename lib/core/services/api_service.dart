// lib/core/services/api_service.dart
// خدمة API شاملة للتواصل مع السيرفر - باستخدام Dio

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  static ApiService get instance => _instance;

  ApiService._internal();

  // ✅ عنوان السيرفر الإنتاجي - يمكن تغييره من الإعدادات لو لزم
  static const String _defaultBaseUrl = 'https://api.smartpsych.cloud/api';

  late final Dio _dio;
  String? _token;
  int? _userId;
  String _baseUrl = _defaultBaseUrl;

  // ═══════════════════════════════════════════════════════════
  // Initialization
  // ═══════════════════════════════════════════════════════════

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // ✅ تنظيف الـ URL القديم المخزن إذا كان placeholder أو localhost قديم
    final savedUrl = prefs.getString('api_base_url');
    final isStaleUrl = savedUrl != null && (
      savedUrl.contains('YOUR_SERVER_IP') ||
      savedUrl.contains('localhost') ||
      savedUrl.contains('10.0.2.2') ||
      savedUrl.contains('192.168.')
    );

    if (isStaleUrl) {
      _baseUrl = _defaultBaseUrl;
      await prefs.setString('api_base_url', _defaultBaseUrl);
      debugPrint('🔄 تم استبدال الـ URL القديم بالـ URL الإنتاجي');
    } else {
      _baseUrl = savedUrl ?? _defaultBaseUrl;
    }

    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    // إضافة Interceptor للتسجيل في وضع التطوير
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint('🌐 $obj'),
      ));
    }

    // إضافة Interceptor للتوكن التلقائي
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          debugPrint('⚠️ التوكن منتهي الصلاحية');
          _token = null;
          _userId = null;
        }
        handler.next(error);
      },
    ));

    await _loadCredentials();
    debugPrint('🔑 API Service initialized - Authenticated: $isAuthenticated');
    debugPrint('🌐 Base URL: $_baseUrl');
  }

  /// تغيير عنوان الـ API وحفظه
  Future<void> setBaseUrl(String url) async {
    _baseUrl = url;
    _dio.options.baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', url);
    debugPrint('🌐 تم تغيير Base URL: $url');
  }

  // ═══════════════════════════════════════════════════════════
  // Authentication
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> register(String email, String password, String fullName) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'full_name': fullName,
      });

      final data = response.data;

      if (response.statusCode == 201 && data['success'] == true) {
        _token = data['data']['token'];
        _userId = data['data']['user']['id'];
        await _saveCredentials(_token!, _userId!);
        return {'success': true, 'user': data['data']['user']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'خطأ غير معروف'};
      }
    } on DioException catch (e) {
      debugPrint('❌ خطأ في التسجيل: ${e.message}');
      return {'success': false, 'message': _mapDioError(e)};
    } catch (e) {
      debugPrint('❌ خطأ في التسجيل: $e');
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final data = response.data;

      if (response.statusCode == 200 && data['success'] == true) {
        _token = data['data']['token'];
        _userId = data['data']['user']['id'];
        await _saveCredentials(_token!, _userId!);
        return {'success': true, 'user': data['data']['user']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'خطأ غير معروف'};
      }
    } on DioException catch (e) {
      debugPrint('❌ خطأ في تسجيل الدخول: ${e.message}');
      return {'success': false, 'message': _mapDioError(e)};
    } catch (e) {
      debugPrint('❌ خطأ في تسجيل الدخول: $e');
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
  }

  // ═══════════════════════════════════════════════════════════
  // Delete Account - حذف منطقي (soft delete)
  // ═══════════════════════════════════════════════════════════
  // الحساب يُعطّل في السيرفر لكن البيانات تبقى محفوظة.
  // إذا المستخدم سجل بنفس الإيميل لاحقاً، يُعاد تفعيل الحساب تلقائياً.
  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      await _ensureAuthenticated();
      final response = await _dio.delete('/auth/account');

      if (response.statusCode == 200 && response.data['success'] == true) {
        // مسح التوكن المحلي بعد حذف الحساب
        await logout();
        return {'success': true, 'message': 'تم حذف الحساب'};
      }
      return {'success': false, 'message': response.data['message'] ?? 'فشل الحذف'};
    } on DioException catch (e) {
      return {'success': false, 'message': _mapDioError(e)};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Generic Sync Methods (DRY)
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> _syncSingle(String endpoint, Map<String, dynamic> data) async {
    try {
      await _ensureAuthenticated();
      final response = await _dio.post(endpoint, data: data);
      final result = response.data;

      if (response.statusCode == 200 && result['success'] == true) {
        return {'success': true, 'data': result['data']};
      } else {
        return {'success': false, 'message': result['message'] ?? 'خطأ غير معروف'};
      }
    } on DioException catch (e) {
      debugPrint('❌ خطأ في مزامنة $endpoint: ${e.message}');
      return {'success': false, 'message': _mapDioError(e)};
    } catch (e) {
      debugPrint('❌ خطأ في مزامنة $endpoint: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _syncBatch(String endpoint, String key, List<Map<String, dynamic>> items) async {
    try {
      await _ensureAuthenticated();
      final response = await _dio.post(endpoint, data: {key: items});
      final result = response.data;

      if (response.statusCode == 200 && result['success'] == true) {
        return {'success': true, 'count': (result['data'] as List?)?.length ?? 0};
      } else {
        return {'success': false, 'message': result['message'] ?? 'خطأ غير معروف'};
      }
    } on DioException catch (e) {
      debugPrint('❌ خطأ في مزامنة $endpoint: ${e.message}');
      return {'success': false, 'message': _mapDioError(e)};
    } catch (e) {
      debugPrint('❌ خطأ في مزامنة $endpoint: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Activity API
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> syncActivity(Map<String, dynamic> activity) =>
      _syncSingle('/activity/daily', activity);

  Future<Map<String, dynamic>> syncActivitiesBatch(List<Map<String, dynamic>> activities) =>
      _syncBatch('/activity/sync', 'activities', activities);

  // ═══════════════════════════════════════════════════════════
  // Sleep API
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> syncSleep(Map<String, dynamic> sleep) =>
      _syncSingle('/sleep/session', sleep);

  Future<Map<String, dynamic>> syncSleepBatch(List<Map<String, dynamic>> sleepSessions) =>
      _syncBatch('/sleep/sync', 'sessions', sleepSessions);

  // ═══════════════════════════════════════════════════════════
  // Phone Usage API
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> syncPhoneUsage(Map<String, dynamic> usage) =>
      _syncSingle('/phone-usage/daily', usage);

  Future<Map<String, dynamic>> syncPhoneUsageBatch(List<Map<String, dynamic>> usageData) =>
      _syncBatch('/phone-usage/sync', 'usage_data', usageData);

  // ═══════════════════════════════════════════════════════════
  // Nutrition API
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> syncMeal(Map<String, dynamic> meal) =>
      _syncSingle('/nutrition/meal', meal);

  Future<Map<String, dynamic>> syncMealsBatch(List<Map<String, dynamic>> meals) =>
      _syncBatch('/nutrition/sync', 'meals', meals);

  // ═══════════════════════════════════════════════════════════
  // Sync All (رفع كل شيء دفعة واحدة)
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> syncAll(Map<String, dynamic> allData) async {
    try {
      await _ensureAuthenticated();
      final response = await _dio.post('/sync/all', data: allData);
      final result = response.data;

      if (response.statusCode == 200 && result['success'] == true) {
        return {'success': true, 'data': result['data'], 'total_synced': result['total_synced']};
      }
      return {'success': false, 'message': result['message'] ?? 'خطأ غير معروف'};
    } on DioException catch (e) {
      return {'success': false, 'message': _mapDioError(e)};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Location API
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> syncLocationsBatch(List<Map<String, dynamic>> locations) =>
      _syncBatch('/sync/location', 'locations', locations);

  // ═══════════════════════════════════════════════════════════
  // Assessments API
  // ═══════════════════════════════════════════════════════════

  /// جلب الاختبار النشط الحالي مع الأسئلة والخيارات
  Future<Map<String, dynamic>> getActiveAssessment() async {
    try {
      await _ensureAuthenticated();
      final response = await _dio.get('/assessments/active');
      return {'success': true, 'data': response.data['data']};
    } on DioException catch (e) {
      return {'success': false, 'message': _mapDioError(e)};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// إرسال إجابات المستخدم
  Future<Map<String, dynamic>> submitAssessmentResponses(Map<String, dynamic> data) =>
      _syncSingle('/assessments/respond', data);

  /// مزامنة إجابات محفوظة محلياً
  Future<Map<String, dynamic>> syncAssessmentResponses(List<Map<String, dynamic>> sessions) =>
      _syncBatch('/assessments/sync-responses', 'sessions', sessions);

  /// نتائجي السابقة
  Future<Map<String, dynamic>> getMyAssessmentResults() async {
    try {
      await _ensureAuthenticated();
      final response = await _dio.get('/assessments/my-results');
      return {'success': true, 'data': response.data['data']};
    } on DioException catch (e) {
      return {'success': false, 'message': _mapDioError(e)};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Helper Methods
  // ═══════════════════════════════════════════════════════════

  Future<void> _ensureAuthenticated() async {
    if (_token == null) {
      await _loadCredentials();
    }

    if (_token == null) {
      throw Exception('غير مصرح - يجب تسجيل الدخول أولاً');
    }
  }

  Future<void> _saveCredentials(String token, int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setInt('user_id', userId);
  }

  Future<void> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _userId = prefs.getInt('user_id');
  }

  /// تحويل أخطاء Dio لرسائل مفهومة بالعربي
  String _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'انتهت مهلة الاتصال بالسيرفر';
      case DioExceptionType.receiveTimeout:
        return 'انتهت مهلة استقبال البيانات';
      case DioExceptionType.connectionError:
        return 'لا يمكن الاتصال بالسيرفر - تحقق من الإنترنت';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        if (statusCode == 401) return 'الجلسة منتهية - سجل دخولك مجدداً';
        if (statusCode == 403) return 'غير مصرح لك بهذا الإجراء';
        if (statusCode == 404) return 'الخدمة غير موجودة';
        if (statusCode >= 500) return 'خطأ في السيرفر - حاول لاحقاً';
        return 'خطأ من السيرفر: $statusCode';
      default:
        return 'خطأ في الاتصال: ${e.message}';
    }
  }

  bool get isAuthenticated => _token != null;
  int? get userId => _userId;
  String get baseUrl => _baseUrl;
}
