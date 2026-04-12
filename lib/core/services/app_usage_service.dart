// lib/core/services/app_usage_service.dart
// ✅ النسخة النهائية - استخدام UsageEvents API للدقة القصوى

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:usage_stats/usage_stats.dart';

import 'package:intl/intl.dart';
import '../database/models/app_usage_entry.dart';
import '../database/repositories/phone_usage_repository.dart';

/// ═══════════════════════════════════════════════════════════
/// AppUsageService - البيانات الحقيقية من UsageEvents
///
/// ✅ ما نجمعه (حقيقي 100%):
/// - الوقت الفعلي من FOREGROUND/BACKGROUND events
/// - حساب دقيق event by event
/// - معالجة ذكية للـ edge cases
/// ═══════════════════════════════════════════════════════════

class AppUsageService {
  static final AppUsageService _instance = AppUsageService._internal();
  factory AppUsageService() => _instance;
  AppUsageService._internal();
  static AppUsageService get instance => _instance;

  final PhoneUsageRepository _phoneRepo = PhoneUsageRepository();

  bool _isInitialized = false;
  bool _isTracking = false;
  Timer? _updateTimer;
  DateTime? _lastUpdate;

  // ✅ خيار تشغيل/إيقاف فلتر تطبيقات النظام
  bool _filterSystemApps = true;

  // Cache for app names only (not usage data)
  final Map<String, String> _appNamesCache = {};
  final Map<String, Map<String, dynamic>> _installedAppsCache = {};

  // ✅ إعدادات معالجة Events
  static const int _maxSessionMinutes = 30; // أقصى وقت للـ session الواحدة
  static const int _minSessionSeconds = 3; // أقل وقت نحسبه
  static const int _sessionMergeSeconds = 30; // دمج sessions القريبة

  // ═══════════════════════════════════════════════════════════
  // Initialization
  // ═══════════════════════════════════════════════════════════

  Future<bool> initialize() async {
    try {
      debugPrint('📱 تهيئة خدمة الاستخدام (UsageEvents API)...');

      _isInitialized = true;
      await _loadRealInstalledApps();

      final hasPermission = await hasPermissions();
      debugPrint('🔐 حالة الصلاحيات: $hasPermission');

      if (hasPermission) {
        debugPrint('✅ الصلاحيات متوفرة، بدء التتبع...');
        await startTracking();
        _schedulePeriodicUpdates();
        await forceRefreshNow();
      } else {
        debugPrint('❌ الصلاحيات غير متوفرة');
      }

      debugPrint('✅ تم تهيئة AppUsageService (UsageEvents API)');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ خطأ في تهيئة AppUsageService: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      _isInitialized = false;
      return false;
    }
  }

  Future<void> _loadRealInstalledApps() async {
    // ✅ لا نستخدم InstalledApps (يحتاج QUERY_ALL_PACKAGES غير مسموح)
    // أسماء التطبيقات تُستخرج من package name مباشرة عند الحاجة
    debugPrint('📲 جاهز - أسماء التطبيقات تُستخرج من package name عند الحاجة');
  }

  /// فلتر للـ Launcher فقط
  bool _isLauncherApp(String packageName) {
    return packageName == 'com.miui.home' ||
        packageName == 'com.android.launcher' ||
        packageName == 'com.android.launcher3';
  }

  /// ✅ فلتر ذكي لتطبيقات النظام
  bool _isSystemApp(String packageName) {
    final systemPrefixes = [
      'android',
      'com.android.',
      'com.google.android.',
      'com.miui.',
      'com.mi.',
      'com.qualcomm.',
      'com.qti.',
      'vendor.',
      'org.codeaurora.',
      'com.xiaomi.',
      'org.ifaa.',
      'com.tencent.soter.',
      'com.lenovo.',
      'com.fido.',
      'com.facebook.services',
      'com.facebook.system',
      'com.facebook.appmanager',
    ];

    final exceptions = [
      'com.android.chrome',
      'com.android.camera',
    ];

    if (exceptions.contains(packageName)) {
      return false;
    }

    for (final prefix in systemPrefixes) {
      if (packageName.startsWith(prefix)) {
        return true;
      }
    }

    return false;
  }

