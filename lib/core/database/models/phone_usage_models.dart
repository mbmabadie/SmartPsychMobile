// lib/core/database/models/phone_usage_models.dart
import 'package:flutter/material.dart';

/// Phone Usage Session class - فئة جلسة استخدام الهاتف
@immutable
class PhoneUsageSession {
  final int? id;
  final DateTime startTime; // ✅ إضافة startTime
  final DateTime? endTime; // ✅ إضافة endTime
  final String date; // YYYY-MM-DD format
  final Duration totalUsageTime;
  final int totalPickups;
  final DateTime? firstPickupTime;
  final DateTime? lastUsageTime;
  final Duration nightUsageDuration;
  final int sleepInterruptions;
  final bool isCompleted; // ✅ إضافة isCompleted
  final int pickupCount; // ✅ إضافة alias للتوافق
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AppUsage> appUsages;

  const PhoneUsageSession({
    this.id,
    required this.startTime, // ✅ مطلوب
    this.endTime, // ✅ اختياري
    required this.date,
    required this.totalUsageTime,
    this.totalPickups = 0,
    this.firstPickupTime,
    this.lastUsageTime,
    this.nightUsageDuration = const Duration(), // ✅ إصلاح Duration.zero
    this.sleepInterruptions = 0,
    this.isCompleted = false, // ✅ افتراضي false
    required this.createdAt,
    required this.updatedAt,
    this.appUsages = const [],
  }) : pickupCount = totalPickups; // ✅ ربط pickupCount بـ totalPickups

