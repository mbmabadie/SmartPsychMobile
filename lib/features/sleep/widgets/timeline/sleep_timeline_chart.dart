// lib/features/sleep/widgets/timeline/sleep_timeline_chart.dart - النسخة البسيطة

import 'package:flutter/material.dart';
import '../../../../core/database/models/sleep_models.dart';
import '../../../../core/database/models/environmental_conditions.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../core/theme/sleep_theme.dart';

class SleepTimelineChart extends StatelessWidget {
  final SleepSession session;
  final List<EnvironmentalConditions> environmentHistory;

  const SleepTimelineChart({
    Key? key,
    required this.session,
    required this.environmentHistory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hours = _generateTimelineHours();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary, width: 1),
                ),
                child: Icon(
                  Icons.timeline,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                '📅 الجدول الزمني',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          // Timeline
          ...hours.map((hour) => _buildTimelineRow(
            context,
            hour['time'] as String,
            hour['status'] as TimelineStatus,
            hour['event'] as String?,
          )).toList(),

          SizedBox(height: 20),

          // مراحل النوم
          _buildSleepPhasesLegend(context),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(
      BuildContext context,
      String time,
      TimelineStatus status,
      String? event,
      ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // الوقت
          SizedBox(
            width: 60,
            child: Text(
              time,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // الخط الزمني
          Column(
            children: [
              if (status != TimelineStatus.beforeSleep)
                Container(
                  width: 2,
                  height: 8,
                  color: _getStatusColor(status),
                ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
              ),
              if (status != TimelineStatus.afterWake)
                Container(
                  width: 2,
                  height: 8,
                  color: _getStatusColor(status),
                ),
            ],
          ),

          SizedBox(width: 12),

          // الحالة والحدث
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getStatusColor(status),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Text(_getStatusIcon(status)),
                  if (event != null) ...[
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepPhasesLegend(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPhaseLegendItem('💤 نوم عميق:', '65%', SleepColors.deepSleep),
          SizedBox(height: 6),
          _buildPhaseLegendItem('😴 نوم خفيف:', '30%', SleepColors.lightSleep),
          SizedBox(height: 6),
          _buildPhaseLegendItem('😮 مستيقظ:', '5%', SleepColors.awake),
        ],
      ),
    );
  }

  Widget _buildPhaseLegendItem(String label, String percentage, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: color, width: 1),
          ),
        ),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
        ),
        Spacer(),
        Text(
          percentage,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _generateTimelineHours() {
    final timeline = <Map<String, dynamic>>[];
    final startHour = session.startTime.hour;
    final endHour = session.endTime?.hour ?? DateTime.now().hour;

    int currentHour = startHour;
    for (int i = 0; i < 12; i++) {
      final status = _getHourStatus(currentHour, startHour, endHour, i);
      final event = _getHourEvent(currentHour, i);

      timeline.add({
        'time': _formatHour(currentHour),
        'status': status,
        'event': event,
      });

      currentHour = (currentHour + 1) % 24;
    }

    return timeline;
  }

  TimelineStatus _getHourStatus(int hour, int startHour, int endHour, int index) {
    if (index == 0) return TimelineStatus.sleepStart;
    if (hour == endHour) return TimelineStatus.wakeUp;
    if (index < 0) return TimelineStatus.beforeSleep;
    if (hour > endHour) return TimelineStatus.afterWake;

    // محاكاة مراحل النوم
    if (index >= 1 && index <= 3) return TimelineStatus.deepSleep;
    if (index >= 4 && index <= 7) return TimelineStatus.lightSleep;
    return TimelineStatus.sleeping;
  }

  String? _getHourEvent(int hour, int index) {
    // محاكاة الأحداث (يمكن استبدالها ببيانات حقيقية)
    if (index == 3) return '📱 انقطاع (رسالة)';
    if (index == 6) return '🔄 تململ';
    return null;
  }

  String _formatHour(int hour) {
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final period = hour >= 12 ? 'م' : 'ص';
    return '$displayHour$period';
  }

  Color _getStatusColor(TimelineStatus status) {
    switch (status) {
      case TimelineStatus.beforeSleep:
      case TimelineStatus.afterWake:
        return AppColors.textMuted;
      case TimelineStatus.sleepStart:
        return AppColors.primary;
      case TimelineStatus.deepSleep:
        return SleepColors.deepSleep;
      case TimelineStatus.lightSleep:
        return SleepColors.lightSleep;
      case TimelineStatus.wakeUp:
        return AppColors.warning;
      case TimelineStatus.sleeping:
      default:
        return AppColors.primary;
    }
  }

  String _getStatusIcon(TimelineStatus status) {
    switch (status) {
      case TimelineStatus.sleepStart:
        return '😴';
      case TimelineStatus.deepSleep:
        return '💤';
      case TimelineStatus.lightSleep:
        return '😴';
      case TimelineStatus.wakeUp:
        return '☀️';
      case TimelineStatus.sleeping:
        return '😌';
      default:
        return '';
    }
  }
}

enum TimelineStatus {
  beforeSleep,
  sleepStart,
  deepSleep,
  lightSleep,
  sleeping,
  wakeUp,
  afterWake,
}