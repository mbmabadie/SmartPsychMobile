// lib/features/sleep_tracking/providers/sleep_tracking_provider.dart
// ✅ النسخة المُحدّثة مع:
// 1. عرض الجلسات المرفوضة في History
// 2. تتبع تعديلات الأوقات (originalStartTime, originalEndTime, wasTimeModified)

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/database_helper.dart';
import '../database/models/environmental_conditions.dart';
import '../database/models/sleep_models.dart';
import '../database/models/sleep_confidence.dart';
import '../database/repositories/sleep_repository.dart';
import '../services/notification_service.dart';
import '../services/insights_service.dart';
import '../services/sensor_service.dart';
import '../services/unified_tracking_service.dart';
import '../services/app_usage_service.dart';
import 'base/base_state.dart';
import 'base/base_provider.dart';
import 'sleep_tracking_state.dart';

class SleepTrackingProvider extends BaseProvider<SleepTrackingState>
    with PeriodicUpdateMixin<SleepTrackingState>, CacheMixin<SleepTrackingState> {

  // التبعيات الأساسية
  final SleepRepository _sleepRepo;
  final SensorService _sensorService;
  final NotificationService _notificationService;
  final InsightsService _insightsService;
  final UnifiedTrackingService _unifiedService;
  final AppUsageService _appUsageService;

  // المؤقتات والاشتراكات
  Timer? _detectionTimer;
  Timer? _environmentalTimer;
  Timer? _windowCheckTimer;
  Timer? _quickWakeCheckTimer;
  Timer? _sessionCleanupTimer;
  StreamSubscription<EnvironmentalConditions>? _environmentSubscription;

  // ⭐ Cooldown للإشعارات
  DateTime? _lastSleepNotification;

  // ⭐ متغيرات تتبع الضوء المستمر
  DateTime? _lastHighLightTime;
  double? _lastLightLevel;

  // ⭐ معاملات الكشف المُحسّنة
  static const Duration _detectionInterval = Duration(minutes: 3);
  static const double _sleepConfidenceThreshold = 0.55;
  static const double _wakeConfidenceThreshold = 0.30;

  // ⭐ معاملات النشاط
  static const int _maxStepsWhileSleeping = 50;
  static const int _wakeUpStepsThreshold = 70;
  static const Duration _stepsCheckDuration = Duration(minutes: 5);
  static const int _lightContinuityMinutes = 5;

  // ✅ معاملات نظام التصنيف الذكي
  static const Duration _humanEvidenceWindow = Duration(minutes: 15);
  static const int _minStepsForHumanEvidence = 10;

  SleepTrackingProvider({
    SleepRepository? sleepRepo,
    SensorService? sensorService,
    NotificationService? notificationService,
    InsightsService? insightsService,
    UnifiedTrackingService? unifiedService,
    AppUsageService? appUsageService,
  })  : _sleepRepo = sleepRepo ?? SleepRepository(),
        _sensorService = sensorService ?? SensorService.instance,
        _notificationService = notificationService ?? NotificationService.instance,
        _insightsService = insightsService ?? InsightsService.instance,
        _unifiedService = unifiedService ?? UnifiedTrackingService.instance,
        _appUsageService = appUsageService ?? AppUsageService.instance,
        super(SleepTrackingState.initial()) {
    debugPrint('🌙 تهيئة مزود تتبع النوم (مع نظام التصنيف الذكي)');
    _initializeProvider();
  }

  // ════════════════════════════════════════════════════════════
  // BaseProvider Overrides
  // ════════════════════════════════════════════════════════════

  @override
  SleepTrackingState _createLoadingState(bool isRefreshing) {
    return state.copyWith(
      loadingState: isRefreshing ? LoadingState.refreshing : LoadingState.loading,
      error: null,
    );
  }

  @override
  SleepTrackingState _createSuccessState() {
    return state.copyWith(
      loadingState: LoadingState.success,
      error: null,
      hasData: true,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  SleepTrackingState _createErrorState(AppError error) {
    return state.copyWith(
      loadingState: LoadingState.error,
      error: error,
    );
  }

  @override
  SleepTrackingState _createIdleState() {
    return state.copyWith(
      loadingState: LoadingState.idle,
      error: null,
    );
  }

  @override
  Future<void> refreshData() async {
    try {
      debugPrint('🔄 تحديث جميع البيانات...');
      await _loadSettings();
      await _loadSleepWindowSettings();
      await _loadRecentSessions();
      await _checkPendingConfirmations();
      await _updateStatistics();
      debugPrint('✅ تم تحديث جميع البيانات');
    } catch (e) {
      debugPrint('❌ خطأ في التحديث: $e');
    }
  }

  @override
  Future<void> performPeriodicUpdate() async {
    if (state.isAutoTrackingActive) {
      debugPrint('🔄 تحديث دوري لتتبع النوم...');
      await _checkBackgroundServiceData();
      await _updateSleepWindowStatus();
      await _performSleepDetection();
      debugPrint('✅ اكتمل التحديث الدوري');
    }
  }

  // ════════════════════════════════════════════════════════════
  // 🧹 Session Cleanup Timer
  // ════════════════════════════════════════════════════════════

  void _startSessionCleanupTimer() {
    _sessionCleanupTimer?.cancel();

    debugPrint('⏰ [Cleanup] بدء Timer: كل 15 دقيقة');

    _sessionCleanupTimer = Timer.periodic(
      const Duration(minutes: 15),
          (_) async {
        await _cleanupOldActiveSessions();
      },
    );
  }

  Future<void> _cleanupOldActiveSessions() async {
    try {
      if (!state.hasActiveSession) return;

      final sessionAge = DateTime.now().difference(state.currentSession!.startTime);

      debugPrint('🧹 [Cleanup] فحص الجلسة النشطة...');
      debugPrint('   - ID: ${state.currentSession!.id}');
      debugPrint('   - العمر: ${sessionAge.inHours}h ${sessionAge.inMinutes % 60}m');

      // ✅ إنهاء الجلسات القديمة جداً (أكتر من 12 ساعة)
      if (sessionAge.inHours >= 12) {
        debugPrint('⚠️ [Cleanup] جلسة معلقة قديمة جداً!');
        debugPrint('   - إنهاء تلقائي...');

        // تخمين وقت استيقاظ معقول (8 ساعات من البداية)
        final estimatedEnd = state.currentSession!.startTime.add(Duration(hours: 8));

        final completedSession = state.currentSession!.copyWith(
          endTime: estimatedEnd,
          duration: Duration(hours: 8),
          isCompleted: true,
          confidence: SleepConfidence.uncertain,
          notes: 'تم إنهاؤها تلقائياً - جلسة معلقة',
          updatedAt: DateTime.now(),
        );

        if (completedSession.id != null) {
          await _sleepRepo.updateSleepSession(completedSession);
          await _sleepRepo.clearActiveSessionId();
        }

        setState(state.copyWith(
          currentSession: null,
          currentSleepState: SleepState.awake,
        ));

        debugPrint('✅ [Cleanup] تم إنهاء الجلسة المعلقة');

      } else {
        debugPrint('✓ [Cleanup] الجلسة ضمن الحد الطبيعي');
      }

    } catch (e, stack) {
      debugPrint('❌ [Cleanup] خطأ في التنظيف: $e');
      debugPrint('Stack: $stack');
    }
  }

  bool _shouldRequireConfirmation(SleepConfidence confidence, Duration duration) {
    if (confidence != SleepConfidence.probable &&
        confidence != SleepConfidence.uncertain) {
      return false;
    }

    if (duration.inMinutes < 15) {
      return false;
    }

    return true;
  }

  Future<void> _sendPendingConfirmationNotification(SleepSession session) async {
    try {
      final duration = session.duration;
      if (duration == null) return;

      final startTime = _formatTime(session.startTime);
      final endTime = session.endTime != null ? _formatTime(session.endTime!) : '';

      debugPrint('📢 إرسال إشعار تأكيد للجلسة ${session.id}');

      await _notificationService.showNotification(
        id: 4004,
        title: '🤔 تأكيد جلسة النوم',
        body: 'هل كنت نائماً من $startTime إلى $endTime؟',
        channelId: NotificationService.channelSleep,
        payload: {
          'type': 'confirm_sleep',
          'session_id': session.id.toString(),
          'start_time': session.startTime.toIso8601String(),
          'end_time': session.endTime?.toIso8601String() ?? '',
        },
      );

      debugPrint('✅ تم إرسال إشعار التأكيد');

    } catch (e) {
      debugPrint('❌ خطأ في إرسال إشعار التأكيد: $e');
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // ════════════════════════════════════════════════════════════
  // 🆕 نظام التصنيف الذكي
  // ════════════════════════════════════════════════════════════

  Future<SleepConfidence> _calculateSleepConfidence({
    required DateTime startTime,
    required DateTime endTime,
    required Duration duration,
    required bool hasPreSleepActivity,
  }) async {
    try {
      debugPrint('\n╔══════════════════════════════════════════════╗');
      debugPrint('║  🧠 حساب التصنيف الذكي                      ║');
      debugPrint('╚══════════════════════════════════════════════╝');

      final durationHours = duration.inMinutes / 60.0;
      final isNighttime = _isNighttime(startTime);

      debugPrint('📋 معلومات الجلسة:');
      debugPrint('   - البداية: ${startTime.toString().substring(11, 16)}');
      debugPrint('   - المدة: ${durationHours.toStringAsFixed(1)}h');
      debugPrint('   - التوقيت: ${isNighttime ? "ليلي 🌙" : "نهاري ☀️"}');
      debugPrint('   - دلائل نشاط: ${hasPreSleepActivity ? "✅ موجودة" : "❌ غير موجودة"}');

      // 1️⃣ نوم ليلي (21:00-07:00)
      if (isNighttime) {
        debugPrint('\n1️⃣ نوم ليلي - تطبيق قواعد الليل:');

        if (durationHours >= 3.0) {
          debugPrint('   ✅ مدة ≥3h → Confirmed');
          return SleepConfidence.confirmed;
        } else if (durationHours >= 0.5) {
          debugPrint('   🟡 مدة 30m-3h → Probable');
          return SleepConfidence.probable;
        } else {
          debugPrint('   ⚠️ مدة <30m → Uncertain');
          return SleepConfidence.uncertain;
        }
      }

      // 2️⃣ نوم نهاري (07:00-21:00)
      debugPrint('\n2️⃣ نوم نهاري - فحص دلائل النشاط:');

      if (!hasPreSleepActivity) {
        debugPrint('   ❌ لا توجد دلائل → Phone Left');
        return SleepConfidence.phoneLeft;
      }

      debugPrint('   ✅ توجد دلائل → تطبيق قواعد النهار:');

      if (durationHours >= 2.0) {
        debugPrint('   ✅ مدة ≥2h → Confirmed');
        return SleepConfidence.confirmed;
      } else if (durationHours >= 0.33) {
        debugPrint('   🟡 مدة 20m-2h → Probable');
        return SleepConfidence.probable;
      } else {
        debugPrint('   ⚠️ مدة <20m → Uncertain');
        return SleepConfidence.uncertain;
      }

    } catch (e, stack) {
      debugPrint('❌ خطأ في حساب التصنيف: $e');
      debugPrint('Stack: $stack');
      return SleepConfidence.uncertain;
    }
  }

  Future<bool> _checkHumanEvidence(DateTime sleepStart) async {
    try {
      debugPrint('\n   🔍 فحص دلائل النشاط البشري (آخر 15 دقيقة):');

      final windowEnd = sleepStart;
      final windowStart = sleepStart.subtract(_humanEvidenceWindow);

      int evidenceScore = 0;
      final evidenceList = <String>[];

      final lastPhoneUsage = await _getLastPhoneUsage(windowEnd);

      if (lastPhoneUsage != null) {
        final timeDiff = windowEnd.difference(lastPhoneUsage);

        if (timeDiff.inMinutes <= 15) {
          evidenceScore += 2;
          evidenceList.add('📱 استخدام الهاتف (${timeDiff.inMinutes}m قبل)');
          debugPrint('      ✅ [+2] استخدام هاتف حديث');
        }
      } else {
        debugPrint('      ⚠️ [+0] لا يوجد استخدام للهاتف');
      }

      final stepsInWindow = await _getStepsInWindow(windowStart, windowEnd);

      if (stepsInWindow > _minStepsForHumanEvidence) {
        evidenceScore += 1;
        evidenceList.add('🚶 خطوات ($stepsInWindow خطوة)');
        debugPrint('      ✅ [+1] نشاط مشي ($stepsInWindow خطوة)');
      } else if (stepsInWindow > 0) {
        debugPrint('      ⚠️ [+0] خطوات قليلة ($stepsInWindow خطوة)');
      } else {
        debugPrint('      ⚠️ [+0] لا يوجد نشاط مشي');
      }

      final hasEvidence = evidenceScore > 0;

      debugPrint('\n   📊 النتيجة:');
      debugPrint('      النقاط: $evidenceScore');

      if (hasEvidence) {
        debugPrint('      ✅ توجد دلائل نشاط بشري');
        debugPrint('      الدلائل: ${evidenceList.join(", ")}');
      } else {
        debugPrint('      ❌ لا توجد دلائل نشاط بشري');
      }

      return hasEvidence;

    } catch (e, stack) {
      debugPrint('❌ خطأ في فحص دلائل النشاط: $e');
      debugPrint('Stack: $stack');
      return false;
    }
  }

  Future<DateTime?> _getLastPhoneUsage(DateTime beforeTime) async {
    try {
      final todayUsage = await _appUsageService.getTodaysUsage();

      if (todayUsage.isEmpty) return null;

      DateTime? lastUsage;

      for (final entry in todayUsage) {
        final lastUsedTime = entry.lastUsedTime;

        if (lastUsedTime != null && lastUsedTime.isBefore(beforeTime)) {
          if (lastUsage == null || lastUsedTime.isAfter(lastUsage)) {
            lastUsage = lastUsedTime;
          }
        }
      }

      return lastUsage;

    } catch (e) {
      debugPrint('❌ خطأ في الحصول على آخر استخدام للهاتف: $e');
      return null;
    }
  }

  Future<int> _getStepsInWindow(DateTime start, DateTime end) async {
    try {
      final currentData = await _unifiedService.getTodayData();
      final currentSteps = currentData['steps'] as int? ?? 0;

      final now = DateTime.now();
      final dayStart = DateTime(now.year, now.month, now.day);

      final totalDayMinutes = now.difference(dayStart).inMinutes;
      final windowMinutes = end.difference(start).inMinutes;

      if (totalDayMinutes == 0) return 0;

      final estimatedSteps = (currentSteps * windowMinutes / totalDayMinutes).round();

      return estimatedSteps;

    } catch (e) {
      debugPrint('❌ خطأ في حساب الخطوات في النافذة: $e');
      return 0;
    }
  }

  bool _isNighttime(DateTime time) {
    final hour = time.hour;
    return hour >= 21 || hour < 7;
  }

  // ════════════════════════════════════════════════════════════
  // Background Service Data Check
  // ════════════════════════════════════════════════════════════

  Future<void> _checkBackgroundServiceData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final bgSleepDetected = prefs.getBool('bg_sleep_detected') ?? false;
      final bgSleepTime = prefs.getInt('bg_sleep_detected_time') ?? 0;

      if (bgSleepDetected && !state.hasActiveSession) {
        final detectionTime = DateTime.fromMillisecondsSinceEpoch(bgSleepTime);
        final timeSince = DateTime.now().difference(detectionTime);

        if (timeSince.inMinutes < 5) {
          debugPrint('😴 BackgroundService كشف نوم! بدء جلسة...');
          await _onSleepDetected(0.85);
          await prefs.setBool('bg_sleep_detected', false);
        }
      }

      final bgWakeDetected = prefs.getBool('bg_wake_detected') ?? false;
      final bgWakeTime = prefs.getInt('bg_wake_detected_time') ?? 0;

      if (bgWakeDetected && state.hasActiveSession) {
        final wakeTime = DateTime.fromMillisecondsSinceEpoch(bgWakeTime);
        final timeSince = DateTime.now().difference(wakeTime);

        if (timeSince.inMinutes < 5) {
          debugPrint('🌅 BackgroundService كشف استيقاظ! إنهاء جلسة...');
          await _onWakeDetected(0.85);
          await prefs.setBool('bg_wake_detected', false);
        }
      }

    } catch (e) {
      debugPrint('❌ خطأ في قراءة بيانات BackgroundService: $e');
    }
  }

  // ════════════════════════════════════════════════════════════
  // ✅ الخطوات - مع الحماية من Glitches
  // ════════════════════════════════════════════════════════════

  Future<int> _getRecentSteps({required int minutes}) async {
    try {
      debugPrint('🔍 فحص الخطوات في آخر $minutes دقيقة...');

      final currentData = await _unifiedService.getTodayData();
      final currentSteps = currentData['steps'] as int? ?? 0;

      debugPrint('   📊 الخطوات الحالية: $currentSteps');

      final prefs = await SharedPreferences.getInstance();
      final key = 'sleep_steps_check_${minutes}min';

      final savedDate = prefs.getString('sleep_steps_check_date');
      final today = DateTime.now().toIso8601String().split('T')[0];

      int previousSteps;

      if (savedDate == today) {
        previousSteps = prefs.getInt(key) ?? currentSteps;
        debugPrint('   📅 استخدام القيمة المحفوظة من اليوم');
      } else {
        previousSteps = currentSteps;
        await prefs.setString('sleep_steps_check_date', today);
        debugPrint('   📅 يوم جديد - إعادة تعيين baseline');
      }

      debugPrint('   📂 الخطوات السابقة: $previousSteps');

      if (currentSteps < previousSteps) {
        debugPrint('   ⚠️ [حماية] Step counter reset detected!');
        await prefs.setInt(key, currentSteps);
        debugPrint('   ✅ تم تجاهل القراءة - إرجاع 0 خطوة');
        return 0;
      }

      final difference = currentSteps - previousSteps;

      if (difference > 200) {
        debugPrint('   ⚠️ [حماية] زيادة غير منطقية: $difference خطوة');
        await prefs.setInt(key, currentSteps);
        debugPrint('   ✅ تم تجاهل القراءة - إرجاع 0 خطوة');
        return 0;
      }

      if (currentSteps == 0 && previousSteps > 0) {
        debugPrint('   ⚠️ [حماية] Current = 0 بينما كان $previousSteps');
        await prefs.setInt(key, 0);
        debugPrint('   ✅ تم تجاهل القراءة - إرجاع 0 خطوة');
        return 0;
      }

      final recentSteps = difference;
      debugPrint('   ➕ الخطوات الجديدة: $recentSteps');

      await prefs.setInt(key, currentSteps);

      if (recentSteps > _maxStepsWhileSleeping) {
        debugPrint('   🚶 نشاط مشي ملحوظ');
      } else {
        debugPrint('   ✅ نشاط مشي طبيعي');
      }

      return recentSteps;

    } catch (e, stack) {
      debugPrint('❌ خطأ في الحصول على الخطوات: $e');
      debugPrint('Stack: $stack');
      return 0;
    }
  }

  // ════════════════════════════════════════════════════════════
  // ✅ فحص الاستيقاظ والنشاط
  // ════════════════════════════════════════════════════════════

  Future<bool> _isUserAwake() async {
    try {
      debugPrint('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🌅 فحص الاستيقاظ (نظام ذكي مع التصنيف)');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      if (state.hasActiveSession) {
        final duration = DateTime.now().difference(state.currentSession!.startTime);
        final confidence = state.currentSession!.confidence;

        // ✅ حماية ديناميكية حسب التصنيف (مخففة)
        int minDuration;
        if (confidence == SleepConfidence.phoneLeft ||
            confidence == SleepConfidence.uncertain) {
          minDuration = 10;
        } else if (confidence == SleepConfidence.probable) {
          minDuration = 15;
        } else {
          minDuration = 20;
        }

        if (duration.inMinutes < minDuration) {
          debugPrint('⏸️ [حماية] نام ${duration.inMinutes}m فقط (الحد الأدنى: ${minDuration}m)');
          debugPrint('   التصنيف: ${confidence?.displayName ?? "غير محدد"}');
          return false;
        }

        debugPrint('📊 معلومات الجلسة:');
        debugPrint('   - المدة: ${duration.inHours}h ${duration.inMinutes % 60}m');
        debugPrint('   - التصنيف: ${confidence?.displayName ?? "غير محدد"} ${confidence?.emoji ?? ""}');
      }

      int wakeScore = 0;

      // ════════════════════════════════════════════════════════════
      // 1️⃣ فحص الخطوات
      // ════════════════════════════════════════════════════════════
      debugPrint('\n1️⃣ فحص الخطوات:');
      final steps = await _getRecentSteps(minutes: _stepsCheckDuration.inMinutes);

      if (steps > _wakeUpStepsThreshold) {
        wakeScore += 3;
        debugPrint('   🚶 [+3 نقاط] مشى $steps خطوة (نشاط واضح)');
      } else if (steps > _maxStepsWhileSleeping) {
        wakeScore += 1;
        debugPrint('   👣 [+1 نقطة] مشى $steps خطوة (نشاط متوسط)');
      } else if (steps > 0) {
        debugPrint('   🛌 [+0 نقاط] مشى $steps خطوة (حركة طبيعية)');
      } else {
        debugPrint('   😴 [+0 نقاط] لا حركة');
      }

      // ════════════════════════════════════════════════════════════
      // 2️⃣ فحص الضوء المستمر
      // ════════════════════════════════════════════════════════════
      debugPrint('\n2️⃣ فحص الضوء المستمر:');
      final conditions = await _sensorService.getCurrentConditions();

      if (conditions?.lightLevel != null) {
        final light = conditions!.lightLevel!;
        final now = DateTime.now();

        if (light > 150) {
          if (_lastHighLightTime != null && _lastLightLevel != null) {
            final duration = now.difference(_lastHighLightTime!);

            if (duration.inMinutes >= 2 && _lastLightLevel! > 150) {
              wakeScore += 1;
              debugPrint('   💡 [+1 نقطة] ضوء عالي مستمر: ${light.toStringAsFixed(0)} lux (${duration.inMinutes}m)');
            } else {
              debugPrint('   💡 [+0 نقاط] ضوء عالي لفترة قصيرة (${duration.inSeconds}s)');
            }
          } else {
            _lastHighLightTime = now;
            _lastLightLevel = light;
            debugPrint('   💡 [+0 نقاط] ضوء عالي جديد (${light.toStringAsFixed(0)} lux)');
          }
        } else {
          if (_lastHighLightTime != null) {
            debugPrint('   🌑 [reset] الضوء رجع منخفض (${light.toStringAsFixed(0)} lux)');
            _lastHighLightTime = null;
            _lastLightLevel = null;
          }
          debugPrint('   🌑 [+0 نقاط] ضوء منخفض (${light.toStringAsFixed(0)} lux)');
        }
      } else {
        debugPrint('   ⚠️ لا توجد بيانات ضوء');
      }

      // ════════════════════════════════════════════════════════════
      // 3️⃣ فحص مدة النوم
      // ════════════════════════════════════════════════════════════
      debugPrint('\n3️⃣ فحص مدة النوم:');

      if (state.hasActiveSession) {
        final duration = DateTime.now().difference(state.currentSession!.startTime);

        if (duration.inHours >= 5) {
          wakeScore += 1;
          debugPrint('   ⏰ [+1 نقطة] نام ${duration.inHours}h ${duration.inMinutes % 60}m (مدة طويلة)');
        } else {
          debugPrint('   ⏰ [+0 نقاط] نام ${duration.inHours}h ${duration.inMinutes % 60}m');
        }
      }

      // ════════════════════════════════════════════════════════════
      // 4️⃣ ✅ فحص التوقيت (محسّن!)
      // ════════════════════════════════════════════════════════════
      debugPrint('\n4️⃣ فحص التوقيت:');
      final hour = DateTime.now().hour;

      if (hour >= 6 && hour <= 10) {
        wakeScore += 1;
        debugPrint('   🌅 [+1 نقطة] وقت صباحي ($hour:00)');
      } else if (hour >= 14 && hour <= 18) {
        wakeScore += 1;
        debugPrint('   ☀️ [+1 نقطة] وقت نهاري ($hour:00 - محتمل استيقاظ من قيلولة)');
      } else if (hour >= 11 && hour <= 13) {
        debugPrint('   🕐 [+0 نقاط] قرب الظهر ($hour:00)');
      } else {
        debugPrint('   🕐 [+0 نقاط] وقت عادي ($hour:00)');
      }

      // ════════════════════════════════════════════════════════════
      // ✅ تحديد العتبة حسب التصنيف (مخففة!)
      // ════════════════════════════════════════════════════════════
      int requiredScore;
      final confidence = state.currentSession?.confidence;

      debugPrint('\n╔══════════════════════════════════════════════╗');
      debugPrint('║  📊 مجموع النقاط: $wakeScore / 6');

      if (confidence == SleepConfidence.phoneLeft) {
        requiredScore = 1;
        debugPrint('║  🎯 العتبة: $requiredScore (Phone Left - سهلة جداً)');
      } else if (confidence == SleepConfidence.uncertain) {
        requiredScore = 1;
        debugPrint('║  🎯 العتبة: $requiredScore (Uncertain - سهلة جداً)');
      } else if (confidence == SleepConfidence.probable) {
        requiredScore = 2;
        debugPrint('║  🎯 العتبة: $requiredScore (Probable - متوسطة)');
      } else {
        requiredScore = 3;
        debugPrint('║  🎯 العتبة: $requiredScore (Confirmed - متوسطة)');
      }

      final isAwake = wakeScore >= requiredScore;

      if (isAwake) {
        debugPrint('║  ✅ القرار: المستخدم استيقظ!');
        debugPrint('║  📈 النقاط ($wakeScore) >= العتبة ($requiredScore)');
      } else {
        debugPrint('║  ❌ القرار: المستخدم ما زال نائم');
        debugPrint('║  📉 النقاط ($wakeScore) < العتبة ($requiredScore)');
      }
      debugPrint('╚══════════════════════════════════════════════╝\n');

      return isAwake;

    } catch (e, stack) {
      debugPrint('❌ خطأ في فحص الاستيقاظ: $e');
      debugPrint('Stack: $stack');
      return false;
    }
  }

  Future<bool> _isUserActive() async {
    try {
      debugPrint('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🔍 فحص النشاط (لكشف النوم - بدون هاتف)');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      final recentSteps = await _getRecentSteps(minutes: _stepsCheckDuration.inMinutes);

      bool hasSignificantActivity = false;

      if (recentSteps > _maxStepsWhileSleeping) {
        debugPrint('🚶 [نشاط] مشى $recentSteps خطوة');
        hasSignificantActivity = true;
      } else if (recentSteps > 0) {
        debugPrint('👣 [عادي] مشى $recentSteps خطوة');
      } else {
        debugPrint('🛌 [سكون] لا حركة');
      }

      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      if (hasSignificantActivity) {
        debugPrint('🟢 النتيجة: المستخدم نشط');
      } else {
        debugPrint('🔵 النتيجة: المستخدم غير نشط (نائم محتمل)');
      }
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      return hasSignificantActivity;

    } catch (e) {
      debugPrint('❌ خطأ في فحص النشاط: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════
  // حساب ثقة النوم
  // ════════════════════════════════════════════════════════════

  Future<double> _calculateSleepConfidenceScore(EnvironmentalConditions environment) async {
    try {
      debugPrint('\n╔══════════════════════════════════════════════╗');
      debugPrint('║    🧮 حساب ثقة النوم - الفحص الشامل        ║');
      debugPrint('╚══════════════════════════════════════════════╝');

      double confidence = 0.0;

      debugPrint('\n1️⃣ فحص النشاط (35%):');

      final isActive = await _isUserActive();

      if (isActive) {
        confidence = 0.2;
        debugPrint('   ⚠️ المستخدم نشط → +20%');
      } else {
        confidence += 0.35;
        debugPrint('   ✅ المستخدم غير نشط → +35%');
      }

      debugPrint('\n2️⃣ فحص البيئة (30%):');

      final environmentScore = _calculateEnvironmentalQuality(environment);
      final envConfidence = (environmentScore / 10.0) * 0.3;
      confidence += envConfidence;

      debugPrint('   📊 نقاط البيئة: ${environmentScore.toStringAsFixed(1)}/10');
      debugPrint('   ➕ إضافة: ${(envConfidence * 100).toStringAsFixed(1)}%');

      debugPrint('\n3️⃣ فحص المثالية (20%):');

      if (environment.isOptimalForSleep != null && environment.isOptimalForSleep!) {
        confidence += 0.2;
        debugPrint('   ✅ بيئة مثالية → +20%');
      } else {
        debugPrint('   ⚠️ بيئة غير مثالية → +0%');
      }

      debugPrint('\n4️⃣ فحص التوقيت (10%):');

      final timingScore = _calculateTimingScore();
      final timingConfidence = timingScore * 0.1;
      confidence += timingConfidence;

      debugPrint('   ⏰ نقاط التوقيت: ${(timingScore * 100).toStringAsFixed(0)}%');
      debugPrint('   ➕ إضافة: ${(timingConfidence * 100).toStringAsFixed(1)}%');

      debugPrint('\n5️⃣ فحص الاستقرار (5%):');

      final stabilityScore = _calculateStabilityScore();
      final stabilityConfidence = stabilityScore * 0.05;
      confidence += stabilityConfidence;

      debugPrint('   📈 نقاط الاستقرار: ${(stabilityScore * 100).toStringAsFixed(0)}%');
      debugPrint('   ➕ إضافة: ${(stabilityConfidence * 100).toStringAsFixed(1)}%');

      final finalConfidence = confidence.clamp(0.0, 1.0);

      debugPrint('\n╔══════════════════════════════════════════════╗');
      debugPrint('║  📊 النتيجة: ${(finalConfidence * 100).toStringAsFixed(1)}%');
      debugPrint('║  🎯 العتبة: ${(_sleepConfidenceThreshold * 100).toStringAsFixed(0)}%');

      if (finalConfidence >= _sleepConfidenceThreshold) {
        debugPrint('║  ✅ كشف نوم محتمل!');
      } else {
        debugPrint('║  ⏸️ لم يتم الوصول للعتبة');
      }
      debugPrint('╚══════════════════════════════════════════════╝\n');

      if (finalConfidence < 0.40 && state.hasActiveSession) {
        debugPrint('⚠️ ثقة منخفضة جداً (${(finalConfidence * 100).toStringAsFixed(1)}%) - استيقاظ محتمل!');
        await _handleWakeDetection();
        return 0.0;
      }

      return finalConfidence;

    } catch (e, stack) {
      debugPrint('❌ خطأ في حساب ثقة النوم: $e');
      debugPrint('Stack: $stack');
      return 0.0;
    }
  }

  // ════════════════════════════════════════════════════════════
  // 🆕 وظائف معالجة الجلسات
  // ════════════════════════════════════════════════════════════

  Future<void> _handleWakeDetection() async {
    if (!state.hasActiveSession) return;

    debugPrint('\n╔══════════════════════════════════════════════╗');
    debugPrint('║  ⏰ كشف استيقاظ محتمل!                      ║');
    debugPrint('╚══════════════════════════════════════════════╝');
    debugPrint('🔄 انتقال: نائم → مستيقظ');

    await _onWakeDetected(0.85);
  }

  Future<void> _continueActiveSession() async {
    if (!state.hasActiveSession) return;

    debugPrint('🔄 تحديث الجلسة النشطة...');
    debugPrint('   - ID: ${state.currentSession!.id}');
    debugPrint('   - آخر تحديث: ${DateTime.now()}');

    final updatedSession = state.currentSession!.copyWith(
      updatedAt: DateTime.now(),
    );

    setState(state.copyWith(currentSession: updatedSession));

    if (updatedSession.id != null) {
      await _sleepRepo.updateSleepSession(updatedSession);
    }

    debugPrint('✅ تم تحديث الجلسة');
  }

  Future<void> _endActiveSessionAndStartNew() async {
    if (!state.hasActiveSession) return;

    final oldSession = state.currentSession!;

    debugPrint('🔄 إنهاء الجلسة القديمة وبدء جلسة جديدة...');
    debugPrint('   - الجلسة القديمة: ID=${oldSession.id}');

    final now = DateTime.now();
    final duration = now.difference(oldSession.startTime);
    final estimatedWake = oldSession.startTime.add(Duration(minutes: duration.inMinutes ~/ 2));

    debugPrint('   - وقت استيقاظ مقدر: $estimatedWake');

    final completedSession = oldSession.copyWith(
      endTime: estimatedWake,
      duration: estimatedWake.difference(oldSession.startTime),
      isCompleted: true,
      updatedAt: now,
    );

    if (completedSession.id != null) {
      await _sleepRepo.updateSleepSession(completedSession);
      await _sleepRepo.clearActiveSessionId();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_session_created_at');
      await prefs.remove('sleep_start_time');
      await prefs.setBool('is_sleeping', false);

      debugPrint('✅ تم إنهاء الجلسة القديمة: ID=${completedSession.id}');
      debugPrint('✅ تم تنظيف SharedPreferences');
    }

    setState(state.copyWith(currentSession: null));

    debugPrint('🆕 بدء جلسة نوم جديدة...');
    await _onSleepDetected(0.75);
  }

  Future<void> _cleanupOldSessionAndStartNew() async {
    if (!state.hasActiveSession) return;

    final oldSession = state.currentSession!;

    debugPrint('🗑️ جلسة قديمة جداً - تنظيف...');
    debugPrint('   - ID: ${oldSession.id}');
    debugPrint('   - العمر: ${DateTime.now().difference(oldSession.startTime).inHours}h');

    if (oldSession.id != null) {
      final cleanedSession = oldSession.copyWith(
        endTime: oldSession.startTime.add(Duration(hours: 8)),
        duration: Duration(hours: 8),
        isCompleted: true,
        confidence: SleepConfidence.uncertain,
        notes: 'تم إنهاؤها تلقائياً - جلسة قديمة جداً',
        updatedAt: DateTime.now(),
      );

      await _sleepRepo.updateSleepSession(cleanedSession);
      await _sleepRepo.clearActiveSessionId();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_session_created_at');
      await prefs.remove('sleep_start_time');
      await prefs.setBool('is_sleeping', false);

      debugPrint('✅ تم تنظيف الجلسة القديمة');
      debugPrint('✅ تم تنظيف SharedPreferences');
    }

    setState(state.copyWith(currentSession: null));

    debugPrint('🆕 بدء جلسة نوم جديدة...');
    await _onSleepDetected(0.70);
  }

  // ════════════════════════════════════════════════════════════
  // معالجة النوم والاستيقاظ
  // ════════════════════════════════════════════════════════════

  Future<void> _onSleepDetected(double confidence) async {
    try {
      if (state.hasActiveSession) {
        final sessionAge = DateTime.now().difference(state.currentSession!.startTime);

        debugPrint('⚠️ جلسة نوم نشطة بالفعل!');
        debugPrint('   - ID: ${state.currentSession?.id}');
        debugPrint('   - العمر: ${sessionAge.inHours}h ${sessionAge.inMinutes % 60}m');

        if (sessionAge < Duration(minutes: 30)) {
          debugPrint('🔄 جلسة حديثة - تحديث الجلسة...');
          await _continueActiveSession();
          return;
        } else if (sessionAge < Duration(hours: 3)) {
          debugPrint('🔄 فجوة معقولة (${sessionAge.inHours}h) - إنهاء وبدء جديدة...');
          await _endActiveSessionAndStartNew();
          return;
        } else {
          debugPrint('🗑️ جلسة قديمة جداً (${sessionAge.inHours}h) - تنظيف وبدء جديدة...');
          await _cleanupOldSessionAndStartNew();
          return;
        }
      }

      final now = DateTime.now();
      final timeSinceLastNotification = _lastSleepNotification != null
          ? now.difference(_lastSleepNotification!)
          : null;

      final shouldNotify = timeSinceLastNotification == null ||
          timeSinceLastNotification.inMinutes >= 30;

      if (!shouldNotify) {
        debugPrint('⏸️ تم إرسال إشعار مؤخراً (${timeSinceLastNotification?.inMinutes}m)');
        debugPrint('   ℹ️ سيتم إنشاء جلسة بدون إشعار');
      }

      debugPrint('\n╔══════════════════════════════════════════════╗');
      debugPrint('║  😴 كشف بداية النوم المحتمل                 ║');
      debugPrint('╚══════════════════════════════════════════════╝');

      final startTime = DateTime.now();

      final newSession = SleepSession(
        startTime: startTime,
        isCompleted: false,
        confidence: SleepConfidence.uncertain,
        hasPreSleepActivity: false,
        createdAt: startTime,
        updatedAt: startTime,
      );

      final sessionId = await _sleepRepo.insertSleepSession(newSession);
      if (sessionId <= 0) {
        debugPrint('❌ فشل حفظ الجلسة في قاعدة البيانات');
        return;
      }

      final savedSession = newSession.copyWith(id: sessionId);

      await _sleepRepo.saveActiveSessionId(sessionId);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('active_session_created_at', startTime.millisecondsSinceEpoch);
      await prefs.setInt('sleep_start_time', startTime.millisecondsSinceEpoch);
      await prefs.setBool('is_sleeping', true);

      debugPrint('💾 تم حفظ الجلسة في SharedPreferences');

      setState(state.copyWith(
        currentSession: savedSession,
        currentSleepState: SleepState.falling,
        sleepDetectionConfidence: confidence,
        lastUpdated: DateTime.now(),
      ));

      debugPrint('✅ تم حفظ الجلسة: ID=$sessionId');

      debugPrint('\n🔍 فحص دلائل النشاط قبل النوم...');

      final activityEvidence = await _checkPreSleepActivity(startTime);

      debugPrint('\n   📊 النتيجة:');
      debugPrint('      النقاط: ${activityEvidence['score']}');
      debugPrint('      ${activityEvidence['hasEvidence'] ? '✅ توجد دلائل نشاط بشري' : '❌ لا توجد دلائل نشاط'}');
      if (activityEvidence['description'] != null) {
        debugPrint('      الدلائل: ${activityEvidence['description']}');
      }

      await _sleepRepo.updatePreSleepActivity(
        sessionId: sessionId,
        hasActivity: activityEvidence['hasEvidence'] as bool,
        lastPhoneUsage: activityEvidence['lastPhoneUsage'] as DateTime?,
        lastStepsCount: activityEvidence['lastStepsCount'] as int?,
      );

      debugPrint('✅ تم تحديث معلومات النشاط قبل النوم للجلسة $sessionId');

      if (shouldNotify) {
        await _notificationService.showNotification(
          id: 4002,
          title: '😴 بداية نوم محتمل',
          body: 'تم كشف بداية جلسة نوم جديدة',
          channelId: NotificationService.channelSleep,
          payload: {
            'type': 'sleep_detected',
            'session_id': sessionId.toString(),
            'start_time': startTime.toIso8601String(),
            'confidence': confidence.toString(),
          },
        );
        _lastSleepNotification = now;
        debugPrint('📢 تم إرسال إشعار جديد');
      }

      debugPrint('✅ دلائل النشاط: ${activityEvidence['hasEvidence'] ? 'موجودة' : 'غير موجودة'}');

    } catch (e, stack) {
      debugPrint('❌ خطأ في معالجة كشف النوم: $e');
      debugPrint('📍 Stack: $stack');
    }
  }

  Future<Map<String, dynamic>> _checkPreSleepActivity(DateTime sleepStart) async {
    try {
      debugPrint('🔍 فحص دلائل النشاط قبل النوم (آخر 15 دقيقة)...');

      final windowEnd = sleepStart;
      final windowStart = sleepStart.subtract(_humanEvidenceWindow);

      int evidenceScore = 0;
      final evidenceList = <String>[];
      DateTime? lastPhoneUsage;
      int? lastStepsCount;

      lastPhoneUsage = await _getLastPhoneUsage(windowEnd);

      if (lastPhoneUsage != null) {
        final timeDiff = windowEnd.difference(lastPhoneUsage);

        if (timeDiff.inMinutes <= 15) {
          evidenceScore += 2;
          evidenceList.add('📱 استخدام هاتف (${timeDiff.inMinutes}m قبل)');
          debugPrint('   ✅ [+2] استخدام هاتف حديث');
        }
      } else {
        debugPrint('   ⚠️ [+0] لا يوجد استخدام للهاتف');
      }

      lastStepsCount = await _getStepsInWindow(windowStart, windowEnd);

      if (lastStepsCount > _minStepsForHumanEvidence) {
        evidenceScore += 1;
        evidenceList.add('🚶 خطوات ($lastStepsCount خطوة)');
        debugPrint('   ✅ [+1] نشاط مشي ($lastStepsCount خطوة)');
      } else if (lastStepsCount > 0) {
        debugPrint('   ⚠️ [+0] خطوات قليلة ($lastStepsCount خطوة)');
      } else {
        debugPrint('   ⚠️ [+0] لا يوجد نشاط مشي');
      }

      final hasEvidence = evidenceScore > 0;

      return {
        'hasEvidence': hasEvidence,
        'score': evidenceScore,
        'description': evidenceList.isNotEmpty ? evidenceList.join(', ') : null,
        'lastPhoneUsage': lastPhoneUsage,
        'lastStepsCount': lastStepsCount,
      };

    } catch (e, stack) {
      debugPrint('❌ خطأ في فحص دلائل النشاط: $e');
      debugPrint('Stack: $stack');
      return {
        'hasEvidence': false,
        'score': 0,
        'description': null,
        'lastPhoneUsage': null,
        'lastStepsCount': null,
      };
    }
  }

  Future<bool> _checkSessionOverlap(DateTime startTime) async {
    try {
      final activeSession = await _sleepRepo.getActiveSleepSession();
      if (activeSession != null) {
        debugPrint('⚠️ توجد جلسة نشطة بالفعل: ID=${activeSession.id}');
        return true;
      }

      final checkStart = startTime.subtract(const Duration(minutes: 30));
      final checkEnd = startTime.add(const Duration(minutes: 30));

      final sessions = await _sleepRepo.getSleepSessionsInRange(
        startDate: checkStart,
        endDate: checkEnd,
      );

      if (sessions.isNotEmpty) {
        debugPrint('⚠️ توجد ${sessions.length} جلسة في نفس الفترة');
        return true;
      }

      return false;

    } catch (e) {
      debugPrint('❌ خطأ في فحص التداخل: $e');
      return false;
    }
  }

  Future<void> _onWakeDetected(double confidence) async {
    try {
      debugPrint('\n╔══════════════════════════════════════════════╗');
      debugPrint('║  🌅 كشف الاستيقاظ - بدء معالجة الجلسة      ║');
      debugPrint('╚══════════════════════════════════════════════╝');

      if (state.hasActiveSession) {
        final sessionDuration = DateTime.now().difference(state.currentSession!.startTime);

        debugPrint('🔍 جلسة نوم نشطة موجودة');
        debugPrint('   - المدة: ${sessionDuration.inHours}h ${sessionDuration.inMinutes % 60}m');

        if (sessionDuration.inMinutes >= 20) {
          debugPrint('🔄 إنهاء الجلسة (مدة كافية)...');
          await _endCurrentSession();
          debugPrint('✅ تم إنهاء الجلسة');
        } else {
          debugPrint('⏸️ الجلسة قصيرة (<20m) - تجاهل');
        }
      } else {
        debugPrint('ℹ️ لا توجد جلسة نشطة');
      }

      setState(state.copyWith(
        currentSleepState: SleepState.awake,
        successMessage: 'تم كشف الاستيقاظ',
      ));

    } catch (e, stack) {
      debugPrint('❌ خطأ في معالجة كشف الاستيقاظ: $e');
      debugPrint('Stack: $stack');
    }
  }

  Future<void> _sendWakeUpNotification(SleepSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastWakeNotif = prefs.getInt('last_wake_notification_time') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (now - lastWakeNotif < Duration(minutes: 10).inMilliseconds) {
        debugPrint('⏸️ تم إرسال إشعار استيقاظ مؤخراً - تجاهل');
        return;
      }

      final duration = session.duration ?? Duration.zero;
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);

      final confidenceEmoji = session.confidence.emoji;
      final confidenceName = session.confidence.displayName;

      await _notificationService.showNotification(
        id: 4101,
        title: '🌅 صباح الخير!',
        body: 'نمت ${hours}h ${minutes}m - $confidenceEmoji $confidenceName',
        channelId: NotificationService.channelReminders,
        payload: {
          'type': 'wake_up_confirmation',
          'session_id': session.id?.toString() ?? '0',
          'confidence': session.confidence.toDbString(),
        },
      );

      await prefs.setInt('last_wake_notification_time', now);
      debugPrint('✅ تم إرسال إشعار استيقاظ');

    } catch (e) {
      debugPrint('❌ خطأ في إرسال إشعار الاستيقاظ: $e');
    }
  }

  // ════════════════════════════════════════════════════════════
  // كشف النوم الرئيسي
  // ════════════════════════════════════════════════════════════

  Future<void> _performSleepDetection() async {
    try {
      debugPrint('\n⏰ [Detection] فحص دوري - ${DateTime.now().toString().substring(11, 19)}');

      if (state.hasActiveSession) {
        final session = state.currentSession!;
        final duration = DateTime.now().difference(session.startTime);

        debugPrint('😴 [جلسة نشطة] فحص الاستيقاظ...');
        debugPrint('   - ID: ${session.id}');
        debugPrint('   - الحالة: ${state.currentSleepState.name}');
        debugPrint('   - المدة: ${duration.inHours}h ${duration.inMinutes % 60}m');

        debugPrint('🔍 استدعاء _isUserAwake()...');

        final isAwake = await _isUserAwake();

        debugPrint('📊 نتيجة _isUserAwake(): $isAwake');

        if (isAwake) {
          debugPrint('🌅 [كشف] المستخدم استيقظ!');
          setState(state.copyWith(currentSleepState: SleepState.waking));

          debugPrint('🔄 استدعاء _onWakeDetected()...');
          await _onWakeDetected(0.9);
          debugPrint('✅ انتهى _onWakeDetected()');
        } else {
          debugPrint('😴 [مستمر] المستخدم ما زال نائم');

          if (state.currentSleepState != SleepState.sleeping && duration.inMinutes >= 5) {
            setState(state.copyWith(currentSleepState: SleepState.sleeping));
            debugPrint('   🔄 تحديث الحالة: falling → sleeping');
          }
        }

        return;
      }

      final conditions = await _sensorService.getCurrentConditions();
      if (conditions == null) {
        debugPrint('⚠️ [تخطي] لا توجد بيانات حساسات');
        return;
      }

      if (!_validateEnvironmentalData(conditions)) {
        debugPrint('⚠️ [تجاهل] بيانات بيئية غير صحيحة');
        return;
      }

      final sleepConfidence = await _calculateSleepConfidenceScore(conditions);
      final newSleepState = _determineSleepState(sleepConfidence);

      setState(state.copyWith(
        sleepDetectionConfidence: sleepConfidence,
        currentSleepState: newSleepState,
        lastUpdated: DateTime.now(),
      ));

      await _handleSleepStateTransition(newSleepState, sleepConfidence);

    } catch (e, stack) {
      debugPrint('❌ خطأ في كشف النوم: $e');
      debugPrint('📍 Stack: $stack');
    }
  }

  Future<void> _handleSleepStateTransition(SleepState newState, double confidence) async {
    final previousState = state.currentSleepState;
    if (previousState == newState) return;

    debugPrint('🔄 انتقال: ${previousState.displayName} → ${newState.displayName}');

    switch (newState) {
      case SleepState.falling:
        if (previousState == SleepState.awake && !state.hasActiveSession) {
          await _onSleepDetected(confidence);
        }
        break;

      case SleepState.sleeping:
        if (previousState == SleepState.falling) {
          await _onSleepConfirmed(confidence);
        }
        break;

      case SleepState.awake:
        if (previousState != SleepState.awake) {
          await _onWakeDetected(confidence);
        }
        break;

      case SleepState.restless:
        await _onRestlessDetected();
        break;

      default:
        break;
    }
  }

  // ════════════════════════════════════════════════════════════
  // ✅ NEW: Session Recovery من Database
  // ════════════════════════════════════════════════════════════

  Future<void> _restoreOrCleanupActiveSession() async {
    try {
      debugPrint('🔍 البحث عن جلسات نشطة في قاعدة البيانات...');

      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;

      final sessions = await db.query(
        'sleep_sessions',
        where: 'is_completed = ?',
        whereArgs: [0],
        orderBy: 'start_time DESC',
        limit: 1,
      );

      if (sessions.isEmpty) {
        debugPrint('ℹ️ لا توجد جلسات نشطة في قاعدة البيانات');
        return;
      }

      final session = sessions.first;
      final sessionId = session['id'] as int;
      final startTime = session['start_time'] as int;
      final createdAt = session['created_at'] as int? ?? startTime;

      final now = DateTime.now();
      final created = DateTime.fromMillisecondsSinceEpoch(createdAt);
      final age = now.difference(created);

      debugPrint('🔍 وُجدت جلسة نشطة: ID=$sessionId');
      debugPrint('📅 تاريخ الإنشاء: ${_formatDateTime(created)}');
      debugPrint('⏱️ العمر: ${age.inHours}h ${age.inMinutes % 60}m');

      if (age.inHours >= 24) {
        debugPrint('⚠️ جلسة قديمة جداً (${age.inHours}h) - سيتم إنهاؤها');

        final start = DateTime.fromMillisecondsSinceEpoch(startTime);
        await _endOldSessionFromDB(sessionId, start, now);

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('active_sleep_session_id');
        await prefs.remove('active_session_created_at');
        await prefs.remove('sleep_start_time');
        await prefs.setBool('is_sleeping', false);

        debugPrint('✅ تم إنهاء الجلسة القديمة تلقائياً');

      } else if (age.inHours >= 12) {
        debugPrint('⚠️ جلسة قديمة (${age.inHours}h) - سيتم إنهاؤها');

        final start = DateTime.fromMillisecondsSinceEpoch(startTime);
        await _endOldSessionFromDB(sessionId, start, now);

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('active_sleep_session_id');
        await prefs.remove('active_session_created_at');
        await prefs.remove('sleep_start_time');
        await prefs.setBool('is_sleeping', false);

        debugPrint('✅ تم إنهاء الجلسة القديمة');

      } else {
        debugPrint('✅ استرجاع جلسة نشطة حديثة (${age.inHours}h)');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('active_sleep_session_id', sessionId);
        await prefs.setInt('active_session_created_at', createdAt);
        await prefs.setInt('sleep_start_time', startTime);
        await prefs.setBool('is_sleeping', true);

        final startDateTime = DateTime.fromMillisecondsSinceEpoch(startTime);

        final restoredSession = SleepSession(
          id: sessionId,
          startTime: startDateTime,
          isCompleted: false,
          createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
          updatedAt: DateTime.now(),
        );

        setState(state.copyWith(
          currentSession: restoredSession,
          currentSleepState: SleepState.sleeping,
        ));

        debugPrint('💾 تم استرجاع الجلسة إلى State:');
        debugPrint('   - Session ID: $sessionId');
        debugPrint('   - Start Time: ${_formatDateTime(startDateTime)}');
        debugPrint('   - Age: ${age.inHours}h ${age.inMinutes % 60}m');
        debugPrint('   ✅ currentSession موجودة في state الآن!');
      }

    } catch (e) {
      debugPrint('❌ خطأ في استرجاع/تنظيف الجلسات: $e');
    }
  }

  Future<void> _endOldSessionFromDB(int sessionId, DateTime start, DateTime end) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;

      final duration = end.difference(start);
      final hours = duration.inMinutes / 60.0;

      await db.update(
        'sleep_sessions',
        {
          'end_time': end.millisecondsSinceEpoch,
          'duration': duration.inMilliseconds,
          'is_completed': 1,
          'quality_score': _calculateSleepQuality(hours),
          'updated_at': end.millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [sessionId],
      );

      debugPrint('✅ تم إنهاء الجلسة: ID=$sessionId (${hours.toStringAsFixed(1)}h)');

    } catch (e) {
      debugPrint('❌ خطأ في إنهاء الجلسة: $e');
    }
  }

  double _calculateSleepQuality(double duration) {
    if (duration >= 7.0 && duration <= 9.0) return 9.0;
    if (duration >= 6.0 && duration <= 10.0) return 7.0;
    if (duration >= 5.0 && duration <= 11.0) return 5.0;
    return 3.0;
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // ════════════════════════════════════════════════════════════
  // باقي الدوال
  // ════════════════════════════════════════════════════════════

  Future<void> _initializeProvider() async {
    try {
      setState(_createLoadingState(false));

      final sensorInitialized = await _sensorService.initialize();
      if (!sensorInitialized) {
        throw Exception('فشل في تهيئة الحساسات');
      }

      if (!_unifiedService.isInitialized) {
        debugPrint('🔧 تهيئة UnifiedTrackingService...');
        await _unifiedService.initialize();
      }

      if (!_unifiedService.isTracking) {
        debugPrint('▶️ بدء تتبع الخطوات...');
        await _unifiedService.startTracking();
      }

      debugPrint('🔧 تهيئة AppUsageService...');
      await _appUsageService.initialize();

      await initializeAutoTracking();
      await _loadInitialData();

      setState(_createSuccessState());
      debugPrint('✅ تم تهيئة مزود تتبع النوم بنجاح');

    } catch (e) {
      debugPrint('❌ خطأ في تهيئة مزود تتبع النوم: $e');
      setState(_createErrorState(ServiceError(
        message: 'فشل في تهيئة نظام تتبع النوم: $e',
        code: 'SLEEP_INIT_FAILED',
      )));
    }
  }

  Future<void> _loadInitialData() async {
    try {
      final activeSession = state.currentSession;

      debugPrint('🔍 جلب الجلسات المعلقة...');

      final pendingSessions = await _sleepRepo.getPendingConfirmations();
      debugPrint('✅ تم جلب ${pendingSessions.length} جلسة معلقة');

      setState(state.copyWith(
        pendingConfirmations: pendingSessions,
        currentSession: activeSession,
        lastUpdated: DateTime.now(),
      ));

      debugPrint('✅ تم تحميل البيانات الأولية');

    } catch (e) {
      debugPrint('❌ خطأ في تحميل البيانات الأولية: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final goalHours = prefs.getInt('sleep_goal_hours') ?? 8;
      final startHour = prefs.getInt('sleep_window_start_hour') ?? 22;
      final startMinute = prefs.getInt('sleep_window_start_minute') ?? 0;
      final endHour = prefs.getInt('sleep_window_end_hour') ?? 7;
      final endMinute = prefs.getInt('sleep_window_end_minute') ?? 0;
      final adaptiveEnabled = prefs.getBool('adaptive_window_enabled') ?? true;
      final autoTrackingEnabled = prefs.getBool('auto_tracking_enabled') ?? false;

      setState(state.copyWith(
        sleepGoalHours: goalHours,
        sleepWindowStart: TimeOfDay(hour: startHour, minute: startMinute),
        sleepWindowEnd: TimeOfDay(hour: endHour, minute: endMinute),
        adaptiveWindowEnabled: adaptiveEnabled,
        isAutoTrackingActive: autoTrackingEnabled,
      ));

      debugPrint('✅ تم تحميل الإعدادات: Goal=$goalHours hours');
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الإعدادات: $e');
    }
  }

  Future<void> initializeAutoTracking() async {
    try {
      debugPrint('🚀 بدء نظام التتبع التلقائي للنوم (مع التصنيف الذكي)');

      await _restoreOrCleanupActiveSession();
      await _startSensorMonitoring();
      _startWindowCheck();
      _startSleepDetection();
      _startSessionCleanupTimer();

      debugPrint('✅ تم تفعيل Cleanup Timer (كل 15 دقيقة)');

      setState(state.copyWith(
        isAutoTrackingActive: true,
        successMessage: 'تم تفعيل التتبع التلقائي للنوم',
      ));

      await _notificationService.showNotification(
        id: 4001,
        title: '🌙 تتبع النوم التلقائي',
        body: 'تم تفعيل النظام الذكي مع التصنيف التلقائي',
        channelId: NotificationService.channelGeneral,
      );

      debugPrint('✅ تم تفعيل التتبع التلقائي مع نظام التصنيف الذكي');

    } catch (e) {
      debugPrint('❌ خطأ في تفعيل التتبع التلقائي: $e');
      throw ServiceError(
        message: 'فشل في تفعيل التتبع التلقائي: $e',
        code: 'AUTO_TRACKING_FAILED',
      );
    }
  }

  Future<void> stopAutoTracking() async {
    try {
      debugPrint('⏹️ إيقاف التتبع التلقائي للنوم');

      _detectionTimer?.cancel();
      _environmentalTimer?.cancel();
      _windowCheckTimer?.cancel();
      _quickWakeCheckTimer?.cancel();
      _sessionCleanupTimer?.cancel();

      await _stopSensorMonitoring();

      if (state.hasActiveSession) {
        await _endCurrentSession();
      }

      _lastHighLightTime = null;
      _lastLightLevel = null;

      setState(state.copyWith(
        isAutoTrackingActive: false,
        currentSleepState: SleepState.awake,
        sleepDetectionConfidence: 0.0,
      ));

      debugPrint('✅ تم إيقاف التتبع التلقائي');
    } catch (e) {
      debugPrint('❌ خطأ في إيقاف التتبع التلقائي: $e');
    }
  }

  Future<void> _startSensorMonitoring() async {
    try {
      final started = await _sensorService.startListening();
      if (!started) {
        throw Exception('فشل في بدء مراقبة الحساسات');
      }

      _environmentSubscription = _sensorService.environmentalStream.listen(
        _onEnvironmentalDataReceived,
        onError: _handleEnvironmentalDataError,
      );

      debugPrint('✅ تم بدء مراقبة الحساسات');
    } catch (e) {
      debugPrint('❌ خطأ في بدء مراقبة الحساسات: $e');
      rethrow;
    }
  }

  Future<void> _stopSensorMonitoring() async {
    try {
      await _sensorService.stopListening();
      await _environmentSubscription?.cancel();
      _environmentSubscription = null;
      debugPrint('✅ تم إيقاف مراقبة الحساسات');
    } catch (e) {
      debugPrint('❌ خطأ في إيقاف مراقبة الحساسات: $e');
    }
  }

  void _onEnvironmentalDataReceived(EnvironmentalConditions conditions) {
    try {
      if (!_validateEnvironmentalData(conditions)) return;

      final updatedHistory = [...state.environmentHistory, conditions];
      if (updatedHistory.length > 100) {
        updatedHistory.removeAt(0);
      }

      final qualityScore = _calculateEnvironmentalQuality(conditions);

      setState(state.copyWith(
        currentEnvironment: conditions,
        environmentHistory: updatedHistory,
        environmentalQualityScore: qualityScore,
        lastUpdated: DateTime.now(),
      ));

      if (state.hasActiveSession) {
        _saveEnvironmentalData(conditions);
      }

      if (kDebugMode && DateTime.now().second % 30 == 0) {
        debugPrint('📊 بيانات بيئية: '
            'ضوء: ${conditions.lightLevel?.toStringAsFixed(1) ?? 'N/A'} lux');
      }
    } catch (e) {
      debugPrint('❌ خطأ في معالجة البيانات البيئية: $e');
    }
  }

  bool _validateEnvironmentalData(EnvironmentalConditions conditions) {
    final now = DateTime.now();
    final timeDiff = now.difference(conditions.timestamp).abs();

    if (timeDiff.inHours > 1) return false;
    if (conditions.accuracy != null && conditions.accuracy! < 0.5) return false;

    return true;
  }

  void _handleEnvironmentalDataError(dynamic error, [StackTrace? stackTrace]) {
    debugPrint('❌ خطأ في البيانات البيئية: $error');

    setState(state.copyWith(
      error: ServiceError(
        message: 'خطأ مؤقت في البيانات البيئية',
        code: 'ENV_DATA_ERROR',
      ),
      lastUpdated: DateTime.now(),
    ));

    Timer(const Duration(seconds: 30), () {
      if (!isDisposed) {
        _restartSensorMonitoring();
      }
    });
  }

  Future<void> _restartSensorMonitoring() async {
    try {
      debugPrint('🔄 إعادة تشغيل مراقبة الحساسات...');
      await _stopSensorMonitoring();
      await Future.delayed(const Duration(seconds: 2));
      await _startSensorMonitoring();
      debugPrint('✅ تم إعادة تشغيل مراقبة الحساسات');
    } catch (e) {
      debugPrint('❌ فشل في إعادة تشغيل مراقبة الحساسات: $e');
    }
  }

  void _startSleepDetection() {
    _detectionTimer?.cancel();
    _quickWakeCheckTimer?.cancel();

    _detectionTimer = Timer.periodic(_detectionInterval, (timer) async {
      if (state.isAutoTrackingActive && !isDisposed) {
        await _performSleepDetection();
      }
    });

    debugPrint('⏰ بدء فحص النوم كل ${_detectionInterval.inMinutes} دقائق');

    _quickWakeCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (isDisposed) {
        timer.cancel();
        return;
      }

      if (state.hasActiveSession) {
        final duration = DateTime.now().difference(state.currentSession!.startTime);

        if (duration.inMinutes >= 5) {
          final isAwake = await _isUserAwake();

          if (isAwake) {
            debugPrint('🌅 [كشف سريع] المستخدم استيقظ!');
            setState(state.copyWith(currentSleepState: SleepState.waking));
            await _onWakeDetected(0.85);
          }
        }
      }
    });
  }

  double _calculateEnvironmentalQuality(EnvironmentalConditions conditions) {
    double score = 0.0;
    int factors = 0;

    if (conditions.lightLevel != null) {
      final lightScore = conditions.lightLevel! <= 5 ? 10.0 :
      conditions.lightLevel! <= 15 ? 8.0 :
      conditions.lightLevel! <= 30 ? 6.0 :
      conditions.lightLevel! <= 50 ? 4.0 : 2.0;
      score += lightScore;
      factors++;
    }

    if (conditions.noiseLevel != null) {
      final noiseScore = conditions.noiseLevel! <= 30 ? 10.0 :
      conditions.noiseLevel! <= 40 ? 8.0 :
      conditions.noiseLevel! <= 50 ? 6.0 :
      conditions.noiseLevel! <= 60 ? 4.0 : 2.0;
      score += noiseScore;
      factors++;
    }

    if (conditions.movementIntensity != null) {
      final movementScore = conditions.movementIntensity! <= 0.1 ? 10.0 :
      conditions.movementIntensity! <= 0.3 ? 8.0 :
      conditions.movementIntensity! <= 0.5 ? 6.0 :
      conditions.movementIntensity! <= 0.7 ? 4.0 : 2.0;
      score += movementScore;
      factors++;
    }

    return factors > 0 ? score / factors : 0.0;
  }

  double _calculateTimingScore() {
    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);

    if (state.isInSleepWindow) {
      return 1.0;
    } else {
      final hour = currentTime.hour;
      if ((hour >= 13 && hour <= 16) || (hour >= 20 && hour <= 23)) {
        return 0.6;
      } else {
        return 0.2;
      }
    }
  }

  double _calculateStabilityScore() {
    if (state.environmentHistory.length < 5) return 0.5;

    final recentHistory = state.environmentHistory.length > 5
        ? state.environmentHistory.sublist(state.environmentHistory.length - 5)
        : state.environmentHistory;

    double stabilityScore = 0.0;
    int factors = 0;

    final lightLevels = recentHistory
        .where((e) => e.lightLevel != null)
        .map((e) => e.lightLevel!)
        .toList();

    if (lightLevels.isNotEmpty) {
      final avgLight = lightLevels.reduce((a, b) => a + b) / lightLevels.length;
      final variance = lightLevels
          .map((l) => pow(l - avgLight, 2))
          .reduce((a, b) => a + b) / lightLevels.length;
      final lightStability = (1.0 - (variance / 100).clamp(0.0, 1.0));
      stabilityScore += lightStability;
      factors++;
    }

    final movementLevels = recentHistory
        .where((e) => e.movementIntensity != null)
        .map((e) => e.movementIntensity!)
        .toList();

    if (movementLevels.isNotEmpty) {
      final avgMovement = movementLevels.reduce((a, b) => a + b) / movementLevels.length;
      final variance = movementLevels
          .map((m) => pow(m - avgMovement, 2))
          .reduce((a, b) => a + b) / movementLevels.length;
      final movementStability = (1.0 - variance.clamp(0.0, 1.0));
      stabilityScore += movementStability;
      factors++;
    }

    return factors > 0 ? stabilityScore / factors : 0.5;
  }

  SleepState _determineSleepState(double confidence) {
    switch (state.currentSleepState) {
      case SleepState.awake:
        if (confidence >= _sleepConfidenceThreshold) {
          return SleepState.falling;
        }
        return SleepState.awake;

      case SleepState.falling:
        if (confidence >= 0.75) {
          return SleepState.sleeping;
        } else if (confidence < 0.4) {
          return SleepState.awake;
        }
        return SleepState.falling;

      case SleepState.sleeping:
        if (confidence < _wakeConfidenceThreshold) {
          return SleepState.restless;
        }
        return SleepState.sleeping;

      case SleepState.restless:
        if (confidence >= 0.75) {
          return SleepState.sleeping;
        } else if (confidence < 0.3) {
          return SleepState.waking;
        }
        return SleepState.restless;

      case SleepState.waking:
        if (confidence < 0.3) {
          return SleepState.awake;
        } else if (confidence > 0.6) {
          return SleepState.sleeping;
        }
        return SleepState.waking;
    }
  }

  Future<void> _onSleepConfirmed(double confidence) async {
    try {
      debugPrint('✅ تم تأكيد النوم (ثقة: ${(confidence * 100).round()}%)');

      if (state.hasActiveSession) {
        final updatedSession = state.currentSession!.copyWith(
          detectionConfidence: confidence,
          updatedAt: DateTime.now(),
        );

        setState(state.copyWith(currentSession: updatedSession));
        await _saveCurrentSession();
      }
    } catch (e) {
      debugPrint('❌ خطأ في تأكيد النوم: $e');
    }
  }

  Future<void> _onRestlessDetected() async {
    try {
      debugPrint('😖 تم كشف نوم متقطع');

      if (state.hasActiveSession) {
        final updatedSession = state.currentSession!.copyWith(
          totalInterruptions: (state.currentSession!.totalInterruptions) + 1,
          updatedAt: DateTime.now(),
        );

        setState(state.copyWith(
          currentSession: updatedSession,
          nightInterruptions: state.nightInterruptions + 1,
        ));
      }
    } catch (e) {
      debugPrint('❌ خطأ في معالجة النوم المتقطع: $e');
    }
  }

  Future<void> _saveCurrentSession() async {
    try {
      if (!state.hasActiveSession) return;

      final session = state.currentSession!;

      if (session.id == null) {
        final sessionId = await _sleepRepo.insertSleepSession(session);
        final updatedSession = session.copyWith(id: sessionId);
        setState(state.copyWith(currentSession: updatedSession));
      } else {
        await _sleepRepo.updateSleepSession(session);
      }

    } catch (e) {
      debugPrint('❌ خطأ في حفظ جلسة النوم: $e');
    }
  }

  Future<void> _endCurrentSession() async {
    try {
      final session = state.currentSession;
      if (session == null) {
        debugPrint('⚠️ لا توجد جلسة نشطة لإنهائها');
        return;
      }

      final endTime = DateTime.now();
      final duration = endTime.difference(session.startTime);

      debugPrint('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🔚 إنهاء جلسة النوم');
      debugPrint('   - ID: ${session.id}');
      debugPrint('   - المدة: ${duration.inHours}h ${duration.inMinutes % 60}m');

      final confidence = await _calculateSleepConfidence(
        startTime: session.startTime,
        endTime: endTime,
        duration: duration,
        hasPreSleepActivity: session.hasPreSleepActivity ?? false,
      );
      debugPrint('   - التصنيف: ${confidence.displayName} ${confidence.emoji}');

      final needsConfirmation = _shouldRequireConfirmation(confidence, duration);
      debugPrint('   - تحتاج تأكيد: ${needsConfirmation ? 'نعم' : 'لا'}');

      final completedSession = session.copyWith(
        endTime: endTime,
        duration: duration,
        isCompleted: true,
        confidence: confidence,
        updatedAt: endTime,
        userConfirmationStatus: needsConfirmation ? 'pending' : 'auto_confirmed',
      );

      await _sleepRepo.updateSleepSession(completedSession);
      await _sleepRepo.clearActiveSessionId();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_session_created_at');
      await prefs.remove('sleep_start_time');
      await prefs.setBool('is_sleeping', false);

      debugPrint('✅ تم إنهاء الجلسة في DB وSharedPreferences');

      setState(state.copyWith(
        currentSession: null,
        currentSleepState: SleepState.awake,
        successMessage: 'تم إنهاء جلسة النوم',
      ));

      debugPrint('✅ تم مسح currentSession من State');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      if (needsConfirmation) {
        await _sendPendingConfirmationNotification(completedSession);
      }

      await _loadRecentSessionsWithoutStateChange();
      await _checkPendingConfirmationsWithoutStateChange();

    } catch (e, stack) {
      debugPrint('❌ خطأ في إنهاء الجلسة: $e');
      debugPrint('Stack: $stack');
    }
  }

  Future<void> _loadRecentSessionsWithoutStateChange() async {
    try {
      final sessions = await _sleepRepo.getSleepSessionsInRange(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
      );

      setState(state.copyWith(
        recentSessions: sessions,
        currentSession: state.currentSession,
      ));

    } catch (e) {
      debugPrint('❌ خطأ في تحميل الجلسات: $e');
    }
  }

  Future<void> _checkPendingConfirmationsWithoutStateChange() async {
    try {
      final pending = await _sleepRepo.getPendingConfirmations();

      setState(state.copyWith(
        pendingConfirmations: pending,
        currentSession: state.currentSession,
      ));

    } catch (e) {
      debugPrint('❌ خطأ في فحص التأكيدات: $e');
    }
  }

  void _startWindowCheck() {
    _windowCheckTimer?.cancel();

    _windowCheckTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (!isDisposed) {
        await _updateSleepWindowStatus();
      }
    });

    debugPrint('⏰ بدء فحص النافذة الزمنية');
  }

  Future<void> _updateSleepWindowStatus() async {
    try {
      final now = DateTime.now();
      final currentTime = TimeOfDay.fromDateTime(now);
      final isInWindow = _isTimeInSleepWindow(currentTime);

      if (isInWindow != state.isInSleepWindow) {
        setState(state.copyWith(
          isInSleepWindow: isInWindow,
          lastUpdated: DateTime.now(),
        ));

        if (isInWindow) {
          debugPrint('🌙 دخول النافذة الزمنية');
          await _onEnterSleepWindow();
        } else {
          debugPrint('🌅 خروج من النافذة الزمنية');
          await _onExitSleepWindow();
        }
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحديث حالة النافذة: $e');
    }
  }

  bool _isTimeInSleepWindow(TimeOfDay currentTime) {
    final start = state.sleepWindowStart;
    final end = state.sleepWindowEnd;

    if (start.hour > end.hour) {
      return currentTime.hour >= start.hour || currentTime.hour < end.hour ||
          (currentTime.hour == start.hour && currentTime.minute >= start.minute) ||
          (currentTime.hour == end.hour && currentTime.minute < end.minute);
    } else {
      final currentMinutes = currentTime.hour * 60 + currentTime.minute;
      final startMinutes = start.hour * 60 + start.minute;
      final endMinutes = end.hour * 60 + end.minute;
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    }
  }

  Future<void> _onEnterSleepWindow() async {
    try {
      _detectionTimer?.cancel();
      _detectionTimer = Timer.periodic(const Duration(minutes: 2), (timer) async {
        if (state.isAutoTrackingActive && state.isInSleepWindow && !isDisposed) {
          await _performSleepDetection();
        }
      });

      debugPrint('🔍 زيادة تردد المراقبة في النافذة');
    } catch (e) {
      debugPrint('❌ خطأ في دخول النافذة: $e');
    }
  }

  Future<void> _onExitSleepWindow() async {
    try {
      _detectionTimer?.cancel();
      _detectionTimer = Timer.periodic(_detectionInterval, (timer) async {
        if (state.isAutoTrackingActive && !isDisposed) {
          await _performSleepDetection();
        }
      });

      debugPrint('🔍 تقليل تردد المراقبة خارج النافذة');
    } catch (e) {
      debugPrint('❌ خطأ في خروج النافذة: $e');
    }
  }

  Future<void> updateSleepWindow({
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    bool? adaptiveEnabled,
  }) async {
    try {
      setState(state.copyWith(
        sleepWindowStart: startTime,
        sleepWindowEnd: endTime,
        adaptiveWindowEnabled: adaptiveEnabled ?? state.adaptiveWindowEnabled,
        lastUpdated: DateTime.now(),
      ));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('sleep_window_start_hour', startTime.hour);
      await prefs.setInt('sleep_window_start_minute', startTime.minute);
      await prefs.setInt('sleep_window_end_hour', endTime.hour);
      await prefs.setInt('sleep_window_end_minute', endTime.minute);

      if (adaptiveEnabled != null) {
        await prefs.setBool('adaptive_window_enabled', adaptiveEnabled);
      }

      await _sleepRepo.updateSleepWindowSettings(
        startTime: startTime,
        endTime: endTime,
        adaptiveEnabled: adaptiveEnabled ?? state.adaptiveWindowEnabled,
      );

      await _updateSleepWindowStatus();

    } catch (e, stack) {
      debugPrint('❌ خطأ في تحديث النافذة: $e');
    }
  }

  Future<void> _loadRecentSessions() async {
    try {
      final sessions = await _sleepRepo.getSleepSessionsInRange(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
      );

      setState(state.copyWith(
        recentSessions: sessions,
        hasData: sessions.isNotEmpty,
      ));

    } catch (e) {
      debugPrint('❌ خطأ في تحميل الجلسات: $e');
    }
  }

  Future<void> _checkPendingConfirmations() async {
    try {
      final pending = await _sleepRepo.getPendingConfirmations();

      setState(state.copyWith(
        pendingConfirmations: pending,
      ));

      if (pending.isNotEmpty) {
        debugPrint('⏳ ${pending.length} جلسات في انتظار التأكيد');
        await _checkForDelayedConfirmations(pending);
      }
    } catch (e) {
      debugPrint('❌ خطأ في فحص التأكيدات: $e');
    }
  }

  Future<void> _checkForDelayedConfirmations(List<SleepSession> pending) async {
    try {
      final now = DateTime.now();

      for (final session in pending) {
        final sessionEnd = session.endTime ?? session.startTime;
        final timeSinceEnd = now.difference(sessionEnd);

        if (timeSinceEnd.inHours >= 4) {
          await _scheduleConfirmationNotification();
          break;
        }
      }
    } catch (e) {
      debugPrint('❌ خطأ في فحص التأكيدات المتأخرة: $e');
    }
  }

  Future<void> _loadSleepWindowSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final startHour = prefs.getInt('sleep_window_start_hour');
      final startMinute = prefs.getInt('sleep_window_start_minute');
      final endHour = prefs.getInt('sleep_window_end_hour');
      final endMinute = prefs.getInt('sleep_window_end_minute');
      final adaptiveEnabled = prefs.getBool('adaptive_window_enabled');

      TimeOfDay? startTime;
      TimeOfDay? endTime;
      bool? adaptive;

      if (startHour != null && startMinute != null) {
        startTime = TimeOfDay(hour: startHour, minute: startMinute);
      }

      if (endHour != null && endMinute != null) {
        endTime = TimeOfDay(hour: endHour, minute: endMinute);
      }

      if (adaptiveEnabled != null) {
        adaptive = adaptiveEnabled;
      }

      if (startTime == null || endTime == null) {
        final dbSettings = await _sleepRepo.getSleepWindowSettings();
        startTime = startTime ?? dbSettings['start_time'];
        endTime = endTime ?? dbSettings['end_time'];
        adaptive = adaptive ?? dbSettings['adaptive_enabled'];
      }

      setState(state.copyWith(
        sleepWindowStart: startTime ?? state.sleepWindowStart,
        sleepWindowEnd: endTime ?? state.sleepWindowEnd,
        adaptiveWindowEnabled: adaptive ?? state.adaptiveWindowEnabled,
      ));

    } catch (e) {
      debugPrint('❌ خطأ في تحميل إعدادات النافذة: $e');
    }
  }

  Future<void> _updateStatistics() async {
    try {
      final weeklyStats = await _sleepRepo.getWeeklySleepStats();

      setState(state.copyWith(
        averageSleepDuration: Duration(
            minutes: (weeklyStats['average_minutes_per_night'] ?? 480).round()
        ),
        averageQualityScore: (weeklyStats['average_quality'] ?? 0.0).toDouble(),
      ));

    } catch (e) {
      debugPrint('❌ خطأ في تحديث الإحصائيات: $e');
    }
  }

  Future<void> _saveEnvironmentalData(EnvironmentalConditions conditions) async {
    try {
      if (!state.hasActiveSession || state.currentSession!.id == null) return;

      await _sleepRepo.insertEnvironmentalData(
        sleepSessionId: state.currentSession!.id!,
        conditions: conditions,
      );
    } catch (e) {
      debugPrint('❌ خطأ في حفظ البيانات البيئية: $e');
    }
  }

  Future<void> _scheduleConfirmationNotification() async {
    try {
      final session = state.pendingConfirmations.isNotEmpty
          ? state.pendingConfirmations.last
          : null;
      if (session == null) return;

      final duration = session.duration ?? Duration.zero;

      await _notificationService.showNotification(
        id: 4100,
        title: '🌅 تأكيد جلسة النوم',
        body: 'نمت ${duration.inHours}h ${duration.inMinutes.remainder(60)}m',
        channelId: NotificationService.channelReminders,
        payload: {
          'type': 'sleep_confirmation',
          'session_id': session.id?.toString() ?? '0',
        },
      );

    } catch (e) {
      debugPrint('❌ خطأ في جدولة إشعار التأكيد: $e');
    }
  }

  // ════════════════════════════════════════════════════════════
  // ✅ تأكيد جلسة النوم
  // ════════════════════════════════════════════════════════════

  Future<void> confirmSleepSession({
    required String sessionId,
    required double qualityRating,
    String? notes,
    List<String>? factors,
  }) async {
    try {
      debugPrint('⏳ [Provider] بدء تأكيد جلسة $sessionId...');

      setState(state.copyWith(
        loadingState: LoadingState.loading,
        error: null,
      ));

      final sessionIndex = state.pendingConfirmations.indexWhere(
            (s) => s.id?.toString() == sessionId,
      );

      if (sessionIndex == -1) {
        throw Exception('لم يتم العثور على الجلسة');
      }

      final session = state.pendingConfirmations[sessionIndex];

      final confirmedSession = session.copyWith(
        qualityScore: qualityRating,
        notes: notes,
        userConfirmationStatus: 'confirmed',
        isCompleted: true,
        updatedAt: DateTime.now(),
      );

      await _sleepRepo.updateSleepSession(confirmedSession);

      final updatedPending = List<SleepSession>.from(state.pendingConfirmations);
      updatedPending.removeAt(sessionIndex);

      final updatedRecent = [confirmedSession, ...state.recentSessions];

      setState(state.copyWith(
        pendingConfirmations: updatedPending,
        recentSessions: updatedRecent,
        loadingState: LoadingState.success,
        successMessage: 'تم تأكيد جلسة النوم',
        lastUpdated: DateTime.now(),
      ));

      debugPrint('✅ [Provider] تم تأكيد الجلسة بنجاح');

      await _updateStatistics();
      await _insightsService.generateSleepInsight(confirmedSession);

    } catch (e, stack) {
      debugPrint('❌ [Provider] خطأ في تأكيد جلسة النوم: $e');
      debugPrint('Stack: $stack');

      setState(state.copyWith(
        loadingState: LoadingState.error,
        error: ServiceError(message: 'فشل في تأكيد جلسة النوم: $e'),
      ));

      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  // ✅ رفض جلسة النوم - مع التعديل الأول
  // ════════════════════════════════════════════════════════════

  Future<void> rejectSleepSession(String sessionId, {String? reason}) async {
    try {
      debugPrint('⏳ [Provider] بدء رفض جلسة $sessionId...');

      setState(state.copyWith(
        loadingState: LoadingState.loading,
        error: null,
      ));

      final sessionIndex = state.pendingConfirmations.indexWhere(
            (s) => s.id?.toString() == sessionId,
      );

      if (sessionIndex == -1) {
        throw Exception('لم يتم العثور على الجلسة');
      }

      final session = state.pendingConfirmations[sessionIndex];

      final rejectedSession = session.copyWith(
        userConfirmationStatus: 'rejected',
        notes: reason ?? 'تم رفض الجلسة',
        updatedAt: DateTime.now(),
      );

      await _sleepRepo.updateSleepSession(rejectedSession);

      final updatedPending = List<SleepSession>.from(state.pendingConfirmations);
      updatedPending.removeAt(sessionIndex);

      // ✅ التعديل الأول: إضافة الجلسة المرفوضة للـ History
      final updatedRecent = [rejectedSession, ...state.recentSessions];

      setState(state.copyWith(
        pendingConfirmations: updatedPending,
        recentSessions: updatedRecent, // ← التعديل هنا!
        loadingState: LoadingState.success,
        successMessage: 'تم رفض جلسة النوم',
        lastUpdated: DateTime.now(),
      ));

      debugPrint('✅ [Provider] تم رفض الجلسة بنجاح');

    } catch (e, stack) {
      debugPrint('❌ [Provider] خطأ في رفض جلسة النوم: $e');
      debugPrint('Stack: $stack');

      setState(state.copyWith(
        loadingState: LoadingState.error,
        error: ServiceError(message: 'فشل في رفض جلسة النوم: $e'),
      ));

      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  // ✅ تعديل أوقات النوم - مع التعديل الثاني
  // ════════════════════════════════════════════════════════════

  Future<void> modifySleepTimes({
    required String sessionId,
    DateTime? newStartTime,
    DateTime? newEndTime,
  }) async {
    try {
      await executeWithLoading(() async {
        var sessionIndex = state.pendingConfirmations.indexWhere(
              (s) => s.id?.toString() == sessionId,
        );

        SleepSession? session;
        bool isPending = true;

        if (sessionIndex != -1) {
          session = state.pendingConfirmations[sessionIndex];
        } else {
          sessionIndex = state.recentSessions.indexWhere(
                (s) => s.id?.toString() == sessionId,
          );
          if (sessionIndex != -1) {
            session = state.recentSessions[sessionIndex];
            isPending = false;
          }
        }

        if (session == null) {
          throw Exception('لم يتم العثور على الجلسة');
        }

        final updatedStartTime = newStartTime ?? session.startTime;
        final updatedEndTime = newEndTime ?? session.endTime;

        Duration? newDuration;
        if (updatedEndTime != null) {
          newDuration = updatedEndTime.difference(updatedStartTime);
        }

        final originalStart = session.originalStartTime ?? session.startTime;
        final originalEnd = session.originalEndTime ?? session.endTime;

        final modifiedSession = session.copyWith(
          startTime: updatedStartTime,
          endTime: updatedEndTime,
          duration: newDuration,
          originalStartTime: originalStart,     // ← جديد
          originalEndTime: originalEnd,         // ← جديد
          wasTimeModified: true,                // ← جديد
          updatedAt: DateTime.now(),
        );

        await _sleepRepo.updateSleepSession(modifiedSession);

        if (isPending) {
          final updatedPending = List<SleepSession>.from(state.pendingConfirmations);
          updatedPending[sessionIndex] = modifiedSession;
          setState(state.copyWith(
            pendingConfirmations: updatedPending,
            successMessage: 'تم تعديل أوقات النوم',
          ));
        } else {
          final updatedRecent = List<SleepSession>.from(state.recentSessions);
          updatedRecent[sessionIndex] = modifiedSession;
          setState(state.copyWith(
            recentSessions: updatedRecent,
            successMessage: 'تم تعديل أوقات النوم',
          ));
        }

        debugPrint('✅ تم تعديل أوقات جلسة النوم');
      });
    } catch (e) {
      debugPrint('❌ خطأ في تعديل أوقات النوم: $e');
      setState(state.copyWith(
        error: ServiceError(message: 'فشل في تعديل أوقات النوم: $e'),
      ));
    }
  }

  Map<String, dynamic> getActivityStatistics() {
    return _sensorService.getActivityStatistics();
  }

  Map<String, dynamic> getSystemStatus() {
    final sensorStatus = _sensorService.getSystemStatus();
    return {
      'sleep': {
        'auto_tracking_active': state.isAutoTrackingActive,
        'current_sleep_state': state.currentSleepState.name,
        'detection_confidence': state.sleepDetectionConfidence,
        'in_sleep_window': state.isInSleepWindow,
        'has_active_session': state.hasActiveSession,
        'pending_confirmations': state.pendingConfirmations.length,
        'environmental_quality': state.environmentalQualityScore,
      },
      'sensor_service': sensorStatus,
    };
  }

  Future<void> setSleepGoal(int hours) async {
    try {
      if (hours < 4 || hours > 12) return;

      setState(state.copyWith(
        sleepGoalHours: hours,
        lastUpdated: DateTime.now(),
      ));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('sleep_goal_hours', hours);

      try {
        await _sleepRepo.insertSleepGoal(
          targetHours: hours,
          targetMinutes: 0,
        );
      } catch (e) {
        debugPrint('⚠️ خطأ في حفظ DB: $e');
      }

      await _updateStatistics();

    } catch (e) {
      debugPrint('❌ خطأ في تحديث الهدف: $e');
      setState(state.copyWith(
        error: ServiceError(message: 'فشل في حفظ الهدف: $e'),
      ));
    }
  }

  Future<void> filterByDateRange(DateTimeRange? dateRange) async {
    try {
      setState(state.copyWith(selectedDateRange: dateRange));

      if (dateRange == null) {
        await _loadRecentSessions();
      } else {
        final filtered = await _sleepRepo.getSleepSessionsInRange(
          startDate: dateRange.start,
          endDate: dateRange.end,
        );

        setState(state.copyWith(recentSessions: filtered));
      }

    } catch (e) {
      debugPrint('❌ خطأ في الفلترة: $e');
    }
  }

  void setViewMode(String mode) {
    if (!['daily', 'weekly', 'monthly'].contains(mode)) return;
    setState(state.copyWith(viewMode: mode));
  }

  @override
  String get cacheKey => 'sleep_tracking_state';

  @override
  Duration get cacheDuration => const Duration(hours: 1);

  @override
  Duration get updateInterval => const Duration(minutes: 5);

  @override
  bool get shouldAutoStart => true;

  @override
  Map<String, dynamic> serializeState(SleepTrackingState state) {
    return {
      'is_auto_tracking_active': state.isAutoTrackingActive,
      'sleep_goal_hours': state.sleepGoalHours,
      'sleep_window_start': '${state.sleepWindowStart.hour}:${state.sleepWindowStart.minute}',
      'sleep_window_end': '${state.sleepWindowEnd.hour}:${state.sleepWindowEnd.minute}',
      'adaptive_window_enabled': state.adaptiveWindowEnabled,
      'view_mode': state.viewMode,
      'last_updated': state.lastUpdated?.toIso8601String(),
    };
  }

  @override
  SleepTrackingState deserializeState(Map<String, dynamic> data) {
    try {
      final startParts = (data['sleep_window_start'] as String).split(':');
      final endParts = (data['sleep_window_end'] as String).split(':');

      return state.copyWith(
        isAutoTrackingActive: data['is_auto_tracking_active'] as bool? ?? false,
        sleepGoalHours: data['sleep_goal_hours'] as int? ?? 8,
        sleepWindowStart: TimeOfDay(
          hour: int.parse(startParts[0]),
          minute: int.parse(startParts[1]),
        ),
        sleepWindowEnd: TimeOfDay(
          hour: int.parse(endParts[0]),
          minute: int.parse(endParts[1]),
        ),
        adaptiveWindowEnabled: data['adaptive_window_enabled'] as bool? ?? true,
        viewMode: data['view_mode'] as String? ?? 'daily',
        lastUpdated: data['last_updated'] != null
            ? DateTime.parse(data['last_updated'])
            : null,
      );
    } catch (e) {
      debugPrint('❌ خطأ في استرجاع الحالة: $e');
      return state;
    }
  }

  Future<void> startAutoSleep() async {
    final now = DateTime.now();

    final newSession = SleepSession(
      startTime: now,
      sleepType: 'automatic',
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
    );

    setState(state.copyWith(
      currentSession: newSession,
      currentSleepState: SleepState.sleeping,
    ));
  }

  Future<void> endAutoSleep() async {
    if (!state.hasActiveSession) return;

    final now = DateTime.now();
    final duration = now.difference(state.currentSession!.startTime);

    final completedSession = state.currentSession!.copyWith(
      endTime: now,
      duration: duration,
      isCompleted: true,
    );

    await _sleepRepo.insertSleepSession(completedSession);

    setState(state.copyWith(
      currentSession: null,
      currentSleepState: SleepState.awake,
      pendingConfirmations: [...state.pendingConfirmations, completedSession],
    ));
  }

  Future<Map<String, bool>> loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final settings = {
        'morning': prefs.getBool('notification_morning') ?? true,
        'sleep': prefs.getBool('notification_sleep') ?? true,
        'wake': prefs.getBool('notification_wake') ?? false,
      };

      return settings;
    } catch (e) {
      debugPrint('❌ خطأ في تحميل إعدادات الإشعارات: $e');
      return {
        'morning': true,
        'sleep': true,
        'wake': false,
      };
    }
  }

  Future<void> saveNotificationSetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notification_$key', value);
    } catch (e) {
      debugPrint('❌ خطأ في حفظ إعداد الإشعار: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getSmartInsights() async {
    try {
      debugPrint('💡 جلب الرؤى الذكية من InsightsService...');

      final today = _formatDate(DateTime.now());

      final sleepInsights = await _insightsService.generateSleepOnlyInsights(today);

      debugPrint('✅ تم جلب ${sleepInsights.length} رؤية من JSON');

      final insightsForUI = sleepInsights.map((insight) {
        return {
          'type': insight.subcategory ?? insight.category,
          'priority': _getPriorityFromConfidence(insight.confidenceScore),
          'message': insight.title.isNotEmpty ? insight.title : insight.message,
          'value': insight.message,
        };
      }).toList();

      debugPrint('✅ تم تحويل ${insightsForUI.length} رؤية للعرض');
      return insightsForUI;

    } catch (e, stack) {
      debugPrint('❌ خطأ في جلب الرؤى الذكية: $e');
      debugPrint('Stack: $stack');
      return [];
    }
  }

  String _getPriorityFromConfidence(double confidence) {
    if (confidence >= 0.85) return 'high';
    if (confidence >= 0.7) return 'medium';
    return 'low';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<List<Map<String, dynamic>>> getConfidenceStatistics({int days = 30}) async {
    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📊 [Provider] جلب إحصائيات التصنيف لآخر $days يوم...');

      final stats = await _sleepRepo.getConfidenceStatistics(days: days);

      debugPrint('✅ [Provider] تم جلب ${stats.length} نوع تصنيف');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      return stats;

    } catch (e, stack) {
      debugPrint('❌ [Provider] خطأ في getConfidenceStatistics: $e');
      debugPrint('Stack: $stack');
      return [];
    }
  }

  @override
  void dispose() {
    debugPrint('🗑️ تنظيف مزود تتبع النوم');

    _detectionTimer?.cancel();
    _environmentalTimer?.cancel();
    _windowCheckTimer?.cancel();
    _quickWakeCheckTimer?.cancel();
    _sessionCleanupTimer?.cancel();
    _environmentSubscription?.cancel();

    _lastHighLightTime = null;
    _lastLightLevel = null;

    _sensorService.stopListening();
    super.dispose();
  }
}