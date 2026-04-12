// lib/features/activity_tracking/views/activity_tracking_screen.dart

import 'package:chatbot_ai/chatbot_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:smart_psych/features/activity_tracking/views/widget/InsightsWidget.dart';
import 'package:smart_psych/features/activity_tracking/views/widget/activity_chart_widget.dart';
import 'dart:async';

import '../../../core/providers/activity_tracking_provider.dart';
import '../../../core/services/unified_tracking_service.dart';
import '../../../core/services/user_settings_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/unified_app_bar.dart';
import '../../location/views/location_screen.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with AutomaticKeepAliveClientMixin {

  int _currentTabIndex = 0;
  int _currentStatIndex = 0;

  Future<int>? _yesterdayStepsFuture;
  Future<int>? _weeklyStepsFuture;
  bool _futuresInitialized = false;

  final _userSettings = UserSettingsService.instance;
  int _goalSteps = 10000;
  double _goalDistance = 8.0;
  double _goalCalories = 500.0;

  Timer? _refreshTimer; // ✅ حفظ مرجع للـ Timer

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _loadUserGoals();

    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {});
      } else {
        timer.cancel(); // ✅ إيقاف إضافي إذا لم يعد mounted
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeStatsFutures();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); // ✅ إيقاف Timer عند التخلص من الشاشة
    super.dispose();
  }

  Future<void> _loadUserGoals() async {
    try {
      final goals = await _userSettings.getAllGoals();
      if (mounted) {
        setState(() {
          _goalSteps = goals['steps'] as int;
          _goalDistance = goals['distance'] as double;
          _goalCalories = goals['calories'] as double;
        });
      }
      debugPrint('✅ تم تحميل الأهداف: $_goalSteps خطوة، $_goalDistance كم، $_goalCalories سعرة');
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الأهداف: $e');
      if (mounted) {
        setState(() {
          _goalSteps = 10000;
          _goalDistance = 8.0;
          _goalCalories = 500.0;
        });
      }
    }
  }

  void _initializeStatsFutures() {
    if (_futuresInitialized) return;

    final provider = Provider.of<ActivityTrackingProvider>(context, listen: false);

    setState(() {
      _yesterdayStepsFuture = provider.getYesterdaySteps();
      _weeklyStepsFuture = provider.getWeeklySteps();
      _futuresInitialized = true;
    });
  }

  void _refreshStatsFutures() {
    final provider = Provider.of<ActivityTrackingProvider>(context, listen: false);

    setState(() {
      _yesterdayStepsFuture = provider.getYesterdaySteps();
      _weeklyStepsFuture = provider.getWeeklySteps();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: UnifiedAppBar(
        greeting: _getGreeting(),
        subtitle: 'كيف حالك اليوم؟',
        onLocationTap: () {
          setState(() {
            _currentTabIndex = 1;
          });
        },
        onNotificationTap: () {},
        onChatTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatbotAi(
                isCvPending: false,
                title: "الرسائل",
                userData: {},
                language: "ar",
                name: "",
                id: "",
                url: "",
              ),
            ),
          );
        },
        onProfileTap: () {},
        hasNotificationBadge: false,
      ),
      body: Consumer<ActivityTrackingProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: () async {
              await provider.refreshData();
              _refreshStatsFutures();
              await _loadUserGoals();
            },
            color: AppColors.primary,
            backgroundColor: Colors.white,
            child: Column(
              children: [
                _buildFixedTabBar(),
                Expanded(
                  child: IndexedStack(
                    index: _currentTabIndex,
                    children: [
                      _buildActivityTab(),
                      const LocationScreen(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFixedTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 220.w,
            height: 50.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTab(Icons.directions_walk_rounded, 'النشاط', 0),
                ),
                Expanded(
                  child: _buildTab(Icons.location_on_rounded, 'الموقع', 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(IconData icon, String label, int index) {
    final isSelected = index == _currentTabIndex;

    return InkWell(
      onTap: () {
        setState(() {
          _currentTabIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20.sp,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTab() {
    return Consumer<ActivityTrackingProvider>(
      builder: (context, provider, child) {
        if (provider.state.error != null) {
          return _buildErrorState(provider);
        }

        return RefreshIndicator(
          onRefresh: () async {
            await provider.refreshData();
            _refreshStatsFutures();
            await _loadUserGoals();
          },
          color: AppColors.primary,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 150),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMainSection(provider),
                const SizedBox(height: 24),
                ActivityChartWidget(provider: provider),
                const SizedBox(height: 24),
                const InsightsWidget(),
                const SizedBox(height: 24),
                _buildAdditionalStats(provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainSection(ActivityTrackingProvider provider) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: UnifiedTrackingService.instance.dataStream,
      initialData: {
        'steps': 0,
        'distance': 0.0,
        'calories': 0.0,
        'is_tracking': false,
      },
      builder: (context, snapshot) {
        final serviceData = snapshot.data;
        final summary = provider.state.todaysSummary;

        final todaySteps = serviceData?['steps'] as int? ?? summary?.totalSteps ?? 0;
        final todayDistance = serviceData?['distance'] as double? ?? summary?.totalDistance ?? 0.0;
        final todayCalories = serviceData?['calories'] as double? ?? summary?.caloriesBurned ?? 0.0;
        final isTracking = serviceData?['is_tracking'] as bool? ?? false;

        final goalSteps = _goalSteps;
        final goalDistance = _goalDistance;
        final goalCalories = _goalCalories;

        String formatValue(dynamic value, String type) {
          if (value == null) return '0';
          switch (type) {
            case 'steps':
              return value.toString();
            case 'calories':
              final cal = value as double;
              if (cal == 0) return '0';
              if (cal < 10) return cal.toStringAsFixed(1);
              if (cal >= 100) return cal.toInt().toString();
              return cal.toStringAsFixed(1);
            case 'distance':
              final dist = value as double;
              if (dist == 0) return '0';
              return dist.toStringAsFixed(1);
            default:
              return value.toString();
          }
        }

        final statsList = [
          {
            'title': 'الخطوات',
            'value': todaySteps,
            'displayValue': formatValue(todaySteps, 'steps'),
            'goal': goalSteps,
            'goalDisplay': formatValue(goalSteps, 'steps'),
            'unit': 'خطوة',
            'color': AppColors.primary,
            'progress': goalSteps > 0 ? (todaySteps / goalSteps).clamp(0.0, 1.0) : 0.0,
          },
          {
            'title': 'السعرات',
            'value': todayCalories,
            'displayValue': formatValue(todayCalories, 'calories'),
            'goal': goalCalories,
            'goalDisplay': formatValue(goalCalories, 'calories'),
            'unit': 'سعرة',
            'color': AppColors.warning,
            'progress': goalCalories > 0 ? (todayCalories / goalCalories).clamp(0.0, 1.0) : 0.0,
          },
          {
            'title': 'المسافة',
            'value': todayDistance,
            'displayValue': formatValue(todayDistance, 'distance'),
            'goal': goalDistance,
            'goalDisplay': formatValue(goalDistance, 'distance'),
            'unit': 'كم',
            'color': AppColors.success,
            'progress': goalDistance > 0 ? (todayDistance / goalDistance).clamp(0.0, 1.0) : 0.0,
          },
        ];

        final currentIndex = _currentStatIndex.clamp(0, statsList.length - 1);
        final currentStat = statsList[currentIndex];

        return Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade50,
                Colors.white,
                const Color(0xFFF3F9FF),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(32.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 30.r,
                offset: Offset(0, 15.h),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: snapshot.hasData ? AppColors.success : AppColors.textMuted,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8.w,
                          height: 8.h,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          snapshot.hasData ? 'مباشر' : 'غير متصل',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: isTracking ? AppColors.info : AppColors.warning,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isTracking ? Icons.play_circle : Icons.pause_circle,
                          size: 12.sp,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          isTracking ? 'نشط' : 'متوقف',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'النشاط',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: -1,
                    ),
                  ),

                  ElevatedButton.icon(
                    onPressed: () => _showGoalEditDialog(context),
                    icon: Icon(
                      Icons.edit_rounded,
                      size: 18.sp,
                    ),
                    label: Text(
                      'تعديل الأهداف',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 2,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              Text(
                'لقد ${_getActivityText(currentStat['title'] as String)} اليوم',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 24.h),

              Row(
                children: [
                  Container(
                    width: 100.w,
                    height: 120.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.shade100.withOpacity(0.6),
                          Colors.blue.shade50.withOpacity(0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(25.r),
                    ),
                    child: Icon(
                      Icons.directions_run_rounded,
                      size: 60.sp,
                      color: AppColors.primary,
                    ),
                  ),

                  SizedBox(width: 20.w),

                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _currentStatIndex = (_currentStatIndex - 1 + statsList.length) % statsList.length;
                                });
                              },
                              child: Icon(
                                Icons.chevron_left,
                                size: 28.sp,
                                color: Colors.grey.shade500,
                              ),
                            ),

                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    currentStat['displayValue'] as String,
                                    style: TextStyle(
                                      fontSize: 36.sp,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),

                                  SizedBox(height: 2.h),

                                  Text(
                                    currentStat['unit'] as String,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),

                                  SizedBox(height: 4.h),

                                  Text(
                                    '/ ${currentStat['goalDisplay']} ${currentStat['unit']}',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.red.shade400,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),

                            InkWell(
                              onTap: () {
                                setState(() {
                                  _currentStatIndex = (_currentStatIndex + 1) % statsList.length;
                                });
                              },
                              child: Icon(
                                Icons.chevron_right,
                                size: 28.sp,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20.h),

                        _buildProgressBar(currentStat),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 32.h),

              _buildBottomCards(statsList),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomCards(List<Map<String, dynamic>> statsList) {
    return Row(
      children: statsList.asMap().entries.map((entry) {
        final index = entry.key;
        final stat = entry.value;
        final isActive = index == _currentStatIndex;
        final statColor = stat['color'] as Color;

        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isActive ? statColor : AppColors.border,
                width: isActive ? 3 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: statColor,
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  child: Icon(
                    _getCardIcon(stat['title'] as String),
                    size: 32.sp,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 12.h),

                Text(
                  stat['title'] as String,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: statColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: 8.h),

                Text(
                  stat['displayValue']?.toString() ?? '0',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 4.h),

                Text(
                  stat['unit'] as String,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                Text(
                  'الهدف ${stat['goalDisplay']}',
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w500,
                    color: statColor,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 8.h),

                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: statColor,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    isActive ? 'نشط' : 'الهدف',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProgressBar(Map<String, dynamic> stat) {
    final progress = (stat['progress'] as double?) ?? 0.0;
    final progressPercentage = (progress * 100).round();

    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 12.h,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: _getProgressColor(progress),
                borderRadius: BorderRadius.circular(6.r),
              ),
            ),
          ),
        ),

        SizedBox(height: 12.h),

        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: _getProgressColor(progress),
            borderRadius: BorderRadius.circular(15.r),
          ),
          child: Text(
            '$progressPercentage%',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalStats(ActivityTrackingProvider provider) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStableFutureCard(
                icon: Icons.history_rounded,
                label: 'أمس',
                future: _yesterdayStepsFuture,
                subtitle: 'خطوة',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStableFutureCard(
                icon: Icons.date_range_rounded,
                label: 'الأسبوع',
                future: _weeklyStepsFuture,
                subtitle: 'خطوة',
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildAdditionalStatsCard(
                icon: Icons.emoji_events_rounded,
                label: 'الهدف',
                value: '${provider.calculateGoalProgress()}%',
                subtitle: 'مكتمل',
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAdditionalStatsCard(
                icon: Icons.monitor_heart_rounded,
                label: 'اللياقة',
                value: '${(provider.state.fitnessScore * 100).round()}',
                subtitle: 'نقطة',
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStableFutureCard({
    required IconData icon,
    required String label,
    required Future<int>? future,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          future == null
              ? Text(
            'لم يتم التحميل',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          )
              : FutureBuilder<int>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '...',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                  ],
                );
              }

              final value = snapshot.data ?? 0;

              return Text(
                _formatNumber(value),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: value > 0 ? color : AppColors.textMuted,
                ),
              );
            },
          ),

          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalStatsCard({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
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

  IconData _getCardIcon(String title) {
    switch (title) {
      case 'الخطوات':
        return Icons.directions_walk_rounded;
      case 'السعرات':
        return Icons.local_fire_department_rounded;
      case 'المسافة':
        return Icons.trending_up_rounded;
      default:
        return Icons.fitness_center;
    }
  }

  String _getActivityText(String title) {
    switch (title) {
      case 'الخطوات':
        return 'مشيت';
      case 'السعرات':
        return 'أحرقت';
      case 'المسافة':
        return 'قطعت مسافة';
      default:
        return 'حققت';
    }
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) return AppColors.error;
    if (progress < 0.7) return AppColors.warning;
    return AppColors.success;
  }

  Widget _buildErrorState(ActivityTrackingProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ في تحميل البيانات',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            provider.state.error?.message ?? 'خطأ غير معروف',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.refreshData(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير';
    if (hour < 17) return 'نهارك سعيد';
    return 'مساء الخير';
  }

  Future<void> _showGoalEditDialog(BuildContext context) async {
    final stepsController = TextEditingController(text: _goalSteps.toString());
    final distanceController = TextEditingController(text: _goalDistance.toString());
    final caloriesController = TextEditingController(text: _goalCalories.toString());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            Icon(Icons.track_changes, color: AppColors.primary, size: 28.sp),
            SizedBox(width: 12.w),
            Text(
              'تعديل الأهداف',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: stepsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'الخطوات',
                  suffixText: 'خطوة',
                  prefixIcon: Icon(Icons.directions_walk, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              TextField(
                controller: distanceController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'المسافة',
                  suffixText: 'كم',
                  prefixIcon: Icon(Icons.straighten, color: AppColors.success),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: AppColors.success, width: 2),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              TextField(
                controller: caloriesController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'السعرات',
                  suffixText: 'سعرة',
                  prefixIcon: Icon(Icons.local_fire_department, color: AppColors.warning),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: AppColors.warning, width: 2),
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info, size: 20.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'سيتم تطبيق الأهداف الجديدة فوراً',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14.sp,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final steps = int.tryParse(stepsController.text);
              final distance = double.tryParse(distanceController.text);
              final calories = double.tryParse(caloriesController.text);

              if (steps == null || steps < 1000 || steps > 100000) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ الخطوات يجب أن تكون بين 1,000 و 100,000'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              if (distance == null || distance < 0.5 || distance > 100) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ المسافة يجب أن تكون بين 0.5 و 100 كم'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              if (calories == null || calories < 50 || calories > 5000) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ السعرات يجب أن تكون بين 50 و 5,000'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              await _updateGoal('steps', steps);
              await _updateGoal('distance', distance);
              await _updateGoal('calories', calories);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ تم تحديث الأهداف بنجاح'),
                    backgroundColor: AppColors.success,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
            child: Text(
              'حفظ',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateGoal(String type, dynamic value) async {
    try {
      bool success = false;

      switch (type) {
        case 'steps':
          success = await _userSettings.setStepsGoal(value as int);
          if (success && mounted) setState(() => _goalSteps = value);
          break;
        case 'distance':
          success = await _userSettings.setDistanceGoal(value as double);
          if (success && mounted) setState(() => _goalDistance = value);
          break;
        case 'calories':
          success = await _userSettings.setCaloriesGoal(value as double);
          if (success && mounted) setState(() => _goalCalories = value);
          break;
      }

      if (success) {
        final provider = Provider.of<ActivityTrackingProvider>(context, listen: false);
        await provider.refreshGoals();

        debugPrint('✅ تم تحديث هدف $type: $value');
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحديث الهدف: $e');
    }
  }
}