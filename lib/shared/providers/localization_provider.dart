// lib/core/providers/localization_provider.dart - النسخة المُصححة
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';

class LocalizationProvider with ChangeNotifier {
  Locale _locale = const Locale('ar', 'SA');
  bool _isRTL = true;

  // Supported locales
  static const List<Locale> supportedLocales = [
    Locale('ar', 'SA'), // Arabic
    Locale('en', 'US'), // English
  ];

  // Getters
  Locale get locale => _locale;
  bool get isRTL => _isRTL;
  bool get isArabic => _locale.languageCode == 'ar';
  bool get isEnglish => _locale.languageCode == 'en';
  String get currentLanguageCode => _locale.languageCode;

  // Initialize localization provider
  Future<void> initialize() async {
    await _loadLanguagePreference();
  }

  // Load language preference from storage
  Future<void> _loadLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(AppConstants.keyLanguage) ?? 'ar';

      if (languageCode == 'en') {
        _locale = const Locale('en', 'US');
        _isRTL = false;
      } else {
        _locale = const Locale('ar', 'SA');
        _isRTL = true;
      }
    } catch (e) {
      debugPrint('Error loading language preference: $e');
      _locale = const Locale('ar', 'SA');
      _isRTL = true;
    }
  }

  // Change language
  Future<void> setLanguage(String languageCode) async {
    if (_locale.languageCode == languageCode) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyLanguage, languageCode);

      if (languageCode == 'en') {
        _locale = const Locale('en', 'US');
        _isRTL = false;
      } else {
        _locale = const Locale('ar', 'SA');
        _isRTL = true;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error setting language: $e');
    }
  }

  // Toggle between Arabic and English
  Future<void> toggleLanguage() async {
    final newLanguage = isArabic ? 'en' : 'ar';
    await setLanguage(newLanguage);
  }

  // Get localized text based on current language
  String getText(String arabicText, String englishText) {
    return isArabic ? arabicText : englishText;
  }

  // App name
  String get appName => getText('متتبع النوم', 'Sleep Tracker');

  // Navigation titles
  String get homeTitle => getText('الرئيسية', 'Home');
  String get sleepTitle => getText('النوم', 'Sleep');
  String get activityTitle => getText('النشاط', 'Activity');
  String get nutritionTitle => getText('التغذية', 'Nutrition');
  String get statisticsTitle => getText('الإحصائيات', 'Statistics');
  String get settingsTitle => getText('الإعدادات', 'Settings');

  // Sleep tracking
  String get sleepTracking => getText('تتبع النوم', 'Sleep Tracking');
  String get startSleep => getText('بدء النوم', 'Start Sleep');
  String get endSleep => getText('إنهاء النوم', 'End Sleep');
  String get sleepDuration => getText('مدة النوم', 'Sleep Duration');
  String get sleepQuality => getText('جودة النوم', 'Sleep Quality');
  String get sleepHistory => getText('سجل النوم', 'Sleep History');
  String get bedtime => getText('وقت النوم', 'Bedtime');
  String get wakeTime => getText('وقت الاستيقاظ', 'Wake Time');
  String get sleepEfficiency => getText('كفاءة النوم', 'Sleep Efficiency');
  String get phoneUsageDuringSleep => getText('استخدام الهاتف أثناء النوم', 'Phone Usage During Sleep');
  String get sleepSession => getText('جلسة النوم', 'Sleep Session');
  String get currentSleep => getText('النوم الحالي', 'Current Sleep');
  String get lastNight => getText('الليلة الماضية', 'Last Night');
  String get averageSleep => getText('متوسط النوم', 'Average Sleep');
  String get bestSleep => getText('أفضل نوم', 'Best Sleep');
  String get deepSleep => getText('نوم عميق', 'Deep Sleep');
  String get lightSleep => getText('نوم خفيف', 'Light Sleep');
  String get remSleep => getText('نوم حالم', 'REM Sleep');
  String get awake => getText('مستيقظ', 'Awake');

  // Activity tracking
  String get activityTracking => getText('تتبع النشاط', 'Activity Tracking');
  String get stepsToday => getText('خطوات اليوم', 'Steps Today');
  String get caloriesBurned => getText('السعرات المحروقة', 'Calories Burned');
  String get distanceWalked => getText('المسافة المقطوعة', 'Distance Walked');
  String get locationVisits => getText('زيارات الأماكن', 'Location Visits');
  String get currentLocation => getText('الموقع الحالي', 'Current Location');
  String get activityType => getText('نوع النشاط', 'Activity Type');
  String get activeMinutes => getText('دقائق النشاط', 'Active Minutes');
  String get dailyGoal => getText('الهدف اليومي', 'Daily Goal');
  String get weeklyGoal => getText('الهدف الأسبوعي', 'Weekly Goal');
  String get monthlyGoal => getText('الهدف الشهري', 'Monthly Goal');

  // Nutrition
  String get nutritionTracking => getText('تتبع التغذية', 'Nutrition Tracking');
  String get addMeal => getText('إضافة وجبة', 'Add Meal');
  String get editMeal => getText('تعديل وجبة', 'Edit Meal');
  String get deleteMeal => getText('حذف وجبة', 'Delete Meal');
  String get breakfast => getText('فطور', 'Breakfast');
  String get lunch => getText('غداء', 'Lunch');
  String get dinner => getText('عشاء', 'Dinner');
  String get snack => getText('وجبة خفيفة', 'Snack');
  String get calories => getText('سعرات', 'Calories');
  String get protein => getText('بروتين', 'Protein');
  String get carbs => getText('كربوهيدرات', 'Carbs');
  String get fat => getText('دهون', 'Fat');
  String get fiber => getText('ألياف', 'Fiber');
  String get sugar => getText('سكر', 'Sugar');
  String get sodium => getText('صوديوم', 'Sodium');
  String get weight => getText('الوزن', 'Weight');
  String get addWeight => getText('إضافة وزن', 'Add Weight');
  String get weightHistory => getText('سجل الوزن', 'Weight History');
  String get bmi => getText('مؤشر كتلة الجسم', 'BMI');
  String get bodyFat => getText('دهون الجسم', 'Body Fat');
  String get muscleMass => getText('الكتلة العضلية', 'Muscle Mass');
  String get waterPercentage => getText('نسبة الماء', 'Water Percentage');

  // Statistics
  String get dailyReport => getText('تقرير يومي', 'Daily Report');
  String get weeklyReport => getText('تقرير أسبوعي', 'Weekly Report');
  String get monthlyReport => getText('تقرير شهري', 'Monthly Report');
  String get yearlyReport => getText('تقرير سنوي', 'Yearly Report');
  String get sleepChart => getText('مخطط النوم', 'Sleep Chart');
  String get activityChart => getText('مخطط النشاط', 'Activity Chart');
  String get nutritionChart => getText('مخطط التغذية', 'Nutrition Chart');
  String get comparison => getText('مقارنة', 'Comparison');
  String get trends => getText('الاتجاهات', 'Trends');
  String get insights => getText('رؤى', 'Insights');
  String get analytics => getText('التحليلات', 'Analytics');
  String get summary => getText('الملخص', 'Summary');
  String get detailed => getText('مفصل', 'Detailed');
  String get overview => getText('نظرة عامة', 'Overview');

  // Common words
  String get save => getText('حفظ', 'Save');
  String get cancel => getText('إلغاء', 'Cancel');
  String get delete => getText('حذف', 'Delete');
  String get edit => getText('تعديل', 'Edit');
  String get add => getText('إضافة', 'Add');
  String get update => getText('تحديث', 'Update');
  String get confirm => getText('تأكيد', 'Confirm');
  String get yes => getText('نعم', 'Yes');
  String get no => getText('لا', 'No');
  String get ok => getText('موافق', 'OK');
  String get done => getText('تم', 'Done');
  String get next => getText('التالي', 'Next');
  String get previous => getText('السابق', 'Previous');
  String get back => getText('رجوع', 'Back');
  String get close => getText('إغلاق', 'Close');
  String get open => getText('فتح', 'Open');
  String get start => getText('بدء', 'Start');
  String get stop => getText('إيقاف', 'Stop');
  String get pause => getText('إيقاف مؤقت', 'Pause');
  String get resume => getText('استئناف', 'Resume');
  String get reset => getText('إعادة تعيين', 'Reset');
  String get clear => getText('مسح', 'Clear');
  String get loading => getText('جاري التحميل...', 'Loading...');
  String get error => getText('خطأ', 'Error');
  String get success => getText('نجح', 'Success');
  String get warning => getText('تحذير', 'Warning');
  String get info => getText('معلومات', 'Info');
  String get noData => getText('لا توجد بيانات', 'No Data');
  String get noResults => getText('لا توجد نتائج', 'No Results');
  String get searchHint => getText('البحث...', 'Search...');
  String get filter => getText('تصفية', 'Filter');
  String get sort => getText('ترتيب', 'Sort');
  String get refresh => getText('تحديث', 'Refresh');

  // Time & Date
  String get today => getText('اليوم', 'Today');
  String get yesterday => getText('أمس', 'Yesterday');
  String get tomorrow => getText('غداً', 'Tomorrow');
  String get thisWeek => getText('هذا الأسبوع', 'This Week');
  String get lastWeek => getText('الأسبوع الماضي', 'Last Week');
  String get thisMonth => getText('هذا الشهر', 'This Month');
  String get lastMonth => getText('الشهر الماضي', 'Last Month');
  String get thisYear => getText('هذا العام', 'This Year');
  String get lastYear => getText('العام الماضي', 'Last Year');
  String get hours => getText('ساعات', 'Hours');
  String get minutes => getText('دقائق', 'Minutes');
  String get seconds => getText('ثواني', 'Seconds');
  String get days => getText('أيام', 'Days');
  String get weeks => getText('أسابيع', 'Weeks');
  String get months => getText('أشهر', 'Months');
  String get years => getText('سنوات', 'Years');
  String get morning => getText('صباحاً', 'Morning');
  String get afternoon => getText('بعد الظهر', 'Afternoon');
  String get evening => getText('مساءً', 'Evening');
  String get night => getText('ليلاً', 'Night');

  // Settings
  String get language => getText('اللغة', 'Language');
  String get arabic => getText('العربية', 'Arabic');
  String get english => getText('English', 'إنجليزي');
  String get theme => getText('المظهر', 'Theme');
  String get lightMode => getText('المظهر الفاتح', 'Light Mode');
  String get darkMode => getText('المظهر الداكن', 'Dark Mode');
  String get systemMode => getText('نظام التشغيل', 'System');
  String get notifications => getText('الإشعارات', 'Notifications');
  String get permissions => getText('الأذونات', 'Permissions');
  String get privacy => getText('الخصوصية', 'Privacy');
  String get security => getText('الأمان', 'Security');
  String get backup => getText('نسخ احتياطي', 'Backup');
  String get restore => getText('استعادة', 'Restore');
  String get export => getText('تصدير البيانات', 'Export Data');
  String get import => getText('استيراد البيانات', 'Import Data');
  String get about => getText('حول التطبيق', 'About');
  String get help => getText('المساعدة', 'Help');
  String get support => getText('الدعم', 'Support');
  String get feedback => getText('ملاحظات', 'Feedback');
  String get rateApp => getText('قيم التطبيق', 'Rate App');
  String get share => getText('مشاركة', 'Share');
  String get version => getText('الإصدار', 'Version');

  // Phone usage
  String get phoneUsage => getText('استخدام الهاتف', 'Phone Usage');
  String get usageCount => getText('عدد مرات الاستخدام', 'Usage Count');
  String get usageDuration => getText('مدة الاستخدام', 'Usage Duration');
  String get shortUsage => getText('استخدام قصير', 'Short Usage');
  String get mediumUsage => getText('استخدام متوسط', 'Medium Usage');
  String get longUsage => getText('استخدام طويل', 'Long Usage');
  String get unlockCount => getText('عدد مرات فتح القفل', 'Unlock Count');
  String get screenTime => getText('وقت الشاشة', 'Screen Time');
  String get appUsage => getText('استخدام التطبيقات', 'App Usage');
  String get mostUsedApps => getText('التطبيقات الأكثر استخداماً', 'Most Used Apps');

  // Environment
  String get environment => getText('البيئة', 'Environment');
  String get lightLevel => getText('مستوى الإضاءة', 'Light Level');
  String get noiseLevel => getText('مستوى الضجيج', 'Noise Level');
  String get temperature => getText('درجة الحرارة', 'Temperature');
  String get humidity => getText('الرطوبة', 'Humidity');
  String get airQuality => getText('جودة الهواء', 'Air Quality');

  // Quality levels
  String get excellent => getText('ممتاز', 'Excellent');
  String get good => getText('جيد', 'Good');
  String get fair => getText('مقبول', 'Fair');
  String get poor => getText('ضعيف', 'Poor');
  String get veryGood => getText('جيد جداً', 'Very Good');
  String get veryPoor => getText('ضعيف جداً', 'Very Poor');

  // Activity types
  String get walking => getText('مشي', 'Walking');
  String get running => getText('جري', 'Running');
  String get cycling => getText('ركوب الدراجة', 'Cycling');
  String get driving => getText('قيادة', 'Driving');
  String get still => getText('ثابت', 'Still');
  String get unknown => getText('غير معروف', 'Unknown');
  String get swimming => getText('سباحة', 'Swimming');
  String get workout => getText('تمرين', 'Workout');
  String get yoga => getText('يوغا', 'Yoga');
  String get dancing => getText('رقص', 'Dancing');
  String get hiking => getText('مشي لمسافات طويلة', 'Hiking');
  String get climbing => getText('تسلق', 'Climbing');

  // Location categories
  String get home => getText('المنزل', 'Home');
  String get work => getText('العمل', 'Work');
  String get gym => getText('النادي الرياضي', 'Gym');
  String get shopping => getText('التسوق', 'Shopping');
  String get restaurant => getText('مطعم', 'Restaurant');
  String get transport => getText('مواصلات', 'Transport');
  String get entertainment => getText('ترفيه', 'Entertainment');
  String get health => getText('صحة', 'Health');
  String get education => getText('تعليم', 'Education');
  String get religion => getText('دين', 'Religion');
  String get other => getText('أخرى', 'Other');
  String get office => getText('مكتب', 'Office');
  String get school => getText('مدرسة', 'School');
  String get university => getText('جامعة', 'University');
  String get hospital => getText('مستشفى', 'Hospital');
  String get pharmacy => getText('صيدلية', 'Pharmacy');
  String get bank => getText('بنك', 'Bank');
  String get park => getText('حديقة', 'Park');
  String get mall => getText('مول', 'Mall');
  String get cafe => getText('مقهى', 'Cafe');

  // Goals
  String get goals => getText('الأهداف', 'Goals');
  String get dailyGoals => getText('الأهداف اليومية', 'Daily Goals');
  String get weeklyGoals => getText('الأهداف الأسبوعية', 'Weekly Goals');
  String get monthlyGoals => getText('الأهداف الشهرية', 'Monthly Goals');
  String get goalAchieved => getText('تم تحقيق الهدف!', 'Goal achieved!');
  String get goalProgress => getText('تقدم الهدف', 'Goal Progress');
  String get setGoal => getText('تحديد هدف', 'Set Goal');
  String get editGoal => getText('تعديل الهدف', 'Edit Goal');
  String get stepsGoal => getText('هدف الخطوات', 'Steps Goal');
  String get sleepGoal => getText('هدف النوم', 'Sleep Goal');
  String get caloriesGoal => getText('هدف السعرات', 'Calories Goal');
  String get weightGoal => getText('هدف الوزن', 'Weight Goal');

  // Messages
  String get sleepSessionStarted => getText('تم بدء جلسة النوم', 'Sleep session started');
  String get sleepSessionEnded => getText('تم إنهاء جلسة النوم', 'Sleep session ended');
  String get dataExported => getText('تم تصدير البيانات بنجاح', 'Data exported successfully');
  String get dataImported => getText('تم استيراد البيانات بنجاح', 'Data imported successfully');
  String get permissionRequired => getText('مطلوب إذن للوصول', 'Permission required for access');
  String get locationPermissionRequired => getText('مطلوب إذن الموقع', 'Location permission required');
  String get notificationPermissionRequired => getText('مطلوب إذن الإشعارات', 'Notification permission required');
  String get cameraPermissionRequired => getText('مطلوب إذن الكاميرا', 'Camera permission required');
  String get storagePermissionRequired => getText('مطلوب إذن التخزين', 'Storage permission required');
  String get microphonePermissionRequired => getText('مطلوب إذن الميكروفون', 'Microphone permission required');

  // Sleep tips
  String get sleepTips => getText('نصائح النوم', 'Sleep Tips');
  String get activityTips => getText('نصائح النشاط', 'Activity Tips');
  String get nutritionTips => getText('نصائح التغذية', 'Nutrition Tips');
  String get tip1 => getText('حافظ على مواعيد نوم منتظمة', 'Maintain regular sleep schedule');
  String get tip2 => getText('تجنب استخدام الهاتف قبل النوم', 'Avoid phone use before bedtime');
  String get tip3 => getText('اجعل غرفة النوم مظلمة وهادئة', 'Keep bedroom dark and quiet');
  String get tip4 => getText('تجنب الكافيين قبل النوم بساعات', 'Avoid caffeine hours before sleep');
  String get tip5 => getText('مارس الرياضة بانتظام', 'Exercise regularly');

  // Status
  String get active => getText('نشط', 'Active');
  String get inactive => getText('غير نشط', 'Inactive');
  String get enabled => getText('مفعل', 'Enabled');
  String get disabled => getText('معطل', 'Disabled');
  String get online => getText('متصل', 'Online');
  String get offline => getText('غير متصل', 'Offline');
  String get synced => getText('متزامن', 'Synced');
  String get notSynced => getText('غير متزامن', 'Not Synced');
  String get completed => getText('مكتمل', 'Completed');
  String get pending => getText('معلق', 'Pending');
  String get inProgress => getText('قيد التقدم', 'In Progress');
  String get failed => getText('فشل', 'Failed');

  // Units
  String get kg => getText('كج', 'kg');
  String get lbs => getText('رطل', 'lbs');
  String get cm => getText('سم', 'cm');
  String get ft => getText('قدم', 'ft');
  String get km => getText('كم', 'km');
  String get miles => getText('ميل', 'miles');
  String get cal => getText('سعرة', 'cal');
  String get kcal => getText('كيلو سعرة', 'kcal');
  String get grams => getText('جرام', 'g');
  String get ml => getText('مل', 'ml');
  String get liters => getText('لتر', 'L');
  String get percent => getText('٪', '%');
  String get bpm => getText('نبضة/دقيقة', 'bpm');
  String get celsius => getText('مئوية', '°C');
  String get fahrenheit => getText('فهرنهايت', '°F');

  // Number formatting - مُصحح
  String formatNumber(num number) {
    if (isArabic) {
      // Convert to Arabic-Indic numerals
      final arabicNumerals = {
        '0': '٠',
        '1': '١',
        '2': '٢',
        '3': '٣',
        '4': '٤',
        '5': '٥',
        '6': '٦',
        '7': '٧',
        '8': '٨',
        '9': '٩',
      };

      String result = number.toString();
      arabicNumerals.forEach((latin, arabic) {
        result = result.replaceAll(latin, arabic);
      });
      return result;
    }
    return number.toString();
  }

  // String formatting helper - جديد
  String formatString(String text) {
    if (isArabic) {
      final arabicNumerals = {
        '0': '٠',
        '1': '١',
        '2': '٢',
        '3': '٣',
        '4': '٤',
        '5': '٥',
        '6': '٦',
        '7': '٧',
        '8': '٨',
        '9': '٩',
      };

      String result = text;
      arabicNumerals.forEach((latin, arabic) {
        result = result.replaceAll(latin, arabic);
      });
      return result;
    }
    return text;
  }

  // Date formatting
  String formatDate(DateTime date) {
    if (isArabic) {
      final months = [
        'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
        'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
      ];
      return '${formatNumber(date.day)} ${months[date.month - 1]} ${formatNumber(date.year)}';
    } else {
      final months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  // Time formatting - مُصحح
  String formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;

    if (isArabic) {
      final period = hour >= 12 ? 'م' : 'ص';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '${formatNumber(displayHour)}:${formatString(minute.toString().padLeft(2, '0'))} $period';
    } else {
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    }
  }

  // Duration formatting
  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (isArabic) {
      if (hours > 0) {
        return '${formatNumber(hours)} ساعة و ${formatNumber(minutes)} دقيقة';
      } else {
        return '${formatNumber(minutes)} دقيقة';
      }
    } else {
      if (hours > 0) {
        return '$hours hour${hours != 1 ? 's' : ''} and $minutes minute${minutes != 1 ? 's' : ''}';
      } else {
        return '$minutes minute${minutes != 1 ? 's' : ''}';
      }
    }
  }

  // Short duration formatting
  String formatShortDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return isArabic ? '${formatNumber(hours)}س ${formatNumber(minutes)}د' : '${hours}h ${minutes}m';
    } else {
      return isArabic ? '${formatNumber(minutes)}د' : '${minutes}m';
    }
  }

  // Weight formatting - مُصحح
  String formatWeight(double weight, {bool useMetric = true}) {
    if (useMetric) {
      return isArabic ? '${formatString(weight.toStringAsFixed(1))} كج' : '${weight.toStringAsFixed(1)} kg';
    } else {
      final lbs = weight * 2.20462;
      return isArabic ? '${formatString(lbs.toStringAsFixed(1))} رطل' : '${lbs.toStringAsFixed(1)} lbs';
    }
  }

  // Distance formatting - مُصحح
  String formatDistance(double distance, {bool useMetric = true}) {
    if (useMetric) {
      if (distance < 1) {
        final meters = (distance * 1000).toInt();
        return isArabic ? '${formatNumber(meters)} متر' : '$meters m';
      } else {
        return isArabic ? '${formatString(distance.toStringAsFixed(1))} كم' : '${distance.toStringAsFixed(1)} km';
      }
    } else {
      final miles = distance * 0.621371;
      return isArabic ? '${formatString(miles.toStringAsFixed(1))} ميل' : '${miles.toStringAsFixed(1)} miles';
    }
  }

  // Calories formatting
  String formatCalories(int calories) {
    return isArabic ? '${formatNumber(calories)} سعرة' : '$calories cal';
  }

  // Steps formatting - مُصحح
  String formatSteps(int steps) {
    if (steps >= 1000) {
      final k = steps / 1000;
      return isArabic ? '${formatString(k.toStringAsFixed(1))}ك خطوة' : '${k.toStringAsFixed(1)}k steps';
    }
    return isArabic ? '${formatNumber(steps)} خطوة' : '$steps steps';
  }

  // Percentage formatting - مُصحح
  String formatPercentage(double percentage) {
    return isArabic ? '${formatString(percentage.toStringAsFixed(0))}٪' : '${percentage.toStringAsFixed(0)}%';
  }

  // Temperature formatting - مُصحح
  String formatTemperature(double temp, {bool useCelsius = true}) {
    if (useCelsius) {
      return isArabic ? '${formatString(temp.toStringAsFixed(1))}°م' : '${temp.toStringAsFixed(1)}°C';
    } else {
      final fahrenheit = (temp * 9/5) + 32;
      return isArabic ? '${formatString(fahrenheit.toStringAsFixed(1))}°ف' : '${fahrenheit.toStringAsFixed(1)}°F';
    }
  }

  // Helper methods
  String getQualityText(String quality) {
    switch (quality.toLowerCase()) {
      case 'excellent':
        return excellent;
      case 'very_good':
        return veryGood;
      case 'good':
        return good;
      case 'fair':
        return fair;
      case 'poor':
        return poor;
      case 'very_poor':
        return veryPoor;
      default:
        return quality;
    }
  }

  String getActivityText(String activity) {
    switch (activity.toLowerCase()) {
      case 'walking':
        return walking;
      case 'running':
        return running;
      case 'cycling':
        return cycling;
      case 'driving':
        return driving;
      case 'still':
        return still;
      case 'swimming':
        return swimming;
      case 'workout':
        return workout;
      case 'yoga':
        return yoga;
      case 'dancing':
        return dancing;
      case 'hiking':
        return hiking;
      case 'climbing':
        return climbing;
      default:
        return unknown;
    }
  }

  String getLocationText(String location) {
    switch (location.toLowerCase()) {
      case 'home':
        return home;
      case 'work':
        return work;
      case 'gym':
        return gym;
      case 'shopping':
        return shopping;
      case 'restaurant':
        return restaurant;
      case 'transport':
        return transport;
      case 'entertainment':
        return entertainment;
      case 'health':
        return health;
      case 'education':
        return education;
      case 'religion':
        return religion;
      case 'office':
        return office;
      case 'school':
        return school;
      case 'university':
        return university;
      case 'hospital':
        return hospital;
      case 'pharmacy':
        return pharmacy;
      case 'bank':
        return bank;
      case 'park':
        return park;
      case 'mall':
        return mall;
      case 'cafe':
        return cafe;
      default:
        return other;
    }
  }

  String getMealTypeText(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return breakfast;
      case 'lunch':
        return lunch;
      case 'dinner':
        return dinner;
      case 'snack':
        return snack;
      default:
        return mealType;
    }
  }

  String getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return active;
      case 'inactive':
        return inactive;
      case 'enabled':
        return enabled;
      case 'disabled':
        return disabled;
      case 'online':
        return online;
      case 'offline':
        return offline;
      case 'synced':
        return synced;
      case 'not_synced':
        return notSynced;
      case 'completed':
        return completed;
      case 'pending':
        return pending;
      case 'in_progress':
        return inProgress;
      case 'failed':
        return failed;
      default:
        return status;
    }
  }

  // Get text direction
  TextDirection get textDirection => _isRTL ? TextDirection.rtl : TextDirection.ltr;

  // Get text alignment
  TextAlign get textAlign => _isRTL ? TextAlign.right : TextAlign.left;

  // Get opposite text alignment
  TextAlign get oppositeTextAlign => _isRTL ? TextAlign.left : TextAlign.right;

  // Get leading alignment
  CrossAxisAlignment get leadingAlignment => _isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start;

  // Get trailing alignment
  CrossAxisAlignment get trailingAlignment => _isRTL ? CrossAxisAlignment.start : CrossAxisAlignment.end;

  // Get available languages
  List<Map<String, String>> get availableLanguages => [
    {'code': 'ar', 'name': 'العربية', 'nameEn': 'Arabic'},
    {'code': 'en', 'name': 'English', 'nameEn': 'English'},
  ];

  // Get relative time (ago)
  String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return isArabic ? 'منذ ${formatNumber(difference.inDays)} ${difference.inDays == 1 ? 'يوم' : 'أيام'}'
          : '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return isArabic ? 'منذ ${formatNumber(difference.inHours)} ${difference.inHours == 1 ? 'ساعة' : 'ساعات'}'
          : '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return isArabic ? 'منذ ${formatNumber(difference.inMinutes)} ${difference.inMinutes == 1 ? 'دقيقة' : 'دقائق'}'
          : '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return isArabic ? 'الآن' : 'Now';
    }
  }

  // Get greeting based on time
  String getTimeBasedGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return isArabic ? 'صباح الخير' : 'Good Morning';
    } else if (hour < 17) {
      return isArabic ? 'مساء الخير' : 'Good Afternoon';
    } else {
      return isArabic ? 'مساء الخير' : 'Good Evening';
    }
  }

  // Get day name
  String getDayName(DateTime date) {
    final days = isArabic
        ? ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت']
        : ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

    return days[date.weekday % 7];
  }

  // Get month name
  String getMonthName(DateTime date) {
    final months = isArabic
        ? ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر']
        : ['January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];

    return months[date.month - 1];
  }

  // Export localization settings
  Map<String, dynamic> exportLocalizationSettings() {
    return {
      'language_code': _locale.languageCode,
      'country_code': _locale.countryCode,
      'is_rtl': _isRTL,
    };
  }

  // Import localization settings
  Future<void> importLocalizationSettings(Map<String, dynamic> settings) async {
    try {
      final languageCode = settings['language_code'] as String?;
      if (languageCode != null) {
        await setLanguage(languageCode);
      }
    } catch (e) {
      debugPrint('Error importing localization settings: $e');
    }
  }
}