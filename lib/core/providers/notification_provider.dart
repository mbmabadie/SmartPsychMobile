// lib/core/providers/notification_provider.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../database/repositories/settings_repository.dart';
import 'base/base_state.dart';
import 'base/base_provider.dart';
import '../services/notification_service.dart';
import '../database/models/common_models.dart';


/// Notification Priority enum - أولوية الإشعار
enum NotificationPriority {
  low('منخفضة', Colors.grey, 1),
  normal('عادية', Colors.blue, 2),
  high('عالية', Colors.orange, 3),
  urgent('عاجلة', Colors.red, 4);

  const NotificationPriority(this.displayName, this.color, this.level);
  final String displayName;
  final Color color;
  final int level;
}

/// Notification Category enum - فئة الإشعار
enum NotificationCategory {
  reminder('تذكير', Icons.access_time),
  achievement('إنجاز', Icons.emoji_events),
  insight('رؤية', Icons.lightbulb),
  warning('تحذير', Icons.warning),
  goal('هدف', Icons.flag),
  health('صحة', Icons.favorite),
  system('نظام', Icons.settings);

  const NotificationCategory(this.displayName, this.icon);
  final String displayName;
  final IconData icon;
}

/// Smart Notification class - فئة الإشعار الذكي
@immutable
class SmartNotification {
  final String id;
  final String title;
  final String body;
  final NotificationCategory category;
  final NotificationPriority priority;
  final DateTime scheduledTime;
  final DateTime? deliveredTime;
  final bool isDelivered;
  final bool isRead;
  final bool isActionable;
  final String? actionText;
  final String? actionType;
  final Map<String, dynamic> payload;
  final DateTime? expiresAt;
  final List<String> tags;

  const SmartNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    this.priority = NotificationPriority.normal,
    required this.scheduledTime,
    this.deliveredTime,
    this.isDelivered = false,
    this.isRead = false,
    this.isActionable = false,
    this.actionText,
    this.actionType,
    this.payload = const {},
    this.expiresAt,
    this.tags = const [],
  });

  bool get isPending => !isDelivered && DateTime.now().isBefore(scheduledTime);
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isOverdue => !isDelivered && DateTime.now().isAfter(scheduledTime);
  bool get hasAction => isActionable && actionText != null;

  String get statusText {
    if (isExpired) return 'منتهي الصلاحية';
    if (isDelivered && isRead) return 'تم القراءة';
    if (isDelivered) return 'تم التسليم';
    if (isOverdue) return 'متأخر';
    if (isPending) return 'مجدول';
    return 'غير معروف';
  }

  SmartNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationCategory? category,
    NotificationPriority? priority,
    DateTime? scheduledTime,
    DateTime? deliveredTime,
    bool? isDelivered,
    bool? isRead,
    bool? isActionable,
    String? actionText,
    String? actionType,
    Map<String, dynamic>? payload,
    DateTime? expiresAt,
    List<String>? tags,
  }) {
    return SmartNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      deliveredTime: deliveredTime ?? this.deliveredTime,
      isDelivered: isDelivered ?? this.isDelivered,
      isRead: isRead ?? this.isRead,
      isActionable: isActionable ?? this.isActionable,
      actionText: actionText ?? this.actionText,
      actionType: actionType ?? this.actionType,
      payload: payload ?? this.payload,
      expiresAt: expiresAt ?? this.expiresAt,
      tags: tags ?? this.tags,
    );
  }

  @override
  String toString() {
    return 'SmartNotification(${category.displayName}: $title - ${priority.displayName})';
  }
}

/// Notification Schedule class - فئة جدولة الإشعارات
@immutable
class NotificationSchedule {
  final String id;
  final String name;
  final bool isEnabled;
  final List<int> weekdays; // 1-7 (Monday-Sunday)
  final TimeOfDay time;
  final String notificationTemplate;
  final NotificationCategory category;
  final NotificationPriority priority;

  const NotificationSchedule({
    required this.id,
    required this.name,
    required this.isEnabled,
    required this.weekdays,
    required this.time,
    required this.notificationTemplate,
    required this.category,
    this.priority = NotificationPriority.normal,
  });

  bool get isActiveToday {
    if (!isEnabled) return false;
    final today = DateTime.now().weekday;
    return weekdays.contains(today);
  }

  DateTime get nextScheduledTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, time.hour, time.minute);

    // If time hasn't passed today and is active today
    if (today.isAfter(now) && isActiveToday) {
      return today;
    }

    // Find next active day
    for (int i = 1; i <= 7; i++) {
      final futureDate = now.add(Duration(days: i));
      if (weekdays.contains(futureDate.weekday)) {
        return DateTime(
          futureDate.year,
          futureDate.month,
          futureDate.day,
          time.hour,
          time.minute,
        );
      }
    }

    // Fallback: next week same day
    return today.add(const Duration(days: 7));
  }

  NotificationSchedule copyWith({
    String? id,
    String? name,
    bool? isEnabled,
    List<int>? weekdays,
    TimeOfDay? time,
    String? notificationTemplate,
    NotificationCategory? category,
    NotificationPriority? priority,
  }) {
    return NotificationSchedule(
      id: id ?? this.id,
      name: name ?? this.name,
      isEnabled: isEnabled ?? this.isEnabled,
      weekdays: weekdays ?? this.weekdays,
      time: time ?? this.time,
      notificationTemplate: notificationTemplate ?? this.notificationTemplate,
      category: category ?? this.category,
      priority: priority ?? this.priority,
    );
  }

  @override
  String toString() {
    return 'NotificationSchedule($name: ${isEnabled ? "مفعل" : "معطل"})';
  }
}

/// Notification Statistics class - فئة إحصائيات الإشعارات
@immutable
class NotificationStatistics {
  final int totalSent;
  final int totalDelivered;
  final int totalRead;
  final int totalActedUpon;
  final Map<NotificationCategory, int> categoryBreakdown;
  final double deliveryRate;
  final double readRate;
  final double actionRate;

  const NotificationStatistics({
    required this.totalSent,
    required this.totalDelivered,
    required this.totalRead,
    required this.totalActedUpon,
    this.categoryBreakdown = const {},
    required this.deliveryRate,
    required this.readRate,
    required this.actionRate,
  });

  String get performanceSummary {
    if (readRate >= 0.8) return 'أداء ممتاز';
    if (readRate >= 0.6) return 'أداء جيد';
    if (readRate >= 0.4) return 'أداء متوسط';
    return 'يحتاج تحسين';
  }

  @override
  String toString() {
    return 'NotificationStats(sent: $totalSent, read: $totalRead, rate: ${(readRate * 100).round()}%)';
  }
}

