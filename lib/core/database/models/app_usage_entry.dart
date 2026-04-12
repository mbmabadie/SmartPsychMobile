// lib/core/database/models/app_usage_entry.dart
import 'package:flutter/material.dart';

@immutable
class AppUsageEntry {
  final int? id;
  final String appName;
  final String packageName;
  final Duration totalUsageTime;
  final int openCount;
  final DateTime? lastUsedTime;
  final String date; // YYYY-MM-DD format
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppUsageEntry({
    this.id,
    required this.appName,
    required this.packageName,
    required this.totalUsageTime,
    required this.openCount,
    this.lastUsedTime,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppUsageEntry.fromMap(Map<String, dynamic> map) {
    return AppUsageEntry(
      id: map['id'] as int?,
      appName: map['app_name'] as String,
      packageName: map['package_name'] as String,
      totalUsageTime: Duration(milliseconds: map['total_usage_time'] as int? ?? 0),
      openCount: map['open_count'] as int? ?? 0,
      lastUsedTime: map['last_used_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_used_time'] as int)
          : null,
      date: map['date'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'app_name': appName,
      'package_name': packageName,
      'total_usage_time': totalUsageTime.inMilliseconds,
      'open_count': openCount,
      'last_used_time': lastUsedTime?.millisecondsSinceEpoch,
      'date': date,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  AppUsageEntry copyWith({
    int? id,
    String? appName,
    String? packageName,
    Duration? totalUsageTime,
    int? openCount,
    DateTime? lastUsedTime,
    String? date,
    DateTime? updatedAt,
  }) {
    return AppUsageEntry(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      packageName: packageName ?? this.packageName,
      totalUsageTime: totalUsageTime ?? this.totalUsageTime,
      openCount: openCount ?? this.openCount,
      lastUsedTime: lastUsedTime ?? this.lastUsedTime,
      date: date ?? this.date,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'AppUsageEntry(app: $appName, usage: ${totalUsageTime.inMinutes}min, opens: $openCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUsageEntry &&
        other.id == id &&
        other.appName == appName &&
        other.packageName == packageName &&
        other.date == date;
  }

  @override
  int get hashCode => Object.hash(id, appName, packageName, date);
}