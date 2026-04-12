// lib/core/database/repositories/sleep_repository.dart
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../models/environmental_conditions.dart';
import '../models/sleep_models.dart';
import '../models/sleep_settings.dart';
import '../models/sleep_confidence.dart'; // ✅ إضافة جديدة
import 'package:shared_preferences/shared_preferences.dart';

class SleepRepository {
  static final SleepRepository _instance = SleepRepository._internal();
  factory SleepRepository() => _instance;
  SleepRepository._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ================================
  // Sleep Sessions Management - إدارة جلسات النوم
  // ================================

  /// إدراج جلسة نوم جديدة
  Future<int> insertSleepSession(SleepSession session) async {
    try {
      final db = await _dbHelper.database;
      final id = await db.insert('sleep_sessions', session.toMap());

      debugPrint('💾 تم حفظ جلسة النوم: $id (${session.confidence.displayName})');
      return id;
    } catch (e) {
      debugPrint('❌ خطأ في حفظ جلسة النوم: $e');
      rethrow;
    }
  }

  /// تحديث جلسة نوم موجودة
  Future<void> updateSleepSession(SleepSession session) async {
    try {
      if (session.id == null) {
        throw ArgumentError('معرف الجلسة مطلوب للتحديث');
      }

      final db = await _dbHelper.database;
      final updated = await db.update(
        'sleep_sessions',
        session.toMap(),
        where: 'id = ?',
        whereArgs: [session.id],
      );

      if (updated == 0) {
        throw Exception('لم يتم العثور على الجلسة للتحديث');
      }

      debugPrint('✅ تم تحديث جلسة النوم: ${session.id}');
    } catch (e) {
      debugPrint('❌ خطأ في تحديث جلسة النوم: $e');
      rethrow;
    }
  }

