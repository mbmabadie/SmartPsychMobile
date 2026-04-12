// lib/core/services/notification_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة الإشعارات المحلية للتطبيق
class NotificationService {
  // =====================
  // Singleton Pattern
  // =====================
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static NotificationService get instance => _instance;

  // =====================
  // Core Dependencies
  // =====================
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // =====================
  // State
  // =====================
  bool _isInitialized = false;
  Timer? _smartNotificationTimer;

  // =====================
  // Notification Channels
  // =====================
  static const String channelGeneral = 'smart_psych_general';
  static const String channelBackground = 'smart_psych_background';
  static const String channelReminders = 'smart_psych_reminders';
  static const String channelInsights = 'smart_psych_insights';
  static const String channelCritical = 'smart_psych_critical';
  static const String channelSleep = 'sleep_notifications';
  static const String channelAlerts = 'alerts_notifications';
  static const String channelHealth = 'health_notifications';
  static const String channelMotivation = 'motivation_notifications';
  static const String channelPhone = 'phone_notifications';

  // =====================
  // Notification IDs
  // =====================
  static const int backgroundServiceId = 888;
  static const int sleepStartId = 1000;
  static const int sleepEndId = 1001;
  static const int bedtimeReminderId = 1002;
  static const int morningGreetingId = 1003;
  static const int mealReminderBreakfastId = 1004;
  static const int mealReminderLunchId = 1005;
  static const int mealReminderDinnerId = 1006;
  static const int activityReminderId = 1007;
  static const int excessivePhoneUsageId = 1008;
  static const int lowActivityId = 1009;
  static const int stepMilestoneBaseId = 2000;
  static const int appReminderBaseId = 3000;
  static const int insightBaseId = 4000;
  static const int motivationBaseId = 5000;
  static const int healthBaseId = 6000;
  static const int screenTimeWarningId = 7000;

  // IDs إضافية لـ Duolingo
  static const int duolingoReminderId = 8000;
  static const int activityBoostId = 8100;
  static const int streakCelebrationId = 8200;
  static const int sleepReminderSmartId = 8300;
  static const int motivationalSmartId = 8400;

  // =====================
  // Getters
  // =====================
  bool get isInitialized => _isInitialized;
  bool get isSmartTimerActive => _smartNotificationTimer?.isActive ?? false;
  FlutterLocalNotificationsPlugin get notificationPlugin =>
      _flutterLocalNotificationsPlugin;

  // =====================
  // Initialization
  // =====================

  /// تهيئة خدمة الإشعارات
  Future<bool> initialize() async {
    if (_isInitialized) {
      debugPrint('✅ خدمة الإشعارات مهيأة مسبقاً');
      return true;
    }

    try {
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      // طلب الأذونات
      await _requestEnhancedPermissions();

      // إعدادات Android
      const androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      // إعدادات iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // تهيئة
      await _flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // إنشاء قنوات الإشعارات
      await _createEnhancedNotificationChannels();

      // جدولة الإشعارات المتكررة
      await _scheduleSmartRecurringNotifications();

      // بدء النظام الذكي
      _startSmartNotificationSystem();

      _isInitialized = true;
      debugPrint('✅ تم تهيئة خدمة الإشعارات بنجاح');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ خطأ في تهيئة خدمة الإشعارات: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      return false;
    }
  }

