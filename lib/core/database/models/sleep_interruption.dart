import 'dart:convert';
import 'package:intl/intl.dart';

/// أنواع أسباب انقطاع النوم
enum InterruptionCause {
  phone,      // استخدام الهاتف
  movement,   // حركة قوية
  noise,      // ضجيج خارجي
  external,   // عامل خارجي (مكالمة، منبه)
  unknown     // غير معروف
}

/// Extension على InterruptionCause لإضافة وظائف مساعدة
extension InterruptionCauseExtension on InterruptionCause {
  /// تحويل سبب الانقطاع إلى نص عربي
  String toArabicString() {
    switch (this) {
      case InterruptionCause.phone:
        return 'استخدام الهاتف';
      case InterruptionCause.movement:
        return 'حركة';
      case InterruptionCause.noise:
        return 'ضجيج';
      case InterruptionCause.external:
        return 'عامل خارجي';
      case InterruptionCause.unknown:
        return 'غير محدد';
    }
  }

  /// تحويل من نص إلى enum
  static InterruptionCause fromString(String value) {
    switch (value.toLowerCase()) {
      case 'phone':
        return InterruptionCause.phone;
      case 'movement':
        return InterruptionCause.movement;
      case 'noise':
        return InterruptionCause.noise;
      case 'external':
        return InterruptionCause.external;
      default:
        return InterruptionCause.unknown;
    }
  }

  /// الحصول على أيقونة مناسبة للسبب
  String getIcon() {
    switch (this) {
      case InterruptionCause.phone:
        return '📱';
      case InterruptionCause.movement:
        return '🏃';
      case InterruptionCause.noise:
        return '🔊';
      case InterruptionCause.external:
        return '🔔';
      case InterruptionCause.unknown:
        return '❓';
    }
  }
}

/// نموذج لتتبع انقطاعات النوم وتحليلها
class SleepInterruption {
  final int? id;
  final int sleepSessionId;
  final DateTime interruptionStart;
  final DateTime? interruptionEnd;
  final Duration? duration;
  final InterruptionCause cause;
  final List<String>? phoneAppsUsed;
  final Map<String, dynamic>? usageDetails;
  final double recoveryQuality;
  final double impactOnSleep;
  final DateTime createdAt;

  SleepInterruption({
    this.id,
    required this.sleepSessionId,
    required this.interruptionStart,
    this.interruptionEnd,
    this.duration,
    this.cause = InterruptionCause.unknown,
    this.phoneAppsUsed,
    this.usageDetails,
    this.recoveryQuality = 0.0,
    this.impactOnSleep = 0.0,
    required this.createdAt,
  });

  // ==================== Named Constructors ====================

  /// تحويل من Map إلى SleepInterruption object
  factory SleepInterruption.fromMap(Map<String, dynamic> map) {
    return SleepInterruption(
      id: map['id'] as int?,
      sleepSessionId: map['sleep_session_id'] as int,
      interruptionStart: DateTime.fromMillisecondsSinceEpoch(
        map['interruption_start'] as int,
      ),
      interruptionEnd: map['interruption_end'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['interruption_end'] as int)
          : null,
      duration: map['duration'] != null
          ? Duration(seconds: map['duration'] as int)
          : null,
      cause: InterruptionCauseExtension.fromString(
        map['cause'] as String? ?? 'unknown',
      ),
      phoneAppsUsed: parseAppsUsed(map['phone_apps_used'] as String?),
      usageDetails: parseUsageDetails(map['usage_details'] as String?),
      recoveryQuality: (map['recovery_quality'] as num?)?.toDouble() ?? 0.0,
      impactOnSleep: (map['impact_on_sleep'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] as int,
      ),
    );
  }

  /// تحويل من JSON string إلى SleepInterruption object
  factory SleepInterruption.fromJson(String jsonString) {
    return SleepInterruption.fromMap(
      json.decode(jsonString) as Map<String, dynamic>,
    );
  }

  // ==================== دوال التحويل ====================

  /// تحويل SleepInterruption object إلى Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'sleep_session_id': sleepSessionId,
      'interruption_start': interruptionStart.millisecondsSinceEpoch,
      'interruption_end': interruptionEnd?.millisecondsSinceEpoch,
      'duration': duration?.inSeconds,
      'cause': cause.name,
      'phone_apps_used': encodeAppsUsed(phoneAppsUsed),
      'usage_details': encodeUsageDetails(usageDetails),
      'recovery_quality': recoveryQuality,
      'impact_on_sleep': impactOnSleep,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  /// تحويل SleepInterruption object إلى JSON string
  String toJson() {
    return json.encode(toMap());
  }

