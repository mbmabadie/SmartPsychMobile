// lib/features/dashboard/views/dashboard_screen.dart - النسخة النهائية الكاملة

import 'package:chatbot_ai/chatbot_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_psych/features/activity_tracking/views/activity_tracking_screen.dart';
import 'package:smart_psych/features/phone_usage/views/phone_usage_screen.dart';
import 'package:smart_psych/features/sleep/screens/sleep_main_screen.dart';
import 'package:smart_psych/features/statistics/views/statistics_screen.dart';
import 'package:smart_psych/features/assessments/views/assessment_screen.dart';

import '../../../core/database/models/nav_item_model.dart';
import '../../../shared/theme/app_colors.dart';
import '../../sleep/screens/sleep_tracking_screen.dart';
import '../widgets/animated_bottom_nav.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  // قائمة الشاشات - 6 شاشات
  late final List<Widget> _screens;

  // قائمة عناصر الـ Navigation - 6 عناصر
  final List<NavItemModel> _navItems = [
    NavItemModel(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'الرئيسية',
      color: AppColors.primary,
    ),
    NavItemModel(
      icon: Icons.phone_android_outlined,
      activeIcon: Icons.phone_android_rounded,
      label: 'الهاتف',
      color: AppColors.secondary,
    ),
    NavItemModel(
      icon: Icons.directions_run_outlined,
      activeIcon: Icons.directions_run_rounded,
      label: 'النشاط',
      color: AppColors.success,
    ),
    NavItemModel(
      icon: Icons.bedtime_outlined,
      activeIcon: Icons.bedtime_rounded,
      label: 'النوم',
      color: AppColors.info,
    ),
    NavItemModel(
      icon: Icons.quiz_outlined,
      activeIcon: Icons.quiz_rounded,
      label: 'الاختبارات',
      color: AppColors.warning,
    ),
    NavItemModel(
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble_rounded,
      label: 'المحادثة',
      color: AppColors.accent,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // تهيئة الشاشات مع callback للـ navigation
    _screens = [
      StatisticsScreen(onNavigateToPage: _navigateToPage),  // 0 - الإحصائيات
      const PhoneUsageScreen(),                              // 1 - استخدام الهاتف
      const ActivityScreen(),                                // 2 - النشاط
      const SleepTrackingScreen(),                               // 3 - النوم
      const AssessmentScreen(),                                    // 4 - الاختبارات
      const ChatbotAi(                                             // 5 - المحادثة
        isCvPending: false,
        title: "المحادثة",
        userData: {},
        language: "ar",
        name: "",
        id: "",
        url: "",
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // دالة للانتقال بين الصفحات
  void _navigateToPage(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= _screens.length) {
      debugPrint('❌ رقم الصفحة غير صحيح: $pageIndex');
      return;
    }

    HapticFeedback.lightImpact();

    setState(() {
      _currentIndex = pageIndex;
    });

    _pageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    debugPrint('🔄 الانتقال للصفحة: $pageIndex (${_navItems[pageIndex].label})');
  }

  void _onNavTap(int index) {
    _navigateToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.backgroundLight,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _screens,
      ),
      bottomNavigationBar: AnimatedBottomNav(
        currentIndex: _currentIndex,
        items: _navItems,
        onTap: _onNavTap,
        isTablet: isTablet,
      ),
    );
  }
}

// ==========================================
// شاشة مؤقتة للأقسام الأخرى
// ==========================================

class _TemporaryScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _TemporaryScreen({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isTablet ? 32 : 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 32 : 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 3),
                ),
                child: Icon(
                  icon,
                  size: isTablet ? 80 : 64,
                  color: color,
                ),
              ),

              SizedBox(height: isTablet ? 32 : 24),

              Text(
                'شاشة $title',
                style: TextStyle(
                  fontSize: isTablet ? 32 : 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),

              SizedBox(height: isTablet ? 16 : 12),

              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24 : 20,
                  vertical: isTablet ? 12 : 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'قريباً... ⚡',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              SizedBox(height: isTablet ? 48 : 32),

              Container(
                padding: EdgeInsets.all(isTablet ? 24 : 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color, width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      'ميزات قادمة',
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),

                    SizedBox(height: isTablet ? 16 : 12),

                    Text(
                      'هذا القسم تحت التطوير وسيتم إضافة ميزات رائعة قريباً',
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 12,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}