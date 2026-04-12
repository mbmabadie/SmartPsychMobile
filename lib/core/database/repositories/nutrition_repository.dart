// lib/core/database/repositories/simplified_nutrition_repository.dart
import 'package:flutter/foundation.dart';
import '../database_helper.dart';
import '../models/simple_meal.dart';

/// مستودع التغذية المبسط
class NutritionRepository {
  static final NutritionRepository _instance = NutritionRepository._internal();

  factory NutritionRepository() => _instance;

  NutritionRepository._internal();

  static NutritionRepository get instance => _instance;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// إنشاء جدول الوجبات المبسط
  Future<void> _createSimpleMealsTableIfNotExists() async {
    try {
      final db = await _dbHelper.database;

      await db.execute('''
        CREATE TABLE IF NOT EXISTS simple_meals (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          meal_type TEXT CHECK(meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')) NOT NULL,
          meal_time INTEGER NOT NULL,
          date TEXT NOT NULL,
          calories REAL,
          notes TEXT,
          created_at INTEGER NOT NULL
        )
      ''');

      // إنشاء فهرس للتاريخ
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_simple_meals_date 
        ON simple_meals(date)
      ''');

      // إنشاء فهرس لنوع الوجبة
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_simple_meals_type 
        ON simple_meals(meal_type)
      ''');

      // إنشاء فهرس للتاريخ ونوع الوجبة
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_simple_meals_date_type 
        ON simple_meals(date, meal_type)
      ''');

      debugPrint('✅ تم إنشاء جدول الوجبات المبسط');
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء جدول الوجبات: $e');
    }
  }

  /// إضافة وجبة
  Future<int?> addMeal(SimpleMeal meal) async {
    try {
      await _createSimpleMealsTableIfNotExists();
      final db = await _dbHelper.database;

      final id = await db.insert('simple_meals', meal.toMap());
      debugPrint('✅ تم إضافة وجبة: ${meal.name} (${meal.mealTypeDisplayName})');
      return id;
    } catch (e) {
      debugPrint('❌ خطأ في إضافة الوجبة: $e');
      return null;
    }
  }

  /// الحصول على وجبات اليوم
  Future<List<SimpleMeal>> getMealsForDate(String date) async {
    try {
      await _createSimpleMealsTableIfNotExists();
      final db = await _dbHelper.database;

      final maps = await db.query(
        'simple_meals',
        where: 'date = ?',
        whereArgs: [date],
        orderBy: 'meal_time ASC',
      );

      return maps.map((map) => SimpleMeal.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ خطأ في قراءة وجبات اليوم: $e');
      return [];
    }
  }

  /// الحصول على وجبات فترة
  Future<List<SimpleMeal>> getMealsForDateRange(String startDate,
      String endDate) async {
    try {
      await _createSimpleMealsTableIfNotExists();
      final db = await _dbHelper.database;

      final maps = await db.query(
        'simple_meals',
        where: 'date >= ? AND date <= ?',
        whereArgs: [startDate, endDate],
        orderBy: 'date DESC, meal_time ASC',
      );

      return maps.map((map) => SimpleMeal.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ خطأ في قراءة وجبات الفترة: $e');
      return [];
    }
  }

  /// تحديث وجبة
  Future<bool> updateMeal(SimpleMeal meal) async {
    try {
      if (meal.id == null) return false;

      final db = await _dbHelper.database;

      final count = await db.update(
        'simple_meals',
        meal.toMap(),
        where: 'id = ?',
        whereArgs: [meal.id],
      );

      if (count > 0) {
        debugPrint('✅ تم تحديث وجبة: ${meal.name}');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ خطأ في تحديث الوجبة: $e');
      return false;
    }
  }

  /// حذف وجبة
  Future<bool> deleteMeal(int mealId) async {
    try {
      final db = await _dbHelper.database;

      final count = await db.delete(
        'simple_meals',
        where: 'id = ?',
        whereArgs: [mealId],
      );

      if (count > 0) {
        debugPrint('✅ تم حذف الوجبة');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ خطأ في حذف الوجبة: $e');
      return false;
    }
  }

  /// الحصول على وجبة بالمعرف
  Future<SimpleMeal?> getMealById(int mealId) async {
    try {
      final db = await _dbHelper.database;

      final maps = await db.query(
        'simple_meals',
        where: 'id = ?',
        whereArgs: [mealId],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return SimpleMeal.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      debugPrint('❌ خطأ في قراءة الوجبة: $e');
      return null;
    }
  }

  /// الحصول على ملخص الوجبات اليومي
  Future<DailyMealsSummary> getDailyMealsSummary(String date) async {
    try {
      final meals = await getMealsForDate(date);
      return DailyMealsSummary(date: date, meals: meals);
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء ملخص الوجبات: $e');
      return DailyMealsSummary(date: date, meals: []);
    }
  }

  /// إحصائيات الوجبات
  Future<Map<String, dynamic>> getMealStatistics(String startDate,
      String endDate) async {
    try {
      await _createSimpleMealsTableIfNotExists();
      final db = await _dbHelper.database;

      final result = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_meals,
          COUNT(CASE WHEN calories IS NOT NULL THEN 1 END) as meals_with_calories,
          AVG(CASE WHEN calories IS NOT NULL THEN calories END) as avg_calories,
          SUM(CASE WHEN calories IS NOT NULL THEN calories END) as total_calories,
          meal_type,
          COUNT(*) as type_count
        FROM simple_meals 
        WHERE date >= ? AND date <= ?
        GROUP BY meal_type
      ''', [startDate, endDate]);

