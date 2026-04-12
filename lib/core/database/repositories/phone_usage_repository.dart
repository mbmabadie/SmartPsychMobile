// lib/core/repositories/phone_usage_repository.dart
// مدمج مع المراقبة الساعية

import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';

import '../database_helper.dart';
import '../models/app_usage_entry.dart';
import '../models/common_models.dart';
import '../models/hourly_usage_entry.dart';
import '../models/phone_usage_models.dart';
import '../models/unified_usage_data.dart';
import 'base_repository.dart';

class PhoneUsageRepository extends BaseRepository {
  @override
  String get tableName => 'phone_usage_sessions';
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ✅ اسم جدول المراقبة الساعية
  static const String _hourlyTableName = 'hourly_usage_tracking';

  // ✅ إضافة هذه الدالة
  DatabaseHelper getDatabaseHelper() {
    return _dbHelper;
  }

  // أو يمكن إضافة دوال مباشرة للعمليات المطلوبة:

  // ✅ تحديث جدول البيانات الساعية
  Future<void> updateHourlyTrackingTable() async {
    await _dbHelper.updateHourlyTrackingTable();
  }

  // ✅ مسح جميع البيانات
  Future<void> clearAllData() async {
    await _dbHelper.clearAllData();
  }

  // ✅ إعادة إنشاء قاعدة البيانات
  Future<void> recreateDatabase() async {
    await _dbHelper.recreateDatabase();
  }

  // ✅ تنظيف البيانات القديمة
  Future<void> cleanupOldData({int daysToKeep = 30}) async {
    await _dbHelper.cleanupOldData(daysToKeep: daysToKeep);
  }

  // ✅ إصلاح شامل لقاعدة البيانات
  Future<void> performComprehensiveFix() async {
    await _dbHelper.performComprehensiveFix();
  }

  // ✅ إحصائيات قاعدة البيانات
  Future<Map<String, int>> getDatabaseStats() async {
    return await _dbHelper.getDatabaseStats();
  }

  // ==================== الدوال الأساسية للجلسات ====================

