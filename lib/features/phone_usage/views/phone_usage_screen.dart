// lib/features/phone_usage/views/phone_usage_screen.dart
// ✅ نسخة محسّنة - بدون تكرار + استغلال أفضل للمساحة

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/helpers/permission_helper.dart';
import '../../../core/providers/phone_usage_provider.dart';
import '../../../core/database/models/app_usage_entry.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/loading_states.dart';
import '../../../shared/widgets/unified_app_bar.dart';
import '../widgets/dual_usage_circular_progress.dart';
import '../widgets/app_category_chart.dart';
import '../widgets/top_apps_list.dart';
import '../widgets/usage_insights_card.dart';

class PhoneUsageScreen extends StatefulWidget {
  const PhoneUsageScreen({Key? key}) : super(key: key);

  @override
  State<PhoneUsageScreen> createState() => _PhoneUsageScreenState();
}

class _PhoneUsageScreenState extends State<PhoneUsageScreen>
    with AutomaticKeepAliveClientMixin {

  bool _hasUsagePermission = false;
  bool _isCheckingPermission = false;
  String _currentView = 'overview';
  int _userGoalHours = 4;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _checkUsagePermission();
    _loadUserGoal();
  }

  Future<void> _checkUsagePermission() async {
    if (!mounted) return;

    setState(() => _isCheckingPermission = true);

    try {
      final hasPermission = await PermissionHelper.hasUsageStatsPermission();

      if (mounted) {
        setState(() {
          _hasUsagePermission = hasPermission;
          _isCheckingPermission = false;
        });

        if (hasPermission) {
          final provider = context.read<PhoneUsageProvider>();
          await provider.refresh();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasUsagePermission = false;
          _isCheckingPermission = false;
        });
      }
    }
  }

  Future<void> _loadUserGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedGoal = prefs.getInt('daily_goal_hours');
      if (savedGoal != null && mounted) {
        setState(() {
          _userGoalHours = savedGoal;
        });
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل هدف المستخدم: $e');
    }
  }

  Widget _buildEnhancedMainUsageCard(PhoneUsageProvider provider) {
    return Column(
      children: [
        _buildMainStatsHeader(provider),
        SizedBox(height: 24.h),
        DualUsageCircularProgress(
          currentUsage: provider.state.todaysTotalUsage,
          unifiedUsage: provider.state.todaysTotalUsage,
          targetUsage: Duration(hours: _getUserGoal()),
          syncAccuracy: 1.0,
          size: 200.w,
          onGoalTap: () => _showGoalSettingDialog(context, provider),
        ),
      ],
    );
  }

  Widget _buildMainStatsHeader(PhoneUsageProvider provider) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Icon(
            Icons.smartphone,
            color: AppColors.primary,
            size: 28.sp,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الاستخدام اليومي',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        // ✅ هون حطينا المستخدم والتطبيقات بدل "ممتاز"
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: AppColors.primary,
                  size: 16.sp,
                ),
                SizedBox(width: 4.w),
                Text(
                  provider.state.todaysUsageFormatted,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Icon(
                  Icons.apps,
                  color: AppColors.secondary,
                  size: 16.sp,
                ),
                SizedBox(width: 4.w),
                Text(
                  '${provider.state.todaysAppUsage.length} تطبيق',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ✅ كارد جديد: أكثر التطبيقات استخداماً اليوم (بدلاً من الكارد الأصفر المكرر)
  Widget _buildTopAppsQuickView(PhoneUsageProvider provider) {
    if (provider.state.todaysAppUsage.isEmpty) {
      return const SizedBox.shrink();
    }

    // ✅ ترتيب التطبيقات حسب الاستخدام وأخذ أول 3
    final sortedApps = provider.state.todaysAppUsage.toList()
      ..sort((a, b) => b.totalUsageTime.compareTo(a.totalUsageTime));
    final topApps = sortedApps.take(3).toList();

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1.w,
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
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.whatshot,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'الأكثر استخداماً اليوم',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...topApps.asMap().entries.map((entry) {
            final index = entry.key;
            final app = entry.value;
            final isLast = index == topApps.length - 1;

            return Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        color: _getTopAppColor(index),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        app.appName,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatDuration(app.totalUsageTime),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: _getTopAppColor(index),
                      ),
                    ),
                  ],
                ),
                if (!isLast) ...[
                  SizedBox(height: 12.h),
                  Divider(
                    color: AppColors.border,
                    height: 1.h,
                  ),
                  SizedBox(height: 12.h),
                ],
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Color _getTopAppColor(int index) {
    switch (index) {
      case 0:
        return AppColors.error; // ذهبي/أحمر
      case 1:
        return AppColors.info; // فضي/أزرق
      case 2:
        return AppColors.warning; // برونزي/برتقالي
      default:
        return AppColors.secondary;
    }
  }

  int _getUserGoal() {
    return _userGoalHours;
  }

  void _showGoalSettingDialog(BuildContext context, PhoneUsageProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.flag,
                color: AppColors.primary,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'تحديد هدف الاستخدام اليومي',
                style: TextStyle(fontSize: 16.sp),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'اختر هدفك لاستخدام الهاتف يومياً',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.secondary,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'الهدف الحالي: ${_userGoalHours} ساعات',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 16.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                _buildGoalChip(2, 'صحي جداً', Icons.sentiment_very_satisfied, AppColors.success),
                _buildGoalChip(4, 'صحي', Icons.sentiment_satisfied, AppColors.primary),
                _buildGoalChip(6, 'متوسط', Icons.sentiment_neutral, AppColors.warning),
                _buildGoalChip(8, 'مرتفع', Icons.sentiment_dissatisfied, AppColors.error),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: TextStyle(color: AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalChip(int hours, String label, IconData icon, Color color) {
    final isSelected = hours == _userGoalHours;

    return GestureDetector(
      onTap: () {
        _saveUserGoal(hours);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم تحديد الهدف إلى ${hours} ساعات يومياً'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 80.h, left: 16.w, right: 16.w),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2.w : 1.w,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? color : AppColors.textSecondary,
              size: 16.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              '${hours}س - $label',
              style: TextStyle(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14.sp,
              ),
            ),
            if (isSelected) ...[
              SizedBox(width: 8.w),
              Icon(
                Icons.check_circle,
                color: color,
                size: 16.sp,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveUserGoal(int hours) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('daily_goal_hours', hours);

      if (mounted) {
        setState(() {
          _userGoalHours = hours;
        });
      }

      debugPrint('✅ تم حفظ هدف المستخدم: $hours ساعات');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ هدف المستخدم: $e');
    }
  }

  Color _getWellnessColor(double score) {
    if (score >= 0.8) return AppColors.success;
    if (score >= 0.6) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = kToolbarHeight + MediaQuery.of(context).viewPadding.top;
    final bottomNavHeight = kBottomNavigationBarHeight + bottomPadding;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: UnifiedAppBar(
        greeting: _getGreeting(),
        onNotificationTap: () {},
        onProfileTap: () {
          Navigator.pushNamed(context, '/profile');
        },
      ),
      body: Consumer<PhoneUsageProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: () => provider.refresh(),
            color: AppColors.primary,
            backgroundColor: Colors.white,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                if (!_hasUsagePermission || _isCheckingPermission)
                  _buildPermissionSliver(),

                if (_hasUsagePermission && provider.state.isLoading)
                  _buildLoadingSliver(),

                if (_hasUsagePermission &&
                    !provider.state.isLoading &&
                    !_hasData(provider))
                  _buildNoDataSliver(),

                if (_hasUsagePermission &&
                    !provider.state.isLoading &&
                    _hasData(provider)) ...[
                  _buildHeaderSliver(provider),
                  _buildMainContentSliver(provider, bottomNavHeight),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSliver(PhoneUsageProvider provider) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(16.w),
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: AppColors.border,
            width: 1.w,
          ),
        ),
        child: _buildEnhancedMainUsageCard(provider),
      ),
    );
  }

  Widget _buildMainContentSliver(PhoneUsageProvider provider, double bottomNavHeight) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, bottomNavHeight + 20.h),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildContentBasedOnView(provider),
        ]),
      ),
    );
  }

  Widget _buildContentBasedOnView(PhoneUsageProvider provider) {
    switch (_currentView) {
      case 'detailed':
        return _buildDetailedView(provider);
      case 'analytics':
        return _buildAnalyticsView(provider);
      default:
        return _buildOverviewContent(provider);
    }
  }

  Widget _buildOverviewContent(PhoneUsageProvider provider) {
    final categorizedApps = _categorizeApps(provider.state.todaysAppUsage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ كارد أكثر التطبيقات (بدلاً من الكارد الأصفر المكرر)
        _buildTopAppsQuickView(provider),

        if (categorizedApps.isNotEmpty) ...[
          _buildSectionTitle('تصنيف التطبيقات', Icons.category),
          SizedBox(height: 12.h),
          AppCategoryChart(
            categorizedApps: categorizedApps,
            totalUsage: provider.state.todaysTotalUsage,
          ),
          SizedBox(height: 24.h),
        ],

        /*if (provider.state.todaysAppUsage.isNotEmpty) ...[
          _buildSectionTitle('جميع التطبيقات', Icons.apps),
          SizedBox(height: 12.h),
          EnhancedTopAppsList(
            apps: provider.state.todaysAppUsage,
            totalUsage: provider.state.todaysTotalUsage,
            categorizedApps: categorizedApps,
          ),
          SizedBox(height: 24.h),
        ],*/

        if (provider.state.activeAlerts.isNotEmpty) ...[
          _buildSectionTitle('تنبيهات وتوصيات', Icons.lightbulb_outline),
          SizedBox(height: 12.h),
          UsageInsightsCard(
            alerts: provider.state.activeAlerts,
            wellnessScore: provider.state.wellnessScore,
            onDismissAlert: (alert) => provider.dismissAlert(alert),
          ),
          SizedBox(height: 24.h),
        ],

        if (_shouldShowWeeklySection(provider))
          _buildWeeklyUsageSection(provider),

        SizedBox(height: 100.h),
      ],
    );
  }

  Widget _buildDetailedView(PhoneUsageProvider provider) {
    return Column(
      children: [
        _buildDetailedStats(provider),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _buildAnalyticsView(PhoneUsageProvider provider) {
    return Column(
      children: [
        _buildAnalyticsSummary(provider),
        SizedBox(height: 24.h),
        _buildTrendAnalysis(provider),
        SizedBox(height: 24.h),
        _buildBehaviorInsights(provider),
      ],
    );
  }

  Widget _buildDetailedStats(PhoneUsageProvider provider) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.border,
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('إحصائيات مفصلة', Icons.analytics),
          SizedBox(height: 16.h),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16.w,
            mainAxisSpacing: 16.h,
            children: [
              _buildDetailedStatCard(
                'التطبيقات',
                '${provider.state.todaysAppUsage.length}',
                Icons.apps,
                AppColors.info,
              ),
              _buildDetailedStatCard(
                'أطول جلسة',
                _findLongestSession(provider),
                Icons.trending_up,
                AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: color,
          width: 2.w,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28.sp),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSummary(PhoneUsageProvider provider) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.border,
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('ملخص التحليلات', Icons.insights),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'نتيجة الصحة',
                  '${(provider.state.wellnessScore * 100).round()}%',
                  provider.state.wellnessGrade,
                  _getWellnessColor(provider.state.wellnessScore),
                  Icons.health_and_safety,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildAnalyticsCard(
                  'التطبيقات المستخدمة',
                  '${provider.state.todaysAppUsage.length}',
                  'تطبيق اليوم',
                  AppColors.info,
                  Icons.apps,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, String subtitle, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: color,
          width: 2.w,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32.sp),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendAnalysis(PhoneUsageProvider provider) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.border,
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('تحليل الاتجاهات', Icons.trending_up),
          SizedBox(height: 16.h),
          if (provider.state.weeklyAppUsage.isNotEmpty) ...[
            _buildTrendChart(provider),
          ] else ...[
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 48.sp,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'بيانات الاتجاهات ستظهر قريباً',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14.sp,
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

  Widget _buildTrendChart(PhoneUsageProvider provider) {
    final weeklyData = provider.state.weeklyAppUsage;
    final sortedDates = weeklyData.keys.toList()..sort();

    return SizedBox(
      height: 200.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final date = sortedDates[index];
          final usage = weeklyData[date]!;
          final maxUsage = weeklyData.values.isNotEmpty
              ? weeklyData.values.reduce((a, b) => a.inMinutes > b.inMinutes ? a : b)
              : const Duration(hours: 1);
          final heightRatio = usage.inMinutes / maxUsage.inMinutes;

          return Container(
            width: 60.w,
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${usage.inHours}س',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Container(
                  height: 120.h * heightRatio,
                  width: 30.w,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  date.split('-').last,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBehaviorInsights(PhoneUsageProvider provider) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.border,
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('رؤى السلوك', Icons.psychology),
          SizedBox(height: 16.h),
          ..._generateBehaviorInsights(provider).map((insight) =>
              _buildInsightItem(insight)).toList(),
        ],
      ),
    );
  }

  Widget _buildInsightItem(Map<String, dynamic> insight) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: insight['color'] as Color,
          width: 2.w,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: insight['color'] as Color,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              insight['icon'] as IconData,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight['title'] as String,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: insight['color'] as Color,
                  ),
                ),
                Text(
                  insight['description'] as String,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyUsageSection(PhoneUsageProvider provider) {
    final weeklyData = provider.state.weeklyAppUsage;

    if (weeklyData.isEmpty) {
      return Container();
    }

    final values = weeklyData.values.toList();
    final dailyAverage = values.isNotEmpty
        ? Duration(minutes: (values.fold(0, (sum, d) => sum + d.inMinutes) / values.length).round())
        : Duration.zero;
    final highestDay = values.isNotEmpty
        ? values.reduce((a, b) => a.inMinutes > b.inMinutes ? a : b)
        : Duration.zero;
    final lowestDay = values.isNotEmpty
        ? values.reduce((a, b) => a.inMinutes < b.inMinutes ? a : b)
        : Duration.zero;

    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: AppColors.border,
          width: 1.w,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(
                  Icons.date_range,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'معدل الاستخدام الأسبوعي',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${weeklyData.length} أيام من البيانات',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: _buildWeeklyStatItem(
                  'معدل يومي',
                  _formatDuration(dailyAverage),
                  Icons.today,
                  AppColors.info,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildWeeklyStatItem(
                  'أعلى يوم',
                  _formatDuration(highestDay),
                  Icons.trending_up,
                  AppColors.error,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildWeeklyStatItem(
                  'أقل يوم',
                  _formatDuration(lowestDay),
                  Icons.trending_down,
                  AppColors.success,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildWeekProgressBar(weeklyData),
        ],
      ),
    );
  }

  Widget _buildWeeklyStatItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: color,
          width: 2.w,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24.sp,
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeekProgressBar(Map<String, Duration> weeklyData) {
    final weekDays = ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
    final today = DateTime.now();
    final todayWeekday = today.weekday % 7;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الأسبوع الحالي',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'أيام البيانات: ${weeklyData.length}',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: weekDays.asMap().entries.map((entry) {
            final index = entry.key;
            final day = entry.value;
            final isToday = index == todayWeekday;

            final dayDate = today.subtract(Duration(days: todayWeekday - index));
            final dayKey = _formatDate(dayDate);
            final hasData = weeklyData.containsKey(dayKey) &&
                weeklyData[dayKey]!.inSeconds > 0;

            final isPassed = index < todayWeekday;

            return Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 2.w),
                child: Column(
                  children: [
                    Container(
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppColors.primary
                            : hasData
                            ? AppColors.success
                            : isPassed
                            ? AppColors.textMuted
                            : AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: Text(
                          isToday
                              ? 'اليوم'
                              : hasData
                              ? '${weeklyData[dayKey]?.inHours ?? 0}س'
                              : isPassed
                              ? 'لا يوجد'
                              : '',
                          style: TextStyle(
                            color: (isToday || hasData) ? Colors.white : AppColors.textSecondary,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      day,
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: isToday ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPermissionSliver() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Container(
        color: AppColors.backgroundLight,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(32.r),
                  ),
                  child: Icon(
                    Icons.security,
                    color: Colors.white,
                    size: 48.sp,
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'إذن الوصول لإحصائيات الاستخدام',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                Text(
                  'نحتاج إذن الوصول لإحصائيات الاستخدام لعرض بيانات التطبيقات بدقة.\n'
                      'هذا الإذن آمن ولا يشارك بياناتك مع أي طرف ثالث.',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32.h),
                if (_isCheckingPermission)
                  const CircularProgressIndicator()
                else
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton(
                      onPressed: () async {
                        final provider = context.read<PhoneUsageProvider>();
                        final granted = await provider.checkAndRequestPermissions();

                        if (granted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('✅ تم منح الإذن بنجاح!'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              margin: EdgeInsets.only(bottom: 120.h, left: 16.w, right: 16.w),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('❌ لم يتم منح الإذن'),
                              backgroundColor: AppColors.warning,
                              behavior: SnackBarBehavior.floating,
                              margin: EdgeInsets.only(bottom: 120.h, left: 16.w, right: 16.w),
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                      child: Text(
                        'منح الإذن',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSliver() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: LoadingStates.modernLoading(
        message: 'جاري تحميل البيانات الحقيقية...',
      ),
    );
  }

  Widget _buildNoDataSliver() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Container(
        color: AppColors.backgroundLight,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(32.r),
                    border: Border.all(
                      color: AppColors.border,
                      width: 2.w,
                    ),
                  ),
                  child: Icon(
                    Icons.data_usage_outlined,
                    color: AppColors.textMuted,
                    size: 48.sp,
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'لا توجد بيانات للعرض',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                Text(
                  'ابدأ باستخدام التطبيقات وستظهر الإحصائيات هنا.\n'
                      'قد تحتاج إلى انتظار بضع دقائق لظهور البيانات.',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32.h),
                ElevatedButton.icon(
                  onPressed: () {
                    final provider = context.read<PhoneUsageProvider>();
                    provider.refresh();
                  },
                  icon: Icon(Icons.refresh, color: Colors.white, size: 20.sp),
                  label: Text(
                    'تحديث البيانات',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 20.sp,
          ),
        ),
        SizedBox(width: 12.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  // Helper functions
  bool _hasData(PhoneUsageProvider provider) {
    return provider.state.todaysTotalUsage.inSeconds > 0 ||
        provider.state.todaysAppUsage.isNotEmpty;
  }

  bool _shouldShowWeeklySection(PhoneUsageProvider provider) {
    return provider.state.weeklyAppUsage.isNotEmpty &&
        provider.state.weeklyAppUsage.values.any((duration) => duration.inSeconds > 0);
  }

  Map<String, List<AppUsageEntry>> _categorizeApps(List<AppUsageEntry> apps) {
    final categories = <String, List<AppUsageEntry>>{};

    for (final app in apps) {
      final category = _getAppCategoryByName(app.packageName, app.appName);
      categories.putIfAbsent(category, () => []).add(app);
    }

    return categories;
  }

  String _getAppCategoryByName(String packageName, String appName) {
    final socialApps = ['whatsapp', 'telegram', 'facebook', 'messenger', 'instagram', 'twitter', 'snapchat', 'tiktok'];
    final entertainmentApps = ['youtube', 'netflix', 'spotify', 'anghami', 'shahid'];
    final productivityApps = ['microsoft', 'google', 'office', 'excel', 'word', 'drive', 'gmail'];
    final gamesApps = ['game', 'play', 'clash', 'candy', 'pubg'];
    final shoppingApps = ['amazon', 'noon', 'souq', 'careem', 'uber', 'talabat'];

    final lowerPackage = packageName.toLowerCase();
    final lowerApp = appName.toLowerCase();

    if (socialApps.any((keyword) => lowerPackage.contains(keyword) || lowerApp.contains(keyword))) {
      return 'التواصل الاجتماعي';
    } else if (entertainmentApps.any((keyword) => lowerPackage.contains(keyword) || lowerApp.contains(keyword))) {
      return 'الترفيه';
    } else if (productivityApps.any((keyword) => lowerPackage.contains(keyword) || lowerApp.contains(keyword))) {
      return 'الإنتاجية';
    } else if (gamesApps.any((keyword) => lowerPackage.contains(keyword) || lowerApp.contains(keyword))) {
      return 'الألعاب';
    } else if (shoppingApps.any((keyword) => lowerPackage.contains(keyword) || lowerApp.contains(keyword))) {
      return 'التسوق';
    } else {
      return 'عام';
    }
  }

  String _findLongestSession(PhoneUsageProvider provider) {
    if (provider.state.todaysAppUsage.isEmpty) return '0د';
    final longest = provider.state.todaysAppUsage
        .map((app) => app.totalUsageTime)
        .reduce((a, b) => a.inMinutes > b.inMinutes ? a : b);
    return _formatDuration(longest);
  }

  List<Map<String, dynamic>> _generateBehaviorInsights(PhoneUsageProvider provider) {
    final insights = <Map<String, dynamic>>[];

    if (provider.state.todaysTotalUsage.inHours > 6) {
      insights.add({
        'title': 'استخدام مكثف',
        'description': 'استخدام عالي اليوم، فكر في أخذ استراحات',
        'icon': Icons.warning,
        'color': AppColors.error,
      });
    } else if (provider.state.todaysTotalUsage.inHours < 2) {
      insights.add({
        'title': 'استخدام صحي',
        'description': 'مستوى استخدام ممتاز اليوم!',
        'icon': Icons.check_circle,
        'color': AppColors.success,
      });
    }

    if (provider.state.todaysAppUsage.length > 20) {
      insights.add({
        'title': 'تطبيقات متعددة',
        'description': 'استخدمت ${provider.state.todaysAppUsage.length} تطبيق اليوم',
        'icon': Icons.apps,
        'color': AppColors.info,
      });
    }

    return insights;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}س ${minutes}د';
    } else {
      return '${minutes}د';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير';
    if (hour < 17) return 'نهارك سعيد';
    return 'مساء الخير';
  }
}