      final overallStats = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_meals,
          COUNT(CASE WHEN calories IS NOT NULL THEN 1 END) as meals_with_calories,
          AVG(CASE WHEN calories IS NOT NULL THEN calories END) as avg_calories,
          SUM(CASE WHEN calories IS NOT NULL THEN calories END) as total_calories,
          COUNT(DISTINCT date) as unique_days
        FROM simple_meals 
        WHERE date >= ? AND date <= ?
      ''', [startDate, endDate]);

      final overall = overallStats.isNotEmpty ? overallStats.first : {};

      return {
        'total_meals': overall['total_meals'] ?? 0,
        'meals_with_calories': overall['meals_with_calories'] ?? 0,
        'avg_calories': (overall['avg_calories'] as num?)?.toDouble() ?? 0.0,
        'total_calories': (overall['total_calories'] as num?)?.toDouble() ??
            0.0,
        'unique_days': overall['unique_days'] ?? 0,
        'types_breakdown': result,
        'period_start': startDate,
        'period_end': endDate,
      };
    } catch (e) {
      debugPrint('❌ خطأ في إحصائيات الوجبات: $e');
      return {};
    }
  }

  /// الحصول على عدد الوجبات اليومي
  Future<Map<String, int>> getDailyMealCount(String date) async {
    try {
      final meals = await getMealsForDate(date);

      final counts = <String, int>{
        'breakfast': 0,
        'lunch': 0,
        'dinner': 0,
        'snack': 0,
        'total': meals.length,
      };

      for (final meal in meals) {
        counts[meal.mealType] = (counts[meal.mealType] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      debugPrint('❌ خطأ في حساب عدد الوجبات: $e');
      return {'total': 0};
    }
  }

  /// إجمالي السعرات لليوم
  Future<double> getTotalCaloriesForDate(String date) async {
    try {
      final meals = await getMealsForDate(date);

      double total = 0.0;
      for (final meal in meals) {
        if (meal.calories != null) {
          total += meal.calories!;
        }
      }

      return total;
    } catch (e) {
      debugPrint('❌ خطأ في حساب السعرات: $e');
      return 0.0;
    }
  }

  /// أوقات الوجبات المعتادة
  Future<Map<String, String>> getTypicalMealTimes() async {
    try {
      final db = await _dbHelper.database;

      // الحصول على آخر 30 يوم
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 30));
      final startDateStr = '${startDate.year}-${startDate.month.toString()
          .padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      final endDateStr = '${endDate.year}-${endDate.month.toString().padLeft(
          2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

      final result = await db.rawQuery('''
        SELECT 
          meal_type,
          AVG(
            (meal_time - (meal_time / 86400000) * 86400000) / 3600000
          ) as avg_hour
        FROM simple_meals 
        WHERE date >= ? AND date <= ?
        GROUP BY meal_type
      ''', [startDateStr, endDateStr]);

      final typicalTimes = <String, String>{};

      for (final row in result) {
        final mealType = row['meal_type'] as String;
        final avgHour = (row['avg_hour'] as num).round();
        final displayTime = '${avgHour}:00';
        typicalTimes[mealType] = displayTime;
      }

      return typicalTimes;
    } catch (e) {
      debugPrint('❌ خطأ في حساب أوقات الوجبات المعتادة: $e');
      return {};
    }
  }

  /// الحصول على آخر الوجبات
  Future<List<SimpleMeal>> getRecentMeals({int limit = 10}) async {
    try {
      await _createSimpleMealsTableIfNotExists();
      final db = await _dbHelper.database;

      final maps = await db.query(
        'simple_meals',
        orderBy: 'meal_time DESC',
        limit: limit,
      );

      return maps.map((map) => SimpleMeal.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ خطأ في قراءة آخر الوجبات: $e');
      return [];
    }
  }

  /// البحث في الوجبات
  Future<List<SimpleMeal>> searchMeals(String query,
      {String? startDate, String? endDate}) async {
    try {
      await _createSimpleMealsTableIfNotExists();
      final db = await _dbHelper.database;

      String whereClause = 'name LIKE ?';
      List<dynamic> whereArgs = ['%$query%'];

      if (startDate != null && endDate != null) {
        whereClause += ' AND date >= ? AND date <= ?';
        whereArgs.addAll([startDate, endDate]);
      }

      final maps = await db.query(
        'simple_meals',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'meal_time DESC',
        limit: 50,
      );

      return maps.map((map) => SimpleMeal.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ خطأ في البحث في الوجبات: $e');
      return [];
    }
  }

  /// الحصول على الوجبات الشائعة
  Future<List<Map<String, dynamic>>> getPopularMeals({int limit = 10}) async {
    try {
      final db = await _dbHelper.database;

      final maps = await db.rawQuery('''
        SELECT 
          name,
          COUNT(*) as frequency,
          AVG(CASE WHEN calories IS NOT NULL THEN calories END) as avg_calories,
          meal_type,
          MAX(created_at) as last_eaten
        FROM simple_meals 
        GROUP BY LOWER(name), meal_type
        ORDER BY frequency DESC
        LIMIT ?
      ''', [limit]);

      return maps.map((map) =>
      {
        'name': map['name'],
        'frequency': map['frequency'],
        'avg_calories': (map['avg_calories'] as num?)?.toDouble(),
        'meal_type': map['meal_type'],
        'last_eaten': map['last_eaten'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['last_eaten'] as int)
            : null,
      }).toList();
    } catch (e) {
      debugPrint('❌ خطأ في قراءة الوجبات الشائعة: $e');
      return [];
    }
  }

  /// عدد الوجبات حسب الشهر
  Future<Map<String, int>> getMealsCountByMonth({int monthsBack = 12}) async {
    try {
      final db = await _dbHelper.database;

      final endDate = DateTime.now();
      final startDate = DateTime(endDate.year, endDate.month - monthsBack, 1);
      final startDateStr = '${startDate.year}-${startDate.month.toString()
          .padLeft(2, '0')}-01';

      final maps = await db.rawQuery('''
        SELECT 
          substr(date, 1, 7) as month,
          COUNT(*) as meal_count
        FROM simple_meals 
        WHERE date >= ?
        GROUP BY substr(date, 1, 7)
        ORDER BY month
      ''', [startDateStr]);

      final result = <String, int>{};
      for (final map in maps) {
        result[map['month'] as String] = map['meal_count'] as int;
      }

      return result;
    } catch (e) {
      debugPrint('❌ خطأ في إحصائيات الوجبات الشهرية: $e');
      return {};
    }
  }

  /// تنظيف البيانات القديمة
  Future<int> cleanOldMeals({int daysToKeep = 365}) async {
    try {
      final db = await _dbHelper.database;
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final cutoffDateStr = '${cutoffDate.year}-${cutoffDate.month.toString()
          .padLeft(2, '0')}-${cutoffDate.day.toString().padLeft(2, '0')}';

      final deletedCount = await db.delete(
        'simple_meals',
        where: 'date < ?',
        whereArgs: [cutoffDateStr],
      );

      if (deletedCount > 0) {
        debugPrint('🗑️ تم حذف $deletedCount وجبة قديمة');
      }

      return deletedCount;
    } catch (e) {
      debugPrint('❌ خطأ في تنظيف الوجبات القديمة: $e');
      return 0;
    }
  }

  /// إحصائيات قاعدة البيانات
  Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      final db = await _dbHelper.database;

      final totalMeals = await db.rawQuery(
          'SELECT COUNT(*) as count FROM simple_meals');
      final mealsWithCalories = await db.rawQuery(
          'SELECT COUNT(*) as count FROM simple_meals WHERE calories IS NOT NULL');
      final firstMeal = await db.rawQuery(
          'SELECT MIN(date) as first_date FROM simple_meals');
      final lastMeal = await db.rawQuery(
          'SELECT MAX(date) as last_date FROM simple_meals');

      return {
        'total_meals': totalMeals.first['count'],
        'meals_with_calories': mealsWithCalories.first['count'],
        'first_meal_date': firstMeal.first['first_date'],
        'last_meal_date': lastMeal.first['last_date'],
        'table_exists': await _dbHelper.tableExists('simple_meals'),
      };
    } catch (e) {
      debugPrint('❌ خطأ في إحصائيات قاعدة البيانات: $e');
      return {};
    }
  }

  /// إنشاء وجبة سريعة بناءً على الوقت الحالي
  SimpleMeal createQuickMeal(String name, {double? calories, String? notes}) {
    final now = DateTime.now();
    final mealType = MealType.getAppropriateType(now);
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now
        .day.toString().padLeft(2, '0')}';

    return SimpleMeal(
      name: name,
      mealType: mealType.value,
      mealTime: now,
      date: dateStr,
      calories: calories,
      notes: notes,
      createdAt: now,
    );
  }

  /// إضافة وجبة سريعة
  Future<int?> addQuickMeal(String name,
      {double? calories, String? notes}) async {
    final meal = createQuickMeal(name, calories: calories, notes: notes);
    return await addMeal(meal);
  }
}