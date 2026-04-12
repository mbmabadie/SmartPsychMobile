import 'dart:convert';

/// نموذج البيانات البيئية
/// يحتوي على جميع القياسات البيئية التي تؤثر على جودة النوم
class EnvironmentalData {
  /// معرّف فريد للقياس
  final String id;

  /// وقت القياس
  final DateTime timestamp;

  /// مستوى الإضاءة (lux)
  /// 0 = ظلام تام، 100+ = إضاءة عالية
  final double lightLevel;

  /// مستوى الضجيج (decibels)
  /// 0-30 = هادئ جداً، 30-50 = هادئ، 50+ = مزعج
  final double noiseLevel;

  /// درجة الحرارة (Celsius)
  /// المثالي للنوم: 18-22 درجة
  final double temperature;

  /// نسبة الرطوبة (%)
  /// المثالي: 40-60%
  final double humidity;

  /// ضغط الهواء (hPa/mbar) - اختياري
  final double? pressure;

  /// جودة الهواء (AQI) - اختياري
  /// 0-50 = جيد، 51-100 = متوسط، 101+ = سيء
  final int? airQuality;

  /// معدل الحركة المكتشفة
  final double? movementLevel;

  /// معرّف جلسة النوم المرتبطة - اختياري
  final String? sleepSessionId;

