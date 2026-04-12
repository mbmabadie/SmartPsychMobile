// lib/features/permissions/permissions_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

// Core
import '../../core/providers/app_state_provider.dart';

// Services

// Shared
import '../../core/utils/permission_utils.dart';
import '../../shared/localization/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/permission_card.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/enums/permission_enums.dart' as permission_enums;

// Utils

/// شاشة طلب الأذونات المطلوبة للتطبيق
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with TickerProviderStateMixin {

  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _progressController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;

  // State
  bool _isLoading = false;
  bool _isAllGranted = false;
  int _currentStep = 0;

  // Permission States - استخدام PermissionState من الملف المشترك
  final Map<String, permission_enums.PermissionState> _permissionStates = {
    'notifications': permission_enums.PermissionState.pending,
    'sensors': permission_enums.PermissionState.pending,
    'activity': permission_enums.PermissionState.pending,
    'location': permission_enums.PermissionState.pending,
    'battery': permission_enums.PermissionState.pending,
    'alarms': permission_enums.PermissionState.pending,
  };

  // Permission Data - استخدام PermissionData من الملف المشترك
  final List<permission_enums.PermissionData> _permissions = [
    permission_enums.PermissionData(
      key: 'notifications',
      permission: Permission.notification,
      icon: Icons.notifications_active,
      titleKey: 'notifications_permission_title',
      descriptionKey: 'notifications_permission_description',
      isEssential: true,
    ),
    permission_enums.PermissionData(
      key: 'sensors',
      permission: Permission.sensors,
      icon: Icons.sensors,
      titleKey: 'sensors_permission_title',
      descriptionKey: 'sensors_permission_description',
      isEssential: true,
    ),
    permission_enums.PermissionData(
      key: 'activity',
      permission: Permission.activityRecognition,
      icon: Icons.directions_run,
      titleKey: 'activity_permission_title',
      descriptionKey: 'activity_permission_description',
      isEssential: true,
    ),
    permission_enums.PermissionData(
      key: 'location',
      permission: Permission.locationWhenInUse,
      icon: Icons.location_on,
      titleKey: 'location_permission_title',
      descriptionKey: 'location_permission_description',
      isEssential: false,
    ),
    permission_enums.PermissionData(
      key: 'battery',
      permission: Permission.ignoreBatteryOptimizations,
      icon: Icons.battery_charging_full,
      titleKey: 'battery_permission_title',
      descriptionKey: 'battery_permission_description',
      isEssential: false,
    ),
    permission_enums.PermissionData(
      key: 'alarms',
      permission: Permission.scheduleExactAlarm,
      icon: Icons.alarm,
      titleKey: 'alarms_permission_title',
      descriptionKey: 'alarms_permission_description',
      isEssential: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _checkInitialPermissions();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  /// تهيئة الرسوم المتحركة
  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    // بدء الرسوم المتحركة
    _fadeController.forward();
    _slideController.forward();
  }

  /// فحص الأذونات الأولية
  Future<void> _checkInitialPermissions() async {
    try {
      for (final permission in _permissions) {
        final status = await permission.permission.status;
        _permissionStates[permission.key] = _mapStatus(status);
      }

      if (mounted) {
        setState(() {});
        _updateProgress();
      }
    } catch (e) {
      debugPrint('❌ خطأ في فحص الأذونات الأولية: $e');
    }
  }

  /// تحديث شريط التقدم
  void _updateProgress() {
    final grantedCount = _permissionStates.values
        .where((state) => state == permission_enums.PermissionState.granted)
        .length;

    final progress = grantedCount / _permissions.length;
    _progressController.animateTo(progress);

    // فحص إذا تم منح جميع الأذونات الأساسية
    final essentialPermissions = _permissions
        .where((p) => p.isEssential)
        .toList();

    final essentialGranted = essentialPermissions
        .every((p) => _permissionStates[p.key] == permission_enums.PermissionState.granted);

    _isAllGranted = essentialGranted;
  }

  /// تحويل PermissionStatus إلى PermissionState
  permission_enums.PermissionState _mapStatus(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return permission_enums.PermissionState.granted;
      case PermissionStatus.denied:
        return permission_enums.PermissionState.denied;
      case PermissionStatus.permanentlyDenied:
        return permission_enums.PermissionState.permanentlyDenied;
      case PermissionStatus.restricted:
        return permission_enums.PermissionState.restricted;
      case PermissionStatus.limited:
        return permission_enums.PermissionState.limited;
      case PermissionStatus.provisional:
        return permission_enums.PermissionState.provisional;
    }
  }

  /// طلب إذن واحد
  Future<void> _requestPermission(permission_enums.PermissionData permissionData) async {
    if (_isLoading) return;

    try {
      setState(() {
        _isLoading = true;
        _permissionStates[permissionData.key] = permission_enums.PermissionState.requesting;
      });

      // إضافة تأخير بصري
      await Future.delayed(const Duration(milliseconds: 500));

      // طلب الإذن
      /*final status = await PermissionUtils.requestSinglePermissionWithRetry(
        permissionData.permission,
        maxRetries: 2,
      );

      // تحديث الحالة
      _permissionStates[permissionData.key] = _mapStatus(status);
*/
      // تحديث التقدم
      _updateProgress();

      // تأثير هزة للنجاح/الفشل
     /* if (status.isGranted) {
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.mediumImpact();
      }*/

    } catch (e) {
      debugPrint('❌ خطأ في طلب الإذن ${permissionData.key}: $e');
      _permissionStates[permissionData.key] = permission_enums.PermissionState.denied;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// طلب جميع الأذونات
  Future<void> _requestAllPermissions() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // طلب الأذونات بشكل تدريجي
      for (int i = 0; i < _permissions.length; i++) {
        final permission = _permissions[i];

        // تخطي الأذونات الممنوحة بالفعل
        if (_permissionStates[permission.key] == permission_enums.PermissionState.granted) {
          continue;
        }

        setState(() {
          _currentStep = i;
        });

        await _requestPermission(permission);

        // تأخير بين الطلبات
        if (i < _permissions.length - 1) {
          await Future.delayed(const Duration(milliseconds: 800));
        }
      }

      // فحص النتيجة النهائية
      await _checkFinalResult();

    } catch (e) {
      debugPrint('❌ خطأ في طلب جميع الأذونات: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _currentStep = 0;
      });
    }
  }

  /// فحص النتيجة النهائية
  Future<void> _checkFinalResult() async {
    final essentialPermissions = _permissions
        .where((p) => p.isEssential)
        .toList();

    final essentialGranted = essentialPermissions
        .every((p) => _permissionStates[p.key] == permission_enums.PermissionState.granted);

    if (essentialGranted) {
      // نجح في الحصول على الأذونات الأساسية
      await _handleSuccess();
    } else {
      // فشل في الحصول على الأذونات الأساسية
      await _handleFailure();
    }
  }

  /// معالجة النجاح
  Future<void> _handleSuccess() async {
    // تأثير نجاح
    HapticFeedback.heavyImpact();

    // تحديث حالة التطبيق
    final appState = context.read<AppStateProvider>();
    await appState.completePermissions();

    // انتظار قصير للتأثير البصري
    await Future.delayed(const Duration(milliseconds: 1500));

    // الانتقال للشاشة الرئيسية
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/home',
            (route) => false,
      );
    }
  }

  /// معالجة الفشل
  Future<void> _handleFailure() async {
    // عرض رسالة تحذيرية
    _showPermissionRequiredDialog();
  }

  /// عرض حوار الأذونات المطلوبة
  void _showPermissionRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.permissionsRequired,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          AppLocalizations.of(context)!.permissionsRequiredMessage,
          style: TextStyle(
            color: Colors.grey[600],
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              SystemNavigator.pop(); // إغلاق التطبيق
            },
            child: Text(AppLocalizations.of(context)!.exit),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings(); // فتح إعدادات التطبيق
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(AppLocalizations.of(context)!.openSettings),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Header
                    _buildHeader(l10n!, theme),

                    const SizedBox(height: 32),

                    // Progress Indicator
                    _buildProgressIndicator(theme),

                    const SizedBox(height: 32),

                    // Permissions List
                    Expanded(
                      child: _buildPermissionsList(l10n, theme),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    _buildActionButtons(l10n, theme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// بناء رأس الشاشة
  Widget _buildHeader(AppLocalizations l10n, ThemeData theme) {
    return Column(
      children: [
        // Logo/Animation
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(60),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: Icon(
            Icons.security,
            size: 60,
            color: AppColors.primary,
          ),
        ),

        const SizedBox(height: 24),

        // Title
        Text(
          l10n.permissionsTitle,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12),

        // Subtitle
        Text(
          l10n.permissionsSubtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// بناء مؤشر التقدم
  Widget _buildProgressIndicator(ThemeData theme) {
    return Column(
      children: [
        // Progress Bar
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progressAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // Progress Text
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            final grantedCount = (_progressAnimation.value * _permissions.length).round();
            return Text(
              '$grantedCount/${_permissions.length} ${AppLocalizations.of(context)!.permissionsGranted}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            );
          },
        ),
      ],
    );
  }

  /// بناء قائمة الأذونات
  Widget _buildPermissionsList(AppLocalizations l10n, ThemeData theme) {
    return ListView.separated(
      itemCount: _permissions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final permission = _permissions[index];
        final state = _permissionStates[permission.key]!;
        final isCurrentStep = _isLoading && _currentStep == index;

        return PermissionCard(
          icon: permission.icon,
          title: _getPermissionTitle(l10n, permission.titleKey),
          description: _getPermissionDescription(l10n, permission.descriptionKey),
          state: state,
          isEssential: permission.isEssential,
          isCurrentStep: isCurrentStep,
          onTap: () => _requestPermission(permission),
        );
      },
    );
  }

  /// بناء أزرار الإجراءات
  Widget _buildActionButtons(AppLocalizations l10n, ThemeData theme) {
    return Column(
      children: [
        // Request All Button
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            text: l10n.requestAllPermissions,
            onPressed: _isLoading ? null : _requestAllPermissions,
            isLoading: _isLoading,
            icon: Icons.security,
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Continue Button (if essential permissions granted)
        if (_isAllGranted) ...[
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: l10n.continueToApp,
              onPressed: () => _handleSuccess(),
              style: CustomButtonStyle.outline,
              icon: Icons.arrow_forward,
            ),
          ),
        ],

        const SizedBox(height: 12),

        // Skip Button (for non-essential permissions)
        TextButton(
          onPressed: _isAllGranted ? () => _handleSuccess() : null,
          child: Text(
            l10n.skipOptionalPermissions,
            style: TextStyle(
              color: _isAllGranted ? AppColors.primary : Colors.grey[400],
            ),
          ),
        ),
      ],
    );
  }

  /// الحصول على عنوان الإذن
  String _getPermissionTitle(AppLocalizations l10n, String key) {
    switch (key) {
      case 'notifications_permission_title':
        return l10n.notificationsPermissionTitle;
      case 'sensors_permission_title':
        return l10n.sensorsPermissionTitle;
      case 'activity_permission_title':
        return l10n.activityPermissionTitle;
      case 'location_permission_title':
        return l10n.locationPermissionTitle;
      case 'battery_permission_title':
        return l10n.batteryPermissionTitle;
      case 'alarms_permission_title':
        return l10n.alarmsPermissionTitle;
      default:
        return key;
    }
  }

  /// الحصول على وصف الإذن
  String _getPermissionDescription(AppLocalizations l10n, String key) {
    switch (key) {
      case 'notifications_permission_description':
        return l10n.notificationsPermissionDescription;
      case 'sensors_permission_description':
        return l10n.sensorsPermissionDescription;
      case 'activity_permission_description':
        return l10n.activityPermissionDescription;
      case 'location_permission_description':
        return l10n.locationPermissionDescription;
      case 'battery_permission_description':
        return l10n.batteryPermissionDescription;
      case 'alarms_permission_description':
        return l10n.alarmsPermissionDescription;
      default:
        return key;
    }
  }
}