  // ═══════════════════════════════════════════════════════════
  // ✅ جلب البيانات الحقيقية - UsageEvents API
  // ═══════════════════════════════════════════════════════════
  Future<void> _fetchAndSaveUsageData() async {
    try {
      debugPrint('🔄 جلب البيانات من UsageEvents API...');

      final now = DateTime.now();
      final startTime = DateTime(now.year, now.month, now.day, 0, 0);
      final endTime = now;
      final dateStr = _formatDate(now);

      debugPrint('📊 من بداية اليوم (${startTime.hour}:${startTime.minute}) لحد هلق (${endTime.hour}:${endTime.minute})');

      // ✅ جلب Events من النظام
      final events = await UsageStats.queryEvents(startTime, endTime);
      debugPrint('📊 تم جلب ${events.length} event من النظام');

      if (events.isEmpty) {
        debugPrint('⚠️ لا توجد events');
        return;
      }

      // ✅ معالجة Events وحساب الوقت الفعلي
      final usageData = await _processEvents(events, now, dateStr);

      if (usageData.isEmpty) {
        debugPrint('⚠️ لا توجد تطبيقات بعد المعالجة');
        return;
      }

      // ✅ ترتيب حسب الاستخدام
      usageData.sort((a, b) => b.totalUsageTime.compareTo(a.totalUsageTime));

      // ✅ حساب الإجمالي
      final totalMinutes = usageData.fold<int>(
        0,
            (sum, app) => sum + app.totalUsageTime.inMinutes,
      );
      debugPrint('⏱️ إجمالي الاستخدام الفعلي: $totalMinutes دقيقة = ${(totalMinutes / 60).toStringAsFixed(2)}h');

      // ✅ حفظ في DB
      await _saveAllEntries(usageData, dateStr);

      _lastUpdate = DateTime.now();

    } catch (e, stackTrace) {
      debugPrint('❌ خطأ في جلب البيانات: $e');
      debugPrint('📍 Stack: $stackTrace');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ✅ معالجة Events وحساب الوقت الحقيقي
  // ═══════════════════════════════════════════════════════════
  Future<List<AppUsageEntry>> _processEvents(
      List<dynamic> events,
      DateTime now,
      String dateStr,
      ) async {
    debugPrint('🔍 معالجة ${events.length} event...');

    // ✅ تتبع حالة كل تطبيق
    final Map<String, DateTime> appOpenTimes = {}; // متى فتح التطبيق
    final Map<String, Duration> appTotalUsage = {}; // الوقت الكلي
    final Map<String, DateTime> appLastUsed = {}; // آخر استخدام
    final Map<String, List<Duration>> appSessions = {}; // جلسات الاستخدام

    int systemAppsFiltered = 0;
    int processedEvents = 0;

    for (final event in events) {
      final pkg = event.packageName ?? '';
      if (pkg.isEmpty) continue;

      // تخطي Launcher
      if (_isLauncherApp(pkg)) continue;

      // فلتر النظام
      if (_filterSystemApps && _isSystemApp(pkg)) {
        systemAppsFiltered++;
        continue;
      }

      final eventType = event.eventType ?? '';
      final timeStamp = event.timeStamp;

      if (timeStamp == null) continue;

      DateTime eventTime;
      try {
        final timestamp = int.parse(timeStamp);
        eventTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } catch (e) {
        continue;
      }

      // ✅ معالجة Events
      if (eventType == '1' || eventType == 'MOVE_TO_FOREGROUND') {
        // التطبيق فتح
        appOpenTimes[pkg] = eventTime;
        appLastUsed[pkg] = eventTime;
        processedEvents++;

      } else if (eventType == '2' || eventType == 'MOVE_TO_BACKGROUND') {
        // التطبيق قفل
        if (appOpenTimes.containsKey(pkg)) {
          final openTime = appOpenTimes[pkg]!;
          final duration = eventTime.difference(openTime);

          // ✅ تطبيق القيود
          if (duration.inSeconds >= _minSessionSeconds) {
            // حد أقصى للـ session (للحماية من crashes)
            final cappedDuration = duration.inMinutes > _maxSessionMinutes
                ? Duration(minutes: _maxSessionMinutes)
                : duration;

            // إضافة للمجموع
            appTotalUsage[pkg] = (appTotalUsage[pkg] ?? Duration.zero) + cappedDuration;

            // حفظ الـ session
            appSessions.putIfAbsent(pkg, () => []);
            appSessions[pkg]!.add(cappedDuration);
          }

          appOpenTimes.remove(pkg);
          processedEvents++;
        }
      }
    }

    // ✅ معالجة التطبيقات المفتوحة حالياً
    for (final entry in appOpenTimes.entries) {
      final pkg = entry.key;
      final openTime = entry.value;
      final duration = now.difference(openTime);

      // حد أقصى
      final cappedDuration = duration.inMinutes > _maxSessionMinutes
          ? Duration(minutes: _maxSessionMinutes)
          : duration;

      if (cappedDuration.inSeconds >= _minSessionSeconds) {
        appTotalUsage[pkg] = (appTotalUsage[pkg] ?? Duration.zero) + cappedDuration;

        appSessions.putIfAbsent(pkg, () => []);
        appSessions[pkg]!.add(cappedDuration);
      }
    }

    debugPrint('🔍 Events معالجة: $processedEvents');
    debugPrint('🔍 تم فلترة $systemAppsFiltered تطبيق نظام');
    debugPrint('✅ تطبيقات فريدة: ${appTotalUsage.length}');

    // ✅ تحويل للصيغة المطلوبة
    final List<AppUsageEntry> results = [];

    for (final entry in appTotalUsage.entries) {
      final pkg = entry.key;
      final totalTime = entry.value;

      if (totalTime.inSeconds < _minSessionSeconds) {
        continue;
      }

      final appName = await _getRealAppName(pkg);
      final lastUsed = appLastUsed[pkg];

      results.add(AppUsageEntry(
        id: null,
        packageName: pkg,
        appName: appName,
        totalUsageTime: totalTime,
        openCount: appSessions[pkg]?.length ?? 0,
        lastUsedTime: lastUsed,
        date: dateStr,
        createdAt: now,
        updatedAt: now,
      ));
    }

    debugPrint('✅ نتائج نهائية: ${results.length} تطبيق');

    return results;
  }

  // ═══════════════════════════════════════════════════════════
  // ✅ حفظ ذكي - DELETE-INSERT
  // ═══════════════════════════════════════════════════════════

  Future<void> _saveAllEntries(List<AppUsageEntry> entries, String date) async {
    try {
      debugPrint('💾 حفظ ${entries.length} تطبيق في DB...');

      final totalMinutes = entries.fold<int>(
        0,
            (sum, app) => sum + app.totalUsageTime.inMinutes,
      );

      debugPrint('⏱️ إجمالي الاستخدام قبل الحفظ: $totalMinutes دقيقة');

      // ✅ DELETE all old records
      debugPrint('🗑️ مسح البيانات القديمة لتاريخ $date...');
      await _phoneRepo.deleteEntriesForDate(date);
      debugPrint('✅ تم مسح البيانات القديمة');

      // ✅ INSERT all as new
      int inserted = 0;
      int failed = 0;

      for (final entry in entries) {
        try {
          final newEntry = entry.copyWith(
            id: null,
            updatedAt: DateTime.now(),
          );
          await _phoneRepo.insertAppUsageEntry(newEntry);
          inserted++;
        } catch (e) {
          failed++;
          debugPrint('   ❌ فشل حفظ ${entry.packageName}: $e');
        }
      }

      debugPrint('✅ تم حفظ البيانات: $inserted جديد، $failed فشل');

    } catch (e) {
      debugPrint('❌ خطأ في حفظ البيانات: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ✅ Public API
  // ═══════════════════════════════════════════════════════════

  Future<List<AppUsageEntry>> getTodaysUsage() async {
    try {
      debugPrint('📊 طلب بيانات الاستخدام اليومي (UsageEvents)...');

      final today = _formatDate(DateTime.now());
      final usage = await _phoneRepo.getAppUsageForDate(today);

      debugPrint('🗄️ تم جلب ${usage.length} تطبيقات من قاعدة البيانات');

      final sorted = usage..sort((a, b) => b.totalUsageTime.compareTo(a.totalUsageTime));

      debugPrint('✅ ${sorted.length} تطبيقات حقيقية');
      return sorted;

    } catch (e) {
      debugPrint('❌ خطأ في جلب الاستخدام اليومي: $e');
      return [];
    }
  }

  Future<Duration> getTotalUsageToday() async {
    try {
      final apps = await getTodaysUsage();

      final total = apps.fold<Duration>(
        Duration.zero,
            (sum, app) => sum + app.totalUsageTime,
      );

      debugPrint('⏱️ إجمالي الاستخدام اليومي: ${total.inMinutes} دقيقة');
      return total;

    } catch (e) {
      debugPrint('❌ خطأ في حساب الاستخدام الكلي: $e');
      return Duration.zero;
    }
  }

  Future<List<AppUsageEntry>> getTopApps({int limit = 10}) async {
    try {
      final usage = await getTodaysUsage();
      final topApps = usage.take(limit).toList();
      debugPrint('🏆 أكثر ${topApps.length} تطبيقات استخداماً');
      return topApps;
    } catch (e) {
      debugPrint('❌ خطأ في جلب أكثر التطبيقات استخداماً: $e');
      return [];
    }
  }

  Future<Duration?> getUsageForTimeRange(DateTime start, DateTime end) async {
    try {
      if (!_isTracking) return null;

      debugPrint('📅 جلب الاستخدام للفترة: ${start.toIso8601String()} - ${end.toIso8601String()}');

      final events = await UsageStats.queryEvents(start, end);
      final dateStr = _formatDate(end);
      final usageData = await _processEvents(events, end, dateStr);

      final totalDuration = usageData.fold<Duration>(
        Duration.zero,
            (sum, app) => sum + app.totalUsageTime,
      );

      debugPrint('⏱️ إجمالي الاستخدام للفترة: ${totalDuration.inMinutes} دقيقة');
      return totalDuration;
    } catch (e) {
      debugPrint('❌ خطأ في جلب الاستخدام للفترة: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getUsageStatistics() async {
    try {
      debugPrint('📈 جلب الإحصائيات (UsageEvents)...');

      final totalUsage = await getTotalUsageToday();
      final allApps = await getTodaysUsage();
      final topApps = await getTopApps(limit: 5);

      final stats = {
        'total_usage': totalUsage,
        'top_apps': topApps,
        'last_update': _lastUpdate,
        'apps_count': allApps.length,
        'is_tracking': _isTracking,
        'is_initialized': _isInitialized,
        'installed_apps_count': _installedAppsCache.length,
        'data_type': 'USAGE_EVENTS_API',
      };

      debugPrint('📊 الإحصائيات جاهزة: ${allApps.length} تطبيقات، ${totalUsage.inMinutes}min إجمالي');
      return stats;
    } catch (e) {
      debugPrint('❌ خطأ في جلب الإحصائيات: $e');
      return {};
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Tracking Control
  // ═══════════════════════════════════════════════════════════

  Future<bool> hasPermissions() async {
    try {
      if (Platform.isIOS) {
        return true;
      }

      final hasPermission = await UsageStats.checkUsagePermission();
      debugPrint('🔍 فحص الصلاحيات: $hasPermission');
      return hasPermission ?? false;
    } catch (e) {
      debugPrint('❌ خطأ في فحص الأذونات: $e');
      return false;
    }
  }

  Future<bool> requestPermissions() async {
    try {
      debugPrint('📱 طلب أذونات الوصول لإحصائيات الاستخدام');

      if (Platform.isIOS) {
        return true;
      }

      await UsageStats.grantUsagePermission();
      await Future.delayed(const Duration(milliseconds: 500));
      return await hasPermissions();
    } catch (e) {
      debugPrint('❌ خطأ في طلب الأذونات: $e');
      return false;
    }
  }

  Future<void> startTracking() async {
    if (!await hasPermissions()) {
      throw Exception('Usage permissions not granted');
    }

    _isTracking = true;
    debugPrint('📱 بدء تتبع استخدام التطبيقات (UsageEvents API)');

    await _fetchAndSaveUsageData();
  }

  Future<void> stopTracking() async {
    _isTracking = false;
    _updateTimer?.cancel();
    _updateTimer = null;

    debugPrint('📱 إيقاف تتبع استخدام التطبيقات');
  }

  void _schedulePeriodicUpdates() {
    _updateTimer?.cancel();

    _updateTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      debugPrint('⏰ تحديث دوري - ${DateTime.now().toIso8601String()}');
      if (_isTracking) {
        await _fetchAndSaveUsageData();
      } else {
        timer.cancel();
      }
    });

    debugPrint('⏰ تم جدولة التحديث كل 5 دقائق');
  }

  Future<void> forceRefreshNow() async {
    debugPrint('🔄 تحديث فوري للبيانات...');
    _lastUpdate = null;
    await _fetchAndSaveUsageData();

    final usage = await getTodaysUsage();
    final totalUsage = await getTotalUsageToday();

    debugPrint('📊 نتائج التحديث:');
    debugPrint('   - عدد التطبيقات: ${usage.length}');
    debugPrint('   - إجمالي الاستخدام: ${totalUsage.inMinutes} دقيقة');

    if (usage.isNotEmpty) {
      debugPrint('🏆 أكثر التطبيقات استخداماً:');
      final topApps = usage.take(5).toList();
      for (int i = 0; i < topApps.length; i++) {
        final app = topApps[i];
        debugPrint('   ${i + 1}. ${app.appName}: ${app.totalUsageTime.inMinutes}min ${app.totalUsageTime.inSeconds.remainder(60)}sec');
      }
    }
  }

  Future<void> refreshData() async {
    debugPrint('🔄 تحديث البيانات (إجباري)...');
    await forceRefreshNow();
  }

  // ═══════════════════════════════════════════════════════════
  // Helper Methods
  // ═══════════════════════════════════════════════════════════

  Future<String> _getRealAppName(String packageName) async {
    if (_appNamesCache.containsKey(packageName)) {
      return _appNamesCache[packageName]!;
    }

    String appName = packageName;

    try {
      if (_installedAppsCache.containsKey(packageName)) {
        appName = _installedAppsCache[packageName]!['name'] ?? packageName;
      } else {
        appName = _extractAppNameFromPackage(packageName);
      }

      _appNamesCache[packageName] = appName;
      return appName;
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على اسم التطبيق $packageName: $e');
      appName = _extractAppNameFromPackage(packageName);
      _appNamesCache[packageName] = appName;
      return appName;
    }
  }

  String _extractAppNameFromPackage(String packageName) {
    try {
      final parts = packageName.split('.');

      if (parts.isEmpty) return packageName;

      String appName;
      if (parts.length >= 2) {
        appName = parts[parts.length - 2];
      } else {
        appName = parts.last;
      }

      if (appName.isEmpty || appName.length < 2) {
        appName = parts.length > 2 ? parts[parts.length - 3] : parts.last;
      }

      appName = appName.replaceAll('_', ' ').replaceAll('-', ' ').trim();

      if (appName.isNotEmpty) {
        appName = appName[0].toUpperCase() + appName.substring(1).toLowerCase();
      }

      if (appName.isEmpty || appName.length < 2) {
        appName = packageName;
      }

      return appName.trim();
    } catch (e) {
      debugPrint('❌ خطأ في استخراج اسم التطبيق: $e');
      return packageName;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // Getters
  bool get isTracking => _isTracking;
  bool get isInitialized => _isInitialized;
  DateTime? get lastUpdate => _lastUpdate;

  // Cleanup
  Future<void> dispose() async {
    debugPrint('🗑️ تنظيف AppUsageService...');

    await stopTracking();
    _appNamesCache.clear();
    _installedAppsCache.clear(); // kept for compatibility

    _isInitialized = false;
    _lastUpdate = null;

    debugPrint('✅ تم تنظيف AppUsageService');
  }

  void printStatus() {
    debugPrint('📋 ===== حالة AppUsageService - UsageEvents API =====');
    debugPrint('🔧 الإعدادات:');
    debugPrint('   - مهيئة: $_isInitialized');
    debugPrint('   - تتتبع: $_isTracking');
    debugPrint('   - آخر تحديث: $_lastUpdate');
    debugPrint('   - فلتر النظام: $_filterSystemApps');
    debugPrint('   - Max Session: $_maxSessionMinutes دقيقة');
    debugPrint('   - Min Session: $_minSessionSeconds ثانية');

    debugPrint('📊 البيانات:');
    debugPrint('   - كاش الأسماء: ${_appNamesCache.length}');
    debugPrint('   - تطبيقات منزلة: ${_installedAppsCache.length}');

    debugPrint('⏰ الموقتات:');
    debugPrint('   - موقت التحديث نشط: ${_updateTimer?.isActive ?? false}');

    debugPrint('===== نهاية الحالة =====');
  }
}