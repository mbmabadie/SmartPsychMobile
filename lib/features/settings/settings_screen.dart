// lib/features/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Core
import '../../core/providers/app_state_provider.dart';
import '../../core/database/models/common_models.dart' as models;
import '../../core/services/api_service.dart';
import '../../core/services/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Shared
import '../../shared/widgets/unified_app_bar.dart';
import '../../shared/localization/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

/// شاشة الإعدادات الرئيسية
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {

  // ==========================================
  // Animation Controllers
  // ==========================================

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late List<AnimationController> _itemControllers;

  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  void _initAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Animation controllers للعناصر
    _itemControllers = List.generate(
      7, // عدد الفئات
          (index) => AnimationController(
        duration: Duration(milliseconds: 400 + (index * 100)),
        vsync: this,
      ),
    );

    // بدء الرسوم المتحركة
    _startAnimations();
  }

  void _startAnimations() async {
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _slideController.forward();

    // تحريك العناصر بشكل متسلسل
    for (int i = 0; i < _itemControllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        _itemControllers[i].forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 768;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: UnifiedAppBar(
        title: l10n.settings,
        showBackButton: true,
      ),
      body: FadeTransition(
        opacity: _fadeController,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _slideController,
            curve: Curves.easeOutBack,
          )),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Profile Header
              _buildProfileHeader(context, theme, l10n, isTablet),

              // Quick Actions
              _buildQuickActions(context, theme, l10n, isTablet),

              // Settings Categories
              _buildSettingsCategories(context, theme, l10n, isTablet),

              // Account / Logout Section
              _buildAccountSection(context, theme, isTablet),

              // Bottom Spacing
              SliverToBoxAdapter(
                child: SizedBox(height: isTablet ? 120 : 100),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // Profile Header
  // ==========================================

  Widget _buildProfileHeader(BuildContext context, ThemeData theme, AppLocalizations l10n, bool isTablet) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(isTablet ? 24 : 16),
        padding: EdgeInsets.all(isTablet ? 32 : 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Profile Picture
            Stack(
              children: [
                Container(
                  width: isTablet ? 100 : 80,
                  height: isTablet ? 100 : 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(isTablet ? 50 : 40),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    Icons.person,
                    size: isTablet ? 50 : 40,
                    color: Colors.white,
                  ),
                ),

                // Edit Button
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _editProfile(),
                    child: Container(
                      width: isTablet ? 32 : 28,
                      height: isTablet ? 32 : 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: isTablet ? 16 : 14,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: isTablet ? 20 : 16),

            // User Name
            Text(
              'مستخدم Smart Psych', // يمكن جلبه من الـ Provider
              style: TextStyle(
                fontSize: isTablet ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            SizedBox(height: isTablet ? 8 : 6),

            // User Email or Info
            Text(
              'user@example.com', // يمكن جلبه من الـ Provider
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),

            SizedBox(height: isTablet ? 24 : 20),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('أيام النشاط', '127', isTablet),
                _buildStatDivider(),
                _buildStatItem('الإنجازات', '24', isTablet),
                _buildStatDivider(),
                _buildStatItem('النقاط', '1,250', isTablet),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, bool isTablet) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: isTablet ? 20 : 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: isTablet ? 4 : 2),
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 14 : 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white.withOpacity(0.3),
    );
  }

  // ==========================================
  // Quick Actions
  // ==========================================

  Widget _buildQuickActions(BuildContext context, ThemeData theme, AppLocalizations l10n, bool isTablet) {
    final quickActions = [
      QuickAction(
        icon: Icons.backup,
        label: 'نسخ احتياطي',
        color: AppColors.info,
        onTap: () => _handleBackup(),
      ),
      QuickAction(
        icon: Icons.file_download,
        label: 'تصدير البيانات',
        color: AppColors.success,
        onTap: () => _handleExportData(),
      ),
      QuickAction(
        icon: Icons.sync,
        label: 'مزامنة',
        color: AppColors.warning,
        onTap: () => _handleSync(),
      ),
      QuickAction(
        icon: Icons.help_outline,
        label: 'المساعدة',
        color: AppColors.secondary,
        onTap: () => _handleHelp(),
      ),
    ];

    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: isTablet ? 24 : 16,
          vertical: isTablet ? 16 : 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إجراءات سريعة',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: isTablet ? 18 : 16,
              ),
            ),

            SizedBox(height: isTablet ? 16 : 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isTablet ? 4 : 2,
                childAspectRatio: isTablet ? 1.2 : 1.5,
                crossAxisSpacing: isTablet ? 16 : 12,
                mainAxisSpacing: isTablet ? 16 : 12,
              ),
              itemCount: quickActions.length,
              itemBuilder: (context, index) {
                final action = quickActions[index];
                return _buildQuickActionCard(action, isTablet, index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(QuickAction action, bool isTablet, int index) {
    return AnimatedBuilder(
      animation: _itemControllers[0], // استخدام أول controller للـ quick actions
      builder: (context, child) {
        final animation = CurvedAnimation(
          parent: _itemControllers[0],
          curve: Interval(
            index * 0.1,
            1.0,
            curve: Curves.easeOutBack,
          ),
        );

        return Transform.scale(
          scale: animation.value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - animation.value)),
            child: Opacity(
              opacity: animation.value,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    action.onTap();
                  },
                  borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: action.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                      border: Border.all(
                        color: action.color.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: isTablet ? 48 : 40,
                          height: isTablet ? 48 : 40,
                          decoration: BoxDecoration(
                            color: action.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
                          ),
                          child: Icon(
                            action.icon,
                            color: action.color,
                            size: isTablet ? 24 : 20,
                          ),
                        ),

                        SizedBox(height: isTablet ? 12 : 8),

                        Text(
                          action.label,
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            fontWeight: FontWeight.w600,
                            color: action.color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // Settings Categories
  // ==========================================

  Widget _buildSettingsCategories(BuildContext context, ThemeData theme, AppLocalizations l10n, bool isTablet) {
    final categories = _getFilteredCategories();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final category = categories[index];
          final animationIndex = index + 1; // +1 لأن 0 استخدمناه للـ quick actions

          return AnimatedBuilder(
            animation: animationIndex < _itemControllers.length
                ? _itemControllers[animationIndex]
                : _itemControllers.last,
            builder: (context, child) {
              final controller = animationIndex < _itemControllers.length
                  ? _itemControllers[animationIndex]
                  : _itemControllers.last;

              final slideAnimation = Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: controller,
                curve: Curves.easeOutBack,
              ));

              final fadeAnimation = Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: controller,
                curve: Curves.easeOut,
              ));

              return SlideTransition(
                position: slideAnimation,
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: _buildCategoryCard(category, theme, l10n, isTablet),
                ),
              );
            },
          );
        },
        childCount: categories.length,
      ),
    );
  }

  Widget _buildCategoryCard(SettingsCategory category, ThemeData theme, AppLocalizations l10n, bool isTablet) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: isTablet ? 12 : 8,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header
          Padding(
            padding: EdgeInsets.all(isTablet ? 24 : 20),
            child: Row(
              children: [
                Container(
                  width: isTablet ? 48 : 40,
                  height: isTablet ? 48 : 40,
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                  ),
                  child: Icon(
                    category.icon,
                    color: category.color,
                    size: isTablet ? 24 : 20,
                  ),
                ),

                SizedBox(width: isTablet ? 16 : 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: isTablet ? 18 : 16,
                        ),
                      ),

                      if (category.subtitle != null) ...[
                        SizedBox(height: 4),
                        Text(
                          category.subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: isTablet ? 14 : 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                Icon(
                  Icons.arrow_forward_ios,
                  size: isTablet ? 20 : 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ],
            ),
          ),

          // Category Items
          ...category.items.map((item) => _buildSettingsItem(item, theme, isTablet)),

          SizedBox(height: isTablet ? 8 : 4),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(SettingsItem item, ThemeData theme, bool isTablet) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          item.onTap();
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 20,
            vertical: isTablet ? 16 : 12,
          ),
          child: Row(
            children: [
              // Leading Icon
              if (item.icon != null) ...[
                Icon(
                  item.icon,
                  size: isTablet ? 22 : 20,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                SizedBox(width: isTablet ? 16 : 12),
              ],

              // Title
              Expanded(
                child: Text(
                  item.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Trailing Widget
              if (item.trailing != null) ...[
                SizedBox(width: isTablet ? 12 : 8),
                item.trailing!,
              ] else if (item.value != null) ...[
                SizedBox(width: isTablet ? 12 : 8),
                Text(
                  item.value!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: isTablet ? 14 : 12,
                  ),
                ),
                SizedBox(width: isTablet ? 8 : 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: isTablet ? 16 : 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // Settings Data - البيانات المبسطة والمهمة فقط
  // ==========================================

  List<SettingsCategory> _getSettingsCategories() {
    final l10n = AppLocalizations.of(context)!;
    final appState = context.read<AppStateProvider>();

    return [
      // User Profile
      SettingsCategory(
        title: 'الملف الشخصي',
        subtitle: 'إدارة معلوماتك الشخصية',
        icon: Icons.person_outline,
        color: AppColors.primary,
        items: [
          SettingsItem(
            title: 'المعلومات الشخصية',
            icon: Icons.edit,
            onTap: () => _navigateToProfile(),
          ),
          SettingsItem(
            title: 'الأهداف الشخصية',
            icon: Icons.track_changes,
            onTap: () => _navigateToGoals(),
          ),
        ],
      ),

      // App Preferences - المفيدة فقط
      SettingsCategory(
        title: 'تفضيلات التطبيق',
        subtitle: 'تخصيص تجربة الاستخدام',
        icon: Icons.tune,
        color: AppColors.secondary,
        items: [
          SettingsItem(
            title: 'اللغة',
            icon: Icons.language,
            value: appState.state.currentLocale.languageCode == 'ar' ? 'العربية' : 'English',
            onTap: () => _showLanguageSelector(),
          ),
          SettingsItem(
            title: 'المظهر',
            icon: Icons.palette_outlined,
            value: _getThemeName(appState.state.currentTheme),
            onTap: () => _showThemeSelector(),
          ),
        ],
      ),

      // Tracking Settings
      SettingsCategory(
        title: 'إعدادات التتبع',
        subtitle: 'التحكم في تتبع البيانات',
        icon: Icons.track_changes,
        color: AppColors.info,
        items: [
          SettingsItem(
            title: 'تتبع النوم',
            icon: Icons.bedtime,
            onTap: () => _navigateToSleepSettings(),
          ),
          SettingsItem(
            title: 'تتبع النشاط',
            icon: Icons.directions_run,
            onTap: () => _navigateToActivitySettings(),
          ),
          SettingsItem(
            title: 'تتبع التغذية',
            icon: Icons.restaurant,
            onTap: () => _navigateToNutritionSettings(),
          ),
          SettingsItem(
            title: 'استخدام الهاتف',
            icon: Icons.phone_android,
            onTap: () => _navigateToPhoneSettings(),
          ),
        ],
      ),

      // Notifications - المهمة فقط
      SettingsCategory(
        title: 'الإشعارات',
        subtitle: 'إدارة التنبيهات والتذكيرات',
        icon: Icons.notifications,
        color: AppColors.warning,
        items: [
          SettingsItem(
            title: 'إشعارات النوم',
            icon: Icons.bedtime,
            trailing: _buildNotificationToggle('sleep'),
            onTap: () {},
          ),
          SettingsItem(
            title: 'تذكيرات النشاط',
            icon: Icons.directions_run,
            trailing: _buildNotificationToggle('activity'),
            onTap: () {},
          ),
          SettingsItem(
            title: 'تذكيرات التغذية',
            icon: Icons.restaurant,
            trailing: _buildNotificationToggle('nutrition'),
            onTap: () {},
          ),
        ],
      ),

      // Privacy & Security - الأساسية فقط
      SettingsCategory(
        title: 'الخصوصية والأمان',
        subtitle: 'حماية بياناتك الشخصية',
        icon: Icons.security,
        color: AppColors.error,
        items: [
          SettingsItem(
            title: 'سياسة الخصوصية',
            icon: Icons.policy_outlined,
            onTap: () => _openPrivacyPolicy(),
          ),
          SettingsItem(
            title: 'إعدادات الخصوصية',
            icon: Icons.privacy_tip_outlined,
            onTap: () => _navigateToPrivacy(),
          ),
          SettingsItem(
            title: 'أذونات التطبيق',
            icon: Icons.admin_panel_settings,
            onTap: () => _showPermissionsSettings(),
          ),
        ],
      ),

      // Data Management
      SettingsCategory(
        title: 'إدارة البيانات',
        subtitle: 'نسخ احتياطي ومزامنة',
        icon: Icons.cloud_outlined,
        color: AppColors.accent,
        items: [
          SettingsItem(
            title: 'النسخ الاحتياطي التلقائي',
            icon: Icons.backup,
            trailing: _buildBackupToggle(),
            onTap: () {},
          ),
          SettingsItem(
            title: 'تصدير البيانات',
            icon: Icons.file_download,
            onTap: () => _handleExportData(),
          ),
          SettingsItem(
            title: 'حذف جميع البيانات',
            icon: Icons.delete_forever,
            onTap: () => _showDeleteDataDialog(),
          ),
        ],
      ),

      // Support & About
      SettingsCategory(
        title: 'الدعم والمعلومات',
        subtitle: 'المساعدة ومعلومات التطبيق',
        icon: Icons.help_outline,
        color: AppColors.focus,
        items: [
          SettingsItem(
            title: 'المساعدة والدروس',
            icon: Icons.help_center,
            onTap: () => _navigateToHelp(),
          ),
          SettingsItem(
            title: 'إرسال ملاحظات',
            icon: Icons.feedback,
            onTap: () => _showFeedbackDialog(),
          ),
          SettingsItem(
            title: 'حول التطبيق',
            icon: Icons.info_outline,
            value: 'الإصدار 1.0.0',
            onTap: () => _showAboutDialog(),
          ),
        ],
      ),
    ];
  }

  List<SettingsCategory> _getFilteredCategories() {
    final categories = _getSettingsCategories();

    if (_searchQuery.isEmpty) {
      return categories;
    }

    return categories.where((category) {
      return category.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          category.items.any((item) =>
              item.title.toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();
  }

  // ==========================================
  // Widget Builders - البسيطة والمهمة
  // ==========================================

  Widget _buildNotificationToggle(String type) {
    return Switch(
      value: true, // يمكن ربطه بالـ Provider
      onChanged: (value) {
        // تحديث إعدادات الإشعارات
        setState(() {
          // تحديث الحالة
        });
      },
    );
  }

  Widget _buildBackupToggle() {
    return Switch(
      value: true, // يمكن ربطه بالـ Provider
      onChanged: (value) {
        // تحديث النسخ الاحتياطي
        setState(() {
          // تحديث الحالة
        });
      },
    );
  }

  // ==========================================
  // Helper Methods
  // ==========================================

  String _getThemeName(models.AppTheme theme) {
    switch (theme) {
      case models.AppTheme.light:
        return 'فاتح';
      case models.AppTheme.dark:
        return 'مظلم';
      case models.AppTheme.system:
        return 'النظام';
    }
  }

  // ==========================================
  // Navigation Methods
  // ==========================================

  void _navigateToProfile() {
    Navigator.of(context).pushNamed('/settings/profile');
  }

  void _navigateToGoals() {
    Navigator.of(context).pushNamed('/settings/goals');
  }

  void _navigateToSleepSettings() {
    // Navigation to sleep settings
  }

  void _navigateToActivitySettings() {
    // Navigation to activity settings
  }

  void _navigateToNutritionSettings() {
    // Navigation to nutrition settings
  }

  void _navigateToPhoneSettings() {
    // Navigation to phone settings
  }

  void _navigateToPrivacy() {
    Navigator.of(context).pushNamed('/settings/privacy');
  }

  void _navigateToHelp() {
    Navigator.of(context).pushNamed('/settings/support');
  }

  void _editProfile() {
    _navigateToProfile();
  }

  // ==========================================
  // Action Methods
  // ==========================================

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('البحث في الإعدادات'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'ابحث...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
            },
            child: const Text('مسح'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelector() {
    final appState = context.read<AppStateProvider>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'اختر اللغة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Text('🇸🇦'),
              title: const Text('العربية'),
              trailing: appState.state.currentLocale.languageCode == 'ar'
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                appState.changeLanguage(const Locale('ar', 'SA'));
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Text('🇺🇸'),
              title: const Text('English'),
              trailing: appState.state.currentLocale.languageCode == 'en'
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                appState.changeLanguage(const Locale('en', 'US'));
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeSelector() {
    final appState = context.read<AppStateProvider>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'اختر المظهر',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('المظهر الفاتح'),
              trailing: appState.state.currentTheme == models.AppTheme.light
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                appState.switchTheme(models.AppTheme.light);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('المظهر المظلم'),
              trailing: appState.state.currentTheme == models.AppTheme.dark
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                appState.switchTheme(models.AppTheme.dark);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_mode),
              title: const Text('مظهر النظام'),
              trailing: appState.state.currentTheme == models.AppTheme.system
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                appState.switchTheme(models.AppTheme.system);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPermissionsSettings() {
    Navigator.of(context).pushNamed('/permissions');
  }

  void _showDeleteDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ تحذير'),
        content: const Text(
          'هل أنت متأكد من حذف جميع البيانات؟ هذا الإجراء لا يمكن التراجع عنه.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleDeleteAllData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إرسال ملاحظات'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'اكتب ملاحظاتك هنا...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('تقييم التطبيق: '),
                Row(
                  children: List.generate(5, (index) =>
                      Icon(
                        Icons.star,
                        color: index < 4 ? AppColors.warning : Colors.grey,
                        size: 20,
                      ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Smart Psych',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 60,
        height: 60,
        child: const Icon(
          Icons.psychology,
          color: Colors.white,
          size: 30,
        ),
      ),
      children: [
        const Text('تطبيق ذكي لتتبع الصحة النفسية والجسدية'),
        const SizedBox(height: 16),
        const Text('المطور: Smart Health Team'),
        const Text('البريد الإلكتروني: support@smartpsych.app'),
      ],
    );
  }

  void _handleBackup() async {
    // عرض مؤشر التحميل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('جاري إنشاء النسخة الاحتياطية...'),
          ],
        ),
      ),
    );

    // محاكاة عملية النسخ الاحتياطي
    await Future.delayed(const Duration(seconds: 3));

    Navigator.of(context).pop(); // إغلاق مؤشر التحميل

    // عرض رسالة النجاح
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إنشاء النسخة الاحتياطية بنجاح'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _handleExportData() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصدير البيانات'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('اختر نوع البيانات المراد تصديرها:'),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('بيانات النوم'),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('بيانات النشاط'),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('بيانات التغذية'),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('استخدام الهاتف'),
              value: false,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performDataExport();
            },
            child: const Text('تصدير'),
          ),
        ],
      ),
    );
  }

  void _handleDeleteAllData() async {
    // عرض مؤشر التحميل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('جاري حذف البيانات...'),
          ],
        ),
      ),
    );

    // محاكاة عملية الحذف
    await Future.delayed(const Duration(seconds: 2));

    Navigator.of(context).pop(); // إغلاق مؤشر التحميل

    // عرض رسالة النجاح
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حذف جميع البيانات'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _performDataExport() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('جاري تصدير البيانات...'),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 3));

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تصدير البيانات بنجاح إلى مجلد التنزيلات'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _handleSync() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('جاري المزامنة...'),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تمت المزامنة بنجاح'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse('https://privacy.smartpsych.cloud/');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _handleHelp() {
    // فتح صفحة المساعدة
    _navigateToHelp();
  }

  // ═══════════════════════════════════════════════════════════
  // Account Section - تسجيل الدخول/الخروج
  // ═══════════════════════════════════════════════════════════

  Widget _buildAccountSection(BuildContext context, ThemeData theme, bool isTablet) {
    final isAuthenticated = ApiService.instance.isAuthenticated;

    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.fromLTRB(isTablet ? 24 : 16, 16, isTablet ? 24 : 16, 0),
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_circle_outlined, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'الحساب والمزامنة',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // عنوان السيرفر
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.dns_outlined, color: AppColors.info, size: 20),
              ),
              title: const Text('عنوان السيرفر', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text(
                ApiService.instance.baseUrl,
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_left, size: 20),
              onTap: _showServerSettingsDialog,
            ),

            const Divider(height: 1),

            // حالة الحساب
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isAuthenticated ? AppColors.success : AppColors.warning).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isAuthenticated ? Icons.check_circle_outline : Icons.warning_amber_outlined,
                  color: isAuthenticated ? AppColors.success : AppColors.warning,
                  size: 20,
                ),
              ),
              title: Text(
                isAuthenticated ? 'مسجّل دخول' : 'وضع الضيف',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                isAuthenticated
                    ? 'البيانات تُرفع للسيرفر تلقائياً'
                    : 'البيانات محفوظة محلياً فقط',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ),

            const SizedBox(height: 8),

            // زر الدخول/الخروج
            SizedBox(
              width: double.infinity,
              child: isAuthenticated
                  ? OutlinedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('تسجيل الخروج'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _handleLogin,
                      icon: const Icon(Icons.login, size: 18),
                      label: const Text('تسجيل الدخول'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
            ),

            // زر حذف الحساب (يظهر فقط عند التسجيل)
            if (isAuthenticated) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _handleDeleteAccount,
                  icon: Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                  label: Text('حذف الحساب', style: TextStyle(color: AppColors.error)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showServerSettingsDialog() async {
    final controller = TextEditingController(text: ApiService.instance.baseUrl);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.dns_outlined, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('عنوان السيرفر'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: 'http://192.168.1.100:3000/api',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.info),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'استخدم IP السيرفر إذا كنت على شبكة محلية',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                await ApiService.instance.setBaseUrl(url);
                if (mounted) {
                  Navigator.pop(ctx);
                  setState(() {}); // تحديث العرض
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم حفظ العنوان: $url'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟ ستُحفظ البيانات محلياً.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('خروج'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      // 1. إيقاف المزامنة التلقائية
      SyncService.instance.stopAutoSync();

      // 2. مسح التوكن من ApiService
      await ApiService.instance.logout();

      // 3. مسح علامة التخطي
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_skipped');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم تسجيل الخروج'),
          backgroundColor: AppColors.success,
        ),
      );

      // 4. الانتقال لشاشة الـ AuthGate
      Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _handleLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
  }

  Future<void> _handleDeleteAccount() async {
    // dialog تأكيد مزدوج لأنه إجراء حساس
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            const Text('حذف الحساب'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'هل أنت متأكد من حذف حسابك؟',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'إذا قمت بإنشاء حساب جديد بنفس البريد لاحقاً، ستعود بياناتك القديمة.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('نعم، احذف'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      // 1. إيقاف المزامنة التلقائية
      SyncService.instance.stopAutoSync();

      // 2. حذف الحساب من السيرفر (soft delete)
      final result = await ApiService.instance.deleteAccount();

      if (result['success'] == true) {
        // 3. مسح علامة التخطي
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_skipped');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم حذف الحساب'),
            backgroundColor: AppColors.success,
          ),
        );

        // 4. الانتقال لـ AuthGate
        Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'فشل الحذف'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
      );
    }
  }
}

// ==========================================
// Models - بسيطة ومباشرة
// ==========================================

class SettingsCategory {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final List<SettingsItem> items;

  const SettingsCategory({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.items,
  });
}

class SettingsItem {
  final String title;
  final IconData? icon;
  final String? value;
  final Widget? trailing;
  final VoidCallback onTap;

  const SettingsItem({
    required this.title,
    this.icon,
    this.value,
    this.trailing,
    required this.onTap,
  });
}

class QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}