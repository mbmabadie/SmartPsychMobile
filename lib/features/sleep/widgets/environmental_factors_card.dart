// lib/features/sleep/widgets/environmental_factors_card.dart - النسخة البسيطة

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/sleep_tracking_provider.dart';
import '../../../shared/theme/app_colors.dart';

class EnvironmentalFactorsCard extends StatelessWidget {
  const EnvironmentalFactorsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SleepTrackingProvider>(
      builder: (context, provider, child) {
        final currentSession = provider.state.currentSession;
        final environmentData = provider.state.currentEnvironment;

        // إذا مافي بيانات، نخفي الكارد
        if (environmentData == null && currentSession == null) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.border,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // العنوان
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary, width: 1),
                      ),
                      child: const Center(
                        child: Text('🌡️', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'العوامل البيئية',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // العوامل
                _buildFactorItem(
                  icon: '💡',
                  label: 'الإضاءة',
                  value: environmentData?.lightLevel?.toInt() ?? 0,
                  maxValue: 100,
                  unit: 'lux',
                  color: AppColors.warning,
                  goodRange: 'أقل من 10',
                ),

                const SizedBox(height: 16),

                _buildFactorItem(
                  icon: '🔊',
                  label: 'الضجيج',
                  value: environmentData?.noiseLevel?.toInt() ?? 0,
                  maxValue: 100,
                  unit: 'dB',
                  color: AppColors.error,
                  goodRange: 'أقل من 40',
                ),

                const SizedBox(height: 16),

                _buildFactorItem(
                  icon: '📳',
                  label: 'الحركة',
                  value: environmentData?.movementIntensity?.toInt() ?? 0,
                  maxValue: 100,
                  unit: '',
                  color: AppColors.info,
                  goodRange: 'قليلة جداً',
                ),

                const SizedBox(height: 20),

                // التقييم العام
                if (currentSession != null)
                  _buildOverallScore(currentSession.environmentStabilityScore),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFactorItem({
    required String icon,
    required String label,
    required int value,
    required int maxValue,
    required String unit,
    required Color color,
    required String goodRange,
  }) {
    final percentage = (value / maxValue * 100).clamp(0, 100).toInt();
    final isGood = percentage < 30;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // العنوان والقيمة
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 2),
                  Text(
                    unit,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),

        const SizedBox(height: 8),

        // شريط التقدم
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage / 100,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // المدى المناسب
        Row(
          children: [
            Icon(
              isGood ? Icons.check_circle : Icons.info_outline,
              size: 14,
              color: isGood ? AppColors.success : AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              'مناسب: $goodRange',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverallScore(double score) {
    final percentage = (score * 100).toInt();
    final emoji = score >= 0.8 ? '🌟' : (score >= 0.6 ? '👍' : '⚠️');
    final text = score >= 0.8 ? 'ممتازة' : (score >= 0.6 ? 'جيدة' : 'تحتاج تحسين');
    final color = score >= 0.8 ? AppColors.success : (score >= 0.6 ? AppColors.warning : AppColors.error);

    return Container(
      padding: const EdgeInsets.all(16),
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
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'البيئة $text',
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'مستوى الثقة: $percentage%',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}