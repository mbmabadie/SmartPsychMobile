// lib/core/database/models/hourly_usage_entry.dart
// موديل لحفظ بيانات المراقبة الساعية

class HourlyUsageEntry {
  final int? id;
  final String date;           // '2025-01-15'
  final int hour;              // 14 (للساعة 2 بعد الظهر)
  final String packageName;
  final String appName;
  final double usageMinutes;   // دقائق الاستخدام في هذه الساعة
  final int openCount;         // عدد مرات الفتح في هذه الساعة
  final DateTime startTime;    // بداية الساعة
  final DateTime endTime;      // نهاية الساعة
  final DateTime createdAt;

  HourlyUsageEntry({
    this.id,
    required this.date,
    required this.hour,
    required this.packageName,
    required this.appName,
    required this.usageMinutes,
    required this.openCount,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
  });

  // تحويل من Map (من قاعدة البيانات)
  factory HourlyUsageEntry.fromMap(Map<String, dynamic> map) {
    return HourlyUsageEntry(
      id: map['id'] as int?,
      date: map['date'] as String,
      hour: map['hour'] as int,
      packageName: map['package_name'] as String,
      appName: map['app_name'] as String,
      usageMinutes: (map['usage_minutes'] as num).toDouble(),
      openCount: map['open_count'] as int,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
      endTime: DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  // تحويل إلى Map (لحفظ في قاعدة البيانات)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'hour': hour,
      'package_name': packageName,
      'app_name': appName,
      'usage_minutes': usageMinutes,
      'open_count': openCount,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  // نسخ مع تعديل
  HourlyUsageEntry copyWith({
    int? id,
    String? date,
    int? hour,
    String? packageName,
    String? appName,
    double? usageMinutes,
    int? openCount,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? createdAt,
  }) {
    return HourlyUsageEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      hour: hour ?? this.hour,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      usageMinutes: usageMinutes ?? this.usageMinutes,
      openCount: openCount ?? this.openCount,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'HourlyUsageEntry(id: $id, date: $date, hour: $hour, app: $appName, usage: ${usageMinutes}min, opens: $openCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HourlyUsageEntry &&
        other.date == date &&
        other.hour == hour &&
        other.packageName == packageName;
  }

  @override
  int get hashCode {
    return date.hashCode ^ hour.hashCode ^ packageName.hashCode;
  }

  // دوال مساعدة

  // دوال مساعدة

  /// تحويل دقائق الاستخدام إلى Duration
  Duration get usageDuration => Duration(minutes: usageMinutes.round());

  /// الحصول على الساعة بتنسيق نصي
  String get hourString => '${hour.toString().padLeft(2, '0')}:00';

  /// فحص إذا كانت الساعة في فترة الليل
  bool get isNightTime => hour >= 22 || hour <= 6;

  /// فحص إذا كانت الساعة في فترة العمل
  bool get isWorkTime => hour >= 9 && hour <= 17;

  /// الحصول على اسم الفترة
  String get periodName {
    if (hour >= 6 && hour < 12) return 'الصباح';
    if (hour >= 12 && hour < 18) return 'بعد الظهر';
    if (hour >= 18 && hour < 22) return 'المساء';
    return 'الليل';
  }

  /// الحصول على لون الفترة
  int get periodColor {
    if (hour >= 6 && hour < 12) return 0xFFFFC107; // أصفر للصباح
    if (hour >= 12 && hour < 18) return 0xFFFF9800; // برتقالي لبعد الظهر
    if (hour >= 18 && hour < 22) return 0xFF9C27B0; // بنفسجي للمساء
    return 0xFF3F51B5; // أزرق للليل
  }

  /// تحويل إلى Map للمخطط
  Map<String, dynamic> toChartData() {
    return {
      'hour': hour,
      'usage_minutes': usageMinutes,
      'pickups': openCount,
      'apps_used': [appName],
      'is_future': false,
      'period_name': periodName,
      'period_color': periodColor,
    };
  }

  /// فحص إذا كان الاستخدام مفرط
  bool get isExcessiveUsage => usageMinutes > 60; // أكثر من ساعة في ساعة واحدة

  /// فحص إذا كان هناك استخدام
  bool get hasUsage => usageMinutes > 0;

  /// تقييم شدة الاستخدام
  String get usageIntensity {
    if (usageMinutes == 0) return 'لا يوجد';
    if (usageMinutes <= 5) return 'قليل';
    if (usageMinutes <= 15) return 'متوسط';
    if (usageMinutes <= 30) return 'عالي';
    return 'مفرط';
  }

  /// الحصول على رمز الاستخدام
  String get usageIcon {
    if (usageMinutes == 0) return '⚫';
    if (usageMinutes <= 5) return '🟢';
    if (usageMinutes <= 15) return '🟡';
    if (usageMinutes <= 30) return '🟠';
    return '🔴';
  }
}