  /// طلب الأذونات
  Future<void> _requestEnhancedPermissions() async {
    if (Platform.isAndroid) {
      final permissions = [
        Permission.notification,
        Permission.scheduleExactAlarm,
      ];

      for (final permission in permissions) {
        if (await permission.isDenied) {
          await permission.request();
        }
      }

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation
      <AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  /// إنشاء قنوات الإشعارات
  Future<void> _createEnhancedNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final androidImplementation = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation
    <AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation == null) return;

    final channels = [
      const AndroidNotificationChannel(
        channelBackground,
        'خدمة الخلفية',
        description: 'تتبع مستمر في الخلفية',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
        showBadge: false,
      ),
      const AndroidNotificationChannel(
        channelGeneral,
        'إشعارات عامة',
        description: 'الإشعارات العامة للتطبيق',
        importance: Importance.defaultImportance,
      ),
      const AndroidNotificationChannel(
        channelReminders,
        'التذكيرات الذكية',
        description: 'تذكيرات ذكية للصحة والنشاط',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
      const AndroidNotificationChannel(
        channelInsights,
        'الرؤى والتحليلات',
        description: 'رؤى ذكية عن صحتك',
        importance: Importance.defaultImportance,
      ),
      const AndroidNotificationChannel(
        channelSleep,
        'تتبع النوم',
        description: 'إشعارات النوم والاستيقاظ',
        importance: Importance.high,
        playSound: true,
      ),
      const AndroidNotificationChannel(
        channelHealth,
        'الصحة واللياقة',
        description: 'إشعارات الخطوات والنشاط',
        importance: Importance.defaultImportance,
      ),
      const AndroidNotificationChannel(
        channelMotivation,
        'التحفيز والإنجازات',
        description: 'رسائل تحفيزية يومية',
        importance: Importance.defaultImportance,
      ),
      const AndroidNotificationChannel(
        channelAlerts,
        'تنبيهات مهمة',
        description: 'تنبيهات صحية مهمة',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
      const AndroidNotificationChannel(
        channelPhone,
        'استخدام الهاتف',
        description: 'تنبيهات استخدام الهاتف',
        importance: Importance.high,
      ),
    ];

    for (final channel in channels) {
      await androidImplementation.createNotificationChannel(channel);
    }

    debugPrint('✅ تم إنشاء ${channels.length} قناة إشعارات');
  }

  /// جدولة الإشعارات المتكررة
  Future<void> _scheduleSmartRecurringNotifications() async {
    try {
      // إشعارات الصباح
      await _scheduleVariedMorningNotifications();

      // إشعارات الغداء
      await _scheduleLunchReminders();

      // إشعارات النشاط المسائي
      await _scheduleEveningActivityReminders();

      // إشعارات النوم
      await _scheduleBedtimeReminders();

      // إشعارات الترطيب
      await _scheduleHydrationReminders();

      // إشعارات فحص المزاج
      await _scheduleMoodCheckIns();

      debugPrint('📅 تم جدولة جميع الإشعارات المتكررة');
    } catch (e) {
      debugPrint('❌ خطأ في جدولة الإشعارات المتكررة: $e');
    }
  }

  /// إشعارات الصباح
  Future<void> _scheduleVariedMorningNotifications() async {
    final morningMessages = [
      {'title': '🌅 صباح الخير', 'body': 'يوم جديد مليء بالفرص'},
      {'title': '☀️ بداية جميلة', 'body': 'ابدأ يومك بطاقة إيجابية'},
      {'title': '🌟 طاقة الصباح', 'body': 'فرصة جديدة لتكون أفضل'},
      {'title': '💪 نشاط وحيوية', 'body': 'صباح مليء بالنشاط'},
      {'title': '🎯 يوم منتج', 'body': 'استعد لإنجازات رائعة'},
    ];

    for (int i = 0; i < 7; i++) {
      final message = morningMessages[i % morningMessages.length];
      await _scheduleWeeklyNotification(
        id: morningGreetingId + i,
        title: message['title']!,
        body: message['body']!,
        weekday: i + 1,
        hour: 8,
        minute: 0,
        channelId: channelMotivation,
      );
    }
  }

  Future<void> _scheduleLunchReminders() async {
    await _scheduleRandomDailyNotification(
      id: mealReminderLunchId,
      title: '🍽️ وقت الغداء',
      body: 'لا تنس وجبة صحية ومتوازنة',
      hour: 12,
      minute: 30,
      channelId: channelHealth,
    );
  }

  Future<void> _scheduleEveningActivityReminders() async {
    await _scheduleRandomDailyNotification(
      id: activityReminderId,
      title: '🚶‍♂️ وقت الحركة',
      body: 'مساء رائع للمشي أو النشاط',
      hour: 18,
      minute: 0,
      channelId: channelHealth,
    );
  }

  Future<void> _scheduleBedtimeReminders() async {
    await _scheduleRandomDailyNotification(
      id: bedtimeReminderId,
      title: '🌙 وقت الاستعداد للنوم',
      body: 'ابدأ بالاسترخاء لنوم مريح',
      hour: 22,
      minute: 0,
      channelId: channelSleep,
    );
  }

  Future<void> _scheduleHydrationReminders() async {
    final hydrationTimes = [9, 12, 15, 18];

    for (int i = 0; i < hydrationTimes.length; i++) {
      await _scheduleRandomDailyNotification(
        id: healthBaseId + i,
        title: '💧 وقت شرب الماء',
        body: 'جسمك يحتاج للماء',
        hour: hydrationTimes[i],
        minute: 0,
        channelId: channelHealth,
      );
    }
  }

  Future<void> _scheduleMoodCheckIns() async {
    final moodCheckTimes = [
      {'hour': 10, 'minute': 0, 'title': 'كيف تشعر صباحاً؟'},
      {'hour': 15, 'minute': 30, 'title': 'فحص مزاج بعد الظهر'},
      {'hour': 20, 'minute': 0, 'title': 'كيف كان يومك؟'},
    ];

    for (int i = 0; i < moodCheckTimes.length; i++) {
      final check = moodCheckTimes[i];
      await _scheduleRandomDailyNotification(
        id: insightBaseId + i,
        title: '😊 ${check['title']}',
        body: 'سجل مزاجك لتتبع حالتك',
        hour: check['hour'] as int,
        minute: check['minute'] as int,
        channelId: channelInsights,
      );
    }
  }

  /// بدء النظام الذكي
  void _startSmartNotificationSystem() {
    _smartNotificationTimer =
        Timer.periodic(const Duration(hours: 1), (timer) async {
          await _checkAndSendSmartNotifications();
        });

    debugPrint('🧠 تم بدء النظام الذكي للإشعارات');
  }

  Future<void> _checkAndSendSmartNotifications() async {
    try {
      await _checkStepGoalsAndNotify();
      await _checkSleepPatternsAndNotify();
      await _checkAppUsageAndNotify();
      await _sendContextualMotivation();
    } catch (e) {
      debugPrint('❌ خطأ في النظام الذكي: $e');
    }
  }

  Future<void> _checkStepGoalsAndNotify() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stepsToday = prefs.getInt('steps_today') ?? 0;
      final hour = DateTime.now().hour;

      final milestones = [2000, 5000, 8000, 10000, 12000, 15000];
      for (final milestone in milestones) {
        final notifiedKey = 'milestone_${milestone}_notified';
        final alreadyNotified = prefs.getBool(notifiedKey) ?? false;

        if (stepsToday >= milestone && !alreadyNotified) {
          await _sendStepMilestoneNotification(milestone);
          await prefs.setBool(notifiedKey, true);
        }
      }

      if (hour == 16 && stepsToday < 3000) {
        await _sendLowActivityWarning(stepsToday);
      }
    } catch (e) {
      debugPrint('❌ خطأ في فحص أهداف الخطوات: $e');
    }
  }

