// lib/core/database/models/environmental_conditions.dart


/// نموذج البيانات البيئية المحيطة أثناء النوم
class EnvironmentalConditions {
  // ================================
  // المعرفات والتوقيت
  // ================================

  /// معرف السجل
  final int? id;

  /// معرف جلسة النوم المرتبطة
  final int? sleepSessionId;

  /// وقت التسجيل
  final DateTime timestamp;

  // ================================
  // بيانات الإضاءة
  // ================================

  /// مستوى الإضاءة (بوحدة lux)
  /// 0 = ظلام تام
  /// 1-10 = إضاءة خفيفة جداً
  /// 10-50 = إضاءة منخفضة
  /// 50-500 = إضاءة متوسطة
  /// 500+ = إضاءة ساطعة
  final double lightLevel;

  /// نوع مصدر الضوء
  final LightSourceType? lightSourceType;

  /// تصنيف جودة الإضاءة للنوم
  final LightQuality lightQuality;

  // ================================
  // بيانات الصوت
  // ================================

  /// مستوى الضوضاء (بوحدة ديسيبل dB)
  /// 0-30 dB = هادئ جداً (مثالي للنوم)
  /// 30-40 dB = هادئ
  /// 40-60 dB = ضوضاء معتدلة
  /// 60-80 dB = مزعج
  /// 80+ dB = مزعج جداً
  final double noiseLevel;

  /// أقصى ارتفاع في الضوضاء
  final double? noisePeak;

  /// نوع الضوضاء
  final NoiseType? noiseType;

  /// تصنيف جودة الصوت للنوم
  final NoiseQuality noiseQuality;

  // ================================
  // بيانات الحركة
  // ================================

  /// شدة الحركة (0.0 - 1.0)
  /// 0.0 = لا حركة
  /// 0.0-0.1 = حركة طفيفة جداً
  /// 0.1-0.3 = حركة خفيفة
  /// 0.3-0.6 = حركة متوسطة
  /// 0.6-1.0 = حركة عالية
  final double movementIntensity;

  /// عدد الحركات المكتشفة في هذه العينة
  final int? movementCount;

  /// نوع الحركة
  final MovementType? movementType;

  // ================================
  // بيانات درجة الحرارة
  // ================================

  /// درجة الحرارة (بالدرجة المئوية)
  /// 16-19°C = بارد
  /// 19-21°C = مثالي للنوم
  /// 21-24°C = دافئ
  /// 24+°C = حار
  final double? temperature;

  /// تصنيف جودة درجة الحرارة
  final TemperatureQuality? temperatureQuality;

  // ================================
  // بيانات الرطوبة
  // ================================

  /// نسبة الرطوبة (%)
  /// 0-30% = جاف جداً
  /// 30-40% = جاف
  /// 40-60% = مثالي
  /// 60-70% = رطب
  /// 70+% = رطب جداً
  final double? humidity;

  /// تصنيف جودة الرطوبة
  final HumidityQuality? humidityQuality;

  // ================================
  // بيانات إضافية
  // ================================

  /// جودة الهواء (0-100)
  /// 90-100 = ممتاز
  /// 70-89 = جيد
  /// 50-69 = متوسط
  /// 30-49 = سيئ
  /// 0-29 = سيئ جداً
  final double? airQuality;

  /// الضغط الجوي (hPa)
  final double? atmosphericPressure;

  /// مستوى ثاني أكسيد الكربون (ppm)
  final double? co2Level;

  // ================================
  // التقييمات والدرجات
  // ================================

  /// الدرجة الإجمالية لجودة البيئة (0-10)
  final double? overallScore;

  /// هل البيئة مثالية للنوم؟
  final bool isOptimalForSleep;

  /// ملاحظات إضافية
  final String? notes;

  // ================================
  // البيانات التقنية
  // ================================

  /// مصدر البيانات (sensor, manual, estimated)
  final DataSource dataSource;

  /// مستوى دقة البيانات (0-1)
  final double? accuracy;

  /// وقت الإنشاء
  final DateTime createdAt;