  /// الحصول على جلسة نوم بالمعرف
  Future<SleepSession?> getSleepSessionById(int id) async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        'sleep_sessions',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (results.isEmpty) return null;
      return SleepSession.fromMap(results.first);
    } catch (e) {
      debugPrint('❌ خطأ في جلب جلسة النوم: $e');
      return null;
    }
  }

  /// الحصول على جلسات نوم لتاريخ محدد
  Future<List<SleepSession>> getSleepSessionsForDate(String date) async {
    try {
      final startDate = DateTime.parse('${date}T00:00:00');
      final endDate = DateTime.parse('${date}T23:59:59');

      final db = await _dbHelper.database;
      final results = await db.query(
        'sleep_sessions',
        where: 'start_time >= ? AND start_time <= ?',
        whereArgs: [
          startDate.millisecondsSinceEpoch,
          endDate.millisecondsSinceEpoch,
        ],
        orderBy: 'start_time DESC',
      );

      return results.map((map) => SleepSession.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ خطأ في جلب جلسات النوم للتاريخ $date: $e');
      return [];
    }
  }

  /// الحصول على جلسات نوم في نطاق زمني
  Future<List<SleepSession>> getSleepSessionsInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        'sleep_sessions',
        where: 'start_time >= ? AND start_time <= ?',
        whereArgs: [
          startDate.millisecondsSinceEpoch,
          endDate.millisecondsSinceEpoch,
        ],
        orderBy: 'start_time DESC',
      );

      return results.map((map) => SleepSession.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ خطأ في جلب جلسات النوم في النطاق: $e');
      return [];
    }
  }

  /// الحصول على أحدث جلسة نوم
  Future<SleepSession?> getLatestSleepSession() async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        'sleep_sessions',
        orderBy: 'start_time DESC',
        limit: 1,
      );

      if (results.isEmpty) return null;
      return SleepSession.fromMap(results.first);
    } catch (e) {
      debugPrint('❌ خطأ في جلب أحدث جلسة نوم: $e');
      return null;
    }
  }

  /// تأكيد جلسة نوم
  Future<void> confirmSleepSession(int sessionId) async {
    try {
      final db = await _dbHelper.database;
      final updated = await db.update(
        'sleep_sessions',
        {
          'user_confirmation': 'confirmed',
          'user_confirmation_status': 'confirmed',
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [sessionId],
      );

      if (updated == 0) {
        throw Exception('لم يتم العثور على الجلسة');
      }

      debugPrint('✅ تم تأكيد جلسة النوم: $sessionId');
    } catch (e) {
      debugPrint('❌ خطأ في تأكيد جلسة النوم: $e');
      rethrow;
    }
  }

  /// رفض جلسة نوم
  Future<void> rejectSleepSession(int sessionId) async {
    try {
      final db = await _dbHelper.database;
      final updated = await db.update(
        'sleep_sessions',
        {
          'user_confirmation': 'rejected',
          'user_confirmation_status': 'rejected',
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [sessionId],
      );

      if (updated == 0) {
        throw Exception('لم يتم العثور على الجلسة');
      }

      debugPrint('🚫 تم رفض جلسة النوم: $sessionId');
    } catch (e) {
      debugPrint('❌ خطأ في رفض جلسة النوم: $e');
      rethrow;
    }
  }

  /// الحصول على الجلسات المعلقة (تحتاج تأكيد) - ✅ محدّث
  Future<List<SleepSession>> getPendingConfirmations() async {
    try {
      final db = await _dbHelper.database;

      debugPrint('🔍 جلب الجلسات المعلقة...');

      final results = await db.query(
        'sleep_sessions',
        where: '''
        is_completed = 1 
        AND (user_confirmation_status = ? OR user_confirmation_status IS NULL)
        AND confidence IN (?, ?)
        AND duration IS NOT NULL
        AND duration >= ?
      ''',
        whereArgs: [
          'pending',
          SleepConfidence.probable.toDbString(),
          SleepConfidence.uncertain.toDbString(),
          900000, // ← 15 دقيقة بالميلي ثانية (15 * 60 * 1000)
        ],
        orderBy: 'end_time DESC',
        limit: 10,
      );

      final sessions = results.map((map) => SleepSession.fromMap(map)).toList();

      debugPrint('✅ تم جلب ${sessions.length} جلسة معلقة');
      for (final session in sessions) {
        debugPrint('   - ${session.id}: ${session.confidence.displayName} (${session.duration?.inMinutes}m)');
      }

      return sessions;

    } catch (e, stack) {
      debugPrint('❌ خطأ في جلب التأكيدات المعلقة: $e');
      debugPrint('Stack: $stack');
      return [];
    }
  }

  /// الحصول على الجلسة النشطة (غير المكتملة)
  Future<SleepSession?> getActiveSleepSession() async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        'sleep_sessions',
        where: 'is_completed = ?',
        whereArgs: [0],
        orderBy: 'start_time DESC',
        limit: 1,
      );

      if (results.isEmpty) return null;
      return SleepSession.fromMap(results.first);
    } catch (e) {
      debugPrint('❌ خطأ في جلب الجلسة النشطة: $e');
      return null;
    }
  }

  /// حذف جلسة نوم
  Future<void> deleteSleepSession(int id) async {
    try {
      final db = await _dbHelper.database;

      await db.transaction((txn) async {
        // حذف الانقطاعات المرتبطة
        await txn.delete(
          'sleep_interruptions',
          where: 'sleep_session_id = ?',
          whereArgs: [id],
        );

        // حذف البيانات البيئية المرتبطة
        await txn.delete(
          'environmental_data',
          where: 'sleep_session_id = ?',
          whereArgs: [id],
        );

        // حذف الجلسة
        final deleted = await txn.delete(
          'sleep_sessions',
          where: 'id = ?',
          whereArgs: [id],
        );

        if (deleted == 0) {
          throw Exception('لم يتم العثور على الجلسة للحذف');
        }
      });

      debugPrint('🗑️ تم حذف جلسة النوم: $id');
    } catch (e) {
      debugPrint('❌ خطأ في حذف جلسة النوم: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  // 🆕 نظام التصنيف الذكي - Smart Classification System
  // ════════════════════════════════════════════════════════════

  /// الحصول على جلسات حسب التصنيف
  Future<List<SleepSession>> getSleepSessionsByConfidence({
    required SleepConfidence confidence,
    int? limit,
  }) async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        'sleep_sessions',
        where: 'confidence = ?',
        whereArgs: [confidence.toDbString()],
        orderBy: 'start_time DESC',
        limit: limit,
      );

      debugPrint('📊 تم جلب ${results.length} جلسة بتصنيف: ${confidence.displayName}');
      return results.map((map) => SleepSession.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ خطأ في جلب الجلسات حسب التصنيف: $e');
      return [];
    }
  }

  /// الحصول على الجلسات التي تحتاج تأكيد (Probable + Uncertain)
  Future<List<SleepSession>> getSleepSessionsNeedingConfirmation() async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        'sleep_sessions',
        where: 'confidence IN (?, ?) AND user_confirmed_sleep = ?',
        whereArgs: [
          SleepConfidence.probable.toDbString(),
          SleepConfidence.uncertain.toDbString(),
          0,
        ],
        orderBy: 'start_time DESC',
        limit: 20,
      );

      debugPrint('🤔 تم جلب ${results.length} جلسة تحتاج تأكيد');
      return results.map((map) => SleepSession.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ خطأ في جلب الجلسات التي تحتاج تأكيد: $e');
      return [];
    }
  }

  /// تأكيد جلسة نوم من المستخدم (نظام التصنيف الذكي)
  Future<void> userConfirmSleepSession({
    required int sessionId,
    required bool isSleep,
  }) async {
    try {
      final db = await _dbHelper.database;

      final now = DateTime.now().millisecondsSinceEpoch;

      final updates = <String, dynamic>{  // ✅ التصحيح هنا
        'user_confirmed_sleep': isSleep ? 1 : 0,
        'confirmation_time': now,
        'updated_at': now,
      };

      // إذا أكد المستخدم أنه نوم، غير التصنيف إلى Confirmed
      if (isSleep) {
        updates['confidence'] = SleepConfidence.confirmed.toDbString();
        updates['user_confirmation_status'] = 'confirmed';
      } else {
        // إذا رفض، غير إلى Phone Left
        updates['confidence'] = SleepConfidence.phoneLeft.toDbString();
        updates['user_confirmation_status'] = 'rejected';
      }

      final updated = await db.update(
        'sleep_sessions',
        updates,
        where: 'id = ?',
        whereArgs: [sessionId],
      );

      if (updated == 0) {
        throw Exception('لم يتم العثور على الجلسة');
      }

      debugPrint(isSleep
          ? '✅ تم تأكيد الجلسة $sessionId كنوم من المستخدم'
          : '📱 تم تصنيف الجلسة $sessionId كهاتف متروك من المستخدم');
    } catch (e) {
      debugPrint('❌ خطأ في تأكيد/رفض الجلسة: $e');
      rethrow;
    }
  }


  /// تحديث معلومات النشاط قبل النوم
  Future<void> updatePreSleepActivity({
    required int sessionId,
    required bool hasActivity,
    DateTime? lastPhoneUsage,
    int? lastStepsCount,
  }) async {
    try {
      final db = await _dbHelper.database;

      final updates = <String, dynamic>{
        'has_pre_sleep_activity': hasActivity ? 1 : 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      };

      if (lastPhoneUsage != null) {
        updates['last_phone_usage'] = lastPhoneUsage.millisecondsSinceEpoch;
      }

      if (lastStepsCount != null) {
        updates['last_steps_count'] = lastStepsCount;
      }

      final updated = await db.update(
        'sleep_sessions',
        updates,
        where: 'id = ?',
        whereArgs: [sessionId],
      );

      if (updated == 0) {
        throw Exception('لم يتم العثور على الجلسة');
      }

      debugPrint('✅ تم تحديث معلومات النشاط قبل النوم للجلسة $sessionId');
    } catch (e) {
      debugPrint('❌ خطأ في تحديث معلومات النشاط: $e');
      rethrow;
    }
  }

  /// الحصول على إحصائيات التصنيف - ✅ محدّث (يرجع List)
  Future<List<Map<String, dynamic>>> getConfidenceStatistics({int days = 30}) async {
    try {
      final db = await _dbHelper.database;
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      debugPrint('📊 جلب إحصائيات التصنيف لآخر $days يوم...');

      final results = await db.rawQuery('''
      SELECT 
        confidence,
        COUNT(*) as count,
        AVG(CASE WHEN duration IS NOT NULL THEN duration ELSE 0 END) / 60000.0 / 60.0 as avg_hours
      FROM sleep_sessions
      WHERE start_time >= ? AND is_completed = 1
      GROUP BY confidence
      ORDER BY count DESC
    ''', [cutoffDate.millisecondsSinceEpoch]);

      final stats = <Map<String, dynamic>>[];

      for (final row in results) {
        final confidenceStr = row['confidence'] as String? ?? 'uncertain';
        final count = row['count'] as int? ?? 0;
        final avgHours = (row['avg_hours'] as num?)?.toDouble() ?? 0.0;

        // ✅ فلترة: فقط الأنواع اللي عندها sessions
        if (count > 0) {
          stats.add({
            'confidence': confidenceStr,
            'count': count,
            'avg_hours': avgHours,
          });
        }
      }

      debugPrint('📊 إحصائيات التصنيف: ${stats.length} أنواع');
      for (final stat in stats) {
        debugPrint('   - ${stat['confidence']}: ${stat['count']} جلسات (متوسط: ${stat['avg_hours'].toStringAsFixed(1)}h)');
      }

      return stats;

    } catch (e, stack) {
      debugPrint('❌ خطأ في إحصائيات التصنيف: $e');
      debugPrint('Stack: $stack');
      return [];
    }
  }

  /// الحصول على الجلسات التي تُحسب في الإحصائيات فقط
  Future<List<SleepSession>> getCountableStatsSessions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final db = await _dbHelper.database;

      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      // فقط Confirmed و Probable
      final results = await db.query(
        'sleep_sessions',
        where: '''
          start_time >= ? AND start_time <= ? 
          AND confidence IN (?, ?)
        ''',
        whereArgs: [
          start.millisecondsSinceEpoch,
          end.millisecondsSinceEpoch,
          SleepConfidence.confirmed.toDbString(),
          SleepConfidence.probable.toDbString(),
        ],
        orderBy: 'start_time DESC',
      );

      debugPrint('📊 تم جلب ${results.length} جلسة تُحسب في الإحصائيات');
      return results.map((map) => SleepSession.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ خطأ في جلب جلسات الإحصائيات: $e');
      return [];
    }
  }

  // ================================
  // Sleep Interruptions - الانقطاعات
  // ================================

  /// إدراج انقطاع جديد
  Future<int> insertInterruption({
    required int sessionId,
    required String type,
    required DateTime timestamp,
    int? durationSeconds,
    String? notes,
  }) async {
    try {
      final db = await _dbHelper.database;
      final id = await db.insert('sleep_interruptions', {
        'sleep_session_id': sessionId,
        'interruption_type': type,
        'interruption_start': timestamp.millisecondsSinceEpoch,
        'duration': durationSeconds,
        'notes': notes,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });

      debugPrint('⚠️ تم تسجيل انقطاع: $type في الجلسة $sessionId');
      return id;
    } catch (e) {
      debugPrint('❌ خطأ في حفظ الانقطاع: $e');
      rethrow;
    }
  }

  /// الحصول على انقطاعات جلسة معينة
  Future<List<Map<String, dynamic>>> getInterruptionsForSession(int sessionId) async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        'sleep_interruptions',
        where: 'sleep_session_id = ?',
        whereArgs: [sessionId],
        orderBy: 'interruption_start ASC',
      );

      return results.toList();
    } catch (e) {
      debugPrint('❌ خطأ في جلب انقطاعات الجلسة: $e');
      return [];
    }
  }

  /// تحديث انقطاع
  Future<void> updateInterruption(int id, Map<String, dynamic> updates) async {
    try {
      final db = await _dbHelper.database;
      final updated = await db.update(
        'sleep_interruptions',
        updates,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (updated == 0) {
        throw Exception('لم يتم العثور على الانقطاع');
      }

      debugPrint('✅ تم تحديث الانقطاع: $id');
    } catch (e) {
      debugPrint('❌ خطأ في تحديث الانقطاع: $e');
      rethrow;
    }
  }

  /// الحصول على عدد الانقطاعات الكلي لجلسة
  Future<int> getTotalInterruptionsCount(int sessionId) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('''
        SELECT COUNT(*) as count 
        FROM sleep_interruptions 
        WHERE sleep_session_id = ?
      ''', [sessionId]);

      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      debugPrint('❌ خطأ في حساب عدد الانقطاعات: $e');
      return 0;
    }
  }

  // ================================
  // Sleep Goals - أهداف النوم
  // ================================

  /// إدراج هدف نوم جديد
  Future<int> insertSleepGoal({
    required int targetHours,
    required int targetMinutes,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final db = await _dbHelper.database;

      // إلغاء الأهداف النشطة الحالية
      await db.update(
        'sleep_goals',
        {'is_active': 0, 'updated_at': DateTime.now().millisecondsSinceEpoch},
        where: 'is_active = ?',
        whereArgs: [1],
      );

      final id = await db.insert('sleep_goals', {
        'user_age': 25,
        'recommended_hours': targetHours.toDouble(),
        'sleep_window_start': 21,
        'sleep_window_end': 7,
        'is_active': 1,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });

      debugPrint('🎯 تم إنشاء هدف نوم جديد: ${targetHours}h');
      return id;
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء هدف النوم: $e');
      rethrow;
    }
  }

  /// الحصول على هدف النوم النشط
  Future<Map<String, dynamic>?> getActiveSleepGoal() async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        'sleep_goals',
        where: 'is_active = ?',
        whereArgs: [1],
        limit: 1,
      );

      if (results.isEmpty) return null;
      return results.first;
    } catch (e) {
      debugPrint('❌ خطأ في جلب هدف النوم النشط: $e');
      return null;
    }
  }

  /// تحديث هدف النوم
  Future<void> updateSleepGoal(int goalId, {
    int? targetHours,
    int? targetMinutes,
    bool? isActive,
  }) async {
    try {
      final db = await _dbHelper.database;
      final updates = <String, dynamic>{};

      if (targetHours != null) updates['recommended_hours'] = targetHours.toDouble();
      if (isActive != null) updates['is_active'] = isActive ? 1 : 0;
      updates['updated_at'] = DateTime.now().millisecondsSinceEpoch;

      final updated = await db.update(
        'sleep_goals',
        updates,
        where: 'id = ?',
        whereArgs: [goalId],
      );

      if (updated == 0) {
        throw Exception('لم يتم العثور على الهدف');
      }

      debugPrint('✅ تم تحديث هدف النوم: $goalId');
    } catch (e) {
      debugPrint('❌ خطأ في تحديث هدف النوم: $e');
      rethrow;
    }
  }

  // ================================
  // Environmental Data - البيانات البيئية
  // ================================

  /// إدراج بيانات بيئية
  Future<int> insertEnvironmentalData({
    required int sleepSessionId,
    required EnvironmentalConditions conditions,
  }) async {
    try {
      final db = await _dbHelper.database;
      final data = conditions.copyWith(sleepSessionId: sleepSessionId);
      final id = await db.insert('environmental_data', data.toMap());

      return id;
    } catch (e) {
      debugPrint('❌ خطأ في حفظ البيانات البيئية: $e');
      rethrow;
    }
  }

  /// الحصول على البيانات البيئية لجلسة
  Future<List<EnvironmentalConditions>> getEnvironmentalDataForSession(int sessionId) async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        'environmental_data',
        where: 'sleep_session_id = ?',
        whereArgs: [sessionId],
        orderBy: 'timestamp ASC',
      );

      return results.map((map) => EnvironmentalConditions.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ خطأ في جلب البيانات البيئية: $e');
      return [];
    }
  }

  /// حساب متوسط درجات البيئة
  Future<Map<String, double>> getAverageEnvironmentScores(int sessionId) async {
    try {
      final db = await _dbHelper.database;
      final results = await db.rawQuery('''
        SELECT 
          AVG(light_level) as avg_light,
          AVG(noise_level) as avg_noise,
          AVG(movement_intensity) as avg_movement,
          AVG(temperature) as avg_temp,
          AVG(humidity) as avg_humidity
        FROM environmental_data 
        WHERE sleep_session_id = ?
      ''', [sessionId]);

      if (results.isEmpty) return {};

      final result = results.first;
      return {
        'light_level': (result['avg_light'] as num?)?.toDouble() ?? 0.0,
        'noise_level': (result['avg_noise'] as num?)?.toDouble() ?? 0.0,
        'movement_intensity': (result['avg_movement'] as num?)?.toDouble() ?? 0.0,
        'temperature': (result['avg_temp'] as num?)?.toDouble() ?? 0.0,
        'humidity': (result['avg_humidity'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      debugPrint('❌ خطأ في حساب متوسط البيئة: $e');
      return {};
    }
  }

  // ================================
  // Statistics & Analytics - الإحصائيات والتحليلات
  // ================================

  /// إحصائيات النوم اليومية
  Future<Map<String, dynamic>> getDailySleepStats(DateTime date) async {
    try {
      final db = await _dbHelper.database;
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final results = await db.rawQuery('''
        SELECT 
          COUNT(*) as sessions_count,
          SUM(CASE WHEN duration IS NOT NULL THEN duration ELSE 0 END) as total_duration,
          AVG(CASE WHEN overall_sleep_quality IS NOT NULL THEN overall_sleep_quality ELSE 0 END) as avg_quality,
          SUM(CASE WHEN total_interruptions IS NOT NULL THEN total_interruptions ELSE 0 END) as total_interruptions,
          AVG(CASE WHEN environment_stability_score IS NOT NULL THEN environment_stability_score ELSE 0 END) as avg_environment
        FROM sleep_sessions 
        WHERE start_time >= ? AND start_time < ? 
        AND confidence IN (?, ?)
      ''', [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
        SleepConfidence.confirmed.toDbString(),
        SleepConfidence.probable.toDbString(),
      ]);

      final result = results.first;
      return {
        'date': date.toIso8601String(),
        'sessions_count': result['sessions_count'] ?? 0,
        'total_duration_minutes': ((result['total_duration'] as num?) ?? 0) / 60,
        'average_quality': (result['avg_quality'] as num?)?.toDouble() ?? 0.0,
        'total_interruptions': result['total_interruptions'] ?? 0,
        'average_environment': (result['avg_environment'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      debugPrint('❌ خطأ في إحصائيات النوم اليومية: $e');
      return {};
    }
  }

  /// إحصائيات النوم الأسبوعية
  Future<Map<String, dynamic>> getWeeklySleepStats() async {
    try {
      final db = await _dbHelper.database;
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));

      final results = await db.rawQuery('''
        SELECT 
          DATE(start_time / 1000, 'unixepoch', 'localtime') as sleep_date,
          COUNT(*) as sessions_count,
          SUM(CASE WHEN duration IS NOT NULL THEN duration ELSE 0 END) / 60.0 as total_minutes,
          AVG(CASE WHEN overall_sleep_quality IS NOT NULL THEN overall_sleep_quality ELSE 0 END) as avg_quality,
          SUM(CASE WHEN total_interruptions IS NOT NULL THEN total_interruptions ELSE 0 END) as total_interruptions
        FROM sleep_sessions 
        WHERE start_time >= ? 
        AND confidence IN (?, ?)
        GROUP BY sleep_date
        ORDER BY sleep_date DESC
      ''', [
        weekAgo.millisecondsSinceEpoch,
        SleepConfidence.confirmed.toDbString(),
        SleepConfidence.probable.toDbString(),
      ]);

      final dailyData = results.map((row) => {
        'date': row['sleep_date'] as String,
        'sessions_count': row['sessions_count'] ?? 0,
        'total_minutes': (row['total_minutes'] as num?)?.toDouble() ?? 0.0,
        'avg_quality': (row['avg_quality'] as num?)?.toDouble() ?? 0.0,
        'total_interruptions': row['total_interruptions'] ?? 0,
      }).toList();

      final totalMinutes = dailyData.fold<double>(0.0, (sum, day) => sum + (day['total_minutes'] as double));
      final avgQuality = dailyData.isNotEmpty
          ? dailyData.fold<double>(0.0, (sum, day) => sum + (day['avg_quality'] as double)) / dailyData.length
          : 0.0;

      return {
        'daily_data': dailyData,
        'total_sleep_minutes': totalMinutes,
        'average_minutes_per_night': dailyData.isNotEmpty ? totalMinutes / dailyData.length : 0.0,
        'average_quality': avgQuality,
        'nights_tracked': dailyData.length,
      };
    } catch (e) {
      debugPrint('❌ خطأ في إحصائيات النوم الأسبوعية: $e');
      return {};
    }
  }

  /// إحصائيات النوم الشهرية
  Future<Map<String, dynamic>> getMonthlySleepStats() async {
    try {
      final db = await _dbHelper.database;
      final monthAgo = DateTime.now().subtract(const Duration(days: 30));

      final results = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_sessions,
          AVG(CASE WHEN duration IS NOT NULL THEN duration ELSE 0 END) / 60.0 as avg_duration_minutes,
          AVG(CASE WHEN overall_sleep_quality IS NOT NULL THEN overall_sleep_quality ELSE 0 END) as avg_quality,
          MIN(CASE WHEN overall_sleep_quality IS NOT NULL THEN overall_sleep_quality END) as min_quality,
          MAX(CASE WHEN overall_sleep_quality IS NOT NULL THEN overall_sleep_quality END) as max_quality,
          SUM(CASE WHEN total_interruptions > 2 THEN 1 ELSE 0 END) as disturbed_nights,
          AVG(CASE WHEN environment_stability_score IS NOT NULL THEN environment_stability_score ELSE 0 END) as avg_environment
        FROM sleep_sessions 
        WHERE start_time >= ? AND is_completed = 1 
        AND confidence IN (?, ?)
      ''', [
        monthAgo.millisecondsSinceEpoch,
        SleepConfidence.confirmed.toDbString(),
        SleepConfidence.probable.toDbString(),
      ]);

      final result = results.first;

      final goalAchievementRate = await _calculateGoalAchievementRate(30);

      return {
        'total_sessions': result['total_sessions'] ?? 0,
        'average_duration_minutes': (result['avg_duration_minutes'] as num?)?.toDouble() ?? 0.0,
        'average_quality': (result['avg_quality'] as num?)?.toDouble() ?? 0.0,
        'min_quality': (result['min_quality'] as num?)?.toDouble() ?? 0.0,
        'max_quality': (result['max_quality'] as num?)?.toDouble() ?? 0.0,
        'disturbed_nights': result['disturbed_nights'] ?? 0,
        'average_environment': (result['avg_environment'] as num?)?.toDouble() ?? 0.0,
        'goal_achievement_rate': goalAchievementRate,
      };
    } catch (e) {
      debugPrint('❌ خطأ في إحصائيات النوم الشهرية: $e');
      return {};
    }
  }

  /// تحليل اتجاهات جودة النوم
  Future<Map<String, dynamic>> getSleepQualityTrends({int days = 30}) async {
    try {
      final db = await _dbHelper.database;
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      final results = await db.rawQuery('''
        SELECT 
          DATE(start_time / 1000, 'unixepoch', 'localtime') as date,
          AVG(overall_sleep_quality) as avg_quality,
          COUNT(*) as sessions_count
        FROM sleep_sessions 
        WHERE start_time >= ? 
        AND overall_sleep_quality IS NOT NULL 
        AND confidence IN (?, ?)
        GROUP BY date
        ORDER BY date ASC
      ''', [
        cutoffDate.millisecondsSinceEpoch,
        SleepConfidence.confirmed.toDbString(),
        SleepConfidence.probable.toDbString(),
      ]);

      final trendData = results.map((row) => {
        'date': row['date'] as String,
        'avg_quality': (row['avg_quality'] as num?)?.toDouble() ?? 0.0,
        'sessions_count': row['sessions_count'] ?? 0,
      }).toList();

      String trend = 'stable';
      if (trendData.length >= 7) {
        final recentAvg = trendData.sublist(trendData.length - 7).fold<double>(
            0.0,
                (sum, day) => sum + (day['avg_quality'] as double)
        ) / 7;

        final olderAvg = trendData.sublist(0, min(7, trendData.length - 7)).fold<double>(
            0.0,
                (sum, day) => sum + (day['avg_quality'] as double)
        ) / min(7, trendData.length - 7);

        if (recentAvg > olderAvg + 0.5) {
          trend = 'improving';
        } else if (recentAvg < olderAvg - 0.5) {
          trend = 'declining';
        }
      }

      return {
        'trend_data': trendData,
        'trend': trend,
        'data_points': trendData.length,
      };
    } catch (e) {
      debugPrint('❌ خطأ في تحليل اتجاهات الجودة: $e');
      return {};
    }
  }

  /// تحليل تأثير استخدام الهاتف على النوم
  Future<Map<String, dynamic>> getPhoneUsageImpact() async {
    try {
      final db = await _dbHelper.database;
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final results = await db.rawQuery('''
        SELECT 
          CASE WHEN phone_activations > 0 THEN 'with_phone' ELSE 'without_phone' END as usage_category,
          COUNT(*) as sessions_count,
          AVG(overall_sleep_quality) as avg_quality,
          AVG(duration) / 60.0 as avg_duration_minutes,
          AVG(total_interruptions) as avg_interruptions
        FROM sleep_sessions 
        WHERE start_time >= ? 
        AND overall_sleep_quality IS NOT NULL 
        AND confidence IN (?, ?)
        GROUP BY usage_category
      ''', [
        thirtyDaysAgo.millisecondsSinceEpoch,
        SleepConfidence.confirmed.toDbString(),
        SleepConfidence.probable.toDbString(),
      ]);

      final withPhone = results.firstWhere(
            (r) => r['usage_category'] == 'with_phone',
        orElse: () => {'sessions_count': 0, 'avg_quality': 0.0, 'avg_duration_minutes': 0.0, 'avg_interruptions': 0.0},
      );

      final withoutPhone = results.firstWhere(
            (r) => r['usage_category'] == 'without_phone',
        orElse: () => {'sessions_count': 0, 'avg_quality': 0.0, 'avg_duration_minutes': 0.0, 'avg_interruptions': 0.0},
      );

      final qualityDifference = (withoutPhone['avg_quality'] as num).toDouble() -
          (withPhone['avg_quality'] as num).toDouble();

      return {
        'with_phone_usage': {
          'sessions_count': withPhone['sessions_count'],
          'avg_quality': (withPhone['avg_quality'] as num?)?.toDouble() ?? 0.0,
          'avg_duration_minutes': (withPhone['avg_duration_minutes'] as num?)?.toDouble() ?? 0.0,
          'avg_interruptions': (withPhone['avg_interruptions'] as num?)?.toDouble() ?? 0.0,
        },
        'without_phone_usage': {
          'sessions_count': withoutPhone['sessions_count'],
          'avg_quality': (withoutPhone['avg_quality'] as num?)?.toDouble() ?? 0.0,
          'avg_duration_minutes': (withoutPhone['avg_duration_minutes'] as num?)?.toDouble() ?? 0.0,
          'avg_interruptions': (withoutPhone['avg_interruptions'] as num?)?.toDouble() ?? 0.0,
        },
        'quality_difference': qualityDifference,
        'impact_assessment': qualityDifference > 0.5
            ? 'negative_impact'
            : qualityDifference < -0.5
            ? 'positive_impact'
            : 'minimal_impact',
      };
    } catch (e) {
      debugPrint('❌ خطأ في تحليل تأثير استخدام الهاتف: $e');
      return {};
    }
  }

  // ================================
  // Sleep Settings - إعدادات النوم
  // ================================

  /// حفظ إعدادات النوم
  Future<void> saveSleepSettings(SleepSettings settings) async {
    try {
      final db = await _dbHelper.database;
      final settingsMap = settings.toMap();

      for (final entry in settingsMap.entries) {
        await db.insert(
          'app_settings',
          {
            'key': entry.key,
            'value': entry.value.toString(),
            'value_type': _getValueType(entry.value),
            'created_at': DateTime.now().millisecondsSinceEpoch,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      debugPrint('⚙️ تم حفظ إعدادات النوم');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ إعدادات النوم: $e');
      rethrow;
    }
  }

  /// جلب إعدادات النوم
  Future<SleepSettings> getSleepSettings() async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        'app_settings',
        where: 'key LIKE ?',
        whereArgs: ['sleep_%'],
      );

      final settingsMap = <String, dynamic>{};
      for (final row in results) {
        final key = row['key'] as String;
        final value = row['value'] as String;
        final type = row['value_type'] as String;

        settingsMap[key] = _parseSettingValue(value, type);
      }

      return SleepSettings.fromMap(settingsMap);
    } catch (e) {
      debugPrint('❌ خطأ في جلب إعدادات النوم: $e');
      return const SleepSettings();
    }
  }

  /// تحديث إعدادات النافذة الزمنية
  Future<void> updateSleepWindowSettings({
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required bool adaptiveEnabled,
  }) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final settings = [
        {'key': 'sleep_window_start_hour', 'value': startTime.hour.toString()},
        {'key': 'sleep_window_start_minute', 'value': startTime.minute.toString()},
        {'key': 'sleep_window_end_hour', 'value': endTime.hour.toString()},
        {'key': 'sleep_window_end_minute', 'value': endTime.minute.toString()},
        {'key': 'adaptive_window_enabled', 'value': adaptiveEnabled ? '1' : '0'},
      ];

      for (final setting in settings) {
        await db.insert(
          'app_settings',
          {
            'key': setting['key'],
            'value': setting['value'],
            'value_type': 'int',
            'created_at': now,
            'updated_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      debugPrint('⚙️ تم تحديث إعدادات النافذة الزمنية');
    } catch (e) {
      debugPrint('❌ خطأ في تحديث النافذة الزمنية: $e');
      rethrow;
    }
  }

  /// الحصول على إعدادات النافذة الزمنية
  Future<Map<String, dynamic>> getSleepWindowSettings() async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        'app_settings',
        where: 'key IN (?, ?, ?, ?, ?)',
        whereArgs: [
          'sleep_window_start_hour',
          'sleep_window_start_minute',
          'sleep_window_end_hour',
          'sleep_window_end_minute',
          'adaptive_window_enabled',
        ],
      );

      final settings = <String, dynamic>{};
      for (final row in results) {
        final key = row['key'] as String;
        final value = int.tryParse(row['value'] as String) ?? 0;
        settings[key] = value;
      }

      return {
        'start_time': TimeOfDay(
          hour: settings['sleep_window_start_hour'] ?? 21,
          minute: settings['sleep_window_start_minute'] ?? 0,
        ),
        'end_time': TimeOfDay(
          hour: settings['sleep_window_end_hour'] ?? 7,
          minute: settings['sleep_window_end_minute'] ?? 0,
        ),
        'adaptive_enabled': (settings['adaptive_window_enabled'] ?? 1) == 1,
      };
    } catch (e) {
      debugPrint('❌ خطأ في جلب إعدادات النافذة: $e');
      return {
        'start_time': const TimeOfDay(hour: 21, minute: 0),
        'end_time': const TimeOfDay(hour: 7, minute: 0),
        'adaptive_enabled': true,
      };
    }
  }

  // ================================
  // Advanced Analysis - التحليل المتقدم
  // ================================

  /// تحليل أنماط النوم
  Future<Map<String, dynamic>> analyzeSleepPatterns({int days = 30}) async {
    try {
      final db = await _dbHelper.database;
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      final weekdayResults = await db.rawQuery('''
        SELECT 
          CASE CAST(strftime('%w', start_time / 1000, 'unixepoch', 'localtime') AS INTEGER)
            WHEN 0 THEN 'الأحد'
            WHEN 1 THEN 'الإثنين'
            WHEN 2 THEN 'الثلاثاء'
            WHEN 3 THEN 'الأربعاء'
            WHEN 4 THEN 'الخميس'
            WHEN 5 THEN 'الجمعة'
            WHEN 6 THEN 'السبت'
          END as day_name,
          AVG(CASE WHEN duration IS NOT NULL THEN duration ELSE 0 END) / 60.0 / 60.0 as avg_hours,
          AVG(CASE WHEN overall_sleep_quality IS NOT NULL THEN overall_sleep_quality ELSE 0 END) as avg_quality,
          COUNT(*) as sessions_count
        FROM sleep_sessions 
        WHERE start_time >= ? AND is_completed = 1 
        AND confidence IN (?, ?)
        GROUP BY strftime('%w', start_time / 1000, 'unixepoch', 'localtime')
        ORDER BY strftime('%w', start_time / 1000, 'unixepoch', 'localtime')
      ''', [
        cutoffDate.millisecondsSinceEpoch,
        SleepConfidence.confirmed.toDbString(),
        SleepConfidence.probable.toDbString(),
      ]);

      final timingResults = await db.rawQuery('''
        SELECT 
          CASE 
            WHEN CAST(strftime('%H', start_time / 1000, 'unixepoch', 'localtime') AS INTEGER) BETWEEN 20 AND 23 THEN 'مبكر'
            WHEN CAST(strftime('%H', start_time / 1000, 'unixepoch', 'localtime') AS INTEGER) BETWEEN 0 AND 2 THEN 'متوسط'
            ELSE 'متأخر'
          END as bedtime_category,
          COUNT(*) as count,
          AVG(CASE WHEN overall_sleep_quality IS NOT NULL THEN overall_sleep_quality ELSE 0 END) as avg_quality
        FROM sleep_sessions 
        WHERE start_time >= ? AND is_completed = 1 
        AND confidence IN (?, ?)
        GROUP BY bedtime_category
      ''', [
        cutoffDate.millisecondsSinceEpoch,
        SleepConfidence.confirmed.toDbString(),
        SleepConfidence.probable.toDbString(),
      ]);

      return {
        'weekday_patterns': weekdayResults.map((row) => {
          'day': row['day_name'] as String,
          'avg_hours': (row['avg_hours'] as num?)?.toDouble() ?? 0.0,
          'avg_quality': (row['avg_quality'] as num?)?.toDouble() ?? 0.0,
          'sessions_count': row['sessions_count'] ?? 0,
        }).toList(),
        'timing_patterns': timingResults.map((row) => {
          'category': row['bedtime_category'] as String,
          'count': row['count'] ?? 0,
          'avg_quality': (row['avg_quality'] as num?)?.toDouble() ?? 0.0,
        }).toList(),
      };
    } catch (e) {
      debugPrint('❌ خطأ في تحليل أنماط النوم: $e');
      return {};
    }
  }

  /// اقتراح وقت النوم المثالي
  Future<TimeOfDay?> suggestOptimalBedtime() async {
    try {
      final db = await _dbHelper.database;
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final results = await db.rawQuery('''
        SELECT 
          CAST(strftime('%H', start_time / 1000, 'unixepoch', 'localtime') AS INTEGER) as hour,
          CAST(strftime('%M', start_time / 1000, 'unixepoch', 'localtime') AS INTEGER) as minute,
          overall_sleep_quality
        FROM sleep_sessions
        WHERE start_time >= ? 
        AND is_completed = 1 
        AND confidence IN (?, ?)
        AND overall_sleep_quality IS NOT NULL
        AND overall_sleep_quality >= 7.0
        ORDER BY overall_sleep_quality DESC
        LIMIT 10
      ''', [
        thirtyDaysAgo.millisecondsSinceEpoch,
        SleepConfidence.confirmed.toDbString(),
        SleepConfidence.probable.toDbString(),
      ]);

      if (results.isEmpty) return null;

      final totalMinutes = results.fold<int>(0, (sum, row) {
        final hour = row['hour'] as int;
        final minute = row['minute'] as int;
        return sum + (hour * 60) + minute;
      });

      final avgMinutes = totalMinutes ~/ results.length;
      final optimalHour = (avgMinutes ~/ 60) % 24;
      final optimalMinute = avgMinutes % 60;

      return TimeOfDay(hour: optimalHour, minute: optimalMinute);
    } catch (e) {
      debugPrint('❌ خطأ في اقتراح وقت النوم المثالي: $e');
      return null;
    }
  }

  /// حساب نقاط اتساق النوم
  Future<double> calculateSleepConsistency({int days = 14}) async {
    try {
      final db = await _dbHelper.database;
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      final results = await db.query(
        'sleep_sessions',
        columns: ['duration'],
        where: '''
          start_time >= ? AND duration IS NOT NULL 
          AND confidence IN (?, ?)
        ''',
        whereArgs: [
          cutoffDate.millisecondsSinceEpoch,
          SleepConfidence.confirmed.toDbString(),
          SleepConfidence.probable.toDbString(),
        ],
      );

      if (results.length < 3) return 0.0;

      final sleepHours = results
          .map((r) => ((r['duration'] as int) / 3600.0))
          .where((h) => h > 0)
          .toList();

      if (sleepHours.isEmpty) return 0.0;

      final mean = sleepHours.reduce((a, b) => a + b) / sleepHours.length;
      final variance = sleepHours
          .map((h) => pow(h - mean, 2))
          .reduce((a, b) => a + b) / sleepHours.length;
      final stdDev = sqrt(variance);

      final consistencyScore = (1.0 - (stdDev / 3.0)).clamp(0.0, 1.0);

      return consistencyScore;
    } catch (e) {
      debugPrint('❌ خطأ في حساب اتساق النوم: $e');
      return 0.0;
    }
  }

  /// الحصول على بيانات الرسم البياني
  Future<List<Map<String, dynamic>>> getSleepChartData(int days) async {
    try {
      final db = await _dbHelper.database;
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      final results = await db.rawQuery('''
        SELECT 
          DATE(start_time / 1000, 'unixepoch', 'localtime') as date,
          AVG(CASE WHEN duration IS NOT NULL THEN duration ELSE 0 END) / 60.0 / 60.0 as sleep_hours,
          AVG(CASE WHEN overall_sleep_quality IS NOT NULL THEN overall_sleep_quality ELSE 0 END) as quality,
          TIME(AVG(start_time / 1000), 'unixepoch', 'localtime') as avg_bedtime,
          TIME(AVG(CASE WHEN end_time IS NOT NULL THEN end_time ELSE start_time + 28800000 END / 1000), 'unixepoch', 'localtime') as avg_wake_time
        FROM sleep_sessions 
        WHERE start_time >= ? AND is_completed = 1 
        AND confidence IN (?, ?)
        GROUP BY date
        ORDER BY date ASC
      ''', [
        cutoffDate.millisecondsSinceEpoch,
        SleepConfidence.confirmed.toDbString(),
        SleepConfidence.probable.toDbString(),
      ]);

      return results.map((row) => {
        'date': row['date'] as String,
        'sleep_hours': (row['sleep_hours'] as num?)?.toDouble() ?? 0.0,
        'quality': (row['quality'] as num?)?.toDouble() ?? 0.0,
        'avg_bedtime': row['avg_bedtime'] as String?,
        'avg_wake_time': row['avg_wake_time'] as String?,
      }).toList();
    } catch (e) {
      debugPrint('❌ خطأ في بيانات الرسم البياني: $e');
      return [];
    }
  }

  // ================================
  // Data Management - إدارة البيانات
  // ================================

  /// تنظيف البيانات القديمة
  Future<void> cleanupOldData({int daysToKeep = 90}) async {
    try {
      final db = await _dbHelper.database;
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final cutoffTimestamp = cutoffDate.millisecondsSinceEpoch;

      await db.transaction((txn) async {
        final envDeleted = await txn.delete(
          'environmental_data',
          where: 'created_at < ?',
          whereArgs: [cutoffTimestamp],
        );

        final sessionsDeleted = await txn.delete(
          'sleep_sessions',
          where: 'created_at < ? AND (user_confirmation_status = ? OR confidence = ?)',
          whereArgs: [
            cutoffTimestamp,
            'rejected',
            SleepConfidence.phoneLeft.toDbString(),
          ],
        );

        await txn.delete(
          'sleep_interruptions',
          where: 'sleep_session_id NOT IN (SELECT id FROM sleep_sessions)',
        );

        if (envDeleted > 0 || sessionsDeleted > 0) {
          debugPrint('🧹 تم تنظيف: $envDeleted بيانات بيئية، $sessionsDeleted جلسات');
        }
      });
    } catch (e) {
      debugPrint('❌ خطأ في تنظيف البيانات القديمة: $e');
    }
  }

  /// إحصائيات قاعدة البيانات
  Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      final db = await _dbHelper.database;

      final results = await Future.wait([
        db.rawQuery('SELECT COUNT(*) as count FROM sleep_sessions'),
        db.rawQuery('SELECT COUNT(*) as count FROM environmental_data'),
        db.rawQuery('SELECT COUNT(*) as count FROM sleep_interruptions'),
        db.rawQuery('SELECT COUNT(*) as count FROM sleep_goals WHERE is_active = 1'),
        db.rawQuery('SELECT AVG(overall_sleep_quality) as avg FROM sleep_sessions WHERE overall_sleep_quality IS NOT NULL'),
      ]);

      return {
        'total_sessions': results[0].first['count'] ?? 0,
        'total_environmental_records': results[1].first['count'] ?? 0,
        'total_interruptions': results[2].first['count'] ?? 0,
        'active_goals': results[3].first['count'] ?? 0,
        'average_quality_score': (results[4].first['avg'] as num?)?.toDouble() ?? 0.0,
        'database_health': 'healthy',
      };
    } catch (e) {
      debugPrint('❌ خطأ في إحصائيات قاعدة البيانات: $e');
      return {'database_health': 'error', 'error': e.toString()};
    }
  }

  /// تصدير بيانات النوم
  Future<Map<String, dynamic>?> exportSleepData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 90));
      final end = endDate ?? DateTime.now();

      final db = await _dbHelper.database;

      final sessions = await db.query(
        'sleep_sessions',
        where: 'start_time >= ? AND start_time <= ?',
        whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
        orderBy: 'start_time DESC',
      );

      final allData = <String, dynamic>{};

      for (final session in sessions) {
        final sessionId = session['id'] as int;

        final interruptions = await db.query(
          'sleep_interruptions',
          where: 'sleep_session_id = ?',
          whereArgs: [sessionId],
        );

        final envData = await db.query(
          'environmental_data',
          where: 'sleep_session_id = ?',
          whereArgs: [sessionId],
        );

        allData[sessionId.toString()] = {
          'interruptions': interruptions,
          'environmental_data': envData,
        };
      }

      return {
        'export_info': {
          'date': DateTime.now().toIso8601String(),
          'period_start': start.toIso8601String(),
          'period_end': end.toIso8601String(),
          'total_sessions': sessions.length,
          'version': '2.0.0', // ✅ تحديث النسخة
        },
        'sessions': sessions,
        'related_data': allData,
        'statistics': await getMonthlySleepStats(),
        'confidence_stats': await getConfidenceStatistics(days: 30),
      };
    } catch (e) {
      debugPrint('❌ خطأ في تصدير بيانات النوم: $e');
      return null;
    }
  }

  // ================================
  // 🆕 Active Session Recovery - استرجاع الجلسة النشطة
  // ================================

  /// حفظ ID الجلسة النشطة في SharedPreferences
  Future<void> saveActiveSessionId(int sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('active_sleep_session_id', sessionId);
      debugPrint('✅ تم حفظ ID الجلسة النشطة: $sessionId');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ ID الجلسة النشطة: $e');
    }
  }

  /// حذف ID الجلسة النشطة من SharedPreferences
  Future<void> clearActiveSessionId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_sleep_session_id');
      debugPrint('✅ تم حذف ID الجلسة النشطة');
    } catch (e) {
      debugPrint('❌ خطأ في حذف ID الجلسة النشطة: $e');
    }
  }

  /// جلب ID الجلسة النشطة من SharedPreferences
  Future<int?> getActiveSessionId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt('active_sleep_session_id');
      debugPrint('🔍 ID الجلسة النشطة المحفوظ: $id');
      return id;
    } catch (e) {
      debugPrint('❌ خطأ في جلب ID الجلسة النشطة: $e');
      return null;
    }
  }

  /// استرجاع الجلسة النشطة من DB (عند إعادة تشغيل التطبيق)
  Future<SleepSession?> recoverActiveSession() async {
    try {
      final sessionId = await getActiveSessionId();
      if (sessionId == null) {
        debugPrint('ℹ️ لا توجد جلسة نشطة محفوظة');
        return null;
      }

      final db = await _dbHelper.database;
      final results = await db.query(
        'sleep_sessions',
        where: 'id = ? AND is_completed = 0',
        whereArgs: [sessionId],
      );

      if (results.isEmpty) {
        debugPrint('⚠️ الجلسة النشطة المحفوظة غير موجودة في DB');
        await clearActiveSessionId();
        return null;
      }

      final session = SleepSession.fromMap(results.first);
      debugPrint('✅ تم استرجاع الجلسة النشطة: ID=${session.id}');
      debugPrint('   - البداية: ${session.startTime}');

      final elapsed = DateTime.now().difference(session.startTime);
      debugPrint('   - المدة الحالية: ${elapsed.inHours}h ${elapsed.inMinutes % 60}m');

      return session;
    } catch (e, stack) {
      debugPrint('❌ خطأ في استرجاع الجلسة النشطة: $e');
      debugPrint('Stack: $stack');
      return null;
    }
  }

  // ================================
  // Helper Methods - دوال مساعدة
  // ================================

  Future<double> _calculateGoalAchievementRate(int days) async {
    try {
      final goal = await getActiveSleepGoal();
      if (goal == null) return 0.0;

      final targetHours = (goal['recommended_hours'] as num?)?.toDouble() ?? 8.0;
      final targetSeconds = (targetHours * 3600).toInt();

      final db = await _dbHelper.database;
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      final results = await db.rawQuery('''
        SELECT 
          COUNT(*) as total,
          SUM(CASE WHEN duration >= ? THEN 1 ELSE 0 END) as achieved
        FROM sleep_sessions
        WHERE start_time >= ? 
        AND is_completed = 1 
        AND confidence IN (?, ?)
      ''', [
        targetSeconds,
        cutoffDate.millisecondsSinceEpoch,
        SleepConfidence.confirmed.toDbString(),
        SleepConfidence.probable.toDbString(),
      ]);

      final result = results.first;
      final total = result['total'] as int;
      final achieved = result['achieved'] as int;

      return total > 0 ? (achieved / total) : 0.0;
    } catch (e) {
      debugPrint('❌ خطأ في حساب نسبة تحقيق الهدف: $e');
      return 0.0;
    }
  }

  String _getValueType(dynamic value) {
    if (value is String) return 'string';
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is bool) return 'bool';
    return 'string';
  }

  dynamic _parseSettingValue(String value, String type) {
    switch (type) {
      case 'int':
        return int.tryParse(value) ?? 0;
      case 'double':
        return double.tryParse(value) ?? 0.0;
      case 'bool':
        return value == 'true' || value == '1';
      default:
        return value;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🔄 Sync Methods
  // ═══════════════════════════════════════════════════════════

  /// جلب جلسات النوم غير المرفوعة
  Future<List<SleepSession>> getUnsyncedSessions() async {
    try {
      final db = await _dbHelper.database;

      final maps = await db.query(
        'sleep_sessions',
        where: 'synced = ? AND is_completed = ?',
        whereArgs: [0, 1], // فقط الجلسات المكتملة
        orderBy: 'start_time DESC',
      );

      debugPrint('📦 [SleepRepo] وجدنا ${maps.length} جلسة نوم غير مرفوعة');

      return maps.map((map) => SleepSession.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ [SleepRepo] خطأ في جلب جلسات النوم غير المرفوعة: $e');
      return [];
    }
  }

  /// تحديد جلسة نوم كمرفوعة
  Future<bool> markAsSynced(int sessionId) async {
    try {
      final db = await _dbHelper.database;

      final count = await db.update(
        'sleep_sessions',
        {
          'synced': 1,
          'last_sync_time': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [sessionId],
      );

      debugPrint('✅ [SleepRepo] تم تحديد جلسة النوم $sessionId كمرفوعة');
      return count > 0;
    } catch (e) {
      debugPrint('❌ [SleepRepo] خطأ في تحديد جلسة النوم كمرفوعة: $e');
      return false;
    }
  }

}