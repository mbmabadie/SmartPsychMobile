import 'dart:convert';

/// نموذج هدف النوم - يحتوي على جميع المعلومات المتعلقة بهدف النوم للمستخدم
class SleepGoal {
  // ============================================================================
  // Constants - المعايير الصحية للنوم حسب العمر
  // ============================================================================

  static const Map<String, Map<String, dynamic>> AGE_SLEEP_RECOMMENDATIONS = {
    'children': {
      'min_age': 6,
      'max_age': 13,
      'min_hours': 9,
      'max_hours': 11,
      'optimal': 10,
    },
    'teens': {
      'min_age': 14,
      'max_age': 17,
      'min_hours': 8,
      'max_hours': 10,
      'optimal': 9,
    },
    'young_adults': {
      'min_age': 18,
      'max_age': 25,
      'min_hours': 7,
      'max_hours': 9,
      'optimal': 8,
    },
    'adults': {
      'min_age': 26,
      'max_age': 64,
      'min_hours': 7,
      'max_hours': 9,
      'optimal': 8,
    },
    'seniors': {
      'min_age': 65,
      'max_age': 120,
      'min_hours': 7,
      'max_hours': 8,
      'optimal': 7.5,
    },
  };

  // ============================================================================
  // Properties - الخصائص الأساسية
  // ============================================================================

  final int? id;
  final int user_age;
  final double recommended_hours;
  final String? user_preferred_bedtime;
  final String? user_preferred_wakeup;
  final int sleep_window_start;
  final int sleep_window_end;
  final bool is_active;
  final DateTime created_at;
  final DateTime updated_at;

  // ============================================================================
  // Constructor
  // ============================================================================

  SleepGoal({
    this.id,
    required this.user_age,
    required this.recommended_hours,
    this.user_preferred_bedtime,
    this.user_preferred_wakeup,
    required this.sleep_window_start,
    required this.sleep_window_end,
    this.is_active = true,
    required this.created_at,
    required this.updated_at,
  });

  // ============================================================================
  // Named Constructors
  // ============================================================================

  /// إنشاء SleepGoal من Map
  factory SleepGoal.fromMap(Map<String, dynamic> map) {
    return SleepGoal(
      id: map['id'] as int?,
      user_age: map['user_age'] as int,
      recommended_hours: (map['recommended_hours'] as num).toDouble(),
      user_preferred_bedtime: map['user_preferred_bedtime'] as String?,
      user_preferred_wakeup: map['user_preferred_wakeup'] as String?,
      sleep_window_start: map['sleep_window_start'] as int,
      sleep_window_end: map['sleep_window_end'] as int,
      is_active: map['is_active'] == 1 || map['is_active'] == true,
      created_at: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updated_at: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  /// إنشاء SleepGoal من JSON string
  factory SleepGoal.fromJson(String source) {
    return SleepGoal.fromMap(json.decode(source) as Map<String, dynamic>);
  }

  /// إنشاء هدف نوم تلقائي بناءً على العمر
  factory SleepGoal.createFromAge(int age) {
    final recommendedHours = getRecommendedHoursByAge(age);
    final now = DateTime.now();

    // تحديد أوقات افتراضية معقولة حسب الفئة العمرية
    String defaultBedtime;
    String defaultWakeup;
    int windowStart;
    int windowEnd;

    if (age >= 6 && age <= 13) {
      // أطفال
      defaultBedtime = '21:00';
      defaultWakeup = '07:00';
      windowStart = 20;
      windowEnd = 8;
    } else if (age >= 14 && age <= 17) {
      // مراهقين
      defaultBedtime = '22:00';
      defaultWakeup = '07:00';
      windowStart = 21;
      windowEnd = 8;
    } else if (age >= 18 && age <= 64) {
      // شباب وبالغين
      defaultBedtime = '22:00';
      defaultWakeup = '06:00';
      windowStart = 21;
      windowEnd = 7;
    } else {
      // كبار السن
      defaultBedtime = '21:30';
      defaultWakeup = '05:30';
      windowStart = 20;
      windowEnd = 7;
    }

    return SleepGoal(
      user_age: age,
      recommended_hours: recommendedHours,
      user_preferred_bedtime: defaultBedtime,
      user_preferred_wakeup: defaultWakeup,
      sleep_window_start: windowStart,
      sleep_window_end: windowEnd,
      is_active: true,
      created_at: now,
      updated_at: now,
    );
  }

  // ============================================================================
  // Conversion Methods - دوال التحويل
  // ============================================================================

  /// تحويل SleepGoal إلى Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_age': user_age,
      'recommended_hours': recommended_hours,
      'user_preferred_bedtime': user_preferred_bedtime,
      'user_preferred_wakeup': user_preferred_wakeup,
      'sleep_window_start': sleep_window_start,
      'sleep_window_end': sleep_window_end,
      'is_active': is_active ? 1 : 0,
      'created_at': created_at.millisecondsSinceEpoch,
      'updated_at': updated_at.millisecondsSinceEpoch,
    };
  }

