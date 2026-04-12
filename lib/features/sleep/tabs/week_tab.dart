// lib/features/sleep/tabs/week_tab.dart - النسخة البسيطة

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/sleep_tracking_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../widgets/stats/weekly_chart.dart';
import '../widgets/stats/weekly_stats_cards.dart';
import '../widgets/stats/sleep_patterns_card.dart';

class WeekTab extends StatelessWidget {
  const WeekTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SleepTrackingProvider>(
      builder: (context, provider, _) {
        final sessions = provider.state.recentSessions;
        final hasEnoughData = sessions.length >= 3;

        return RefreshIndicator(
          onRefresh: () => provider.refreshData(),
          child: hasEnoughData
              ? _buildFullContent(provider)
              : _buildInsufficientDataState(context, sessions),
        );
      },
    );
  }

  Widget _buildFullContent(SleepTrackingProvider provider) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        WeeklyChart(provider: provider),
        SizedBox(height: 20),
        WeeklyStatsCards(provider: provider),
        SizedBox(height: 20),
        SleepPatternsCard(provider: provider),
        SizedBox(height: 20),
        _buildGoalComparisonCard(provider),
        SizedBox(height: 100),
      ],
    );
  }

  Widget _buildInsufficientDataState(BuildContext context, List sessions) {
    return Center(
      child: SingleChildScrollView(
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
                Icons.show_chart,
                size: 80,
                color: AppColors.primary,
              ),
            ),

            SizedBox(height: 32),

            Text(
              sessions.isEmpty
                  ? '📊 ابدأ رحلة النوم'
                  : '📈 جاري جمع البيانات',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 16),

            Text(
              sessions.isEmpty
                  ? 'فعّل التتبع التلقائي وسنبدأ\nبجمع بيانات نومك وتحليلها'
                  : 'رائع! لديك ${sessions.length} جلسة نوم\n'
                  'نحتاج 3 جلسات على الأقل لعرض التحليلات',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),

            if (sessions.isNotEmpty) ...[
              SizedBox(height: 24),

              // شريط التقدم
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
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${sessions.length}/3',
                          style: TextStyle(
                            fontSize: 14,
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
                        value: sessions.length / 3.0,
                        minHeight: 10,
                        backgroundColor: AppColors.backgroundLight,
                        valueColor: AlwaysStoppedAnimation(AppColors.success),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 32),

            if (sessions.isEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    DefaultTabController.of(context).animateTo(0);
                  },
                  icon: Icon(Icons.arrow_back),
                  label: Text('العودة للرئيسية'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalComparisonCard(
      SleepTrackingProvider provider,
      ) {
    final goalHours = provider.state.sleepGoalHours;
    final avgHours = provider.state.averageSleepDuration.inHours;
    final avgMinutes = provider.state.averageSleepDuration.inMinutes.remainder(60);
    final achievementRate = (avgHours + avgMinutes / 60) / goalHours;

    final cardColor = achievementRate >= 0.9 ? AppColors.success : AppColors.warning;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardColor, width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardColor, width: 2),
                ),
                child: Icon(
                  Icons.flag,
                  color: cardColor,
                  size: 28,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تحقيق الهدف الأسبوعي',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'الهدف: $goalHours ساعات يومياً',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          // شريط التقدم
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: achievementRate.clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation<Color>(cardColor),
            ),
          ),

          SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$avgHours س $avgMinutes د',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${(achievementRate * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          if (achievementRate >= 0.9) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardColor, width: 2),
              ),
              child: Row(
                children: [
                  Text('🎉', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'رائع! أنت تحقق هدفك بانتظام',
                      style: TextStyle(
                        color: cardColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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
}