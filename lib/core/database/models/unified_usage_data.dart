// lib/core/database/models/unified_usage_data.dart
import 'package:flutter/foundation.dart';

/// نموذج البيانات الموحد للاستخدام الساعي
@immutable
class UnifiedHourlyUsageData {
  final String date;
  final int hour;
  final String packageName;
  final String appName;
  final double usageMinutes;
  final int openCount;
  final bool isCurrentHour;
  final bool isFinalized;
  final String dataSource; // 'live', 'captured', 'reconstructed'
  final DateTime lastSyncTime;
  final DateTime startTime;
  final DateTime endTime;

  const UnifiedHourlyUsageData({
    required this.date,
    required this.hour,
    required this.packageName,
    required this.appName,
    required this.usageMinutes,
    required this.openCount,
    this.isCurrentHour = false,
    this.isFinalized = false,
    this.dataSource = 'live',
    required this.lastSyncTime,
    required this.startTime,
    required this.endTime,
  });

  factory UnifiedHourlyUsageData.fromMap(Map<String, dynamic> map) {
    return UnifiedHourlyUsageData(
      date: map['date'] as String,
      hour: map['hour'] as int,
      packageName: map['package_name'] as String,
      appName: map['app_name'] as String,
      usageMinutes: (map['usage_minutes'] as num).toDouble(),
      openCount: map['open_count'] as int,
      isCurrentHour: (map['is_current_hour'] as int?) == 1,
      isFinalized: (map['is_finalized'] as int?) == 1,
      dataSource: map['data_source'] as String? ?? 'live',
      lastSyncTime: DateTime.fromMillisecondsSinceEpoch(
        map['last_sync_time'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
      endTime: DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'hour': hour,
      'package_name': packageName,
      'app_name': appName,
      'usage_minutes': usageMinutes,
      'open_count': openCount,
      'is_current_hour': isCurrentHour ? 1 : 0,
      'is_finalized': isFinalized ? 1 : 0,
      'data_source': dataSource,
      'last_sync_time': lastSyncTime.millisecondsSinceEpoch,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime.millisecondsSinceEpoch,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  UnifiedHourlyUsageData copyWith({
    String? date,
    int? hour,
    String? packageName,
    String? appName,
    double? usageMinutes,
    int? openCount,
    bool? isCurrentHour,
    bool? isFinalized,
    String? dataSource,
    DateTime? lastSyncTime,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return UnifiedHourlyUsageData(
      date: date ?? this.date,
      hour: hour ?? this.hour,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      usageMinutes: usageMinutes ?? this.usageMinutes,
      openCount: openCount ?? this.openCount,
      isCurrentHour: isCurrentHour ?? this.isCurrentHour,
      isFinalized: isFinalized ?? this.isFinalized,
      dataSource: dataSource ?? this.dataSource,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnifiedHourlyUsageData &&
        other.date == date &&
        other.hour == hour &&
        other.packageName == packageName;
  }

  @override
  int get hashCode => Object.hash(date, hour, packageName);

  @override
  String toString() {
    return 'UnifiedHourlyUsageData(date: $date, hour: $hour, app: $appName, usage: ${usageMinutes}min, source: $dataSource)';
  }
}

/// نموذج ملخص البيانات الساعية
@immutable
class HourlySummaryData {
  final String date;
  final int hour;
  final double totalUsageMinutes;
  final int totalOpenCount;
  final int appsCount;
  final List<String> topApps;
  final bool isCurrentHour;
  final bool hasRealData;
  final DateTime lastUpdated;

  const HourlySummaryData({
    required this.date,
    required this.hour,
    required this.totalUsageMinutes,
    required this.totalOpenCount,
    required this.appsCount,
    required this.topApps,
    this.isCurrentHour = false,
    this.hasRealData = false,
    required this.lastUpdated,
  });

  factory HourlySummaryData.fromHourlyData(List<UnifiedHourlyUsageData> hourlyData, int hour) {
    final hourData = hourlyData.where((d) => d.hour == hour).toList();

    if (hourData.isEmpty) {
      return HourlySummaryData(
        date: '',
        hour: hour,
        totalUsageMinutes: 0,
        totalOpenCount: 0,
        appsCount: 0,
        topApps: [],
        lastUpdated: DateTime.now(),
      );
    }

    final totalUsage = hourData.fold<double>(0, (sum, d) => sum + d.usageMinutes);
    final totalOpens = hourData.fold<int>(0, (sum, d) => sum + d.openCount);
    final apps = hourData.map((d) => d.appName).toList();
    apps.sort((a, b) => hourData.firstWhere((d) => d.appName == b).usageMinutes
        .compareTo(hourData.firstWhere((d) => d.appName == a).usageMinutes));

    return HourlySummaryData(
      date: hourData.first.date,
      hour: hour,
      totalUsageMinutes: totalUsage,
      totalOpenCount: totalOpens,
      appsCount: apps.length,
      topApps: apps.take(3).toList(),
      isCurrentHour: hourData.any((d) => d.isCurrentHour),
      hasRealData: totalUsage > 0,
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hour': hour,
      'usage_minutes': totalUsageMinutes,
      'pickups': totalOpenCount,
      'apps_used': topApps,
      'apps_count': appsCount,
      'is_current': isCurrentHour,
      'is_future': false,
      'has_real_data': hasRealData,
    };
  }

  @override
  String toString() {
    return 'HourlySummaryData(hour: $hour, usage: ${totalUsageMinutes}min, apps: $appsCount)';
  }
}