  const EnvironmentalConditions({
    this.id,
    this.sleepSessionId,
    required this.timestamp,
    required this.lightLevel,
    this.lightSourceType,
    required this.lightQuality,
    required this.noiseLevel,
    this.noisePeak,
    this.noiseType,
    required this.noiseQuality,
    required this.movementIntensity,
    this.movementCount,
    this.movementType,
    this.temperature,
    this.temperatureQuality,
    this.humidity,
    this.humidityQuality,
    this.airQuality,
    this.atmosphericPressure,
    this.co2Level,
    this.overallScore,
    required this.isOptimalForSleep,
    this.notes,
    this.dataSource = DataSource.sensor,
    this.accuracy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? timestamp;

  // ================================
  // Factory Constructors
  // ================================

  /// إنشاء شروط بيئية افتراضية (مثالية)
  factory EnvironmentalConditions.optimal({
    int? sleepSessionId,
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();
    return EnvironmentalConditions(
      sleepSessionId: sleepSessionId,
      timestamp: now,
      lightLevel: 0.0,
      lightQuality: LightQuality.optimal,
      noiseLevel: 25.0,
      noiseQuality: NoiseQuality.optimal,
      movementIntensity: 0.0,
      temperature: 20.0,
      temperatureQuality: TemperatureQuality.optimal,
      humidity: 50.0,
      humidityQuality: HumidityQuality.optimal,
      overallScore: 10.0,
      isOptimalForSleep: true,
      dataSource: DataSource.estimated,
      createdAt: now,
    );
  }

  /// إنشاء من بيانات الحساسات
  factory EnvironmentalConditions.fromSensors({
    int? sleepSessionId,
    required double lightLevel,
    required double noiseLevel,
    required double movementIntensity,
    double? temperature,
    double? humidity,
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();

    return EnvironmentalConditions(
      sleepSessionId: sleepSessionId,
      timestamp: now,
      lightLevel: lightLevel,
      lightQuality: _evaluateLightQuality(lightLevel),
      noiseLevel: noiseLevel,
      noiseQuality: _evaluateNoiseQuality(noiseLevel),
      movementIntensity: movementIntensity,
      temperature: temperature,
      temperatureQuality: temperature != null ? _evaluateTemperatureQuality(temperature) : null,
      humidity: humidity,
      humidityQuality: humidity != null ? _evaluateHumidityQuality(humidity) : null,
      overallScore: _calculateOverallScore(
        lightLevel: lightLevel,
        noiseLevel: noiseLevel,
        movementIntensity: movementIntensity,
        temperature: temperature,
        humidity: humidity,
      ),
      isOptimalForSleep: _checkIfOptimal(
        lightLevel: lightLevel,
        noiseLevel: noiseLevel,
        movementIntensity: movementIntensity,
        temperature: temperature,
        humidity: humidity,
      ),
      dataSource: DataSource.sensor,
      accuracy: 0.95,
      createdAt: now,
    );
  }

  // ================================
  // Getters المساعدة
  // ================================

  /// هل الإضاءة منخفضة بما يكفي؟
  bool get isLightLevelGood => lightLevel < 10.0;

  /// هل الضوضاء منخفضة بما يكفي؟
  bool get isNoiseLevelGood => noiseLevel < 40.0;

  /// هل الحركة منخفضة بما يكفي؟
  bool get isMovementLevelGood => movementIntensity < 0.1;

  /// هل درجة الحرارة مناسبة؟
  bool get isTemperatureGood => temperature != null && temperature! >= 18.0 && temperature! <= 22.0;

  /// هل الرطوبة مناسبة؟
  bool get isHumidityGood => humidity != null && humidity! >= 40.0 && humidity! <= 60.0;

  /// عدد العوامل المثالية
  int get optimalFactorsCount {
    int count = 0;
    if (isLightLevelGood) count++;
    if (isNoiseLevelGood) count++;
    if (isMovementLevelGood) count++;
    if (isTemperatureGood) count++;
    if (isHumidityGood) count++;
    return count;
  }

  /// نسبة العوامل المثالية
  double get optimalFactorsPercentage {
    int totalFactors = 3; // الأساسية: ضوء، صوت، حركة
    if (temperature != null) totalFactors++;
    if (humidity != null) totalFactors++;
    return (optimalFactorsCount / totalFactors) * 100;
  }

  /// وصف حالة البيئة
  String get environmentDescription {
    if (optimalFactorsPercentage >= 80) return 'بيئة مثالية للنوم';
    if (optimalFactorsPercentage >= 60) return 'بيئة جيدة للنوم';
    if (optimalFactorsPercentage >= 40) return 'بيئة متوسطة';
    if (optimalFactorsPercentage >= 20) return 'بيئة غير مناسبة';
    return 'بيئة سيئة للنوم';
  }

  // ================================
  // التحويل من/إلى Map
  // ================================

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (sleepSessionId != null) 'sleep_session_id': sleepSessionId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'light_level': lightLevel,
      'light_source_type': lightSourceType?.name,
      'light_quality': lightQuality.name,
      'noise_level': noiseLevel,
      'noise_peak': noisePeak,
      'noise_type': noiseType?.name,
      'noise_quality': noiseQuality.name,
      'movement_intensity': movementIntensity,
      'movement_count': movementCount,
      'movement_type': movementType?.name,
      'temperature': temperature,
      'temperature_quality': temperatureQuality?.name,
      'humidity': humidity,
      'humidity_quality': humidityQuality?.name,
      'air_quality': airQuality,
      'atmospheric_pressure': atmosphericPressure,
      'co2_level': co2Level,
      'overall_score': overallScore,
      'is_optimal_for_sleep': isOptimalForSleep ? 1 : 0,
      'notes': notes,
      'data_source': dataSource.name,
      'accuracy': accuracy,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory EnvironmentalConditions.fromMap(Map<String, dynamic> map) {
    return EnvironmentalConditions(
      id: map['id'] as int?,
      sleepSessionId: map['sleep_session_id'] as int?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      lightLevel: (map['light_level'] as num).toDouble(),
      lightSourceType: map['light_source_type'] != null
          ? LightSourceType.values.firstWhere(
            (e) => e.name == map['light_source_type'],
        orElse: () => LightSourceType.unknown,
      )
          : null,
      lightQuality: LightQuality.values.firstWhere(
            (e) => e.name == map['light_quality'],
        orElse: () => LightQuality.poor,
      ),
      noiseLevel: (map['noise_level'] as num).toDouble(),
      noisePeak: map['noise_peak'] != null ? (map['noise_peak'] as num).toDouble() : null,
      noiseType: map['noise_type'] != null
          ? NoiseType.values.firstWhere(
            (e) => e.name == map['noise_type'],
        orElse: () => NoiseType.unknown,
      )
          : null,
      noiseQuality: NoiseQuality.values.firstWhere(
            (e) => e.name == map['noise_quality'],
        orElse: () => NoiseQuality.poor,
      ),
      movementIntensity: (map['movement_intensity'] as num).toDouble(),
      movementCount: map['movement_count'] as int?,
      movementType: map['movement_type'] != null
          ? MovementType.values.firstWhere(
            (e) => e.name == map['movement_type'],
        orElse: () => MovementType.unknown,
      )
          : null,
      temperature: map['temperature'] != null ? (map['temperature'] as num).toDouble() : null,
      temperatureQuality: map['temperature_quality'] != null
          ? TemperatureQuality.values.firstWhere(
            (e) => e.name == map['temperature_quality'],
        orElse: () => TemperatureQuality.poor,
      )
          : null,
      humidity: map['humidity'] != null ? (map['humidity'] as num).toDouble() : null,
      humidityQuality: map['humidity_quality'] != null
          ? HumidityQuality.values.firstWhere(
            (e) => e.name == map['humidity_quality'],
        orElse: () => HumidityQuality.poor,
      )
          : null,
      airQuality: map['air_quality'] != null ? (map['air_quality'] as num).toDouble() : null,
      atmosphericPressure: map['atmospheric_pressure'] != null
          ? (map['atmospheric_pressure'] as num).toDouble()
          : null,
      co2Level: map['co2_level'] != null ? (map['co2_level'] as num).toDouble() : null,
      overallScore: map['overall_score'] != null ? (map['overall_score'] as num).toDouble() : null,
      isOptimalForSleep: (map['is_optimal_for_sleep'] as int) == 1,
      notes: map['notes'] as String?,
      dataSource: DataSource.values.firstWhere(
            (e) => e.name == map['data_source'],
        orElse: () => DataSource.sensor,
      ),
      accuracy: map['accuracy'] != null ? (map['accuracy'] as num).toDouble() : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  // ================================
  // دوال التقييم الثابتة
  // ================================

  static LightQuality _evaluateLightQuality(double lightLevel) {
    if (lightLevel <= 5) return LightQuality.optimal;
    if (lightLevel <= 15) return LightQuality.good;
    if (lightLevel <= 50) return LightQuality.fair;
    return LightQuality.poor;
  }

  static NoiseQuality _evaluateNoiseQuality(double noiseLevel) {
    if (noiseLevel <= 30) return NoiseQuality.optimal;
    if (noiseLevel <= 40) return NoiseQuality.good;
    if (noiseLevel <= 60) return NoiseQuality.fair;
    return NoiseQuality.poor;
  }

  static TemperatureQuality _evaluateTemperatureQuality(double temperature) {
    if (temperature >= 18 && temperature <= 22) return TemperatureQuality.optimal;
    if (temperature >= 16 && temperature <= 24) return TemperatureQuality.good;
    if (temperature >= 14 && temperature <= 26) return TemperatureQuality.fair;
    return TemperatureQuality.poor;
  }

  static HumidityQuality _evaluateHumidityQuality(double humidity) {
    if (humidity >= 40 && humidity <= 60) return HumidityQuality.optimal;
    if (humidity >= 30 && humidity <= 70) return HumidityQuality.good;
    if (humidity >= 20 && humidity <= 80) return HumidityQuality.fair;
    return HumidityQuality.poor;
  }

  static double _calculateOverallScore({
    required double lightLevel,
    required double noiseLevel,
    required double movementIntensity,
    double? temperature,
    double? humidity,
  }) {
    double score = 0.0;
    int factors = 0;

    // تقييم الضوء (0-10)
    score += (1 - (lightLevel / 100).clamp(0.0, 1.0)) * 10;
    factors++;

    // تقييم الضوضاء (0-10)
    score += (1 - (noiseLevel / 100).clamp(0.0, 1.0)) * 10;
    factors++;

    // تقييم الحركة (0-10)
    score += (1 - movementIntensity) * 10;
    factors++;

    // تقييم الحرارة (0-10)
    if (temperature != null) {
      double tempScore = 10.0;
      if (temperature < 18 || temperature > 22) {
        tempScore = (1 - ((temperature - 20).abs() / 10).clamp(0.0, 1.0)) * 10;
      }
      score += tempScore;
      factors++;
    }

    // تقييم الرطوبة (0-10)
    if (humidity != null) {
      double humScore = 10.0;
      if (humidity < 40 || humidity > 60) {
        humScore = (1 - ((humidity - 50).abs() / 50).clamp(0.0, 1.0)) * 10;
      }
      score += humScore;
      factors++;
    }

    return (score / factors).clamp(0.0, 10.0);
  }

  static bool _checkIfOptimal({
    required double lightLevel,
    required double noiseLevel,
    required double movementIntensity,
    double? temperature,
    double? humidity,
  }) {
    bool isOptimal = true;

    if (lightLevel > 10) isOptimal = false;
    if (noiseLevel > 40) isOptimal = false;
    if (movementIntensity > 0.1) isOptimal = false;
    if (temperature != null && (temperature < 18 || temperature > 22)) isOptimal = false;
    if (humidity != null && (humidity < 40 || humidity > 60)) isOptimal = false;

    return isOptimal;
  }

  // ================================
  // copyWith
  // ================================

  EnvironmentalConditions copyWith({
    int? id,
    int? sleepSessionId,
    DateTime? timestamp,
    double? lightLevel,
    LightSourceType? lightSourceType,
    LightQuality? lightQuality,
    double? noiseLevel,
    double? noisePeak,
    NoiseType? noiseType,
    NoiseQuality? noiseQuality,
    double? movementIntensity,
    int? movementCount,
    MovementType? movementType,
    double? temperature,
    TemperatureQuality? temperatureQuality,
    double? humidity,
    HumidityQuality? humidityQuality,
    double? airQuality,
    double? atmosphericPressure,
    double? co2Level,
    double? overallScore,
    bool? isOptimalForSleep,
    String? notes,
    DataSource? dataSource,
    double? accuracy,
    DateTime? createdAt,
  }) {
    return EnvironmentalConditions(
      id: id ?? this.id,
      sleepSessionId: sleepSessionId ?? this.sleepSessionId,
      timestamp: timestamp ?? this.timestamp,
      lightLevel: lightLevel ?? this.lightLevel,
      lightSourceType: lightSourceType ?? this.lightSourceType,
      lightQuality: lightQuality ?? this.lightQuality,
      noiseLevel: noiseLevel ?? this.noiseLevel,
      noisePeak: noisePeak ?? this.noisePeak,
      noiseType: noiseType ?? this.noiseType,
      noiseQuality: noiseQuality ?? this.noiseQuality,
      movementIntensity: movementIntensity ?? this.movementIntensity,
      movementCount: movementCount ?? this.movementCount,
      movementType: movementType ?? this.movementType,
      temperature: temperature ?? this.temperature,
      temperatureQuality: temperatureQuality ?? this.temperatureQuality,
      humidity: humidity ?? this.humidity,
      humidityQuality: humidityQuality ?? this.humidityQuality,
      airQuality: airQuality ?? this.airQuality,
      atmosphericPressure: atmosphericPressure ?? this.atmosphericPressure,
      co2Level: co2Level ?? this.co2Level,
      overallScore: overallScore ?? this.overallScore,
      isOptimalForSleep: isOptimalForSleep ?? this.isOptimalForSleep,
      notes: notes ?? this.notes,
      dataSource: dataSource ?? this.dataSource,
      accuracy: accuracy ?? this.accuracy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'EnvironmentalConditions('
        'light: ${lightLevel.toStringAsFixed(1)} lux [${lightQuality.name}], '
        'noise: ${noiseLevel.toStringAsFixed(1)} dB [${noiseQuality.name}], '
        'movement: ${(movementIntensity * 100).toStringAsFixed(0)}%, '
        'score: ${overallScore?.toStringAsFixed(1) ?? 'N/A'})';
  }
}

// ================================
// Enums
// ================================

/// نوع مصدر الضوء
enum LightSourceType {
  natural,      // طبيعي (شمس، قمر)
  artificial,   // اصطناعي (مصابيح)
  screen,       // شاشة (هاتف، تلفاز)
  streetLight,  // إنارة الشارع
  mixed,        // مختلط
  unknown,      // غير معروف
}

/// جودة الإضاءة
enum LightQuality {
  optimal,  // مثالية (0-5 lux)
  good,     // جيدة (5-15 lux)
  fair,     // مقبولة (15-50 lux)
  poor,     // سيئة (50+ lux)
}

/// نوع الضوضاء
enum NoiseType {
  traffic,      // مرور
  conversation, // محادثات
  music,        // موسيقى
  snoring,      // شخير
  appliances,   // أجهزة منزلية
  nature,       // طبيعة
  construction, // بناء
  unknown,      // غير معروف
}

/// جودة الصوت
enum NoiseQuality {
  optimal,  // مثالية (0-30 dB)
  good,     // جيدة (30-40 dB)
  fair,     // مقبولة (40-60 dB)
  poor,     // سيئة (60+ dB)
}

/// نوع الحركة
enum MovementType {
  none,         // لا حركة
  minimal,      // حد أدنى
  tossing,      // تقلب
  restless,     // قلق
  getUp,        // نهوض
  unknown,      // غير معروف
}

/// جودة درجة الحرارة
enum TemperatureQuality {
  optimal,  // مثالية (18-22°C)
  good,     // جيدة (16-24°C)
  fair,     // مقبولة (14-26°C)
  poor,     // سيئة (خارج النطاق)
}

/// جودة الرطوبة
enum HumidityQuality {
  optimal,  // مثالية (40-60%)
  good,     // جيدة (30-70%)
  fair,     // مقبولة (20-80%)
  poor,     // سيئة (خارج النطاق)
}

/// مصدر البيانات
enum DataSource {
  sensor,    // من الحساسات
  manual,    // إدخال يدوي
  estimated, // تقديري
}