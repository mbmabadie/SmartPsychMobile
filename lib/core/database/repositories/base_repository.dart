// lib/core/repositories/base_repository.dart
import 'package:flutter/foundation.dart';

import '../database_helper.dart';

abstract class BaseRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<T> executeWithErrorHandling<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (e) {
      debugPrint('❌ خطأ في العملية: $e');
      rethrow;
    }
  }

  String get tableName;

  Future<void> deleteOldRecords({required int daysToKeep}) async {
    try {
      final db = await _dbHelper.database;
      final cutoffTime = DateTime.now().subtract(Duration(days: daysToKeep));

      await db.delete(
        tableName,
        where: 'created_at < ?',
        whereArgs: [cutoffTime.millisecondsSinceEpoch],
      );

      debugPrint('🗑️ تم حذف البيانات القديمة من $tableName');
    } catch (e) {
      debugPrint('❌ خطأ في حذف البيانات القديمة من $tableName: $e');
    }
  }
}



