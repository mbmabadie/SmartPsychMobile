// lib/features/sleep/screens/sleep_insights_screen.dart - النسخة البسيطة

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/sleep_tracking_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/unified_app_bar.dart';
import '../widgets/insights/insight_card.dart';
import '../widgets/insights/sleep_score_card.dart';
import '../widgets/insights/trend_chart_card.dart';
import '../widgets/insights/recommendations_card.dart';

class SleepInsightsScreen extends StatelessWidget {
  const SleepInsightsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: UnifiedAppBar(
        greeting: 'الرؤى الذكية',
        subtitle: 'تحليل عميق لنومك',
        onNotificationTap: () {},
        onProfileTap: () {},
        hasNotificationBadge: false,
      ),
      body: Consumer<SleepTrackingProvider>(
        builder: (context, provider, _) {
          final sessions = provider.state.recentSessions;

          if (sessions.length < 5) {
            return _buildInsufficientDataState(sessions.length);
          }

          return RefreshIndicator(
            onRefresh: () => provider.refreshData(),
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                // نقاط النوم الإجمالية
                SleepScoreCard(provider: provider),

                SizedBox(height: 16),

                // الاتجاهات
                TrendChartCard(provider: provider),

                SizedBox(height: 16),

                // الرؤى
                ..._generateInsights(provider).map((insight) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: InsightCard(insight: insight),
                  );
                }).toList(),

                SizedBox(height: 16),

                // التوصيات
                RecommendationsCard(provider: provider),

                SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInsufficientDataState(int currentSessions) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 3),
              ),
              child: Icon(
                Icons.psychology,
                size: 80,
                color: AppColors.primary,
              ),
            ),

            SizedBox(height: 32),

            Text(
              '🧠 رؤى ذكية قريباً',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 16),

            Text(
              'نحتاج 5 جلسات نوم على الأقل\n'
                  'لتقديم رؤى وتوصيات دقيقة',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 24),

            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'التقدم',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '$currentSessions/5',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: currentSessions / 5.0,
                      minHeight: 10,
                      backgroundColor: AppColors.backgroundLight,
                      valueColor: AlwaysStoppedAnimation(AppColors.success),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<SleepInsight> _generateInsights(SleepTrackingProvider provider) {
    final insights = <SleepInsight>[];
    final sessions = provider.state.recentSessions;
    final avgQuality = provider.state.averageQualityScore;
    final avgDuration = provider.state.averageSleepDuration;

    // رؤية الإنجاز
    if (sessions.length >= 5) {
      final goodNights = sessions.where((s) => (s.qualityScore ?? 0) >= 7).length;
      if (goodNights >= 5) {
        insights.add(SleepInsight(
          type: InsightType.achievement,
          title: '🎉 إنجاز رائع!',
          message: 'نمت بجودة عالية لـ $goodNights أيام متتالية! استمر على هذا المنوال 💪',
          icon: Icons.emoji_events,
          color: AppColors.success,
          priority: 1,
        ));
      }
    }

    // رؤية استخدام الهاتف
    final phoneUsage = sessions.where((s) => (s.phoneActivations ?? 0) > 0).length;
    if (phoneUsage >= 3) {
      insights.add(SleepInsight(
        type: InsightType.warning,
        title: '⚠️ تنبيه',
        message: 'لاحظنا أنك تستخدم الهاتف قبل النوم بـ 15 دقيقة فقط. '
            'حاول إيقافه قبل 30 دقيقة لنوم أفضل.',
        icon: Icons.phone_android,
        color: AppColors.warning,
        priority: 2,
        actionLabel: 'نصائح',
        onActionTap: () {
          // TODO: فتح نصائح تقليل استخدام الهاتف
        },
      ));
    }

    // رؤية النمط المكتشف
    if (avgQuality >= 7.5 && avgDuration.inHours >= 7) {
      insights.add(SleepInsight(
        type: InsightType.pattern,
        title: '📊 نمط مكتشف',
        message: 'تنام أفضل في الليالي التي تمارس فيها الرياضة. '
            'حاول المشي 30 دقيقة يومياً.',
        icon: Icons.directions_walk,
        color: AppColors.info,
        priority: 3,
      ));
    }

    // رؤية البيئة
    final currentEnv = provider.state.currentEnvironment;
    if (currentEnv != null && !currentEnv.isOptimalForSleep) {
      insights.add(SleepInsight(
        type: InsightType.environment,
        title: '🌡️ ملاحظة بيئية',
        message: 'جودة نومك ترتفع عندما تكون درجة حرارة الغرفة 19-21°C',
        icon: Icons.thermostat,
        color: AppColors.primary,
        priority: 4,
      ));
    }

    // رؤية الاتساق
    if (sessions.length >= 7) {
      final consistency = _calculateConsistency(sessions);
      if (consistency >= 0.8) {
        insights.add(SleepInsight(
          type: InsightType.positive,
          title: '✅ انتظام ممتاز',
          message: 'تنام وتستيقظ في أوقات ثابتة. هذا رائع لصحتك!',
          icon: Icons.schedule,
          color: AppColors.success,
          priority: 5,
        ));
      } else if (consistency < 0.5) {
        insights.add(SleepInsight(
          type: InsightType.warning,
          title: '⏰ أوقات غير منتظمة',
          message: 'حاول النوم والاستيقاظ في نفس الأوقات يومياً لتحسين جودة نومك.',
          icon: Icons.schedule,
          color: AppColors.warning,
          priority: 2,
        ));
      }
    }

    // رؤية تحسين الجودة
    if (avgQuality < 6.0 && sessions.length >= 3) {
      insights.add(SleepInsight(
        type: InsightType.improvement,
        title: '📈 فرصة للتحسين',
        message: 'جودة نومك الحالية ${avgQuality.toStringAsFixed(1)}/10. '
            'اتبع التوصيات أدناه لتحسينها.',
        icon: Icons.trending_up,
        color: AppColors.info,
        priority: 1,
      ));
    }

    // ترتيب حسب الأولوية
    insights.sort((a, b) => a.priority.compareTo(b.priority));

    return insights;
  }

  double _calculateConsistency(List sessions) {
    if (sessions.length < 3) return 0.0;

    final sleepTimes = sessions
        .map((s) => s.startTime.hour * 60 + s.startTime.minute)
        .toList();

    if (sleepTimes.isEmpty) return 0.0;

    final mean = sleepTimes.reduce((a, b) => a + b) / sleepTimes.length;
    final variance = sleepTimes
        .map((t) => (t - mean) * (t - mean))
        .reduce((a, b) => a + b) / sleepTimes.length;

    // تحويل الانحراف المعياري إلى نقاط اتساق (0-1)
    final stdDev = variance;
    return (1.0 - (stdDev / 3600)).clamp(0.0, 1.0);
  }
}

// نموذج الرؤية
class SleepInsight {
  final InsightType type;
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final int priority;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  SleepInsight({
    required this.type,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.priority,
    this.actionLabel,
    this.onActionTap,
  });
}

enum InsightType {
  achievement,
  warning,
  pattern,
  environment,
  positive,
  improvement,
}