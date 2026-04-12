// lib/shared/localization/app_localizations.dart
import 'package:flutter/material.dart';

/// App Localizations - نظام الترجمة
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  /// الحصول على نسخة الترجمة الحالية
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  /// معرف اللغة
  String get languageCode => locale.languageCode;

  /// فحص إذا كانت اللغة عربية
  bool get isArabic => languageCode == 'ar';

  /// فحص إذا كانت اللغة إنجليزية
  bool get isEnglish => languageCode == 'en';

  /// اتجاه النص
  TextDirection get textDirection => isArabic ? TextDirection.rtl : TextDirection.ltr;

  // ==========================================
  // App General - عام التطبيق
  // ==========================================

  String get appName => _getText(
    ar: 'Smart Psych',
    en: 'Smart Psych',
  );

  String get appDescription => _getText(
    ar: 'تطبيق ذكي لتتبع الصحة النفسية والجسدية',
    en: 'Smart app for tracking mental and physical health',
  );

  // ==========================================
  // Navigation - التنقل
  // ==========================================

  String get home => _getText(ar: 'الرئيسية', en: 'Home');
  String get sleep => _getText(ar: 'النوم', en: 'Sleep');
  String get activity => _getText(ar: 'النشاط', en: 'Activity');
  String get nutrition => _getText(ar: 'التغذية', en: 'Nutrition');
  String get statistics => _getText(ar: 'الإحصائيات', en: 'Statistics');
  String get settings => _getText(ar: 'الإعدادات', en: 'Settings');
  String get more => _getText(ar: 'المزيد', en: 'More');

  // ==========================================
  // Common Actions - الإجراءات الشائعة
  // ==========================================

  String get save => _getText(ar: 'حفظ', en: 'Save');
  String get cancel => _getText(ar: 'إلغاء', en: 'Cancel');
  String get delete => _getText(ar: 'حذف', en: 'Delete');
  String get edit => _getText(ar: 'تعديل', en: 'Edit');
  String get add => _getText(ar: 'إضافة', en: 'Add');
  String get update => _getText(ar: 'تحديث', en: 'Update');
  String get refresh => _getText(ar: 'تحديث', en: 'Refresh');
  String get retry => _getText(ar: 'إعادة المحاولة', en: 'Retry');
  String get confirm => _getText(ar: 'تأكيد', en: 'Confirm');
  String get close => _getText(ar: 'إغلاق', en: 'Close');
  String get next => _getText(ar: 'التالي', en: 'Next');
  String get previous => _getText(ar: 'السابق', en: 'Previous');
  String get done => _getText(ar: 'تم', en: 'Done');
  String get skip => _getText(ar: 'تخطي', en: 'Skip');
  String get start => _getText(ar: 'بدء', en: 'Start');
  String get stop => _getText(ar: 'إيقاف', en: 'Stop');
  String get pause => _getText(ar: 'إيقاف مؤقت', en: 'Pause');
  String get resume => _getText(ar: 'استئناف', en: 'Resume');

  // ==========================================
  // Time and Dates - الوقت والتواريخ
  // ==========================================

  String get today => _getText(ar: 'اليوم', en: 'Today');
  String get yesterday => _getText(ar: 'أمس', en: 'Yesterday');
  String get tomorrow => _getText(ar: 'غداً', en: 'Tomorrow');
  String get thisWeek => _getText(ar: 'هذا الأسبوع', en: 'This Week');
  String get thisMonth => _getText(ar: 'هذا الشهر', en: 'This Month');
  String get thisYear => _getText(ar: 'هذه السنة', en: 'This Year');

  // Days of week
  String get monday => _getText(ar: 'الاثنين', en: 'Monday');
  String get tuesday => _getText(ar: 'الثلاثاء', en: 'Tuesday');
  String get wednesday => _getText(ar: 'الأربعاء', en: 'Wednesday');
  String get thursday => _getText(ar: 'الخميس', en: 'Thursday');
  String get friday => _getText(ar: 'الجمعة', en: 'Friday');
  String get saturday => _getText(ar: 'السبت', en: 'Saturday');
  String get sunday => _getText(ar: 'الأحد', en: 'Sunday');

  // Months
  String get january => _getText(ar: 'يناير', en: 'January');
  String get february => _getText(ar: 'فبراير', en: 'February');
  String get march => _getText(ar: 'مارس', en: 'March');
  String get april => _getText(ar: 'أبريل', en: 'April');
  String get may => _getText(ar: 'مايو', en: 'May');
  String get june => _getText(ar: 'يونيو', en: 'June');
  String get july => _getText(ar: 'يوليو', en: 'July');
  String get august => _getText(ar: 'أغسطس', en: 'August');
  String get september => _getText(ar: 'سبتمبر', en: 'September');
  String get october => _getText(ar: 'أكتوبر', en: 'October');
  String get november => _getText(ar: 'نوفمبر', en: 'November');
  String get december => _getText(ar: 'ديسمبر', en: 'December');

  // ==========================================
  // Sleep Tracking - تتبع النوم
  // ==========================================

  String get sleepTracking => _getText(ar: 'تتبع النوم', en: 'Sleep Tracking');
  String get sleepQuality => _getText(ar: 'جودة النوم', en: 'Sleep Quality');
  String get sleepDuration => _getText(ar: 'مدة النوم', en: 'Sleep Duration');
  String get bedtime => _getText(ar: 'وقت النوم', en: 'Bedtime');
  String get wakeupTime => _getText(ar: 'وقت الاستيقاظ', en: 'Wake up Time');
  String get sleepSession => _getText(ar: 'جلسة النوم', en: 'Sleep Session');
  String get deepSleep => _getText(ar: 'النوم العميق', en: 'Deep Sleep');
  String get lightSleep => _getText(ar: 'النوم الخفيف', en: 'Light Sleep');
  String get remSleep => _getText(ar: 'نوم الأحلام', en: 'REM Sleep');
  String get awake => _getText(ar: 'مستيقظ', en: 'Awake');
  String get sleeping => _getText(ar: 'نائم', en: 'Sleeping');

  String get sleepGoal => _getText(ar: 'هدف النوم', en: 'Sleep Goal');
  String get averageSleep => _getText(ar: 'متوسط النوم', en: 'Average Sleep');
  String get bestSleep => _getText(ar: 'أفضل نوم', en: 'Best Sleep');
  String get worstSleep => _getText(ar: 'أسوأ نوم', en: 'Worst Sleep');

  // ==========================================
  // Phone Usage - استخدام الهاتف
  // ==========================================

  String get phoneUsage => _getText(ar: 'استخدام الهاتف', en: 'Phone Usage');
  String get screenTime => _getText(ar: 'وقت الشاشة', en: 'Screen Time');
  String get pickups => _getText(ar: 'مرات الفتح', en: 'Pickups');
  String get digitalWellness => _getText(ar: 'العافية الرقمية', en: 'Digital Wellness');
  String get appUsage => _getText(ar: 'استخدام التطبيقات', en: 'App Usage');
  String get nightUsage => _getText(ar: 'الاستخدام الليلي', en: 'Night Usage');
  String get breakReminder => _getText(ar: 'تذكير الاستراحة', en: 'Break Reminder');
  String get digitalDetox => _getText(ar: 'التخلص الرقمي', en: 'Digital Detox');

  String get totalScreenTime => _getText(ar: 'إجمالي وقت الشاشة', en: 'Total Screen Time');
  String get averageScreenTime => _getText(ar: 'متوسط وقت الشاشة', en: 'Average Screen Time');
  String get mostUsedApp => _getText(ar: 'أكثر تطبيق استخداماً', en: 'Most Used App');

  // ==========================================
  // Activity Tracking - تتبع النشاط
  // ==========================================

  String get activityTracking => _getText(ar: 'تتبع النشاط', en: 'Activity Tracking');
  String get steps => _getText(ar: 'الخطوات', en: 'Steps');
  String get distance => _getText(ar: 'المسافة', en: 'Distance');
  String get calories => _getText(ar: 'السعرات', en: 'Calories');
  String get activeMinutes => _getText(ar: 'الدقائق النشطة', en: 'Active Minutes');
  String get floors => _getText(ar: 'الطوابق', en: 'Floors');
  String get heartRate => _getText(ar: 'معدل القلب', en: 'Heart Rate');

  String get walking => _getText(ar: 'المشي', en: 'Walking');
  String get running => _getText(ar: 'الجري', en: 'Running');
  String get cycling => _getText(ar: 'ركوب الدراجة', en: 'Cycling');
  String get swimming => _getText(ar: 'السباحة', en: 'Swimming');
  String get workout => _getText(ar: 'التمرين', en: 'Workout');

  String get stepGoal => _getText(ar: 'هدف الخطوات', en: 'Step Goal');
  String get calorieGoal => _getText(ar: 'هدف السعرات', en: 'Calorie Goal');
  String get dailyActivity => _getText(ar: 'النشاط اليومي', en: 'Daily Activity');

  // ==========================================
  // Nutrition - التغذية
  // ==========================================

  String get nutritionTracking => _getText(ar: 'تتبع التغذية', en: 'Nutrition Tracking');
  String get meals => _getText(ar: 'الوجبات', en: 'Meals');
  String get breakfast => _getText(ar: 'الإفطار', en: 'Breakfast');
  String get lunch => _getText(ar: 'الغداء', en: 'Lunch');
  String get dinner => _getText(ar: 'العشاء', en: 'Dinner');
  String get snack => _getText(ar: 'وجبة خفيفة', en: 'Snack');

  String get protein => _getText(ar: 'البروتين', en: 'Protein');
  String get carbs => _getText(ar: 'الكربوهيدرات', en: 'Carbs');
  String get fats => _getText(ar: 'الدهون', en: 'Fats');
  String get fiber => _getText(ar: 'الألياف', en: 'Fiber');
  String get sugar => _getText(ar: 'السكر', en: 'Sugar');
  String get sodium => _getText(ar: 'الصوديوم', en: 'Sodium');

  String get water => _getText(ar: 'الماء', en: 'Water');
  String get waterIntake => _getText(ar: 'شرب الماء', en: 'Water Intake');
  String get hydration => _getText(ar: 'الترطيب', en: 'Hydration');

  String get weight => _getText(ar: 'الوزن', en: 'Weight');
  String get weightGoal => _getText(ar: 'هدف الوزن', en: 'Weight Goal');
  String get bmi => _getText(ar: 'مؤشر كتلة الجسم', en: 'BMI');

  // ==========================================
  // Goals & Achievements - الأهداف والإنجازات
  // ==========================================

  String get goals => _getText(ar: 'الأهداف', en: 'Goals');
  String get achievements => _getText(ar: 'الإنجازات', en: 'Achievements');
  String get progress => _getText(ar: 'التقدم', en: 'Progress');
  String get target => _getText(ar: 'الهدف', en: 'Target');
  String get completed => _getText(ar: 'مكتمل', en: 'Completed');
  String get inProgress => _getText(ar: 'قيد التقدم', en: 'In Progress');
  String get notStarted => _getText(ar: 'لم يبدأ', en: 'Not Started');

  String get dailyGoal => _getText(ar: 'الهدف اليومي', en: 'Daily Goal');
  String get weeklyGoal => _getText(ar: 'الهدف الأسبوعي', en: 'Weekly Goal');
  String get monthlyGoal => _getText(ar: 'الهدف الشهري', en: 'Monthly Goal');

  // ==========================================
  // Insights & Analysis - الرؤى والتحليل
  // ==========================================

  String get insights => _getText(ar: 'الرؤى', en: 'Insights');
  String get analysis => _getText(ar: 'التحليل', en: 'Analysis');
  String get trends => _getText(ar: 'الاتجاهات', en: 'Trends');
  String get patterns => _getText(ar: 'الأنماط', en: 'Patterns');
  String get recommendations => _getText(ar: 'التوصيات', en: 'Recommendations');
  String get tips => _getText(ar: 'النصائح', en: 'Tips');

  String get weeklyReport => _getText(ar: 'التقرير الأسبوعي', en: 'Weekly Report');
  String get monthlyReport => _getText(ar: 'التقرير الشهري', en: 'Monthly Report');
  String get healthScore => _getText(ar: 'درجة الصحة', en: 'Health Score');

  // ==========================================
  // Settings - الإعدادات
  // ==========================================

  String get profile => _getText(ar: 'الملف الشخصي', en: 'Profile');
  String get preferences => _getText(ar: 'التفضيلات', en: 'Preferences');
  String get notifications => _getText(ar: 'الإشعارات', en: 'Notifications');
  String get privacy => _getText(ar: 'الخصوصية', en: 'Privacy');
  String get security => _getText(ar: 'الأمان', en: 'Security');
  String get backup => _getText(ar: 'النسخ الاحتياطي', en: 'Backup');
  String get sync => _getText(ar: 'المزامنة', en: 'Sync');
  String get language => _getText(ar: 'اللغة', en: 'Language');
  String get theme => _getText(ar: 'المظهر', en: 'Theme');

  String get lightTheme => _getText(ar: 'المظهر الفاتح', en: 'Light Theme');
  String get darkTheme => _getText(ar: 'المظهر المظلم', en: 'Dark Theme');
  String get systemTheme => _getText(ar: 'مظهر النظام', en: 'System Theme');

  String get arabic => _getText(ar: 'العربية', en: 'Arabic');
  String get english => _getText(ar: 'الإنجليزية', en: 'English');

  // ==========================================
  // Permissions - الأذونات
  // ==========================================

  String get permissions => _getText(ar: 'الأذونات', en: 'Permissions');
  String get location => _getText(ar: 'الموقع', en: 'Location');
  String get camera => _getText(ar: 'الكاميرا', en: 'Camera');
  String get storage => _getText(ar: 'التخزين', en: 'Storage');
  String get microphone => _getText(ar: 'الميكروفون', en: 'Microphone');
  String get sensors => _getText(ar: 'الحساسات', en: 'Sensors');
  String get healthData => _getText(ar: 'بيانات الصحة', en: 'Health Data');

  String get permissionRequired => _getText(
    ar: 'مطلوب إذن للوصول',
    en: 'Permission required for access',
  );

  String get allowPermission => _getText(ar: 'السماح بالإذن', en: 'Allow Permission');
  String get denyPermission => _getText(ar: 'رفض الإذن', en: 'Deny Permission');

  // ==========================================
  // Status Messages - رسائل الحالة
  // ==========================================

  String get loading => _getText(ar: 'جارٍ التحميل...', en: 'Loading...');
  String get saving => _getText(ar: 'جارٍ الحفظ...', en: 'Saving...');
  String get updating => _getText(ar: 'جارٍ التحديث...', en: 'Updating...');
  String get deleting => _getText(ar: 'جارٍ الحذف...', en: 'Deleting...');

  String get success => _getText(ar: 'نجح', en: 'Success');
  String get error => _getText(ar: 'خطأ', en: 'Error');
  String get warning => _getText(ar: 'تحذير', en: 'Warning');
  String get info => _getText(ar: 'معلومات', en: 'Info');

  String get noData => _getText(ar: 'لا توجد بيانات', en: 'No data available');
  String get noInternet => _getText(ar: 'لا يوجد اتصال بالإنترنت', en: 'No internet connection');

  // ==========================================
  // Error Messages - رسائل الخطأ
  // ==========================================

  String get genericError => _getText(
    ar: 'حدث خطأ غير متوقع. حاول مرة أخرى.',
    en: 'An unexpected error occurred. Please try again.',
  );

  String get networkError => _getText(
    ar: 'خطأ في الشبكة. تحقق من اتصالك بالإنترنت.',
    en: 'Network error. Please check your internet connection.',
  );

  String get permissionDenied => _getText(
    ar: 'تم رفض الإذن. اذهب للإعدادات لتفعيل الأذونات.',
    en: 'Permission denied. Go to settings to enable permissions.',
  );

  String get dataNotFound => _getText(
    ar: 'البيانات غير موجودة.',
    en: 'Data not found.',
  );

  String get invalidInput => _getText(
    ar: 'المدخلات غير صحيحة.',
    en: 'Invalid input.',
  );

  // ==========================================
  // Units - الوحدات
  // ==========================================

  String get kg => _getText(ar: 'كغ', en: 'kg');
  String get lbs => _getText(ar: 'رطل', en: 'lbs');
  String get cm => _getText(ar: 'سم', en: 'cm');
  String get ft => _getText(ar: 'قدم', en: 'ft');
  String get km => _getText(ar: 'كم', en: 'km');
  String get miles => _getText(ar: 'ميل', en: 'miles');
  String get minutes => _getText(ar: 'دقيقة', en: 'minutes');
  String get hours => _getText(ar: 'ساعة', en: 'hours');
  String get days => _getText(ar: 'أيام', en: 'days');
  String get weeks => _getText(ar: 'أسابيع', en: 'weeks');
  String get months => _getText(ar: 'أشهر', en: 'months');
  String get years => _getText(ar: 'سنوات', en: 'years');
  String get liters => _getText(ar: 'لتر', en: 'liters');
  String get ml => _getText(ar: 'مل', en: 'ml');
  String get grams => _getText(ar: 'جرام', en: 'grams');
  String get ounces => _getText(ar: 'أونصة', en: 'ounces');

  // ==========================================
  // Onboarding - التعريف بالتطبيق
  // ==========================================

  String get welcome => _getText(ar: 'مرحباً', en: 'Welcome');
  String get getStarted => _getText(ar: 'ابدأ الآن', en: 'Get Started');
  String get onboardingTitle1 => _getText(
    ar: 'تتبع صحتك بذكاء',
    en: 'Track Your Health Smartly',
  );
  String get onboardingDesc1 => _getText(
    ar: 'راقب نومك، نشاطك، تغذيتك واستخدام هاتفك بطريقة ذكية وتلقائية',
    en: 'Monitor your sleep, activity, nutrition and phone usage automatically',
  );

  String get onboardingTitle2 => _getText(
    ar: 'رؤى مخصصة لك',
    en: 'Personalized Insights',
  );
  String get onboardingDesc2 => _getText(
    ar: 'احصل على تحليلات ذكية ونصائح مخصصة لتحسين صحتك النفسية والجسدية',
    en: 'Get smart analytics and personalized tips to improve your mental and physical health',
  );

  String get onboardingTitle3 => _getText(
    ar: 'تحكم كامل في خصوصيتك',
    en: 'Complete Privacy Control',
  );
  String get onboardingDesc3 => _getText(
    ar: 'بياناتك محفوظة على جهازك بشكل آمن مع تشفير متقدم',
    en: 'Your data is securely stored on your device with advanced encryption',
  );

  // ==========================================
  // Permissions Screen - شاشة الأذونات
  // ==========================================

  String get permissionsTitle => _getText(
    ar: 'أذونات التطبيق',
    en: 'App Permissions',
  );

  String get permissionsSubtitle => _getText(
    ar: 'نحتاج بعض الأذونات لتوفير أفضل تجربة لك',
    en: 'We need some permissions to provide you the best experience',
  );

  String get permissionsRequired => _getText(
    ar: 'الأذونات مطلوبة',
    en: 'Permissions Required',
  );

  String get permissionsRequiredMessage => _getText(
    ar: 'بعض الأذونات الأساسية مطلوبة لعمل التطبيق بشكل صحيح. يرجى منح الأذونات من الإعدادات.',
    en: 'Some essential permissions are required for the app to work properly. Please grant permissions from settings.',
  );

  String get permissionsGranted => _getText(
    ar: 'أذونات ممنوحة',
    en: 'permissions granted',
  );

  String get requestAllPermissions => _getText(
    ar: 'طلب جميع الأذونات',
    en: 'Request All Permissions',
  );

  String get continueToApp => _getText(
    ar: 'المتابعة للتطبيق',
    en: 'Continue to App',
  );

  String get skipOptionalPermissions => _getText(
    ar: 'تخطي الأذونات الاختيارية',
    en: 'Skip Optional Permissions',
  );

  String get openSettings => _getText(
    ar: 'فتح الإعدادات',
    en: 'Open Settings',
  );

  String get exit => _getText(
    ar: 'خروج',
    en: 'Exit',
  );

  // ==========================================
  // Individual Permissions - الأذونات الفردية
  // ==========================================

  String get notificationsPermissionTitle => _getText(
    ar: 'الإشعارات',
    en: 'Notifications',
  );

  String get notificationsPermissionDescription => _getText(
    ar: 'للحصول على تذكيرات مهمة حول صحتك ونشاطك اليومي',
    en: 'To receive important reminders about your health and daily activities',
  );

  String get sensorsPermissionTitle => _getText(
    ar: 'حساسات الجهاز',
    en: 'Device Sensors',
  );

  String get sensorsPermissionDescription => _getText(
    ar: 'لتتبع حركتك ونشاطك البدني تلقائياً دون الحاجة لتدخلك',
    en: 'To automatically track your movement and physical activity without manual input',
  );

  String get activityPermissionTitle => _getText(
    ar: 'مراقبة النشاط',
    en: 'Activity Recognition',
  );

  String get activityPermissionDescription => _getText(
    ar: 'للتعرف على أنواع الأنشطة المختلفة مثل المشي والجري والنوم',
    en: 'To recognize different activity types like walking, running, and sleeping',
  );

  String get locationPermissionTitle => _getText(
    ar: 'الموقع الجغرافي',
    en: 'Location Access',
  );

  String get locationPermissionDescription => _getText(
    ar: 'لتتبع الأماكن التي تزورها وربطها بمزاجك وصحتك (اختياري)',
    en: 'To track places you visit and correlate them with your mood and health (optional)',
  );

  String get batteryPermissionTitle => _getText(
    ar: 'تحسين البطارية',
    en: 'Battery Optimization',
  );

  String get batteryPermissionDescription => _getText(
    ar: 'للسماح للتطبيق بالعمل في الخلفية وتتبع البيانات بدقة',
    en: 'To allow the app to work in background and track data accurately',
  );

  String get alarmsPermissionTitle => _getText(
    ar: 'المنبهات الدقيقة',
    en: 'Exact Alarms',
  );

  String get alarmsPermissionDescription => _getText(
    ar: 'لإرسال تذكيرات دقيقة في الأوقات المحددة مثل أوقات النوم والوجبات',
    en: 'To send precise reminders at scheduled times like bedtime and meal times',
  );

  // ==========================================
  // Permission Status Messages - رسائل حالة الأذونات
  // ==========================================

  String get permissionGranted => _getText(
    ar: 'ممنوح',
    en: 'Granted',
  );

  String get permissionDeniedStatus => _getText(
    ar: 'مرفوض',
    en: 'Denied',
  );

  String get permissionPermanentlyDenied => _getText(
    ar: 'مرفوض نهائياً',
    en: 'Permanently Denied',
  );

  String get permissionRequesting => _getText(
    ar: 'جاري الطلب...',
    en: 'Requesting...',
  );

  String get permissionPending => _getText(
    ar: 'في الانتظار',
    en: 'Pending',
  );

  String get permissionRestricted => _getText(
    ar: 'مقيد',
    en: 'Restricted',
  );

  String get permissionLimited => _getText(
    ar: 'محدود',
    en: 'Limited',
  );

  String get permissionProvisional => _getText(
    ar: 'مؤقت',
    en: 'Provisional',
  );

  String get essentialPermission => _getText(
    ar: 'أساسي',
    en: 'Essential',
  );

  String get optionalPermission => _getText(
    ar: 'اختياري',
    en: 'Optional',
  );

  // ==========================================
  // Permission Actions - إجراءات الأذونات
  // ==========================================

  String get requestPermission => _getText(
    ar: 'طلب الإذن',
    en: 'Request Permission',
  );

  String get retryPermission => _getText(
    ar: 'إعادة المحاولة',
    en: 'Retry',
  );

  String get openPermissionSettings => _getText(
    ar: 'فتح الإعدادات',
    en: 'Open Settings',
  );

  String get permissionExplanation => _getText(
    ar: 'لماذا نحتاج هذا الإذن؟',
    en: 'Why do we need this permission?',
  );

  // ==========================================
  // Loading Messages - رسائل التحميل
  // ==========================================

  String get loadingPermissions => _getText(
    ar: 'جاري تحميل الأذونات...',
    en: 'Loading permissions...',
  );

  String get checkingPermissions => _getText(
    ar: 'جاري فحص الأذونات...',
    en: 'Checking permissions...',
  );

  String get requestingPermissions => _getText(
    ar: 'جاري طلب الأذونات...',
    en: 'Requesting permissions...',
  );

  String get savingPermissions => _getText(
    ar: 'جاري حفظ الأذونات...',
    en: 'Saving permissions...',
  );

  // ==========================================
  // Success Messages - رسائل النجاح
  // ==========================================

  String get allPermissionsGranted => _getText(
    ar: 'تم منح جميع الأذونات بنجاح!',
    en: 'All permissions granted successfully!',
  );

  String get essentialPermissionsGranted => _getText(
    ar: 'تم منح الأذونات الأساسية',
    en: 'Essential permissions granted',
  );

  String get permissionGrantedSuccess => _getText(
    ar: 'تم منح الإذن بنجاح',
    en: 'Permission granted successfully',
  );

  String get readyToUseApp => _getText(
    ar: 'جاهز لاستخدام التطبيق!',
    en: 'Ready to use the app!',
  );

  // ==========================================
  // Error Messages - رسائل الخطأ
  // ==========================================

  String get permissionRequestFailed => _getText(
    ar: 'فشل في طلب الإذن',
    en: 'Permission request failed',
  );

  String get permissionNotSupported => _getText(
    ar: 'هذا الإذن غير مدعوم على جهازك',
    en: 'This permission is not supported on your device',
  );

  String get permissionSystemError => _getText(
    ar: 'خطأ في النظام أثناء طلب الإذن',
    en: 'System error while requesting permission',
  );

  String get cannotProceedWithoutPermissions => _getText(
    ar: 'لا يمكن المتابعة بدون الأذونات الأساسية',
    en: 'Cannot proceed without essential permissions',
  );

  // ==========================================
  // Tips and Hints - نصائح وإرشادات
  // ==========================================

  String get permissionTip => _getText(
    ar: 'نصيحة: يمكنك تغيير الأذونات في أي وقت من إعدادات الجهاز',
    en: 'Tip: You can change permissions anytime from device settings',
  );

  String get whyPermissionsNeeded => _getText(
    ar: 'نحتاج هذه الأذونات لتوفير تجربة شخصية ودقيقة في تتبع صحتك',
    en: 'We need these permissions to provide a personalized and accurate health tracking experience',
  );

  String get dataPrivacyNote => _getText(
    ar: 'ملاحظة: جميع بياناتك تبقى على جهازك ولا نشاركها مع أطراف خارجية',
    en: 'Note: All your data stays on your device and we don\'t share it with third parties',
  );

  String get optionalPermissionsNote => _getText(
    ar: 'الأذونات الاختيارية تحسن من تجربتك لكن يمكنك استخدام التطبيق بدونها',
    en: 'Optional permissions enhance your experience but you can use the app without them',
  );

  // ==========================================
  // Complete Permission Functions - دوال الأذونات المكتملة
  // ==========================================

  /// دالة لتحديد إذا تم منح الإذن
  String get completePermissions => _getText(
    ar: 'إكمال الأذونات',
    en: 'Complete Permissions',
  );

  /// رسالة الانتهاء من الأذونات
  String get permissionsCompleted => _getText(
    ar: 'تم إكمال إعداد الأذونات',
    en: 'Permissions setup completed',
  );

  /// رسالة الانتقال للصفحة التالية
  String get proceedToNextStep => _getText(
    ar: 'المتابعة للخطوة التالية',
    en: 'Proceed to Next Step',
  );

  // ==========================================
  // AppStateProvider Integration Messages
  // ==========================================

  String get initializingApp => _getText(
    ar: 'جاري تهيئة التطبيق...',
    en: 'Initializing app...',
  );

  String get setupComplete => _getText(
    ar: 'تم إكمال الإعداد',
    en: 'Setup Complete',
  );

  String get welcomeToSmartPsych => _getText(
    ar: 'مرحباً بك في Smart Psych',
    en: 'Welcome to Smart Psych',
  );

  // ==========================================
  // Helper Methods - الدوال المساعدة
  // ==========================================

  /// الحصول على النص حسب اللغة
  String _getText({required String ar, required String en}) {
    return isArabic ? ar : en;
  }

  /// تنسيق الوقت
  String formatTime(DateTime time) {
    if (isArabic) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
      final period = time.hour >= 12 ? 'PM' : 'AM';
      return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
    }
  }

  /// تنسيق التاريخ
  String formatDate(DateTime date) {
    if (isArabic) {
      return '${date.day}/${date.month}/${date.year}';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  /// تنسيق المدة
  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return isArabic
          ? '$hours ساعة و $minutes دقيقة'
          : '${hours}h ${minutes}m';
    } else {
      return isArabic
          ? '$minutes دقيقة'
          : '${minutes}m';
    }
  }

  /// تنسيق الأرقام
  String formatNumber(double number, {int decimals = 0}) {
    if (decimals == 0) {
      return number.round().toString();
    } else {
      return number.toStringAsFixed(decimals);
    }
  }

  /// تنسيق النسبة المئوية
  String formatPercentage(double percentage) {
    return '${percentage.round()}%';
  }

  /// الحصول على اسم اليوم
  String getDayName(int weekday) {
    switch (weekday) {
      case 1: return monday;
      case 2: return tuesday;
      case 3: return wednesday;
      case 4: return thursday;
      case 5: return friday;
      case 6: return saturday;
      case 7: return sunday;
      default: return '';
    }
  }

  /// الحصول على اسم الشهر
  String getMonthName(int month) {
    switch (month) {
      case 1: return january;
      case 2: return february;
      case 3: return march;
      case 4: return april;
      case 5: return may;
      case 6: return june;
      case 7: return july;
      case 8: return august;
      case 9: return september;
      case 10: return october;
      case 11: return november;
      case 12: return december;
      default: return '';
    }
  }

  /// دعم اللغات المتاحة
  static const List<Locale> supportedLocales = [
    Locale('ar', 'SA'), // العربية - السعودية
    Locale('en', 'US'), // الإنجليزية - الولايات المتحدة
  ];

  /// Delegate للترجمة
  static const LocalizationsDelegate<AppLocalizations> delegate =
  _AppLocalizationsDelegate();
}