  Future<void> _checkSleepPatternsAndNotify() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hour = DateTime.now().hour;
      final lastSleepDuration = prefs.getDouble('last_sleep_duration') ?? 0.0;

      if (hour == 10 && lastSleepDuration > 0 && lastSleepDuration < 6.0) {
        await showNotification(
          id: sleepEndId + 100,
          title: '😴 نوم قصير الليلة الماضية',
          body:
          'نمت ${lastSleepDuration.toStringAsFixed(1)} ساعات فقط. حاول النوم مبكراً الليلة',
          channelId: channelSleep,
        );
      }

      if (hour == 23) {
        await showNotification(
          id: bedtimeReminderId + 100,
          title: '🌙 الوقت متأخر',
          body: 'النوم الكافي مهم لصحتك',
          channelId: channelSleep,
        );
      }
    } catch (e) {
      debugPrint('❌ خطأ في فحص أنماط النوم: $e');
    }
  }

  Future<void> _checkAppUsageAndNotify() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastAppUsage = prefs.getInt('last_app_usage') ?? 0;

      if (lastAppUsage == 0) return;

      final daysSinceLastUsage = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(lastAppUsage))
          .inDays;

      if (daysSinceLastUsage == 1) {
        await _sendDailyCheckInReminder();
      } else if (daysSinceLastUsage == 3) {
        await _sendThreeDayReminder();
      } else if (daysSinceLastUsage == 7) {
        await _sendWeeklyReminder();
      } else if (daysSinceLastUsage >= 14) {
        await _sendLongAbsenceReminder(daysSinceLastUsage);
      }
    } catch (e) {
      debugPrint('❌ خطأ في فحص استخدام التطبيق: $e');
    }
  }

  Future<void> _sendContextualMotivation() async {
    try {
      final hour = DateTime.now().hour;
      final random = Random();

      if (hour == 14 && random.nextDouble() < 0.3) {
        await showNotification(
          id: motivationBaseId + hour,
          title: '💪 استمر بقوة',
          body: 'نصف اليوم انتهى، استمر بنفس الطاقة',
          channelId: channelMotivation,
        );
      } else if (hour == 16 && random.nextDouble() < 0.2) {
        await showNotification(
          id: motivationBaseId + hour,
          title: '🌟 إنجازاتك مهمة',
          body: 'كل خطوة صغيرة تقربك من أهدافك',
          channelId: channelMotivation,
        );
      }
    } catch (e) {
      debugPrint('❌ خطأ في إرسال التحفيز: $e');
    }
  }

  // =====================
  // Core Notification Methods
  // =====================

  /// عرض إشعار
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String channelId = channelGeneral,
    Map<String, dynamic>? payload,
    String? bigText,
    List<AndroidNotificationAction>? actions,
  }) async {
    if (!_isInitialized) {
      debugPrint('⚠️ خدمة الإشعارات غير مهيأة');
      return;
    }

    try {
      final notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          _getChannelName(channelId),
          channelDescription: _getChannelDescription(channelId),
          importance: _getChannelImportance(channelId),
          priority: _getChannelPriority(channelId),
          icon: '@mipmap/ic_launcher',
          styleInformation:
          bigText != null ? BigTextStyleInformation(bigText) : null,
          actions: actions,
          enableVibration: _shouldVibrate(channelId),
          playSound: true,
          when: DateTime.now().millisecondsSinceEpoch,
          showWhen: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload != null ? jsonEncode(payload) : null,
      );
    } catch (e) {
      debugPrint('❌ خطأ في عرض الإشعار: $e');
    }
  }

  /// إشعار خدمة الخلفية
  Future<void> showBackgroundServiceNotification({
    required int id,
    String title = 'Smart Psych نشط',
    String body = 'تتبع مستمر للصحة والنشاط',
    Map<String, dynamic>? data,
  }) async {
    if (!_isInitialized) {
      debugPrint('⚠️ خدمة الإشعارات غير مهيأة');
      return;
    }

    try {
      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          channelBackground,
          'خدمة الخلفية',
          channelDescription: 'تتبع مستمر في الخلفية',
          importance: Importance.low,
          priority: Priority.low,
          playSound: false,
          enableVibration: false,
          ongoing: true,
          autoCancel: false,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: false,
          presentBadge: false,
          presentSound: false,
        ),
      );

      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: data != null ? jsonEncode(data) : null,
      );
    } catch (e) {
      debugPrint('❌ خطأ في عرض إشعار خدمة الخلفية: $e');
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    DateTime? scheduledDate,
    DateTime? scheduledTime,
    String channelId = channelGeneral,
    Map<String, dynamic>? payload,
  }) async {
    try {
      final effectiveScheduledTime = scheduledDate ?? scheduledTime;

      if (effectiveScheduledTime == null) {
        debugPrint('❌ يجب توفير scheduledDate أو scheduledTime');
        return;
      }

      final tzScheduledTime = tz.TZDateTime.from(effectiveScheduledTime, tz.local);

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            _getChannelName(channelId),
            importance: _getChannelImportance(channelId),
          ),
        ),
        payload: payload != null ? jsonEncode(payload) : null,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      debugPrint('📅 تم جدولة إشعار: $title');
    } catch (e) {
      debugPrint('❌ خطأ في جدولة الإشعار: $e');
    }
  }


  Future<void> _scheduleRandomDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String channelId,
    Map<String, dynamic>? payload,
  }) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            _getChannelName(channelId),
            importance: _getChannelImportance(channelId),
          ),
        ),
        payload: payload != null ? jsonEncode(payload) : null,
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('❌ خطأ في جدولة إشعار يومي: $e');
    }
  }


  Future<void> _scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required int hour,
    required int minute,
    required String channelId,
  }) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      final daysToAdd = (weekday - now.weekday) % 7;
      if (daysToAdd == 0 && scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 7));
      } else {
        scheduledTime = scheduledTime.add(Duration(days: daysToAdd));
      }

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            _getChannelName(channelId),
            importance: _getChannelImportance(channelId),
          ),
        ),
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('❌ خطأ في جدولة إشعار أسبوعي: $e');
    }
  }

  /// تحذير استخدام مفرط للهاتف
  Future<void> showExcessivePhoneUsageAlert({
    required Duration usageTime,
    required int pickupCount,
  }) async {
    if (!_isInitialized) {
      debugPrint('⚠️ خدمة الإشعارات غير مهيأة');
      return;
    }

    try {
      final hours = usageTime.inHours;
      final minutes = usageTime.inMinutes.remainder(60);

      String message;
      String severity;

      if (hours > 8) {
        message = 'استخدمت الهاتف ${hours}س ${minutes}د اليوم! هذا أكثر من المعدل الصحي المقترح.';
        severity = 'high';
      } else if (hours > 6) {
        message = 'استخدام مفرط: ${hours}س ${minutes}د مع $pickupCount فتحة. حان وقت الاستراحة!';
        severity = 'medium';
      } else {
        message = 'استخدام عالي: ${hours}س ${minutes}د اليوم. انتبه لصحتك الرقمية.';
        severity = 'low';
      }

      await showNotification(
        id: excessivePhoneUsageId,
        title: '📱 استخدام مفرط للهاتف',
        body: message,
        channelId: severity == 'high' ? channelAlerts : channelPhone,
        bigText: '$message\n\nنصائح:\n• خذ استراحة كل 30 دقيقة\n• استخدم وضع عدم الإزعاج\n• ضع الهاتف بعيداً عند النوم',
        payload: {
          'type': 'excessive_usage_alert',
          'usage_hours': hours,
          'usage_minutes': minutes,
          'pickup_count': pickupCount,
          'severity': severity,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      debugPrint('📱 تم إرسال تحذير استخدام مفرط: ${hours}س ${minutes}د');
    } catch (e) {
      debugPrint('❌ خطأ في إرسال تحذير الاستخدام المفرط: $e');
    }
  }

  // =====================
  // Specific Notifications
  // =====================

  Future<void> _sendStepMilestoneNotification(int milestone) async {
    String title, body;

    switch (milestone) {
      case 2000:
        title = '🎯 بداية رائعة';
        body = 'وصلت لـ 2000 خطوة!';
        break;
      case 5000:
        title = '🌟 نصف الطريق';
        body = '5000 خطوة محققة!';
        break;
      case 8000:
        title = '🏃‍♂️ هدف صحي ممتاز';
        body = '8000 خطوة!';
        break;
      case 10000:
        title = '🏆 إنجاز رائع';
        body = 'هدف الـ 10000 خطوة محقق!';
        break;
      case 12000:
        title = '⭐ فوق المتوقع';
        body = '12000 خطوة!';
        break;
      case 15000:
        title = '🚀 نشاط خارق';
        body = '15000 خطوة!';
        break;
      default:
        title = '🎉 إنجاز في الخطوات';
        body = 'واصل هذا النشاط!';
    }

    await showNotification(
      id: stepMilestoneBaseId + milestone,
      title: title,
      body: body,
      channelId: channelHealth,
      payload: {
        'type': 'step_milestone',
        'milestone': milestone,
      },
    );
  }

  Future<void> _sendLowActivityWarning(int currentSteps) async {
    await showNotification(
      id: lowActivityId,
      title: '⚡ وقت الحركة',
      body: 'لديك $currentSteps خطوة حتى الآن. مشي قصير سيحسن يومك!',
      channelId: channelHealth,
    );
  }

  Future<void> _sendDailyCheckInReminder() async {
    await showNotification(
      id: appReminderBaseId + 1,
      title: '📝 تسجيل دخول يومي',
      body: 'كيف مزاجك اليوم؟',
      channelId: channelReminders,
    );
  }

  Future<void> _sendThreeDayReminder() async {
    await showNotification(
      id: appReminderBaseId + 3,
      title: '👋 نفتقدك',
      body: 'لم نراك منذ 3 أيام',
      channelId: channelReminders,
    );
  }

  Future<void> _sendWeeklyReminder() async {
    await showNotification(
      id: appReminderBaseId + 7,
      title: '🌟 تذكير أسبوعي',
      body: 'أسبوع كامل! نحن هنا لدعمك',
      channelId: channelReminders,
    );
  }

  Future<void> _sendLongAbsenceReminder(int days) async {
    await showNotification(
      id: appReminderBaseId + days,
      title: days >= 30 ? '💪 عودة قوية' : '🤗 نشتاق لعودتك',
      body: days >= 30
          ? 'شهر كامل! وقت للبدء من جديد'
          : 'مضى $days يوم. دعنا نبدأ رحلة جديدة',
      channelId: channelReminders,
    );
  }

  // ================================
  // 🦉 Duolingo-Style Notifications
  // ================================

  Future<void> sendDuolingoReminder({
    required int daysAway,
    required int currentStreak,
    String? userName,
  }) async {
    if (!_isInitialized) return;

    try {
      String title, body, emoji;

      switch (daysAway) {
        case 1:
          emoji = '💪';
          title = 'لا تفقد زخمك!';
          body = 'يوم واحد فقط! الاستمرار يجعل العادات أسهل';
          break;
        case 2:
          emoji = '🔥';
          title = 'سلسلتك في خطر!';
          body = currentStreak > 0
              ? '$currentStreak يوم متتالي! لا تدعها تضيع'
              : 'يومان بعيداً! عد الآن';
          break;
        case 3:
          emoji = '😢';
          title = 'نفتقدك حقاً!';
          body = '3 أيام بدونك...';
          break;
        case 7:
          emoji = '🌟';
          title = 'أسبوع كامل!';
          body = 'عد لبناء عادات صحية';
          break;
        default:
          return;
      }

      await showNotification(
        id: duolingoReminderId + daysAway,
        title: '$emoji $title',
        body: body,
        channelId: channelMotivation,
        payload: {
          'type': 'duolingo_reminder',
          'days_away': daysAway,
          'streak': currentStreak,
        },
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_duolingo_notification',
          DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('❌ خطأ في إرسال تذكير Duolingo: $e');
    }
  }

  Future<void> sendActivityBoost({
    required int currentSteps,
    required int targetSteps,
  }) async {
    if (!_isInitialized) return;

    try {
      final remaining = targetSteps - currentSteps;
      final percent = (currentSteps / targetSteps * 100).round();

      String title, body;

      if (percent >= 80) {
        title = '🎯 قريب جداً من الهدف!';
        body = 'فقط $remaining خطوة متبقية!';
      } else if (percent >= 50) {
        title = '💪 نصف الطريق!';
        body = '$remaining خطوة للوصول للهدف';
      } else {
        title = '🚶‍♂️ وقت الحركة!';
        body = 'لديك $currentSteps خطوة';
      }

      await showNotification(
        id: activityBoostId,
        title: title,
        body: body,
        channelId: channelHealth,
      );
    } catch (e) {
      debugPrint('❌ خطأ في إرسال دفعة النشاط: $e');
    }
  }

  Future<void> sendStreakCelebration({
    required int streakDays,
  }) async {
    if (!_isInitialized) return;

    try {
      String title, body, emoji;

      if (streakDays == 3) {
        emoji = '⭐';
        title = '3 أيام متتالية!';
        body = 'رائع! أنت تبني عادة قوية';
      } else if (streakDays == 7) {
        emoji = '🔥';
        title = 'أسبوع كامل!';
        body = '7 أيام متتالية!';
      } else if (streakDays == 30) {
        emoji = '🏆';
        title = 'شهر كامل!';
        body = '30 يوماً متتالياً!';
      } else {
        return;
      }

      await showNotification(
        id: streakCelebrationId + streakDays,
        title: '$emoji $title',
        body: body,
        channelId: channelMotivation,
      );
    } catch (e) {
      debugPrint('❌ خطأ في احتفال الـ streak: $e');
    }
  }

  Future<void> sendContextualMotivation({
    required String context,
    required Map<String, dynamic> data,
  }) async {
    if (!_isInitialized) return;

    try {
      String title, body, emoji;

      switch (context) {
        case 'morning_greeting':
          emoji = '🌅';
          title = 'صباح الخير!';
          body = 'يوم جديد مليء بالفرص';
          break;
        case 'perfect_day':
          emoji = '🎉';
          title = 'يوم مثالي!';
          body = 'نشاط ممتاز، نوم جيد!';
          break;
        default:
          emoji = '💡';
          title = '';
          body = 'صحتك أهم استثمار';
      }

      await showNotification(
        id: motivationalSmartId + context.hashCode.abs(),
        title: '$emoji $title',
        body: body,
        channelId: channelMotivation,
      );
    } catch (e) {
      debugPrint('❌ خطأ في الرسالة التحفيزية: $e');
    }
  }

  // =====================
  // Notification Handlers
  // =====================

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 تم النقر على إشعار');

    if (response.payload != null) {
      _handleNotificationTap(response.payload!);
    }

    _updateLastAppUsage();
  }

  void _handleNotificationTap(String payload) {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final type = data['type'] as String?;

      debugPrint('👆 معالجة نقر: $type');

      // هنا يمكن إضافة Navigation حسب النوع
    } catch (e) {
      debugPrint('❌ خطأ في معالجة النقر: $e');
    }
  }

  Future<void> _updateLastAppUsage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        'last_app_usage', DateTime.now().millisecondsSinceEpoch);
  }

  // =====================
  // Management Methods
  // =====================

  Future<void> cancelNotification(int id) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
      debugPrint('❌ تم إلغاء الإشعار: $id');
    } catch (e) {
      debugPrint('❌ خطأ في إلغاء الإشعار: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('❌ تم إلغاء جميع الإشعارات');
    } catch (e) {
      debugPrint('❌ خطأ في إلغاء الإشعارات: $e');
    }
  }

  /// إلغاء الإشعارات حسب النوع
  Future<void> cancelNotificationsByType(String type) async {
    try {
      debugPrint('🗑️ إلغاء إشعارات من نوع: $type');

      // إلغاء حسب النوع
      if (type == 'break_reminder') {
        // إلغاء تذكيرات الاستراحة (IDs من 3000 إلى 3009)
        for (int i = 0; i < 10; i++) {
          await _flutterLocalNotificationsPlugin.cancel(3000 + i);
        }
      } else if (type == 'step_milestone') {
        // إلغاء إشعارات الخطوات
        final milestones = [2000, 5000, 8000, 10000, 12000, 15000];
        for (final milestone in milestones) {
          await _flutterLocalNotificationsPlugin
              .cancel(stepMilestoneBaseId + milestone);
        }
      } else if (type == 'duolingo_reminder') {
        // إلغاء تذكيرات Duolingo
        for (int i = 1; i <= 30; i++) {
          await _flutterLocalNotificationsPlugin
              .cancel(duolingoReminderId + i);
        }
      }

      debugPrint('✅ تم إلغاء إشعارات النوع: $type');
    } catch (e) {
      debugPrint('❌ خطأ في إلغاء إشعارات النوع $type: $e');
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
    } catch (e) {
      debugPrint('❌ خطأ في فحص الإشعارات المجدولة: $e');
      return [];
    }
  }

  // =====================
  // Helper Methods
  // =====================

  String _getChannelName(String channelId) {
    switch (channelId) {
      case channelBackground:
        return 'خدمة الخلفية';
      case channelReminders:
        return 'التذكيرات الذكية';
      case channelInsights:
        return 'الرؤى والتحليلات';
      case channelSleep:
        return 'تتبع النوم';
      case channelHealth:
        return 'الصحة واللياقة';
      case channelMotivation:
        return 'التحفيز والإنجازات';
      case channelAlerts:
        return 'تنبيهات مهمة';
      case channelPhone:
        return 'استخدام الهاتف';
      default:
        return 'إشعارات عامة';
    }
  }

  String _getChannelDescription(String channelId) {
    switch (channelId) {
      case channelBackground:
        return 'تتبع مستمر في الخلفية';
      case channelReminders:
        return 'تذكيرات ذكية';
      case channelInsights:
        return 'رؤى ذكية';
      case channelSleep:
        return 'إشعارات النوم';
      case channelHealth:
        return 'إشعارات النشاط';
      case channelMotivation:
        return 'رسائل تحفيزية';
      case channelAlerts:
        return 'تنبيهات مهمة';
      case channelPhone:
        return 'تنبيهات الهاتف';
      default:
        return 'إشعارات عامة';
    }
  }

  Importance _getChannelImportance(String channelId) {
    switch (channelId) {
      case channelBackground:
        return Importance.low;
      case channelAlerts:
        return Importance.max;
      case channelReminders:
        return Importance.high;
      case channelSleep:
        return Importance.high;
      default:
        return Importance.defaultImportance;
    }
  }

  Priority _getChannelPriority(String channelId) {
    switch (channelId) {
      case channelBackground:
        return Priority.low;
      case channelAlerts:
        return Priority.max;
      case channelReminders:
        return Priority.high;
      case channelSleep:
        return Priority.high;
      default:
        return Priority.defaultPriority;
    }
  }

  bool _shouldVibrate(String channelId) {
    return channelId == channelAlerts || channelId == channelReminders;
  }

  // =====================
  // Cleanup
  // =====================

  Future<void> dispose() async {
    _smartNotificationTimer?.cancel();
    _smartNotificationTimer = null;
    _isInitialized = false;
    debugPrint('🗑️ تم التخلص من خدمة الإشعارات');
  }
}