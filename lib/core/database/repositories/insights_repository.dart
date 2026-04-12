// lib/core/database/repositories/insights_repository.dart - إصلاح كامل

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../services/insights_service.dart';
import '../database_helper.dart';
import '../models/common_models.dart';
import 'base_repository.dart';

class InsightsRepository extends BaseRepository {
  @override
  String get tableName => 'insights';

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// إضافة رؤية جديدة - مع إنشاء ID تلقائي
  Future<int> insertInsight(Insight insight) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      // تحويل الرؤية إلى Map مع إضافة ID
      final insightMap = insight.toMap();

      // إضافة metadata كـ JSON string إذا كانت موجودة
      if (insight.metadata != null) {
        insightMap['related_data'] = insight.metadata.toString();
      }

      return await db.insert(tableName, insightMap);
    });
  }

  /// الحصول على الرؤى لتاريخ معين
  Future<List<Insight>> getInsightsForDate(String date) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final maps = await db.query(
        tableName,
        where: 'date = ?',
        whereArgs: [date],
        orderBy: 'confidence_score DESC, created_at DESC',
      );

      return maps.map((map) => Insight.fromMap(map)).toList();
    });
  }

  /// الحصول على الرؤى غير المعروضة
  Future<List<Insight>> getUnshownInsights({int limit = 5}) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final maps = await db.query(
        tableName,
        where: 'is_shown = ?',
        whereArgs: [0],
        orderBy: 'confidence_score DESC, created_at DESC',
        limit: limit,
      );

      return maps.map((map) => Insight.fromMap(map)).toList();
    });
  }

  /// حذف رؤية - باستخدام معرف فريد مركب
  Future<bool> deleteInsight(String uniqueId) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      // البحث عن الرؤية باستخدام التاريخ والفئة والوقت
      final parts = uniqueId.split('_');
      if (parts.length >= 3) {
        final date = parts[0];
        final category = parts[1];
        final timestamp = parts.last;

        final count = await db.delete(
          tableName,
          where: 'date = ? AND category = ? AND created_at = ?',
          whereArgs: [date, category, timestamp],
        );
        return count > 0;
      }

      return false;
    });
  }

  /// ✅ تحديد رؤية كمعروضة - مع دعم المعرف الفريد المركب
  Future<bool> markInsightAsShown(String uniqueId) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      // البحث عن الرؤية باستخدام المعرف المركب
      final parts = uniqueId.split('_');
      if (parts.length >= 3) {
        final date = parts[0];
        final category = parts[1];
        final timestamp = parts.last;

        final count = await db.update(
          tableName,
          {'is_shown': 1},
          where: 'date = ? AND category = ? AND created_at = ?',
          whereArgs: [date, category, timestamp],
        );

        return count > 0;
      }

      return false;
    });
  }

  /// ✅ تحديد رؤية كتم التفاعل معها
  Future<bool> markInsightAsActedUpon(String uniqueId) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      // التأكد من وجود العمود
      await _ensureActedUponColumn(db);

      // البحث عن الرؤية باستخدام المعرف المركب
      final parts = uniqueId.split('_');
      if (parts.length >= 3) {
        final date = parts[0];
        final category = parts[1];
        final timestamp = parts.last;

        final count = await db.update(
          tableName,
          {'is_acted_upon': 1},
          where: 'date = ? AND category = ? AND created_at = ?',
          whereArgs: [date, category, timestamp],
        );

        return count > 0;
      }

      return false;
    });
  }

  /// ✅ التأكد من وجود عمود is_acted_upon
  Future<void> _ensureActedUponColumn(Database db) async {
    try {
      // محاولة إضافة العمود إذا لم يكن موجود
      await db.execute('ALTER TABLE $tableName ADD COLUMN is_acted_upon INTEGER DEFAULT 0');
      debugPrint('✅ تم إضافة عمود is_acted_upon');
    } catch (e) {
      // تجاهل الخطأ إذا كان العمود موجود بالفعل
      if (!e.toString().contains('duplicate column name')) {
        debugPrint('❌ خطأ في إضافة عمود is_acted_upon: $e');
      }
    }
  }

  /// الحصول على الرؤى بين تاريخين
  Future<List<Insight>> getInsightsBetweenDates(String startDate, String endDate) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final maps = await db.query(
        tableName,
        where: 'date BETWEEN ? AND ?',
        whereArgs: [startDate, endDate],
        orderBy: 'date DESC, confidence_score DESC',
      );

      return maps.map((map) => Insight.fromMap(map)).toList();
    });
  }

  /// الحصول على الرؤى حسب الفئة
  Future<List<Insight>> getInsightsByCategory(String category, {int? limit}) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final maps = await db.query(
        tableName,
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'created_at DESC',
        limit: limit,
      );

      return maps.map((map) => Insight.fromMap(map)).toList();
    });
  }

  /// إحصائيات الرؤى
  Future<Map<String, dynamic>> getInsightsStatistics() async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      // التأكد من وجود عمود is_acted_upon
      await _ensureActedUponColumn(db);

      final result = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_insights,
          AVG(confidence_score) as avg_confidence,
          SUM(CASE WHEN insight_type = 'positive' THEN 1 ELSE 0 END) as positive_count,
          SUM(CASE WHEN insight_type = 'negative' THEN 1 ELSE 0 END) as negative_count,
          SUM(CASE WHEN insight_type = 'neutral' THEN 1 ELSE 0 END) as neutral_count,
          SUM(CASE WHEN is_shown = 1 THEN 1 ELSE 0 END) as shown_count,
          SUM(CASE WHEN is_acted_upon = 1 THEN 1 ELSE 0 END) as acted_upon_count
        FROM $tableName
      ''');

      final stats = result.first;
      return {
        'total_insights': stats['total_insights'] ?? 0,
        'avg_confidence': stats['avg_confidence'] ?? 0.0,
        'positive_count': stats['positive_count'] ?? 0,
        'negative_count': stats['negative_count'] ?? 0,
        'neutral_count': stats['neutral_count'] ?? 0,
        'shown_count': stats['shown_count'] ?? 0,
        'acted_upon_count': stats['acted_upon_count'] ?? 0,
      };
    });
  }

  /// الحصول على أحدث الرؤى
  Future<List<Insight>> getLatestInsights({int limit = 10}) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final maps = await db.query(
        tableName,
        orderBy: 'created_at DESC',
        limit: limit,
      );

      return maps.map((map) => Insight.fromMap(map)).toList();
    });
  }

  /// البحث في الرؤى
  Future<List<Insight>> searchInsights(String query) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final maps = await db.query(
        tableName,
        where: 'title LIKE ? OR message LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'confidence_score DESC, created_at DESC',
      );

      return maps.map((map) => Insight.fromMap(map)).toList();
    });
  }

  /// تحديث رؤية - باستخدام المعرف المركب
  Future<bool> updateInsight(Insight insight, String uniqueId) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      // البحث عن الرؤية باستخدام المعرف المركب
      final parts = uniqueId.split('_');
      if (parts.length >= 3) {
        final date = parts[0];
        final category = parts[1];
        final timestamp = parts.last;

        final insightMap = insight.toMap();
        if (insight.metadata != null) {
          insightMap['related_data'] = insight.metadata.toString();
        }

        final count = await db.update(
          tableName,
          insightMap,
          where: 'date = ? AND category = ? AND created_at = ?',
          whereArgs: [date, category, timestamp],
        );

        return count > 0;
      }

      return false;
    });
  }

  /// ✅ الحصول على رؤية واحدة بالمعرف المركب
  Future<Insight?> getInsightByUniqueId(String uniqueId) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      // البحث عن الرؤية باستخدام المعرف المركب
      final parts = uniqueId.split('_');
      if (parts.length >= 3) {
        final date = parts[0];
        final category = parts[1];
        final timestamp = parts.last;

        final maps = await db.query(
          tableName,
          where: 'date = ? AND category = ? AND created_at = ?',
          whereArgs: [date, category, timestamp],
          limit: 1,
        );

        if (maps.isNotEmpty) {
          return Insight.fromMap(maps.first);
        }
      }

      return null;
    });
  }

  /// ✅ الحصول على الرؤى المتفاعل معها
  Future<List<Insight>> getActedUponInsights({int limit = 10}) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      // التأكد من وجود العمود
      await _ensureActedUponColumn(db);

      final maps = await db.query(
        tableName,
        where: 'is_acted_upon = ?',
        whereArgs: [1],
        orderBy: 'created_at DESC',
        limit: limit,
      );

      return maps.map((map) => Insight.fromMap(map)).toList();
    });
  }

  /// ✅ الحصول على الرؤى غير المتفاعل معها
  Future<List<Insight>> getPendingInsights({int limit = 10}) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      // التأكد من وجود العمود
      await _ensureActedUponColumn(db);

      final maps = await db.query(
        tableName,
        where: 'is_shown = ? AND (is_acted_upon = ? OR is_acted_upon IS NULL)',
        whereArgs: [1, 0],
        orderBy: 'confidence_score DESC, created_at DESC',
        limit: limit,
      );

      return maps.map((map) => Insight.fromMap(map)).toList();
    });
  }

  /// حذف الرؤى القديمة
  Future<int> deleteOldInsights({int daysToKeep = 30}) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final cutoffDateStr = '${cutoffDate.year}-${cutoffDate.month.toString().padLeft(2, '0')}-${cutoffDate.day.toString().padLeft(2, '0')}';

      final count = await db.delete(
        tableName,
        where: 'date < ?',
        whereArgs: [cutoffDateStr],
      );

      debugPrint('🗑️ تم حذف $count رؤية قديمة');
      return count;
    });
  }

  /// ✅ إصلاح الجدول وإضافة الأعمدة المفقودة
  Future<void> fixInsightsTable() async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      // إضافة عمود is_acted_upon إذا لم يكن موجود
      await _ensureActedUponColumn(db);

      debugPrint('✅ تم إصلاح جدول الرؤى');
    });
  }

  /// ✅ إنشاء معرف فريد للرؤية - دالة مساعدة
  String createUniqueId(Insight insight) {
    return '${insight.date}_${insight.category}_${insight.subcategory ?? 'general'}_${insight.createdAt.millisecondsSinceEpoch}';
  }

  /// ✅ حفظ رؤية مع معرف فريد
  Future<String> insertInsightWithUniqueId(Insight insight) async {
    await insertInsight(insight);
    return createUniqueId(insight);
  }

  /// ✅ الحصول على جميع الرؤى مع معرفاتها الفريدة
  Future<Map<String, Insight>> getAllInsightsWithIds() async {
    return executeWithErrorHandling(() async {
      final insights = await getLatestInsights(limit: 1000); // جلب عدد كبير
      final Map<String, Insight> result = {};

      for (final insight in insights) {
        final uniqueId = createUniqueId(insight);
        result[uniqueId] = insight;
      }

      return result;
    });
  }
}

/// مستودع قاعدة مجرد للمستودعات
abstract class BaseRepository {
  String get tableName;

  /// تنفيذ عملية مع معالجة الأخطاء
  Future<T> executeWithErrorHandling<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      debugPrint('❌ خطأ في مستودع $tableName: $e');
      debugPrint('📍 Stack trace: $stackTrace');

      // إعادة رمي الخطأ مع معلومات إضافية
      throw DatabaseException(
        'خطأ في قاعدة البيانات - جدول $tableName: ${e.toString()}',
      );
    }
  }

  /// فحص وجود الجدول
  Future<bool> tableExists() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      return await dbHelper.tableExists(tableName);
    } catch (e) {
      debugPrint('❌ خطأ في فحص وجود الجدول $tableName: $e');
      return false;
    }
  }

  /// إنشاء الجدول إذا لم يكن موجوداً
  Future<void> ensureTableExists() async {
    final exists = await tableExists();
    if (!exists) {
      debugPrint('⚠️ الجدول $tableName غير موجود، سيتم إنشاؤه');
      await _createTable();
    }
  }

  /// إنشاء الجدول - يجب تنفيذها في كل مستودع
  Future<void> _createTable() async {
    final dbHelper = DatabaseHelper.instance;

    switch (tableName) {
      case 'insights':
        await dbHelper.createTableIfNotExists(tableName, '''
          CREATE TABLE insights (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT NOT NULL,
            subcategory TEXT,
            insight_type TEXT CHECK(insight_type IN ('positive', 'negative', 'neutral')) NOT NULL,
            title TEXT NOT NULL,
            message TEXT NOT NULL,
            related_data TEXT,
            confidence_score REAL DEFAULT 0.5,
            date TEXT NOT NULL,
            is_shown INTEGER DEFAULT 0,
            is_acted_upon INTEGER DEFAULT 0,
            created_at INTEGER NOT NULL
          )
        ''');
        break;

      default:
        debugPrint('⚠️ لا يوجد تعريف لإنشاء الجدول: $tableName');
    }
  }
}

/// استثناء قاعدة البيانات المخصص
class DatabaseException implements Exception {
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  DatabaseException(this.message, {this.originalError, this.stackTrace});

  @override
  String toString() => 'DatabaseException: $message';
}