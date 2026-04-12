// lib/core/database/repositories/settings_repository.dart
import 'package:flutter/foundation.dart';
import '../database_helper.dart';
import '../models/common_models.dart';
import 'base_repository.dart';

class SettingsRepository extends BaseRepository {
  static final SettingsRepository _instance = SettingsRepository._internal();
  factory SettingsRepository() => _instance;
  SettingsRepository._internal();

  static SettingsRepository get instance => _instance;

  @override
  String get tableName => 'app_settings';
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ===============================
  // Core Settings Operations
  // ===============================

  /// الحصول على إعداد مع قيمة افتراضية
  Future<T?> getSetting<T>(String key, T? defaultValue) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final maps = await db.query(
        tableName,
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );

      if (maps.isEmpty) {
        return defaultValue;
      }

      final setting = AppSettings.fromMap(maps.first);

      // تحويل القيمة حسب النوع المطلوب
      switch (T) {
        case int:
          return int.tryParse(setting.value.toString()) as T? ?? defaultValue;
        case double:
          return double.tryParse(setting.value.toString()) as T? ?? defaultValue;
        case bool:
          return (setting.value.toString().toLowerCase() == 'true') as T? ?? defaultValue;
        case String:
        default:
          return setting.value.toString() as T? ?? defaultValue;
      }
    });
  }

  /// دالة محسنة للحصول على إعداد اختياري
  Future<T?> getOptionalSetting<T>(String key) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final maps = await db.query(
        tableName,
        where: 'key = ?',
        whereArgs: [key],
      );

      if (maps.isNotEmpty) {
        final setting = AppSettings.fromMap(maps.first);
        return setting.value as T?;
      }

      return null; // إرجاع null إذا لم يوجد الإعداد
    });
  }

  /// دالة للحصول على إعداد String اختياري
  Future<String?> getStringOrNull(String key) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final maps = await db.query(
        tableName,
        where: 'key = ?',
        whereArgs: [key],
      );

      if (maps.isNotEmpty) {
        final setting = AppSettings.fromMap(maps.first);
        final value = setting.value as String?;
        return (value?.isEmpty ?? true) ? null : value;
      }

      return null;
    });
  }

  /// حفظ إعداد
  Future<bool> setSetting<T>(String key, T value, SettingValueType valueType) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final settingData = {
        'key': key,
        'value': value.toString(),
        'value_type': valueType.name,
        'created_at': now,
        'updated_at': now,
      };

      // محاولة التحديث أولاً
      final updateCount = await db.update(
        tableName,
        settingData,
        where: 'key = ?',
        whereArgs: [key],
      );

      // إذا لم يتم التحديث، قم بالإدراج
      if (updateCount == 0) {
        await db.insert(tableName, settingData);
      }

      debugPrint('✅ تم حفظ الإعداد: $key = $value');
      return true;
    });
  }

  /// حذف إعداد - المطلوب للـ AppStateProvider
  Future<bool> deleteSetting(String key) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final count = await db.delete(
        tableName,
        where: 'key = ?',
        whereArgs: [key],
      );

      debugPrint('🗑️ تم حذف الإعداد $key: ${count > 0 ? 'نجح' : 'فشل'}');
      return count > 0;
    });
  }

  /// حذف عدة إعدادات بمفاتيح معينة
  Future<bool> deleteSettings(List<String> keys) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      if (keys.isEmpty) return true;

      final placeholders = List.generate(keys.length, (index) => '?').join(',');
      final count = await db.delete(
        tableName,
        where: 'key IN ($placeholders)',
        whereArgs: keys,
      );

      debugPrint('🗑️ تم حذف $count إعداد من ${keys.length}');
      return count > 0;
    });
  }

  /// فحص إذا كان الإعداد موجود
  Future<bool> settingExists(String key) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final maps = await db.query(
        tableName,
        columns: ['key'],
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );

      return maps.isNotEmpty;
    });
  }

  // ===============================
  // Batch Operations
  // ===============================

  /// الحصول على جميع الإعدادات
  Future<Map<String, dynamic>> getAllSettings() async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final maps = await db.query(tableName);
      final settings = <String, dynamic>{};

      for (final map in maps) {
        final setting = AppSettings.fromMap(map);
        settings[setting.key] = setting.value;
      }

      return settings;
    });
  }

  /// الحصول على جميع الإعدادات كـ AppSettings objects
  Future<List<AppSettings>> getAllSettingsAsObjects() async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;
      final maps = await db.query(tableName, orderBy: 'key ASC');

      return maps.map((map) => AppSettings.fromMap(map)).toList();
    });
  }

  /// تطبيق إعدادات متعددة في transaction واحد
  Future<bool> batchSetSettings(Map<String, dynamic> settings) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      return await db.transaction((txn) async {
        int successCount = 0;

        for (final entry in settings.entries) {
          try {
            final now = DateTime.now().millisecondsSinceEpoch;

            // تحديد نوع البيانات
            SettingValueType type;
            if (entry.value is bool) {
              type = SettingValueType.bool;
            } else if (entry.value is int) {
              type = SettingValueType.int;
            } else if (entry.value is double) {
              type = SettingValueType.double;
            } else {
              type = SettingValueType.string;
            }

            final settingMap = {
              'key': entry.key,
              'value': entry.value.toString(),
              'value_type': type.name,
              'updated_at': now,
            };

            final existing = await txn.query(
              tableName,
              where: 'key = ?',
              whereArgs: [entry.key],
            );

            if (existing.isNotEmpty) {
              await txn.update(
                tableName,
                settingMap,
                where: 'key = ?',
                whereArgs: [entry.key],
              );
            } else {
              settingMap['created_at'] = now;
              await txn.insert(tableName, settingMap);
            }

            successCount++;
          } catch (e) {
            debugPrint('⚠️ فشل في حفظ الإعداد ${entry.key}: $e');
          }
        }

        debugPrint('💾 تم حفظ $successCount من ${settings.length} إعداد');
        return successCount == settings.length;
      });
    });
  }

  /// حذف جميع الإعدادات
  Future<bool> clearAllSettings() async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;
      final count = await db.delete(tableName);
      debugPrint('🗑️ تم حذف جميع الإعدادات: $count');
      return count > 0;
    });
  }

  // ===============================
  // App Preferences Management
  // ===============================

  /// إعادة تعيين الإعدادات للافتراضية
  Future<void> resetToDefaults() async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      // حذف جميع الإعدادات
      await db.delete(tableName);

      // إعادة إدراج الافتراضية
      final now = DateTime.now().millisecondsSinceEpoch;
      final defaultSettings = [
        {'key': 'step_goal_daily', 'value': '10000', 'value_type': 'int'},
        {'key': 'calories_goal_daily', 'value': '500', 'value_type': 'int'},
        {'key': 'meals_goal_daily', 'value': '4', 'value_type': 'int'},
        {'key': 'weight_unit', 'value': 'kg', 'value_type': 'string'},
        {'key': 'distance_unit', 'value': 'km', 'value_type': 'string'},
        {'key': 'notifications_enabled', 'value': 'true', 'value_type': 'bool'},
        {'key': 'location_tracking_enabled', 'value': 'true', 'value_type': 'bool'},
        {'key': 'activity_tracking_enabled', 'value': 'true', 'value_type': 'bool'},
        {'key': 'theme_mode', 'value': 'system', 'value_type': 'string'},
        {'key': 'language', 'value': 'ar', 'value_type': 'string'},
      ];

      for (final setting in defaultSettings) {
        await db.insert(tableName, {
          ...setting,
          'created_at': now,
          'updated_at': now,
        });
      }

      debugPrint('✅ تم إعادة تعيين الإعدادات الافتراضية');
    });
  }

  /// الحصول على إعدادات التطبيق الأساسية
  Future<Map<String, dynamic>> getAppPreferences() async {
    return executeWithErrorHandling(() async {
      final prefs = <String, dynamic>{};

      prefs['step_goal_daily'] = await getSetting<int>('step_goal_daily', 10000);
      prefs['calories_goal_daily'] = await getSetting<int>('calories_goal_daily', 500);
      prefs['meals_goal_daily'] = await getSetting<int>('meals_goal_daily', 4);
      prefs['weight_unit'] = await getSetting<String>('weight_unit', 'kg');
      prefs['distance_unit'] = await getSetting<String>('distance_unit', 'km');
      prefs['notifications_enabled'] = await getSetting<bool>('notifications_enabled', true);
      prefs['location_tracking_enabled'] = await getSetting<bool>('location_tracking_enabled', true);
      prefs['activity_tracking_enabled'] = await getSetting<bool>('activity_tracking_enabled', true);
      prefs['theme_mode'] = await getSetting<String>('theme_mode', 'system');
      prefs['language'] = await getSetting<String>('language', 'ar');

      return prefs;
    });
  }

  /// حفظ إعدادات التطبيق الأساسية
  Future<bool> saveAppPreferences(Map<String, dynamic> preferences) async {
    return executeWithErrorHandling(() async {
      bool allSuccess = true;

      for (final entry in preferences.entries) {
        final key = entry.key;
        final value = entry.value;

        SettingValueType valueType;
        if (value is int) {
          valueType = SettingValueType.int;
        } else if (value is double) {
          valueType = SettingValueType.double;
        } else if (value is bool) {
          valueType = SettingValueType.bool;
        } else {
          valueType = SettingValueType.string;
        }

        final success = await setSetting(key, value, valueType);
        if (!success) allSuccess = false;
      }

      return allSuccess;
    });
  }

  /// الحصول على إعدادات التطبيق كـ AppSettings object
  Future<AppSettings> getAppSettings() async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final maps = await db.query(
        tableName,
        where: 'key = ?',
        whereArgs: ['app_main_settings'],
      );

      if (maps.isNotEmpty) {
        return AppSettings.fromMap(maps.first);
      }

      // إرجاع إعدادات افتراضية إذا لم توجد
      return AppSettings.initial();
    });
  }

  /// حفظ إعدادات التطبيق كـ AppSettings object
  Future<bool> saveAppSettings(AppSettings settings) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final settingMap = settings.toMap();
      settingMap['updated_at'] = DateTime.now().millisecondsSinceEpoch;

      final existing = await db.query(
        tableName,
        where: 'key = ?',
        whereArgs: [settings.key],
      );

      if (existing.isNotEmpty) {
        final count = await db.update(
          tableName,
          settingMap,
          where: 'key = ?',
          whereArgs: [settings.key],
        );
        return count > 0;
      } else {
        settingMap['created_at'] = DateTime.now().millisecondsSinceEpoch;
        final id = await db.insert(tableName, settingMap);
        return id > 0;
      }
    });
  }

  // ===============================
  // Advanced Operations
  // ===============================

  /// البحث في الإعدادات
  Future<List<AppSettings>> searchSettings(String searchTerm) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final maps = await db.query(
        tableName,
        where: 'key LIKE ? OR value LIKE ?',
        whereArgs: ['%$searchTerm%', '%$searchTerm%'],
        orderBy: 'key ASC',
      );

      return maps.map((map) => AppSettings.fromMap(map)).toList();
    });
  }

  /// الحصول على الإعدادات بنوع معين
  Future<List<AppSettings>> getSettingsByType(SettingValueType type) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final maps = await db.query(
        tableName,
        where: 'value_type = ?',
        whereArgs: [type.name],
        orderBy: 'key ASC',
      );

      return maps.map((map) => AppSettings.fromMap(map)).toList();
    });
  }

  /// تحديث قيمة إعداد موجود فقط
  Future<bool> updateSettingIfExists(String key, dynamic value, SettingValueType type) async {
    return executeWithErrorHandling(() async {
      final exists = await settingExists(key);
      if (!exists) return false;

      return await setSetting(key, value, type);
    });
  }

  /// الحصول على إعداد مع معلومات إضافية
  Future<AppSettings?> getSettingDetails(String key) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final maps = await db.query(
        tableName,
        where: 'key = ?',
        whereArgs: [key],
      );

      if (maps.isNotEmpty) {
        return AppSettings.fromMap(maps.first);
      }

      return null;
    });
  }

  // ===============================
  // Statistics and Analytics
  // ===============================

  /// عدد الإعدادات
  Future<int> getSettingsCount() async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
      return result.first['count'] as int;
    });
  }

  /// إحصائيات الإعدادات
  Future<Map<String, dynamic>> getSettingsStatistics() async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      // إجمالي العدد
      final totalCount = await getSettingsCount();

      // العدد حسب النوع
      final typeStats = <String, int>{};
      for (final type in SettingValueType.values) {
        final result = await db.rawQuery(
          'SELECT COUNT(*) as count FROM $tableName WHERE value_type = ?',
          [type.name],
        );
        typeStats[type.name] = result.first['count'] as int;
      }

      // آخر تحديث
      final lastUpdateResult = await db.rawQuery(
        'SELECT MAX(updated_at) as last_update FROM $tableName',
      );
      final lastUpdate = lastUpdateResult.first['last_update'] as int?;

      return {
        'total_settings': totalCount,
        'by_type': typeStats,
        'last_update': lastUpdate != null
            ? DateTime.fromMillisecondsSinceEpoch(lastUpdate).toIso8601String()
            : null,
      };
    });
  }

  // ===============================
  // Backup and Restore
  // ===============================

  /// نسخ احتياطي للإعدادات
  Future<Map<String, dynamic>?> backupSettings() async {
    return executeWithErrorHandling(() async {
      final allSettings = await getAllSettings();

      return {
        'backup_date': DateTime.now().toIso8601String(),
        'settings_count': allSettings.length,
        'settings': allSettings,
        'version': '1.0.0',
      };
    });
  }

  /// استعادة الإعدادات من نسخة احتياطية
  Future<bool> restoreSettings(Map<String, dynamic> backup) async {
    return executeWithErrorHandling(() async {
      if (!backup.containsKey('settings')) {
        debugPrint('❌ النسخة الاحتياطية غير صالحة');
        return false;
      }

      final settings = backup['settings'] as Map<String, dynamic>;

      // حذف الإعدادات الحالية
      final db = await _dbHelper.database;
      await db.delete(tableName);

      // استعادة الإعدادات
      final now = DateTime.now().millisecondsSinceEpoch;

      for (final entry in settings.entries) {
        final key = entry.key;
        final value = entry.value;

        SettingValueType valueType = SettingValueType.string;
        if (value is int) valueType = SettingValueType.int;
        else if (value is double) valueType = SettingValueType.double;
        else if (value is bool) valueType = SettingValueType.bool;

        await db.insert(tableName, {
          'key': key,
          'value': value.toString(),
          'value_type': valueType.name,
          'created_at': now,
          'updated_at': now,
        });
      }

      debugPrint('✅ تم استعادة ${settings.length} إعداد من النسخة الاحتياطية');
      return true;
    });
  }

  // ===============================
  // Maintenance and Cleanup
  // ===============================

  /// حذف الإعدادات القديمة
  Future<bool> deleteOldSettings(Duration maxAge) async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;
      final cutoffTime = DateTime.now().subtract(maxAge).millisecondsSinceEpoch;

      final count = await db.delete(
        tableName,
        where: 'updated_at < ?',
        whereArgs: [cutoffTime],
      );

      debugPrint('🗑️ تم حذف $count إعداد قديم');
      return count > 0;
    });
  }

  /// تنظيف وصيانة قاعدة البيانات
  Future<bool> maintenanceCleanup() async {
    return executeWithErrorHandling(() async {
      final db = await _dbHelper.database;

      // حذف الإعدادات المكررة (إن وجدت)
      await db.rawDelete('''
        DELETE FROM $tableName 
        WHERE rowid NOT IN (
          SELECT MIN(rowid) 
          FROM $tableName 
          GROUP BY key
        )
      ''');

      // تنظيف الإعدادات القديمة (أكثر من سنة)
      await deleteOldSettings(const Duration(days: 365));

      // إعادة بناء فهارس الجدول
      await db.execute('REINDEX $tableName');

      debugPrint('🧹 تم تنظيف وصيانة جدول الإعدادات');
      return true;
    });
  }

  // ===============================
  // Data Export and Import
  // ===============================

  /// تصدير الإعدادات إلى JSON
  Future<Map<String, dynamic>?> exportSettingsToJson() async {
    return executeWithErrorHandling(() async {
      final settings = await getAllSettingsAsObjects();

      return {
        'export_date': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
        'settings_count': settings.length,
        'settings': settings.map((setting) => {
          'key': setting.key,
          'value': setting.value,
          'value_type': setting.valueType.name,
          'created_at': setting.createdAt.toIso8601String(),
          'updated_at': setting.updatedAt.toIso8601String(),
        }).toList(),
      };
    });
  }

  /// استيراد الإعدادات من JSON
  Future<bool> importSettingsFromJson(Map<String, dynamic> jsonData) async {
    return executeWithErrorHandling(() async {
      if (!jsonData.containsKey('settings')) {
        debugPrint('❌ بيانات الاستيراد غير صالحة');
        return false;
      }

      final settingsList = jsonData['settings'] as List;
      int importedCount = 0;

      for (final settingData in settingsList) {
        try {
          final key = settingData['key'] as String;
          final value = settingData['value'];
          final typeString = settingData['value_type'] as String;

          final valueType = SettingValueType.values.firstWhere(
                (type) => type.name == typeString,
            orElse: () => SettingValueType.string,
          );

          final success = await setSetting(key, value, valueType);
          if (success) importedCount++;
        } catch (e) {
          debugPrint('⚠️ فشل في استيراد إعداد: $e');
        }
      }

      debugPrint('✅ تم استيراد $importedCount من ${settingsList.length} إعداد');
      return importedCount > 0;
    });
  }

  // ===============================
  // Helper Methods
  // ===============================

  /// التحقق من صحة مفتاح الإعداد
  bool _isValidKey(String key) {
    return key.isNotEmpty && key.length <= 255 && !key.contains(' ');
  }

  /// تنظيف قيمة الإعداد
  String _sanitizeValue(dynamic value) {
    if (value == null) return '';
    final stringValue = value.toString();
    return stringValue.length > 1000 ? stringValue.substring(0, 1000) : stringValue;
  }

  /// الحصول على نوع البيانات من القيمة
  SettingValueType _getValueType(dynamic value) {
    if (value is bool) return SettingValueType.bool;
    if (value is int) return SettingValueType.int;
    if (value is double) return SettingValueType.double;
    if (value is Map || value is List) return SettingValueType.json;
    return SettingValueType.string;
  }
}