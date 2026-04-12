// lib/features/sleep/widgets/sleep_insights_card.dart - النسخة البسيطة

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/database/models/sleep_models.dart';
import '../../../core/providers/sleep_tracking_provider.dart';
import '../../../shared/theme/app_colors.dart';

class SleepInsightsCard extends StatelessWidget {
  const SleepInsightsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SleepTrackingProvider>(
      builder: (context, provider, child) {
        // توليد رؤى بسيطة من البيانات المتاحة
        final sessions = provider.state.recentSessions.take(7).toList();
        final insights = _generateSimpleInsights(sessions, provider.state.sleepGoalHours ?? 8);

        // إذا مافي رؤى، نخفي الكارد
        if (insights.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary,
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: const Center(
                        child: Text('💡', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'رؤى ذكية',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // قائمة الرؤى
                ...insights.map((insight) => _buildInsightItem(insight)),
              ],
            ),
          ),
        );
      },
    );
  }

  // توليد رؤى بسيطة من الجلسات
  List<Map<String, dynamic>> _generateSimpleInsights(List<SleepSession> sessions, int goalHours) {
    if (sessions.isEmpty) return [];

    final insights = <Map<String, dynamic>>[];

    // حساب متوسط ساعات النوم
    final avgHours = sessions
        .where((s) => s.duration != null)
        .map((s) => s.duration!.inHours)
        .fold(0, (sum, hours) => sum + hours) / sessions.length;

    // رؤية عن ساعات النوم
    if (avgHours >= goalHours) {
      insights.add({
        'type': 'success',
        'message': 'رائع! متوسط نومك ${avgHours.toStringAsFixed(1)} ساعة، أنت تحقق هدفك!',
        'recommendation': 'استمر على هذا النظام الصحي',
      });
    } else if (avgHours < goalHours - 1) {
      insights.add({
        'type': 'warning',
        'message': 'متوسط نومك ${avgHours.toStringAsFixed(1)} ساعة، أقل من هدفك بـ ${(goalHours - avgHours).toStringAsFixed(1)} ساعة',
        'recommendation': 'حاول النوم مبكراً بـ 30 دقيقة كل ليلة',
      });
    }

    // رؤية عن جودة النوم
    final qualitySessions = sessions.where((s) => s.overallSleepQuality > 0).toList();
    if (qualitySessions.isNotEmpty) {
      final avgQuality = qualitySessions
          .map((s) => s.overallSleepQuality)
          .fold(0.0, (sum, q) => sum + q) / qualitySessions.length;

      if (avgQuality < 5) {
        insights.add({
          'type': 'error',
          'message': 'جودة نومك منخفضة (${avgQuality.toStringAsFixed(1)}/10)',
          'recommendation': 'راقب العوامل البيئية وقلل استخدام الهاتف قبل النوم',
        });
      } else if (avgQuality >= 8) {
        insights.add({
          'type': 'success',
          'message': 'جودة نومك ممتازة! (${avgQuality.toStringAsFixed(1)}/10)',
          'recommendation': 'حافظ على عاداتك الصحية',
        });
      }
    }

    // رؤية عن الانقطاعات
    final avgInterruptions = sessions
        .map((s) => s.totalInterruptions)
        .fold(0, (sum, count) => sum + count) / sessions.length;

    if (avgInterruptions > 3) {
      insights.add({
        'type': 'warning',
        'message': 'كثرة الانقطاعات (${avgInterruptions.toStringAsFixed(0)} مرة في الليلة)',
        'recommendation': 'اجعل غرفتك أكثر هدوءاً وأطفئ الهاتف',
      });
    }

    // رؤية عن استخدام الهاتف
    final avgPhoneUsage = sessions
        .map((s) => s.phoneActivations)
        .fold(0, (sum, count) => sum + count) / sessions.length;

    if (avgPhoneUsage > 2) {
      insights.add({
        'type': 'tip',
        'message': 'تستخدم الهاتف كثيراً أثناء النوم (${avgPhoneUsage.toStringAsFixed(0)} مرة)',
        'recommendation': 'ضع الهاتف بعيداً عن السرير أو فعّل وضع عدم الإزعاج',
      });
    }

    return insights;
  }

  Widget _buildInsightItem(Map<String, dynamic> insight) {
    final type = insight['type'] as String? ?? 'info';
    final message = insight['message'] as String? ?? '';
    final recommendation = insight['recommendation'] as String?;

    final config = _getInsightConfig(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: config.color,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان والأيقونة
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: config.color, width: 1),
                ),
                child: Center(
                  child: Text(config.emoji, style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.title,
                      style: TextStyle(
                        color: config.color,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // التوصية
          if (recommendation != null && recommendation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  _InsightConfig _getInsightConfig(String type) {
    switch (type) {
      case 'success':
        return _InsightConfig(
          emoji: '🎉',
          title: 'أداء رائع',
          color: AppColors.success,
        );
      case 'warning':
        return _InsightConfig(
          emoji: '⚠️',
          title: 'انتبه',
          color: AppColors.warning,
        );
      case 'error':
        return _InsightConfig(
          emoji: '🚨',
          title: 'يحتاج تحسين',
          color: AppColors.error,
        );
      case 'tip':
        return _InsightConfig(
          emoji: '💡',
          title: 'نصيحة',
          color: AppColors.info,
        );
      default:
        return _InsightConfig(
          emoji: 'ℹ️',
          title: 'معلومة',
          color: AppColors.primary,
        );
    }
  }
}

class _InsightConfig {
  final String emoji;
  final String title;
  final Color color;

  _InsightConfig({
    required this.emoji,
    required this.title,
    required this.color,
  });
}