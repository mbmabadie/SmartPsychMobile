// lib/features/sleep/widgets/sleep_stats_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/sleep_tracking_provider.dart';

class SleepStatsCard extends StatelessWidget {
  const SleepStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SleepTrackingProvider>(
      builder: (context, provider, child) {
        final avgDuration = provider.state.averageSleepDuration;
        final avgHours = avgDuration.inHours;
        final avgMinutes = avgDuration.inMinutes.remainder(60);
        final goal = provider.state.sleepGoalHours;
        final avgQuality = provider.state.averageQualityScore;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'الإحصائيات الأسبوعية',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Stats Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        context,
                        icon: Icons.schedule,
                        label: 'متوسط النوم',
                        value: '${avgHours}h ${avgMinutes}m',
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        icon: Icons.flag,
                        label: 'الهدف اليومي',
                        value: '${goal}h',
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        context,
                        icon: Icons.star,
                        label: 'متوسط الجودة',
                        value: avgQuality > 0
                            ? '${(avgQuality * 5).toStringAsFixed(1)}/5'
                            : 'N/A',
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        icon: Icons.trending_up,
                        label: 'التقدم',
                        value: _calculateProgress(avgHours, goal),
                        color: _getProgressColor(avgHours, goal),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String value,
        required Color color,
      }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _calculateProgress(int avgHours, int goalHours) {
    if (goalHours == 0) return 'N/A';
    final percentage = ((avgHours / goalHours) * 100).clamp(0, 100);
    return '${percentage.round()}%';
  }

  Color _getProgressColor(int avgHours, int goalHours) {
    if (goalHours == 0) return Colors.grey;
    final percentage = (avgHours / goalHours);
    if (percentage >= 0.9) return Colors.green;
    if (percentage >= 0.7) return Colors.lightGreen;
    if (percentage >= 0.5) return Colors.amber;
    return Colors.red;
  }
}