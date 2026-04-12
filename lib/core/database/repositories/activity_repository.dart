// lib/core/repositories/activity_repository_fixed.dart

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../models/activity_models.dart';
import '../models/common_models.dart';
import 'base_repository.dart';

class ActivityRepository extends BaseRepository {
  @override
  String get tableName => 'daily_activity';
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ================================
  // Activity Sessions - جلسات النشاط
  // ================================

  /// إدراج جلسة نشاط جديدة
  Future<int> insertActivitySession(ActivitySession session) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;
      final id = await db.insert('activity_sessions', session.toMap());
      debugPrint('✅ تم إدراج جلسة نشاط: $id');
      return id;
    });
  }

  /// تحديث جلسة النشاط
  Future<bool> updateActivitySession(ActivitySession session) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;
      final count = await db.update(
        'activity_sessions',
        session.toMap(),
        where: 'id = ?',
        whereArgs: [session.id],
      );
      debugPrint('✅ تم تحديث جلسة النشاط: ${session.id}');
      return count > 0;
    });
  }

  /// الحصول على الجلسة النشطة
  Future<ActivitySession?> getActiveActivitySession() async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;
      final maps = await db.query(
        'activity_sessions',
        where: 'end_time IS NULL',
        orderBy: 'start_time DESC',
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return ActivitySession.fromMap(maps.first);
      }
      return null;
    });
  }

  /// الحصول على جلسات النشاط بالتاريخ
  Future<List<ActivitySession>> getActivitySessionsByDate(String date) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      // تحويل التاريخ إلى نطاق زمني
      final startTimestamp = DateTime.parse('${date}T00:00:00').millisecondsSinceEpoch;
      final endTimestamp = DateTime.parse('${date}T23:59:59').millisecondsSinceEpoch;

      final maps = await db.query(
        'activity_sessions',
        where: 'start_time >= ? AND start_time <= ?',
        whereArgs: [startTimestamp, endTimestamp],
        orderBy: 'start_time ASC',
      );

      return maps.map((map) => ActivitySession.fromMap(map)).toList();
    });
  }

  /// حذف جلسة نشاط
  Future<bool> deleteActivitySession(int id) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;
      final count = await db.delete(
        'activity_sessions',
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('🗑️ تم حذف جلسة النشاط: $id');
      return count > 0;
    });
  }

  // ================================
  // Daily Activity - النشاط اليومي
  // ================================

  /// الدالة المفقودة - getDailyActivitiesByDate (توافق مع الكود الموجود)
  Future<DailyActivity?> getDailyActivitiesByDate(String date) async {
    return await getDailyActivityForDate(date);
  }

  /// الحصول على الأنشطة اليومية في فترة
  Future<List<DailyActivity>> getDailyActivitiesInPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final startDateStr = _formatDate(startDate);
      final endDateStr = _formatDate(endDate);

      final maps = await db.query(
        tableName,
        where: 'date >= ? AND date <= ?',
        whereArgs: [startDateStr, endDateStr],
        orderBy: 'date ASC',
      );

      return maps.map((map) => DailyActivity.fromMap(map)).toList();
    });
  }

  /// إدراج أو تحديث النشاط اليومي
  Future<bool> insertOrUpdateDailyActivity(DailyActivity dailyActivity) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final existing = await db.query(
        tableName,
        where: 'date = ?',
        whereArgs: [dailyActivity.date],
      );

      if (existing.isNotEmpty) {
        final count = await db.update(
          tableName,
          dailyActivity.toMap(),
          where: 'date = ?',
          whereArgs: [dailyActivity.date],
        );
        return count > 0;
      } else {
        final id = await db.insert(tableName, dailyActivity.toMap());
        return id > 0;
      }
    });
  }

  /// ⭐ حفظ أو تحديث نشاط يومي (Upsert)
  Future<void> upsertDailyActivity({
    required String date,
    required int totalSteps,
    required double distance,
    required double caloriesBurned,
    required String activityType,
    required double intensityScore,
    int? goalSteps, // ✅ جديد - اختياري
    double? goalDistance, // ✅ جديد - اختياري
    double? goalCalories, // ✅ جديد - اختياري
  }) async {
    try {
      final db = await _dbHelper.database;

      // تحقق إذا كان السجل موجود
      final existing = await db.query(
        'daily_activity',
        where: 'date = ?',
        whereArgs: [date],
      );

      final Map<String, dynamic> activityData = {
        'date': date,
        'total_steps': totalSteps,
        'distance': distance,
        'calories_burned': caloriesBurned,
        'activity_type': activityType,
        'intensity_score': intensityScore,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      };

      // ✅ إضافة الأهداف إذا تم توفيرها
      if (goalSteps != null) activityData['goal_steps'] = goalSteps;
      if (goalDistance != null) activityData['goal_distance'] = goalDistance;
      if (goalCalories != null) activityData['goal_calories'] = goalCalories;

      if (existing.isNotEmpty) {
        // ⭐ تحديث السجل الموجود
        await db.update(
          'daily_activity',
          activityData,
          where: 'date = ?',
          whereArgs: [date],
        );
        debugPrint('🔄 [DB] تحديث: $date → $totalSteps خطوة (هدف: ${goalSteps ?? "غير محدد"})');
      } else {
        // ⭐ إدراج سجل جديد
        activityData['created_at'] = DateTime.now().millisecondsSinceEpoch;

        await db.insert(
          'daily_activity',
          activityData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        debugPrint('➕ [DB] إدراج جديد: $date → $totalSteps خطوة (هدف: ${goalSteps ?? "غير محدد"})');
      }
    } catch (e, stack) {
      debugPrint('❌ [DB] خطأ في upsert: $e');
      debugPrint('Stack: $stack');
    }
  }

  /// ⭐ الحصول على نشاط يومي حسب التاريخ
  Future<DailyActivity?> getDailyActivityForDate(String date) async {
    try {
      final db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        'daily_activity',
        where: 'date = ?',
        whereArgs: [date],
      );

      if (maps.isNotEmpty) {
        debugPrint('📊 [DB] وُجدت بيانات لتاريخ $date: ${maps[0]['total_steps']} خطوة');
        return DailyActivity.fromMap(maps[0]);
      } else {
        debugPrint('📂 [DB] لا توجد بيانات لتاريخ $date');
        return null;
      }
    } catch (e, stack) {
      debugPrint('❌ [DB] خطأ في قراءة البيانات: $e');
      debugPrint('Stack: $stack');
      return null;
    }
  }

  // ================================
  // Statistics - الإحصائيات
  // ================================

  /// إحصائيات بسيطة
  Future<Map<String, dynamic>> getBasicStats() async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final result = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_records,
          SUM(CASE WHEN is_completed = 1 THEN 1 ELSE 0 END) as completed_days,
          AVG(CASE WHEN duration IS NOT NULL AND duration > 0 THEN duration ELSE NULL END) as avg_duration,
          SUM(CASE WHEN distance IS NOT NULL THEN distance ELSE 0 END) as total_distance,
          SUM(CASE WHEN calories IS NOT NULL THEN calories ELSE 0 END) as total_calories,
          SUM(CASE WHEN steps IS NOT NULL THEN steps ELSE 0 END) as total_steps
        FROM $tableName
        WHERE is_completed = 1
      ''');

      final data = result.first;
      return {
        'total_records': data['total_records'] ?? 0,
        'completed_days': data['completed_days'] ?? 0,
        'avg_duration_minutes': data['avg_duration'] != null
            ? (data['avg_duration'] as num) / 60 // Duration is in seconds
            : 0,
        'total_distance': (data['total_distance'] as num?)?.toDouble() ?? 0.0,
        'total_calories': (data['total_calories'] as num?)?.toDouble() ?? 0.0,
        'total_steps': data['total_steps'] ?? 0,
      };
    });
  }

  /// الحصول على إحصائيات النشاط للفترة
  Future<Map<String, dynamic>> getActivityStatsForPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final startDateStr = _formatDate(startDate);
      final endDateStr = _formatDate(endDate);

      // احصائيات يومية من جدول daily_activity
      final dailyStats = await db.rawQuery('''
        SELECT 
          COUNT(*) as active_days,
          AVG(CASE WHEN total_steps > 0 THEN total_steps ELSE NULL END) as avg_daily_steps,
          AVG(CASE WHEN distance > 0 THEN distance ELSE NULL END) as avg_daily_distance,
          AVG(CASE WHEN calories > 0 THEN calories ELSE NULL END) as avg_daily_calories,
          SUM(CASE WHEN total_steps IS NOT NULL THEN total_steps ELSE 0 END) as total_steps,
          SUM(CASE WHEN distance IS NOT NULL THEN distance ELSE 0 END) as total_distance,
          SUM(CASE WHEN calories IS NOT NULL THEN calories ELSE 0 END) as total_calories,
          SUM(CASE WHEN duration IS NOT NULL THEN duration ELSE 0 END) as total_duration
        FROM $tableName 
        WHERE date >= ? AND date <= ?
      ''', [startDateStr, endDateStr]);

      final dailyData = dailyStats.first;

      // احصائيات حسب نوع النشاط
      final activityTypeStats = await db.rawQuery('''
        SELECT 
          COALESCE(activity_type, 'general') as activity_type,
          COUNT(*) as session_count,
          SUM(CASE WHEN duration IS NOT NULL THEN duration ELSE 0 END) as total_duration,
          AVG(CASE WHEN duration IS NOT NULL AND duration > 0 THEN duration ELSE NULL END) as avg_duration,
          SUM(CASE WHEN distance IS NOT NULL THEN distance ELSE 0 END) as total_distance,
          SUM(CASE WHEN calories IS NOT NULL THEN calories ELSE 0 END) as total_calories,
          SUM(CASE WHEN steps IS NOT NULL THEN steps ELSE 0 END) as total_steps
        FROM $tableName 
        WHERE date >= ? AND date <= ? AND is_completed = 1
        GROUP BY COALESCE(activity_type, 'general')
        ORDER BY session_count DESC
      ''', [startDateStr, endDateStr]);

      return {
        'active_days': dailyData['active_days'] ?? 0,
        'avg_daily_steps': (dailyData['avg_daily_steps'] as num?)?.round() ?? 0,
        'avg_daily_distance': (dailyData['avg_daily_distance'] as num?)?.toDouble() ?? 0.0,
        'avg_daily_calories': (dailyData['avg_daily_calories'] as num?)?.toDouble() ?? 0.0,
        'total_steps': (dailyData['total_steps'] as num?)?.toInt() ?? 0,
        'total_distance': (dailyData['total_distance'] as num?)?.toDouble() ?? 0.0,
        'total_calories': (dailyData['total_calories'] as num?)?.toDouble() ?? 0.0,
        'total_duration_minutes': ((dailyData['total_duration'] as num?)?.toDouble() ?? 0.0) / 60,
        'activity_type_breakdown': activityTypeStats,
      };
    });
  }

  /// توليد ملخص النشاط للفترة
  Future<Map<String, dynamic>> generateActivitySummary(
      String startDate,
      String endDate,
      ) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      // إحصائيات عامة
      final generalStats = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_days,
          COUNT(CASE WHEN total_steps > 0 THEN 1 END) as active_days,
          AVG(CASE WHEN total_steps > 0 THEN total_steps ELSE NULL END) as avg_steps,
          MAX(total_steps) as max_steps,
          SUM(CASE WHEN total_steps IS NOT NULL THEN total_steps ELSE 0 END) as total_steps,
          SUM(CASE WHEN distance IS NOT NULL THEN distance ELSE 0 END) as total_distance,
          SUM(CASE WHEN calories IS NOT NULL THEN calories ELSE 0 END) as total_calories,
          SUM(CASE WHEN duration IS NOT NULL THEN duration ELSE 0 END) as total_duration_seconds
        FROM $tableName 
        WHERE date >= ? AND date <= ?
      ''', [startDate, endDate]);

      // إحصائيات حسب نوع النشاط
      final activityBreakdown = await db.rawQuery('''
        SELECT 
          COALESCE(activity_type, 'general') as activity_type,
          COUNT(*) as count,
          SUM(CASE WHEN duration IS NOT NULL THEN duration ELSE 0 END) as total_duration,
          SUM(CASE WHEN distance IS NOT NULL THEN distance ELSE 0 END) as total_distance,
          SUM(CASE WHEN calories IS NOT NULL THEN calories ELSE 0 END) as total_calories,
          SUM(CASE WHEN steps IS NOT NULL THEN steps ELSE 0 END) as total_steps
        FROM $tableName 
        WHERE date >= ? AND date <= ? AND is_completed = 1
        GROUP BY COALESCE(activity_type, 'general')
        ORDER BY count DESC
      ''', [startDate, endDate]);

      final general = generalStats.first;

      return {
        'period': {
          'start_date': startDate,
          'end_date': endDate,
          'total_days': general['total_days'] ?? 0,
          'active_days': general['active_days'] ?? 0,
        },
        'totals': {
          'steps': (general['total_steps'] as num?)?.toInt() ?? 0,
          'distance': (general['total_distance'] as num?)?.toDouble() ?? 0.0,
          'calories': (general['total_calories'] as num?)?.toDouble() ?? 0.0,
          'duration_minutes': ((general['total_duration_seconds'] as num?)?.toDouble() ?? 0.0) / 60,
        },
        'averages': {
          'daily_steps': (general['avg_steps'] as num?)?.round() ?? 0,
          'daily_distance': ((general['total_distance'] as num?)?.toDouble() ?? 0.0) / ((general['active_days'] as num?)?.toInt() ?? 1),
          'daily_calories': ((general['total_calories'] as num?)?.toDouble() ?? 0.0) / ((general['active_days'] as num?)?.toInt() ?? 1),
        },
        'records': {
          'max_steps': (general['max_steps'] as num?)?.toInt() ?? 0,
        },
        'activity_breakdown': activityBreakdown,
      };
    });
  }

  // ================================
  // Data Management - إدارة البيانات
  // ================================

  /// حذف البيانات القديمة
  @override
  Future<Map<String, int>> deleteOldRecords({int daysToKeep = 90}) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final cutoffDateStr = _formatDate(cutoffDate);
      final cutoffTimestamp = cutoffDate.millisecondsSinceEpoch;

      // حذف جلسات النشاط القديمة
      final sessionsDeleted = await db.delete(
        'activity_sessions',
        where: 'start_time < ?',
        whereArgs: [cutoffTimestamp],
      );

      // حذف الأنشطة اليومية القديمة
      final dailyActivitiesDeleted = await db.delete(
        tableName,
        where: 'date < ?',
        whereArgs: [cutoffDateStr],
      );

      debugPrint('🗑️ تم حذف $sessionsDeleted جلسة و $dailyActivitiesDeleted نشاط يومي قديم');

      return {
        'sessions_deleted': sessionsDeleted,
        'daily_activities_deleted': dailyActivitiesDeleted,
        'total_deleted': sessionsDeleted + dailyActivitiesDeleted,
      };
    });
  }

  /// إحصائيات المستودع
  Future<Map<String, dynamic>> getRepositoryStats() async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final dailyCount = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
      final sessionsCount = await db.rawQuery('SELECT COUNT(*) as count FROM activity_sessions');

      final today = _formatDate(DateTime.now());
      final todayActivity = await db.query(
        tableName,
        where: 'date = ?',
        whereArgs: [today],
      );

      final activeSessions = await db.query(
        'activity_sessions',
        where: 'end_time IS NULL',
      );

      return {
        'total_daily_activities': dailyCount.first['count'],
        'total_activity_sessions': sessionsCount.first['count'],
        'has_today_activity': todayActivity.isNotEmpty,
        'active_sessions_count': activeSessions.length,
      };
    });
  }

  // ================================
  // Weekly and Historical Data - البيانات الأسبوعية والتاريخية
  // ================================

  /// الحصول على خطوات الأمس
  Future<int> getYesterdaySteps() async {
    return executeWithErrorHandling(() async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStr = _formatDate(yesterday);

      final activity = await getDailyActivityForDate(yesterdayStr);
      return activity?.totalSteps ?? 0;
    });
  }

  /// الحصول على إجمالي خطوات الأسبوع
  Future<int> getWeeklySteps() async {
    return executeWithErrorHandling(() async {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));

      final activities = await getDailyActivitiesInPeriod(
        startDate: weekStart,
        endDate: weekEnd,
      );

      int totalSteps = 0;
      for (final activity in activities) {
        totalSteps += activity.totalSteps;
      }
      return totalSteps;
    });
  }

  /// حساب تقدم الهدف اليومي (بالنسبة المئوية)
  Future<int> calculateGoalProgress({int dailyGoal = 10000}) async {
    return executeWithErrorHandling(() async {
      final todayStr = _formatDate(DateTime.now());
      final todayActivity = await getDailyActivityForDate(todayStr);

      if (todayActivity == null) return 0;

      final progress = ((todayActivity.totalSteps / dailyGoal) * 100).round();
      return progress.clamp(0, 100);
    });
  }

  /// الحصول على بيانات الأسبوع (آخر 7 أيام)
  Future<List<Map<String, dynamic>>> getWeeklyData() async {
    return executeWithErrorHandling(() async {
      final now = DateTime.now();
      final weeklyData = <Map<String, dynamic>>[];

      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateStr = _formatDate(date);

        final activity = await getDailyActivityForDate(dateStr);

        weeklyData.add({
          'date': dateStr,
          'day_name': _getDayName(date.weekday),
          'steps': activity?.totalSteps ?? 0,
          'distance': activity?.distance ?? 0.0,
          'calories': activity?.caloriesBurned ?? 0.0,
          'active_minutes': activity?.activeMinutes ?? 0,
          'is_today': dateStr == _formatDate(now),
        });
      }

      return weeklyData;
    });
  }

  /// الحصول على بيانات الشهر الحالي
  Future<Map<String, dynamic>> getMonthlyData() async {
    return executeWithErrorHandling(() async {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0);

      final activities = await getDailyActivitiesInPeriod(
        startDate: monthStart,
        endDate: monthEnd,
      );

      int totalSteps = 0;
      double totalDistance = 0.0;
      double totalCalories = 0.0;
      int activeDays = 0;

      for (final activity in activities) {
        totalSteps += activity.totalSteps;
        totalDistance += activity.distance;
        totalCalories += activity.caloriesBurned;
        if (activity.totalSteps > 0) activeDays++;
      }

      final daysInMonth = monthEnd.day;

      return {
        'month': now.month,
        'year': now.year,
        'total_steps': totalSteps,
        'total_distance': totalDistance,
        'total_calories': totalCalories,
        'active_days': activeDays,
        'total_days': daysInMonth,
        'average_daily_steps': totalSteps / daysInMonth,
        'activity_percentage': ((activeDays / daysInMonth) * 100).round(),
      };
    });
  }

  /// الحصول على أفضل يوم في الشهر
  Future<DailyActivity?> getBestDayThisMonth() async {
    return executeWithErrorHandling(() async {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = now;

      final db = await _dbHelper.database;

      final maps = await db.query(
        tableName,
        where: 'date >= ? AND date <= ?',
        whereArgs: [_formatDate(monthStart), _formatDate(monthEnd)],
        orderBy: 'total_steps DESC',
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return DailyActivity.fromMap(maps.first);
      }
      return null;
    });
  }

  // ================================
  // Helper Methods - الدوال المساعدة
  // ================================

  /// تنسيق التاريخ
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// الحصول على اسم اليوم
  String _getDayName(int weekday) {
    const days = ['', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    return days[weekday];
  }

  /// تحليل نوع النشاط من النص
  ActivityType _parseActivityType(String activityTypeStr) {
    try {
      return ActivityType.values.firstWhere(
            (e) => e.name == activityTypeStr,
        orElse: () => ActivityType.general,
      );
    } catch (e) {
      return ActivityType.general;
    }
  }

  /// إنشاء نشاط يومي افتراضي للتاريخ المحدد
  Future<DailyActivity> createDefaultDailyActivity(String date) async {
    final now = DateTime.now();
    return DailyActivity(
      date: date,
      totalSteps: 0,
      distance: 0.0,
      caloriesBurned: 0.0,
      activeMinutes: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// الحصول على النشاط اليومي أو إنشاؤه إذا لم يكن موجود
  Future<DailyActivity> getOrCreateDailyActivity(String date) async {
    var activity = await getDailyActivityForDate(date);
    if (activity == null) {
      activity = await createDefaultDailyActivity(date);
      await insertOrUpdateDailyActivity(activity);
    }
    return activity;
  }

  /// دالة للتوافق مع الكود الموجود
  Future<DailyActivity?> getDailyActivity(String date) async {
    return await getDailyActivityForDate(date);
  }

  /// الحصول على آخر 7 أيام من النشاط
  Future<List<DailyActivity>> getLastWeekActivity() async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 6));

    return await getDailyActivitiesInPeriod(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// الحصول على آخر 30 يوم من النشاط
  Future<List<DailyActivity>> getLastMonthActivity() async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 29));

    return await getDailyActivitiesInPeriod(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// دالة لحساب إحصائيات سريعة لتاريخ معين
  Future<Map<String, dynamic>> getDailyActivityStats(String date) async {
    return executeWithErrorHandling(() async {
      final dailyActivity = await getDailyActivityForDate(date);
      final sessions = await getActivitySessionsByDate(date);

      if (dailyActivity == null) {
        return {
          'has_data': false,
          'total_steps': 0,
          'total_distance': 0.0,
          'total_calories': 0.0,
          'active_minutes': 0,
          'sessions_count': 0,
        };
      }

      return {
        'has_data': true,
        'total_steps': dailyActivity.totalSteps,
        'total_distance': dailyActivity.distance,
        'total_calories': dailyActivity.caloriesBurned,
        'active_minutes': dailyActivity.activeMinutes,
        'sessions_count': sessions.length,
        'fitness_score': dailyActivity.fitnessScore,
      };
    });
  }

  /// التحقق من وجود بيانات لتاريخ معين
  Future<bool> hasDailyActivityData(String date) async {
    return executeWithErrorHandling(() async {
      final activity = await getDailyActivityForDate(date);
      return activity != null;
    });
  }

// ================================
// ⭐ Daily Summaries - ملخصات يومية (للمخططات)
// ================================

  /// الحصول على ملخصات يومية للنشاط (للمخططات البيانية)
  Future<List<ActivityDailySummary>> getDailySummaries({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return executeWithErrorHandling(() async {
      debugPrint('📊 [Activity] جلب الملخصات اليومية من $startDate إلى $endDate');

      final activities = await getDailyActivitiesInPeriod(
        startDate: startDate,
        endDate: endDate,
      );

      final summaries = activities.map((activity) {
        return ActivityDailySummary (
          date: DateTime.parse(activity.date),
          totalSteps: activity.totalSteps,
          distance: activity.distance,
          calories: activity.caloriesBurned,
          activeMinutes: activity.activeMinutes,
        );
      }).toList();

      debugPrint('   ✅ تم جلب ${summaries.length} ملخص يومي');
      return summaries;
    });
  }

  // ═══════════════════════════════════════════════════════════
  // 🔄 Sync Methods
  // ═══════════════════════════════════════════════════════════

  /// جلب الأنشطة غير المرفوعة
  Future<List<DailyActivity>> getUnsyncedActivities() async {
    try {
      final db = await _dbHelper.database;

      final maps = await db.query(
        'daily_activity',
        where: 'synced = ?',
        whereArgs: [0],
        orderBy: 'date DESC',
      );

      debugPrint('📦 [ActivityRepo] وجدنا ${maps.length} نشاط غير مرفوع');

      return maps.map((map) => DailyActivity.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ [ActivityRepo] خطأ في جلب الأنشطة غير المرفوعة: $e');
      return [];
    }
  }

  /// تحديد نشاط كمرفوع
  Future<bool> markAsSynced(String date) async {
    try {
      final db = await _dbHelper.database;

      final count = await db.update(
        'daily_activity',
        {
          'synced': 1,
          'last_sync_time': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'date = ?',
        whereArgs: [date],
      );

      debugPrint('✅ [ActivityRepo] تم تحديد $date كمرفوع');
      return count > 0;
    } catch (e) {
      debugPrint('❌ [ActivityRepo] خطأ في تحديد النشاط كمرفوع: $e');
      return false;
    }
  }

}