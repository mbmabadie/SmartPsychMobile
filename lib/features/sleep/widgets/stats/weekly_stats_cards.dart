// lib/features/sleep/widgets/stats/weekly_stats_cards.dart - النسخة المعدلة

import 'package:flutter/material.dart';
import '../../../../core/providers/sleep_tracking_provider.dart';
import '../../../../shared/theme/app_colors.dart';

class WeeklyStatsCards extends StatelessWidget {
  final SleepTrackingProvider provider;

  const WeeklyStatsCards({
    Key? key,
    required this.provider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sessions = provider.state.recentSessions;

    if (sessions.isEmpty) {
      return Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: Column(
          children: [
            Icon(
              Icons.assessment_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            SizedBox(height: 12),
            Text(
              'لا توجد إحصائيات بعد',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final bestSession = _getBestSession(sessions);
    final worstSession = _getWorstSession(sessions);
    final avgQuality = provider.state.averageQualityScore;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            '📈 إحصائيات الأسبوع',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),

        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                title: 'متوسط الجودة',
                value: avgQuality.toStringAsFixed(1),
                subtitle: '/10',
                icon: '⭐',
                color: _getQualityColor(avgQuality),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                title: 'أفضل ليلة',
                value: bestSession != null
                    ? bestSession.qualityScore?.toStringAsFixed(1) ?? '--'
                    : '--',
                subtitle: _getDayName(bestSession?.startTime),
                icon: '🏆',
                color: AppColors.success,
              ),
            ),
          ],
        ),

        SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                title: 'أسوأ ليلة',
                value: worstSession != null
                    ? worstSession.qualityScore?.toStringAsFixed(1) ?? '--'
                    : '--',
                subtitle: _getDayName(worstSession?.startTime),
                icon: '📉',
                color: AppColors.warning,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                title: 'ليالي مُتتبعة',
                value: sessions.length.toString(),
                subtitle: 'جلسة',
                icon: '📅',
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      BuildContext context, {
        required String title,
        required String value,
        required String subtitle,
        required String icon,
        required Color color,
      }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                icon,
                style: TextStyle(fontSize: 28),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color, width: 1),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: color,
                  size: 16,
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),

          SizedBox(height: 4),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(width: 4),
              Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  dynamic _getBestSession(List sessions) {
    if (sessions.isEmpty) return null;

    dynamic best = sessions.first;
    for (var session in sessions) {
      if ((session.qualityScore ?? 0) > (best.qualityScore ?? 0)) {
        best = session;
      }
    }
    return best;
  }

  dynamic _getWorstSession(List sessions) {
    if (sessions.isEmpty) return null;

    dynamic worst = sessions.first;
    for (var session in sessions) {
      if ((session.qualityScore ?? 10) < (worst.qualityScore ?? 10)) {
        worst = session;
      }
    }
    return worst;
  }

  String _getDayName(DateTime? date) {
    if (date == null) return '';
    final days = [
      'الأحد',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت'
    ];
    return days[date.weekday % 7];
  }

  Color _getQualityColor(double quality) {
    if (quality >= 8) return AppColors.success;
    if (quality >= 6) return AppColors.primary;
    if (quality >= 4) return AppColors.warning;
    return AppColors.error;
  }
}