  /// تحويل SleepGoal إلى JSON string
  String toJson() => json.encode(toMap());

  // ============================================================================
  // Static Methods - دوال ثابتة للحسابات حسب العمر
  // ============================================================================

  /// الحصول على الساعات الموصى بها حسب العمر
  static double getRecommendedHoursByAge(int age) {
    for (var category in AGE_SLEEP_RECOMMENDATIONS.values) {
      if (age >= category['min_age'] && age <= category['max_age']) {
        return (category['optimal'] as num).toDouble();
      }
    }
    return 8.0; // القيمة الافتراضية
  }

  /// الحد الأدنى للساعات الموصى بها
  static double getMinRecommendedHours(int age) {
    for (var category in AGE_SLEEP_RECOMMENDATIONS.values) {
      if (age >= category['min_age'] && age <= category['max_age']) {
        return (category['min_hours'] as num).toDouble();
      }
    }
    return 7.0;
  }

  /// الحد الأقصى للساعات الموصى بها
  static double getMaxRecommendedHours(int age) {
    for (var category in AGE_SLEEP_RECOMMENDATIONS.values) {
      if (age >= category['min_age'] && age <= category['max_age']) {
        return (category['max_hours'] as num).toDouble();
      }
    }
    return 9.0;
  }

  /// الحصول على فئة العمر
  static String getAgeCategory(int age) {
    for (var entry in AGE_SLEEP_RECOMMENDATIONS.entries) {
      final category = entry.value;
      if (age >= category['min_age'] && age <= category['max_age']) {
        return entry.key;
      }
    }
    return 'adults';
  }

  /// الحصول على فئة العمر بالعربية
  static String getAgeCategoryArabic(int age) {
    final category = getAgeCategory(age);
    const Map<String, String> arabicNames = {
      'children': 'أطفال',
      'teens': 'مراهقين',
      'young_adults': 'شباب',
      'adults': 'بالغين',
      'seniors': 'كبار السن',
    };
    return arabicNames[category] ?? 'بالغين';
  }

  // ============================================================================
  // Computed Properties - الخصائص المحسوبة
  // ============================================================================

  /// مدة نافذة النوم
  Duration get sleepWindowDuration {
    int hours;
    if (sleep_window_end < sleep_window_start) {
      // النافذة تمتد لليوم التالي
      hours = (24 - sleep_window_start) + sleep_window_end;
    } else {
      hours = sleep_window_end - sleep_window_start;
    }
    return Duration(hours: hours);
  }

