// lib/features/sleep/screens/sleep_main_screen.dart - النسخة البسيطة

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:smart_psych/features/sleep/screens/sleep_confirmation_screen.dart';
import '../../../core/providers/sleep_tracking_provider.dart';
import '../../../shared/widgets/unified_app_bar.dart';
import '../../../shared/theme/app_colors.dart';
import '../tabs/today_tab.dart';
import '../tabs/week_tab.dart';
import '../tabs/history_tab.dart';
import '../screens/sleep_settings_screen.dart';
import '../screens/sleep_insights_screen.dart';

class SleepMainScreen extends StatefulWidget {
  const SleepMainScreen({Key? key}) : super(key: key);

  @override
  State<SleepMainScreen> createState() => _SleepMainScreenState();
}

class _SleepMainScreenState extends State<SleepMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير 🌅';
    if (hour < 17) return 'مساء الخير ☀️';
    if (hour < 21) return 'مساء الخير 🌆';
    return 'ليلة سعيدة 🌙';
  }

  String _getSubtitle() {
    final provider = context.read<SleepTrackingProvider>();
    final state = provider.state;

    if (state.hasActiveSession) {
      final duration = DateTime.now().difference(state.currentSession!.startTime);
      return 'نائم منذ ${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (state.pendingConfirmations.isNotEmpty) {
      return 'لديك ${state.pendingConfirmations.length} جلسات تحتاج تأكيد';
    } else {
      return 'تتبع نومك تلقائياً 😴';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: UnifiedAppBar(
        greeting: _getGreeting(),
        subtitle: _getSubtitle(),
        onNotificationTap: () {
          _showNotifications(context);
        },
        onProfileTap: () {
          Navigator.pushNamed(context, '/profile');
        },
        hasNotificationBadge: context.watch<SleepTrackingProvider>()
            .state.pendingConfirmations.isNotEmpty,
      ),
      body: Column(
        children: [
          // Tab Bar مخصص بالألوان الموحدة
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border,
                width: 1,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 14,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('📅'),
                      SizedBox(width: 4),
                      Text('اليوم'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('📊'),
                      SizedBox(width: 4),
                      Text('الأسبوع'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('📜'),
                      SizedBox(width: 4),
                      Text('السجل'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // محتوى التابات
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                TodayTab(),
                WeekTab(),
                HistoryTab(),
              ],
            ),
          ),

          SizedBox(height: 100.h),
        ],
      ),

      // زر الإعدادات والرؤى
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // زر الرؤى الذكية
          FloatingActionButton(
            heroTag: 'insights',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SleepInsightsScreen(),
                ),
              );
            },
            backgroundColor: AppColors.info,
            child: Icon(Icons.lightbulb_outline, color: Colors.white),
          ),

          SizedBox(height: 12),

        /*  // زر الإعدادات
          FloatingActionButton(
            heroTag: 'settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SleepSettingsScreen(),
                ),
              );
            },
            backgroundColor: AppColors.primary,
            child: Icon(Icons.settings, color: Colors.white),
          ),
*/
          SizedBox(height: 12),

          // زر التأكيد (يظهر فقط عند وجود جلسات معلقة)
          Consumer<SleepTrackingProvider>(
            builder: (context, provider, _) {
              if (provider.state.pendingConfirmations.isEmpty) {
                return SizedBox.shrink();
              }

              return FloatingActionButton.extended(
                heroTag: 'confirm',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SleepConfirmationScreen(),
                    ),
                  );

                },
                backgroundColor: AppColors.warning,
                icon: Icon(Icons.check_circle_outline, color: Colors.white),
                label: Text(
                  'تأكيد (${provider.state.pendingConfirmations.length})',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),

          SizedBox(height: 100.h),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  void _showNotifications(BuildContext context) {
    final provider = context.read<SleepTrackingProvider>();
    final pendingCount = provider.state.pendingConfirmations.length;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            SizedBox(height: 20),

            Text(
              '🔔 الإشعارات',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),

            SizedBox(height: 20),

            if (pendingCount > 0)
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary, width: 1),
                  ),
                  child: Icon(
                    Icons.bedtime,
                    color: AppColors.primary,
                  ),
                ),
                title: Text(
                  'جلسات نوم تحتاج تأكيد',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '$pendingCount جلسة في انتظار التقييم',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/sleep-confirmation');
                },
              ),

            if (pendingCount == 0)
              Padding(
                padding: EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: AppColors.success,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'لا توجد إشعارات جديدة',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}