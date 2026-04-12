// lib/core/models/goal_type.dart - ملف موحد لـ GoalType

/// نوع الهدف - مستخدم في جميع أنحاء التطبيق
enum GoalType {
  // أهداف النشاط البدني
  steps,           // الخطوات
  distance,        // المسافة
  duration,        // المدة الزمنية
  calories,        // السعرات المحروقة

  // أهداف التغذية
  meals,           // عدد الوجبات
  breakfast,       // وجبة الإفطار
  lunch,           // وجبة الغداء
  dinner,          // وجبة العشاء
}

/// امتداد لإضافة خصائص مفيدة لـ GoalType
extension GoalTypeExtension on GoalType {
  /// اسم الهدف بالعربية
  String get displayName {
    switch (this) {
      case GoalType.steps:
        return 'الخطوات';
      case GoalType.distance:
        return 'المسافة';
      case GoalType.duration:
        return 'المدة الزمنية';
      case GoalType.calories:
        return 'السعرات المحروقة';
      case GoalType.meals:
        return 'عدد الوجبات';
      case GoalType.breakfast:
        return 'وجبة الإفطار';
      case GoalType.lunch:
        return 'وجبة الغداء';
      case GoalType.dinner:
        return 'وجبة العشاء';
    }
  }

  /// وحدة القياس
  String get unit {
    switch (this) {
      case GoalType.steps:
        return 'خطوة';
      case GoalType.distance:
        return 'كم';
      case GoalType.duration:
        return 'دقيقة';
      case GoalType.calories:
        return 'سعرة';
      case GoalType.meals:
      case GoalType.breakfast:
      case GoalType.lunch:
      case GoalType.dinner:
        return 'وجبة';
    }
  }

  /// هل هذا هدف نشاط بدني؟
  bool get isActivityGoal {
    switch (this) {
      case GoalType.steps:
      case GoalType.distance:
      case GoalType.duration:
      case GoalType.calories:
        return true;
      case GoalType.meals:
      case GoalType.breakfast:
      case GoalType.lunch:
      case GoalType.dinner:
        return false;
    }
  }

  /// هل هذا هدف تغذية؟
  bool get isNutritionGoal {
    return !isActivityGoal;
  }

  /// القيمة الافتراضية للهدف
  double get defaultTarget {
    switch (this) {
      case GoalType.steps:
        return 10000.0;
      case GoalType.distance:
        return 8.0;
      case GoalType.duration:
        return 60.0;
      case GoalType.calories:
        return 500.0;
      case GoalType.meals:
        return 4.0;
      case GoalType.breakfast:
      case GoalType.lunch:
      case GoalType.dinner:
        return 1.0;
    }
  }

  /// أيقونة الهدف
  String get icon {
    switch (this) {
      case GoalType.steps:
        return '👟';
      case GoalType.distance:
        return '📍';
      case GoalType.duration:
        return '⏱️';
      case GoalType.calories:
        return '🔥';
      case GoalType.meals:
        return '🍽️';
      case GoalType.breakfast:
        return '☀️';
      case GoalType.lunch:
        return '🌞';
      case GoalType.dinner:
        return '🌙';
    }
  }
}