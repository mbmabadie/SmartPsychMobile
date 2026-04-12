// lib/main.dart - ✅ النسخة الكاملة المدمجة: WorkManager + MIUI Dialog
import 'dart:async';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_psych/core/providers/location_provider.dart';
import 'package:smart_psych/core/utils/permission_utils.dart';
import 'package:smart_psych/features/dashboard/views/dashboard_screen.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'core/constants/strings.dart';
import 'core/providers/app_state_provider.dart';
import 'core/providers/base/base_state.dart';
import 'core/providers/insights_provider.dart';
import 'core/providers/sleep_tracking_provider.dart';
import 'core/providers/phone_usage_provider.dart';
import 'core/providers/activity_tracking_provider.dart';
import 'core/providers/statistics_provider.dart';
import 'core/providers/unified_health_hub.dart';
import 'core/providers/assessment_provider.dart';
import 'core/services/notification_service.dart';
import 'core/services/unified_tracking_service.dart';
import 'core/services/background_service.dart';
import 'core/services/api_service.dart';
import 'core/services/sync_service.dart';

import 'features/sleep/screens/sleep_confirmation_screen.dart';
import 'features/permissions/accessibility_disclosure_screen.dart';
import 'features/auth/views/auth_screen.dart';
import 'features/settings/settings_screen.dart';
import 'shared/providers/theme_provider.dart';
import 'shared/providers/localization_provider.dart';
import 'shared/localization/app_localizations.dart';
import 'shared/theme/app_theme.dart';
import 'shared/theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    debugPrint('🚀 بدء تهيئة التطبيق...');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_app_open', DateTime.now().millisecondsSinceEpoch);
    debugPrint('📝 تم تسجيل آخر فتح للتطبيق');

    tz.initializeTimeZones();
    debugPrint('🕒 تم تهيئة التوقيت المحلي');

    debugPrint('📱 بدء تهيئة خدمة الإشعارات...');
    final notificationService = NotificationService.instance;
    final notificationInitialized = await notificationService.initialize();
    debugPrint('📱 خدمة الإشعارات: ${notificationInitialized ? 'تم' : 'فشل'}');

    // ═══════════════════════════════════════════════════════════
    // ✅ تهيئة Sync System
    // ═══════════════════════════════════════════════════════════
    try {
      debugPrint('🔄 بدء تهيئة نظام المزامنة...');

      // تهيئة API Service
      await ApiService.instance.initialize();
      debugPrint('✅ API Service initialized');

      // إذا المستخدم مسجل دخول، ابدأ المزامنة التلقائية
      if (ApiService.instance.isAuthenticated) {
        debugPrint('👤 المستخدم مسجل دخول - بدء المزامنة...');

        // بدء المزامنة التلقائية (كل 5 دقائق)
        SyncService.instance.startAutoSync();

        // مزامنة فورية عند فتح التطبيق
        final result = await SyncService.instance.syncAll();
        debugPrint('📤 نتيجة المزامنة: ${result['message']}');
        debugPrint('📊 عدد السجلات المرفوعة: ${result['total_synced']}');
      } else {
        debugPrint('ℹ️ المستخدم غير مسجل دخول - المزامنة معطلة');
      }

    } catch (e) {
      debugPrint('⚠️ تحذير: فشل تهيئة نظام المزامنة: $e');
      debugPrint('ℹ️ التطبيق سيعمل في وضع offline فقط');
    }


    // ✅ WorkManager يتم تهيئته من BackgroundService.initialize()
    // لتجنب التكرار - لا حاجة لتهيئته هنا

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    debugPrint('📱 تم تحديد اتجاه الشاشة');

    debugPrint('✅ تم الانتهاء من تهيئة التطبيق بنجاح');

  } catch (e, stackTrace) {
    debugPrint('❌ خطأ في تهيئة التطبيق: $e');
    debugPrint('📍 Stack trace: $stackTrace');
  }

  runApp(const SmartPsychApp());
}

// ═══════════════════════════════════════════════════════════════
// SmartPsychApp - تطبيق Flutter الرئيسي
// ═══════════════════════════════════════════════════════════════

