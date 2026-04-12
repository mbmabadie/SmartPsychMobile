// lib/features/sleep/widgets/sleep_stats_grid.dart - النسخة البسيطة

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/sleep_tracking_provider.dart';
import '../../../shared/theme/app_colors.dart';

class SleepStatsGrid extends StatelessWidget {
  const SleepStatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SleepTrackingProvider>(
      builder: (context, provider, child) {
        // حساب الإحصائيات من recentSessions مباشرة
        final sessions = provider.state.recentSessions.take(7).toList();

        // حساب متوسط ساعات النوم
        double avgHours = 0;
        if (sessions.isNotEmpty) {
          final totalHours = sessions
              .where((s) => s.duration != null)
              .map((s) => s.duration!.inMinutes / 60.0)
              .fold(0.0, (sum, hours) => sum + hours);
          avgHours = totalHours / sessions.length;
        }

        // حساب متوسط الجودة
        double avgQuality = 0;
        final qualitySessions = sessions.where((s) => s.overallSleepQuality > 0).toList();
        if (qualitySessions.isNotEmpty) {
          final totalQuality = qualitySessions
              .map((s) => s.overallSleepQuality)
              .fold(0.0, (sum, q) => sum + q);
          avgQuality = totalQuality / qualitySessions.length;
        }

        // حساب متوسط الانقطاعات
        int avgInterruptions = 0;
        if (sessions.isNotEmpty) {
          final totalInterruptions = sessions
              .map((s) => s.totalInterruptions)
              .fold(0, (sum, count) => sum + count);
          avgInterruptions = (totalInterruptions / sessions.length).round();
        }

        // حساب نسبة تحقيق الهدف (افتراضي 8 ساعات)
        final goalHours = provider.state.sleepGoalHours ?? 8;
        final goalRate = (avgHours / goalHours * 100).clamp(0, 100).toInt();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text('📊', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Text(
                    'إحصائيات سريعة',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Grid الإحصائيات
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.75,
              children: [
                _buildStatCard(
                  icon: '⏱️',
                  label: 'متوسط ساعات النوم',
                  value: avgHours.toStringAsFixed(1),
                  unit: 'ساعة',
                  color: AppColors.primary,
                ),
                _buildStatCard(
                  icon: '🎯',
                  label: 'تحقيق الهدف',
                  value: '$goalRate',
                  unit: '%',
                  color: AppColors.success,
                ),
                _buildStatCard(
                  icon: '⭐',
                  label: 'متوسط الجودة',
                  value: avgQuality.toStringAsFixed(1),
                  unit: '/10',
                  color: AppColors.warning,
                ),
                _buildStatCard(
                  icon: '🔄',
                  label: 'متوسط الانقطاعات',
                  value: '$avgInterruptions',
                  unit: 'مرة',
                  color: AppColors.error,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // الأيقونة
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color, width: 1),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 18)),
              ),
            ),

            // القيمة والوحدة
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        color: color,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        unit,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}