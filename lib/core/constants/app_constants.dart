class AppConstants {
  // App Info
  static const String appName = 'Sleep Tracker';
  static const String appVersion = '1.0.0';

  // Database
  static const String dbName = 'sleep_tracker.db';
  static const int dbVersion = 1;

  // Tables
  static const String tableSleepSessions = 'sleep_sessions';
  static const String tablePhoneUsage = 'phone_usage';
  static const String tableActivityRecords = 'activity_records';
  static const String tableMealRecords = 'meal_records';
  static const String tableWeightRecords = 'weight_records';
  static const String tableLocationVisits = 'location_visits';

  // Shared Preferences Keys
  static const String keyIsFirstTime = 'is_first_time';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyLocationEnabled = 'location_enabled';
  static const String keyBackgroundEnabled = 'background_enabled';
  static const String keyUsageStatsEnabled = 'usage_stats_enabled';
  static const String keyAutoSleepDetection = 'auto_sleep_detection';
  static const String keyDailyStepsGoal = 'daily_steps_goal';
  static const String keyDailyCaloriesGoal = 'daily_calories_goal';
  static const String keyUserHeight = 'user_height';
  static const String keyUserAge = 'user_age';
  static const String keyUserGender = 'user_gender';

  // Sleep Detection
  static const int sleepDetectionIntervalMinutes = 5;
  static const int minSleepDurationMinutes = 60;
  static const int maxAwakeDurationMinutes = 30;
  static const double sleepMotionThreshold = 0.5;
  static const double sleepLightThreshold = 10.0;
  static const double sleepNoiseThreshold = 40.0;

  // Phone Usage
  static const int shortUsageLimitSeconds = 30;
  static const int mediumUsageLimitSeconds = 300; // 5 minutes
  static const int phoneUsageCheckIntervalSeconds = 10;

  // Activity Tracking
  static const int activityUpdateIntervalMinutes = 15;
  static const int locationUpdateIntervalMinutes = 30;
  static const double significantLocationChangeMeters = 100.0;
  static const int defaultStepsGoal = 10000;
  static const int defaultCaloriesGoal = 2000;

  // Background Tasks
  static const String taskSleepDetection = 'sleepDetection';
  static const String taskPhoneUsageTracking = 'phoneUsageTracking';
  static const String taskActivityTracking = 'activityTracking';
  static const String taskLocationTracking = 'locationTracking';

  // Notification IDs
  static const int notificationSleepStarted = 1;
  static const int notificationSleepEnded = 2;
  static const int notificationDailyReport = 3;
  static const int notificationStepsGoal = 4;
  static const int notificationBedtimeReminder = 5;

  // Chart Colors
  static const List<int> chartColors = [
    0xFF6C63FF, // Primary
    0xFF4CAF50, // Green
    0xFFFF9800, // Orange
    0xFFE91E63, // Pink
    0xFF2196F3, // Blue
    0xFF9C27B0, // Purple
    0xFF00BCD4, // Cyan
    0xFFFF5722, // Deep Orange
  ];

  // Sleep Quality Ranges
  static const Map<String, List<int>> sleepQualityRanges = {
    'excellent': [90, 100],
    'good': [70, 89],
    'fair': [50, 69],
    'poor': [0, 49],
  };

  // Activity Types
  static const List<String> activityTypes = [
    'walking',
    'running',
    'cycling',
    'driving',
    'still',
    'unknown',
  ];

  // Location Categories
  static const Map<String, List<String>> locationCategories = {
    'home': ['house', 'apartment', 'residence'],
    'work': ['office', 'workplace', 'company'],
    'gym': ['fitness', 'gym', 'sports'],
    'shopping': ['mall', 'market', 'store'],
    'restaurant': ['restaurant', 'cafe', 'food'],
    'transport': ['station', 'airport', 'bus'],
    'entertainment': ['cinema', 'park', 'club'],
    'health': ['hospital', 'clinic', 'pharmacy'],
    'education': ['school', 'university', 'library'],
    'religion': ['mosque', 'church', 'temple'],
  };

  // Meal Types
  static const List<String> mealTypes = [
    'breakfast',
    'lunch',
    'dinner',
    'snack',
  ];

  // Export Formats
  static const List<String> exportFormats = [
    'json',
    'csv',
  ];

  // Date Formats
  static const String dateFormatFull = 'yyyy-MM-dd HH:mm:ss';
  static const String dateFormatShort = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm';

  // Permissions
  static const List<String> requiredPermissions = [
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.ACCESS_COARSE_LOCATION',
    'android.permission.ACTIVITY_RECOGNITION',
    'android.permission.RECORD_AUDIO',
    'android.permission.CAMERA',
    'android.permission.WAKE_LOCK',
    'android.permission.FOREGROUND_SERVICE',
    'android.permission.PACKAGE_USAGE_STATS',
  ];
}

// Enums
enum SleepPhase {
  awake,
  lightSleep,
  deepSleep,
  rem,
}

enum PhoneUsageType {
  short,
  medium,
  long,
}

enum SleepQuality {
  excellent,
  good,
  fair,
  poor,
}

enum LocationCategory {
  home,
  work,
  gym,
  shopping,
  restaurant,
  transport,
  entertainment,
  health,
  education,
  religion,
  other,
}

enum MealType {
  breakfast,
  lunch,
  dinner,
  snack,
}

enum ChartType {
  line,
  bar,
  pie,
  area,
}

enum StatisticsPeriod {
  daily,
  weekly,
  monthly,
  yearly,
}