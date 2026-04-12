// lib/core/models/user_profile.dart

import 'dart:math';

import 'package:flutter/foundation.dart';

enum Gender {
  male,
  female,
  other
}

@immutable
class UserProfile {
  final String? id;
  final String? name;
  final int age;
  final Gender gender;
  final double height; // in centimeters
  final double weight; // in kilograms
  final double? stepLengthCalibration; // custom calibration factor
  final int dailyStepGoal;
  final double dailyCalorieGoal;
  final double dailyDistanceGoal; // هدف المسافة اليومية بالكيلومتر
  final double dailyCaloriesGoal; // هدف حرق السعرات اليومي
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    this.id,
    this.name,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    this.stepLengthCalibration,
    this.dailyStepGoal = 10000,
    this.dailyCalorieGoal = 2000.0,
    this.dailyDistanceGoal = 8.0,
    this.dailyCaloriesGoal = 500.0,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor for default profile
  factory UserProfile.defaultProfile() {
    final now = DateTime.now();
    return UserProfile(
      age: 30,
      gender: Gender.male,
      height: 170.0,
      weight: 70.0,
      dailyStepGoal: 10000,
      dailyCalorieGoal: 2000.0,
      dailyDistanceGoal: 8.0,
      dailyCaloriesGoal: 500.0,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Factory constructor from map
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id']?.toString(),
      name: map['name']?.toString(),
      age: map['age']?.toInt() ?? 30,
      gender: _parseGender(map['gender']?.toString()),
      height: map['height']?.toDouble() ?? 170.0,
      weight: map['weight']?.toDouble() ?? 70.0,
      stepLengthCalibration: map['step_length_calibration']?.toDouble(),
      dailyStepGoal: map['daily_step_goal']?.toInt() ?? 10000,
      dailyCalorieGoal: map['daily_calorie_goal']?.toDouble() ?? 2000.0,
      dailyDistanceGoal: map['daily_distance_goal']?.toDouble() ?? 8.0,
      dailyCaloriesGoal: map['daily_calories_goal']?.toDouble() ?? 500.0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updated_at'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  // Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender.name,
      'height': height,
      'weight': weight,
      'step_length_calibration': stepLengthCalibration,
      'daily_step_goal': dailyStepGoal,
      'daily_calorie_goal': dailyCalorieGoal,
      'daily_distance_goal': dailyDistanceGoal,
      'daily_calories_goal': dailyCaloriesGoal,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Copy with method
  UserProfile copyWith({
    String? id,
    String? name,
    int? age,
    Gender? gender,
    double? height,
    double? weight,
    double? stepLengthCalibration,
    int? dailyStepGoal,
    double? dailyCalorieGoal,
    double? dailyDistanceGoal,
    double? dailyCaloriesGoal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      stepLengthCalibration: stepLengthCalibration ?? this.stepLengthCalibration,
      dailyStepGoal: dailyStepGoal ?? this.dailyStepGoal,
      dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
      dailyDistanceGoal: dailyDistanceGoal ?? this.dailyDistanceGoal,
      dailyCaloriesGoal: dailyCaloriesGoal ?? this.dailyCaloriesGoal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Helper methods

  // Calculate BMI
  double get bmi => weight / pow(height / 100, 2);

  // BMI category
  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue < 18.5) return 'نحيف';
    if (bmiValue < 25) return 'طبيعي';
    if (bmiValue < 30) return 'زيادة وزن';
    return 'سمنة';
  }

  // Calculate ideal step length for walking (in meters)
  double get idealWalkingStepLength {
    if (stepLengthCalibration != null) {
      return (height * 0.43 * stepLengthCalibration!) / 100.0;
    }
    return (height * 0.43) / 100.0; // Default: height * 0.43 for walking
  }

  // Calculate ideal step length for running (in meters)
  double get idealRunningStepLength {
    if (stepLengthCalibration != null) {
      return (height * 0.45 * stepLengthCalibration!) / 100.0;
    }
    return (height * 0.45) / 100.0; // Default: height * 0.45 for running
  }

  // Calculate basal metabolic rate (BMR) using Mifflin-St Jeor equation
  double get basalMetabolicRate {
    switch (gender) {
      case Gender.male:
        return 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
      case Gender.female:
        return 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
      default:
      // Average of male and female
        final maleRate = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
        final femaleRate = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
        return (maleRate + femaleRate) / 2;
    }
  }

  // Calculate calories per step based on weight and activity
  double getCaloriesPerStep(String activityType) {
    double factor;
    switch (activityType.toLowerCase()) {
      case 'running':
        factor = 0.063; // Calories per step per kg for running
        break;
      case 'walking':
        factor = 0.04; // Calories per step per kg for walking
        break;
      default:
        factor = 0.035; // General activity
    }
    return weight * factor / 1000; // Convert to calories per step
  }

  // Get gender display name in Arabic
  String get genderDisplayName {
    switch (gender) {
      case Gender.male: return 'ذكر';
      case Gender.female: return 'أنثى';
      case Gender.other: return 'آخر';
    }
  }

  // Validate profile data
  bool get isValid {
    return age > 0 && age < 150 &&
        height > 50 && height < 300 &&
        weight > 20 && weight < 500 &&
        dailyStepGoal > 0 && dailyStepGoal <= 100000 &&
        dailyCalorieGoal > 0 && dailyCalorieGoal <= 10000 &&
        dailyDistanceGoal > 0 && dailyDistanceGoal <= 100 &&
        dailyCaloriesGoal > 0 && dailyCaloriesGoal <= 5000;
  }

  // Get validation errors
  List<String> get validationErrors {
    final errors = <String>[];

    if (age <= 0 || age >= 150) {
      errors.add('العمر يجب أن يكون بين 1 و 149 سنة');
    }

    if (height <= 50 || height >= 300) {
      errors.add('الطول يجب أن يكون بين 50 و 300 سنتيمتر');
    }

    if (weight <= 20 || weight >= 500) {
      errors.add('الوزن يجب أن يكون بين 20 و 500 كيلوجرام');
    }

    if (dailyStepGoal <= 0 || dailyStepGoal > 100000) {
      errors.add('هدف الخطوات اليومي يجب أن يكون بين 1 و 100000');
    }

    if (dailyCalorieGoal <= 0 || dailyCalorieGoal > 10000) {
      errors.add('هدف السعرات اليومي يجب أن يكون بين 1 و 10000');
    }

    if (dailyDistanceGoal <= 0 || dailyDistanceGoal > 100) {
      errors.add('هدف المسافة اليومي يجب أن يكون بين 1 و 100 كيلومتر');
    }

    if (dailyCaloriesGoal <= 0 || dailyCaloriesGoal > 5000) {
      errors.add('هدف حرق السعرات اليومي يجب أن يكون بين 1 و 5000');
    }

    return errors;
  }

  // Calculate recommended daily calorie intake
  double get recommendedDailyCalories {
    final bmr = basalMetabolicRate;
    // Multiply by activity factor (assuming moderate activity = 1.55)
    return bmr * 1.55;
  }

  // Check if step goal is realistic
  bool get isStepGoalRealistic {
    // Most people can achieve 3000-50000 steps per day
    return dailyStepGoal >= 3000 && dailyStepGoal <= 50000;
  }

  // Check if distance goal is realistic
  bool get isDistanceGoalRealistic {
    // Most people can achieve 1-50 km per day
    return dailyDistanceGoal >= 1.0 && dailyDistanceGoal <= 50.0;
  }

  // Check if calories goal is realistic
  bool get isCaloriesGoalRealistic {
    // Most people can burn 100-3000 calories per day through activity
    return dailyCaloriesGoal >= 100 && dailyCaloriesGoal <= 3000;
  }

  // Get step goal difficulty level
  String get stepGoalDifficulty {
    if (dailyStepGoal < 5000) return 'سهل';
    if (dailyStepGoal < 10000) return 'متوسط';
    if (dailyStepGoal < 15000) return 'صعب';
    return 'صعب جداً';
  }

  // Get distance goal difficulty level
  String get distanceGoalDifficulty {
    if (dailyDistanceGoal < 3.0) return 'سهل';
    if (dailyDistanceGoal < 8.0) return 'متوسط';
    if (dailyDistanceGoal < 15.0) return 'صعب';
    return 'صعب جداً';
  }

  // Get calories goal difficulty level
  String get caloriesGoalDifficulty {
    if (dailyCaloriesGoal < 200) return 'سهل';
    if (dailyCaloriesGoal < 500) return 'متوسط';
    if (dailyCaloriesGoal < 1000) return 'صعب';
    return 'صعب جداً';
  }

  // Calculate expected distance for step goal
  double get expectedDailyDistance {
    return dailyStepGoal * idealWalkingStepLength / 1000; // in kilometers
  }

  // Get profile completion percentage
  double get completionPercentage {
    double completion = 0.0;
    const totalFields = 8.0;

    // Required fields
    if (age > 0) completion += 1.0;
    if (height > 0) completion += 1.0;
    if (weight > 0) completion += 1.0;
    if (dailyStepGoal > 0) completion += 1.0;
    if (dailyDistanceGoal > 0) completion += 1.0;
    if (dailyCaloriesGoal > 0) completion += 1.0;

    // Optional fields
    if (name != null && name!.isNotEmpty) completion += 1.0;
    if (stepLengthCalibration != null) completion += 1.0;

    return (completion / totalFields) * 100;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserProfile &&
        other.id == id &&
        other.age == age &&
        other.gender == gender &&
        other.height == height &&
        other.weight == weight &&
        other.stepLengthCalibration == stepLengthCalibration &&
        other.dailyStepGoal == dailyStepGoal &&
        other.dailyCalorieGoal == dailyCalorieGoal &&
        other.dailyDistanceGoal == dailyDistanceGoal &&
        other.dailyCaloriesGoal == dailyCaloriesGoal;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      age,
      gender,
      height,
      weight,
      stepLengthCalibration,
      dailyStepGoal,
      dailyCalorieGoal,
      dailyDistanceGoal,
      dailyCaloriesGoal,
    );
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, age: $age, gender: ${gender.name}, '
        'height: ${height}cm, weight: ${weight}kg, '
        'stepGoal: $dailyStepGoal, distanceGoal: ${dailyDistanceGoal}km, '
        'caloriesGoal: ${dailyCaloriesGoal}cal, bmi: ${bmi.toStringAsFixed(1)})';
  }

  // Helper method to parse gender from string
  static Gender _parseGender(String? genderStr) {
    if (genderStr == null) return Gender.male;

    switch (genderStr.toLowerCase()) {
      case 'male':
      case 'ذكر':
        return Gender.male;
      case 'female':
      case 'أنثى':
        return Gender.female;
      case 'other':
      case 'آخر':
        return Gender.other;
      default:
        return Gender.male;
    }
  }
}

// Extension to add some utility methods
extension UserProfileExtension on UserProfile {
  // Quick profile summary
  String get summary => '${genderDisplayName}، ${age} سنة، ${height.round()}cm، ${weight.round()}kg';

  // Health status based on BMI
  String get healthStatus {
    final bmiValue = bmi;
    if (bmiValue < 18.5) return 'نحيف - يُنصح بزيادة الوزن';
    if (bmiValue < 25) return 'وزن طبيعي - ممتاز!';
    if (bmiValue < 30) return 'زيادة وزن - يُنصح بإنقاص الوزن';
    return 'سمنة - يُنصح بمراجعة طبيب';
  }

  // Goals summary
  String get goalsSummary => 'أهداف: ${dailyStepGoal} خطوة، ${dailyDistanceGoal}كم، ${dailyCaloriesGoal.round()} سعرة';

  // All goals difficulty summary
  String get goalsDifficultySummary => 'صعوبة الأهداف: خطوات ($stepGoalDifficulty)، مسافة ($distanceGoalDifficulty)، سعرات ($caloriesGoalDifficulty)';
}