  // ==================== Computed Properties ====================

  /// هل الانقطاع نشط حالياً (لم ينتهِ)
  bool get isActive => interruptionEnd == null;

  /// المدة الفعلية للانقطاع
  Duration get actualDuration {
    if (duration != null) return duration!;

    final endTime = interruptionEnd ?? DateTime.now();
    return endTime.difference(interruptionStart);
  }

  /// الوقت منذ بداية الانقطاع
  Duration get timeSinceStart {
    return DateTime.now().difference(interruptionStart);
  }

  /// تنسيق المدة بشكل قابل للقراءة
  String get formattedDuration {
    final dur = actualDuration;
    final minutes = dur.inMinutes;
    final seconds = dur.inSeconds % 60;

    if (minutes == 0) {
      return '${seconds}s';
    } else if (seconds == 0) {
      return '${minutes}m';
    } else {
      return '${minutes}m ${seconds}s';
    }
  }

  /// هل الانقطاع متعلق باستخدام الهاتف
  bool get isPhoneRelated {
    return cause == InterruptionCause.phone || phoneAppsUsed != null;
  }

  /// هل تم استخدام تطبيقات
  bool get hasAppUsage {
    return phoneAppsUsed != null && phoneAppsUsed!.isNotEmpty;
  }

  /// عدد التطبيقات المستخدمة
  int get appCount => phoneAppsUsed?.length ?? 0;

  /// التطبيق الأساسي المستخدم (الأول في القائمة)
  String? get primaryApp => phoneAppsUsed?.first;

  /// هل انقطاع سريع (أقل من دقيقتين)
  bool get isQuickInterruption {
    return actualDuration.inMinutes < 2;
  }

  /// هل انقطاع طويل (أكثر من 15 دقيقة)
  bool get isLongInterruption {
    return actualDuration.inMinutes > 15;
  }

  /// مستوى خطورة الانقطاع
  String get severityLevel {
    final minutes = actualDuration.inMinutes;

    if (minutes < 2 && impactOnSleep < 0.3) {
      return 'خفيف';
    } else if (minutes < 10 && impactOnSleep < 0.6) {
      return 'متوسط';
    } else {
      return 'شديد';
    }
  }

  /// سرعة العودة للنوم
  String get recoverySpeed {
    if (recoveryQuality >= 0.8) {
      return 'سريعة جداً';
    } else if (recoveryQuality >= 0.6) {
      return 'سريعة';
    } else if (recoveryQuality >= 0.4) {
      return 'متوسطة';
    } else {
      return 'بطيئة';
    }
  }

  // ==================== دوال معالجة البيانات ====================

