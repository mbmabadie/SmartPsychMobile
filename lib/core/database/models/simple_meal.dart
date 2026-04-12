// lib/core/database/models/simple_meal.dart
import 'package:flutter/foundation.dart';

/// نموذج وجبة مبسط
@immutable
class SimpleMeal {
  final int? id;
  final String name;
  final String mealType; // breakfast, lunch, dinner, snack
  final DateTime mealTime;
  final String date; // YYYY-MM-DD
  final double? calories;
  final String? notes;
  final DateTime createdAt;

  const SimpleMeal({
    this.id,
    required this.name,
    required this.mealType,
    required this.mealTime,
    required this.date,
    this.calories,
    this.notes,
    required this.createdAt,
  });

  factory SimpleMeal.fromMap(Map<String, dynamic> map) {
    return SimpleMeal(
      id: map['id'] as int?,
      name: map['name'] as String,
      mealType: map['meal_type'] as String,
      mealTime: DateTime.fromMillisecondsSinceEpoch(map['meal_time'] as int),
      date: map['date'] as String,
      calories: map['calories'] != null ? (map['calories'] as num).toDouble() : null,
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'meal_type': mealType,
      'meal_time': mealTime.millisecondsSinceEpoch,
      'date': date,
      'calories': calories,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  /// نسخ مع تعديل
  SimpleMeal copyWith({
    int? id,
    String? name,
    String? mealType,
    DateTime? mealTime,
    String? date,
    double? calories,
    String? notes,
  }) {
    return SimpleMeal(
      id: id ?? this.id,
      name: name ?? this.name,
      mealType: mealType ?? this.mealType,
      mealTime: mealTime ?? this.mealTime,
      date: date ?? this.date,
      calories: calories ?? this.calories,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  /// اسم نوع الوجبة باللغة العربية
  String get mealTypeDisplayName {
    switch (mealType) {
      case 'breakfast':
        return 'فطار';
      case 'lunch':
        return 'غداء';
      case 'dinner':
        return 'عشاء';
      case 'snack':
        return 'سناك';
      default:
        return mealType;
    }
  }

  /// الوقت منسق
  String get formattedTime {
    final hour = mealTime.hour;
    final minute = mealTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// السعرات منسقة
  String get formattedCalories {
    if (calories == null) return 'غير محدد';
    return '${calories!.round()} سعرة';
  }

  /// تحقق من صحة البيانات
  bool get isValid {
    return name.trim().isNotEmpty &&
        ['breakfast', 'lunch', 'dinner', 'snack'].contains(mealType) &&
        date.isNotEmpty;
  }

  /// هل الوجبة اليوم؟
  bool get isToday {
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return date == todayString;
  }

  /// فترة الوجبة (صباح، ظهر، مساء)
  String get mealPeriod {
    final hour = mealTime.hour;
    if (hour >= 5 && hour < 11) return 'صباح';
    if (hour >= 11 && hour < 16) return 'ظهر';
    if (hour >= 16 && hour < 22) return 'مساء';
    return 'ليل';
  }

  /// رمز الوجبة
  String get mealIcon {
    switch (mealType) {
      case 'breakfast':
        return '🍳';
      case 'lunch':
        return '🍽️';
      case 'dinner':
        return '🌙';
      case 'snack':
        return '🍿';
      default:
        return '🍴';
    }
  }

  /// لون الوجبة
  String get mealColorHex {
    switch (mealType) {
      case 'breakfast':
        return '#FFA726'; // برتقالي فاتح
      case 'lunch':
        return '#66BB6A'; // أخضر
      case 'dinner':
        return '#5C6BC0'; // بنفسجي
      case 'snack':
        return '#FFCA28'; // أصفر
      default:
        return '#9E9E9E'; // رمادي
    }
  }

  /// مدى صحة الوجبة (بناءً على السعرات ووقت اليوم)
  String get healthLevel {
    if (calories == null) return 'غير محدد';

    final hour = mealTime.hour;
    double expectedCalories = 0;

    switch (mealType) {
      case 'breakfast':
        expectedCalories = 400; // فطار صحي
        break;
      case 'lunch':
        expectedCalories = 600; // غداء صحي
        break;
      case 'dinner':
        expectedCalories = 500; // عشاء صحي
        break;
      case 'snack':
        expectedCalories = 150; // سناك صحي
        break;
    }

    final ratio = calories! / expectedCalories;

    if (ratio <= 0.7) return 'خفيف';
    if (ratio <= 1.3) return 'صحي';
    if (ratio <= 1.8) return 'مشبع';
    return 'كثير';
  }

  /// توقيت الوجبة مناسب؟
  bool get isTimingAppropriate {
    final hour = mealTime.hour;

    switch (mealType) {
      case 'breakfast':
        return hour >= 5 && hour <= 11;
      case 'lunch':
        return hour >= 11 && hour <= 16;
      case 'dinner':
        return hour >= 16 && hour <= 22;
      case 'snack':
        return true; // السناك في أي وقت
      default:
        return true;
    }
  }

  @override
  String toString() {
    return 'SimpleMeal(name: $name, type: $mealType, time: $formattedTime, calories: $formattedCalories)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SimpleMeal &&
        other.id == id &&
        other.name == name &&
        other.mealTime == mealTime &&
        other.date == date;
  }

  @override
  int get hashCode => Object.hash(id, name, mealTime, date);
}

/// نوع الوجبة
enum MealType {
  breakfast('breakfast', 'فطار', '🍳'),
  lunch('lunch', 'غداء', '🍽️'),
  dinner('dinner', 'عشاء', '🌙'),
  snack('snack', 'سناك', '🍿');

  const MealType(this.value, this.displayName, this.icon);

  final String value;
  final String displayName;
  final String icon;

  static MealType fromString(String value) {
    return MealType.values.firstWhere(
          (type) => type.value == value,
      orElse: () => MealType.snack,
    );
  }

  /// الحصول على نوع الوجبة المناسب حسب الوقت
  static MealType getAppropriateType(DateTime time) {
    final hour = time.hour;

    if (hour >= 5 && hour < 11) return MealType.breakfast;
    if (hour >= 11 && hour < 16) return MealType.lunch;
    if (hour >= 16 && hour < 22) return MealType.dinner;
    return MealType.snack;
  }
}

/// ملخص الوجبات اليومي
class DailyMealsSummary {
  final String date;
  final List<SimpleMeal> meals;
  final int totalMealsCount;
  final double totalCalories;
  final Map<String, int> mealTypeCounts;

  DailyMealsSummary({
    required this.date,
    required this.meals,
  }) : totalMealsCount = meals.length,
        totalCalories = meals.where((m) => m.calories != null)
            .fold(0.0, (sum, m) => sum + m.calories!),
        mealTypeCounts = _calculateMealTypeCounts(meals);

  static Map<String, int> _calculateMealTypeCounts(List<SimpleMeal> meals) {
    final counts = <String, int>{
      'breakfast': 0,
      'lunch': 0,
      'dinner': 0,
      'snack': 0,
    };

    for (final meal in meals) {
      counts[meal.mealType] = (counts[meal.mealType] ?? 0) + 1;
    }

    return counts;
  }

  /// هل تم تناول وجبة معينة؟
  bool hasMealType(MealType type) {
    return mealTypeCounts[type.value]! > 0;
  }

  /// عدد الوجبات المتبقية لليوم
  int get remainingMeals {
    const targetMeals = 4; // فطار + غداء + عشاء + سناك
    return (targetMeals - totalMealsCount).clamp(0, targetMeals);
  }

  /// نسبة تحقق هدف الوجبات
  double get mealsCompletionRatio {
    const targetMeals = 4;
    return (totalMealsCount / targetMeals).clamp(0.0, 1.0);
  }

  /// متوسط السعرات للوجبة
  double get averageCaloriesPerMeal {
    final mealsWithCalories = meals.where((m) => m.calories != null).length;
    if (mealsWithCalories == 0) return 0.0;
    return totalCalories / mealsWithCalories;
  }

  /// أكثر أنواع الوجبات
  String get mostFrequentMealType {
    String mostFrequent = 'snack';
    int maxCount = 0;

    for (final entry in mealTypeCounts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostFrequent = entry.key;
      }
    }

    return mostFrequent;
  }

  /// النقص في الوجبات الأساسية
  List<MealType> get missingEssentialMeals {
    final missing = <MealType>[];

    if (!hasMealType(MealType.breakfast)) missing.add(MealType.breakfast);
    if (!hasMealType(MealType.lunch)) missing.add(MealType.lunch);
    if (!hasMealType(MealType.dinner)) missing.add(MealType.dinner);

    return missing;
  }

  @override
  String toString() {
    return 'DailyMealsSummary(date: $date, meals: $totalMealsCount, calories: ${totalCalories.round()})';
  }
}