class SmartPsychApp extends StatelessWidget {
  const SmartPsychApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ════════════════════════════════════════════════════════════════
        // المزودات الأساسية (الترتيب 0)
        // ════════════════════════════════════════════════════════════════
        ChangeNotifierProvider(
          create: (_) {
            debugPrint('🎨 إنشاء ThemeProvider');
            return ThemeProvider()..initialize();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            debugPrint('🌐 إنشاء LocalizationProvider');
            return LocalizationProvider()..initialize();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            debugPrint('⚙️ إنشاء AppStateProvider');
            return AppStateProvider();
          },
        ),

        // ════════════════════════════════════════════════════════════════
        // المزودات المستقلة (الترتيب 1)
        // ════════════════════════════════════════════════════════════════

        ChangeNotifierProvider(
          create: (_) {
            debugPrint('🏃 إنشاء ActivityTrackingProvider');
            return ActivityTrackingProvider();
          },
        ),

        ChangeNotifierProvider(
          create: (_) {
            debugPrint('📱 إنشاء PhoneUsageProvider');
            return PhoneUsageProvider();
          },
        ),

        ChangeNotifierProvider(
          create: (_) {
            debugPrint('😴 إنشاء SleepTrackingProvider');
            final sleepProvider = SleepTrackingProvider();

            sleepProvider.initializeAutoTracking().then((_) {
              debugPrint('   ✅ تم تشغيل التتبع التلقائي للنوم');
            }).catchError((error) {
              debugPrint('   ❌ خطأ في تشغيل التتبع: $error');
            });

            return sleepProvider;
          },
        ),

        ChangeNotifierProvider(
          create: (_) {
            debugPrint('📍 إنشاء LocationProvider');
            return LocationProvider();
          },
        ),

        // ════════════════════════════════════════════════════════════════
        // المزودات مع التبعيات (الترتيب 2)
        // ════════════════════════════════════════════════════════════════

        ChangeNotifierProvider(
          create: (context) {
            debugPrint('📊 إنشاء StatisticsProvider');
            return StatisticsProvider(
              activityProvider: context.read<ActivityTrackingProvider>(),
              phoneUsageProvider: context.read<PhoneUsageProvider>(),
              sleepProvider: context.read<SleepTrackingProvider>(),
            );
          },
        ),

        ChangeNotifierProvider(
          create: (context) {
            debugPrint('💡 إنشاء InsightsTrackingProvider');
            return InsightsTrackingProvider();
          },
        ),

        ChangeNotifierProvider(
          create: (_) {
            debugPrint('📝 إنشاء AssessmentProvider');
            return AssessmentProvider();
          },
        ),

        // ════════════════════════════════════════════════════════════════
        // UnifiedHealthHub - المركز الموحد (الترتيب 3)
        // ════════════════════════════════════════════════════════════════

