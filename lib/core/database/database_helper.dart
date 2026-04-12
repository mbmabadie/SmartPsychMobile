// lib/core/database/database_helper.dart - الإصدار 3 - تتبع تعديلات الأوقات

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static DatabaseHelper get instance => _instance;

  Future<Database> get database async {
    if (_database == null) {
      _database = await _initDatabase();
    }
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, 'smart_psych.db');

      debugPrint('📂 قاعدة البيانات: $path');

      return await openDatabase(
        path,
        version: 6, // ✅ النسخة 6 - توحيد جداول النشاط + Sync Support
        onCreate: _createDatabase,
        onUpgrade: _upgradeDatabase,
        onOpen: (db) async {
          debugPrint('✅ تم فتح قاعدة البيانات بنجاح');
          await db.execute('PRAGMA foreign_keys = ON');
        },
      );
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة قاعدة البيانات: $e');
      rethrow;
    }
  }

  Future<void> _createDatabase(Database db, int version) async {
    try {
      debugPrint('🏗️ إنشاء جداول قاعدة البيانات (الإصدار $version)...');

      // ✅ جدول جلسات النوم - محدث بجميع الأعمدة المطلوبة + نظام التصنيف الذكي + تتبع التعديلات
      await db.execute('''
        CREATE TABLE sleep_sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          start_time INTEGER NOT NULL,
          end_time INTEGER,
          duration INTEGER,
          quality_score REAL,
          sleep_type TEXT CHECK(sleep_type IN ('manual', 'automatic')) DEFAULT 'manual',
          notes TEXT,
          is_completed INTEGER DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          detection_confidence REAL DEFAULT 0.8,
          total_interruptions INTEGER DEFAULT 0,
          interruption_count INTEGER DEFAULT 0,
          phone_activations INTEGER DEFAULT 0,
          longest_deep_sleep_duration INTEGER DEFAULT 0,
          environment_stability_score REAL DEFAULT 0,
          light_quality_score REAL DEFAULT 0,
          noise_quality_score REAL DEFAULT 0,
          overall_sleep_quality REAL DEFAULT 0,
          sleep_efficiency REAL DEFAULT 0,
          user_age_at_sleep INTEGER,
          user_confirmation_status TEXT DEFAULT 'pending',
          user_confirmation TEXT DEFAULT 'pending',
          user_rating INTEGER,
          sleep_goal_hours REAL,
          goal_achievement REAL DEFAULT 0,
          confidence TEXT DEFAULT 'uncertain',
          has_pre_sleep_activity INTEGER DEFAULT 0,
          last_phone_usage INTEGER,
          last_steps_count INTEGER,
          user_confirmed_sleep INTEGER DEFAULT 0,
          confirmation_time INTEGER,
          original_start_time INTEGER,
          original_end_time INTEGER,
          was_time_modified INTEGER DEFAULT 0
        )
      ''');

      // ✅ جدول البيانات البيئية
      await db.execute('''
  CREATE TABLE environmental_data (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    sleep_session_id INTEGER NOT NULL,
    timestamp INTEGER NOT NULL,
    light_level REAL,
    light_source_type TEXT,
    light_quality TEXT,
    noise_level REAL,
    noise_peak REAL,
    noise_type TEXT,
    noise_quality TEXT,
    movement_intensity REAL,
    movement_count INTEGER,
    movement_type TEXT,
    temperature REAL,
    temperature_quality TEXT,
    humidity REAL,
    humidity_quality TEXT,
    air_quality REAL,
    atmospheric_pressure REAL,
    co2_level REAL,
    overall_score REAL,
    is_optimal_for_sleep INTEGER DEFAULT 0,
    notes TEXT,
    data_source TEXT DEFAULT 'sensor',
    accuracy REAL DEFAULT 1.0,
    created_at INTEGER NOT NULL,
    phone_screen_on INTEGER DEFAULT 0,
    app_used TEXT,
    usage_duration INTEGER DEFAULT 0,
    interruption_type TEXT,
    recovery_time INTEGER,
    data_quality REAL DEFAULT 1.0,
    FOREIGN KEY (sleep_session_id) REFERENCES sleep_sessions (id) ON DELETE CASCADE
  )
''');

      // ✅ جدول انقطاعات النوم
      await db.execute('''
        CREATE TABLE sleep_interruptions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sleep_session_id INTEGER NOT NULL,
          interruption_start INTEGER NOT NULL,
          interruption_end INTEGER,
          duration INTEGER,
          cause TEXT CHECK(cause IN ('phone', 'movement', 'noise', 'external', 'unknown')) DEFAULT 'unknown',
          phone_apps_used TEXT,
          usage_details TEXT,
          recovery_quality REAL DEFAULT 0,
          impact_on_sleep REAL DEFAULT 0,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (sleep_session_id) REFERENCES sleep_sessions (id) ON DELETE CASCADE
        )
      ''');

      // ✅ جدول أهداف النوم
      await db.execute('''
        CREATE TABLE sleep_goals (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_age INTEGER NOT NULL,
          recommended_hours REAL NOT NULL,
          user_preferred_bedtime TEXT,
          user_preferred_wakeup TEXT,
          sleep_window_start INTEGER,
          sleep_window_end INTEGER,
          is_active INTEGER DEFAULT 1,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      // جدول استخدام الهاتف
      await db.execute('''
        CREATE TABLE phone_usage_sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          start_time INTEGER NOT NULL,
          end_time INTEGER,
          total_usage_time INTEGER NOT NULL,
          total_pickups INTEGER DEFAULT 0,
          first_pickup_time INTEGER,
          last_usage_time INTEGER,
          night_usage_duration INTEGER DEFAULT 0,
          sleep_interruptions INTEGER DEFAULT 0,
          is_completed INTEGER DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          UNIQUE(date)
        )
      ''');

      // جدول استخدام التطبيقات اليومي
      await db.execute('''
        CREATE TABLE app_usage_entries (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          app_name TEXT NOT NULL,
          package_name TEXT NOT NULL,
          date TEXT NOT NULL,
          total_usage_time INTEGER DEFAULT 0,
          open_count INTEGER DEFAULT 0,
          last_used_time INTEGER,
          first_used_time INTEGER,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          UNIQUE(package_name, date)
        )
      ''');

      // جدول المراقبة الساعية
      await db.execute('''
        CREATE TABLE hourly_usage_tracking (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          hour INTEGER NOT NULL,
          package_name TEXT NOT NULL,
          app_name TEXT NOT NULL,
          usage_minutes REAL NOT NULL DEFAULT 0,
          open_count INTEGER NOT NULL DEFAULT 0,
          start_time INTEGER NOT NULL,
          end_time INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          is_current_hour INTEGER DEFAULT 0,
          last_sync_time INTEGER,
          data_source TEXT DEFAULT "live",
          is_finalized INTEGER DEFAULT 0,
          UNIQUE(date, hour, package_name)
        )
      ''');

      // جدول استخدام التطبيقات (للجلسات)
      await db.execute('''
        CREATE TABLE app_usage (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          phone_session_id INTEGER NOT NULL,
          package_name TEXT NOT NULL,
          app_name TEXT,
          category TEXT,
          usage_time INTEGER NOT NULL,
          open_count INTEGER DEFAULT 0,
          first_used INTEGER,
          last_used INTEGER,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (phone_session_id) REFERENCES phone_usage_sessions (id) ON DELETE CASCADE
        )
      ''');

      // جدول إعدادات المستخدم
      await db.execute('''
        CREATE TABLE user_settings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          key TEXT NOT NULL UNIQUE,
          value TEXT NOT NULL,
          value_type TEXT CHECK(value_type IN ('string', 'int', 'double', 'bool', 'json')) DEFAULT 'string',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      // جدول النشاط اليومي الأساسي
      await db.execute('''
        CREATE TABLE daily_activity (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          total_steps INTEGER DEFAULT 0,
          distance_meters REAL DEFAULT 0,
          calories_burned REAL DEFAULT 0,
          active_minutes INTEGER DEFAULT 0,
          average_speed REAL DEFAULT 0.0,
          floors_climbed INTEGER DEFAULT 0,
          activity_breakdown TEXT DEFAULT '{}',
          activity_calories TEXT DEFAULT '{}',
          activity_score REAL DEFAULT 0,
          duration INTEGER DEFAULT 0,
          distance REAL DEFAULT 0,
          calories REAL DEFAULT 0,
          steps INTEGER DEFAULT 0,
          activity_type TEXT DEFAULT 'general',
          is_completed INTEGER DEFAULT 1,
          intensity_score REAL DEFAULT 0,
          sedentary_minutes INTEGER DEFAULT 0,
          fitness_score REAL DEFAULT 0,
          goal_steps INTEGER DEFAULT 10000,
          goal_distance REAL DEFAULT 8.0,
          goal_calories REAL DEFAULT 500.0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          UNIQUE(date)
        )
      ''');

      // ✅ VIEW يشير لجدول daily_activity الأساسي (لتجنب التكرار)
      await db.execute('''
        CREATE VIEW IF NOT EXISTS daily_activities AS
        SELECT * FROM daily_activity
      ''');

      // جدول جلسات النشاط
      await db.execute('''
        CREATE TABLE activity_sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          daily_activity_id INTEGER NOT NULL,
          activity_type TEXT NOT NULL,
          start_time INTEGER NOT NULL,
          end_time INTEGER NOT NULL,
          duration INTEGER NOT NULL,
          date TEXT NOT NULL,
          steps INTEGER DEFAULT 0,
          distance_meters REAL DEFAULT 0,
          calories_burned REAL DEFAULT 0,
          intensity TEXT CHECK(intensity IN ('low', 'moderate', 'high')) DEFAULT 'moderate',
          notes TEXT,
          is_completed INTEGER DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (daily_activity_id) REFERENCES daily_activity (id) ON DELETE CASCADE
        )
      ''');

      // جدول المواقع
      await db.execute('''
        CREATE TABLE location_visits (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          accuracy REAL,
          altitude REAL,
          place_name TEXT,
          place_type TEXT,
          place_category TEXT,
          mood_impact TEXT CHECK(mood_impact IN ('positive', 'neutral', 'negative')),
          arrival_time INTEGER NOT NULL,
          departure_time INTEGER,
          duration INTEGER,
          visit_frequency INTEGER DEFAULT 1,
          is_home INTEGER DEFAULT 0,
          is_work INTEGER DEFAULT 0,
          notes TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      // جدول الوجبات
      await db.execute('''
        CREATE TABLE meals (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          meal_type TEXT CHECK(meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')) NOT NULL,
          meal_time INTEGER NOT NULL,
          total_calories REAL DEFAULT 0,
          total_protein REAL DEFAULT 0,
          total_carbs REAL DEFAULT 0,
          total_fat REAL DEFAULT 0,
          mood_before TEXT,
          mood_after TEXT,
          notes TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      // جدول الأطعمة في الوجبات
      await db.execute('''
        CREATE TABLE meal_foods (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          meal_id INTEGER NOT NULL,
          food_name TEXT NOT NULL,
          quantity REAL NOT NULL,
          unit TEXT NOT NULL,
          calories_per_unit REAL DEFAULT 0,
          protein_per_unit REAL DEFAULT 0,
          carbs_per_unit REAL DEFAULT 0,
          fat_per_unit REAL DEFAULT 0,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (meal_id) REFERENCES meals (id) ON DELETE CASCADE
        )
      ''');

      // جدول الوزن
      await db.execute('''
        CREATE TABLE weight_entries (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          weight REAL NOT NULL,
          unit TEXT CHECK(unit IN ('kg', 'lbs')) DEFAULT 'kg',
          body_fat_percentage REAL,
          muscle_mass REAL,
          notes TEXT,
          created_at INTEGER NOT NULL,
          UNIQUE(date)
        )
      ''');

      // جدول الإشعارات
      await db.execute('''
        CREATE TABLE notifications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          body TEXT NOT NULL,
          type TEXT NOT NULL,
          category TEXT,
          data TEXT,
          scheduled_time INTEGER,
          sent_time INTEGER,
          is_sent INTEGER DEFAULT 0,
          is_read INTEGER DEFAULT 0,
          created_at INTEGER NOT NULL
        )
      ''');

      // جدول الملاحظات والرؤى
      await db.execute('''
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

      // جدول الإعدادات
      await db.execute('''
        CREATE TABLE app_settings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          key TEXT NOT NULL UNIQUE,
          value TEXT NOT NULL,
          value_type TEXT CHECK(value_type IN ('string', 'int', 'double', 'bool', 'json')) DEFAULT 'string',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      // جدول بيانات الحساسات الخام
      await db.execute('''
        CREATE TABLE sensor_data (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sensor_type TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          value_x REAL,
          value_y REAL,
          value_z REAL,
          accuracy INTEGER,
          processed INTEGER DEFAULT 0,
          created_at INTEGER NOT NULL
        )
      ''');

      // ═══════════════════════════════════════════════════════════
      // جداول نظام الاختبارات (تُحمّل من السيرفر + تُحفظ محلياً)
      // ═══════════════════════════════════════════════════════════

      // الاختبارات (كاش من السيرفر)
      await db.execute('''
        CREATE TABLE cached_assessments (
          id INTEGER PRIMARY KEY,
          rotation_id INTEGER NOT NULL,
          title TEXT,
          title_ar TEXT,
          description TEXT,
          description_ar TEXT,
          category TEXT,
          scoring_type TEXT DEFAULT 'sum',
          max_score REAL,
          start_date TEXT,
          end_date TEXT,
          fetched_at INTEGER NOT NULL
        )
      ''');

      // الأسئلة (كاش من السيرفر)
      await db.execute('''
        CREATE TABLE cached_questions (
          id INTEGER PRIMARY KEY,
          assessment_id INTEGER NOT NULL,
          question_text TEXT NOT NULL,
          question_text_ar TEXT,
          display_type TEXT DEFAULT 'radio_list',
          display_order INTEGER DEFAULT 0,
          is_required INTEGER DEFAULT 1,
          FOREIGN KEY (assessment_id) REFERENCES cached_assessments(id) ON DELETE CASCADE
        )
      ''');

      // الخيارات (كاش من السيرفر)
      await db.execute('''
        CREATE TABLE cached_options (
          id INTEGER PRIMARY KEY,
          question_id INTEGER NOT NULL,
          option_text TEXT NOT NULL,
          option_text_ar TEXT,
          option_value INTEGER NOT NULL,
          option_order INTEGER DEFAULT 0,
          emoji TEXT,
          icon_name TEXT,
          color_hex TEXT,
          FOREIGN KEY (question_id) REFERENCES cached_questions(id) ON DELETE CASCADE
        )
      ''');

      // جلسات إجابة المستخدم (محلية + sync)
      await db.execute('''
        CREATE TABLE assessment_sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          rotation_id INTEGER NOT NULL,
          server_session_id INTEGER,
          total_score REAL,
          max_possible_score REAL,
          score_percentage REAL,
          is_completed INTEGER DEFAULT 0,
          started_at INTEGER NOT NULL,
          completed_at INTEGER,
          synced INTEGER DEFAULT 0,
          last_sync_time INTEGER
        )
      ''');

      // إجابات المستخدم (محلية + sync)
      await db.execute('''
        CREATE TABLE assessment_responses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          session_id INTEGER NOT NULL,
          question_id INTEGER NOT NULL,
          selected_option_id INTEGER NOT NULL,
          response_value INTEGER NOT NULL,
          response_time_seconds INTEGER,
          answered_at INTEGER NOT NULL,
          FOREIGN KEY (session_id) REFERENCES assessment_sessions(id) ON DELETE CASCADE,
          UNIQUE(session_id, question_id)
        )
      ''');

      // إنشاء الفهارس
      await _createIndexes(db);

      // إدراج البيانات الافتراضية
      await _insertDefaultData(db);

      debugPrint('✅ تم إنشاء جميع الجداول بنجاح (الإصدار $version)');

    } catch (e) {
      debugPrint('❌ خطأ في إنشاء الجداول: $e');
      rethrow;
    }
  }

  Future<void> _createIndexes(Database db) async {
    debugPrint('📊 إنشاء الفهارس...');

    try {
      // فهارس التواريخ الأساسية
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sleep_sessions_date ON sleep_sessions(start_time)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_phone_usage_date ON phone_usage_sessions(date)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_phone_usage_start_time ON phone_usage_sessions(start_time)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_daily_activity_date ON daily_activity(date)');
      // daily_activities هو VIEW - لا يحتاج index
      await db.execute('CREATE INDEX IF NOT EXISTS idx_meals_date ON meals(date)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_weight_date ON weight_entries(date)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_insights_date ON insights(date)');

      // فهارس جداول التطبيقات
      await db.execute('CREATE INDEX IF NOT EXISTS idx_app_usage_entries_date ON app_usage_entries(date)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_app_usage_entries_package ON app_usage_entries(package_name)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_user_settings_key ON user_settings(key)');

      // فهارس المراقبة الساعية
      await db.execute('CREATE INDEX IF NOT EXISTS idx_hourly_usage_date_hour ON hourly_usage_tracking(date, hour)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_hourly_usage_package ON hourly_usage_tracking(package_name)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_hourly_usage_date ON hourly_usage_tracking(date)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_hourly_usage_time_range ON hourly_usage_tracking(start_time, end_time)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_hourly_current ON hourly_usage_tracking(is_current_hour)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_hourly_finalized ON hourly_usage_tracking(is_finalized)');

      // ✅ فهارس تتبع النوم
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sleep_sessions_start_time ON sleep_sessions(start_time)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sleep_sessions_confirmation_status ON sleep_sessions(user_confirmation_status)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sleep_sessions_confirmation ON sleep_sessions(user_confirmation)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sleep_interruptions_session ON sleep_interruptions(sleep_session_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sleep_interruptions_cause ON sleep_interruptions(cause)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sleep_goals_active ON sleep_goals(is_active)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_environmental_data_timestamp ON environmental_data(timestamp)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_environmental_data_phone_usage ON environmental_data(phone_screen_on)');

      // ✅ فهارس نظام التصنيف الذكي
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sleep_confidence ON sleep_sessions(confidence)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sleep_user_confirmed ON sleep_sessions(user_confirmed_sleep)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sleep_pre_activity ON sleep_sessions(has_pre_sleep_activity)');

      // ✅ فهارس تتبع التعديلات (v3)
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sleep_time_modified ON sleep_sessions(was_time_modified)');

      // فهارس العلاقات الخارجية
      await db.execute('CREATE INDEX IF NOT EXISTS idx_environmental_data_session ON environmental_data(sleep_session_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_app_usage_session ON app_usage(phone_session_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_activity_sessions_daily ON activity_sessions(daily_activity_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_meal_foods_meal ON meal_foods(meal_id)');

      // فهارس البحث
      await db.execute('CREATE INDEX IF NOT EXISTS idx_location_visits_coords ON location_visits(latitude, longitude)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sensor_data_type_time ON sensor_data(sensor_type, timestamp)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type, is_sent)');

      debugPrint('✅ تم إنشاء جميع الفهارس');
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء الفهارس: $e');
    }
  }

  Future<void> _insertDefaultData(Database db) async {
    debugPrint('💾 إدراج البيانات الافتراضية...');

    final now = DateTime.now().millisecondsSinceEpoch;

    try {
      // ✅ إعدادات افتراضية محدثة
      final defaultSettings = [
        {'key': 'app_version', 'value': '1.0.0'},
        {'key': 'user_setup_completed', 'value': 'false', 'value_type': 'bool'},
        {'key': 'sleep_tracking_enabled', 'value': 'true', 'value_type': 'bool'},
        {'key': 'auto_sleep_detection', 'value': 'true', 'value_type': 'bool'},
        {'key': 'sleep_goal_hours', 'value': '8', 'value_type': 'int'},
        {'key': 'sleep_window_start_hour', 'value': '21', 'value_type': 'int'},
        {'key': 'sleep_window_end_hour', 'value': '7', 'value_type': 'int'},
        {'key': 'sleep_detection_sensitivity', 'value': '0.7', 'value_type': 'double'},
        {'key': 'confirm_sleep_notifications', 'value': 'true', 'value_type': 'bool'},
        {'key': 'user_age', 'value': '25', 'value_type': 'int'},
        {'key': 'step_goal_daily', 'value': '10000', 'value_type': 'int'},
        {'key': 'daily_usage_goal', 'value': '240', 'value_type': 'int'},
        {'key': 'break_reminder_minutes', 'value': '30', 'value_type': 'int'},
        {'key': 'hourly_tracking_enabled', 'value': 'true', 'value_type': 'bool'},
        {'key': 'notification_enabled', 'value': 'true', 'value_type': 'bool'},
        {'key': 'theme_mode', 'value': 'system'},
        {'key': 'language', 'value': 'ar'},
        {'key': 'data_retention_days', 'value': '180', 'value_type': 'int'},
      ];

      for (final setting in defaultSettings) {
        try {
          await db.insert('app_settings', {
            ...setting,
            'value_type': setting['value_type'] ?? 'string',
            'created_at': now,
            'updated_at': now,
          });
        } catch (e) {
          debugPrint('تم تجاهل خطأ إدراج الإعداد: ${setting['key']}');
        }
      }

      // إعدادات المستخدم الافتراضية
      final defaultUserSettings = [
        {'key': 'daily_usage_goal', 'value': '240', 'value_type': 'int'},
        {'key': 'break_reminder_minutes', 'value': '30', 'value_type': 'int'},
        {'key': 'phone_tracking_enabled', 'value': 'true', 'value_type': 'bool'},
        {'key': 'excessive_usage_threshold', 'value': '480', 'value_type': 'int'},
        {'key': 'hourly_tracking_enabled', 'value': 'true', 'value_type': 'bool'},
      ];

      for (final setting in defaultUserSettings) {
        try {
          await db.insert('user_settings', {
            ...setting,
            'value_type': setting['value_type'] ?? 'string',
            'created_at': now,
            'updated_at': now,
          });
        } catch (e) {
          debugPrint('تم تجاهل خطأ إدراج إعداد المستخدم: ${setting['key']}');
        }
      }

      // ✅ إنشاء هدف نوم افتراضي
      try {
        await db.insert('sleep_goals', {
          'user_age': 25,
          'recommended_hours': 8.0,
          'sleep_window_start': 21,
          'sleep_window_end': 7,
          'is_active': 1,
          'created_at': now,
          'updated_at': now,
        });
        debugPrint('✅ تم إنشاء هدف النوم الافتراضي');
      } catch (e) {
        debugPrint('تم تجاهل خطأ إنشاء هدف النوم الافتراضي: $e');
      }

      debugPrint('✅ تم إدراج البيانات الافتراضية');
    } catch (e) {
      debugPrint('❌ خطأ في إدراج البيانات الافتراضية: $e');
    }
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    debugPrint('🔄 ترقية قاعدة البيانات من $oldVersion إلى $newVersion');

    try {
      // ════════════════════════════════════════════════════════════
      // 🆕 الترقية من النسخة 1 إلى 2 - نظام التصنيف الذكي
      // ════════════════════════════════════════════════════════════
      if (oldVersion < 2) {
        debugPrint('📦 تطبيق ترقية النسخة 2: نظام التصنيف الذكي...');

        // إضافة الحقول الجديدة لجدول sleep_sessions
        await addColumnIfNotExists(
          db,
          'sleep_sessions',
          'confidence',
          'TEXT DEFAULT "uncertain"',
        );

        await addColumnIfNotExists(
          db,
          'sleep_sessions',
          'has_pre_sleep_activity',
          'INTEGER DEFAULT 0',
        );

        await addColumnIfNotExists(
          db,
          'sleep_sessions',
          'last_phone_usage',
          'INTEGER',
        );

        await addColumnIfNotExists(
          db,
          'sleep_sessions',
          'last_steps_count',
          'INTEGER',
        );

        await addColumnIfNotExists(
          db,
          'sleep_sessions',
          'user_confirmed_sleep',
          'INTEGER DEFAULT 0',
        );

        await addColumnIfNotExists(
          db,
          'sleep_sessions',
          'confirmation_time',
          'INTEGER',
        );

        // إنشاء الفهارس الجديدة
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_sleep_confidence 
          ON sleep_sessions(confidence)
        ''');

        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_sleep_user_confirmed 
          ON sleep_sessions(user_confirmed_sleep)
        ''');

        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_sleep_pre_activity 
          ON sleep_sessions(has_pre_sleep_activity)
        ''');

        debugPrint('✅ تم تطبيق ترقية النسخة 2 بنجاح');
      }

      // ════════════════════════════════════════════════════════════
      // 🆕 الترقية من النسخة 2 إلى 3 - تتبع تعديلات الأوقات
      // ════════════════════════════════════════════════════════════
      if (oldVersion < 3) {
        debugPrint('📦 تطبيق ترقية النسخة 3: تتبع تعديلات الأوقات...');

        // إضافة الحقول الجديدة لتتبع التعديلات
        await addColumnIfNotExists(
          db,
          'sleep_sessions',
          'original_start_time',
          'INTEGER',
        );

        await addColumnIfNotExists(
          db,
          'sleep_sessions',
          'original_end_time',
          'INTEGER',
        );

        await addColumnIfNotExists(
          db,
          'sleep_sessions',
          'was_time_modified',
          'INTEGER DEFAULT 0',
        );

        // إنشاء الفهرس الجديد
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_sleep_time_modified 
          ON sleep_sessions(was_time_modified)
        ''');

        debugPrint('✅ تم تطبيق ترقية النسخة 3 بنجاح');
      }

      // ════════════════════════════════════════════════════════════
      // 🆕 الترقية من النسخة 3 إلى 4 - حفظ أهداف النشاط
      // ════════════════════════════════════════════════════════════
      if (oldVersion < 4) {
        debugPrint('📦 تطبيق ترقية النسخة 4: حفظ أهداف النشاط...');

        // إضافة حقول الأهداف لجدول daily_activity
        await addColumnIfNotExists(
          db,
          'daily_activity',
          'goal_steps',
          'INTEGER DEFAULT 10000',
        );

        await addColumnIfNotExists(
          db,
          'daily_activity',
          'goal_distance',
          'REAL DEFAULT 8.0',
        );

        await addColumnIfNotExists(
          db,
          'daily_activity',
          'goal_calories',
          'REAL DEFAULT 500.0',
        );

        // إنشاء فهارس للأهداف (اختياري - للبحث السريع)
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_activity_goals 
          ON daily_activity(goal_steps, goal_distance, goal_calories)
        ''');

        debugPrint('✅ تم تطبيق ترقية النسخة 4 بنجاح');
      }

      // في المستقبل، يمكن إضافة ترقيات أخرى هنا:
      // if (oldVersion < 5) { ... }

      // ════════════════════════════════════════════════════════════
      // 🆕 الترقية من النسخة 4 إلى 5 - Sync Support
      // ════════════════════════════════════════════════════════════
      if (oldVersion < 5) {
        debugPrint('📦 تطبيق ترقية النسخة 5: Sync Tracking...');

        try {
          // قائمة الجداول المحتاجة sync
          final tables = [
            'daily_activity',
            'sleep_sessions',
            'app_usage_entries',
            'simple_meals',
            'hourly_usage_entries',
          ];

          // إضافة حقول sync لكل جدول
          for (final table in tables) {
            await addColumnIfNotExists(db, table, 'synced', 'INTEGER DEFAULT 0');
            await addColumnIfNotExists(db, table, 'last_sync_time', 'INTEGER');
          }

          // إضافة indexes للبحث السريع
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_activity_synced ON daily_activity(synced)'
          );
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_sleep_synced ON sleep_sessions(synced)'
          );
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_usage_synced ON app_usage_entries(synced)'
          );
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_meals_synced ON simple_meals(synced)'
          );

          debugPrint('✅ تم تطبيق ترقية النسخة 5 بنجاح - Sync Tracking جاهز!');

        } catch (e) {
          debugPrint('❌ خطأ في ترقية النسخة 5: $e');
          rethrow;
        }
      }

      // ════════════════════════════════════════════════════════════
      // 🆕 الترقية من النسخة 5 إلى 6 - توحيد جداول النشاط
      // ════════════════════════════════════════════════════════════
      if (oldVersion < 6) {
        debugPrint('📦 تطبيق ترقية النسخة 6: توحيد daily_activity/daily_activities...');

        try {
          // فحص إذا كان daily_activities جدول حقيقي (وليس VIEW)
          final tableCheck = await db.rawQuery(
            "SELECT type FROM sqlite_master WHERE name='daily_activities'"
          );

          if (tableCheck.isNotEmpty && tableCheck.first['type'] == 'table') {
            // نقل أي بيانات فريدة من daily_activities إلى daily_activity
            try {
              await db.execute('''
                INSERT OR IGNORE INTO daily_activity 
                (date, total_steps, distance_meters, calories_burned, active_minutes,
                 average_speed, floors_climbed, activity_breakdown, activity_calories,
                 activity_score, duration, distance, calories, steps, activity_type,
                 is_completed, intensity_score, sedentary_minutes, fitness_score,
                 goal_steps, goal_distance, goal_calories, created_at, updated_at)
                SELECT date, total_steps, distance_meters, calories_burned, active_minutes,
                 average_speed, floors_climbed, activity_breakdown, activity_calories,
                 activity_score, duration, distance, calories, steps, activity_type,
                 is_completed, intensity_score, sedentary_minutes, fitness_score,
                 goal_steps, goal_distance, goal_calories, created_at, updated_at
                FROM daily_activities
                WHERE date NOT IN (SELECT date FROM daily_activity)
              ''');
              debugPrint('✅ تم نقل البيانات الفريدة من daily_activities');
            } catch (e) {
              debugPrint('⚠️ تجاهل خطأ نقل البيانات: $e');
            }

            // حذف الجدول القديم
            await db.execute('DROP TABLE IF EXISTS daily_activities');
            debugPrint('🗑️ تم حذف جدول daily_activities القديم');
          } else if (tableCheck.isNotEmpty && tableCheck.first['type'] == 'view') {
            // حذف VIEW القديم لإعادة إنشائه
            await db.execute('DROP VIEW IF EXISTS daily_activities');
          }

          // إنشاء VIEW جديد
          await db.execute('''
            CREATE VIEW IF NOT EXISTS daily_activities AS
            SELECT * FROM daily_activity
          ''');
          debugPrint('✅ تم إنشاء VIEW daily_activities → daily_activity');

          // إضافة synced لجدول location_visits
          await addColumnIfNotExists(db, 'location_visits', 'synced', 'INTEGER DEFAULT 0');
          await addColumnIfNotExists(db, 'location_visits', 'last_sync_time', 'INTEGER');

          // إنشاء جداول الاختبارات (إذا لم تكن موجودة)
          await db.execute('''
            CREATE TABLE IF NOT EXISTS cached_assessments (
              id INTEGER PRIMARY KEY, rotation_id INTEGER NOT NULL,
              title TEXT, title_ar TEXT, description TEXT, description_ar TEXT,
              category TEXT, scoring_type TEXT DEFAULT 'sum', max_score REAL,
              start_date TEXT, end_date TEXT, fetched_at INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS cached_questions (
              id INTEGER PRIMARY KEY, assessment_id INTEGER NOT NULL,
              question_text TEXT NOT NULL, question_text_ar TEXT,
              display_type TEXT DEFAULT 'radio_list', display_order INTEGER DEFAULT 0,
              is_required INTEGER DEFAULT 1
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS cached_options (
              id INTEGER PRIMARY KEY, question_id INTEGER NOT NULL,
              option_text TEXT NOT NULL, option_text_ar TEXT,
              option_value INTEGER NOT NULL, option_order INTEGER DEFAULT 0,
              emoji TEXT, icon_name TEXT, color_hex TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS assessment_sessions (
              id INTEGER PRIMARY KEY AUTOINCREMENT, rotation_id INTEGER NOT NULL,
              server_session_id INTEGER, total_score REAL, max_possible_score REAL,
              score_percentage REAL, is_completed INTEGER DEFAULT 0,
              started_at INTEGER NOT NULL, completed_at INTEGER,
              synced INTEGER DEFAULT 0, last_sync_time INTEGER
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS assessment_responses (
              id INTEGER PRIMARY KEY AUTOINCREMENT, session_id INTEGER NOT NULL,
              question_id INTEGER NOT NULL, selected_option_id INTEGER NOT NULL,
              response_value INTEGER NOT NULL, response_time_seconds INTEGER,
              answered_at INTEGER NOT NULL, UNIQUE(session_id, question_id)
            )
          ''');

          debugPrint('✅ تم تطبيق ترقية النسخة 6 بنجاح');
        } catch (e) {
          debugPrint('❌ خطأ في ترقية النسخة 6: $e');
          // لا نعمل rethrow هنا - التطبيق يمكن أن يعمل بدون هذه الترقية
        }
      }

    } catch (e) {
      debugPrint('❌ خطأ في ترقية قاعدة البيانات: $e');
      rethrow;
    }
  }

  // ✅ الدوال المفقودة - تم استعادتها

  Future<bool> columnExists(Database db, String tableName, String columnName) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info($tableName)');
      return columns.any((column) => column['name'] == columnName);
    } catch (e) {
      debugPrint('❌ خطأ في فحص العمود $columnName في $tableName: $e');
      return false;
    }
  }

  Future<void> addColumnIfNotExists(
      Database db,
      String tableName,
      String columnName,
      String columnDefinition,
      ) async {
    try {
      final exists = await columnExists(db, tableName, columnName);
      if (!exists) {
        await db.execute('ALTER TABLE $tableName ADD COLUMN $columnName $columnDefinition');
        debugPrint('✅ تم إضافة العمود $columnName إلى $tableName');
      } else {
        debugPrint('⏭️ العمود $columnName موجود مسبقاً في $tableName');
      }
    } catch (e) {
      debugPrint('⚠️ فشل في إضافة العمود $columnName إلى $tableName: $e');
    }
  }

  Future<bool> tableExists(String tableName) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [tableName]
      );
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('❌ خطأ في فحص وجود الجدول $tableName: $e');
      return false;
    }
  }

  // ✅ دالة createTableIfNotExists
  Future<void> createTableIfNotExists(String tableName, String createTableSQL) async {
    try {
      final db = await database;
      final exists = await tableExists(tableName);

      if (!exists) {
        await db.execute(createTableSQL);
        debugPrint('✅ تم إنشاء جدول $tableName');
      } else {
        debugPrint('⏭️ جدول $tableName موجود مسبقاً');
      }
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء الجدول $tableName: $e');
    }
  }

  // ✅ دالة updateHourlyTrackingTable
  Future<void> updateHourlyTrackingTable() async {
    try {
      debugPrint('🔧 تحديث جدول hourly_usage_tracking...');
      final db = await database;

      // التحقق من وجود الأعمدة المطلوبة وإضافتها إن لم تكن موجودة
      await addColumnIfNotExists(db, 'hourly_usage_tracking', 'is_current_hour', 'INTEGER DEFAULT 0');
      await addColumnIfNotExists(db, 'hourly_usage_tracking', 'last_sync_time', 'INTEGER');
      await addColumnIfNotExists(db, 'hourly_usage_tracking', 'data_source', 'TEXT DEFAULT "live"');
      await addColumnIfNotExists(db, 'hourly_usage_tracking', 'is_finalized', 'INTEGER DEFAULT 0');

      // إنشاء الفهارس إذا لم تكن موجودة
      await db.execute('CREATE INDEX IF NOT EXISTS idx_hourly_current ON hourly_usage_tracking(is_current_hour)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_hourly_finalized ON hourly_usage_tracking(is_finalized)');

      debugPrint('✅ تم تحديث جدول hourly_usage_tracking');
    } catch (e) {
      debugPrint('❌ خطأ في تحديث جدول hourly_usage_tracking: $e');
    }
  }

  // ✅ دالة performComprehensiveFix
  Future<void> performComprehensiveFix() async {
    try {
      debugPrint('🔧 بدء الإصلاح الشامل لقاعدة البيانات...');

      final db = await database;

      // 1. إصلاح جدول sleep_sessions
      debugPrint('🔧 إصلاح جدول sleep_sessions...');
      await addColumnIfNotExists(db, 'sleep_sessions', 'interruption_count', 'INTEGER DEFAULT 0');
      await addColumnIfNotExists(db, 'sleep_sessions', 'user_confirmation', 'TEXT DEFAULT "pending"');
      await addColumnIfNotExists(db, 'sleep_sessions', 'detection_confidence', 'REAL DEFAULT 0.8');
      await addColumnIfNotExists(db, 'sleep_sessions', 'phone_activations', 'INTEGER DEFAULT 0');
      await addColumnIfNotExists(db, 'sleep_sessions', 'user_confirmation_status', 'TEXT DEFAULT "pending"');

      // ✅ إضافة حقول التصنيف الذكي
      await addColumnIfNotExists(db, 'sleep_sessions', 'confidence', 'TEXT DEFAULT "uncertain"');
      await addColumnIfNotExists(db, 'sleep_sessions', 'has_pre_sleep_activity', 'INTEGER DEFAULT 0');
      await addColumnIfNotExists(db, 'sleep_sessions', 'last_phone_usage', 'INTEGER');
      await addColumnIfNotExists(db, 'sleep_sessions', 'last_steps_count', 'INTEGER');
      await addColumnIfNotExists(db, 'sleep_sessions', 'user_confirmed_sleep', 'INTEGER DEFAULT 0');
      await addColumnIfNotExists(db, 'sleep_sessions', 'confirmation_time', 'INTEGER');

      // ✅ إضافة حقول تتبع التعديلات (v3)
      await addColumnIfNotExists(db, 'sleep_sessions', 'original_start_time', 'INTEGER');
      await addColumnIfNotExists(db, 'sleep_sessions', 'original_end_time', 'INTEGER');
      await addColumnIfNotExists(db, 'sleep_sessions', 'was_time_modified', 'INTEGER DEFAULT 0');

      // 2. إصلاح جدول hourly_usage_tracking
      await updateHourlyTrackingTable();

      // 3. إصلاح جدول daily_activity
      debugPrint('🔧 إصلاح جدول daily_activity...');
      await addColumnIfNotExists(db, 'daily_activity', 'average_speed', 'REAL DEFAULT 0.0');
      await addColumnIfNotExists(db, 'daily_activity', 'activity_breakdown', 'TEXT DEFAULT "{}"');
      await addColumnIfNotExists(db, 'daily_activity', 'activity_calories', 'TEXT DEFAULT "{}"');
      await addColumnIfNotExists(db, 'daily_activity', 'sedentary_minutes', 'INTEGER DEFAULT 0');

      // 4. إصلاح جدول environmental_data
      debugPrint('🔧 إصلاح جدول environmental_data...');
      await addColumnIfNotExists(db, 'environmental_data', 'phone_screen_on', 'INTEGER DEFAULT 0');
      await addColumnIfNotExists(db, 'environmental_data', 'data_quality', 'REAL DEFAULT 1.0');

      // 5. التأكد من وجود جميع الجداول الضرورية
      final criticalTables = {
        'sleep_interruptions': '''
          CREATE TABLE sleep_interruptions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sleep_session_id INTEGER NOT NULL,
            interruption_start INTEGER NOT NULL,
            interruption_end INTEGER,
            duration INTEGER,
            cause TEXT CHECK(cause IN ('phone', 'movement', 'noise', 'external', 'unknown')) DEFAULT 'unknown',
            phone_apps_used TEXT,
            usage_details TEXT,
            recovery_quality REAL DEFAULT 0,
            impact_on_sleep REAL DEFAULT 0,
            created_at INTEGER NOT NULL,
            FOREIGN KEY (sleep_session_id) REFERENCES sleep_sessions (id) ON DELETE CASCADE
          )
        ''',
        'sleep_goals': '''
          CREATE TABLE sleep_goals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_age INTEGER NOT NULL,
            recommended_hours REAL NOT NULL,
            user_preferred_bedtime TEXT,
            user_preferred_wakeup TEXT,
            sleep_window_start INTEGER,
            sleep_window_end INTEGER,
            is_active INTEGER DEFAULT 1,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''',
      };

      for (final entry in criticalTables.entries) {
        await createTableIfNotExists(entry.key, entry.value);
      }

      // 6. إنشاء الفهارس المفقودة
      debugPrint('📊 إنشاء الفهارس المفقودة...');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sleep_sessions_confirmation ON sleep_sessions(user_confirmation)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sleep_sessions_confirmation_status ON sleep_sessions(user_confirmation_status)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_environmental_data_phone_usage ON environmental_data(phone_screen_on)');

      // ✅ فهارس التصنيف الذكي
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sleep_confidence ON sleep_sessions(confidence)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sleep_user_confirmed ON sleep_sessions(user_confirmed_sleep)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sleep_pre_activity ON sleep_sessions(has_pre_sleep_activity)');

      // ✅ فهارس تتبع التعديلات (v3)
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sleep_time_modified ON sleep_sessions(was_time_modified)');

      // 7. تحسين قاعدة البيانات
      await optimizeDatabase();

      debugPrint('✅ تم إكمال الإصلاح الشامل بنجاح');

    } catch (e) {
      debugPrint('❌ خطأ في الإصلاح الشامل: $e');
      rethrow;
    }
  }

  Future<void> cleanOldSleepData({int daysToKeep = 180}) async {
    try {
      debugPrint('🧹 تنظيف بيانات النوم القديمة (الاحتفاظ بـ $daysToKeep يوم)...');

      final db = await database;
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final cutoffTimestamp = cutoffDate.millisecondsSinceEpoch;

      final deletedSessions = await db.delete(
        'sleep_sessions',
        where: 'start_time < ?',
        whereArgs: [cutoffTimestamp],
      );

      if (deletedSessions > 0) {
        debugPrint('🗑️ تم حذف $deletedSessions جلسة نوم قديمة');
        await vacuum();
      }

      debugPrint('✅ تم تنظيف بيانات النوم');

    } catch (e) {
      debugPrint('❌ خطأ في تنظيف بيانات النوم القديمة: $e');
    }
  }

  Future<void> clearAllData() async {
    try {
      final db = await database;
      debugPrint('🗑️ مسح جميع البيانات...');

      final tables = [
        'sensor_data',
        'environmental_data',
        'sleep_interruptions',
        'sleep_sessions',
        'sleep_goals',
        'app_usage',
        'app_usage_entries',
        'hourly_usage_tracking',
        'phone_usage_sessions',
        'activity_sessions',
        'daily_activity',
        'location_visits',
        'meal_foods',
        'meals',
        'weight_entries',
        'notifications',
        'insights',
      ];

      for (final table in tables) {
        try {
          await db.delete(table);
        } catch (e) {
          debugPrint('تجاهل خطأ حذف جدول $table: $e');
        }
      }

      debugPrint('✅ تم مسح جميع البيانات');
    } catch (e) {
      debugPrint('❌ خطأ في مسح البيانات: $e');
      rethrow;
    }
  }

  Future<void> vacuum() async {
    try {
      final db = await database;
      await db.execute('VACUUM');
      debugPrint('🧹 تم ضغط قاعدة البيانات');
    } catch (e) {
      debugPrint('❌ خطأ في ضغط قاعدة البيانات: $e');
    }
  }

  Future<Map<String, int>> getDatabaseStats() async {
    try {
      final db = await database;

      final stats = <String, int>{};
      final tables = [
        'sleep_sessions',
        'sleep_interruptions',
        'sleep_goals',
        'environmental_data',
        'phone_usage_sessions',
        'app_usage',
        'app_usage_entries',
        'hourly_usage_tracking',
        'user_settings',
        'daily_activity',
        'activity_sessions',
        'location_visits',
        'meals',
        'meal_foods',
        'weight_entries',
        'notifications',
        'insights',
        'sensor_data',
      ];

      for (final table in tables) {
        try {
          final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
          stats[table] = result.first['count'] as int;
        } catch (e) {
          debugPrint('تجاهل خطأ احصائيات جدول $table: $e');
          stats[table] = 0;
        }
      }

      return stats;
    } catch (e) {
      debugPrint('❌ خطأ في إحصائيات قاعدة البيانات: $e');
      return {};
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
      debugPrint('🔐 تم إغلاق قاعدة البيانات');
    }
  }

  Future<void> recreateDatabase() async {
    try {
      await close();

      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, 'smart_psych.db');

      await deleteDatabase(path);
      debugPrint('🗑️ تم حذف قاعدة البيانات القديمة');

      _database = await _initDatabase();
      debugPrint('✅ تم إعادة إنشاء قاعدة البيانات بنجاح');

    } catch (e) {
      debugPrint('❌ خطأ في إعادة إنشاء قاعدة البيانات: $e');
      rethrow;
    }
  }

  Future<bool> checkDatabaseIntegrity() async {
    try {
      final db = await database;
      final result = await db.rawQuery('PRAGMA integrity_check');
      final isOk = result.isNotEmpty && result.first.values.first == 'ok';

      if (isOk) {
        debugPrint('✅ فحص سلامة قاعدة البيانات: سليمة');
      } else {
        debugPrint('⚠️ فحص سلامة قاعدة البيانات: مشاكل محتملة');
      }

      return isOk;
    } catch (e) {
      debugPrint('❌ خطأ في فحص سلامة قاعدة البيانات: $e');
      return false;
    }
  }

  Future<void> optimizeDatabase() async {
    try {
      final db = await database;
      await db.execute('ANALYZE');
      await db.execute('REINDEX');
      debugPrint('✅ تم تحسين أداء قاعدة البيانات');
    } catch (e) {
      debugPrint('❌ خطأ في تحسين قاعدة البيانات: $e');
    }
  }

  Future<Map<String, dynamic>> getDatabaseInfo() async {
    try {
      final db = await database;

      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, 'smart_psych.db');
      final file = await File(path).stat();

      final stats = await getDatabaseStats();

      final versionResult = await db.rawQuery('PRAGMA user_version');
      final version = versionResult.first['user_version'] as int;

      return {
        'database_path': path,
        'database_size_bytes': file.size,
        'database_size_mb': (file.size / (1024 * 1024)).toStringAsFixed(2),
        'version': version,
        'tables_count': stats.length,
        'total_records': stats.values.fold(0, (sum, count) => sum + count),
        'table_stats': stats,
        'created_at': file.changed.toIso8601String(),
        'last_modified': file.modified.toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على معلومات قاعدة البيانات: $e');
      return {};
    }
  }

  Future<void> cleanupOldData({int daysToKeep = 90}) async {
    try {
      debugPrint('🧹 بدء تنظيف البيانات القديمة...');

      final db = await database;
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final cutoffTimestamp = cutoffDate.millisecondsSinceEpoch;
      final cutoffDateStr = '${cutoffDate.year}-${cutoffDate.month.toString().padLeft(2, '0')}-${cutoffDate.day.toString().padLeft(2, '0')}';

      int totalDeleted = 0;

      final tablesToClean = [
        {'table': 'sensor_data', 'column': 'created_at', 'type': 'timestamp'},
        {'table': 'environmental_data', 'column': 'created_at', 'type': 'timestamp'},
        {'table': 'phone_usage_sessions', 'column': 'date', 'type': 'date'},
        {'table': 'app_usage_entries', 'column': 'date', 'type': 'date'},
        {'table': 'hourly_usage_tracking', 'column': 'date', 'type': 'date'},
        {'table': 'daily_activity', 'column': 'date', 'type': 'date'},
        {'table': 'notifications', 'column': 'created_at', 'type': 'timestamp'},
      ];

      for (final tableInfo in tablesToClean) {
        try {
          final table = tableInfo['table']!;
          final column = tableInfo['column']!;
          final type = tableInfo['type']!;

          int deleted = 0;
          if (type == 'timestamp') {
            deleted = await db.delete(
              table,
              where: '$column < ?',
              whereArgs: [cutoffTimestamp],
            );
          } else if (type == 'date') {
            deleted = await db.delete(
              table,
              where: '$column < ?',
              whereArgs: [cutoffDateStr],
            );
          }

          if (deleted > 0) {
            debugPrint('🗑️ تم حذف $deleted سجل من جدول $table');
            totalDeleted += deleted;
          }
        } catch (e) {
          debugPrint('تجاهل خطأ تنظيف جدول ${tableInfo['table']}: $e');
        }
      }

      if (totalDeleted > 0) {
        await vacuum();
        debugPrint('✅ تم تنظيف $totalDeleted سجل قديم وضغط قاعدة البيانات');
      } else {
        debugPrint('✅ لا توجد بيانات قديمة للتنظيف');
      }

    } catch (e) {
      debugPrint('❌ خطأ في تنظيف البيانات القديمة: $e');
    }
  }

  Future<String?> createBackup() async {
    try {
      debugPrint('💾 إنشاء نسخة احتياطية...');

      final documentsDirectory = await getApplicationDocumentsDirectory();
      final dbPath = join(documentsDirectory.path, 'smart_psych.db');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = join(documentsDirectory.path, 'smart_psych_backup_$timestamp.db');

      await close();

      final dbFile = File(dbPath);
      await dbFile.copy(backupPath);

      await database;

      debugPrint('✅ تم إنشاء نسخة احتياطية: $backupPath');
      return backupPath;

    } catch (e) {
      debugPrint('❌ خطأ في إنشاء النسخة الاحتياطية: $e');
      return null;
    }
  }

  Future<bool> restoreFromBackup(String backupPath) async {
    try {
      debugPrint('📥 استعادة من النسخة الاحتياطية...');

      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        debugPrint('❌ ملف النسخة الاحتياطية غير موجود');
        return false;
      }

      await close();

      final documentsDirectory = await getApplicationDocumentsDirectory();
      final dbPath = join(documentsDirectory.path, 'smart_psych.db');

      await backupFile.copy(dbPath);

      await database;

      debugPrint('✅ تم استعادة قاعدة البيانات من النسخة الاحتياطية');
      return true;

    } catch (e) {
      debugPrint('❌ خطأ في استعادة النسخة الاحتياطية: $e');
      return false;
    }
  }

  Future<void> resetDatabase() async {
    try {
      debugPrint('🔄 إعادة تعيين قاعدة البيانات...');

      await clearAllData();

      final db = await database;
      await _insertDefaultData(db);

      debugPrint('✅ تم إعادة تعيين قاعدة البيانات بنجاح');

    } catch (e) {
      debugPrint('❌ خطأ في إعادة تعيين قاعدة البيانات: $e');
      rethrow;
    }
  }
}