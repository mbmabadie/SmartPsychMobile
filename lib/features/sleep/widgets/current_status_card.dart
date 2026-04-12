// lib/features/sleep/widgets/current_status_card.dart - النسخة البسيطة

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/sleep_tracking_provider.dart';
import '../../../core/providers/sleep_tracking_state.dart';
import '../../../shared/theme/app_colors.dart';

class CurrentStatusCard extends StatelessWidget {
  const CurrentStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SleepTrackingProvider>(
      builder: (context, provider, child) {
        final isAsleep = provider.state.currentSleepState == SleepState.sleeping;
        final currentSession = provider.state.currentSession;

        final cardColor = isAsleep ? AppColors.accent : AppColors.primary;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cardColor, width: 3),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // الأيقونة والحالة
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // الأيقونة
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cardColor, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          isAsleep ? '😴' : '🌞',
                          style: const TextStyle(fontSize: 48),
                        ),
                      ),
                    ),

                    // الحالة
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isAsleep ? 'نايم حالياً' : 'صاحي',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isAsleep ? 'المراقبة نشطة' : 'في انتظار النوم',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // معلومات إضافية إذا كان نايم
                if (isAsleep && currentSession != null) ...[
                  const SizedBox(height: 20),
                  Divider(color: Colors.white, height: 1, thickness: 2),
                  const SizedBox(height: 20),

                  // المدة والتفاصيل
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoItem(
                        icon: '⏱️',
                        label: 'المدة',
                        value: _formatDuration(currentSession.duration ?? Duration.zero),
                      ),
                      _buildInfoItem(
                        icon: '🌙',
                        label: 'بدأ الساعة',
                        value: _formatTime(currentSession.startTime),
                      ),
                      _buildInfoItem(
                        icon: '📱',
                        label: 'استخدام الهاتف',
                        value: '${currentSession.phoneActivations}',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoItem({
    required String icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}س ${minutes}د';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'م' : 'ص';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}