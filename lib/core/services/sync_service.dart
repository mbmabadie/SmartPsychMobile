// lib/core/services/sync_service.dart
// ✅ نظام مزامنة شامل - يستخدم /api/sync/all لرفع كل شيء دفعة واحدة

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../database/repositories/activity_repository.dart';
import '../database/repositories/sleep_repository.dart';
import '../database/repositories/phone_usage_repository.dart';
import '../database/repositories/location_repository.dart';
import '../database/repositories/nutrition_repository.dart';
import 'api_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  static SyncService get instance => _instance;

  SyncService._internal();

  final ApiService _api = ApiService.instance;
  final ActivityRepository _activityRepo = ActivityRepository();
  final SleepRepository _sleepRepo = SleepRepository();
  final PhoneUsageRepository _phoneUsageRepo = PhoneUsageRepository();
  final LocationRepository _locationRepo = LocationRepository();
  final NutritionRepository _nutritionRepo = NutritionRepository();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  Timer? _autoSyncTimer;

  // ═══════════════════════════════════════════════════════════
  // Auto Sync
  // ═══════════════════════════════════════════════════════════

  void startAutoSync({Duration interval = const Duration(minutes: 5)}) {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(interval, (timer) async {
      if (_api.isAuthenticated) {
        await syncAll();
      }
    });
    debugPrint('⏰ [Sync] بدأت المزامنة التلقائية (كل ${interval.inMinutes} دقائق)');
  }

  void stopAutoSync() {
    _autoSyncTimer?.cancel();
    debugPrint('⏹️ [Sync] توقفت المزامنة التلقائية');
  }

  // ═══════════════════════════════════════════════════════════
  // Sync All — رفع كل البيانات غير المرفوعة دفعة واحدة
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> syncAll() async {
    if (_isSyncing) {
      debugPrint('⚠️ [Sync] مزامنة قيد التنفيذ بالفعل');
      return {'success': false, 'message': 'مزامنة قيد التنفيذ'};
    }

    if (!_api.isAuthenticated) {
      debugPrint('❌ [Sync] المستخدم غير مسجل الدخول');
      return {'success': false, 'message': 'غير مسجل الدخول'};
    }

    try {
      _isSyncing = true;
      debugPrint('🔄 [Sync] بدء المزامنة الشاملة...');

      // 1. جمع كل البيانات غير المرفوعة
      final payload = <String, dynamic>{};

      // النشاط
      final unsyncedActivities = await _activityRepo.getUnsyncedActivities();
      if (unsyncedActivities.isNotEmpty) {
        payload['activities'] = unsyncedActivities.map((a) => {
          'date': a.date,
          'total_steps': a.totalSteps,
          'distance': a.distance,
          'calories_burned': a.caloriesBurned,
          'active_minutes': a.activeMinutes,
          'activity_type': a.activityType,
          'intensity_score': a.intensityScore,
          'goal_steps': a.goalSteps,
          'goal_distance': a.goalDistance,
          'goal_calories': a.goalCalories,
          'created_at': a.createdAt.millisecondsSinceEpoch,
          'updated_at': a.updatedAt.millisecondsSinceEpoch,
        }).toList();
      }

      // النوم
      final unsyncedSleep = await _sleepRepo.getUnsyncedSessions();
      if (unsyncedSleep.isNotEmpty) {
        payload['sleep_sessions'] = unsyncedSleep.map((s) => {
          'client_id': s.id,
          'start_time': s.startTime.millisecondsSinceEpoch,
          'end_time': s.endTime?.millisecondsSinceEpoch,
          'duration_minutes': s.duration?.inMinutes,
          'quality_score': s.qualityScore,
          'sleep_type': s.sleepType,
          'confidence': s.confidence.toDbString(),
          'overall_sleep_quality': s.overallSleepQuality,
          'sleep_efficiency': s.sleepEfficiency,
          'detection_confidence': s.detectionConfidence,
          'total_interruptions': s.totalInterruptions,
          'phone_activations': s.phoneActivations,
          'user_confirmation': s.userConfirmationStatus,
          'user_rating': s.userRating,
          'notes': s.notes,
          'is_completed': s.isCompleted,
          'created_at': s.createdAt.millisecondsSinceEpoch,
        }).toList();
      }

      // استخدام الهاتف
      final unsyncedPhone = await _phoneUsageRepo.getUnsyncedEntries();
      if (unsyncedPhone.isNotEmpty) {
        payload['phone_usage'] = unsyncedPhone.map((e) => {
          'date': e.date,
          'app_name': e.appName,
          'package_name': e.packageName,
          'total_usage_time': e.totalUsageTime.inMinutes,
          'open_count': e.openCount,
          'created_at': e.createdAt.millisecondsSinceEpoch,
        }).toList();
      }

      // المواقع
      try {
        final unsyncedLocations = await _locationRepo.getUnsyncedVisits();
        if (unsyncedLocations.isNotEmpty) {
          payload['locations'] = unsyncedLocations.map((l) => {
            'latitude': l.latitude,
            'longitude': l.longitude,
            'accuracy': l.accuracy,
            'place_name': l.placeName,
            'place_type': l.placeType,
            'mood_impact': l.moodImpact?.name,
            'arrival_time': l.arrivalTime.millisecondsSinceEpoch,
            'departure_time': l.departureTime?.millisecondsSinceEpoch,
            'duration_minutes': l.duration?.inMinutes,
            'is_home': l.isHome,
            'is_work': l.isWork,
            'created_at': l.createdAt.millisecondsSinceEpoch,
          }).toList();
        }
      } catch (e) {
        debugPrint('⚠️ [Sync] تجاهل خطأ المواقع: $e');
      }

      // الاختبارات
      try {
        final unsyncedAssessments = await _getUnsyncedAssessmentSessions();
        if (unsyncedAssessments.isNotEmpty) {
          // مزامنة الاختبارات عبر endpoint منفصل
          final assessmentResult = await _api.syncAssessmentResponses(unsyncedAssessments);
          if (assessmentResult['success'] == true) {
            await _markAssessmentSessionsSynced(unsyncedAssessments);
            debugPrint('✅ [Sync] تم مزامنة ${unsyncedAssessments.length} جلسة اختبار');
          }
        }
      } catch (e) {
        debugPrint('⚠️ [Sync] تجاهل خطأ الاختبارات: $e');
      }

      // 2. إذا ما في شي للرفع
      if (payload.isEmpty) {
        debugPrint('✅ [Sync] لا توجد بيانات جديدة للرفع');
        _lastSyncTime = DateTime.now();

        // جلب الاختبار النشط حتى لو ما في بيانات للرفع
        try {
          await fetchAndCacheActiveAssessment();
        } catch (e) {
          debugPrint('⚠️ [Sync] تجاهل خطأ جلب الاختبار: $e');
        }

        return {'success': true, 'total_synced': 0, 'message': 'لا توجد بيانات جديدة'};
      }

      // 3. رفع كل شيء دفعة واحدة
      debugPrint('📤 [Sync] رفع: ${payload.keys.join(", ")}');
      final result = await _api.syncAll(payload);

      if (result['success'] == true) {
        // 4. تحديث حالة المزامنة محلياً
        if (unsyncedActivities.isNotEmpty) {
          for (final a in unsyncedActivities) {
            await _activityRepo.markAsSynced(a.date);
          }
        }
        if (unsyncedSleep.isNotEmpty) {
          for (final s in unsyncedSleep) {
            await _sleepRepo.markAsSynced(s.id!);
          }
        }
        if (unsyncedPhone.isNotEmpty) {
          for (final e in unsyncedPhone) {
            await _phoneUsageRepo.markAsSynced(e.id!);
          }
        }

        _lastSyncTime = DateTime.now();
        final totalSynced = result['total_synced'] ?? 0;
        debugPrint('✅ [Sync] المزامنة اكتملت - تم رفع $totalSynced عنصر');

        // 5. جلب آخر اختبار نشط بعد الرفع الناجح
        try {
          await fetchAndCacheActiveAssessment();
        } catch (e) {
          debugPrint('⚠️ [Sync] تجاهل خطأ جلب الاختبار: $e');
        }

        return {
          'success': true,
          'total_synced': totalSynced,
          'results': result['data'],
          'sync_time': _lastSyncTime,
        };
      } else {
        debugPrint('❌ [Sync] فشل الرفع: ${result['message']}');
        return {'success': false, 'message': result['message']};
      }
    } catch (e) {
      debugPrint('❌ [Sync] خطأ في المزامنة: $e');
      return {'success': false, 'message': e.toString()};
    } finally {
      _isSyncing = false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Sync Individual Types (للاستخدام المنفرد)
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> syncActivities() async {
    try {
      final unsynced = await _activityRepo.getUnsyncedActivities();
      if (unsynced.isEmpty) return {'success': true, 'count': 0};

      final json = unsynced.map((a) => {
        'date': a.date,
        'total_steps': a.totalSteps,
        'distance': a.distance,
        'calories_burned': a.caloriesBurned,
        'goal_steps': a.goalSteps,
        'activity_type': a.activityType,
        'intensity_score': a.intensityScore,
        'active_minutes': a.activeMinutes,
      }).toList();

      final result = await _api.syncActivitiesBatch(json);
      if (result['success'] == true) {
        for (final a in unsynced) { await _activityRepo.markAsSynced(a.date); }
        return {'success': true, 'count': unsynced.length};
      }
      return {'success': false, 'message': result['message']};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> syncSleep() async {
    try {
      final unsynced = await _sleepRepo.getUnsyncedSessions();
      if (unsynced.isEmpty) return {'success': true, 'count': 0};

      final json = unsynced.map((s) => {
        'client_id': s.id,
        'start_time': s.startTime.millisecondsSinceEpoch,
        'end_time': s.endTime?.millisecondsSinceEpoch,
        'duration_minutes': s.duration?.inMinutes,
        'quality_score': s.qualityScore,
        'sleep_type': s.sleepType,
        'confidence': s.confidence.toDbString(),
        'is_completed': s.isCompleted,
      }).toList();

      final result = await _api.syncSleepBatch(json);
      if (result['success'] == true) {
        for (final s in unsynced) { await _sleepRepo.markAsSynced(s.id!); }
        return {'success': true, 'count': unsynced.length};
      }
      return {'success': false, 'message': result['message']};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> syncPhoneUsage() async {
    try {
      final unsynced = await _phoneUsageRepo.getUnsyncedEntries();
      if (unsynced.isEmpty) return {'success': true, 'count': 0};

      final json = unsynced.map((e) => {
        'date': e.date,
        'app_name': e.appName,
        'package_name': e.packageName,
        'total_usage_time': e.totalUsageTime.inMinutes,
        'open_count': e.openCount,
      }).toList();

      final result = await _api.syncPhoneUsageBatch(json);
      if (result['success'] == true) {
        for (final e in unsynced) { await _phoneUsageRepo.markAsSynced(e.id!); }
        return {'success': true, 'count': unsynced.length};
      }
      return {'success': false, 'message': result['message']};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Assessment Sync Helpers
  // ═══════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> _getUnsyncedAssessmentSessions() async {
    try {
      final db = await _dbHelper.database;
      final sessions = await db.query(
        'assessment_sessions',
        where: 'synced = 0 AND is_completed = 1',
      );

      final result = <Map<String, dynamic>>[];
      for (final s in sessions) {
        final responses = await db.query(
          'assessment_responses',
          where: 'session_id = ?',
          whereArgs: [s['id']],
        );

        result.add({
          'client_session_id': s['id'],
          'rotation_id': s['rotation_id'],
          'total_score': s['total_score'],
          'max_possible_score': s['max_possible_score'],
          'score_percentage': s['score_percentage'],
          'completed_at': s['completed_at'] != null
              ? DateTime.fromMillisecondsSinceEpoch(s['completed_at'] as int).toIso8601String()
              : null,
          'responses': responses.map((r) => {
            'question_id': r['question_id'],
            'selected_option_id': r['selected_option_id'],
            'response_value': r['response_value'],
            'response_time_seconds': r['response_time_seconds'],
          }).toList(),
        });
      }

      return result;
    } catch (e) {
      debugPrint('❌ خطأ في جلب جلسات الاختبارات غير المرفوعة: $e');
      return [];
    }
  }

  Future<void> _markAssessmentSessionsSynced(List<Map<String, dynamic>> sessions) async {
    try {
      final db = await _dbHelper.database;
      for (final s in sessions) {
        await db.update(
          'assessment_sessions',
          {'synced': 1, 'last_sync_time': DateTime.now().millisecondsSinceEpoch},
          where: 'id = ?',
          whereArgs: [s['client_session_id']],
        );
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحديث حالة المزامنة: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Fetch Active Assessment (تحميل الاختبار من السيرفر للكاش المحلي)
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> fetchAndCacheActiveAssessment() async {
    try {
      final result = await _api.getActiveAssessment();
      if (result['success'] != true || result['data'] == null) return null;

      final data = result['data'] as Map<String, dynamic>;
      final db = await _dbHelper.database;

      // حذف الكاش القديم
      await db.delete('cached_options');
      await db.delete('cached_questions');
      await db.delete('cached_assessments');

      // حفظ الاختبار
      await db.insert('cached_assessments', {
        'id': data['assessment_id'],
        'rotation_id': data['rotation_id'],
        'title': data['title'],
        'title_ar': data['title_ar'],
        'description': data['description'],
        'description_ar': data['description_ar'],
        'category': data['category'],
        'scoring_type': data['scoring_type'],
        'max_score': data['max_score'],
        'start_date': data['start_date'],
        'end_date': data['end_date'],
        'fetched_at': DateTime.now().millisecondsSinceEpoch,
      });

      // حفظ الأسئلة والخيارات
      final questions = data['questions'] as List<dynamic>? ?? [];
      for (final q in questions) {
        await db.insert('cached_questions', {
          'id': q['question_id'],
          'assessment_id': data['assessment_id'],
          'question_text': q['question_text'],
          'question_text_ar': q['question_text_ar'],
          'display_type': q['display_type'],
          'display_order': q['display_order'],
          'is_required': q['is_required'] == true ? 1 : 0,
        });

        final options = q['options'] as List<dynamic>? ?? [];
        for (final o in options) {
          await db.insert('cached_options', {
            'id': o['id'],
            'question_id': q['question_id'],
            'option_text': o['option_text'],
            'option_text_ar': o['option_text_ar'],
            'option_value': o['option_value'],
            'option_order': o['option_order'],
            'emoji': o['emoji'],
            'icon_name': o['icon_name'],
            'color_hex': o['color_hex'],
          });
        }
      }

      debugPrint('✅ تم تخزين الاختبار النشط محلياً (${questions.length} سؤال)');
      return data;
    } catch (e) {
      debugPrint('❌ خطأ في جلب الاختبار النشط: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Status & Info
  // ═══════════════════════════════════════════════════════════

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get autoSyncEnabled => _autoSyncTimer?.isActive ?? false;

  Map<String, dynamic> getSyncStatus() {
    return {
      'is_syncing': _isSyncing,
      'last_sync': _lastSyncTime?.toIso8601String(),
      'auto_sync_enabled': autoSyncEnabled,
      'is_authenticated': _api.isAuthenticated,
    };
  }

  Future<Map<String, int>> getPendingCounts() async {
    try {
      final activityCount = (await _activityRepo.getUnsyncedActivities()).length;
      final sleepCount = (await _sleepRepo.getUnsyncedSessions()).length;
      final phoneCount = (await _phoneUsageRepo.getUnsyncedEntries()).length;

      int assessmentCount = 0;
      try {
        final db = await _dbHelper.database;
        final result = await db.rawQuery(
          'SELECT COUNT(*) as count FROM assessment_sessions WHERE synced = 0 AND is_completed = 1'
        );
        assessmentCount = (result.first['count'] as int?) ?? 0;
      } catch (_) {}

      return {
        'activity': activityCount,
        'sleep': sleepCount,
        'phone_usage': phoneCount,
        'assessments': assessmentCount,
        'total': activityCount + sleepCount + phoneCount + assessmentCount,
      };
    } catch (e) {
      debugPrint('❌ خطأ في حساب البيانات المعلقة: $e');
      return {'total': 0};
    }
  }

  void dispose() {
    _autoSyncTimer?.cancel();
  }
}
