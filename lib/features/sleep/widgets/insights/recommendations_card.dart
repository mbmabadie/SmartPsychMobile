// lib/features/sleep/widgets/insights/recommendations_card.dart - النسخة البسيطة

import 'package:flutter/material.dart';
import '../../../../core/providers/sleep_tracking_provider.dart';
import '../../../../shared/theme/app_colors.dart';

class RecommendationsCard extends StatelessWidget {
  final SleepTrackingProvider provider;

  const RecommendationsCard({
    Key? key,
    required this.provider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final recommendations = _generateRecommendations();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary, width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  Icons.tips_and_updates,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 توصيات لك',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'نصائح مخصصة لتحسين نومك',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          // التوصيات
          ...recommendations.asMap().entries.map((entry) {
            final index = entry.key;
            final rec = entry.value;

            return Padding(
              padding: EdgeInsets.only(
                  bottom: index < recommendations.length - 1 ? 12 : 0),
              child: _buildRecommendationItem(
                context,
                number: index + 1,
                icon: rec['icon'] as String,
                title: rec['title'] as String,
                description: rec['description'] as String,
                actionLabel: rec['actionLabel'] as String?,
                onActionTap: rec['onActionTap'] as VoidCallback?,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(
      BuildContext context, {
        required int number,
        required String icon,
        required String title,
        required String description,
        String? actionLabel,
        VoidCallback? onActionTap,
      }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الرقم
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$number',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              SizedBox(width: 12),

              // الأيقونة والعنوان
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(icon, style: TextStyle(fontSize: 20)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // زر الإجراء
          if (actionLabel != null && onActionTap != null) ...[
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onActionTap,
                icon: Icon(Icons.arrow_forward, size: 16),
                label: Text(actionLabel),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  backgroundColor: AppColors.primarySurface,
                  padding: EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: AppColors.primary, width: 1),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _generateRecommendations() {
    final recommendations = <Map<String, dynamic>>[];
    final avgQuality = provider.state.averageQualityScore;
    final avgDuration = provider.state.averageSleepDuration;
    final goalHours = provider.state.sleepGoalHours;
    final sessions = provider.state.recentSessions;

    // توصية بتحسين البيئة
    if (provider.state.environmentalQualityScore < 7.0) {
      recommendations.add({
        'icon': '🌡️',
        'title': 'حسّن بيئة نومك',
        'description':
        'اجعل غرفتك أكثر ظلاماً وهدوءاً. درجة الحرارة المثالية: 18-21°C',
        'actionLabel': 'نصائح البيئة',
        'onActionTap': () {
          // TODO: فتح نصائح البيئة
        },
      });
    }

    // توصية بتقليل وقت الشاشة
    final phoneUsage =
        sessions.where((s) => (s.phoneActivations ?? 0) > 0).length;
    if (phoneUsage >= 3) {
      recommendations.add({
        'icon': '📱',
        'title': 'قلل استخدام الهاتف',
        'description':
        'أوقف الهاتف قبل النوم بـ 30 دقيقة. الضوء الأزرق يؤثر على جودة النوم',
        'actionLabel': 'تفعيل وضع النوم',
        'onActionTap': () {
          // TODO: تفعيل وضع النوم
        },
      });
    }

    // توصية بالنوم المبكر
    final avgSleepTime = _calculateAverageSleepTime(sessions);
    if (avgSleepTime != null && avgSleepTime.hour >= 1) {
      recommendations.add({
        'icon': '🌙',
        'title': 'نم مبكراً',
        'description':
        'حاول النوم قبل منتصف الليل. النوم من 10 مساءً إلى 2 صباحاً هو الأكثر فائدة',
        'actionLabel': null,
        'onActionTap': null,
      });
    }

    // توصية بالانتظام
    if (_calculateConsistency(sessions) < 0.6) {
      recommendations.add({
        'icon': '⏰',
        'title': 'التزم بجدول ثابت',
        'description':
        'نم واستيقظ في نفس الوقت يومياً، حتى في عطلة نهاية الأسبوع',
        'actionLabel': 'ضبط منبه',
        'onActionTap': () {
          // TODO: فتح إعدادات المنبه
        },
      });
    }

    // توصية بالرياضة
    if (avgQuality < 7.0) {
      recommendations.add({
        'icon': '🏃',
        'title': 'مارس الرياضة',
        'description':
        'التمارين المنتظمة تحسن جودة النوم. تجنب التمارين الشاقة قبل النوم بـ 3 ساعات',
        'actionLabel': null,
        'onActionTap': null,
      });
    }

    // توصية بتجنب الكافيين
    recommendations.add({
      'icon': '☕',
      'title': 'قلل الكافيين',
      'description':
      'تجنب القهوة والشاي بعد الساعة 4 مساءً. الكافيين يبقى في الجسم لـ 6 ساعات',
      'actionLabel': null,
      'onActionTap': null,
    });

    // توصية بالاسترخاء
    if (avgQuality < 7.0) {
      recommendations.add({
        'icon': '🧘',
        'title': 'تمارين الاسترخاء',
        'description':
        'جرّب التأمل أو تمارين التنفس العميق قبل النوم بـ 15 دقيقة',
        'actionLabel': 'ابدأ التأمل',
        'onActionTap': () {
          // TODO: فتح تمارين التأمل
        },
      });
    }

    // محدود بـ 5 توصيات
    return recommendations.take(5).toList();
  }

  DateTime? _calculateAverageSleepTime(List sessions) {
    if (sessions.isEmpty) return null;

    final totalMinutes = sessions
        .map((s) => s.startTime.hour * 60 + s.startTime.minute)
        .reduce((a, b) => a + b);

    final avgMinutes = totalMinutes ~/ sessions.length;
    final hour = avgMinutes ~/ 60;
    final minute = avgMinutes % 60;

    return DateTime(2024, 1, 1, hour, minute);
  }

  double _calculateConsistency(List sessions) {
    if (sessions.length < 3) return 0.5;

    final sleepTimes = sessions
        .map((s) => s.startTime.hour * 60 + s.startTime.minute)
        .toList();

    if (sleepTimes.isEmpty) return 0.5;

    final mean = sleepTimes.reduce((a, b) => a + b) / sleepTimes.length;
    final variance = sleepTimes
        .map((t) => (t - mean) * (t - mean))
        .reduce((a, b) => a + b) /
        sleepTimes.length;

    final stdDev = variance;
    return (1.0 - (stdDev / 3600)).clamp(0.0, 1.0);
  }
}