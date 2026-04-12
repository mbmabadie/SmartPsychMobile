// lib/core/models/nutrition_models.dart
enum MealType { breakfast, lunch, dinner, snack }
enum WeightUnit { kg, lbs }

class Meal {
  final int? id;
  final String date; // YYYY-MM-DD format
  final MealType mealType;
  final DateTime mealTime;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final String? moodBefore;
  final String? moodAfter;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<MealFood> foods;

  const Meal({
    this.id,
    required this.date,
    required this.mealType,
    required this.mealTime,
    this.totalCalories = 0.0,
    this.totalProtein = 0.0,
    this.totalCarbs = 0.0,
    this.totalFat = 0.0,
    this.moodBefore,
    this.moodAfter,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.foods = const [],
  });

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'] as int?,
      date: map['date'] as String,
      mealType: MealType.values.firstWhere((e) => e.name == map['meal_type']),
      mealTime: DateTime.fromMillisecondsSinceEpoch(map['meal_time'] as int),
      totalCalories: (map['total_calories'] as num?)?.toDouble() ?? 0.0,
      totalProtein: (map['total_protein'] as num?)?.toDouble() ?? 0.0,
      totalCarbs: (map['total_carbs'] as num?)?.toDouble() ?? 0.0,
      totalFat: (map['total_fat'] as num?)?.toDouble() ?? 0.0,
      moodBefore: map['mood_before'] as String?,
      moodAfter: map['mood_after'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'meal_type': mealType.name,
      'meal_time': mealTime.millisecondsSinceEpoch,
      'total_calories': totalCalories,
      'total_protein': totalProtein,
      'total_carbs': totalCarbs,
      'total_fat': totalFat,
      'mood_before': moodBefore,
      'mood_after': moodAfter,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  Meal copyWith({
    int? id,
    String? date,
    MealType? mealType,
    DateTime? mealTime,
    double? totalCalories,
    double? totalProtein,
    double? totalCarbs,
    double? totalFat,
    String? moodBefore,
    String? moodAfter,
    String? notes,
    DateTime? updatedAt,
    List<MealFood>? foods,
  }) {
    return Meal(
      id: id ?? this.id,
      date: date ?? this.date,
      mealType: mealType ?? this.mealType,
      mealTime: mealTime ?? this.mealTime,
      totalCalories: totalCalories ?? this.totalCalories,
      totalProtein: totalProtein ?? this.totalProtein,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      totalFat: totalFat ?? this.totalFat,
      moodBefore: moodBefore ?? this.moodBefore,
      moodAfter: moodAfter ?? this.moodAfter,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      foods: foods ?? this.foods,
    );
  }

  @override
  String toString() {
    return 'Meal(type: $mealType, time: $mealTime, calories: ${totalCalories.round()}, foods: ${foods.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Meal &&
        other.id == id &&
        other.date == date &&
        other.mealType == mealType;
  }

  @override
  int get hashCode => Object.hash(id, date, mealType);
}

class MealFood {
  final int? id;
  final int mealId;
  final String foodName;
  final double quantity;
  final String unit;
  final double caloriesPerUnit;
  final double proteinPerUnit;
  final double carbsPerUnit;
  final double fatPerUnit;
  final DateTime createdAt;

  const MealFood({
    this.id,
    required this.mealId,
    required this.foodName,
    required this.quantity,
    required this.unit,
    this.caloriesPerUnit = 0.0,
    this.proteinPerUnit = 0.0,
    this.carbsPerUnit = 0.0,
    this.fatPerUnit = 0.0,
    required this.createdAt,
  });