/// Notification Tracking State class - فئة حالة تتبع الإشعارات
class NotificationTrackingState extends BaseState {
  final bool notificationsEnabled;
  final bool intelligentSchedulingEnabled;
  final List<SmartNotification> pendingNotifications;
  final List<SmartNotification> deliveredNotifications;
  final List<SmartNotification> recentNotifications;
  final List<NotificationSchedule> activeSchedules;
  final NotificationStatistics? statistics;
  final Map<NotificationCategory, bool> categorySettings;
  final TimeOfDay? quietHoursStart;
  final TimeOfDay? quietHoursEnd;
  final bool doNotDisturbEnabled;
  final int maxDailyNotifications;
  final Duration notificationCooldown;

  NotificationTrackingState({
    super.loadingState,
    super.error,
    super.lastUpdated,
    super.hasData,
    super.successMessage,
    this.notificationsEnabled = true,
    this.intelligentSchedulingEnabled = true,
    this.pendingNotifications = const [],
    this.deliveredNotifications = const [],
    this.recentNotifications = const [],
    this.activeSchedules = const [],
    this.statistics,
    this.categorySettings = const {},
    this.quietHoursStart,
    this.quietHoursEnd,
    this.doNotDisturbEnabled = false,
    this.maxDailyNotifications = 20,
    this.notificationCooldown = const Duration(minutes: 5),
  });

  factory NotificationTrackingState.initial() {
    return NotificationTrackingState(
      loadingState: LoadingState.idle,
      hasData: false,
      categorySettings: {
        for (final category in NotificationCategory.values) category: true
      },
    );
  }

  // Computed properties
  bool get hasNotifications => recentNotifications.isNotEmpty;
  bool get hasPendingNotifications => pendingNotifications.isNotEmpty;
  bool get hasUnreadNotifications => deliveredNotifications.any((n) => !n.isRead);
  bool get isQuietHoursActive => _isCurrentlyInQuietHours();
  bool get canSendNotifications => notificationsEnabled && !doNotDisturbEnabled;

  int get unreadCount => deliveredNotifications.where((n) => !n.isRead).length;
  int get todaysNotificationCount => _getTodaysNotificationCount();
  int get urgentNotificationCount => pendingNotifications.where((n) => n.priority == NotificationPriority.urgent).length;

  bool get hasReachedDailyLimit => todaysNotificationCount >= maxDailyNotifications;

  List<SmartNotification> get unreadNotifications =>
      deliveredNotifications.where((n) => !n.isRead).toList();

  List<SmartNotification> get urgentNotifications =>
      pendingNotifications.where((n) => n.priority == NotificationPriority.urgent).toList();

  List<SmartNotification> get actionableNotifications =>
      deliveredNotifications.where((n) => n.isActionable && !n.isRead).toList();

  bool _isCurrentlyInQuietHours() {
    if (quietHoursStart == null || quietHoursEnd == null) return false;

    final now = TimeOfDay.now();
    final startMinutes = quietHoursStart!.hour * 60 + quietHoursStart!.minute;
    final endMinutes = quietHoursEnd!.hour * 60 + quietHoursEnd!.minute;
    final nowMinutes = now.hour * 60 + now.minute;

    if (startMinutes <= endMinutes) {
      return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
    } else {
      return nowMinutes >= startMinutes || nowMinutes <= endMinutes;
    }
  }

  int _getTodaysNotificationCount() {
    final today = DateTime.now();
    return deliveredNotifications.where((notification) {
      final deliveredTime = notification.deliveredTime;
      if (deliveredTime == null) return false;

      return deliveredTime.year == today.year &&
          deliveredTime.month == today.month &&
          deliveredTime.day == today.day;
    }).length;
  }

  NotificationTrackingState copyWith({
    LoadingState? loadingState,
    AppError? error,
    DateTime? lastUpdated,
    bool? hasData,
    String? successMessage,
    bool? notificationsEnabled,
    bool? intelligentSchedulingEnabled,
    List<SmartNotification>? pendingNotifications,
    List<SmartNotification>? deliveredNotifications,
    List<SmartNotification>? recentNotifications,
    List<NotificationSchedule>? activeSchedules,
    NotificationStatistics? statistics,
    Map<NotificationCategory, bool>? categorySettings,
    TimeOfDay? quietHoursStart,
    TimeOfDay? quietHoursEnd,
    bool? doNotDisturbEnabled,
    int? maxDailyNotifications,
    Duration? notificationCooldown,
  }) {
    return NotificationTrackingState(
      loadingState: loadingState ?? this.loadingState,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      hasData: hasData ?? this.hasData,
      successMessage: successMessage ?? this.successMessage,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      intelligentSchedulingEnabled: intelligentSchedulingEnabled ?? this.intelligentSchedulingEnabled,
      pendingNotifications: pendingNotifications ?? this.pendingNotifications,
      deliveredNotifications: deliveredNotifications ?? this.deliveredNotifications,
      recentNotifications: recentNotifications ?? this.recentNotifications,
      activeSchedules: activeSchedules ?? this.activeSchedules,
      statistics: statistics ?? this.statistics,
      categorySettings: categorySettings ?? this.categorySettings,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      doNotDisturbEnabled: doNotDisturbEnabled ?? this.doNotDisturbEnabled,
      maxDailyNotifications: maxDailyNotifications ?? this.maxDailyNotifications,
      notificationCooldown: notificationCooldown ?? this.notificationCooldown,
    );
  }
}