  EnvironmentalData({
    String? id,
    required this.timestamp,
    required this.lightLevel,
    required this.noiseLevel,
    required this.temperature,
    required this.humidity,
    this.pressure,
    this.airQuality,
    this.movementLevel,
    this.sleepSessionId,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  // ============ Getters للتقييمات ============

  /// تقييم مستوى الإضاءة
  /// Returns: 'optimal', 'acceptable', 'poor'
  String get lightLevelAssessment {
    if (lightLevel <= 10) return 'optimal';
    if (lightLevel <= 50) return 'acceptable';
    return 'poor';
  }

  /// تقييم مستوى الضجيج
  String get noiseLevelAssessment {
    if (noiseLevel <= 30) return 'optimal';
    if (noiseLevel <= 45) return 'acceptable';
    return 'poor';
  }

  /// تقييم درجة الحرارة
  String get temperatureAssessment {
    if (temperature >= 18 && temperature <= 22) return 'optimal';
    if (temperature >= 16 && temperature <= 24) return 'acceptable';
    return 'poor';
  }

  /// تقييم الرطوبة
  String get humidityAssessment {
    if (humidity >= 40 && humidity <= 60) return 'optimal';
    if (humidity >= 30 && humidity <= 70) return 'acceptable';
    return 'poor';
  }

  /// تقييم جودة الهواء
  String get airQualityAssessment {
    if (airQuality == null) return 'unknown';
    if (airQuality! <= 50) return 'optimal';
    if (airQuality! <= 100) return 'acceptable';
    return 'poor';
  }

  /// نسبة الجودة الكلية للبيئة (0.0 - 1.0)
  double get overallQualityScore {
    double score = 0.0;
    int factors = 0;

    // تقييم الإضاءة (25%)
    if (lightLevel <= 10) {
      score += 0.25;
    } else if (lightLevel <= 50) {
      score += 0.25 * (1 - (lightLevel - 10) / 40);
    }
    factors++;

    // تقييم الضجيج (25%)
    if (noiseLevel <= 30) {
      score += 0.25;
    } else if (noiseLevel <= 50) {
      score += 0.25 * (1 - (noiseLevel - 30) / 20);
    }
    factors++;

    // تقييم الحرارة (25%)
    if (temperature >= 18 && temperature <= 22) {
      score += 0.25;
    } else if (temperature >= 16 && temperature <= 24) {
      final deviation = temperature < 18 ? 18 - temperature : temperature - 22;
      score += 0.25 * (1 - deviation / 4);
    }
    factors++;

    // تقييم الرطوبة (15%)
    if (humidity >= 40 && humidity <= 60) {
      score += 0.15;
    } else if (humidity >= 30 && humidity <= 70) {
      final deviation = humidity < 40 ? 40 - humidity : humidity - 60;
      score += 0.15 * (1 - deviation / 20);
    }
    factors++;

    // تقييم جودة الهواء (10%) - إذا متوفر
    if (airQuality != null) {
      if (airQuality! <= 50) {
        score += 0.10;
      } else if (airQuality! <= 100) {
        score += 0.10 * (1 - (airQuality! - 50) / 50);
      }
      factors++;
    }

    return score;
  }

  /// هل البيئة مثالية للنوم؟
  bool get isOptimalForSleep {
    return lightLevel <= 10 &&
        noiseLevel <= 30 &&
        temperature >= 18 &&
        temperature <= 22 &&
        humidity >= 40 &&
        humidity <= 60;
  }

  /// هل البيئة مقبولة للنوم؟
  bool get isAcceptableForSleep {
    return lightLevel <= 50 &&
        noiseLevel <= 45 &&
        temperature >= 16 &&
        temperature <= 24 &&
        humidity >= 30 &&
        humidity <= 70;
  }

  /// وصف الحالة البيئية
  String get environmentDescription {
    final List<String> issues = [];

    if (lightLevel > 50) {
      issues.add('الإضاءة عالية');
    } else if (lightLevel > 10) {
      issues.add('الإضاءة متوسطة');
    }

    if (noiseLevel > 45) {
      issues.add('الضجيج مرتفع');
    } else if (noiseLevel > 30) {
      issues.add('الضجيج متوسط');
    }

    if (temperature < 18) {
      issues.add('الحرارة منخفضة');
    } else if (temperature > 22) {
      issues.add('الحرارة مرتفعة');
    }

    if (humidity < 40) {
      issues.add('الرطوبة منخفضة');
    } else if (humidity > 60) {
      issues.add('الرطوبة مرتفعة');
    }

    if (airQuality != null && airQuality! > 100) {
      issues.add('جودة الهواء سيئة');
    }

    if (issues.isEmpty) {
      return 'البيئة مثالية للنوم';
    } else {
      return 'مشاكل: ${issues.join('، ')}';
    }
  }

  /// توصيات لتحسين البيئة
  List<String> get recommendations {
    final List<String> recommendations = [];

    if (lightLevel > 50) {
      recommendations.add('🌙 أطفئ الأضواء أو استخدم ستائر معتمة');
    } else if (lightLevel > 10) {
      recommendations.add('💡 خفف الإضاءة قدر الإمكان');
    }

    if (noiseLevel > 45) {
      recommendations.add('🔇 قلل مصادر الضجيج أو استخدم سماعات عزل الصوت');
    } else if (noiseLevel > 30) {
      recommendations.add('🎵 استخدم الضوضاء البيضاء لإخفاء الأصوات');
    }

    if (temperature < 18) {
      recommendations.add('🌡️ ارفع درجة الحرارة قليلاً (المثالي: 18-22°C)');
    } else if (temperature > 22) {
      recommendations.add('❄️ خفض درجة الحرارة (المثالي: 18-22°C)');
    }

    if (humidity < 40) {
      recommendations.add('💧 استخدم مرطب هواء لزيادة الرطوبة');
    } else if (humidity > 60) {
      recommendations.add('🌬️ استخدم مزيل رطوبة أو افتح النافذة');
    }

    if (airQuality != null && airQuality! > 100) {
      recommendations.add('🍃 استخدم منقي هواء أو افتح النافذة للتهوية');
    }

    if (recommendations.isEmpty) {
      recommendations.add('✅ البيئة ممتازة! استمر في الحفاظ على هذه الظروف');
    }

    return recommendations;
  }

  // ============ Copy With ============

  EnvironmentalData copyWith({
    String? id,
    DateTime? timestamp,
    double? lightLevel,
    double? noiseLevel,
    double? temperature,
    double? humidity,
    double? pressure,
    int? airQuality,
    double? movementLevel,
    String? sleepSessionId,
  }) {
    return EnvironmentalData(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      lightLevel: lightLevel ?? this.lightLevel,
      noiseLevel: noiseLevel ?? this.noiseLevel,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      pressure: pressure ?? this.pressure,
      airQuality: airQuality ?? this.airQuality,
      movementLevel: movementLevel ?? this.movementLevel,
      sleepSessionId: sleepSessionId ?? this.sleepSessionId,
    );
  }

  // ============ JSON Serialization ============

  /// تحويل إلى Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'lightLevel': lightLevel,
      'noiseLevel': noiseLevel,
      'temperature': temperature,
      'humidity': humidity,
      'pressure': pressure,
      'airQuality': airQuality,
      'movementLevel': movementLevel,
      'sleepSessionId': sleepSessionId,
    };
  }

  /// تحويل إلى JSON String
  String toJson() => json.encode(toMap());