  factory MealFood.fromMap(Map<String, dynamic> map) {
    return MealFood(
      id: map['id'] as int?,
      mealId: map['meal_id'] as int,
      foodName: map['food_name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      caloriesPerUnit: (map['calories_per_unit'] as num?)?.toDouble() ?? 0.0,
      proteinPerUnit: (map['protein_per_unit'] as num?)?.toDouble() ?? 0.0,
      carbsPerUnit: (map['carbs_per_unit'] as num?)?.toDouble() ?? 0.0,
      fatPerUnit: (map['fat_per_unit'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'meal_id': mealId,
      'food_name': foodName,
      'quantity': quantity,
      'unit': unit,
      'calories_per_unit': caloriesPerUnit,
      'protein_per_unit': proteinPerUnit,
      'carbs_per_unit': carbsPerUnit,
      'fat_per_unit': fatPerUnit,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  MealFood copyWith({
    int? id,
    int? mealId,
    String? foodName,
    double? quantity,
    String? unit,
    double? caloriesPerUnit,
    double? proteinPerUnit,
    double? carbsPerUnit,
    double? fatPerUnit,
  }) {
    return MealFood(
      id: id ?? this.id,
      mealId: mealId ?? this.mealId,
      foodName: foodName ?? this.foodName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      caloriesPerUnit: caloriesPerUnit ?? this.caloriesPerUnit,
      proteinPerUnit: proteinPerUnit ?? this.proteinPerUnit,
      carbsPerUnit: carbsPerUnit ?? this.carbsPerUnit,
      fatPerUnit: fatPerUnit ?? this.fatPerUnit,
      createdAt: createdAt,
    );
  }

  // حسابات إجمالية
  double get totalCalories => quantity * caloriesPerUnit;
  double get totalProtein => quantity * proteinPerUnit;
  double get totalCarbs => quantity * carbsPerUnit;
  double get totalFat => quantity * fatPerUnit;

  @override
  String toString() {
    return 'MealFood(food: $foodName, qty: $quantity$unit, calories: ${totalCalories.round()})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MealFood &&
        other.id == id &&
        other.mealId == mealId &&
        other.foodName == foodName;
  }

  @override
  int get hashCode => Object.hash(id, mealId, foodName);
}

class WeightEntry {
  final int? id;
  final String date; // YYYY-MM-DD format
  final double weight;
  final WeightUnit unit;
  final double? bodyFatPercentage;
  final double? muscleMass;
  final String? notes;
  final DateTime createdAt;

  const WeightEntry({
    this.id,
    required this.date,
    required this.weight,
    this.unit = WeightUnit.kg,
    this.bodyFatPercentage,
    this.muscleMass,
    this.notes,
    required this.createdAt,
  });

  factory WeightEntry.fromMap(Map<String, dynamic> map) {
    return WeightEntry(
      id: map['id'] as int?,
      date: map['date'] as String,
      weight: (map['weight'] as num).toDouble(),
      unit: WeightUnit.values.firstWhere(
            (e) => e.name == map['unit'],
        orElse: () => WeightUnit.kg,
      ),
      bodyFatPercentage: map['body_fat_percentage'] != null
          ? (map['body_fat_percentage'] as num).toDouble()
          : null,
      muscleMass: map['muscle_mass'] != null
          ? (map['muscle_mass'] as num).toDouble()
          : null,
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'weight': weight,
      'unit': unit.name,
      'body_fat_percentage': bodyFatPercentage,
      'muscle_mass': muscleMass,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  WeightEntry copyWith({
    int? id,
    String? date,
    double? weight,
    WeightUnit? unit,
    double? bodyFatPercentage,
    double? muscleMass,
    String? notes,
  }) {
    return WeightEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      unit: unit ?? this.unit,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
      muscleMass: muscleMass ?? this.muscleMass,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  // تحويل الوزن إلى وحدات مختلفة
  double get weightInKg => unit == WeightUnit.kg ? weight : weight * 0.453592;
  double get weightInLbs => unit == WeightUnit.lbs ? weight : weight * 2.20462;

  @override
  String toString() {
    return 'WeightEntry(date: $date, weight: $weight${unit.name}, bodyFat: $bodyFatPercentage%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeightEntry &&
        other.id == id &&
        other.date == date;
  }

  @override
  int get hashCode => Object.hash(id, date);
}

// النماذج الناقصة: WaterIntake و FoodItem

/// Water Intake class - فئة استهلاك الماء
class WaterIntake {
  final int? id;
  final double amount; // بالمللي لتر
  final DateTime timestamp;
  final String date; // YYYY-MM-DD format
  final String? notes;
  final DateTime createdAt;

  const WaterIntake({
    this.id,
    required this.amount,
    required this.timestamp,
    required this.date,
    this.notes,
    required this.createdAt,
  });

  factory WaterIntake.fromMap(Map<String, dynamic> map) {
    return WaterIntake(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      date: map['date'] as String,
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'date': date,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  WaterIntake copyWith({
    int? id,
    double? amount,
    DateTime? timestamp,
    String? date,
    String? notes,
  }) {
    return WaterIntake(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  // Computed properties
  double get amountInLiters => amount / 1000; // تحويل لليتر
  String get formattedAmount => '${amount.round()} مل';
  String get formattedAmountInLiters => '${amountInLiters.toStringAsFixed(1)} L';

  @override
  String toString() {
    return 'WaterIntake(amount: $formattedAmount, time: ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WaterIntake &&
        other.id == id &&
        other.date == date &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => Object.hash(id, date, timestamp);
}

/// Food Item class - فئة عنصر الطعام
class FoodItem {
  final int? id;
  final String name;
  final String? brand;
  final double calories; // لكل 100g
  final double protein; // لكل 100g
  final double carbohydrates; // لكل 100g
  final double fats; // لكل 100g
  final double fiber; // لكل 100g
  final double sugar; // لكل 100g
  final double sodium; // لكل 100g بالمليجرام
  final String? category;
  final String? barcode;
  final bool isCustom; // هل أضافه المستخدم؟
  final DateTime createdAt;
  final DateTime updatedAt;

  const FoodItem({
    this.id,
    required this.name,
    this.brand,
    required this.calories,
    this.protein = 0.0,
    this.carbohydrates = 0.0,
    this.fats = 0.0,
    this.fiber = 0.0,
    this.sugar = 0.0,
    this.sodium = 0.0,
    this.category,
    this.barcode,
    this.isCustom = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      brand: map['brand'] as String?,
      calories: (map['calories'] as num).toDouble(),
      protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
      carbohydrates: (map['carbohydrates'] as num?)?.toDouble() ?? 0.0,
      fats: (map['fats'] as num?)?.toDouble() ?? 0.0,
      fiber: (map['fiber'] as num?)?.toDouble() ?? 0.0,
      sugar: (map['sugar'] as num?)?.toDouble() ?? 0.0,
      sodium: (map['sodium'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] as String?,
      barcode: map['barcode'] as String?,
      isCustom: (map['is_custom'] as int?) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'calories': calories,
      'protein': protein,
      'carbohydrates': carbohydrates,
      'fats': fats,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'category': category,
      'barcode': barcode,
      'is_custom': isCustom ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  FoodItem copyWith({
    int? id,
    String? name,
    String? brand,
    double? calories,
    double? protein,
    double? carbohydrates,
    double? fats,
    double? fiber,
    double? sugar,
    double? sodium,
    String? category,
    String? barcode,
    bool? isCustom,
    DateTime? updatedAt,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbohydrates: carbohydrates ?? this.carbohydrates,
      fats: fats ?? this.fats,
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
      sodium: sodium ?? this.sodium,
      category: category ?? this.category,
      barcode: barcode ?? this.barcode,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Computed properties
  String get displayName => brand != null ? '$name ($brand)' : name;

  String get formattedCalories => '${calories.round()} سعرة/100g';
  String get formattedProtein => '${protein.toStringAsFixed(1)}g بروتين/100g';
  String get formattedCarbs => '${carbohydrates.toStringAsFixed(1)}g كربوهيدرات/100g';
  String get formattedFats => '${fats.toStringAsFixed(1)}g دهون/100g';

  // Nutrition density calculations
  double get proteinPerCalorie => calories > 0 ? protein / calories : 0.0;
  double get fiberPerCalorie => calories > 0 ? fiber / calories : 0.0;

  bool get isHighProtein => proteinPerCalorie > 0.15; // أكثر من 15% بروتين
  bool get isHighFiber => fiber > 3.0; // أكثر من 3g ألياف لكل 100g
  bool get isLowSodium => sodium < 140; // أقل من 140mg صوديوم

  // Calculate nutrition for specific quantity
  FoodNutrition calculateForQuantity(double grams) {
    final multiplier = grams / 100.0;
    return FoodNutrition(
      calories: calories * multiplier,
      protein: protein * multiplier,
      carbohydrates: carbohydrates * multiplier,
      fats: fats * multiplier,
      fiber: fiber * multiplier,
      sugar: sugar * multiplier,
      sodium: sodium * multiplier,
    );
  }

  @override
  String toString() {
    return 'FoodItem(name: $name, calories: ${calories.round()}/100g, brand: $brand)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FoodItem &&
        other.name == name &&
        other.brand == brand &&
        other.calories == calories;
  }

  @override
  int get hashCode => Object.hash(name, brand, calories);
}

/// Food Nutrition calculation result - نتيجة حساب التغذية
class FoodNutrition {
  final double calories;
  final double protein;
  final double carbohydrates;
  final double fats;
  final double fiber;
  final double sugar;
  final double sodium;

  const FoodNutrition({
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fats,
    required this.fiber,
    required this.sugar,
    required this.sodium,
  });

  @override
  String toString() {
    return 'FoodNutrition(calories: ${calories.round()}, protein: ${protein.toStringAsFixed(1)}g)';
  }
}

/// تحديث Meal class لتدعم foodItems بدلاً من foods
extension MealWithFoodItems on Meal {
  List<FoodItem> get foodItems {
    // تحويل MealFood إلى FoodItem للتوافق
    return foods.map((mealFood) => FoodItem(
      name: mealFood.foodName,
      calories: mealFood.caloriesPerUnit,
      protein: mealFood.proteinPerUnit,
      carbohydrates: mealFood.carbsPerUnit,
      fats: mealFood.fatPerUnit,
      createdAt: mealFood.createdAt,
      updatedAt: mealFood.createdAt,
    )).toList();
  }

  // إضافة دالة لحساب إجمالي المغذيات باستخدام المعادلات الصحيحة
  double get calculatedTotalCalories => foods.fold(0.0, (sum, food) => sum + food.totalCalories);
  double get calculatedTotalProtein => foods.fold(0.0, (sum, food) => sum + food.totalProtein);
  double get calculatedTotalCarbs => foods.fold(0.0, (sum, food) => sum + food.totalCarbs);
  double get calculatedTotalFat => foods.fold(0.0, (sum, food) => sum + food.totalFat);
}