  factory PhoneUsageSession.fromMap(Map<String, dynamic> map) {
    return PhoneUsageSession(
      id: map['id'] as int?,
      startTime: map['start_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int)
          : DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int), // fallback
      endTime: map['end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int)
          : null,
      date: map['date'] as String,
      totalUsageTime: Duration(milliseconds: map['total_usage_time'] as int? ?? 0),
      totalPickups: map['total_pickups'] as int? ?? 0,
      firstPickupTime: map['first_pickup_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['first_pickup_time'] as int)
          : null,
      lastUsageTime: map['last_usage_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_usage_time'] as int)
          : null,
      nightUsageDuration: Duration(milliseconds: map['night_usage_duration'] as int? ?? 0),
      sleepInterruptions: map['sleep_interruptions'] as int? ?? 0,
      isCompleted: (map['is_completed'] as int?) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'date': date,
      'total_usage_time': totalUsageTime.inMilliseconds,
      'total_pickups': totalPickups,
      'first_pickup_time': firstPickupTime?.millisecondsSinceEpoch,
      'last_usage_time': lastUsageTime?.millisecondsSinceEpoch,
      'night_usage_duration': nightUsageDuration.inMilliseconds,
      'sleep_interruptions': sleepInterruptions,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  PhoneUsageSession copyWith({
    int? id,
    DateTime? startTime,
    DateTime? endTime,
    String? date,
    Duration? totalUsageTime,
    int? totalPickups,
    DateTime? firstPickupTime,
    DateTime? lastUsageTime,
    Duration? nightUsageDuration,
    int? sleepInterruptions,
    bool? isCompleted,
    DateTime? updatedAt,
    List<AppUsage>? appUsages,
  }) {
    return PhoneUsageSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      date: date ?? this.date,
      totalUsageTime: totalUsageTime ?? this.totalUsageTime,
      totalPickups: totalPickups ?? this.totalPickups,
      firstPickupTime: firstPickupTime ?? this.firstPickupTime,
      lastUsageTime: lastUsageTime ?? this.lastUsageTime,
      nightUsageDuration: nightUsageDuration ?? this.nightUsageDuration,
      sleepInterruptions: sleepInterruptions ?? this.sleepInterruptions,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      appUsages: appUsages ?? this.appUsages,
    );
  }

  // Computed properties
  Duration get duration => endTime != null ? endTime!.difference(startTime) : totalUsageTime;
  bool get isActive => !isCompleted && endTime == null;
  bool get hasExcessiveUsage => totalUsageTime.inHours > 6;
  bool get hasExcessivePickups => totalPickups > 100;

  String get formattedUsageTime {
    final hours = totalUsageTime.inHours;
    final minutes = totalUsageTime.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  String get usageCategory {
    final hours = totalUsageTime.inHours;
    if (hours <= 2) return 'معتدل';
    if (hours <= 4) return 'متوسط';
    if (hours <= 6) return 'مرتفع';
    return 'مفرط';
  }

  @override
  String toString() {
    return 'PhoneUsageSession(date: $date, usage: $formattedUsageTime, pickups: $totalPickups, completed: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PhoneUsageSession &&
        other.id == id &&
        other.date == date &&
        other.startTime == startTime;
  }

  @override
  int get hashCode => Object.hash(id, date, startTime);
}

/// App Usage class - فئة استخدام التطبيق
@immutable
class AppUsage {
  final int? id;
  final int phoneSessionId;
  final String packageName;
  final String? appName;
  final String? category;
  final Duration usageTime;
  final int openCount;
  final DateTime? firstUsed;
  final DateTime? lastUsed;
  final DateTime createdAt;

  const AppUsage({
    this.id,
    required this.phoneSessionId,
    required this.packageName,
    this.appName,
    this.category,
    required this.usageTime,
    this.openCount = 0,
    this.firstUsed,
    this.lastUsed,
    required this.createdAt,
  });

  factory AppUsage.fromMap(Map<String, dynamic> map) {
    return AppUsage(
      id: map['id'] as int?,
      phoneSessionId: map['phone_session_id'] as int,
      packageName: map['package_name'] as String,
      appName: map['app_name'] as String?,
      category: map['category'] as String?,
      usageTime: Duration(milliseconds: map['usage_time'] as int? ?? 0),
      openCount: map['open_count'] as int? ?? 0,
      firstUsed: map['first_used'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['first_used'] as int)
          : null,
      lastUsed: map['last_used'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_used'] as int)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phone_session_id': phoneSessionId,
      'package_name': packageName,
      'app_name': appName,
      'category': category,
      'usage_time': usageTime.inMilliseconds,
      'open_count': openCount,
      'first_used': firstUsed?.millisecondsSinceEpoch,
      'last_used': lastUsed?.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  AppUsage copyWith({
    int? id,
    int? phoneSessionId,
    String? packageName,
    String? appName,
    String? category,
    Duration? usageTime,
    int? openCount,
    DateTime? firstUsed,
    DateTime? lastUsed,
  }) {
    return AppUsage(
      id: id ?? this.id,
      phoneSessionId: phoneSessionId ?? this.phoneSessionId,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      category: category ?? this.category,
      usageTime: usageTime ?? this.usageTime,
      openCount: openCount ?? this.openCount,
      firstUsed: firstUsed ?? this.firstUsed,
      lastUsed: lastUsed ?? this.lastUsed,
      createdAt: createdAt,
    );
  }

  // Computed properties
  String get displayName => appName ?? packageName;

  String get formattedUsageTime {
    if (usageTime.inHours > 0) {
      return '${usageTime.inHours}h ${usageTime.inMinutes.remainder(60)}m';
    }
    return '${usageTime.inMinutes}m';
  }

  double get usagePercentage {
    // This would be calculated relative to total session usage
    // For now, return a placeholder
    return 0.0;
  }

  String get usageIntensity {
    final minutes = usageTime.inMinutes;
    if (minutes <= 5) return 'قليل';
    if (minutes <= 30) return 'معتدل';
    if (minutes <= 120) return 'كثير';
    return 'مفرط';
  }

  AppCategory get appCategory {
    switch (category?.toLowerCase()) {
      case 'social':
      case 'social_media':
        return AppCategory.social;
      case 'entertainment':
      case 'video':
        return AppCategory.entertainment;
      case 'productivity':
      case 'work':
        return AppCategory.productivity;
      case 'games':
      case 'gaming':
        return AppCategory.games;
      case 'education':
      case 'learning':
        return AppCategory.education;
      case 'health':
      case 'fitness':
        return AppCategory.health;
      case 'shopping':
        return AppCategory.shopping;
      case 'news':
        return AppCategory.news;
      case 'communication':
        return AppCategory.communication;
      case 'tools':
      case 'utilities':
        return AppCategory.tools;
      default:
        return AppCategory.other;
    }
  }

  @override
  String toString() {
    return 'AppUsage(app: $displayName, usage: $formattedUsageTime, opens: $openCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUsage &&
        other.id == id &&
        other.phoneSessionId == phoneSessionId &&
        other.packageName == packageName;
  }

  @override
  int get hashCode => Object.hash(id, phoneSessionId, packageName);
}

/// App Category enum - تصنيفات التطبيقات
enum AppCategory {
  social('اجتماعي'),
  entertainment('ترفيه'),
  productivity('إنتاجية'),
  games('ألعاب'),
  education('تعليم'),
  health('صحة'),
  shopping('تسوق'),
  news('أخبار'),
  communication('تواصل'),
  tools('أدوات'),
  other('أخرى');

  const AppCategory(this.displayName);
  final String displayName;

  @override
  String toString() => displayName;
}

/// Phone Usage Event class - فئة أحداث استخدام الهاتف
@immutable
class PhoneUsageEvent {
  final int? id;
  final int phoneSessionId;
  final PhoneEventType eventType;
  final DateTime timestamp;
  final String? packageName;
  final String? appName;
  final Duration? duration;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const PhoneUsageEvent({
    this.id,
    required this.phoneSessionId,
    required this.eventType,
    required this.timestamp,
    this.packageName,
    this.appName,
    this.duration,
    this.metadata,
    required this.createdAt,
  });

  factory PhoneUsageEvent.fromMap(Map<String, dynamic> map) {
    return PhoneUsageEvent(
      id: map['id'] as int?,
      phoneSessionId: map['phone_session_id'] as int,
      eventType: PhoneEventType.values.firstWhere(
            (e) => e.name == map['event_type'],
        orElse: () => PhoneEventType.unknown,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      packageName: map['package_name'] as String?,
      appName: map['app_name'] as String?,
      duration: map['duration'] != null
          ? Duration(milliseconds: map['duration'] as int)
          : null,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phone_session_id': phoneSessionId,
      'event_type': eventType.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'package_name': packageName,
      'app_name': appName,
      'duration': duration?.inMilliseconds,
      'metadata': metadata,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  PhoneUsageEvent copyWith({
    int? id,
    int? phoneSessionId,
    PhoneEventType? eventType,
    DateTime? timestamp,
    String? packageName,
    String? appName,
    Duration? duration,
    Map<String, dynamic>? metadata,
  }) {
    return PhoneUsageEvent(
      id: id ?? this.id,
      phoneSessionId: phoneSessionId ?? this.phoneSessionId,
      eventType: eventType ?? this.eventType,
      timestamp: timestamp ?? this.timestamp,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      duration: duration ?? this.duration,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
    );
  }

  @override
  String toString() {
    return 'PhoneUsageEvent(type: $eventType, app: $appName, time: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PhoneUsageEvent &&
        other.id == id &&
        other.phoneSessionId == phoneSessionId &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => Object.hash(id, phoneSessionId, timestamp);
}

/// Phone Event Type enum - أنواع أحداث الهاتف
enum PhoneEventType {
  screenOn('تشغيل الشاشة'),
  screenOff('إغلاق الشاشة'),
  appOpen('فتح تطبيق'),
  appClose('إغلاق تطبيق'),
  appUsage('استخدام تطبيق'),
  phoneUnlock('إلغاء القفل'),
  phoneLock('قفل الهاتف'),
  notification('إشعار'),
  call('مكالمة'),
  unknown('غير معروف');

  const PhoneEventType(this.displayName);
  final String displayName;

  @override
  String toString() => displayName;
}

/// Usage Statistics class - فئة الإحصائيات
@immutable
class UsageStatistics {
  final String date;
  final Duration totalScreenTime;
  final int totalPickups;
  final Duration averageSessionTime;
  final int totalNotifications;
  final Duration nightUsage;
  final Map<String, Duration> categoryUsage;
  final Map<String, int> categoryPickups;
  final List<String> topApps;
  final double wellnessScore;

  const UsageStatistics({
    required this.date,
    required this.totalScreenTime,
    required this.totalPickups,
    required this.averageSessionTime,
    required this.totalNotifications,
    required this.nightUsage,
    this.categoryUsage = const {},
    this.categoryPickups = const {},
    this.topApps = const [],
    required this.wellnessScore,
  });

  // Computed properties
  String get formattedScreenTime {
    final hours = totalScreenTime.inHours;
    final minutes = totalScreenTime.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  String get wellnessGrade {
    if (wellnessScore >= 0.9) return 'ممتاز';
    if (wellnessScore >= 0.8) return 'جيد جداً';
    if (wellnessScore >= 0.7) return 'جيد';
    if (wellnessScore >= 0.6) return 'مقبول';
    if (wellnessScore >= 0.5) return 'ضعيف';
    return 'ضعيف جداً';
  }

  bool get hasHealthyUsage => totalScreenTime.inHours <= 3 && totalPickups <= 50;
  bool get hasExcessiveUsage => totalScreenTime.inHours > 6 || totalPickups > 150;

  @override
  String toString() {
    return 'UsageStatistics(date: $date, screenTime: $formattedScreenTime, pickups: $totalPickups, wellness: ${(wellnessScore * 100).round()}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UsageStatistics && other.date == date;
  }

  @override
  int get hashCode => date.hashCode;
}