        ChangeNotifierProvider(
          create: (context) {
            debugPrint('🌟 إنشاء UnifiedHealthHubProvider');
            return UnifiedHealthHubProvider(
              phoneProvider: context.read<PhoneUsageProvider>(),
              sleepProvider: context.read<SleepTrackingProvider>(),
              activityProvider: context.read<ActivityTrackingProvider>(),
              insightsProvider: context.read<InsightsTrackingProvider>(),
              notificationProvider: null,
            );
          },
        ),
      ],
      child: Consumer2<ThemeProvider, LocalizationProvider>(
        builder: (context, themeProvider, localizationProvider, child) {
          return _buildWithScreenUtil(
            MaterialApp(
              title: AppStrings.appName,
              debugShowCheckedModeBanner: false,
              theme: _buildTheme(themeProvider.isDarkMode),
              locale: localizationProvider.locale,
              supportedLocales: const [
                Locale('ar', 'SA'),
                Locale('en', 'US'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const DirectPermissionsScreen(),
              routes: {
                '/main': (context) => const AuthGate(),
                '/home': (context) => const DashboardScreen(),
                '/settings': (context) => const SettingsScreen(),
                '/sleep-confirmation': (context) => const SleepConfirmationScreen(),
              },
            ),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(bool isDarkMode) {
    return ThemeData(
      useMaterial3: true,
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
      ),
      fontFamily: 'NotoSansArabic',
      appBarTheme: AppBarTheme(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDarkMode ? Brightness.dark : Brightness.light,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildWithScreenUtil(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (context, _) => child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DirectPermissionsScreen - شاشة الأذونات
// ═══════════════════════════════════════════════════════════════

class DirectPermissionsScreen extends StatefulWidget {
  const DirectPermissionsScreen({Key? key}) : super(key: key);

  @override
  State<DirectPermissionsScreen> createState() => _DirectPermissionsScreenState();
}

class _DirectPermissionsScreenState extends State<DirectPermissionsScreen> {
  bool _isLoading = true;
  bool _permissionsGranted = false;
  bool _isRequesting = false;
  String _currentStep = 'فحص النظام...';
  Map<String, bool> _permissionsStatus = {};
  bool _isSamsungDevice = false;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    try {
      setState(() => _currentStep = 'فحص نوع الجهاز...');
      await Future.delayed(const Duration(milliseconds: 500));

      try {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        _isSamsungDevice = androidInfo.manufacturer.toLowerCase().contains('samsung');
        debugPrint('📱 نوع الجهاز: ${_isSamsungDevice ? 'Samsung' : 'عادي'}');
      } catch (e) {
        _isSamsungDevice = false;
      }

      setState(() => _currentStep = 'فحص الأذونات الحالية...');
      await Future.delayed(const Duration(milliseconds: 500));

      _permissionsStatus = await _recheckAllPermissions();
      _permissionsGranted = _checkEssentialPermissions();

      if (_permissionsGranted) {
        setState(() => _currentStep = 'جميع الأذونات ممنوحة ✅');

        // تشغيل كل الخدمات الخلفية
        await _startAllBackgroundServices();

        await Future.delayed(const Duration(seconds: 1));
        _navigateToMain();
        return;
      }

      setState(() {
        _isLoading = false;
        _currentStep = 'جاهز لطلب الأذونات';
      });

    } catch (e) {
      debugPrint('❌ خطأ في فحص الحالة: $e');
      setState(() {
        _isLoading = false;
        _currentStep = 'خطأ في فحص النظام';
      });
    }
  }

  Future<void> _startAllBackgroundServices() async {
    try {
      debugPrint('🎯 بدء جميع الخدمات الخلفية...');

      // 1. UnifiedTrackingService
      final unifiedService = UnifiedTrackingService.instance;
      if (!unifiedService.isInitialized) {
        await unifiedService.initialize();
      }
      if (!unifiedService.isTracking) {
        await unifiedService.startTracking();
      }
      debugPrint('✅ UnifiedService نشط');

      // 2. BackgroundService
      final backgroundService = BackgroundService.instance;
      final bgInitialized = await backgroundService.initialize();
      if (bgInitialized) {
        await backgroundService.start();
        debugPrint('✅ BackgroundService نشط');
      }

      debugPrint('🎉 جميع الخدمات الخلفية نشطة الآن!');

    } catch (e, stack) {
      debugPrint('❌ خطأ في تشغيل الخدمات الخلفية: $e');
      debugPrint('Stack: $stack');
    }
  }

  Future<void> _requestPermissionsDirectly() async {
    if (_isRequesting) return;

    setState(() {
      _isRequesting = true;
      _currentStep = 'جاري طلب الأذونات...';
    });

    try {
      // ✅ Prominent Disclosure قبل طلب Accessibility (مطلوب Google Play)
      final shouldShowDisclosure = await AccessibilityDisclosureScreen.shouldShowDisclosure();
      if (shouldShowDisclosure && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AccessibilityDisclosureScreen(
              onAccept: () => Navigator.of(context).pop(),
              onDecline: () => Navigator.of(context).pop(),
            ),
          ),
        );
      }

      // ✅ طلب الأذونات مع MIUI Dialog support
      await PermissionUtils.requestAllEssentialPermissions(
        context,
        requestUsageAccess: false,
        showMiuiDialog: true, // ✅ NEW: دعم MIUI Dialog
      );

      setState(() => _currentStep = 'جاري إعادة فحص الأذونات...');
      await Future.delayed(const Duration(milliseconds: 1000));

      _permissionsStatus = await _recheckAllPermissions();
      _permissionsGranted = _checkEssentialPermissions();

      if (_permissionsGranted) {
        setState(() => _currentStep = 'تم منح الأذونات بنجاح! ✅');

        // تشغيل الخدمات بعد الأذونات
        await _startAllBackgroundServices();

        await Future.delayed(const Duration(seconds: 1));
        _navigateToMain();
      } else {
        setState(() => _currentStep = 'بعض الأذونات لم يتم منحها');
      }
    } catch (e) {
      debugPrint('❌ خطأ في طلب الأذونات: $e');
      setState(() => _currentStep = 'حدث خطأ أثناء طلب الأذونات');
    } finally {
      setState(() => _isRequesting = false);
    }
  }

  Future<Map<String, bool>> _recheckAllPermissions() async {
    Map<String, bool> status = {};
    try {
      status['الإشعارات'] = (await Permission.notification.status).isGranted;
      status['الحساسات'] = (await Permission.sensors.status).isGranted;
      status['مراقبة النشاط'] = (await Permission.activityRecognition.status).isGranted;
      return status;
    } catch (e) {
      debugPrint('❌ خطأ في إعادة فحص الأذونات: $e');
      return {};
    }
  }

  bool _checkEssentialPermissions() {
    final essential = ['الإشعارات', 'الحساسات', 'مراقبة النشاط'];
    for (String permission in essential) {
      if (_permissionsStatus[permission] != true) {
        return false;
      }
    }
    return true;
  }

  void _navigateToMain() {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/main');
    }
  }

  void _skipPermissions() {
    _navigateToMain();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.bedtime,
                  size: 80,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Smart Psych',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 48),
              if (_isLoading) ...[
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                const SizedBox(height: 24),
                Text(_currentStep),
              ] else ...[
                if (!_permissionsGranted) ...[
                  Text(
                    'أذونات التطبيق',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 32),
                  if (_isRequesting)
                    CircularProgressIndicator()
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _skipPermissions,
                            child: const Text('تخطي'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _requestPermissionsDirectly,
                            child: const Text('منح الأذونات'),
                          ),
                        ),
                      ],
                    ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// AuthGate - بوابة المصادقة
// ═══════════════════════════════════════════════════════════════

class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checking = true;
  bool _authenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final skipped = prefs.getBool('auth_skipped') ?? false;
      final api = ApiService.instance;

      if (api.isAuthenticated || skipped) {
        // المستخدم مسجل دخوله أو تخطى التسجيل سابقاً
        if (api.isAuthenticated) {
          // بدء المزامنة التلقائية
          SyncService.instance.startAutoSync();
          // مزامنة فورية
          SyncService.instance.syncAll();
          // جلب الاختبار النشط
          SyncService.instance.fetchAndCacheActiveAssessment();
        }

        if (mounted) {
          setState(() {
            _authenticated = true;
            _checking = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _checking = false);
        }
      }
    } catch (e) {
      debugPrint('❌ خطأ في فحص المصادقة: $e');
      if (mounted) setState(() => _checking = false);
    }
  }

  void _onAuthSuccess() async {
    final prefs = await SharedPreferences.getInstance();

    // إذا المستخدم مسجل فعلاً → بدء المزامنة
    if (ApiService.instance.isAuthenticated) {
      SyncService.instance.startAutoSync();
      SyncService.instance.syncAll();
      SyncService.instance.fetchAndCacheActiveAssessment();
    } else {
      // تخطي → حفظ العلامة
      await prefs.setBool('auth_skipped', true);
    }

    if (mounted) {
      setState(() => _authenticated = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text('جاري التحقق...', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    if (_authenticated) {
      return const DashboardScreen();
    }

    return AuthScreen(onAuthSuccess: _onAuthSuccess);
  }
}

// ═══════════════════════════════════════════════════════════════
// Extensions
// ═══════════════════════════════════════════════════════════════

extension SafeInitialization on AppStateProvider {
  Future<void> initializeAppSafely() async {
    try {
      await Future.any([
        initializeApp(),
        Future.delayed(const Duration(seconds: 25), () {
          throw TimeoutException('انتهت مهلة التهيئة');
        }),
      ]);
    } catch (error) {
      setState(state.copyWith(
        appError: AppStateError(
          message: 'فشل في التهيئة: $error',
          code: 'initialization_failed',
        ),
        loadingState: LoadingState.error,
      ));
    }
  }
}