/// Notification Tracking Provider class - مزود تتبع الإشعارات الذكية
class NotificationTrackingProvider extends BaseProvider<NotificationTrackingState>
    with PeriodicUpdateMixin<NotificationTrackingState>, CacheMixin<NotificationTrackingState> {

  final NotificationService _notificationService;
  final SettingsRepository _settingsRepo;

  Timer? _scheduleTimer;
  final Map<String, Timer> _pendingTimers = {};

  NotificationTrackingProvider({
    NotificationService? notificationService,
    SettingsRepository? settingsRepo,
  })  : _notificationService = notificationService ?? NotificationService.instance,
        _settingsRepo = settingsRepo ?? SettingsRepository(),
        super(NotificationTrackingState.initial()) {

    debugPrint('🔔 تهيئة NotificationTrackingProvider');
    _initializeProvider();
  }

  Future<void> _initializeProvider() async {
    await executeWithLoading(() async {
      await _loadSettings();
      await _loadNotificationHistory();
      await _loadActiveSchedules();
      await _startScheduling();

      setState(state.copyWith(hasData: true));
      debugPrint('🔔 تم تهيئة مزود تتبع الإشعارات');
    });
  }

  // ================================
  // Notification Management - إدارة الإشعارات
  // ================================

  /// إرسال إشعار ذكي
  Future<void> sendSmartNotification({
    required String title,
    required String body,
    required NotificationCategory category,
    NotificationPriority priority = NotificationPriority.normal,
    DateTime? scheduledTime,
    Map<String, dynamic> payload = const {},
    String? actionText,
    String? actionType,
    Duration? expiresAfter,
    List<String> tags = const [],
  }) async {
    if (!state.canSendNotifications) {
      debugPrint('❌ الإشعارات معطلة أو في وضع عدم الإزعاج');
      return;
    }

    // Check daily limit
    if (state.hasReachedDailyLimit && priority != NotificationPriority.urgent) {
      debugPrint('⚠️ تم الوصول للحد الأقصى من الإشعارات اليومية');
      return;
    }

    // Check category settings
    if (state.categorySettings[category] == false) {
      debugPrint('⚠️ فئة الإشعار ${category.displayName} معطلة');
      return;
    }

    await executeWithLoading(() async {
      final now = DateTime.now();
      final targetTime = scheduledTime ?? now;

      // Generate unique ID
      final notificationId = '${now.millisecondsSinceEpoch}_${category.name}';

      final smartNotification = SmartNotification(
        id: notificationId,
        title: title,
        body: body,
        category: category,
        priority: priority,
        scheduledTime: targetTime,
        isActionable: actionText != null,
        actionText: actionText,
        actionType: actionType,
        payload: payload,
        expiresAt: expiresAfter != null ? now.add(expiresAfter) : null,
        tags: tags,
      );

      if (targetTime.isAfter(now)) {
        // Schedule for later
        await _scheduleNotification(smartNotification);
      } else {
        // Send immediately
        await _deliverNotification(smartNotification);
      }

      setState(state.copyWith(
        successMessage: 'تم ${targetTime.isAfter(now) ? "جدولة" : "إرسال"} الإشعار',
      ));

      debugPrint('🔔 تم إنشاء إشعار: $title');
    });
  }

  /// جدولة إشعار متكرر
  Future<void> scheduleRecurringNotification({
    required String name,
    required String title,
    required String body,
    required NotificationCategory category,
    required List<int> weekdays,
    required TimeOfDay time,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    await executeWithLoading(() async {
      final scheduleId = DateTime.now().millisecondsSinceEpoch.toString();

      final schedule = NotificationSchedule(
        id: scheduleId,
        name: name,
        isEnabled: true,
        weekdays: weekdays,
        time: time,
        notificationTemplate: '$title|$body',
        category: category,
        priority: priority,
      );

      final updatedSchedules = [...state.activeSchedules, schedule];
      setState(state.copyWith(
        activeSchedules: updatedSchedules,
        successMessage: 'تم إنشاء جدولة إشعار متكررة: $name',
      ));

      await _saveSchedulesToSettings(updatedSchedules);
      await _updateScheduleTimers();

      debugPrint('📅 تم إنشاء جدولة متكررة: $name');
    });
  }

  /// تحديث جدولة إشعار
  Future<void> updateNotificationSchedule(String scheduleId, NotificationSchedule updatedSchedule) async {
    await executeWithLoading(() async {
      final updatedSchedules = state.activeSchedules.map((schedule) {
        return schedule.id == scheduleId ? updatedSchedule : schedule;
      }).toList();

      setState(state.copyWith(
        activeSchedules: updatedSchedules,
        successMessage: 'تم تحديث جدولة الإشعار',
      ));

      await _saveSchedulesToSettings(updatedSchedules);
      await _updateScheduleTimers();

      debugPrint('📝 تم تحديث جدولة: $scheduleId');
    });
  }

  /// حذف جدولة إشعار
  Future<void> deleteNotificationSchedule(String scheduleId) async {
    await executeWithLoading(() async {
      final updatedSchedules = state.activeSchedules.where((s) => s.id != scheduleId).toList();

      setState(state.copyWith(
        activeSchedules: updatedSchedules,
        successMessage: 'تم حذف جدولة الإشعار',
      ));

      await _saveSchedulesToSettings(updatedSchedules);
      await _updateScheduleTimers();

      debugPrint('🗑️ تم حذف جدولة: $scheduleId');
    });
  }

  /// تحديد الإشعار كمقروء
  Future<void> markNotificationAsRead(String notificationId) async {
    final updatedDelivered = state.deliveredNotifications.map((notification) {
      if (notification.id == notificationId) {
        return notification.copyWith(isRead: true);
      }
      return notification;
    }).toList();

    final updatedRecent = state.recentNotifications.map((notification) {
      if (notification.id == notificationId) {
        return notification.copyWith(isRead: true);
      }
      return notification;
    }).toList();

    setState(state.copyWith(
      deliveredNotifications: updatedDelivered,
      recentNotifications: updatedRecent,
    ));

    debugPrint('👁️ تم تحديد الإشعار كمقروء: $notificationId');
  }

  /// تحديد جميع الإشعارات كمقروءة
  Future<void> markAllNotificationsAsRead() async {
    final updatedDelivered = state.deliveredNotifications.map((n) => n.copyWith(isRead: true)).toList();
    final updatedRecent = state.recentNotifications.map((n) => n.copyWith(isRead: true)).toList();

    setState(state.copyWith(
      deliveredNotifications: updatedDelivered,
      recentNotifications: updatedRecent,
      successMessage: 'تم تحديد جميع الإشعارات كمقروءة',
    ));

    debugPrint('👁️ تم تحديد جميع الإشعارات كمقروءة');
  }

  /// تنفيذ إجراء الإشعار
  Future<void> executeNotificationAction(String notificationId, String actionType) async {
    final notification = state.deliveredNotifications
        .where((n) => n.id == notificationId)
        .firstOrNull;

    if (notification == null) {
      debugPrint('❌ الإشعار غير موجود: $notificationId');
      return;
    }

    await executeWithLoading(() async {
      // Mark as read and acted upon
      await markNotificationAsRead(notificationId);

      // Handle different action types
      switch (actionType) {
        case 'open_sleep_tracking':
          debugPrint('🌙 فتح تتبع النوم');
          break;
        case 'open_activity_tracking':
          debugPrint('🏃‍♀️ فتح تتبع النشاط');
          break;
        case 'open_nutrition_tracking':
          debugPrint('🍎 فتح تتبع التغذية');
          break;
        case 'snooze_reminder':
          await _snoozeNotification(notification);
          break;
        case 'dismiss':
          await _dismissNotification(notificationId);
          break;
        default:
          debugPrint('❓ نوع إجراء غير معروف: $actionType');
      }

      setState(state.copyWith(
        successMessage: 'تم تنفيذ إجراء الإشعار',
      ));

      debugPrint('⚡ تم تنفيذ إجراء: $actionType للإشعار: $notificationId');
    });
  }

  // ================================
  // Settings Management - إدارة الإعدادات
  // ================================

  /// تفعيل/إلغاء الإشعارات
  Future<void> toggleNotifications(bool enabled) async {
    setState(state.copyWith(notificationsEnabled: enabled));

    await _settingsRepo.setSetting('notifications_enabled', enabled, SettingValueType.bool);

    if (enabled) {
      await _startScheduling();
      debugPrint('🔔 تم تفعيل الإشعارات');
    } else {
      await _stopScheduling();
      debugPrint('🔕 تم إلغاء تفعيل الإشعارات');
    }
  }

  /// تفعيل/إلغاء الجدولة الذكية
  Future<void> toggleIntelligentScheduling(bool enabled) async {
    setState(state.copyWith(intelligentSchedulingEnabled: enabled));
    await _settingsRepo.setSetting('intelligent_scheduling', enabled, SettingValueType.bool);

    if (enabled) {
      await _optimizeScheduling();
    }

    debugPrint('🧠 الجدولة الذكية: ${enabled ? "مفعلة" : "معطلة"}');
  }

  /// تفعيل/إلغاء فئة إشعارات
  Future<void> toggleNotificationCategory(NotificationCategory category, bool enabled) async {
    final updatedSettings = Map<NotificationCategory, bool>.from(state.categorySettings);
    updatedSettings[category] = enabled;

    setState(state.copyWith(categorySettings: updatedSettings));

    await _settingsRepo.setSetting(
      'notification_category_${category.name}',
      enabled,
      SettingValueType.bool,
    );

    debugPrint('🏷️ فئة ${category.displayName}: ${enabled ? "مفعلة" : "معطلة"}');
  }

  /// تعديل ساعات الهدوء
  Future<void> setQuietHours({
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) async {
    setState(state.copyWith(
      quietHoursStart: startTime,
      quietHoursEnd: endTime,
    ));

    await _settingsRepo.setSetting('quiet_hours_start', '${startTime.hour}:${startTime.minute}', SettingValueType.string);
    await _settingsRepo.setSetting('quiet_hours_end', '${endTime.hour}:${endTime.minute}', SettingValueType.string);

    debugPrint('🤫 تم تعديل ساعات الهدوء: ${startTime.hour}:${startTime.minute} - ${endTime.hour}:${endTime.minute}');
  }

  /// تفعيل/إلغاء وضع عدم الإزعاج
  Future<void> toggleDoNotDisturb(bool enabled) async {
    setState(state.copyWith(doNotDisturbEnabled: enabled));
    await _settingsRepo.setSetting('do_not_disturb', enabled, SettingValueType.bool);

    debugPrint('🔕 وضع عدم الإزعاج: ${enabled ? "مفعل" : "معطل"}');
  }

  /// تعديل الحد الأقصى للإشعارات اليومية
  Future<void> setMaxDailyNotifications(int maxCount) async {
    if (maxCount < 1 || maxCount > 50) {
      throw ArgumentError('الحد الأقصى يجب أن يكون بين 1 و 50');
    }

    setState(state.copyWith(
      maxDailyNotifications: maxCount,
      successMessage: 'تم تحديد الحد الأقصى: $maxCount إشعار يومياً',
    ));

    await _settingsRepo.setSetting('max_daily_notifications', maxCount, SettingValueType.int);

    debugPrint('📊 تم تحديد الحد الأقصى للإشعارات اليومية: $maxCount');
  }

  /// تعديل فترة التهدئة بين الإشعارات
  Future<void> setNotificationCooldown(Duration cooldown) async {
    setState(state.copyWith(
      notificationCooldown: cooldown,
      successMessage: 'تم تحديد فترة التهدئة: ${cooldown.inMinutes} دقيقة',
    ));

    await _settingsRepo.setSetting('notification_cooldown_minutes', cooldown.inMinutes, SettingValueType.int);

    debugPrint('⏰ تم تحديد فترة التهدئة: ${cooldown.inMinutes} دقيقة');
  }

  // ================================
  // Smart Features - الميزات الذكية
  // ================================

  /// إرسال إشعار ذكي بناءً على السياق
  Future<void> sendContextualNotification({
    required String context,
    required Map<String, dynamic> data,
  }) async {
    if (!state.intelligentSchedulingEnabled) return;

    await executeWithLoading(() async {
      final notification = await _generateContextualNotification(context, data);

      if (notification != null) {
        await _deliverNotification(notification);

        setState(state.copyWith(
          successMessage: 'تم إرسال إشعار ذكي',
        ));

        debugPrint('🧠 تم إرسال إشعار ذكي للسياق: $context');
      }
    });
  }

  /// إرسال إشعار تحفيزي
  Future<void> sendMotivationalNotification() async {
    final motivationalMessages = [
      'أنت تحرز تقدماً رائعاً! استمر في هذا المسار 🌟',
      'كل خطوة صغيرة تقودك نحو هدفك الكبير 👣',
      'صحتك أهم استثمار في حياتك 💪',
      'اليوم هو فرصة جديدة لتحسين نفسك 🌅',
      'تذكر: التقدم أهم من الكمال ✨',
    ];

    final randomMessage = motivationalMessages[Random().nextInt(motivationalMessages.length)];

    await sendSmartNotification(
      title:'',
      body: randomMessage,
      category: NotificationCategory.achievement,
      priority: NotificationPriority.normal,
      tags: ['motivation', 'positive'],
    );
  }

  /// إرسال إشعار تذكير ذكي
  Future<void> sendIntelligentReminder({
    required String reminderType,
    Map<String, dynamic>? context,
  }) async {
    final now = DateTime.now();

    // تحديد أفضل وقت للتذكير
    final optimalTime = await _calculateOptimalReminderTime(reminderType, context);

    String title, body;
    NotificationCategory category;

    switch (reminderType) {
      case 'drink_water':
        title = '💧 وقت شرب الماء';
        body = 'حان وقت شرب كوب من الماء للحفاظ على ترطيب جسمك';
        category = NotificationCategory.health;
        break;
      case 'take_break':
        title = '🧘‍♀️ وقت الاستراحة';
        body = 'خذ استراحة قصيرة وحرك جسمك قليلاً';
        category = NotificationCategory.reminder;
        break;
      case 'sleep_preparation':
        title = '🌙 تحضير للنوم';
        body = 'حان وقت تحضير نفسك للنوم الهادئ';
        category = NotificationCategory.health;
        break;
      case 'meal_time':
        title = '🍽️ وقت الوجبة';
        body = 'لا تنس تناول وجبة صحية ومتوازنة';
        category = NotificationCategory.reminder;
        break;
      default:
        title = '⏰ تذكير';
        body = 'لديك تذكير مهم';
        category = NotificationCategory.reminder;
    }

    await sendSmartNotification(
      title: title,
      body: body,
      category: category,
      scheduledTime: optimalTime,
      actionText: 'تم',
      actionType: 'mark_completed',
      tags: ['reminder', reminderType],
    );
  }

  /// إرسال ملخص يومي
  Future<void> sendDailySummary(Map<String, dynamic> summaryData) async {
    final sleepHours = summaryData['sleep_hours'] ?? 0;
    final steps = summaryData['steps'] ?? 0;
    final phoneUsageHours = summaryData['phone_usage_hours'] ?? 0;

    String summaryText = 'ملخص يومك:\n';
    if (sleepHours > 0) summaryText += '• النوم: ${sleepHours}h\n';
    if (steps > 0) summaryText += '• الخطوات: ${steps.toString()}\n';
    if (phoneUsageHours > 0) summaryText += '• استخدام الهاتف: ${phoneUsageHours}h';

    await sendSmartNotification(
      title: '📊 ملخص اليوم',
      body: summaryText,
      category: NotificationCategory.insight,
      priority: NotificationPriority.normal,
      actionText: 'عرض التفاصيل',
      actionType: 'open_daily_summary',
      tags: ['daily_summary', 'statistics'],
    );
  }

  /// إرسال إشعار إنجاز
  Future<void> sendAchievementNotification({
    required String achievementTitle,
    required String description,
    String? badgeIcon,
  }) async {
    await sendSmartNotification(
      title: '🏆 إنجاز جديد!',
      body: '$achievementTitle\n$description',
      category: NotificationCategory.achievement,
      priority: NotificationPriority.high,
      actionText: 'احتفل',
      actionType: 'celebrate_achievement',
      tags: ['achievement', 'celebration'],
    );
  }

  // ================================
  // Analytics and Insights - التحليلات والرؤى
  // ================================

  /// حساب إحصائيات الإشعارات
  Future<void> calculateNotificationStatistics() async {
    await executeWithLoading(() async {
      final allNotifications = [...state.deliveredNotifications, ...state.recentNotifications];

      if (allNotifications.isEmpty) {
        setState(state.copyWith(
          statistics: const NotificationStatistics(
            totalSent: 0,
            totalDelivered: 0,
            totalRead: 0,
            totalActedUpon: 0,
            deliveryRate: 0.0,
            readRate: 0.0,
            actionRate: 0.0,
          ),
        ));
        return;
      }

      final totalSent = allNotifications.length;
      final totalDelivered = allNotifications.where((n) => n.isDelivered).length;
      final totalRead = allNotifications.where((n) => n.isRead).length;
      final totalActedUpon = allNotifications.where((n) => n.hasAction && n.isRead).length;

      final categoryBreakdown = <NotificationCategory, int>{};

      for (final notification in allNotifications) {
        categoryBreakdown[notification.category] =
            (categoryBreakdown[notification.category] ?? 0) + 1;
      }

      final deliveryRate = totalSent > 0 ? totalDelivered / totalSent : 0.0;
      final readRate = totalDelivered > 0 ? totalRead / totalDelivered : 0.0;
      final actionRate = totalRead > 0 ? totalActedUpon / totalRead : 0.0;

      final statistics = NotificationStatistics(
        totalSent: totalSent,
        totalDelivered: totalDelivered,
        totalRead: totalRead,
        totalActedUpon: totalActedUpon,
        categoryBreakdown: categoryBreakdown,
        deliveryRate: deliveryRate,
        readRate: readRate,
        actionRate: actionRate,
      );

      setState(state.copyWith(
        statistics: statistics,
        successMessage: 'تم حساب إحصائيات الإشعارات',
      ));

      debugPrint('📊 إحصائيات الإشعارات: معدل القراءة ${(readRate * 100).round()}%');
    });
  }

  /// الحصول على توصيات تحسين الإشعارات
  Future<List<String>> getNotificationRecommendations() async {
    return await executeWithResult(() async {
      final recommendations = <String>[];

      // تحليل الإحصائيات الحالية
      final stats = state.statistics;
      if (stats == null) return recommendations;

      if (stats.readRate < 0.5) {
        recommendations.add('معدل قراءة الإشعارات منخفض. جرب تحسين عناوين الإشعارات وجعلها أكثر جاذبية');
      }

      if (stats.actionRate < 0.3) {
        recommendations.add('معدل التفاعل مع الإشعارات منخفض. أضف إجراءات واضحة ومفيدة');
      }

      if (state.todaysNotificationCount > state.maxDailyNotifications * 0.8) {
        recommendations.add('تقترب من الحد الأقصى للإشعارات اليومية. فعّل الجدولة الذكية لتحسين التوقيت');
      }

      if (recommendations.isEmpty) {
        recommendations.add('أداء الإشعارات جيد! استمر في هذا المسار');
      }

      return recommendations;
    }) ?? [];
  }

  // ================================
  // Private Helper Methods - الدوال المساعدة الخاصة
  // ================================

  Future<void> _loadSettings() async {
    try {
      final notificationsEnabled = await _settingsRepo.getSetting<bool>('notifications_enabled', true) ?? true;
      final intelligentScheduling = await _settingsRepo.getSetting<bool>('intelligent_scheduling', true) ?? true;
      final doNotDisturb = await _settingsRepo.getSetting<bool>('do_not_disturb', false) ?? false;
      final maxDaily = await _settingsRepo.getSetting<int>('max_daily_notifications', 20) ?? 20;
      final cooldownMinutes = await _settingsRepo.getSetting<int>('notification_cooldown_minutes', 5) ?? 5;

      // Load category settings
      final categorySettings = <NotificationCategory, bool>{};
      for (final category in NotificationCategory.values) {
        final enabled = await _settingsRepo.getSetting<bool>('notification_category_${category.name}', true) ?? true;
        categorySettings[category] = enabled;
      }

      // Load quiet hours
      TimeOfDay? quietStart, quietEnd;
      final quietStartStr = await _settingsRepo.getStringOrNull('quiet_hours_start');
      final quietEndStr = await _settingsRepo.getStringOrNull('quiet_hours_end');

      if (quietStartStr != null) {
        try {
          final parts = quietStartStr.split(':');
          if (parts.length == 2) {
            quietStart = TimeOfDay(
                hour: int.parse(parts[0]),
                minute: int.parse(parts[1])
            );
          }
        } catch (e) {
          debugPrint('❌ خطأ في تحليل وقت بداية الهدوء: $e');
        }
      }

      if (quietEndStr != null) {
        try {
          final parts = quietEndStr.split(':');
          if (parts.length == 2) {
            quietEnd = TimeOfDay(
                hour: int.parse(parts[0]),
                minute: int.parse(parts[1])
            );
          }
        } catch (e) {
          debugPrint('❌ خطأ في تحليل وقت نهاية الهدوء: $e');
        }
      }

      setState(state.copyWith(
        notificationsEnabled: notificationsEnabled,
        intelligentSchedulingEnabled: intelligentScheduling,
        doNotDisturbEnabled: doNotDisturb,
        maxDailyNotifications: maxDaily,
        notificationCooldown: Duration(minutes: cooldownMinutes),
        categorySettings: categorySettings,
        quietHoursStart: quietStart,
        quietHoursEnd: quietEnd,
      ));

    } catch (e) {
      debugPrint('❌ خطأ في تحميل إعدادات الإشعارات: $e');
    }
  }

  Future<void> _loadNotificationHistory() async {
    // في التطبيق الحقيقي، ستأتي هذه البيانات من قاعدة البيانات
    final recentNotifications = <SmartNotification>[];
    final deliveredNotifications = <SmartNotification>[];

    setState(state.copyWith(
      recentNotifications: recentNotifications,
      deliveredNotifications: deliveredNotifications,
    ));
  }

  Future<void> _loadActiveSchedules() async {
    // تحميل الجدولات المحفوظة
    try {
      final schedules = <NotificationSchedule>[];
      setState(state.copyWith(activeSchedules: schedules));
    } catch (e) {
      debugPrint('❌ خطأ في تحميل جدولات الإشعارات: $e');
    }
  }

  Future<void> _saveSchedulesToSettings(List<NotificationSchedule> schedules) async {
    try {
      // في التطبيق الحقيقي، ستتم معالجة الكائنات وتحويلها إلى JSON
      await _settingsRepo.setSetting('notification_schedules', '[]', SettingValueType.string);
    } catch (e) {
      debugPrint('❌ خطأ في حفظ جدولات الإشعارات: $e');
    }
  }

  Future<void> _scheduleNotification(SmartNotification notification) async {
    // إضافة للقائمة المعلقة
    final updatedPending = [...state.pendingNotifications, notification];
    setState(state.copyWith(pendingNotifications: updatedPending));

    // جدولة Timer للتسليم
    final delay = notification.scheduledTime.difference(DateTime.now());
    if (delay.isNegative) {
      // إرسال فوراً إذا كان الوقت قد مضى
      await _deliverNotification(notification);
      return;
    }

    final timer = Timer(delay, () async {
      await _deliverNotification(notification);
      _pendingTimers.remove(notification.id);
    });

    _pendingTimers[notification.id] = timer;
  }

  Future<void> _deliverNotification(SmartNotification notification) async {
    try {
      // فحص القيود
      if (!_canDeliverNotification(notification)) {
        debugPrint('⚠️ لا يمكن تسليم الإشعار: ${notification.title}');
        return;
      }

      // إرسال عبر NotificationService
      await _notificationService.showNotification(
        id: notification.id.hashCode,
        title: notification.title,
        body: notification.body,
        channelId: _getChannelIdForCategory(notification.category),
        payload: notification.payload,
      );

      // تحديث الحالة
      final deliveredNotification = notification.copyWith(
        isDelivered: true,
        deliveredTime: DateTime.now(),
      );

      // إزالة من المعلقة وإضافة للمسلمة
      final updatedPending = state.pendingNotifications.where((n) => n.id != notification.id).toList();
      final updatedDelivered = [...state.deliveredNotifications, deliveredNotification];
      final updatedRecent = [deliveredNotification, ...state.recentNotifications.take(19)].toList();

      setState(state.copyWith(
        pendingNotifications: updatedPending,
        deliveredNotifications: updatedDelivered,
        recentNotifications: updatedRecent,
      ));

      debugPrint('✅ تم تسليم الإشعار: ${notification.title}');

    } catch (e) {
      debugPrint('❌ خطأ في تسليم الإشعار: $e');
    }
  }

  bool _canDeliverNotification(SmartNotification notification) {
    // فحص إذا كانت الإشعارات مفعلة
    if (!state.notificationsEnabled) return false;

    // فحص وضع عدم الإزعاج
    if (state.doNotDisturbEnabled && notification.priority != NotificationPriority.urgent) {
      return false;
    }

    // فحص ساعات الهدوء
    if (state.isQuietHoursActive && notification.priority != NotificationPriority.urgent) {
      return false;
    }

    // فحص إعدادات الفئة
    if (state.categorySettings[notification.category] == false) {
      return false;
    }

    // فحص الحد الأقصى اليومي
    if (state.hasReachedDailyLimit && notification.priority != NotificationPriority.urgent) {
      return false;
    }

    // فحص انتهاء الصلاحية
    if (notification.isExpired) return false;

    return true;
  }

  String _getChannelIdForCategory(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.reminder:
        return NotificationService.channelReminders;
     /* case NotificationCategory.achievement:
        return NotificationService.channelAchievements;*/
      case NotificationCategory.insight:
        return NotificationService.channelInsights;
      case NotificationCategory.health:
        return NotificationService.channelGeneral;
     /* case NotificationCategory.warning:
        return NotificationService.channelCritical;*/
      default:
        return NotificationService.channelGeneral;
    }
  }

  Future<void> _startScheduling() async {
    if (_scheduleTimer != null) return;

    _scheduleTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (!state.notificationsEnabled) return;

      await _checkScheduledNotifications();
      await _cleanupExpiredNotifications();
    });

    await _updateScheduleTimers();
  }

  Future<void> _stopScheduling() async {
    _scheduleTimer?.cancel();
    _scheduleTimer = null;

    // إلغاء جميع التايمرات المعلقة
    for (final timer in _pendingTimers.values) {
      timer.cancel();
    }
    _pendingTimers.clear();
  }

  Future<void> _updateScheduleTimers() async {
    // إعادة حساب جميع الجدولات النشطة
    for (final schedule in state.activeSchedules) {
      if (schedule.isEnabled && schedule.isActiveToday) {
        final nextTime = schedule.nextScheduledTime;
        final now = DateTime.now();

        if (nextTime.isAfter(now)) {
          // جدولة الإشعار التالي
          await _scheduleFromTemplate(schedule, nextTime);
        }
      }
    }
  }

  Future<void> _scheduleFromTemplate(NotificationSchedule schedule, DateTime scheduledTime) async {
    final parts = schedule.notificationTemplate.split('|');
    if (parts.length < 2) return;

    final title = parts[0];
    final body = parts[1];

    final notification = SmartNotification(
      id: '${schedule.id}_${scheduledTime.millisecondsSinceEpoch}',
      title: title,
      body: body,
      category: schedule.category,
      priority: schedule.priority,
      scheduledTime: scheduledTime,
      tags: ['scheduled', schedule.id],
    );

    await _scheduleNotification(notification);
  }

  Future<void> _checkScheduledNotifications() async {
    final now = DateTime.now();

    // فحص الإشعارات المعلقة التي حان وقتها
    final readyNotifications = state.pendingNotifications.where((notification) {
      return notification.scheduledTime.isBefore(now) || notification.scheduledTime.isAtSameMomentAs(now);
    }).toList();

    for (final notification in readyNotifications) {
      await _deliverNotification(notification);
    }
  }

  Future<void> _cleanupExpiredNotifications() async {
    final now = DateTime.now();

    // إزالة الإشعارات منتهية الصلاحية
    final validPending = state.pendingNotifications.where((n) => !n.isExpired).toList();
    final validDelivered = state.deliveredNotifications.where((n) => !n.isExpired).toList();

    if (validPending.length != state.pendingNotifications.length ||
        validDelivered.length != state.deliveredNotifications.length) {
      setState(state.copyWith(
        pendingNotifications: validPending,
        deliveredNotifications: validDelivered,
      ));
    }

    // إزالة الإشعارات القديمة (أكثر من 7 أيام)
    final cutoffDate = now.subtract(const Duration(days: 7));
    final recentDelivered = state.deliveredNotifications.where((notification) {
      final deliveredTime = notification.deliveredTime;
      return deliveredTime == null || deliveredTime.isAfter(cutoffDate);
    }).toList();

    if (recentDelivered.length != state.deliveredNotifications.length) {
      setState(state.copyWith(deliveredNotifications: recentDelivered));
    }
  }

  Future<SmartNotification?> _generateContextualNotification(String context, Map<String, dynamic> data) async {
    final now = DateTime.now();

    switch (context) {
      case 'sleep_quality_poor':
        return SmartNotification(
          id: '${now.millisecondsSinceEpoch}_sleep_poor',
          title: '😴 جودة نوم منخفضة',
          body: 'لوحظ انخفاض في جودة نومك. جرب تحسين بيئة النوم أو تقليل الضوء.',
          category: NotificationCategory.health,
          priority: NotificationPriority.high,
          scheduledTime: now,
          isActionable: true,
          actionText: 'نصائح النوم',
          actionType: 'open_sleep_tips',
          tags: ['sleep', 'health', 'contextual'],
        );

      case 'goal_achieved':
        final goalName = data['goal_name'] ?? 'هدف';
        return SmartNotification(
          id: '${now.millisecondsSinceEpoch}_goal_achieved',
          title: '🎉 تم تحقيق الهدف!',
          body: 'مبروك! حققت هدف "$goalName". استمر في هذا التقدم الرائع!',
          category: NotificationCategory.achievement,
          priority: NotificationPriority.high,
          scheduledTime: now,
          isActionable: true,
          actionText: 'احتفل',
          actionType: 'celebrate_achievement',
          tags: ['achievement', 'goal', 'celebration'],
        );

      case 'inactivity_detected':
        final hoursInactive = data['hours_inactive'] ?? 2;
        return SmartNotification(
          id: '${now.millisecondsSinceEpoch}_inactivity',
          title: '🏃‍♀️ وقت الحركة!',
          body: 'لم تتحرك لمدة $hoursInactive ساعات. حان وقت نشاط بسيط!',
          category: NotificationCategory.reminder,
          priority: NotificationPriority.normal,
          scheduledTime: now,
          isActionable: true,
          actionText: 'بدء نشاط',
          actionType: 'start_activity',
          tags: ['activity', 'reminder', 'health'],
        );

      default:
        return null;
    }
  }

  Future<DateTime> _calculateOptimalReminderTime(String reminderType, Map<String, dynamic>? context) async {
    final now = DateTime.now();

    // تحديد أفضل وقت بناءً على نوع التذكير
    switch (reminderType) {
      case 'drink_water':
      // كل ساعتين أثناء النهار
        var nextWaterTime = DateTime(now.year, now.month, now.day, now.hour + 2);
        if (nextWaterTime.hour > 22) {
          nextWaterTime = DateTime(now.year, now.month, now.day + 1, 8);
        }
        return nextWaterTime;

      case 'take_break':
      // كل 45 دقيقة أثناء ساعات العمل
        if (now.hour >= 9 && now.hour <= 17) {
          return now.add(const Duration(minutes: 45));
        } else {
          return DateTime(now.year, now.month, now.day + 1, 10);
        }

      case 'sleep_preparation':
      // ساعة قبل وقت النوم المعتاد (افتراضي 22:00)
        return DateTime(now.year, now.month, now.day, 21);

      case 'meal_time':
      // أوقات الوجبات التقليدية
        if (now.hour < 8) {
          return DateTime(now.year, now.month, now.day, 8); // إفطار
        } else if (now.hour < 13) {
          return DateTime(now.year, now.month, now.day, 13); // غداء
        } else if (now.hour < 19) {
          return DateTime(now.year, now.month, now.day, 19); // عشاء
        } else {
          return DateTime(now.year, now.month, now.day + 1, 8); // إفطار الغد
        }

      default:
        return now.add(const Duration(minutes: 30));
    }
  }

  Future<void> _optimizeScheduling() async {
    if (!state.intelligentSchedulingEnabled) return;

    // تحليل أنماط استخدام المستخدم وتحسين أوقات الإشعارات
    try {
      for (final schedule in state.activeSchedules) {
        if (!schedule.isEnabled) continue;

        // تحسين التوقيت بناءً على الفئة
        TimeOfDay optimizedTime = schedule.time;

        switch (schedule.category) {
          case NotificationCategory.health:
          // إشعارات الصحة في الصباح الباكر أو المساء
            if (schedule.time.hour > 12) {
              optimizedTime = const TimeOfDay(hour: 19, minute: 0);
            } else {
              optimizedTime = const TimeOfDay(hour: 8, minute: 0);
            }
            break;

          case NotificationCategory.reminder:
          // التذكيرات أثناء ساعات النشاط
            if (schedule.time.hour < 9 || schedule.time.hour > 20) {
              optimizedTime = const TimeOfDay(hour: 10, minute: 0);
            }
            break;

          case NotificationCategory.insight:
          // الرؤى في المساء للمراجعة
            optimizedTime = const TimeOfDay(hour: 20, minute: 0);
            break;

          default:
            break;
        }

        if (optimizedTime != schedule.time) {
          final optimizedSchedule = schedule.copyWith(time: optimizedTime);
          await updateNotificationSchedule(schedule.id, optimizedSchedule);
        }
      }

      debugPrint('🧠 تم تحسين جدولة الإشعارات بالذكاء الاصطناعي');

    } catch (e) {
      debugPrint('❌ خطأ في تحسين الجدولة: $e');
    }
  }

  Future<void> _snoozeNotification(SmartNotification notification) async {
    // تأجيل الإشعار لـ 10 دقائق
    final snoozeTime = DateTime.now().add(const Duration(minutes: 10));

    final snoozedNotification = notification.copyWith(
      id: '${notification.id}_snoozed',
      scheduledTime: snoozeTime,
      isDelivered: false,
      deliveredTime: null,
    );

    await _scheduleNotification(snoozedNotification);

    setState(state.copyWith(
      successMessage: 'تم تأجيل الإشعار لـ 10 دقائق',
    ));

    debugPrint('⏰ تم تأجيل الإشعار: ${notification.title}');
  }

  Future<void> _dismissNotification(String notificationId) async {
    // إزالة من جميع القوائم
    final updatedDelivered = state.deliveredNotifications.where((n) => n.id != notificationId).toList();
    final updatedRecent = state.recentNotifications.where((n) => n.id != notificationId).toList();
    final updatedPending = state.pendingNotifications.where((n) => n.id != notificationId).toList();

    setState(state.copyWith(
      deliveredNotifications: updatedDelivered,
      recentNotifications: updatedRecent,
      pendingNotifications: updatedPending,
    ));

    // إلغاء التايمر إذا كان موجوداً
    _pendingTimers[notificationId]?.cancel();
    _pendingTimers.remove(notificationId);

    debugPrint('🗑️ تم حذف الإشعار: $notificationId');
  }

  // ================================
  // Quick Actions - الإجراءات السريعة
  // ================================

  /// إرسال تذكير سريع
  Future<void> sendQuickReminder(String message, {Duration? delay}) async {
    await sendSmartNotification(
      title: '⏰ تذكير سريع',
      body: message,
      category: NotificationCategory.reminder,
      scheduledTime: delay != null ? DateTime.now().add(delay) : null,
      tags: ['quick_reminder'],
    );
  }

  /// إرسال إشعار عاجل
  Future<void> sendUrgentNotification(String title, String message) async {
    await sendSmartNotification(
      title: title,
      body: message,
      category: NotificationCategory.warning,
      priority: NotificationPriority.urgent,
      tags: ['urgent'],
    );
  }

  /// إرسال إشعار تجريبي
  Future<void> sendTestNotification() async {
    await sendSmartNotification(
      title: '🧪 إشعار تجريبي',
      body: 'هذا إشعار تجريبي للتأكد من عمل النظام بشكل صحيح.',
      category: NotificationCategory.system,
      priority: NotificationPriority.normal,
      actionText: 'تم الاختبار',
      actionType: 'test_completed',
      tags: ['test', 'development'],
    );

    debugPrint('🧪 تم إرسال إشعار تجريبي');
  }

  /// مسح جميع الإشعارات (للاختبار)
  Future<void> clearAllNotifications() async {
    // إلغاء جميع التايمرات المعلقة
    for (final timer in _pendingTimers.values) {
      timer.cancel();
    }
    _pendingTimers.clear();

    setState(state.copyWith(
      pendingNotifications: [],
      deliveredNotifications: [],
      recentNotifications: [],
      successMessage: 'تم مسح جميع الإشعارات',
    ));

    debugPrint('🧹 تم مسح جميع الإشعارات');
  }

  // ================================
  // Public Utility Methods - الدوال المساعدة العامة
  // ================================

  /// الحصول على إشعار بالمعرف
  SmartNotification? getNotificationById(String id) {
    for (final notification in [...state.pendingNotifications, ...state.deliveredNotifications, ...state.recentNotifications]) {
      if (notification.id == id) {
        return notification;
      }
    }
    return null;
  }

  /// الحصول على الإشعارات حسب الفئة
  List<SmartNotification> getNotificationsByCategory(NotificationCategory category) {
    return state.recentNotifications.where((n) => n.category == category).toList();
  }

  /// الحصول على الإشعارات حسب العلامات
  List<SmartNotification> getNotificationsByTags(List<String> tags) {
    return state.recentNotifications.where((notification) {
      return tags.any((tag) => notification.tags.contains(tag));
    }).toList();
  }

  /// فحص إذا كان هناك إشعار معلق لنفس النوع
  bool hasPendingNotificationOfType(String type) {
    return state.pendingNotifications.any((n) => n.tags.contains(type));
  }

  /// الحصول على العدد المتبقي من الإشعارات اليومية
  int getRemainingDailyNotifications() {
    return (state.maxDailyNotifications - state.todaysNotificationCount).clamp(0, state.maxDailyNotifications);
  }

  /// تقدير الوقت المتبقي لإشعار معلق
  Duration? getTimeUntilNotification(String notificationId) {
    final notification = state.pendingNotifications.where((n) => n.id == notificationId).firstOrNull;
    if (notification == null) return null;

    final now = DateTime.now();
    final scheduledTime = notification.scheduledTime;

    if (scheduledTime.isBefore(now)) return Duration.zero;
    return scheduledTime.difference(now);
  }

  /// إحصائيات سريعة
  Map<String, int> getQuickStats() {
    return {
      'pending': state.pendingNotifications.length,
      'delivered_today': state.todaysNotificationCount,
      'unread': state.unreadCount,
      'urgent': state.urgentNotificationCount,
      'actionable': state.actionableNotifications.length,
    };
  }

  // ================================
  // BaseProvider Implementation
  // ================================

  @override
  Future<void> refreshData() async {
    await _loadNotificationHistory();
    await calculateNotificationStatistics();
  }

  @override
  NotificationTrackingState _createLoadingState(bool isRefreshing) {
    return state.copyWith(
      loadingState: isRefreshing ? LoadingState.refreshing : LoadingState.loading,
      error: null,
      successMessage: null,
    );
  }

  @override
  NotificationTrackingState _createSuccessState({String? message}) {
    return state.copyWith(
      loadingState: LoadingState.success,
      error: null,
      successMessage: message,
      hasData: true,
    );
  }

  @override
  NotificationTrackingState _createErrorState(AppError error) {
    return state.copyWith(
      loadingState: LoadingState.error,
      error: error,
      successMessage: null,
    );
  }

  @override
  NotificationTrackingState _createIdleState() {
    return state.copyWith(
      loadingState: LoadingState.idle,
      error: null,
      successMessage: null,
    );
  }

  // PeriodicUpdateMixin implementation
  @override
  Future<void> performPeriodicUpdate() async {
    await _checkScheduledNotifications();
    await _cleanupExpiredNotifications();

    // تحديث الإحصائيات كل 30 دقيقة
    final now = DateTime.now();
    if (now.minute % 30 == 0) {
      await calculateNotificationStatistics();
    }
  }

  @override
  void dispose() {
    debugPrint('🗑️ تنظيف NotificationTrackingProvider');
    _stopScheduling();
    super.dispose();
  }
}