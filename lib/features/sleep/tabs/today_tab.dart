// lib/features/sleep/tabs/today_tab.dart - النسخة البسيطة

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/sleep_tracking_provider.dart';
import '../../../core/database/models/sleep_models.dart';
import '../../../core/providers/sleep_tracking_state.dart';
import '../../../core/theme/sleep_theme.dart';
import '../../../shared/theme/app_colors.dart';
import '../widgets/hero_section/sleep_status_card.dart';
import '../widgets/hero_section/awake_status_card.dart';
import '../widgets/timeline/sleep_timeline_chart.dart';
import '../widgets/quality/environment_quality_card.dart';

class TodayTab extends StatelessWidget {
  const TodayTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SleepTrackingProvider>(
      builder: (context, provider, _) {
        final state = provider.state;

        return RefreshIndicator(
          onRefresh: () => provider.refreshData(),
          child: ListView(
            padding: EdgeInsets.all(16),
            children: [
              if (state.pendingConfirmations.isNotEmpty)
                _buildPendingConfirmationBanner(context, state),

              SizedBox(height: 16),

              // Hero Section
              _buildHeroSection(context, state),

              SizedBox(height: 24),

              // Sleep Timeline (إذا كان نائم أو انتهى للتو)
              if (state.hasActiveSession || _hasRecentSession(state))
                _buildTimelineSection(context, state),

              SizedBox(height: 24),

              // Environmental Quality
              if (state.currentEnvironment != null)
                EnvironmentQualityCard(
                  conditions: state.currentEnvironment!,
                  qualityScore: state.environmentalQualityScore,
                ),

              SizedBox(height: 24),

              // Quick Stats
              _buildQuickStats(context, state),

              SizedBox(height: 100), // مساحة للـ FAB
            ],
          ),
        );
      },
    );
  }

  Widget _buildPendingConfirmationBanner(BuildContext context, SleepTrackingState state) {
    final count = state.pendingConfirmations.length;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/sleep-confirmation');
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warning,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.warning, width: 3),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning, width: 2),
              ),
              child: Icon(
                Icons.notifications_active,
                color: AppColors.warning,
                size: 32,
              ),
            ),

            SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⏰ انتباه!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'لديك $count ${count == 1 ? 'جلسة' : 'جلسات'} تحتاج تأكيد',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, SleepTrackingState state) {
    if (state.hasActiveSession) {
      return SleepStatusCard(
        session: state.currentSession!,
        currentState: state.currentSleepState,
        environment: state.currentEnvironment,
      );
    } else {
      return AwakeStatusCard(
        lastSession: state.recentSessions.isNotEmpty
            ? state.recentSessions.first
            : null,
        hasPendingConfirmation: state.pendingConfirmations.isNotEmpty,
        onConfirmPressed: () {
          Navigator.pushNamed(context, '/sleep-confirmation');
        },
      );
    }
  }

  Widget _buildTimelineSection(BuildContext context, SleepTrackingState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            '📅 الجدول الزمني',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        SleepTimelineChart(
          session: state.currentSession ?? state.recentSessions.first,
          environmentHistory: state.environmentHistory,
        ),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context, SleepTrackingState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            '📊 إحصائيات سريعة',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: '⏱️',
                label: 'متوسط النوم',
                value: '${state.averageSleepDuration.inHours}h ${state.averageSleepDuration.inMinutes.remainder(60)}m',
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                icon: '⭐',
                label: 'متوسط الجودة',
                value: state.averageQualityScore.toStringAsFixed(1),
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      BuildContext context, {
        required String icon,
        required String label,
        required String value,
        required Color color,
      }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Text(icon, style: TextStyle(fontSize: 32)),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  bool _hasRecentSession(SleepTrackingState state) {
    if (state.recentSessions.isEmpty) return false;

    final lastSession = state.recentSessions.first;
    final now = DateTime.now();
    final hoursSinceEnd = lastSession.endTime != null
        ? now.difference(lastSession.endTime!).inHours
        : 999;

    return hoursSinceEnd < 12; // عرض التايم لاين إذا انتهى منذ أقل من 12 ساعة
  }
}