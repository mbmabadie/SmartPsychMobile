// lib/core/database/repositories/location_repository.dart
import 'package:flutter/foundation.dart';
import '../database_helper.dart';
import '../models/activity_models.dart';

class LocationRepository {
  static final LocationRepository _instance = LocationRepository._internal();
  factory LocationRepository() => _instance;
  LocationRepository._internal();

  static LocationRepository get instance => _instance;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// إضافة زيارة موقع
  Future<int?> insertLocationVisit(LocationVisit visit) async {
    try {
      final db = await _dbHelper.database;

      final id = await db.insert('location_visits', visit.toMap());
      debugPrint('✅ تم حفظ زيارة موقع: ${visit.placeName ?? "مكان غير معروف"}');
      return id;
    } catch (e) {
      debugPrint('❌ خطأ في حفظ زيارة الموقع: $e');
      return null;
    }
  }

  /// تحديث زيارة موقع
  Future<bool> updateLocationVisit(LocationVisit visit) async {
    try {
      if (visit.id == null) return false;

      final db = await _dbHelper.database;

      final count = await db.update(
        'location_visits',
        visit.toMap(),
        where: 'id = ?',
        whereArgs: [visit.id],
      );

      if (count > 0) {
        debugPrint('✅ تم تحديث زيارة الموقع: ${visit.placeName}');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ خطأ في تحديث زيارة الموقع: $e');
      return false;
    }
  }

  /// الحصول على زيارات تاريخ معين
  Future<List<LocationVisit>> getLocationVisitsForDate(String date) async {
    try {
      final db = await _dbHelper.database;

      // تحويل التاريخ إلى نطاق زمني
      final startTimestamp = DateTime.parse('${date}T00:00:00').millisecondsSinceEpoch;
      final endTimestamp = DateTime.parse('${date}T23:59:59').millisecondsSinceEpoch;

      final maps = await db.query(
        'location_visits',
        where: 'arrival_time >= ? AND arrival_time <= ?',
        whereArgs: [startTimestamp, endTimestamp],
        orderBy: 'arrival_time ASC',
      );

      return maps.map((map) => LocationVisit.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ خطأ في قراءة زيارات التاريخ: $e');
      return [];
    }
  }

  /// الحصول على زيارات فترة زمنية
  Future<List<LocationVisit>> getLocationVisitsForDateRange(String startDate, String endDate) async {
    try {
      final db = await _dbHelper.database;

      final startTimestamp = DateTime.parse('${startDate}T00:00:00').millisecondsSinceEpoch;
      final endTimestamp = DateTime.parse('${endDate}T23:59:59').millisecondsSinceEpoch;

      final maps = await db.query(
        'location_visits',
        where: 'arrival_time >= ? AND arrival_time <= ?',
        whereArgs: [startTimestamp, endTimestamp],
        orderBy: 'arrival_time DESC',
      );

      return maps.map((map) => LocationVisit.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ خطأ في قراءة زيارات الفترة: $e');
      return [];
    }
  }

  /// البحث عن موقع مشابه
  Future<LocationVisit?> findSimilarLocation(double latitude, double longitude, {double radiusMeters = 100.0}) async {
    try {
      final db = await _dbHelper.database;

      // بحث تقريبي بناءً على المسافة
      // درجة واحدة تقريباً = 111 كم
      final latDelta = radiusMeters / 111000;
      final lonDelta = radiusMeters / (111000 * 1.0); // تبسيط حساب خط الطول

      final maps = await db.query(
        'location_visits',
        where: '''
          ABS(latitude - ?) < ? AND 
          ABS(longitude - ?) < ?
        ''',
        whereArgs: [latitude, latDelta, longitude, lonDelta],
        orderBy: 'visit_frequency DESC, updated_at DESC',
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return LocationVisit.fromMap(maps.first);
      }

      return null;
    } catch (e) {
      debugPrint('❌ خطأ في البحث عن موقع مشابه: $e');
      return null;
    }
  }

  /// الحصول على الأماكن المتكررة
  Future<List<LocationVisit>> getFrequentLocations({int limit = 10}) async {
    try {
      final db = await _dbHelper.database;

      final maps = await db.query(
        'location_visits',
        where: 'visit_frequency > 1 AND place_name IS NOT NULL',
        orderBy: 'visit_frequency DESC, updated_at DESC',
        limit: limit,
      );

      return maps.map((map) => LocationVisit.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ خطأ في قراءة الأماكن المتكررة: $e');
      return [];
    }
  }

  /// الحصول على الأماكن المحفوظة (البيت والعمل)
  Future<Map<String, LocationVisit?>> getSavedPlaces() async {
    try {
      final db = await _dbHelper.database;

      final homeResult = await db.query(
        'location_visits',
        where: 'is_home = 1',
        orderBy: 'visit_frequency DESC',
        limit: 1,
      );

      final workResult = await db.query(
        'location_visits',
        where: 'is_work = 1',
        orderBy: 'visit_frequency DESC',
        limit: 1,
      );

      return {
        'home': homeResult.isNotEmpty ? LocationVisit.fromMap(homeResult.first) : null,
        'work': workResult.isNotEmpty ? LocationVisit.fromMap(workResult.first) : null,
      };
    } catch (e) {
      debugPrint('❌ خطأ في قراءة الأماكن المحفوظة: $e');
      return {'home': null, 'work': null};
    }
  }

  /// تحديث تكرار الزيارة
  Future<bool> updateVisitFrequency(int visitId, int newFrequency) async {
    try {
      final db = await _dbHelper.database;

      final count = await db.update(
        'location_visits',
        {
          'visit_frequency': newFrequency,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [visitId],
      );

      return count > 0;
    } catch (e) {
      debugPrint('❌ خطأ في تحديث تكرار الزيارة: $e');
      return false;
    }
  }

  /// تحديث بيانات المكان
  Future<bool> updateLocationDetails(int visitId, {
    String? placeName,
    String? placeType,
    String? placeCategory,
    bool? isHome,
    bool? isWork,
    String? notes,
  }) async {
    try {
      final db = await _dbHelper.database;

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      };

      if (placeName != null) updates['place_name'] = placeName;
      if (placeType != null) updates['place_type'] = placeType;
      if (placeCategory != null) updates['place_category'] = placeCategory;
      if (isHome != null) updates['is_home'] = isHome ? 1 : 0;
      if (isWork != null) updates['is_work'] = isWork ? 1 : 0;
      if (notes != null) updates['notes'] = notes;

      final count = await db.update(
        'location_visits',
        updates,
        where: 'id = ?',
        whereArgs: [visitId],
      );

      if (count > 0) {
        debugPrint('✅ تم تحديث بيانات المكان: $placeName');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ خطأ في تحديث بيانات المكان: $e');
      return false;
    }
  }

  /// تعيين مكان كبيت
  Future<bool> setAsHome(int visitId) async {
    try {
      final db = await _dbHelper.database;

      // إلغاء تعيين البيت من أماكن أخرى
      await db.update(
        'location_visits',
        {'is_home': 0, 'updated_at': DateTime.now().millisecondsSinceEpoch},
        where: 'is_home = 1',
      );

      // تعيين المكان الجديد كبيت
      final count = await db.update(
        'location_visits',
        {
          'is_home': 1,
          'is_work': 0, // لا يمكن أن يكون بيت ومكتب في نفس الوقت
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [visitId],
      );

      return count > 0;
    } catch (e) {
      debugPrint('❌ خطأ في تعيين المكان كبيت: $e');
      return false;
    }
  }

  /// تعيين مكان كمكتب
  Future<bool> setAsWork(int visitId) async {
    try {
      final db = await _dbHelper.database;

      // إلغاء تعيين المكتب من أماكن أخرى
      await db.update(
        'location_visits',
        {'is_work': 0, 'updated_at': DateTime.now().millisecondsSinceEpoch},
        where: 'is_work = 1',
      );

      // تعيين المكان الجديد كمكتب
      final count = await db.update(
        'location_visits',
        {
          'is_work': 1,
          'is_home': 0, // لا يمكن أن يكون بيت ومكتب في نفس الوقت
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [visitId],
      );

      return count > 0;
    } catch (e) {
      debugPrint('❌ خطأ في تعيين المكان كمكتب: $e');
      return false;
    }
  }

  /// حذف زيارة موقع
  Future<bool> deleteLocationVisit(int visitId) async {
    try {
      final db = await _dbHelper.database;

      final count = await db.delete(
        'location_visits',
        where: 'id = ?',
        whereArgs: [visitId],
      );

      if (count > 0) {
        debugPrint('✅ تم حذف زيارة الموقع');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ خطأ في حذف زيارة الموقع: $e');
      return false;
    }
  }

  /// البحث في المواقع
  Future<List<LocationVisit>> searchLocations(String query) async {
    try {
      final db = await _dbHelper.database;

      final maps = await db.query(
        'location_visits',
        where: 'place_name LIKE ? OR place_type LIKE ? OR notes LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: 'visit_frequency DESC, updated_at DESC',
        limit: 20,
      );

      return maps.map((map) => LocationVisit.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ خطأ في البحث في المواقع: $e');
      return [];
    }
  }

  /// إحصائيات المواقع
  Future<Map<String, dynamic>> getLocationStatistics({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final db = await _dbHelper.database;

      final startTimestamp = DateTime.parse('${startDate}T00:00:00').millisecondsSinceEpoch;
      final endTimestamp = DateTime.parse('${endDate}T23:59:59').millisecondsSinceEpoch;

      final result = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_visits,
          COUNT(DISTINCT place_name) as unique_places,
          COUNT(DISTINCT CASE WHEN place_name IS NOT NULL THEN place_name END) as named_places,
          AVG(CASE WHEN duration IS NOT NULL THEN duration END) as avg_visit_duration,
          SUM(CASE WHEN duration IS NOT NULL THEN duration END) as total_time_spent,
          MAX(visit_frequency) as most_visited_count,
          COUNT(CASE WHEN is_home = 1 THEN 1 END) as home_visits,
          COUNT(CASE WHEN is_work = 1 THEN 1 END) as work_visits
        FROM location_visits 
        WHERE arrival_time >= ? AND arrival_time <= ?
      ''', [startTimestamp, endTimestamp]);

      // إحصائيات أنواع الأماكن
      final typeStats = await db.rawQuery('''
        SELECT 
          place_type,
          COUNT(*) as count,
          AVG(CASE WHEN duration IS NOT NULL THEN duration END) as avg_duration
        FROM location_visits 
        WHERE arrival_time >= ? AND arrival_time <= ? 
          AND place_type IS NOT NULL
        GROUP BY place_type
        ORDER BY count DESC
      ''', [startTimestamp, endTimestamp]);

      final stats = result.isNotEmpty ? result.first : {};

      return {
        'total_visits': stats['total_visits'] ?? 0,
        'unique_places': stats['unique_places'] ?? 0,
        'named_places': stats['named_places'] ?? 0,
        'avg_visit_duration_minutes': ((stats['avg_visit_duration'] as num?)?.toDouble() ?? 0.0) / 60000,
        'total_time_spent_hours': ((stats['total_time_spent'] as num?)?.toDouble() ?? 0.0) / 3600000,
        'most_visited_count': stats['most_visited_count'] ?? 0,
        'home_visits': stats['home_visits'] ?? 0,
        'work_visits': stats['work_visits'] ?? 0,
        'place_types': typeStats,
        'period_start': startDate,
        'period_end': endDate,
      };
    } catch (e) {
      debugPrint('❌ خطأ في إحصائيات المواقع: $e');
      return {};
    }
  }

  /// الحصول على الأماكن الأكثر زيارة
  Future<List<Map<String, dynamic>>> getMostVisitedPlaces({int limit = 10}) async {
    try {
      final db = await _dbHelper.database;

      final maps = await db.rawQuery('''
        SELECT 
          place_name,
          place_type,
          latitude,
          longitude,
          visit_frequency,
          COUNT(*) as total_visits,
          SUM(CASE WHEN duration IS NOT NULL THEN duration END) as total_time,
          AVG(CASE WHEN duration IS NOT NULL THEN duration END) as avg_time,
          MAX(arrival_time) as last_visit,
          is_home,
          is_work
        FROM location_visits 
        WHERE place_name IS NOT NULL
        GROUP BY place_name, latitude, longitude
        ORDER BY visit_frequency DESC, total_visits DESC
        LIMIT ?
      ''', [limit]);

      return maps.map((map) => {
        'place_name': map['place_name'],
        'place_type': map['place_type'],
        'latitude': map['latitude'],
        'longitude': map['longitude'],
        'visit_frequency': map['visit_frequency'],
        'total_visits': map['total_visits'],
        'total_time_hours': ((map['total_time'] as num?)?.toDouble() ?? 0.0) / 3600000,
        'avg_time_minutes': ((map['avg_time'] as num?)?.toDouble() ?? 0.0) / 60000,
        'last_visit': map['last_visit'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['last_visit'] as int)
            : null,
        'is_home': (map['is_home'] as int) == 1,
        'is_work': (map['is_work'] as int) == 1,
      }).toList();
    } catch (e) {
      debugPrint('❌ خطأ في قراءة الأماكن الأكثر زيارة: $e');
      return [];
    }
  }

  /// الحصول على الوقت المقضي في كل مكان لتاريخ معين
  Future<Map<String, Duration>> getTimeSpentByPlace(String date) async {
    try {
      final visits = await getLocationVisitsForDate(date);
      final timeByPlace = <String, Duration>{};

      for (final visit in visits) {
        final placeName = visit.placeName ?? 'مكان غير معروف';
        final duration = visit.duration ?? Duration.zero;

        if (timeByPlace.containsKey(placeName)) {
          timeByPlace[placeName] = timeByPlace[placeName]! + duration;
        } else {
          timeByPlace[placeName] = duration;
        }
      }

      return timeByPlace;
    } catch (e) {
      debugPrint('❌ خطأ في حساب الوقت المقضي في الأماكن: $e');
      return {};
    }
  }

  /// الحصول على نمط الحركة اليومي
  Future<List<Map<String, dynamic>>> getDailyMovementPattern(String date) async {
    try {
      final visits = await getLocationVisitsForDate(date);
      final pattern = <Map<String, dynamic>>[];

      for (final visit in visits) {
        pattern.add({
          'place_name': visit.placeName ?? 'مكان غير معروف',
          'place_type': visit.placeType ?? 'غير محدد',
          'arrival_time': visit.arrivalTime,
          'departure_time': visit.departureTime,
          'duration': visit.duration,
          'duration_minutes': visit.duration?.inMinutes ?? 0,
          'is_home': visit.isHome,
          'is_work': visit.isWork,
          'latitude': visit.latitude,
          'longitude': visit.longitude,
        });
      }

      return pattern;
    } catch (e) {
      debugPrint('❌ خطأ في تحليل نمط الحركة: $e');
      return [];
    }
  }

  /// تحديد الأماكن الجديدة (لم تُزر من قبل)
  Future<List<LocationVisit>> getNewPlacesVisited({int daysBack = 7}) async {
    try {
      final db = await _dbHelper.database;

      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: daysBack));
      final startTimestamp = startDate.millisecondsSinceEpoch;

      final maps = await db.query(
        'location_visits',
        where: 'arrival_time >= ? AND visit_frequency = 1',
        whereArgs: [startTimestamp],
        orderBy: 'arrival_time DESC',
      );

      return maps.map((map) => LocationVisit.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ خطأ في قراءة الأماكن الجديدة: $e');
      return [];
    }
  }

  /// دمج زيارات متشابهة
  Future<bool> mergeSimilarVisits(List<int> visitIds, {
    required String newPlaceName,
    String? newPlaceType,
  }) async {
    try {
      final db = await _dbHelper.database;

      if (visitIds.isEmpty) return false;

      // الحصول على الزيارات المراد دمجها
      final visits = <LocationVisit>[];
      for (final id in visitIds) {
        final maps = await db.query(
          'location_visits',
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );
        if (maps.isNotEmpty) {
          visits.add(LocationVisit.fromMap(maps.first));
        }
      }

      if (visits.isEmpty) return false;

      // حساب المتوسط للإحداثيات
      final avgLat = visits.map((v) => v.latitude).reduce((a, b) => a + b) / visits.length;
      final avgLng = visits.map((v) => v.longitude).reduce((a, b) => a + b) / visits.length;

      // حساب التكرار الإجمالي
      final totalFrequency = visits.map((v) => v.visitFrequency).reduce((a, b) => a + b);

      // إنشاء زيارة مدموجة جديدة
      final mergedVisit = visits.first.copyWith(
        latitude: avgLat,
        longitude: avgLng,
        placeName: newPlaceName,
        placeType: newPlaceType ?? visits.first.placeType,
        visitFrequency: totalFrequency,
        updatedAt: DateTime.now(),
      );

      // تحديث الزيارة الأولى
      await updateLocationVisit(mergedVisit);

      // حذف الزيارات الأخرى
      for (int i = 1; i < visitIds.length; i++) {
        await deleteLocationVisit(visitIds[i]);
      }

      debugPrint('✅ تم دمج ${visitIds.length} زيارة في "$newPlaceName"');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في دمج الزيارات: $e');
      return false;
    }
  }

  /// تنظيف البيانات القديمة
  Future<int> cleanOldLocationData({int daysToKeep = 365}) async {
    try {
      final db = await _dbHelper.database;
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final cutoffTimestamp = cutoffDate.millisecondsSinceEpoch;

      // حذف الزيارات القديمة (ما عدا البيت والعمل والأماكن المهمة)
      final deletedCount = await db.delete(
        'location_visits',
        where: '''
          arrival_time < ? AND 
          is_home = 0 AND 
          is_work = 0 AND 
          visit_frequency <= 2
        ''',
        whereArgs: [cutoffTimestamp],
      );

      if (deletedCount > 0) {
        debugPrint('🗑️ تم حذف $deletedCount زيارة موقع قديمة');
      }

      return deletedCount;
    } catch (e) {
      debugPrint('❌ خطأ في تنظيف بيانات المواقع القديمة: $e');
      return 0;
    }
  }

  /// إحصائيات قاعدة البيانات
  Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      final db = await _dbHelper.database;

      final totalVisits = await db.rawQuery('SELECT COUNT(*) as count FROM location_visits');
      final namedPlaces = await db.rawQuery('SELECT COUNT(DISTINCT place_name) as count FROM location_visits WHERE place_name IS NOT NULL');
      final homeVisits = await db.rawQuery('SELECT COUNT(*) as count FROM location_visits WHERE is_home = 1');
      final workVisits = await db.rawQuery('SELECT COUNT(*) as count FROM location_visits WHERE is_work = 1');
      final firstVisit = await db.rawQuery('SELECT MIN(arrival_time) as first_visit FROM location_visits');
      final lastVisit = await db.rawQuery('SELECT MAX(arrival_time) as last_visit FROM location_visits');

      return {
        'total_visits': totalVisits.first['count'],
        'named_places': namedPlaces.first['count'],
        'home_visits': homeVisits.first['count'],
        'work_visits': workVisits.first['count'],
        'first_visit': firstVisit.first['first_visit'] != null
            ? DateTime.fromMillisecondsSinceEpoch(firstVisit.first['first_visit'] as int)
            : null,
        'last_visit': lastVisit.first['last_visit'] != null
            ? DateTime.fromMillisecondsSinceEpoch(lastVisit.first['last_visit'] as int)
            : null,
      };
    } catch (e) {
      debugPrint('❌ خطأ في إحصائيات قاعدة البيانات: $e');
      return {};
    }
  }

  /// نسخ احتياطي من بيانات المواقع
  Future<Map<String, dynamic>?> exportLocationData({
    String? startDate,
    String? endDate,
  }) async {
    try {
      List<LocationVisit> visits;

      if (startDate != null && endDate != null) {
        visits = await getLocationVisitsForDateRange(startDate, endDate);
      } else {
        final db = await _dbHelper.database;
        final maps = await db.query('location_visits', orderBy: 'arrival_time DESC');
        visits = maps.map((map) => LocationVisit.fromMap(map)).toList();
      }

      final exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'total_visits': visits.length,
        'period_start': startDate,
        'period_end': endDate,
        'visits': visits.map((visit) => {
          'place_name': visit.placeName,
          'place_type': visit.placeType,
          'latitude': visit.latitude,
          'longitude': visit.longitude,
          'arrival_time': visit.arrivalTime.toIso8601String(),
          'departure_time': visit.departureTime?.toIso8601String(),
          'duration_minutes': visit.duration?.inMinutes,
          'visit_frequency': visit.visitFrequency,
          'is_home': visit.isHome,
          'is_work': visit.isWork,
          'notes': visit.notes,
        }).toList(),
      };

      return exportData;
    } catch (e) {
      debugPrint('❌ خطأ في تصدير بيانات المواقع: $e');
      return null;
    }
  }

  /// إنشاء ملخص أسبوعي للمواقع
  Future<Map<String, dynamic>> getWeeklyLocationSummary() async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final startDate = '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';

      final endDate = DateTime.now();
      final endDateStr = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

      final visits = await getLocationVisitsForDateRange(startDate, endDateStr);
      final stats = await getLocationStatistics(startDate: startDate, endDate: endDateStr);
      final topPlaces = await getMostVisitedPlaces(limit: 5);

      return {
        'week_start': startDate,
        'week_end': endDateStr,
        'total_visits': visits.length,
        'unique_places': stats['unique_places'] ?? 0,
        'total_time_hours': stats['total_time_spent_hours'] ?? 0.0,
        'home_time_percentage': _calculateHomeTimePercentage(visits),
        'work_time_percentage': _calculateWorkTimePercentage(visits),
        'top_places': topPlaces,
        'new_places': (await getNewPlacesVisited(daysBack: 7)).length,
      };
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء الملخص الأسبوعي: $e');
      return {};
    }
  }

  /// حساب نسبة الوقت في البيت
  double _calculateHomeTimePercentage(List<LocationVisit> visits) {
    final homeVisits = visits.where((v) => v.isHome).toList();
    if (homeVisits.isEmpty) return 0.0;

    final totalHomeTime = homeVisits
        .where((v) => v.duration != null)
        .map((v) => v.duration!.inMilliseconds)
        .fold(0, (sum, duration) => sum + duration);

    final totalTime = visits
        .where((v) => v.duration != null)
        .map((v) => v.duration!.inMilliseconds)
        .fold(0, (sum, duration) => sum + duration);

    return totalTime > 0 ? (totalHomeTime / totalTime) * 100 : 0.0;
  }

  /// حساب نسبة الوقت في العمل
  double _calculateWorkTimePercentage(List<LocationVisit> visits) {
    final workVisits = visits.where((v) => v.isWork).toList();
    if (workVisits.isEmpty) return 0.0;

    final totalWorkTime = workVisits
        .where((v) => v.duration != null)
        .map((v) => v.duration!.inMilliseconds)
        .fold(0, (sum, duration) => sum + duration);

    final totalTime = visits
        .where((v) => v.duration != null)
        .map((v) => v.duration!.inMilliseconds)
        .fold(0, (sum, duration) => sum + duration);

    return totalTime > 0 ? (totalWorkTime / totalTime) * 100 : 0.0;
  }

  // ═══════════════════════════════════════════════════════════
  // Sync Methods - للمزامنة مع السيرفر
  // ═══════════════════════════════════════════════════════════

  /// جلب الزيارات غير المرفوعة
  Future<List<LocationVisit>> getUnsyncedVisits() async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        'location_visits',
        where: 'synced = ? OR synced IS NULL',
        whereArgs: [0],
        orderBy: 'arrival_time ASC',
        limit: 100,
      );
      return results.map((map) => LocationVisit.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ خطأ في جلب الزيارات غير المرفوعة: $e');
      return [];
    }
  }

  /// تحديث حالة المزامنة
  Future<void> markAsSynced(int visitId) async {
    try {
      final db = await _dbHelper.database;
      await db.update(
        'location_visits',
        {'synced': 1, 'last_sync_time': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [visitId],
      );
    } catch (e) {
      debugPrint('❌ خطأ في تحديث حالة المزامنة: $e');
    }
  }
}