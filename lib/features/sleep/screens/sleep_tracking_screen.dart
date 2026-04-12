// lib/features/sleep/screens/sleep_tracking_screen.dart
import 'package:chatbot_ai/chatbot_ai.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/sleep_tracking_provider.dart';
import '../../../core/providers/sleep_tracking_state.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/unified_app_bar.dart';
import '../widgets/current_session_card.dart';
import '../widgets/pending_confirmations_card.dart';
import '../widgets/sleep_stats_card.dart';
import '../widgets/confidence_statistics_widget.dart';
import '../widgets/sleep_sessions_list.dart';
import '../widgets/smart_insights_widget.dart';
import 'session_details_screen.dart';
import 'sleep_settings_screen.dart';

class SleepTrackingScreen extends StatefulWidget {
  const SleepTrackingScreen({super.key});

  @override
  State<SleepTrackingScreen> createState() => _SleepTrackingScreenState();
}

class _SleepTrackingScreenState extends State<SleepTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🔄 [SleepTrackingScreen] بدء تحميل البيانات...');

    try {
      final provider = context.read<SleepTrackingProvider>();

      debugPrint('📊 [State Before] hasActiveSession: ${provider.state.hasActiveSession}');
      debugPrint('📊 [State Before] recentSessions: ${provider.state.recentSessions.length}');
      debugPrint('📊 [State Before] pendingConfirmations: ${provider.state.pendingConfirmations.length}');

      await provider.refreshData();

      debugPrint('📊 [State After] hasActiveSession: ${provider.state.hasActiveSession}');
      debugPrint('📊 [State After] recentSessions: ${provider.state.recentSessions.length}');
      debugPrint('📊 [State After] pendingConfirmations: ${provider.state.pendingConfirmations.length}');
      debugPrint('✅ [SleepTrackingScreen] تم تحميل البيانات بنجاح');

    } catch (e, stack) {
      debugPrint('❌ [SleepTrackingScreen] خطأ في تحميل البيانات: $e');
      debugPrint('Stack: $stack');
    }

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════
  // دوال UnifiedAppBar
  // ════════════════════════════════════════════════════════════

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'صباح الخير';
    } else if (hour >= 12 && hour < 17) {
      return 'مساء الخير';
    } else if (hour >= 17 && hour < 21) {
      return 'مساء الخير';
    } else {
      return 'مساء الخير';
    }
  }

  String _getSubtitle() {
    final provider = context.read<SleepTrackingProvider>();
    final state = provider.state;

    if (state.hasActiveSession) {
      final duration = DateTime.now().difference(state.currentSession!.startTime);
      return 'نائم منذ ${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (state.pendingConfirmations.isNotEmpty) {
      return '${state.pendingConfirmations.length} جلسات تحتاج تأكيد';
    } else if (state.recentSessions.isNotEmpty) {
      final lastSession = state.recentSessions.first;
      final hours = lastSession.duration?.inHours ?? 0;
      final minutes = lastSession.duration?.inMinutes.remainder(60) ?? 0;
      return 'آخر نوم: ${hours}h ${minutes}m';
    } else {
      return 'تتبع نومك بذكاء';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: UnifiedAppBar(
        greeting: _getGreeting(),
        subtitle: 'كيف حالك اليوم؟',
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
              child: Container()
          ),
        ],
        body: Column(
          children: [
            // Tab Bar
            _buildTabBar(),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTodayTab(),
                  _buildWeekTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // Tab Bar
  // ════════════════════════════════════════════════════════════

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 14,
        ),
        tabs: const [
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
    );
  }

  // ════════════════════════════════════════════════════════════
  // ✅ Settings Card - بديل FloatingActionButton
  // ════════════════════════════════════════════════════════════

  Widget _buildSettingsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SleepSettingsScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.settings,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إعدادات التتبع',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'تخصيص إعدادات النوم والتنبيهات',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // Tab 1: اليوم
  // ════════════════════════════════════════════════════════════

  // في _buildTodayTab()
  Widget _buildTodayTab() {
    debugPrint('🖼️ [UI] Building Today Tab...');

    return Consumer<SleepTrackingProvider>(
      builder: (context, provider, child) {
        debugPrint('📊 [Today Tab] hasActiveSession: ${provider.state.hasActiveSession}');
        debugPrint('📊 [Today Tab] pendingConfirmations: ${provider.state.pendingConfirmations.length}');

        return RefreshIndicator(
          onRefresh: () async {
            await provider.refreshData();
          },
          color: AppColors.primary,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Settings Card
                _buildSettingsCard(),
                const SizedBox(height: 16),

                // Current Session Card
                if (provider.state.hasActiveSession) ...[
                  CurrentSessionCard(
                    session: provider.state.currentSession!,
                    sleepState: provider.state.currentSleepState,
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  _buildNoActiveSessionCard(),
                  const SizedBox(height: 16),
                ],

                // ✅ Pending Confirmations - التعديل هنا!
                if (provider.state.pendingConfirmations.isNotEmpty) ...[
                  PendingConfirmationsCard(
                    sessions: provider.state.pendingConfirmations,
                    onConfirm: (sessionId, quality) async {
                      debugPrint('⏳ [Screen] بدء تأكيد جلسة $sessionId...');
                      await provider.confirmSleepSession(
                        sessionId: sessionId,
                        qualityRating: quality,
                      );
                      debugPrint('✅ [Screen] تم تأكيد الجلسة');
                    },
                    onReject: (sessionId) async {
                      debugPrint('⏳ [Screen] بدء رفض جلسة $sessionId...');
                      await provider.rejectSleepSession(sessionId);
                      debugPrint('✅ [Screen] تم رفض الجلسة');
                    },
                  ),
                  const SizedBox(height: 50),
                ],

                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════
  // Tab 2: الأسبوع (📊 هنا الرؤى الذكية!)
  // ════════════════════════════════════════════════════════════

  Widget _buildWeekTab() {
    debugPrint('🖼️ [UI] Building Week Tab...');

    return Consumer<SleepTrackingProvider>(
      builder: (context, provider, child) {
        debugPrint('📊 [Week Tab] recentSessions: ${provider.state.recentSessions.length}');

        return RefreshIndicator(
          onRefresh: () async {
            await provider.refreshData();
          },
          color: AppColors.primary,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // ✅ Debug Info - معلّق
                // _buildDebugInfoCard(provider),
                // const SizedBox(height: 16),

                // ✅ Settings Card
                _buildSettingsCard(),
                const SizedBox(height: 16),

                // Confidence Statistics
                const ConfidenceStatisticsWidget(),

                const SizedBox(height: 16),

                // ✅ الرؤى الذكية - موجودة هنا!
                const SmartInsightsWidget(),

                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════
  // Tab 3: السجل
  // ════════════════════════════════════════════════════════════

  Widget _buildHistoryTab() {
    debugPrint('🖼️ [UI] Building History Tab...');

    return Consumer<SleepTrackingProvider>(
      builder: (context, provider, child) {
        debugPrint('📊 [History Tab] recentSessions: ${provider.state.recentSessions.length}');

        if (provider.state.recentSessions.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            await provider.refreshData();
          },
          color: AppColors.primary,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Debug Info - معلّق
                // _buildDebugInfoCard(provider),
                // const SizedBox(height: 16),

                // ✅ Settings Card
                _buildSettingsCard(),
                const SizedBox(height: 16),

                // Section Header
                Row(
                  children: [
                    Icon(
                      Icons.history,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'جميع الجلسات',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${provider.state.recentSessions.length} جلسة',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Sessions List
                SleepSessionsList(
                  sessions: provider.state.recentSessions,
                  onSessionTap: (session) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SessionDetailsScreen(
                          session: session,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 150),
              ],
            ),
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════
  // ✅ Debug Info Card - معلّق (إزالة الـ comment لتفعيله)
  // ════════════════════════════════════════════════════════════

  /*
  Widget _buildDebugInfoCard(SleepTrackingProvider provider) {
    return Card(
      elevation: 1,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bug_report, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Debug Info',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildDebugRow('Auto Tracking', provider.state.isAutoTrackingActive ? '✅ نشط' : '❌ معطّل'),
            _buildDebugRow('Sleep State', provider.state.currentSleepState.displayName),
            _buildDebugRow('Active Session', provider.state.hasActiveSession ? '✅ موجودة' : '❌ لا توجد'),
            _buildDebugRow('Recent Sessions', '${provider.state.recentSessions.length}'),
            _buildDebugRow('Pending', '${provider.state.pendingConfirmations.length}'),
            _buildDebugRow('Loading', provider.state.loadingState.name),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
  */

  // ════════════════════════════════════════════════════════════
  // ✅ No Active Session Card
  // ════════════════════════════════════════════════════════════

  Widget _buildNoActiveSessionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.wb_sunny,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد جلسة نوم نشطة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'التتبع التلقائي يعمل في الخلفية',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // Empty State
  // ════════════════════════════════════════════════════════════

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bedtime_outlined,
              size: 80,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 24),
            Text(
              'لا توجد جلسات نوم بعد',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'التتبع التلقائي نشط ويعمل على مدار الساعة',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'سيتم تسجيل جلسات نومك تلقائياً',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

}