  /// تحويل JSON string إلى List<String>
  static List<String>? parseAppsUsed(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return null;

    try {
      final decoded = json.decode(jsonString);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// تحويل JSON string إلى Map<String, dynamic>
  static Map<String, dynamic>? parseUsageDetails(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return null;

    try {
      final decoded = json.decode(jsonString);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// تحويل List<String> إلى JSON string
  static String? encodeAppsUsed(List<String>? apps) {
    if (apps == null || apps.isEmpty) return null;
    return json.encode(apps);
  }

  /// تحويل Map إلى JSON string
  static String? encodeUsageDetails(Map<String, dynamic>? details) {
    if (details == null || details.isEmpty) return null;
    return json.encode(details);
  }

  /// إضافة تطبيق للقائمة
  SleepInterruption addAppUsed(String appName) {
    final currentApps = phoneAppsUsed ?? [];
    if (!currentApps.contains(appName)) {
      final newApps = [...currentApps, appName];
      return copyWith(phoneAppsUsed: newApps);
    }
    return this;
  }

  /// إضافة تفاصيل استخدام
  SleepInterruption addUsageDetail(String key, dynamic value) {
    final currentDetails = usageDetails ?? {};
    final newDetails = {...currentDetails, key: value};
    return copyWith(usageDetails: newDetails);
  }

  // ==================== دوال حساب التأثير ====================

  /// حساب سرعة العودة للنوم
  double calculateRecoveryQuality(Duration timeToSleep) {
    final minutes = timeToSleep.inMinutes;

    if (minutes < 1) {
      return 1.0;
    } else if (minutes < 2) {
      return 0.9;
    } else if (minutes < 5) {
      return 0.7;
    } else if (minutes < 10) {
      return 0.5;
    } else if (minutes < 15) {
      return 0.3;
    } else {
      return 0.1;
    }
  }

  /// حساب تأثير الانقطاع على جودة النوم
  double calculateImpactOnSleep() {
    // العوامل: مدة الانقطاع (40%)، نوع الانقطاع (30%)، سرعة العودة (30%)

    // تأثير المدة (0-1)
    final durationMinutes = actualDuration.inMinutes;
    final durationImpact = (durationMinutes / 20).clamp(0.0, 1.0);

    // تأثير نوع الانقطاع (0-1)
    final causeImpact = _getCauseImpactFactor();

    // تأثير سرعة العودة (0-1) - معكوس
    final recoveryImpact = 1.0 - recoveryQuality;

    // الحساب النهائي
    final totalImpact = (durationImpact * 0.4) +
        (causeImpact * 0.3) +
        (recoveryImpact * 0.3);

    return totalImpact.clamp(0.0, 1.0);
  }

  /// معامل تأثير حسب سبب الانقطاع
  double _getCauseImpactFactor() {
    switch (cause) {
      case InterruptionCause.phone:
        return 0.9;
      case InterruptionCause.external:
        return 0.7;
      case InterruptionCause.noise:
        return 0.6;
      case InterruptionCause.movement:
        return 0.5;
      case InterruptionCause.unknown:
        return 0.4;
    }
  }

  // ==================== دوال تحليلية ====================

  /// ملخص نصي عن الانقطاع
  String getInterruptionSummary() {
    final causeText = cause.toArabicString();
    final durationText = formattedDuration;

    String summary = 'انقطاع بسبب $causeText لمدة $durationText';

    if (hasAppUsage) {
      final apps = phoneAppsUsed!.take(3).join('، ');
      summary += '، التطبيقات: $apps';
      if (appCount > 3) {
        summary += ' وأخرى';
      }
    }

    return summary;
  }

  /// تحليل مفصل للانقطاع
  Map<String, dynamic> getDetailedAnalysis() {
    return {
      'cause_text': cause.toArabicString(),
      'cause_icon': cause.getIcon(),
      'duration_text': formattedDuration,
      'duration_minutes': actualDuration.inMinutes,
      'severity': severityLevel,
      'impact_text': 'تأثير ${(impactOnSleep * 100).toStringAsFixed(0)}%',
      'impact_value': impactOnSleep,
      'apps_used': phoneAppsUsed ?? [],
      'app_count': appCount,
      'recovery_text': recoverySpeed,
      'recovery_value': recoveryQuality,
      'is_active': isActive,
      'is_phone_related': isPhoneRelated,
      'recommendations': getRecommendations(),
      'start_time': formatStartTime(),
      'end_time': formatEndTime(),
      'time_range': formatTimeRange(),
    };
  }

  /// الحصول على توصيات بناءً على نوع الانقطاع
  List<String> getRecommendations() {
    final recommendations = <String>[];

    switch (cause) {
      case InterruptionCause.phone:
        recommendations.addAll([
          'ضع الهاتف بعيداً عن السرير',
          'فعّل وضع عدم الإزعاج',
          'استخدم منبه تقليدي بدلاً من الهاتف',
          'قلل من استخدام الهاتف قبل النوم بساعة',
        ]);
        break;
      case InterruptionCause.noise:
        recommendations.addAll([
          'استخدم سدادات أذن',
          'حسّن عزل الغرفة صوتياً',
          'استخدم جهاز الضوضاء البيضاء',
          'أغلق النوافذ والأبواب',
        ]);
        break;
      case InterruptionCause.movement:
        recommendations.addAll([
          'تجنب السوائل قبل النوم بساعتين',
          'استخدم فراش مريح',
          'مارس تمارين الاسترخاء',
          'تجنب الوجبات الثقيلة قبل النوم',
        ]);
        break;
      case InterruptionCause.external:
        recommendations.addAll([
          'أوقف المنبهات غير الضرورية',
          'اطلب من الآخرين عدم إزعاجك',
          'فعّل الرد الآلي للمكالمات',
        ]);
        break;
      case InterruptionCause.unknown:
        recommendations.addAll([
          'راقب أنماط نومك لتحديد السبب',
          'احتفظ بمفكرة نوم',
          'استشر طبيباً إذا استمرت المشكلة',
        ]);
        break;
    }

    // توصيات إضافية بناءً على خطورة الانقطاع
    if (isLongInterruption) {
      recommendations.add('هذا انقطاع طويل، حاول معالجة السبب الأساسي');
    }

    if (recoveryQuality < 0.3) {
      recommendations.add('تستغرق وقتاً طويلاً للعودة للنوم، جرب تقنيات الاسترخاء');
    }

    return recommendations;
  }

  // ==================== دالة copyWith ====================

  /// إنشاء نسخة جديدة مع تعديل بعض الخصائص
  SleepInterruption copyWith({
    int? id,
    int? sleepSessionId,
    DateTime? interruptionStart,
    DateTime? interruptionEnd,
    Duration? duration,
    InterruptionCause? cause,
    List<String>? phoneAppsUsed,
    Map<String, dynamic>? usageDetails,
    double? recoveryQuality,
    double? impactOnSleep,
    DateTime? createdAt,
  }) {
    return SleepInterruption(
      id: id ?? this.id,
      sleepSessionId: sleepSessionId ?? this.sleepSessionId,
      interruptionStart: interruptionStart ?? this.interruptionStart,
      interruptionEnd: interruptionEnd ?? this.interruptionEnd,
      duration: duration ?? this.duration,
      cause: cause ?? this.cause,
      phoneAppsUsed: phoneAppsUsed ?? this.phoneAppsUsed,
      usageDetails: usageDetails ?? this.usageDetails,
      recoveryQuality: recoveryQuality ?? this.recoveryQuality,
      impactOnSleep: impactOnSleep ?? this.impactOnSleep,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ==================== دوال Validation ====================

  /// التحقق من صحة البيانات
  bool isValid() {
    // التحقق من sleep_session_id
    if (sleepSessionId <= 0) return false;

    // التحقق من interruption_start
    if (interruptionStart == null) return false;

    // التحقق من أن interruption_end بعد interruption_start
    if (interruptionEnd != null &&
        interruptionEnd!.isBefore(interruptionStart)) {
      return false;
    }

    // التحقق من نطاق recovery_quality
    if (recoveryQuality < 0 || recoveryQuality > 1) return false;

    // التحقق من نطاق impact_on_sleep
    if (impactOnSleep < 0 || impactOnSleep > 1) return false;

    return true;
  }

  /// الحصول على قائمة الأخطاء
  List<String> getValidationErrors() {
    final errors = <String>[];

    if (sleepSessionId <= 0) {
      errors.add('معرف جلسة النوم غير صحيح');
    }

    if (interruptionEnd != null &&
        interruptionEnd!.isBefore(interruptionStart)) {
      errors.add('وقت النهاية يجب أن يكون بعد وقت البداية');
    }

    if (recoveryQuality < 0 || recoveryQuality > 1) {
      errors.add('قيمة جودة التعافي يجب أن تكون بين 0 و 1');
    }

    if (impactOnSleep < 0 || impactOnSleep > 1) {
      errors.add('قيمة التأثير على النوم يجب أن تكون بين 0 و 1');
    }

    return errors;
  }

  // ==================== دوال المقارنة والترتيب ====================

  /// مقارنة بين الانقطاعات للترتيب
  int compareTo(SleepInterruption other) {
    return interruptionStart.compareTo(other.interruptionStart);
  }

  @override
  String toString() {
    return 'SleepInterruption('
        'id: $id, '
        'cause: ${cause.toArabicString()}, '
        'duration: $formattedDuration, '
        'severity: $severityLevel, '
        'active: $isActive'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SleepInterruption &&
        other.id == id &&
        id != null;
  }

  @override
  int get hashCode => id.hashCode;

  // ==================== دوال Formatting ====================

  /// تنسيق وقت البداية
  String formatStartTime() {
    final formatter = DateFormat('hh:mm a', 'ar');
    return formatter.format(interruptionStart);
  }

  /// تنسيق وقت النهاية
  String formatEndTime() {
    if (interruptionEnd == null) return 'مستمر';
    final formatter = DateFormat('hh:mm a', 'ar');
    return formatter.format(interruptionEnd!);
  }

  /// تنسيق نطاق الوقت
  String formatTimeRange() {
    final start = formatStartTime();
    final end = formatEndTime();
    return '$start - $end';
  }
}