  Future<PhoneUsageSession?> getCurrentPhoneUsageSession() async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final maps = await db.query(
        tableName,
        where: 'is_completed = ? AND end_time IS NULL',
        whereArgs: [0],
        orderBy: 'start_time DESC',
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return PhoneUsageSession.fromMap(maps.first);
      }
      return null;
    });
  }

  Future<int> createPhoneUsageSession(PhoneUsageSession session) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final id = await db.insert(tableName, session.toMap());
      debugPrint('✅ تم إنشاء جلسة استخدام هاتف جديدة: $id');
      return id;
    });
  }

  Future<bool> updatePhoneUsageSession(PhoneUsageSession session) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final count = await db.update(
        tableName,
        session.toMap(),
        where: 'id = ?',
        whereArgs: [session.id],
      );

      debugPrint('✅ تم تحديث جلسة الاستخدام: ${session.id}');
      return count > 0;
    });
  }

  Future<List<PhoneUsageSession>> getPhoneUsageSessionsForDate(String date) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final maps = await db.query(
        tableName,
        where: 'date = ?',
        whereArgs: [date],
        orderBy: 'start_time ASC',
      );

      return maps.map((map) => PhoneUsageSession.fromMap(map)).toList();
    });
  }

  // ==================== دوال التطبيقات اليومية ====================

  Future<List<AppUsageEntry>> getAppUsageForDate(String date) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      // ✅ 1. شوف كل الـ records في الجدول
      final allMaps = await db.query('app_usage_entries');
      debugPrint('🔍 إجمالي records في app_usage_entries: ${allMaps.length}');

      // ✅ 2. شوف كم record لهذا التاريخ
      final countMaps = await db.rawQuery(
        'SELECT COUNT(*) as count FROM app_usage_entries WHERE date = ?',
        [date],
      );
      final count = Sqflite.firstIntValue(countMaps) ?? 0;
      debugPrint('🔍 عدد records للتاريخ $date: $count');

      // ✅ 3. جلب البيانات
      final maps = await db.query(
        'app_usage_entries',
        where: 'date = ?',
        whereArgs: [date],
        orderBy: 'total_usage_time DESC',
      );

      debugPrint('🔍 تم جلب ${maps.length} records فعلياً');

      // ✅ 4. اطبع أول 3 package names
      if (maps.isNotEmpty) {
        debugPrint('🔍 أول 3 تطبيقات:');
        for (int i = 0; i < maps.length && i < 3; i++) {
          debugPrint('   ${i+1}. ${maps[i]['package_name']} (${maps[i]['app_name']})');
        }
      }

      return maps.map((map) => AppUsageEntry.fromMap(map)).toList();
    });
  }

  /// حذف كل البيانات لتاريخ معين
  Future<void> deleteEntriesForDate(String date) async {
    try {
      final db = await _dbHelper.database;
      await db.delete(
        'app_usage_entries',
        where: 'date = ?',
        whereArgs: [date],
      );
      debugPrint('🗑️ تم حذف جميع البيانات لتاريخ $date');
    } catch (e) {
      debugPrint('❌ خطأ في حذف البيانات: $e');
      rethrow;
    }
  }

  Future<List<AppUsageEntry>> getAppUsageForPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final startDateStr = _formatDate(startDate);
      final endDateStr = _formatDate(endDate);

      final maps = await db.rawQuery('''
        SELECT app_name, package_name,
               SUM(total_usage_time) as total_usage_time,
               SUM(open_count) as open_count,
               AVG(last_used_time) as last_used_time,
               MAX(date) as date
        FROM app_usage_entries 
        WHERE date >= ? AND date <= ?
        GROUP BY app_name, package_name
        ORDER BY total_usage_time DESC
      ''', [startDateStr, endDateStr]);

      return maps.map((map) => AppUsageEntry.fromMap(map)).toList();
    });
  }

  Future<int> insertAppUsageEntry(AppUsageEntry entry) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final id = await db.insert(
        'app_usage_entries',
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return id;
    });
  }

  Future<bool> updateAppUsageEntry(AppUsageEntry entry) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final count = await db.update(
        'app_usage_entries',
        entry.toMap(),
        where: 'id = ?',
        whereArgs: [entry.id],
      );

      return count > 0;
    });
  }

  // ==================== ✅ دوال المراقبة الساعية الجديدة ====================

  /// إدراج بيانات ساعة جديدة
  Future<int> insertHourlyUsage(HourlyUsageEntry entry) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      debugPrint('💾 حفظ بيانات الساعة: ${entry.date} ${entry.hour}:00 - ${entry.appName} (${entry.usageMinutes}min)');

      final id = await db.insert(
        _hourlyTableName,
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace, // استبدال في حالة التكرار
      );

      debugPrint('✅ تم حفظ البيانات الساعية بـ ID: $id');
      return id;
    });
  }

  /// إدراج مجموعة من البيانات الساعية
  Future<List<int>> insertMultipleHourlyUsage(List<HourlyUsageEntry> entries) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;
      final List<int> ids = [];

      debugPrint('💾 حفظ ${entries.length} مدخل ساعي...');

      await db.transaction((txn) async {
        for (final entry in entries) {
          final id = await txn.insert(
            _hourlyTableName,
            entry.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          ids.add(id);
        }
      });

      debugPrint('✅ تم حفظ ${entries.length} مدخل ساعي بنجاح');
      return ids;
    });
  }

  /// جلب بيانات ساعية لتاريخ محدد
  Future<List<HourlyUsageEntry>> getHourlyUsageForDate(String date) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      debugPrint('📊 جلب البيانات الساعية لتاريخ: $date');

      final List<Map<String, dynamic>> maps = await db.query(
        _hourlyTableName,
        where: 'date = ?',
        whereArgs: [date],
        orderBy: 'hour ASC, usage_minutes DESC',
      );

      final entries = maps.map((map) => HourlyUsageEntry.fromMap(map)).toList();

      debugPrint('📋 تم جلب ${entries.length} مدخل ساعي لتاريخ $date');
      return entries;
    });
  }

  /// جلب بيانات ساعة محددة
  Future<List<HourlyUsageEntry>> getHourlyUsageForSpecificHour(String date, int hour) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      debugPrint('🕐 جلب بيانات الساعة $hour لتاريخ $date');

      final List<Map<String, dynamic>> maps = await db.query(
        _hourlyTableName,
        where: 'date = ? AND hour = ?',
        whereArgs: [date, hour],
        orderBy: 'usage_minutes DESC',
      );

      final entries = maps.map((map) => HourlyUsageEntry.fromMap(map)).toList();

      debugPrint('📱 تم جلب ${entries.length} تطبيق للساعة $hour');
      return entries;
    });
  }

  /// جلب أكثر التطبيقات استخداماً في ساعة محددة
  Future<List<HourlyUsageEntry>> getTopAppsForHour(String date, int hour, {int limit = 5}) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        _hourlyTableName,
        where: 'date = ? AND hour = ? AND usage_minutes > 0',
        whereArgs: [date, hour],
        orderBy: 'usage_minutes DESC',
        limit: limit,
      );

      final entries = maps.map((map) => HourlyUsageEntry.fromMap(map)).toList();

      debugPrint('🏆 أكثر ${entries.length} تطبيقات في الساعة $hour');
      return entries;
    });
  }


  /// تحديث بيانات ساعية
  Future<int> updateHourlyUsage(HourlyUsageEntry entry) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      debugPrint('🔄 تحديث البيانات الساعية: ${entry.date} ${entry.hour}:00 - ${entry.appName}');

      final updatedRows = await db.update(
        _hourlyTableName,
        entry.toMap(),
        where: 'date = ? AND hour = ? AND package_name = ?',
        whereArgs: [entry.date, entry.hour, entry.packageName],
      );

      debugPrint('✅ تم تحديث $updatedRows صف');
      return updatedRows;
    });
  }

  /// فحص وجود بيانات لساعة محددة
  Future<bool> hasDataForHour(String date, int hour) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final List<Map<String, dynamic>> result = await db.query(
        _hourlyTableName,
        where: 'date = ? AND hour = ?',
        whereArgs: [date, hour],
        limit: 1,
      );

      return result.isNotEmpty;
    });
  }

  /// حذف جميع بيانات يوم محدد
  Future<int> deleteAllHourlyUsageForDate(String date) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final deletedRows = await db.delete(
        _hourlyTableName,
        where: 'date = ?',
        whereArgs: [date],
      );

      debugPrint('🗑️ تم حذف $deletedRows مدخل ساعي لتاريخ $date');
      return deletedRows;
    });
  }

  // ==================== باقي الدوال الأصلية ====================

  Future<Map<String, dynamic>> getUsageStatsForPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final startDateStr = _formatDate(startDate);
      final endDateStr = _formatDate(endDate);

      // احصائيات الجلسات
      final sessionStats = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_sessions,
          AVG(total_usage_time) as avg_session_time,
          SUM(total_usage_time) as total_usage_time,
          MIN(total_usage_time) as min_session_time,
          MAX(total_usage_time) as max_session_time
        FROM $tableName 
        WHERE date >= ? AND date <= ? AND is_completed = 1
      ''', [startDateStr, endDateStr]);

      // احصائيات التطبيقات
      final appStats = await db.rawQuery('''
        SELECT 
          COUNT(DISTINCT app_name) as unique_apps,
          AVG(total_usage_time) as avg_app_time,
          SUM(open_count) as total_opens
        FROM app_usage_entries 
        WHERE date >= ? AND date <= ?
      ''', [startDateStr, endDateStr]);

      final sessionData = sessionStats.first;
      final appData = appStats.first;

      return {
        'total_sessions': sessionData['total_sessions'] ?? 0,
        'avg_session_time': sessionData['avg_session_time'] != null
            ? Duration(milliseconds: (sessionData['avg_session_time'] as num).round())
            : const Duration(),
        'total_usage_time': sessionData['total_usage_time'] != null
            ? Duration(milliseconds: (sessionData['total_usage_time'] as num).round())
            : const Duration(),
        'min_session_time': sessionData['min_session_time'] != null
            ? Duration(milliseconds: sessionData['min_session_time'] as int)
            : const Duration(),
        'max_session_time': sessionData['max_session_time'] != null
            ? Duration(milliseconds: sessionData['max_session_time'] as int)
            : const Duration(),
        'unique_apps': appData['unique_apps'] ?? 0,
        'avg_app_time': appData['avg_app_time'] != null
            ? Duration(milliseconds: (appData['avg_app_time'] as num).round())
            : const Duration(),
        'total_opens': appData['total_opens'] ?? 0,
      };
    });
  }

  Future<List<AppUsageEntry>> getTopAppsForPeriod({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final startDateStr = _formatDate(startDate);
      final endDateStr = _formatDate(endDate);

      final maps = await db.rawQuery('''
        SELECT app_name, package_name,
               SUM(total_usage_time) as total_usage_time,
               SUM(open_count) as open_count,
               MAX(last_used_time) as last_used_time,
               MAX(date) as date
        FROM app_usage_entries 
        WHERE date >= ? AND date <= ?
        GROUP BY app_name, package_name
        ORDER BY total_usage_time DESC
        LIMIT ?
      ''', [startDateStr, endDateStr, limit]);

      return maps.map((map) => AppUsageEntry.fromMap(map)).toList();
    });
  }

  // إعدادات المستخدم
  Future<T> getUserSetting<T>(String key, T defaultValue) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final maps = await db.query(
        'user_settings',
        where: 'key = ?',
        whereArgs: [key],
      );

      if (maps.isNotEmpty) {
        final value = maps.first['value'];
        if (T == int) return int.tryParse(value.toString()) as T? ?? defaultValue;
        if (T == double) return double.tryParse(value.toString()) as T? ?? defaultValue;
        if (T == bool) return (value.toString().toLowerCase() == 'true') as T? ?? defaultValue;
        return value as T? ?? defaultValue;
      }

      return defaultValue;
    }) ?? defaultValue;
  }

  Future<bool> setUserSetting(String key, dynamic value) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final settingMap = {
        'key': key,
        'value': value.toString(),
        'updated_at': now,
      };

      final existing = await db.query(
        'user_settings',
        where: 'key = ?',
        whereArgs: [key],
      );

      if (existing.isNotEmpty) {
        final count = await db.update(
          'user_settings',
          settingMap,
          where: 'key = ?',
          whereArgs: [key],
        );
        return count > 0;
      } else {
        settingMap['created_at'] = now;
        final id = await db.insert('user_settings', settingMap);
        return id > 0;
      }
    });
  }

  Future<Map<String, Duration>> getDailyUsageForWeek() async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 7));

      final maps = await db.rawQuery('''
        SELECT date, SUM(total_usage_time) as daily_usage
        FROM $tableName 
        WHERE date >= ? AND date <= ? AND is_completed = 1
        GROUP BY date
        ORDER BY date ASC
      ''', [_formatDate(startDate), _formatDate(endDate)]);

      final result = <String, Duration>{};
      for (final map in maps) {
        final date = map['date'] as String;
        final usage = map['daily_usage'] as int? ?? 0;
        result[date] = Duration(milliseconds: usage);
      }

      return result;
    });
  }

  @override
  Future<Map<String, int>> deleteOldRecords({int daysToKeep = 90}) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final cutoffDateStr = _formatDate(cutoffDate);

      final sessionsDeleted = await db.delete(
        tableName,
        where: 'date < ?',
        whereArgs: [cutoffDateStr],
      );

      final appEntriesDeleted = await db.delete(
        'app_usage_entries',
        where: 'date < ?',
        whereArgs: [cutoffDateStr],
      );

      // ✅ حذف البيانات الساعية القديمة أيضاً
      final hourlyEntriesDeleted = await db.delete(
        _hourlyTableName,
        where: 'date < ?',
        whereArgs: [cutoffDateStr],
      );

      debugPrint('🗑️ تم حذف $sessionsDeleted جلسة و $appEntriesDeleted إدخال تطبيق و $hourlyEntriesDeleted إدخال ساعي قديم');

      return {
        'sessions_deleted': sessionsDeleted,
        'app_entries_deleted': appEntriesDeleted,
        'hourly_entries_deleted': hourlyEntriesDeleted, // ✅ إضافة العداد الجديد
      };
    });
  }

  Future<Map<String, dynamic>> getAppDetailedStats(String appName, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      final startDateStr = _formatDate(start);
      final endDateStr = _formatDate(end);

      final maps = await db.rawQuery('''
        SELECT 
          COUNT(*) as days_used,
          SUM(total_usage_time) as total_usage,
          AVG(total_usage_time) as avg_daily_usage,
          SUM(open_count) as total_opens,
          AVG(open_count) as avg_daily_opens,
          MIN(date) as first_use_date,
          MAX(date) as last_use_date
        FROM app_usage_entries 
        WHERE app_name = ? AND date >= ? AND date <= ?
      ''', [appName, startDateStr, endDateStr]);

      final result = maps.first;
      return {
        'app_name': appName,
        'days_used': result['days_used'] ?? 0,
        'total_usage': Duration(milliseconds: (result['total_usage'] as num?)?.round() ?? 0),
        'avg_daily_usage': Duration(milliseconds: (result['avg_daily_usage'] as num?)?.round() ?? 0),
        'total_opens': result['total_opens'] ?? 0,
        'avg_daily_opens': (result['avg_daily_opens'] as num?)?.round() ?? 0,
        'first_use_date': result['first_use_date'] as String?,
        'last_use_date': result['last_use_date'] as String?,
      };
    });
  }

  Future<int> upsertPhoneUsageSession(PhoneUsageSession session) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final existing = await db.query(
        tableName,
        where: 'date = ?',
        whereArgs: [session.date],
      );

      if (existing.isNotEmpty) {
        final count = await db.update(
          tableName,
          session.toMap(),
          where: 'date = ?',
          whereArgs: [session.date],
        );
        return existing.first['id'] as int;
      } else {
        return await db.insert(tableName, session.toMap());
      }
    });
  }

  Future<PhoneUsageSession?> getPhoneUsageForDate(String date) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final maps = await db.query(
        tableName,
        where: 'date = ?',
        whereArgs: [date],
      );

      if (maps.isNotEmpty) {
        final session = PhoneUsageSession.fromMap(maps.first);
        final appUsages = await getAppUsagesForSession(session.id!);
        return session.copyWith(appUsages: appUsages);
      }
      return null;
    });
  }

  Future<Map<String, dynamic>> getPhoneUsageStatsForPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final startDateStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      final endDateStr = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

      final maps = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_days,
          AVG(total_usage_time) as avg_usage_time,
          AVG(total_pickups) as avg_pickups,
          AVG(night_usage_duration) as avg_night_usage,
          SUM(sleep_interruptions) as total_interruptions
        FROM $tableName 
        WHERE date >= ? AND date <= ?
      ''', [startDateStr, endDateStr]);

      final result = maps.first;
      return {
        'total_days': result['total_days'] ?? 0,
        'avg_usage_time': result['avg_usage_time'] != null
            ? Duration(milliseconds: (result['avg_usage_time'] as num).round())
            : Duration.zero,
        'avg_pickups': (result['avg_pickups'] as num?)?.round() ?? 0,
        'avg_night_usage': result['avg_night_usage'] != null
            ? Duration(milliseconds: (result['avg_night_usage'] as num).round())
            : Duration.zero,
        'total_interruptions': result['total_interruptions'] ?? 0,
      };
    });
  }

  // App Usage Operations
  Future<int> insertAppUsage(AppUsage appUsage) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;
      return await db.insert('app_usage', appUsage.toMap());
    });
  }

  Future<List<AppUsage>> getAppUsagesForSession(int sessionId) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final maps = await db.query(
        'app_usage',
        where: 'phone_session_id = ?',
        whereArgs: [sessionId],
        orderBy: 'usage_time DESC',
      );

      return maps.map((map) => AppUsage.fromMap(map)).toList();
    });
  }

  // ==================== دوال مساعدة ====================

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _calculateUsageIntensity(double totalMinutes) {
    if (totalMinutes == 0) return 'لا يوجد';
    if (totalMinutes < 60) return 'قليل';
    if (totalMinutes < 180) return 'متوسط';
    if (totalMinutes < 360) return 'عالي';
    return 'مفرط';
  }

  // ✅ حفظ البيانات الساعية الموحدة
  Future<void> saveUnifiedHourlyData(List<UnifiedHourlyUsageData> data) async {
    try {
      final db = await _dbHelper.database;

      await db.transaction((txn) async {
        for (final entry in data) {
          await txn.insert(
            'hourly_usage_tracking',
            entry.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });

      debugPrint('💾 تم حفظ ${data.length} مدخل ساعي موحد');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ البيانات الساعية الموحدة: $e');
      rethrow;
    }
  }

  // lib/core/database/repositories/phone_usage_repository.dart - استكمال الدوال

  // ✅ جلب البيانات الساعية الموحدة
  Future<List<UnifiedHourlyUsageData>> getUnifiedHourlyData(String date) async {
    try {
      final db = await _dbHelper.database;

      final maps = await db.query(
        'hourly_usage_tracking',
        where: 'date = ?',
        whereArgs: [date],
        orderBy: 'hour ASC, usage_minutes DESC',
      );

      final data = maps.map((map) => UnifiedHourlyUsageData.fromMap(map)).toList();
      debugPrint('📊 تم جلب ${data.length} مدخل ساعي موحد لتاريخ $date');

      return data;
    } catch (e) {
      debugPrint('❌ خطأ في جلب البيانات الساعية الموحدة: $e');
      return [];
    }
  }

  // ✅ تحديث الساعة الحالية
  Future<void> updateCurrentHourData(String date, int hour, List<UnifiedHourlyUsageData> data) async {
    try {
      final db = await _dbHelper.database;

      await db.transaction((txn) async {
        // مسح البيانات القديمة للساعة الحالية
        await txn.delete(
          'hourly_usage_tracking',
          where: 'date = ? AND hour = ? AND is_current_hour = 1',
          whereArgs: [date, hour],
        );

        // إدراج البيانات الجديدة
        for (final entry in data) {
          await txn.insert(
            'hourly_usage_tracking',
            entry.copyWith(
              isCurrentHour: true,
              isFinalized: false,
              dataSource: 'live_current',
              lastSyncTime: DateTime.now(),
            ).toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });

      debugPrint('🔄 تم تحديث ${data.length} مدخل للساعة الحالية $hour');
    } catch (e) {
      debugPrint('❌ خطأ في تحديث الساعة الحالية: $e');
    }
  }

  // ✅ إنهاء الساعة السابقة
  Future<void> finalizeHour(String date, int hour) async {
    try {
      final db = await _dbHelper.database;

      await db.update(
        'hourly_usage_tracking',
        {
          'is_finalized': 1,
          'is_current_hour': 0,
          'data_source': 'finalized',
          'last_sync_time': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'date = ? AND hour = ?',
        whereArgs: [date, hour],
      );

      debugPrint('✅ تم إنهاء الساعة $hour لتاريخ $date');
    } catch (e) {
      debugPrint('❌ خطأ في إنهاء الساعة: $e');
    }
  }

  // ✅ ملخص البيانات الساعية للتاريخ
  Future<List<Map<String, dynamic>>> getHourlySummaryForDate(String date) async {
    try {
      final db = await _dbHelper.database;

      final maps = await db.rawQuery('''
       SELECT 
         hour,
         SUM(usage_minutes) as usage_minutes,
         SUM(open_count) as pickups,
         COUNT(DISTINCT package_name) as apps_count,
         GROUP_CONCAT(app_name) as apps_used,
         MAX(is_current_hour) as is_current,
         MAX(CASE WHEN hour > ? THEN 1 ELSE 0 END) as is_future,
         COUNT(*) > 0 as has_real_data
       FROM hourly_usage_tracking 
       WHERE date = ? 
       GROUP BY hour 
       ORDER BY hour ASC
     ''', [DateTime.now().hour, date]);

      final result = <Map<String, dynamic>>[];

      // إنشاء مصفوفة كاملة من 24 ساعة
      for (int hour = 0; hour < 24; hour++) {
        final hourData = maps.firstWhere(
              (m) => m['hour'] == hour,
          orElse: () => {
            'hour': hour,
            'usage_minutes': 0.0,
            'pickups': 0,
            'apps_count': 0,
            'apps_used': '',
            'is_current': hour == DateTime.now().hour ? 1 : 0,
            'is_future': hour > DateTime.now().hour ? 1 : 0,
            'has_real_data': 0,
          },
        );

        // تحويل apps_used من نص إلى قائمة
        final appsUsedString = hourData['apps_used'] as String? ?? '';
        final appsUsedList = appsUsedString.isNotEmpty
            ? appsUsedString.split(',').take(5).toList()
            : <String>[];

        result.add({
          'hour': hour,
          'usage_minutes': (hourData['usage_minutes'] as num?)?.toDouble() ?? 0.0,
          'pickups': hourData['pickups'] as int? ?? 0,
          'apps_used': appsUsedList,
          'apps_count': hourData['apps_count'] as int? ?? 0,
          'is_current': (hourData['is_current'] as int?) == 1,
          'is_future': (hourData['is_future'] as int?) == 1,
          'has_real_data': (hourData['has_real_data'] as int?) == 1,
        });
      }

      debugPrint('📈 تم إنتاج ملخص 24 ساعة، ${result.where((h) => h['usage_minutes'] > 0).length} ساعات لها بيانات');
      return result;
    } catch (e) {
      debugPrint('❌ خطأ في ملخص البيانات الساعية: $e');
      return _generateEmptyHourlySummary();
    }
  }

  // ✅ إنتاج ملخص فارغ
  List<Map<String, dynamic>> _generateEmptyHourlySummary() {
    return List.generate(24, (hour) => {
      'hour': hour,
      'usage_minutes': 0.0,
      'pickups': 0,
      'apps_used': <String>[],
      'apps_count': 0,
      'is_current': hour == DateTime.now().hour,
      'is_future': hour > DateTime.now().hour,
      'has_real_data': false,
    });
  }

  // ✅ البيانات الساعية للأسبوع
  Future<Map<String, double>> getWeeklyHourlyUsage(DateTime startDate) async {
    try {
      final db = await _dbHelper.database;
      final endDate = startDate.add(const Duration(days: 7));

      final startDateStr = _formatDate(startDate);
      final endDateStr = _formatDate(endDate);

      final maps = await db.rawQuery('''
       SELECT 
         date,
         SUM(usage_minutes) as total_minutes
       FROM hourly_usage_tracking 
       WHERE date >= ? AND date <= ?
       GROUP BY date 
       ORDER BY date ASC
     ''', [startDateStr, endDateStr]);

      final weeklyData = <String, double>{};
      for (final map in maps) {
        final date = map['date'] as String;
        final minutes = (map['total_minutes'] as num?)?.toDouble() ?? 0.0;
        weeklyData[date] = minutes;
      }

      debugPrint('📅 تم جلب بيانات ${weeklyData.length} أيام أسبوعية');
      return weeklyData;
    } catch (e) {
      debugPrint('❌ خطأ في البيانات الأسبوعية: $e');
      return {};
    }
  }

  // ✅ إحصائيات المراقبة الساعية
  Future<Map<String, dynamic>> getHourlyUsageStatistics(String date) async {
    try {
      final db = await _dbHelper.database;

      final stats = await db.rawQuery('''
       SELECT 
         COUNT(*) as total_entries,
         COUNT(DISTINCT hour) as hours_covered,
         COUNT(DISTINCT package_name) as unique_apps,
         SUM(usage_minutes) as total_usage_minutes,
         SUM(open_count) as total_opens,
         AVG(usage_minutes) as avg_usage_per_entry,
         MAX(usage_minutes) as max_usage_entry,
         COUNT(CASE WHEN is_current_hour = 1 THEN 1 END) as current_hour_entries,
         COUNT(CASE WHEN is_finalized = 1 THEN 1 END) as finalized_entries
       FROM hourly_usage_tracking 
       WHERE date = ?
     ''', [date]);

      final result = stats.isNotEmpty ? stats.first : <String, dynamic>{};

      // إضافة معلومات إضافية
      result['date'] = date;
      result['data_coverage_percent'] =
          ((result['hours_covered'] as int? ?? 0) / 24 * 100).round();

      debugPrint('📊 إحصائيات المراقبة الساعية: ${result['hours_covered']} ساعات مغطاة');
      return result;
    } catch (e) {
      debugPrint('❌ خطأ في إحصائيات المراقبة الساعية: $e');
      return {'date': date, 'total_entries': 0};
    }
  }

  // ✅ تنظيف البيانات الساعية القديمة
  Future<int> deleteOldHourlyData(int daysToKeep) async {
    try {
      final db = await _dbHelper.database;
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final cutoffDateStr = _formatDate(cutoffDate);

      final deletedCount = await db.delete(
        'hourly_usage_tracking',
        where: 'date < ?',
        whereArgs: [cutoffDateStr],
      );

      if (deletedCount > 0) {
        debugPrint('🗑️ تم حذف $deletedCount مدخل ساعي قديم (أقدم من $daysToKeep يوم)');
      }

      return deletedCount;
    } catch (e) {
      debugPrint('❌ خطأ في حذف البيانات الساعية القديمة: $e');
      return 0;
    }
  }

  // ✅ فحص تطابق البيانات
  Future<Map<String, dynamic>> validateDataConsistency(String date) async {
    try {
      final db = await _dbHelper.database;

      // البيانات اليومية
      final dailyData = await db.rawQuery('''
       SELECT 
         SUM(total_usage_time) / 1000 / 60 as daily_total_minutes,
         SUM(open_count) as daily_total_opens,
         COUNT(*) as daily_apps_count
       FROM app_usage_entries 
       WHERE date = ?
     ''', [date]);

      // البيانات الساعية
      final hourlyData = await db.rawQuery('''
       SELECT 
         SUM(usage_minutes) as hourly_total_minutes,
         SUM(open_count) as hourly_total_opens,
         COUNT(DISTINCT package_name) as hourly_apps_count
       FROM hourly_usage_tracking 
       WHERE date = ?
     ''', [date]);

      final daily = dailyData.isNotEmpty ? dailyData.first : <String, dynamic>{};
      final hourly = hourlyData.isNotEmpty ? hourlyData.first : <String, dynamic>{};

      final dailyMinutes = (daily['daily_total_minutes'] as num?)?.toDouble() ?? 0.0;
      final hourlyMinutes = (hourly['hourly_total_minutes'] as num?)?.toDouble() ?? 0.0;

      final difference = (dailyMinutes - hourlyMinutes).abs();
      final isConsistent = difference <= 5.0; // هامش خطأ 5 دقائق

      final result = {
        'date': date,
        'daily_total_minutes': dailyMinutes,
        'hourly_total_minutes': hourlyMinutes,
        'difference_minutes': difference,
        'is_consistent': isConsistent,
        'daily_apps': daily['daily_apps_count'] ?? 0,
        'hourly_apps': hourly['hourly_apps_count'] ?? 0,
        'consistency_percent': hourlyMinutes > 0
            ? ((1 - (difference / hourlyMinutes)) * 100).clamp(0, 100).round()
            : (dailyMinutes == 0 ? 100 : 0),
      };

      debugPrint('🔍 فحص التطابق: ${result['consistency_percent']}% متطابق');
      return result;
    } catch (e) {
      debugPrint('❌ خطأ في فحص التطابق: $e');
      return {'date': date, 'is_consistent': false};
    }
  }

  // ✅ إصلاح عدم التطابق
  Future<void> fixDataInconsistency(String date) async {
    try {
      debugPrint('🔧 بدء إصلاح عدم التطابق لتاريخ $date');

      final db = await _dbHelper.database;

      // جلب البيانات اليومية (المصدر الأساسي)
      final dailyApps = await getAppUsageForDate(date);

      if (dailyApps.isEmpty) {
        debugPrint('⚠️ لا توجد بيانات يومية للإصلاح');
        return;
      }

      // حذف البيانات الساعية القديمة
      await db.delete(
        'hourly_usage_tracking',
        where: 'date = ?',
        whereArgs: [date],
      );

      // إعادة إنشاء البيانات الساعية من البيانات اليومية
      final hourlyEntries = <UnifiedHourlyUsageData>[];
      final now = DateTime.now();

      for (final app in dailyApps) {
        final totalMinutes = app.totalUsageTime.inMinutes.toDouble();
        if (totalMinutes <= 0) continue;

        // توزيع بسيط على الساعات
        final distribution = _distributeUsageForRepair(totalMinutes, app.openCount);

        for (final entry in distribution.entries) {
          final hour = entry.key;
          final usage = entry.value;

          if (usage > 0) {
            final hourStart = DateTime.parse('${date}T${hour.toString().padLeft(2, '0')}:00:00');
            final hourEnd = hourStart.add(const Duration(hours: 1));

            hourlyEntries.add(UnifiedHourlyUsageData(
              date: date,
              hour: hour,
              packageName: app.packageName,
              appName: app.appName,
              usageMinutes: usage,
              openCount: (app.openCount * (usage / totalMinutes)).round(),
              isCurrentHour: false,
              isFinalized: true,
              dataSource: 'repaired',
              lastSyncTime: now,
              startTime: hourStart,
              endTime: hourEnd,
            ));
          }
        }
      }

      // حفظ البيانات المصلحة
      await saveUnifiedHourlyData(hourlyEntries);

      debugPrint('✅ تم إصلاح ${hourlyEntries.length} مدخل ساعي');

    } catch (e) {
      debugPrint('❌ خطأ في إصلاح عدم التطابق: $e');
    }
  }

  // ✅ توزيع بسيط للإصلاح
  Map<int, double> _distributeUsageForRepair(double totalMinutes, int openCount) {
    final distribution = <int, double>{};

    // توزيع بسيط على ساعات العمل النموذجية
    final activeHours = [9, 10, 11, 14, 15, 16, 20, 21, 22];
    final minutesPerHour = totalMinutes / activeHours.length;

    for (final hour in activeHours) {
      distribution[hour] = minutesPerHour;
    }

    return distribution;
  }

// ================================
// ⭐ Daily Summaries - ملخصات يومية (للمخططات)
// ================================

  /// الحصول على ملخصات يومية لاستخدام الهاتف (للمخططات البيانية)
  Future<List<PhoneDailySummary>> getDailySummaries({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return executeWithErrorHandling(() async {
      debugPrint('📊 [Phone] جلب الملخصات اليومية من $startDate إلى $endDate');

      final db = await _dbHelper.database;

      final startDateStr = _formatDate(startDate);
      final endDateStr = _formatDate(endDate);

      // جلب البيانات من app_usage_entries
      final maps = await db.rawQuery('''
      SELECT 
        date,
        SUM(total_usage_time) as total_usage_milliseconds,
        SUM(open_count) as total_pickups
      FROM app_usage_entries 
      WHERE date >= ? AND date <= ?
      GROUP BY date
      ORDER BY date ASC
    ''', [startDateStr, endDateStr]);

      final summaries = <PhoneDailySummary>[];

      for (final map in maps) {
        final dateStr = map['date'] as String;
        final usageMs = (map['total_usage_milliseconds'] as num?)?.toInt() ?? 0;
        final pickups = (map['total_pickups'] as num?)?.toInt() ?? 0;

        summaries.add(PhoneDailySummary(
          date: DateTime.parse(dateStr),
          totalUsageTime: Duration(milliseconds: usageMs),
          totalPickups: pickups,
        ));
      }

      debugPrint('   ✅ تم جلب ${summaries.length} ملخص يومي للهاتف');
      return summaries;
    });
  }

  // ═══════════════════════════════════════════════════════════
  // 🔄 Sync Methods
  // ═══════════════════════════════════════════════════════════

  /// جلب سجلات الاستخدام غير المرفوعة
  Future<List<AppUsageEntry>> getUnsyncedEntries() async {
    try {
      final db = await _dbHelper.database;

      final maps = await db.query(
        'app_usage_entries',
        where: 'synced = ?',
        whereArgs: [0],
        orderBy: 'date DESC',
        limit: 100, // حد أقصى 100 سجل في المرة
      );

      debugPrint('📦 [PhoneUsageRepo] وجدنا ${maps.length} سجل استخدام غير مرفوع');

      return maps.map((map) => AppUsageEntry.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ [PhoneUsageRepo] خطأ في جلب سجلات الاستخدام غير المرفوعة: $e');
      return [];
    }
  }

  /// تحديد سجل استخدام كمرفوع
  Future<bool> markAsSynced(int entryId) async {
    try {
      final db = await _dbHelper.database;

      final count = await db.update(
        'app_usage_entries',
        {
          'synced': 1,
          'last_sync_time': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [entryId],
      );

      debugPrint('✅ [PhoneUsageRepo] تم تحديد سجل الاستخدام $entryId كمرفوع');
      return count > 0;
    } catch (e) {
      debugPrint('❌ [PhoneUsageRepo] خطأ في تحديد سجل الاستخدام كمرفوع: $e');
      return false;
    }
  }

}