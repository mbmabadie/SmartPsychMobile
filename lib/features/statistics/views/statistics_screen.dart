// lib/features/statistics/views/statistics_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/base/base_state.dart';
import '../../../core/providers/unified_health_hub.dart';
import '../../../core/providers/statistics_provider.dart';
import '../../../core/providers/insights_provider.dart';
import '../../../core/providers/activity_tracking_provider.dart';
import '../../../core/providers/phone_usage_provider.dart';
import '../../../core/providers/sleep_tracking_provider.dart';
import '../../../core/services/insights_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/unified_app_bar.dart';

class StatisticsScreen extends StatefulWidget {
  final Function(int)? onNavigateToPage;

  const StatisticsScreen({
    super.key,
    this.onNavigateToPage,
  });

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _debugData();
    });
  }

  void _loadData() {
    final insightsProvider = context.read<InsightsTrackingProvider>();
    insightsProvider.generateDailyInsights();
  }

  void _debugData() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;

      final hub = context.read<UnifiedHealthHubProvider>();
      final stats = context.read<StatisticsProvider>();
      final insights = context.read<InsightsTrackingProvider>();

      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🔍 DEBUG - Statistics Screen Data (بعد 5 ثواني)');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      debugPrint('📊 HUB DATA:');
      debugPrint('   - todaySteps: ${hub.state.currentData.todaySteps}');
      debugPrint('   - todayPhoneUsage: ${hub.state.currentData.todayPhoneUsage.inMinutes} min');
      debugPrint('   - todaySleepHours: ${hub.state.currentData.todaySleepHours}');
      debugPrint('   - overallHealthScore: ${hub.state.currentData.overallHealthScore}');
      debugPrint('   - healthGrade: ${hub.state.currentData.healthGrade}');
      debugPrint('   - streak: ${hub.state.currentData.consecutiveDaysStreak}');
      debugPrint('   - streakEmoji: ${hub.state.currentData.streakEmoji}');

      debugPrint('\n📈 STATS DATA:');
      debugPrint('   - loadingState: ${stats.state.loadingState}');
      debugPrint('   - hasData: ${stats.state.hasData}');
      debugPrint('   - selectedPeriod: ${stats.state.selectedPeriod}');
      debugPrint('   - selectedCategory: ${stats.state.selectedCategory}');
      debugPrint('   - error: ${stats.state.error}');

      debugPrint('\n   📊 Activity Stats:');
      stats.state.activityStats.forEach((key, value) {
        debugPrint('      - $key: $value');
      });

      debugPrint('\n   😴 Sleep Stats:');
      stats.state.sleepStats.forEach((key, value) {
        debugPrint('      - $key: $value');
      });

      debugPrint('\n   📱 Phone Stats:');
      stats.state.phoneStats.forEach((key, value) {
        debugPrint('      - $key: $value');
      });

      debugPrint('\n   📉 Chart Data:');
      debugPrint('      - points count: ${stats.state.chartData.length}');
      if (stats.state.chartData.isNotEmpty) {
        debugPrint('      - first point: ${stats.state.chartData.first}');
        debugPrint('      - last point: ${stats.state.chartData.last}');
      }

      debugPrint('\n💡 INSIGHTS DATA:');
      debugPrint('   - loadingState: ${insights.state.loadingState}');
      debugPrint('   - hasData: ${insights.state.hasData}');
      debugPrint('   - currentInsights count: ${insights.state.currentInsights.length}');
      debugPrint('   - error: ${insights.state.error}');

      if (insights.state.currentInsights.isNotEmpty) {
        debugPrint('\n   Insights List:');
        for (var i = 0; i < insights.state.currentInsights.length; i++) {
          final insight = insights.state.currentInsights[i];
          debugPrint('      ${i + 1}. [${insight.type}] ${insight.message}');
        }
      } else {
        debugPrint('   ⚠️ No insights available!');
      }

      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: UnifiedAppBar(
        greeting: _getGreeting(),
        subtitle: 'إليك ملخص يومك',
        onLocationTap: () {},
        onNotificationTap: () {},
        onChatTap: () {},
        onProfileTap: () {},
        hasNotificationBadge: false,
      ),
      body: Consumer3<
      UnifiedHealthHubProvider,
      StatisticsProvider,
      InsightsTrackingProvider>(
      builder: (context, hub, stats, insights, child) {
        if (stats.state.loadingState == LoadingState.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () async {
            await hub.forceSync();
            await stats.refreshData();
            await insights.generateDailyInsights();
            _debugData();
          },
          color: AppColors.primary,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuickSnapshot(hub),
                SizedBox(height: 20.h),
                _buildSmartInsights(insights),
                SizedBox(height: 20.h),
                _buildDailyTasks(insights),
                SizedBox(height: 20.h),
                _buildWeeklyProgress(hub, stats),
                SizedBox(height: 100.h),
              ],
            ),
          ),
        );
      },
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير';
    if (hour < 17) return 'نهارك سعيد';
    return 'مساء الخير';
  }

  Widget _buildQuickSnapshot(UnifiedHealthHubProvider hub) {
    final data = hub.state.currentData;

    final todayPhoneMinutes = data.todayPhoneUsage.inMinutes;
    final phoneHours = todayPhoneMinutes ~/ 60;
    final phoneMinutes = todayPhoneMinutes % 60;

    final todaySleepHours = data.todaySleepHours;
    final todaySteps = data.todaySteps;

    final snapshots = [
      {
        'title': 'الهاتف',
        'value': todayPhoneMinutes > 0
            ? '${phoneHours}س ${phoneMinutes}د'
            : '0س 0د',
        'subtitle': 'استخدام اليوم',
        'icon': Icons.smartphone_rounded,
        'color': AppColors.primary,
        'page_index': 1,
      },
      {
        'title': 'الخطوات',
        'value': _formatNumber(todaySteps),
        'subtitle': 'خطوة اليوم',
        'icon': Icons.directions_walk_rounded,
        'color': AppColors.success,
        'page_index': 2,
      },
      {
        'title': 'النوم',
        'value': '${todaySleepHours.toStringAsFixed(1)}س',
        'subtitle': 'ساعات النوم',
        'icon': Icons.bedtime_rounded,
        'color': AppColors.secondary,
        'page_index': 3,
      },
      {
        'title': 'العافية',
        'value': '${(data.overallHealthScore * 100).round()}%',
        'subtitle': data.healthGrade,
        'icon': Icons.favorite_rounded,
        'color': _getHealthColor(data.overallHealthScore),
        'page_index': 4,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نظرة سريعة',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 10.h),

        // ✅ الصف الأول
        Row(
          children: [
            Expanded(child: _buildSnapshotCard(snapshots[0])),
            SizedBox(width: 10.w),
            Expanded(child: _buildSnapshotCard(snapshots[1])),
          ],
        ),
        SizedBox(height: 8.h),

        // ✅ الصف الثاني
        Row(
          children: [
            Expanded(child: _buildSnapshotCard(snapshots[2])),
            SizedBox(width: 10.w),
            Expanded(child: _buildSnapshotCard(snapshots[3])),
          ],
        ),
      ],
    );
  }

  Widget _buildSnapshotCard(Map<String, dynamic> snapshot) {
    return GestureDetector(
      onTap: () {
        final pageIndex = snapshot['page_index'] as int;

        if (widget.onNavigateToPage != null) {
          widget.onNavigateToPage!(pageIndex);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('الانتقال إلى ${snapshot['title']}'),
              duration: const Duration(seconds: 1),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      },
      child: Container(
        height: 120.h, // ✅ ارتفاع ثابت ومحدود
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: snapshot['color'].withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(7.w),
                  decoration: BoxDecoration(
                    color: snapshot['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    snapshot['icon'],
                    size: 20.sp,
                    color: snapshot['color'],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11.sp,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  snapshot['value'],
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    color: snapshot['color'],
                    height: 1.0,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  snapshot['subtitle'],
                  style: TextStyle(
                    fontSize: 9.5.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSmartInsights(InsightsTrackingProvider insights) {
    final currentInsights = insights.state.currentInsights;
    final displayInsights = currentInsights.take(3).toList();

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade50,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: Colors.purple.shade100,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.lightbulb_rounded,
                  size: 20.sp,
                  color: Colors.purple.shade700,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'رؤى ذكية',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.purple.shade900,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (displayInsights.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Text(
                  'مافي رؤى متاحة حالياً',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            )
          else
            ...displayInsights.asMap().entries.map((entry) {
              final index = entry.key;
              final insight = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < displayInsights.length - 1 ? 10.h : 0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 4.h),
                      width: 6.w,
                      height: 6.h,
                      decoration: BoxDecoration(
                        color: Colors.purple.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        insight.message,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade800,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildDailyTasks(InsightsTrackingProvider insights) {
    final currentInsights = insights.state.currentInsights;

    final tasks = currentInsights
        .where((insight) =>
    insight.type == InsightType.negative ||
        insight.type == InsightType.neutral)
        .take(3)
        .map((insight) => {
      'title': insight.message,
      'icon': _getInsightIcon(insight.type),
      'completed': false,
    })
        .toList();

    final completedCount = tasks.where((t) => t['completed'] as bool).length;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: AppColors.info.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.task_alt_rounded,
                  size: 20.sp,
                  color: AppColors.info,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'توصيات اليوم',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (tasks.isNotEmpty)
                Text(
                  '$completedCount/${tasks.length}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.info,
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),
          if (tasks.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Text(
                  'مافي توصيات متاحة حالياً',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            )
          else
            ...tasks.map((task) {
              return Container(
                margin: EdgeInsets.only(bottom: 10.h),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: task['completed'] as bool
                      ? AppColors.success.withOpacity(0.05)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: task['completed'] as bool
                        ? AppColors.success.withOpacity(0.3)
                        : Colors.grey.shade200,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: task['completed'] as bool
                            ? AppColors.success
                            : Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        task['completed'] as bool
                            ? Icons.check_rounded
                            : task['icon'] as IconData,
                        size: 16.sp,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        task['title'] as String,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: task['completed'] as bool
                              ? AppColors.success
                              : Colors.grey.shade700,
                          decoration: task['completed'] as bool
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgress(
      UnifiedHealthHubProvider hub,
      StatisticsProvider stats,
      ) {
    final hubData = hub.state.currentData;
    final streak = hubData.consecutiveDaysStreak;

    final activityStats = stats.state.activityStats;
    final sleepStats = stats.state.sleepStats;
    final phoneStats = stats.state.phoneStats;

    final activeDaysFromActivity = activityStats['active_days'] as int? ?? 0;
    final completedSleepSessions = sleepStats['completed_sessions'] as int? ?? 0;
    final hasPhoneData = phoneStats['has_data'] as bool? ?? false;

    final completedDays = [
      activeDaysFromActivity,
      completedSleepSessions,
      if (hasPhoneData) 7,
    ].fold<int>(0, (max, value) => value > max ? value : max).clamp(0, 7);

    final totalDays = 7;
    final progress = completedDays / totalDays;

    if (completedDays == 0 && streak == 0) {
      return Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.shade50,
              Colors.white,
            ],
          ),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: Colors.orange.shade200,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    size: 20.sp,
                    color: AppColors.warning,
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  'تقدمك هذا الأسبوع',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Center(
              child: Text(
                'لا يوجد بيانات حالياً',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            SizedBox(height: 16.h),

          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.shade50,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: Colors.orange.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  size: 20.sp,
                  color: AppColors.warning,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'تقدمك هذا الأسبوع',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'لقد حققتَ $completedDays من $totalDays أيام سليمة',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      height: 10.h,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(5.r),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.warning,
                                Colors.orange.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(5.r),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              Column(
                children: [
                  Row(
                    children: [
                      Text(
                        '$streak',
                        style: TextStyle(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.warning,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        ' ${hubData.streakEmoji}',
                        style: TextStyle(
                          fontSize: 24.sp,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'يوم متتالي',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}م';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}ك';
    }
    return number.toString();
  }

  Color _getHealthColor(double score) {
    if (score >= 0.8) return AppColors.success;
    if (score >= 0.6) return AppColors.warning;
    return AppColors.error;
  }

  IconData _getInsightIcon(InsightType type) {
    switch (type) {
      case InsightType.positive:
        return Icons.check_circle_rounded;
      case InsightType.negative:
        return Icons.warning_amber_rounded;
      case InsightType.neutral:
        return Icons.lightbulb_outline_rounded;
    }
  }
}