  /// إنشاء من Map
  factory EnvironmentalData.fromMap(Map<String, dynamic> map) {
    return EnvironmentalData(
      id: map['id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      lightLevel: (map['lightLevel'] as num).toDouble(),
      noiseLevel: (map['noiseLevel'] as num).toDouble(),
      temperature: (map['temperature'] as num).toDouble(),
      humidity: (map['humidity'] as num).toDouble(),
      pressure: map['pressure'] != null ? (map['pressure'] as num).toDouble() : null,
      airQuality: map['airQuality'] as int?,
      movementLevel: map['movementLevel'] != null
          ? (map['movementLevel'] as num).toDouble()
          : null,
      sleepSessionId: map['sleepSessionId'] as String?,
    );
  }

  /// إنشاء من JSON String
  factory EnvironmentalData.fromJson(String source) =>
      EnvironmentalData.fromMap(json.decode(source) as Map<String, dynamic>);

  // ============ Comparison ============

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EnvironmentalData &&
        other.id == id &&
        other.timestamp == timestamp &&
        other.lightLevel == lightLevel &&
        other.noiseLevel == noiseLevel &&
        other.temperature == temperature &&
        other.humidity == humidity &&
        other.pressure == pressure &&
        other.airQuality == airQuality &&
        other.movementLevel == movementLevel &&
        other.sleepSessionId == sleepSessionId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    timestamp.hashCode ^
    lightLevel.hashCode ^
    noiseLevel.hashCode ^
    temperature.hashCode ^
    humidity.hashCode ^
    pressure.hashCode ^
    airQuality.hashCode ^
    movementLevel.hashCode ^
    sleepSessionId.hashCode;
  }

  @override
  String toString() {
    return 'EnvironmentalData('
        'id: $id, '
        'timestamp: $timestamp, '
        'light: ${lightLevel.toStringAsFixed(1)} lux, '
        'noise: ${noiseLevel.toStringAsFixed(1)} dB, '
        'temp: ${temperature.toStringAsFixed(1)}°C, '
        'humidity: ${humidity.toStringAsFixed(1)}%, '
        'quality: ${overallQualityScore.toStringAsFixed(2)}'
        ')';
  }

  // ============ Static Helper Methods ============

  /// حساب المتوسط لمجموعة من البيانات
  static EnvironmentalData average(List<EnvironmentalData> dataList) {
    if (dataList.isEmpty) {
      throw ArgumentError('Cannot calculate average of empty list');
    }

    final avgLight = dataList.map((e) => e.lightLevel).reduce((a, b) => a + b) / dataList.length;
    final avgNoise = dataList.map((e) => e.noiseLevel).reduce((a, b) => a + b) / dataList.length;
    final avgTemp = dataList.map((e) => e.temperature).reduce((a, b) => a + b) / dataList.length;
    final avgHumidity = dataList.map((e) => e.humidity).reduce((a, b) => a + b) / dataList.length;

    double? avgPressure;
    final pressureList = dataList.where((e) => e.pressure != null).toList();
    if (pressureList.isNotEmpty) {
      avgPressure = pressureList.map((e) => e.pressure!).reduce((a, b) => a + b) / pressureList.length;
    }

    int? avgAirQuality;
    final airQualityList = dataList.where((e) => e.airQuality != null).toList();
    if (airQualityList.isNotEmpty) {
      avgAirQuality = (airQualityList.map((e) => e.airQuality!).reduce((a, b) => a + b) / airQualityList.length).round();
    }

    double? avgMovement;
    final movementList = dataList.where((e) => e.movementLevel != null).toList();
    if (movementList.isNotEmpty) {
      avgMovement = movementList.map((e) => e.movementLevel!).reduce((a, b) => a + b) / movementList.length;
    }

    return EnvironmentalData(
      timestamp: dataList.last.timestamp,
      lightLevel: avgLight,
      noiseLevel: avgNoise,
      temperature: avgTemp,
      humidity: avgHumidity,
      pressure: avgPressure,
      airQuality: avgAirQuality,
      movementLevel: avgMovement,
    );
  }

  /// تصفية البيانات ضمن نطاق زمني
  static List<EnvironmentalData> filterByTimeRange(
      List<EnvironmentalData> dataList,
      DateTime start,
      DateTime end,
      ) {
    return dataList
        .where((data) =>
    data.timestamp.isAfter(start) && data.timestamp.isBefore(end))
        .toList();
  }

  /// الحصول على أسوأ البيانات (الأقل جودة)
  static EnvironmentalData? getWorst(List<EnvironmentalData> dataList) {
    if (dataList.isEmpty) return null;

    return dataList.reduce((curr, next) =>
    curr.overallQualityScore < next.overallQualityScore ? curr : next);
  }

  /// الحصول على أفضل البيانات (الأعلى جودة)
  static EnvironmentalData? getBest(List<EnvironmentalData> dataList) {
    if (dataList.isEmpty) return null;

    return dataList.reduce((curr, next) =>
    curr.overallQualityScore > next.overallQualityScore ? curr : next);
  }

  /// إنشاء بيانات تجريبية
  factory EnvironmentalData.mock({
    DateTime? timestamp,
    String? sleepSessionId,
  }) {
    return EnvironmentalData(
      timestamp: timestamp ?? DateTime.now(),
      lightLevel: 5.0,
      noiseLevel: 25.0,
      temperature: 20.0,
      humidity: 50.0,
      pressure: 1013.25,
      airQuality: 35,
      movementLevel: 0.1,
      sleepSessionId: sleepSessionId,
    );
  }
}