/// Localizations Delegate - مندوب الترجمة
class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((supportedLocale) => supportedLocale.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}

/// Extension للوصول السهل للترجمة
extension LocalizationExtension on BuildContext {
  /// الحصول على الترجمة
  AppLocalizations get l10n {
    final localizations = AppLocalizations.of(this);
    if (localizations == null) {
      throw Exception('AppLocalizations not found in context');
    }
    return localizations;
  }

  /// فحص إذا كانت اللغة عربية
  bool get isArabic => l10n.isArabic;

  /// فحص إذا كانت اللغة إنجليزية
  bool get isEnglish => l10n.isEnglish;

  /// اتجاه النص
  TextDirection get textDirection => l10n.textDirection;
}

/// Pluralization Helper - مساعد صيغ الجمع
class PluralizationHelper {
  /// صيغة الجمع للعربية
  static String arabicPlural(int count, {
    required String zero,
    required String one,
    required String two,
    required String few,
    required String many,
    required String other,
  }) {
    if (count == 0) return zero;
    if (count == 1) return one;
    if (count == 2) return two;
    if (count >= 3 && count <= 10) return few;
    if (count >= 11 && count <= 99) return many;
    return other;
  }

  /// صيغة الجمع للإنجليزية
  static String englishPlural(int count, {
    required String one,
    required String other,
  }) {
    return count == 1 ? one : other;
  }
}

/// RTL Helper - مساعد الاتجاه من اليمين لليسار
class RTLHelper {
  /// فحص إذا كان النص يحتاج اتجاه من اليمين لليسار
  static bool isRTL(String text) {
    if (text.isEmpty) return false;

    // فحص أول حرف في النص
    final firstChar = text.codeUnitAt(0);

    // النطاقات العربية في Unicode
    return (firstChar >= 0x0600 && firstChar <= 0x06FF) || // Arabic
        (firstChar >= 0x0750 && firstChar <= 0x077F) || // Arabic Supplement
        (firstChar >= 0x08A0 && firstChar <= 0x08FF) || // Arabic Extended-A
        (firstChar >= 0xFB50 && firstChar <= 0xFDFF) || // Arabic Presentation Forms-A
        (firstChar >= 0xFE70 && firstChar <= 0xFEFF);   // Arabic Presentation Forms-B
  }

  /// تحديد اتجاه النص تلقائياً
  static TextDirection getTextDirection(String text) {
    return isRTL(text) ? TextDirection.rtl : TextDirection.ltr;
  }
}