  /// تحويل وقت النوم المفضل إلى DateTime
  DateTime? get bedtimeDateTime {
    if (user_preferred_bedtime == null) return null;
    final parsed = parseTimeString(user_preferred_bedtime!);
    if (parsed == null) return null;

    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, parsed['hour']!, parsed['minute']!);
  }

  /// تحويل وقت الاستيقاظ المفضل إلى DateTime
  DateTime? get wakeupDateTime {
    if (user_preferred_wakeup == null) return null;
    final parsed = parseTimeString(user_preferred_wakeup!);
    if (parsed == null) return null;

    final bedtime = bedtimeDateTime;
    if (bedtime == null) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, parsed['hour']!, parsed['minute']!);
    }

    var wakeup = DateTime(bedtime.year, bedtime.month, bedtime.day, parsed['hour']!, parsed['minute']!);

    // إذا كان وقت الاستيقاظ أقل من وقت النوم، يعني في اليوم التالي
    if (wakeup.isBefore(bedtime)) {
      wakeup = wakeup.add(Duration(days: 1));
    }

    return wakeup;
  }

  /// المدة المفضلة للنوم
  Duration? get preferredSleepDuration {
    final bedtime = bedtimeDateTime;
    final wakeup = wakeupDateTime;
    if (bedtime == null || wakeup == null) return null;
    return wakeup.difference(bedtime);
  }

  /// تنسيق وقت النوم المفضل
  String get formattedBedtime {
    if (user_preferred_bedtime == null) return 'غير محدد';
    final parsed = parseTimeString(user_preferred_bedtime!);
    if (parsed == null) return 'غير محدد';
    return formatHourTo12Hour(parsed['hour']!);
  }

  /// تنسيق وقت الاستيقاظ المفضل
  String get formattedWakeup {
    if (user_preferred_wakeup == null) return 'غير محدد';
    final parsed = parseTimeString(user_preferred_wakeup!);
    if (parsed == null) return 'غير محدد';
    return formatHourTo12Hour(parsed['hour']!);
  }

  /// نص يصف نافذة النوم
  String get sleepWindowText {
    return 'من ${formatHourTo12Hour(sleep_window_start)} إلى ${formatHourTo12Hour(sleep_window_end)}';
  }

  /// هل ضمن النطاق الموصى به
  bool get isWithinRecommendedRange {
    final minHours = getMinRecommendedHours(user_age);
    final maxHours = getMaxRecommendedHours(user_age);
    return recommended_hours >= minHours && recommended_hours <= maxHours;
  }

  /// كم ساعة ينقص عن الحد الأدنى
  double get hoursShortOfMinimum {
    final minHours = getMinRecommendedHours(user_age);
    final shortage = minHours - recommended_hours;
    return shortage > 0 ? shortage : 0;
  }

  /// كم ساعة يزيد عن الحد الأقصى
  double get hoursOverMaximum {
    final maxHours = getMaxRecommendedHours(user_age);
    final excess = recommended_hours - maxHours;
    return excess > 0 ? excess : 0;
  }

  // ============================================================================
  // Time Validation Methods - دوال التحقق من الأوقات
  // ============================================================================

  /// التحقق هل الوقت المعطى ضمن نافذة النوم
  bool isWithinSleepWindow(DateTime time) {
    final hour = time.hour;
    return isWithinSleepWindowByHour(hour);
  }

  /// التحقق هل الساعة ضمن نافذة النوم
  bool isWithinSleepWindowByHour(int hour) {
    if (sleep_window_end < sleep_window_start) {
      // النافذة تمتد لليوم التالي
      return hour >= sleep_window_start || hour < sleep_window_end;
    } else {
      return hour >= sleep_window_start && hour < sleep_window_end;
    }
  }

  /// هل يجب بدء المراقبة المكثفة
  bool shouldStartIntensiveMonitoring(DateTime time) {
    final hour = time.hour;
    int monitoringStart = sleep_window_start - 1;
    if (monitoringStart < 0) monitoringStart = 23;

    if (sleep_window_end < sleep_window_start) {
      return hour >= monitoringStart || hour < sleep_window_end;
    } else {
      return hour >= monitoringStart && hour < sleep_window_end;
    }
  }

  /// الوقت المتبقي حتى موعد النوم المفضل
  Duration? getTimeUntilBedtime() {
    final bedtime = bedtimeDateTime;
    if (bedtime == null) return null;

    final now = DateTime.now();
    var target = bedtime;

    // إذا مر الوقت اليوم، احسب للغد
    if (target.isBefore(now)) {
      target = target.add(Duration(days: 1));
    }

    final difference = target.difference(now);
    return difference.isNegative ? null : difference;
  }

  /// الوقت المتبقي حتى موعد الاستيقاظ المفضل
  Duration? getTimeUntilWakeup() {
    final wakeup = wakeupDateTime;
    if (wakeup == null) return null;

    final now = DateTime.now();
    var target = wakeup;

    if (target.isBefore(now)) {
      target = target.add(Duration(days: 1));
    }

    final difference = target.difference(now);
    return difference.isNegative ? null : difference;
  }

  /// الوقت الذي مر منذ موعد النوم
  Duration? getTimeSinceBedtime() {
    final bedtime = bedtimeDateTime;
    if (bedtime == null) return null;

    final now = DateTime.now();
    var target = bedtime;

    // إذا كان الوقت في المستقبل، احسب من الأمس
    if (target.isAfter(now)) {
      target = target.subtract(Duration(days: 1));
    }

    final difference = now.difference(target);
    return difference.isNegative ? null : difference;
  }

  // ============================================================================
  // Achievement Methods - دوال تقييم تحقيق الهدف
  // ============================================================================

  /// حساب نسبة تحقيق الهدف
  double calculateAchievement(Duration actualSleepDuration) {
    final actualHours = actualSleepDuration.inMinutes / 60.0;
    return actualHours / recommended_hours;
  }

  /// هل تم تحقيق الهدف
  bool isGoalAchieved(Duration actualSleepDuration) {
    final actualHours = actualSleepDuration.inMinutes / 60.0;
    return actualHours >= recommended_hours;
  }

  /// مستوى تحقيق الهدف
  String getAchievementLevel(Duration actualSleepDuration) {
    final percentage = calculateAchievement(actualSleepDuration);

    if (percentage >= 1.0 && isWithinRecommendedRange) {
      return 'ممتاز';
    } else if (percentage >= 0.9) {
      return 'جيد';
    } else if (percentage >= 0.7) {
      return 'مقبول';
    } else {
      return 'ضعيف';
    }
  }

  /// حساب الدين أو الفائض في ساعات النوم
  Duration getSleepDebtOrSurplus(Duration actualSleepDuration) {
    final actualHours = actualSleepDuration.inMinutes / 60.0;
    final difference = actualHours - recommended_hours;
    return Duration(minutes: (difference * 60).round());
  }

  // ============================================================================
  // Analysis Methods - دوال التحليل والتوصيات
  // ============================================================================

  /// تقييم شامل لجودة النوم
  Map<String, dynamic> getSleepQualityAssessment(Duration actualSleepDuration) {
    final percentage = calculateAchievement(actualSleepDuration);
    final level = getAchievementLevel(actualSleepDuration);
    final withinRange = isWithinRecommendedRange;

    String recommendation;
    String emoji;

    if (level == 'ممتاز') {
      recommendation = 'نوم ممتاز! استمر على هذا النمط الصحي';
      emoji = '🌟';
    } else if (level == 'جيد') {
      recommendation = 'نوم جيد، حاول الوصول للهدف الكامل';
      emoji = '😊';
    } else if (level == 'مقبول') {
      recommendation = 'تحتاج لتحسين جودة نومك، حاول النوم مبكراً';
      emoji = '😐';
    } else {
      recommendation = 'نوم غير كافٍ! يجب زيادة ساعات النوم للحفاظ على صحتك';
      emoji = '😟';
    }

    return {
      'achievement_percentage': (percentage * 100).toStringAsFixed(1),
      'level': level,
      'within_range': withinRange,
      'recommendation': recommendation,
      'emoji': emoji,
    };
  }

  /// الحصول على توصيات عامة
  List<String> getRecommendations() {
    final recommendations = <String>[];

    if (user_preferred_bedtime != null) {
      recommendations.add('اذهب للنوم قبل $formattedBedtime بـ 30 دقيقة للاسترخاء');
    }

    recommendations.add('حافظ على نوم ${recommended_hours.toStringAsFixed(1)} ساعات يومياً');
    recommendations.add('تجنب الكافيين بعد الساعة 4 مساءً');
    recommendations.add('أطفئ جميع الشاشات قبل النوم بساعة');
    recommendations.add('حافظ على غرفة نوم مظلمة وباردة');
    recommendations.add('مارس الرياضة بانتظام لكن ليس قبل النوم مباشرة');

    if (user_age >= 6 && user_age <= 17) {
      recommendations.add('تجنب الواجبات المدرسية قبل النوم بساعتين');
      recommendations.add('اقرأ كتاباً أو استمع لقصة قبل النوم');
    } else if (user_age >= 65) {
      recommendations.add('تجنب القيلولة الطويلة في النهار');
      recommendations.add('تعرض لضوء الشمس في الصباح');
    }

    return recommendations;
  }

  /// جدول نوم شخصي مقترح
  Map<String, dynamic> getPersonalizedSleepSchedule() {
    final bedtime = user_preferred_bedtime ?? '22:00';
    final wakeup = user_preferred_wakeup ?? '06:00';

    final bedtimeParsed = parseTimeString(bedtime);
    final windDownHour = bedtimeParsed != null
        ? (bedtimeParsed['hour']! - 1 + 24) % 24
        : 21;
    final screenOffHour = bedtimeParsed != null
        ? (bedtimeParsed['hour']! - 1 + 24) % 24
        : 21;

    return {
      'suggested_bedtime': bedtime,
      'suggested_wakeup': wakeup,
      'wind_down_start': formatTimeString(windDownHour, 0),
      'screen_off_time': formatTimeString(screenOffHour, 30),
      'caffeine_cutoff': '16:00',
    };
  }

  // ============================================================================
  // Update Methods - دوال التحديث والتعديل
  // ============================================================================

  /// تعديل الهدف بناءً على عمر جديد
  SleepGoal adjustForAge(int newAge) {
    final newRecommendedHours = getRecommendedHoursByAge(newAge);
    return copyWith(
      user_age: newAge,
      recommended_hours: newRecommendedHours,
    );
  }

  /// تعديل نافذة النوم
  SleepGoal adjustSleepWindow(int newStart, int newEnd) {
    if (newStart < 0 || newStart > 23 || newEnd < 0 || newEnd > 23) {
      throw ArgumentError('يجب أن تكون الساعات بين 0-23');
    }

    return copyWith(
      sleep_window_start: newStart,
      sleep_window_end: newEnd,
    );
  }

  /// تحديد الأوقات المفضلة
  SleepGoal setPreferredTimes(String bedtime, String wakeup) {
    if (!validateTimeString(bedtime) || !validateTimeString(wakeup)) {
      throw ArgumentError('صيغة الوقت يجب أن تكون HH:mm');
    }

    return copyWith(
      user_preferred_bedtime: bedtime,
      user_preferred_wakeup: wakeup,
    );
  }

  /// تعديل الساعات الموصى بها يدوياً
  SleepGoal adjustRecommendedHours(double newHours) {
    if (newHours < 4 || newHours > 12) {
      throw ArgumentError('يجب أن تكون الساعات بين 4-12');
    }

    return copyWith(recommended_hours: newHours);
  }

  // ============================================================================
  // Parsing Methods - دوال التحليل والتنسيق
  // ============================================================================

  /// تحويل نص الوقت إلى hour و minute
  static Map<String, int>? parseTimeString(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length != 2) return null;

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        return null;
      }

      return {'hour': hour, 'minute': minute};
    } catch (e) {
      return null;
    }
  }

  /// تحويل hour و minute إلى نص
  static String formatTimeString(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// تحويل الساعة من 24 إلى 12 مع AM/PM بالعربية
  static String formatHourTo12Hour(int hour) {
    if (hour == 0) return '12 منتصف الليل';
    if (hour < 12) return '$hour صباحاً';
    if (hour == 12) return '12 ظهراً';
    return '${hour - 12} مساءً';
  }

  // ============================================================================
  // CopyWith Method
  // ============================================================================

  /// إنشاء نسخة جديدة مع تعديل بعض الخصائص
  SleepGoal copyWith({
    int? id,
    int? user_age,
    double? recommended_hours,
    String? user_preferred_bedtime,
    String? user_preferred_wakeup,
    int? sleep_window_start,
    int? sleep_window_end,
    bool? is_active,
    DateTime? created_at,
    DateTime? updated_at,
  }) {
    return SleepGoal(
      id: id ?? this.id,
      user_age: user_age ?? this.user_age,
      recommended_hours: recommended_hours ?? this.recommended_hours,
      user_preferred_bedtime: user_preferred_bedtime ?? this.user_preferred_bedtime,
      user_preferred_wakeup: user_preferred_wakeup ?? this.user_preferred_wakeup,
      sleep_window_start: sleep_window_start ?? this.sleep_window_start,
      sleep_window_end: sleep_window_end ?? this.sleep_window_end,
      is_active: is_active ?? this.is_active,
      created_at: created_at ?? this.created_at,
      updated_at: updated_at ?? DateTime.now(),
    );
  }

  // ============================================================================
  // Validation Methods - دوال التحقق
  // ============================================================================

  /// التحقق من صحة البيانات
  bool isValid() {
    return getValidationErrors().isEmpty;
  }

  /// الحصول على قائمة الأخطاء
  List<String> getValidationErrors() {
    final errors = <String>[];

    if (user_age < 1 || user_age > 120) {
      errors.add('العمر يجب أن يكون بين 1-120');
    }

    if (recommended_hours < 4 || recommended_hours > 14) {
      errors.add('الساعات الموصى بها يجب أن تكون بين 4-14');
    }

    if (sleep_window_start < 0 || sleep_window_start > 23) {
      errors.add('ساعة بداية النافذة يجب أن تكون بين 0-23');
    }

    if (sleep_window_end < 0 || sleep_window_end > 23) {
      errors.add('ساعة نهاية النافذة يجب أن تكون بين 0-23');
    }

    if (user_preferred_bedtime != null && !validateTimeString(user_preferred_bedtime!)) {
      errors.add('صيغة وقت النوم غير صحيحة');
    }

    if (user_preferred_wakeup != null && !validateTimeString(user_preferred_wakeup!)) {
      errors.add('صيغة وقت الاستيقاظ غير صحيحة');
    }

    return errors;
  }

  /// التحقق من صحة صيغة الوقت
  static bool validateTimeString(String? timeString) {
    if (timeString == null) return false;
    return parseTimeString(timeString) != null;
  }

  // ============================================================================
  // Comparison Methods - دوال المقارنة
  // ============================================================================

  @override
  String toString() {
    return 'SleepGoal(id: $id, age: $user_age, recommended: ${recommended_hours}h, window: $sleepWindowText, active: $is_active)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SleepGoal && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // ============================================================================
  // Additional Utility Methods - دوال إضافية مفيدة
  // ============================================================================

  /// ملخص نصي كامل عن الهدف
  String getGoalSummary() {
    return 'هدف النوم: ${recommended_hours.toStringAsFixed(1)} ساعات يومياً ($formattedBedtime - $formattedWakeup) للفئة العمرية: ${getAgeCategoryArabic(user_age)}';
  }

  /// معلومات تفصيلية عن الهدف
  Map<String, dynamic> getDetailedInfo() {
    final minHours = getMinRecommendedHours(user_age);
    final maxHours = getMaxRecommendedHours(user_age);

    return {
      'age_category': getAgeCategoryArabic(user_age),
      'recommended_range': '$minHours - $maxHours ساعات',
      'current_goal': '${recommended_hours.toStringAsFixed(1)} ساعات',
      'sleep_window': sleepWindowText,
      'preferred_schedule': user_preferred_bedtime != null
          ? '$formattedBedtime - $formattedWakeup'
          : 'غير محدد',
      'recommendations': getRecommendations(),
    };
  }

  /// هل الهدف قديم ويحتاج تحديث
  bool isOutdated() {
    final sixMonthsAgo = DateTime.now().subtract(Duration(days: 180));
    if (updated_at.isBefore(sixMonthsAgo)) {
      return true;
    }

    // التحقق من تغير الفئة العمرية
    final currentAge = user_age; // في التطبيق الفعلي، يجب حساب العمر الحالي من تاريخ الميلاد
    final currentCategory = getAgeCategory(currentAge);
    final goalCategory = getAgeCategory(user_age);

    return currentCategory != goalCategory;
  }

  /// هل يحتاج الهدف لتحديث بسبب تغير العمر
  bool needsAgeUpdate(int currentAge) {
    if (currentAge == user_age) return false;

    final currentCategory = getAgeCategory(currentAge);
    final goalCategory = getAgeCategory(user_age);

    return currentCategory != goalCategory;
  }
}