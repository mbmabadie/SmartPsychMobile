// lib/features/sleep/widgets/stats/sleep_patterns_card.dart - النسخة البسيطة

import 'package:flutter/material.dart';
import '../../../../core/providers/sleep_tracking_provider.dart';
import '../../../../shared/theme/app_colors.dart';

class SleepPatternsCard extends StatelessWidget {
  final SleepTrackingProvider provider;

  const SleepPatternsCard({
    Key? key,
    required this.provider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final patterns = _analyzePatterns();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: AppColors.primary),
              SizedBox(width: 12),
              Text(
                '📈 أنماط ملاحظة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          patterns.isEmpty
              ? _buildEmptyState()
              : Column(
            children: patterns.map((pattern) {
              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: _buildPatternItem(
                  context,
                  icon: pattern['icon'] as String,
                  text: pattern['text'] as String,
                  type: pattern['type'] as PatternType,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 48,
            color: AppColors.textMuted,
          ),
          SizedBox(height: 12),
          Text(
            'نحتاج المزيد من البيانات',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'سنحلل أنماط نومك بعد أسبوع من التتبع',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPatternItem(
      BuildContext context, {
        required String icon,
        required String text,
        required PatternType type,
      }) {
    final color = _getPatternColor(type);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color, width: 1),
            ),
            child: Text(
              icon,
              style: TextStyle(fontSize: 20),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
          Icon(
            _getPatternIcon(type),
            color: color,
            size: 20,
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _analyzePatterns() {
    final sessions = provider.state.recentSessions;
    if (sessions.length < 3) return [];

    final patterns = <Map<String, dynamic>>[];

    // تحليل الانتظام
    final consistentSleep = _checkConsistency(sessions);
    if (consistentSleep != null) {
      patterns.add(consistentSleep);
    }

    // تحليل استخدام الهاتف
    final phonePattern = _checkPhoneUsage(sessions);
    if (phonePattern != null) {
      patterns.add(phonePattern);
    }

    // تحليل جودة النوم العميق
    final deepSleepPattern = _checkDeepSleep(sessions);
    if (deepSleepPattern != null) {
      patterns.add(deepSleepPattern);
    }

    // تحليل الاستيقاظ المتأخر
    final lateWakePattern = _checkLateWake(sessions);
    if (lateWakePattern != null) {
      patterns.add(lateWakePattern);
    }

    return patterns;
  }

  Map<String, dynamic>? _checkConsistency(List sessions) {
    if (sessions.length < 5) return null;

    final recentSessions = sessions.take(7).toList();
    final consistentDays = recentSessions.where((session) {
      final startHour = session.startTime.hour;
      return startHour >= 21 || startHour <= 1;
    }).length;

    if (consistentDays >= 5) {
      return {
        'icon': '✅',
        'text': 'نمت في وقت ثابت $consistentDays/${recentSessions.length} أيام',
        'type': PatternType.positive,
      };
    }

    return null;
  }

  Map<String, dynamic>? _checkPhoneUsage(List sessions) {
    final phoneInterruptions = sessions
        .where((s) => (s.phoneActivations ?? 0) > 0)
        .length;

    if (phoneInterruptions >= 3) {
      return {
        'icon': '📱',
        'text': 'استخدام هاتف ليلي: $phoneInterruptions مرات هذا الأسبوع',
        'type': PatternType.warning,
      };
    }

    if (phoneInterruptions == 0 && sessions.length >= 5) {
      return {
        'icon': '🚫',
        'text': 'رائع! لم تستخدم الهاتف أثناء النوم',
        'type': PatternType.positive,
      };
    }

    return null;
  }

  Map<String, dynamic>? _checkDeepSleep(List sessions) {
    if (sessions.isEmpty) return null;

    final avgQuality = provider.state.averageQualityScore;

    if (avgQuality >= 8.0) {
      return {
        'icon': '🌙',
        'text': 'نوم عميق: ${avgQuality.toStringAsFixed(1)}/10 (ممتاز)',
        'type': PatternType.positive,
      };
    }

    if (avgQuality < 6.0) {
      return {
        'icon': '😴',
        'text': 'جودة النوم تحتاج تحسين (${avgQuality.toStringAsFixed(1)}/10)',
        'type': PatternType.negative,
      };
    }

    return null;
  }

  Map<String, dynamic>? _checkLateWake(List sessions) {
    if (sessions.length < 3) return null;

    final lateWakes = sessions.where((session) {
      if (session.endTime == null) return false;
      return session.endTime!.hour >= 9;
    }).length;

    if (lateWakes >= 2) {
      return {
        'icon': '⏰',
        'text': 'استيقظت متأخر $lateWakes مرات هذا الأسبوع',
        'type': PatternType.warning,
      };
    }

    return null;
  }

  Color _getPatternColor(PatternType type) {
    switch (type) {
      case PatternType.positive:
        return AppColors.success;
      case PatternType.warning:
        return AppColors.warning;
      case PatternType.negative:
        return AppColors.error;
      case PatternType.info:
        return AppColors.info;
    }
  }

  IconData _getPatternIcon(PatternType type) {
    switch (type) {
      case PatternType.positive:
        return Icons.check_circle;
      case PatternType.warning:
        return Icons.warning_amber;
      case PatternType.negative:
        return Icons.error;
      case PatternType.info:
        return Icons.info;
    }
  }
}

enum PatternType {
  positive,
  warning,
  negative,
  info,
}