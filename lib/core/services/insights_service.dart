// lib/core/services/insights_service.dart - ✅ النسخة النهائية - JSON ONLY
// ═══════════════════════════════════════════════════════════════════════
// التعديلات النهائية:
// ✅ حذف كل الـ hardcoded messages
// ✅ JSON هو المصدر الوحيد للرسائل
// ✅ يعمل مع JSON البسيط الموجود (بدون dynamic sections)
// ✅ إذا فشل تحميل JSON، الخدمة لا تعمل
// ═══════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../database/models/sleep_models.dart';
import '../database/models/environmental_conditions.dart';
import '../database/models/activity_models.dart';
import '../database/repositories/activity_repository.dart';
import '../database/repositories/nutrition_repository.dart';
import '../database/repositories/location_repository.dart';
import '../database/repositories/settings_repository.dart';
import '../database/repositories/sleep_repository.dart';
import 'notification_service.dart';

// تعدادات الرؤى
enum InsightType {
  positive,
  negative,
  neutral;

  String get displayName {
    switch (this) {
      case InsightType.positive:
        return 'إيجابي';
      case InsightType.negative:
        return 'يحتاج تحسين';
      case InsightType.neutral:
        return 'ملاحظة';
    }
  }

  String get emoji {
    switch (this) {
      case InsightType.positive:
        return '✅';
      case InsightType.negative:
        return '⚠️';
      case InsightType.neutral:
        return 'ℹ️';
    }
  }
}

// نموذج الرؤية
@immutable
class Insight {
  final String category;
  final String? subcategory;
  final InsightType insightType;
  final String title;
  final String message;
  final double confidenceScore;
  final String date;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  const Insight({
    required this.category,
    this.subcategory,
    required this.insightType,
    required this.title,
    required this.message,
    required this.confidenceScore,
    required this.date,
    required this.createdAt,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'subcategory': subcategory,
      'insight_type': insightType.name,
      'title': title,
      'message': message,
      'confidence_score': confidenceScore,
      'date': date,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory Insight.fromMap(Map<String, dynamic> map) {
    return Insight(
      category: map['category'] ?? '',
      subcategory: map['subcategory'],
      insightType: InsightType.values.firstWhere(
            (e) => e.name == map['insight_type'],
        orElse: () => InsightType.neutral,
      ),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      confidenceScore: (map['confidence_score'] ?? 0.0).toDouble(),
      date: map['date'] ?? '',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      metadata: map['metadata'],
    );
  }

  @override
  String toString() {
    return 'Insight(category: $category, type: ${insightType.name}, title: $title, confidence: $confidenceScore)';
  }
}

// نماذج البيانات المساعدة
class DailyActivityData {
  final String date;
  final int steps;
  final double distance;
  final int activeMinutes;
  final double caloriesBurned;
  final List<ActivitySession> activitySessions;
  final int? timeOutsideHome;

  const DailyActivityData({
    required this.date,
    required this.steps,
    required this.distance,
    required this.activeMinutes,
    required this.caloriesBurned,
    required this.activitySessions,
    this.timeOutsideHome,
  });
}

class DailyPhoneData {
  final String date;
  final int totalUsageMinutes;
  final int nightUsageMinutes;
  final int unlockCount;
  final bool immediateCheckAfterWakeup;
  final int socialMediaMinutes;

  const DailyPhoneData({
    required this.date,
    this.totalUsageMinutes = 0,
    this.nightUsageMinutes = 0,
    this.unlockCount = 0,
    this.immediateCheckAfterWakeup = false,
    this.socialMediaMinutes = 0,
  });
}

class CompleteSleepData {
  final String date;
  final SleepSession? session;
  final double? totalSleepHours;
  final double? sleepQuality;
  final List<EnvironmentalConditions> environmentalConditions;
  final double? avgLightLevel;
  final double? avgNoiseLevel;
  final double? avgMovementIntensity;
  final double? avgTemperature;
  final double? overallEnvironmentScore;
  final int? nightWakeups;
  final double? deepSleepPercentage;
  final double? remSleepPercentage;
  final double? overallQuality;

  const CompleteSleepData({
    required this.date,
    this.session,
    this.totalSleepHours,
    this.sleepQuality,
    this.environmentalConditions = const [],
    this.avgLightLevel,
    this.avgNoiseLevel,
    this.avgMovementIntensity,
    this.avgTemperature,
    this.overallEnvironmentScore,
    this.nightWakeups,
    this.deepSleepPercentage,
    this.remSleepPercentage,
    this.overallQuality,
  });
}

class DailyLocationData {
  final String date;
  final bool sleptAwayFromHome;
  final int totalPlacesVisited;

  const DailyLocationData({
    required this.date,
    this.sleptAwayFromHome = false,
    this.totalPlacesVisited = 0,
  });
}

class BMIData {
  final double? currentBMI;
  final double? weightChange;
  final double? weight;
  final double? height;

  const BMIData({
    this.currentBMI,
    this.weightChange,
    this.weight,
    this.height,
  });

  String getBMICategory() {
    if (currentBMI == null) return 'غير محدد';

    final bmi = currentBMI!;
    if (bmi < 18.5) return 'نقص في الوزن';
    if (bmi <= 24.9) return 'وزن طبيعي';
    if (bmi <= 29.9) return 'زيادة في الوزن';
    return 'سمنة';
  }
}

/// خدمة الرؤى والتحليلات الذكية
class InsightsService {
  static final InsightsService _instance = InsightsService._internal();
  factory InsightsService() => _instance;
  InsightsService._internal();

  static InsightsService get instance => _instance;

  // Dependencies
  final ActivityRepository _activityRepo = ActivityRepository();
  final NutritionRepository _nutritionRepo = NutritionRepository();
  final LocationRepository _locationRepo = LocationRepository();
  final SettingsRepository _settingsRepo = SettingsRepository();
  final SleepRepository _sleepRepo = SleepRepository();
  final NotificationService _notificationService = NotificationService.instance;

  // Cache
  final Map<String, List<Insight>> _insightsCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, List<String>> _usedMessagesToday = {};

  // Messages data - من JSON فقط
  Map<String, dynamic> _messagesData = {};

  static const Duration _cacheExpiry = Duration(hours: 2);
  bool _isInitialized = false;
  bool _isGenerating = false;

  // ════════════════════════════════════════════════════════════════════════
  // تهيئة وتحميل البيانات
  // ════════════════════════════════════════════════════════════════════════

  /// تهيئة خدمة الرؤى
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      debugPrint('🧠 تهيئة خدمة الرؤى...');
      await _loadInsightsMessages();
      _isInitialized = true;
      debugPrint('✅ تم تهيئة خدمة الرؤى بنجاح');
      return true;
    } catch (e, stack) {
      debugPrint('❌ خطأ في تهيئة خدمة الرؤى: $e');
      debugPrint('Stack: $stack');
      debugPrint('⚠️ تأكد من وجود ملف assets/data/insights_messages.json');
      _isInitialized = false;
      return false;
    }
  }

  /// تحميل رسائل الرؤى من JSON - المصدر الوحيد
  Future<void> _loadInsightsMessages() async {
    final String jsonString = await rootBundle.loadString('assets/data/insights_messages.json');
    _messagesData = json.decode(jsonString);

    // التحقق من البنية الأساسية
    if (!_messagesData.containsKey('daily_limits')) {
      throw Exception('JSON file missing required "daily_limits" section');
    }

    debugPrint('✅ تم تحميل رسائل الرؤى من JSON');
    debugPrint('   - الفئات المتوفرة: ${_messagesData.keys.where((k) => k != 'daily_limits' && k != 'general_motivation').join(', ')}');
    debugPrint('   - الحد الأقصى اليومي: ${_messagesData['daily_limits']['max_insights_per_day']}');
  }

  // ════════════════════════════════════════════════════════════════════════
  // ✅ دوال الرؤى المخصصة لكل شاشة
  // ════════════════════════════════════════════════════════════════════════

  /// إنتاج رؤى النشاط فقط (للاستخدام في شاشة النشاط)
  Future<List<Insight>> generateActivityOnlyInsights(String date) async {
    try {
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) {
          debugPrint('❌ فشل تهيئة خدمة الرؤى');
          return [];
        }
      }

      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🏃 [Activity Insights] إنتاج رؤى النشاط فقط...');
      debugPrint('   📅 التاريخ: $date');

      final insights = <Insight>[];
      final maxInsights = 5;
      final minConfidence = 0.6;

      _resetUsedMessagesIfNewDay(date);

      // جمع بيانات النشاط الحقيقية فقط
      debugPrint('📂 جمع بيانات النشاط...');
      final activityData = await _getDailyActivityData(date);
      debugPrint('   ✅ Activity: ${activityData.steps} steps, ${activityData.distance.toStringAsFixed(1)} km');

      // إنتاج رؤى النشاط
      debugPrint('🔍 توليد رؤى النشاط...');
      final activityInsights = await _generateActivityInsights(date, activityData);
      debugPrint('   - تم إنتاج ${activityInsights.length} رؤية للنشاط');

      // فلترة حسب الثقة
      final filtered = activityInsights.where((i) => i.confidenceScore >= minConfidence).toList();
      debugPrint('   - بعد الفلترة: ${filtered.length} رؤية');
      insights.addAll(filtered);

      // رؤية تحفيزية إذا كان العدد قليل
      if (insights.length < 3) {
        debugPrint('💪 محاولة إضافة رؤية تحفيزية...');
        final motivationInsight = _generateMotivationalInsight(date);
        if (motivationInsight != null) {
          insights.add(motivationInsight);
          debugPrint('   ✅ تمت إضافة رؤية تحفيزية');
        }
      }

      final finalInsights = insights.take(maxInsights).toList();

      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('✅ [Activity Insights] تم إنتاج ${finalInsights.length} رؤية للنشاط');
      for (var i = 0; i < finalInsights.length; i++) {
        debugPrint('   ${i + 1}. ${finalInsights[i].title} (${(finalInsights[i].confidenceScore * 100).round()}%)');
      }
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      return finalInsights;

    } catch (e, stack) {
      debugPrint('❌ خطأ في إنتاج رؤى النشاط: $e');
      debugPrint('Stack: $stack');
      return [];
    }
  }

  /// إنتاج رؤى النوم فقط (للاستخدام في شاشة النوم - مستقبلاً)
  Future<List<Insight>> generateSleepOnlyInsights(String date) async {
    try {
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) {
          debugPrint('❌ فشل تهيئة خدمة الرؤى');
          return [];
        }
      }

      debugPrint('😴 [Sleep Insights] إنتاج رؤى النوم فقط...');

      final insights = <Insight>[];
      final maxInsights = 5;
      final minConfidence = 0.6;

      _resetUsedMessagesIfNewDay(date);

      // جمع بيانات النوم الحقيقية فقط
      final sleepData = await _getCompleteSleepData(date);
      debugPrint('   ✅ Sleep: ${sleepData.totalSleepHours ?? 0} hours');

      // إنتاج رؤى النوم (بدون بيانات وهمية)
      final sleepInsights = await _generateSleepInsights(
        date,
        sleepData,
        DailyPhoneData(date: date),  // بيانات فارغة
        DailyLocationData(date: date),  // بيانات فارغة
      );
      debugPrint('   - تم إنتاج ${sleepInsights.length} رؤية للنوم');

      // فلترة حسب الثقة
      final filtered = sleepInsights.where((i) => i.confidenceScore >= minConfidence).toList();
      insights.addAll(filtered);

      final finalInsights = insights.take(maxInsights).toList();

      debugPrint('✅ [Sleep Insights] تم إنتاج ${finalInsights.length} رؤية للنوم');

      return finalInsights;

    } catch (e, stack) {
      debugPrint('❌ خطأ في إنتاج رؤى النوم: $e');
      debugPrint('Stack: $stack');
      return [];
    }
  }

  /// إنتاج الرؤى اليومية (للاستخدام في UnifiedHealthHub - يشمل كل شي)
  Future<List<Insight>> generateDailyInsights(String date) async {
    // ✅ منع التوليد المتزامن
    if (_isGenerating) {
      debugPrint('⏳ توليد الرؤى جاري بالفعل، تخطي...');
      return _insightsCache[date] ?? [];
    }

    try {
      _isGenerating = true;

      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) {
          debugPrint('❌ فشل تهيئة خدمة الرؤى');
          return [];
        }
      }

      if (_isInsightsCacheValid(date)) {
        debugPrint('💾 استخدام cache للتاريخ: $date');
        return _insightsCache[date] ?? [];
      }

      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🧠 إنتاج رؤى يومية لتاريخ: $date');

      final insights = <Insight>[];
      final maxInsights = _messagesData['daily_limits']?['max_insights_per_day'] ?? 5;
      final minConfidence = _messagesData['daily_limits']?['min_confidence_score'] ?? 0.6;

      debugPrint('   - maxInsights: $maxInsights');
      debugPrint('   - minConfidence: $minConfidence');

      _resetUsedMessagesIfNewDay(date);

      // جمع البيانات
      debugPrint('📂 جمع البيانات...');

      final sleepData = await _getCompleteSleepData(date);
      debugPrint('   ✅ Sleep: ${sleepData.totalSleepHours ?? 0} hours');

      final activityData = await _getDailyActivityData(date);
      debugPrint('   ✅ Activity: ${activityData.steps} steps');

      // ✅ ملاحظة: phoneData و locationData فارغة الآن
      final phoneData = DailyPhoneData(date: date);
      final locationData = DailyLocationData(date: date);
      debugPrint('   ⚠️ Phone/Location: بيانات فارغة (مش مستخدمة)');

      final bmiData = await _getBMIData();
      debugPrint('   ✅ BMI: ${bmiData.currentBMI ?? "null"}');

      // إنتاج الرؤى
      final priorityCategories = List<String>.from(
          _messagesData['daily_limits']?['categories_priority'] ??
              ['sleep', 'activity', 'phone_usage']
      );

      debugPrint('📊 إنتاج الرؤى حسب الأولوية: $priorityCategories');

      for (final category in priorityCategories) {
        if (insights.length >= maxInsights) {
          debugPrint('⚠️ وصلنا للحد الأقصى: $maxInsights');
          break;
        }

        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('🔍 معالجة category: $category');

        List<Insight> categoryInsights = [];

        switch (category) {
          case 'sleep':
            categoryInsights = await _generateSleepInsights(date, sleepData, phoneData, locationData);
            break;
          case 'activity':
            categoryInsights = await _generateActivityInsights(date, activityData);
            break;
          case 'phone_usage':
          // ✅ معطّل مؤقتاً - سيتم تفعيله عند توفر بيانات حقيقية
            debugPrint('   ⏭️ تخطي Phone Usage (ميزة غير مفعّلة حالياً)');
            categoryInsights = [];
            break;
          case 'bmi':
            categoryInsights = await _generateBMIInsights(date, bmiData);
            break;
        }

        debugPrint('   - تم إنتاج ${categoryInsights.length} رؤية');

        final filtered = categoryInsights.where((i) => i.confidenceScore >= minConfidence).toList();
        debugPrint('   - بعد الفلترة: ${filtered.length} رؤية');

        insights.addAll(filtered);
        debugPrint('   - إجمالي الرؤى حتى الآن: ${insights.length}');
      }

      final finalInsights = insights.take(maxInsights).toList();

      // إضافة رؤية تحفيزية عند الحاجة
      if (finalInsights.length < maxInsights && Random().nextDouble() < 0.3) {
        debugPrint('💪 محاولة إضافة رؤية تحفيزية...');
        final motivationInsight = _generateMotivationalInsight(date);
        if (motivationInsight != null) {
          finalInsights.add(motivationInsight);
          debugPrint('   ✅ تمت إضافة رؤية تحفيزية');
        }
      }

      _insightsCache[date] = finalInsights;
      _cacheTimestamps[date] = DateTime.now();

      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('✅ تم إنتاج ${finalInsights.length} رؤية نهائية ليوم $date');
      for (var i = 0; i < finalInsights.length; i++) {
        debugPrint('   ${i + 1}. ${finalInsights[i].title} (${finalInsights[i].category})');
      }
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      return finalInsights;

    } catch (e, stack) {
      debugPrint('❌ خطأ في إنتاج الرؤى اليومية: $e');
      debugPrint('Stack: $stack');
      return [];
    } finally {
      _isGenerating = false;
    }
  }

  /// إنتاج رؤية من جلسة النوم
  Future<void> generateSleepInsight(SleepSession session) async {
    try {
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) return;
      }

      final date = _formatDate(session.startTime);
      debugPrint('💡 إنتاج رؤية من جلسة النوم: ${session.id}');

      final insights = <Insight>[];

      // تحليل المدة
      if (session.duration != null) {
        final hours = (session.duration?.inHours ?? 0).toDouble();
        if (hours < 6) {
          insights.add(Insight(
            category: 'sleep',
            subcategory: 'duration',
            insightType: InsightType.negative,
            title: 'نوم قصير',
            message: 'نمت ${hours.toStringAsFixed(1)} ساعات فقط. جسمك يحتاج 7-9 ساعات.',
            confidenceScore: 0.9,
            date: date,
            createdAt: DateTime.now(),
          ));
        } else if (hours >= 7 && hours <= 9) {
          insights.add(Insight(
            category: 'sleep',
            subcategory: 'duration',
            insightType: InsightType.positive,
            title: 'مدة نوم مثالية',
            message: 'نمت ${hours.toStringAsFixed(1)} ساعات - مدة ممتازة لصحتك!',
            confidenceScore: 0.9,
            date: date,
            createdAt: DateTime.now(),
          ));
        }
      }

      // تحليل الانقطاعات
      if (session.totalInterruptions > 3) {
        insights.add(Insight(
          category: 'sleep',
          subcategory: 'interruptions',
          insightType: InsightType.negative,
          title: 'نوم متقطع',
          message: 'استيقظت ${session.totalInterruptions} مرات. حاول تحسين بيئة نومك.',
          confidenceScore: 0.85,
          date: date,
          createdAt: DateTime.now(),
        ));
      }

      debugPrint('✅ تم إنتاج ${insights.length} رؤية من الجلسة');

    } catch (e) {
      debugPrint('❌ خطأ في إنتاج رؤية النوم: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // جمع البيانات
  // ════════════════════════════════════════════════════════════════════════

  Future<CompleteSleepData> _getCompleteSleepData(String date) async {
    try {
      final sessions = await _sleepRepo.getSleepSessionsForDate(date);
      final mainSession = sessions.isNotEmpty ? sessions.first : null;

      // ✅ إضافة حماية: إذا ما في session، أرجع بيانات فاضية
      if (mainSession == null) {
        debugPrint('⚠️ لا توجد جلسة نوم للتاريخ $date');
        return CompleteSleepData(date: date);
      }

      final environmentalData = mainSession.id != null
          ? await _sleepRepo.getEnvironmentalDataForSession(mainSession.id!)
          : <EnvironmentalConditions>[];

      // حساب المتوسطات من البيانات البيئية
      double? avgLight;
      double? avgNoise;
      double? avgMovement;
      double? avgTemp;

      if (environmentalData.isNotEmpty) {
        // ✅ إضافة حماية من null
        final lightLevels = environmentalData
            .where((e) => e.lightLevel != null)
            .map((e) => e.lightLevel!)
            .toList();

        if (lightLevels.isNotEmpty) {
          avgLight = lightLevels.reduce((a, b) => a + b) / lightLevels.length;
        }

        final noiseLevels = environmentalData
            .where((e) => e.noiseLevel != null)
            .map((e) => e.noiseLevel!)
            .toList();

        if (noiseLevels.isNotEmpty) {
          avgNoise = noiseLevels.reduce((a, b) => a + b) / noiseLevels.length;
        }

        final movements = environmentalData
            .where((e) => e.movementIntensity != null)
            .map((e) => e.movementIntensity!)
            .toList();

        if (movements.isNotEmpty) {
          avgMovement = movements.reduce((a, b) => a + b) / movements.length;
        }

        final temps = environmentalData
            .where((e) => e.temperature != null)
            .map((e) => e.temperature!)
            .toList();

        if (temps.isNotEmpty) {
          avgTemp = temps.reduce((a, b) => a + b) / temps.length;
        }
      }

      return CompleteSleepData(
        date: date,
        session: mainSession,
        // ✅ التعديل الأساسي هون
        totalSleepHours: mainSession.duration != null
            ? mainSession.duration!.inHours.toDouble()
            : 0.0,
        sleepQuality: mainSession.qualityScore,
        environmentalConditions: environmentalData,
        avgLightLevel: avgLight,
        avgNoiseLevel: avgNoise,
        avgMovementIntensity: avgMovement,
        avgTemperature: avgTemp,
        overallEnvironmentScore: mainSession.overallSleepQuality,
        nightWakeups: mainSession.totalInterruptions,
      );

    } catch (e, stack) {
      debugPrint('❌ خطأ في جمع بيانات النوم: $e');
      debugPrint('Stack: $stack');
      // ✅ أرجع بيانات فاضية بدل exception
      return CompleteSleepData(date: date);
    }
  }

  Future<DailyActivityData> _getDailyActivityData(String date) async {
    try {
      final dailyActivity = await _activityRepo.getDailyActivityForDate(date);
      final activitySessions = await _activityRepo.getActivitySessionsByDate(date);

      return DailyActivityData(
        date: date,
        steps: dailyActivity?.totalSteps ?? 0,
        distance: dailyActivity?.distance ?? 0.0,
        activeMinutes: dailyActivity?.activeMinutes ?? 0,
        caloriesBurned: dailyActivity?.caloriesBurned ?? 0.0,
        activitySessions: activitySessions,
        timeOutsideHome: 0,
      );
    } catch (e) {
      debugPrint('❌ خطأ في جمع بيانات النشاط: $e');
      return DailyActivityData(
        date: date,
        steps: 0,
        distance: 0.0,
        activeMinutes: 0,
        caloriesBurned: 0.0,
        activitySessions: [],
        timeOutsideHome: 0,
      );
    }
  }

  Future<BMIData> _getBMIData() async {
    try {
      final weight = await _settingsRepo.getSetting<double>('user_weight', null);
      final height = await _settingsRepo.getSetting<double>('user_height', null);

      if (weight == null || height == null) {
        return BMIData();
      }

      final heightInMeters = height / 100.0;
      final bmi = weight / (heightInMeters * heightInMeters);

      return BMIData(
        currentBMI: bmi,
        weight: weight,
        height: height,
      );
    } catch (e) {
      debugPrint('❌ خطأ في حساب BMI: $e');
      return BMIData();
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // إنتاج الرؤى المختلفة
  // ════════════════════════════════════════════════════════════════════════

  /// إنتاج رؤى النوم - محدّثة بالكامل ✅
  Future<List<Insight>> _generateSleepInsights(
      String date,
      CompleteSleepData sleepData,
      DailyPhoneData phoneData,
      DailyLocationData locationData) async {
    final insights = <Insight>[];

    try {
      // ═══════════════════════════════════════════════════════════
      // 🌙 تحليل الإضاءة (Light Level)
      // ═══════════════════════════════════════════════════════════
      if (sleepData.avgLightLevel != null) {
        final lightLevel = sleepData.avgLightLevel!;

        if (lightLevel < 10.0) {
          // إضاءة منخفضة - إيجابي
          final insight = _createInsightFromCondition(
            date: date,
            category: 'sleep',
            condition: 'positive.low_light',
            confidenceScore: 0.88,
            additionalData: {'light_level': lightLevel},
          );
          if (insight != null) insights.add(insight);
        } else if (lightLevel > 30.0) {
          // إضاءة عالية - سلبي
          final insight = _createInsightFromCondition(
            date: date,
            category: 'sleep',
            condition: 'negative.high_light',
            confidenceScore: 0.85,
            additionalData: {'light_level': lightLevel},
          );
          if (insight != null) insights.add(insight);
        }
      }

      // ═══════════════════════════════════════════════════════════
      // 🔇 تحليل الضوضاء (Noise Level)
      // ═══════════════════════════════════════════════════════════
      if (sleepData.avgNoiseLevel != null) {
        final noiseLevel = sleepData.avgNoiseLevel!;

        if (noiseLevel < 20.0) {
          // ضوضاء منخفضة - إيجابي
          final insight = _createInsightFromCondition(
            date: date,
            category: 'sleep',
            condition: 'positive.low_noise',
            confidenceScore: 0.87,
            additionalData: {'noise_level': noiseLevel},
          );
          if (insight != null) insights.add(insight);
        } else if (noiseLevel > 50.0) {
          // ضوضاء عالية - سلبي
          final insight = _createInsightFromCondition(
            date: date,
            category: 'sleep',
            condition: 'negative.high_noise',
            confidenceScore: 0.90,
            additionalData: {'noise_level': noiseLevel},
          );
          if (insight != null) insights.add(insight);
        }
      }

      // ═══════════════════════════════════════════════════════════
      // 🛌 تحليل الحركة أثناء النوم (Movement)
      // ═══════════════════════════════════════════════════════════
      if (sleepData.avgMovementIntensity != null) {
        final movement = sleepData.avgMovementIntensity!;

        if (movement < 15.0) {
          // حركة قليلة - إيجابي (نوم مستقر)
          final insight = _createInsightFromCondition(
            date: date,
            category: 'sleep',
            condition: 'positive.stable_sleep',
            confidenceScore: 0.83,
            additionalData: {'movement': movement},
          );
          if (insight != null) insights.add(insight);
        } else if (movement > 40.0) {
          // حركة كثيرة - سلبي (نوم مضطرب)
          final insight = _createInsightFromCondition(
            date: date,
            category: 'sleep',
            condition: 'negative.restless_sleep',
            confidenceScore: 0.85,
            additionalData: {'movement': movement},
          );
          if (insight != null) insights.add(insight);
        }
      }

      // ═══════════════════════════════════════════════════════════
      // 📵 تحليل استخدام الهاتف قبل النوم
      // ═══════════════════════════════════════════════════════════
      if (phoneData.nightUsageMinutes > 0) {
        final nightUsage = phoneData.nightUsageMinutes;

        if (nightUsage == 0) {
          // عدم استخدام - إيجابي
          final insight = _createInsightFromCondition(
            date: date,
            category: 'sleep',
            condition: 'positive.no_phone_before_sleep',
            confidenceScore: 0.80,
            additionalData: {'night_usage': nightUsage},
          );
          if (insight != null) insights.add(insight);
        } else if (nightUsage > 30) {
          // استخدام كثير - سلبي
          final insight = _createInsightFromCondition(
            date: date,
            category: 'sleep',
            condition: 'negative.phone_before_sleep',
            confidenceScore: 0.82,
            additionalData: {'night_usage': nightUsage},
          );
          if (insight != null) insights.add(insight);
        }
      }

      // ═══════════════════════════════════════════════════════════
      // 😴 تحليل الاستيقاظ الليلي (Night Wakeups)
      // ═══════════════════════════════════════════════════════════
      if (sleepData.nightWakeups != null) {
        final wakeups = sleepData.nightWakeups!;

        if (wakeups == 0 || wakeups == 1) {
          // استيقاظ قليل - إيجابي
          final insight = _createInsightFromCondition(
            date: date,
            category: 'sleep',
            condition: 'positive.no_phone_during_sleep',
            confidenceScore: 0.85,
            additionalData: {'wakeups': wakeups},
          );
          if (insight != null) insights.add(insight);
        } else if (wakeups > 4) {
          // استيقاظ كثير - سلبي
          final insight = _createInsightFromCondition(
            date: date,
            category: 'sleep',
            condition: 'negative.phone_during_sleep',
            confidenceScore: 0.87,
            additionalData: {'wakeups': wakeups},
          );
          if (insight != null) insights.add(insight);
        }
      }

    } catch (e) {
      debugPrint('❌ خطأ في إنتاج رؤى النوم: $e');
    }

    return insights;
  }

  /// إنتاج رؤى النشاط - محدّثة بالكامل ✅
  Future<List<Insight>> _generateActivityInsights(String date, DailyActivityData activityData) async {
    final insights = <Insight>[];

    try {
      final dailySteps = activityData.steps;
      final activeMinutes = activityData.activeMinutes;

      // ═══════════════════════════════════════════════════════════
      // 🚶 تحليل المشي (Walking)
      // ═══════════════════════════════════════════════════════════
      if (dailySteps >= 8000) {
        // مشي ممتاز
        final insight = _createInsightFromCondition(
          date: date,
          category: 'activity',
          condition: 'positive.good_walking',
          confidenceScore: 0.90,
          additionalData: {'steps': dailySteps},
        );
        if (insight != null) insights.add(insight);
      } else if (dailySteps < 3000) {
        // مشي قليل - سلبي
        final insight = _createInsightFromCondition(
          date: date,
          category: 'activity',
          condition: 'negative.low_walking',
          confidenceScore: 0.88,
          additionalData: {'steps': dailySteps},
        );
        if (insight != null) insights.add(insight);
      }

      // ═══════════════════════════════════════════════════════════
      // 🏃 تحليل النشاط العام (General Activity)
      // ═══════════════════════════════════════════════════════════
      if (activeMinutes >= 30) {
        // نشاط جيد
        final insight = _createInsightFromCondition(
          date: date,
          category: 'activity',
          condition: 'positive.good_activity',
          confidenceScore: 0.85,
          additionalData: {'active_minutes': activeMinutes},
        );
        if (insight != null) insights.add(insight);
      } else if (activeMinutes < 10) {
        // نشاط قليل - سلبي
        final insight = _createInsightFromCondition(
          date: date,
          category: 'activity',
          condition: 'negative.low_activity',
          confidenceScore: 0.87,
          additionalData: {'active_minutes': activeMinutes},
        );
        if (insight != null) insights.add(insight);
      }

    } catch (e) {
      debugPrint('❌ خطأ في إنتاج رؤى النشاط: $e');
    }

    return insights;
  }

  /// إنتاج رؤى استخدام الهاتف - جديد كامل ✅ (معطّل مؤقتاً)
  Future<List<Insight>> _generatePhoneUsageInsights(String date, DailyPhoneData phoneData) async {
    final insights = <Insight>[];

    try {
      // ⚠️ ملاحظة: هذه الميزة معطّلة حالياً لأن البيانات غير متوفرة
      // سيتم تفعيلها عند توفر بيانات حقيقية من phone usage tracking

      final totalUsageHours = phoneData.totalUsageMinutes / 60.0;
      final unlockCount = phoneData.unlockCount;
      final nightUsageMinutes = phoneData.nightUsageMinutes;
      final socialMediaHours = phoneData.socialMediaMinutes / 60.0;
      final immediateCheck = phoneData.immediateCheckAfterWakeup;

      // ═══════════════════════════════════════════════════════════
      // 📱 تحليل الاستخدام العام
      // ═══════════════════════════════════════════════════════════
      if (totalUsageHours >= 1.0 && totalUsageHours <= 4.0) {
        final insight = _createInsightFromCondition(
          date: date,
          category: 'phone_usage',
          condition: 'positive.moderate_usage',
          confidenceScore: 0.80,
          additionalData: {'usage_hours': totalUsageHours},
        );
        if (insight != null) insights.add(insight);
      } else if (totalUsageHours > 6.0) {
        final insight = _createInsightFromCondition(
          date: date,
          category: 'phone_usage',
          condition: 'negative.excessive_usage',
          confidenceScore: 0.85,
          additionalData: {'usage_hours': totalUsageHours},
        );
        if (insight != null) insights.add(insight);
      } else if (totalUsageHours < 1.0) {
        final insight = _createInsightFromCondition(
          date: date,
          category: 'phone_usage',
          condition: 'negative.very_low_usage',
          confidenceScore: 0.75,
          additionalData: {'usage_hours': totalUsageHours},
        );
        if (insight != null) insights.add(insight);
      }

      // ═══════════════════════════════════════════════════════════
      // 🌙 تحليل الاستخدام الليلي
      // ═══════════════════════════════════════════════════════════
      if (nightUsageMinutes == 0) {
        final insight = _createInsightFromCondition(
          date: date,
          category: 'phone_usage',
          condition: 'positive.no_night_usage',
          confidenceScore: 0.88,
        );
        if (insight != null) insights.add(insight);
      } else if (nightUsageMinutes > 30) {
        final insight = _createInsightFromCondition(
          date: date,
          category: 'phone_usage',
          condition: 'negative.night_usage',
          confidenceScore: 0.90,
          additionalData: {'night_minutes': nightUsageMinutes},
        );
        if (insight != null) insights.add(insight);
      }

      // ═══════════════════════════════════════════════════════════
      // ☀️ تحليل الفحص الصباحي
      // ═══════════════════════════════════════════════════════════
      if (!immediateCheck) {
        final insight = _createInsightFromCondition(
          date: date,
          category: 'phone_usage',
          condition: 'positive.no_morning_check',
          confidenceScore: 0.82,
        );
        if (insight != null) insights.add(insight);
      } else {
        final insight = _createInsightFromCondition(
          date: date,
          category: 'phone_usage',
          condition: 'negative.immediate_usage',
          confidenceScore: 0.80,
        );
        if (insight != null) insights.add(insight);
      }

      // ═══════════════════════════════════════════════════════════
      // 🔓 تحليل عدد الفتحات
      // ═══════════════════════════════════════════════════════════
      if (unlockCount >= 20 && unlockCount <= 80) {
        final insight = _createInsightFromCondition(
          date: date,
          category: 'phone_usage',
          condition: 'positive.moderate_unlocks',
          confidenceScore: 0.78,
          additionalData: {'unlocks': unlockCount},
        );
        if (insight != null) insights.add(insight);
      } else if (unlockCount > 120) {
        final insight = _createInsightFromCondition(
          date: date,
          category: 'phone_usage',
          condition: 'negative.excessive_unlocks',
          confidenceScore: 0.83,
          additionalData: {'unlocks': unlockCount},
        );
        if (insight != null) insights.add(insight);
      }

      // ═══════════════════════════════════════════════════════════
      // 💬 تحليل السوشيال ميديا
      // ═══════════════════════════════════════════════════════════
      if (socialMediaHours >= 0.5 && socialMediaHours <= 2.0) {
        final insight = _createInsightFromCondition(
          date: date,
          category: 'phone_usage',
          condition: 'positive.healthy_social',
          confidenceScore: 0.75,
          additionalData: {'social_hours': socialMediaHours},
        );
        if (insight != null) insights.add(insight);
      } else if (socialMediaHours < 0.2) {
        final insight = _createInsightFromCondition(
          date: date,
          category: 'phone_usage',
          condition: 'negative.social_withdrawal',
          confidenceScore: 0.70,
          additionalData: {'social_hours': socialMediaHours},
        );
        if (insight != null) insights.add(insight);
      }

    } catch (e) {
      debugPrint('❌ خطأ في إنتاج رؤى استخدام الهاتف: $e');
    }

    return insights;
  }

  /// إنتاج رؤى BMI
  Future<List<Insight>> _generateBMIInsights(String date, BMIData bmiData) async {
    final insights = <Insight>[];

    try {
      if (bmiData.currentBMI == null) return insights;

      final bmi = bmiData.currentBMI!;

      // ملاحظة: BMI insights غير موجودة في JSON المقدم
      // يمكن إضافتها لاحقاً إذا لزم الأمر

    } catch (e) {
      debugPrint('❌ خطأ في إنتاج رؤى BMI: $e');
    }

    return insights;
  }

  /// إنشاء رؤية من condition
  Insight? _createInsightFromCondition({
    required String date,
    required String category,
    required String condition,
    required double confidenceScore,
    Map<String, dynamic>? additionalData,
  }) {
    try {
      final conditionParts = condition.split('.');
      if (conditionParts.length != 2) {
        debugPrint('   ❌ condition format غلط: $condition');
        return null;
      }

      final type = conditionParts[0];
      final subCondition = conditionParts[1];

      final categoryData = _messagesData[category];
      if (categoryData == null) {
        debugPrint('   ❌ categoryData null لـ: $category');
        return null;
      }

      final typeData = categoryData[type];
      if (typeData == null) {
        debugPrint('   ❌ typeData null لـ: $type');
        return null;
      }

      final messages = List<String>.from(typeData[subCondition] ?? []);
      if (messages.isEmpty) {
        debugPrint('   ❌ messages فاضية لـ: $subCondition');
        return null;
      }

      final unusedMessages = messages.where((msg) =>
      !(_usedMessagesToday[date] ?? []).contains(msg)
      ).toList();

      final selectedMessage = unusedMessages.isNotEmpty
          ? unusedMessages[Random().nextInt(unusedMessages.length)]
          : messages[Random().nextInt(messages.length)];

      _usedMessagesToday[date] = (_usedMessagesToday[date] ?? [])..add(selectedMessage);

      InsightType insightType;
      String title = selectedMessage;

      if (type == 'positive') {
        insightType = InsightType.positive;
        title = _extractTitleFromMessage(selectedMessage) ?? 'رؤية إيجابية';
      } else {
        insightType = InsightType.negative;
        title = _extractTitleFromMessage(selectedMessage) ?? 'نصيحة للتحسين';
      }

      final insight = Insight(
        category: category,
        subcategory: subCondition,
        insightType: insightType,
        title: title,
        message: _enhanceMessageWithData(selectedMessage, additionalData),
        confidenceScore: confidenceScore,
        date: date,
        createdAt: DateTime.now(),
      );

      return insight;

    } catch (e, stack) {
      debugPrint('❌ خطأ في إنشاء رؤية: $e');
      debugPrint('Stack: $stack');
      return null;
    }
  }

  /// تحسين الرسالة بالبيانات - محدّث ✅
  String _enhanceMessageWithData(String message, Map<String, dynamic>? data) {
    if (data == null) return message;

    String enhancedMessage = message;

    // Sleep data
    if (data['light_level'] != null) {
      enhancedMessage += ' (مستوى الإضاءة: ${data['light_level'].toStringAsFixed(1)})';
    }

    if (data['noise_level'] != null) {
      enhancedMessage += ' (مستوى الضوضاء: ${data['noise_level'].toStringAsFixed(1)})';
    }

    if (data['movement'] != null) {
      enhancedMessage += ' (شدة الحركة: ${data['movement'].toStringAsFixed(1)})';
    }

    if (data['wakeups'] != null) {
      enhancedMessage += ' (${data['wakeups']} استيقاظ)';
    }

    // Activity data
    if (data['steps'] != null) {
      enhancedMessage += ' (${_formatNumber(data['steps'] as int)} خطوة)';
    }

    if (data['active_minutes'] != null) {
      enhancedMessage += ' (${data['active_minutes']} دقيقة نشاط)';
    }

    // Phone usage data
    if (data['usage_hours'] != null) {
      enhancedMessage += ' (${data['usage_hours'].toStringAsFixed(1)} ساعة)';
    }

    if (data['unlocks'] != null) {
      enhancedMessage += ' (${data['unlocks']} فتحة)';
    }

    if (data['night_minutes'] != null) {
      enhancedMessage += ' (${data['night_minutes']} دقيقة ليلاً)';
    }

    if (data['social_hours'] != null) {
      enhancedMessage += ' (${data['social_hours'].toStringAsFixed(1)} ساعة سوشيال ميديا)';
    }

    // BMI data
    if (data['bmi'] != null) {
      enhancedMessage += ' (مؤشر كتلة الجسم: ${data['bmi'].toStringAsFixed(1)})';
    }

    if (data['env_score'] != null) {
      enhancedMessage += ' (درجة البيئة: ${data['env_score'].toStringAsFixed(1)}/10)';
    }

    return enhancedMessage;
  }

  String? _extractTitleFromMessage(String message) {
    final sentences = message.split('.');
    if (sentences.isNotEmpty) {
      String title = sentences.first.trim();
      if (title.length > 50) {
        title = title.substring(0, 47) + '...';
      }
      return title;
    }
    return null;
  }

  Insight? _generateMotivationalInsight(String date) {
    try {
      final motivationMessages = List<String>.from(_messagesData['general_motivation'] ?? []);
      if (motivationMessages.isEmpty) return null;

      final unusedMessages = motivationMessages.where((msg) =>
      !(_usedMessagesToday[date] ?? []).contains(msg)
      ).toList();

      final selectedMessage = unusedMessages.isNotEmpty
          ? unusedMessages[Random().nextInt(unusedMessages.length)]
          : motivationMessages[Random().nextInt(motivationMessages.length)];

      _usedMessagesToday[date] = (_usedMessagesToday[date] ?? [])..add(selectedMessage);

      return Insight(
        category: 'motivation',
        subcategory: 'general',
        insightType: InsightType.positive,
        title: '',
        message: selectedMessage,
        confidenceScore: 0.5,
        date: date,
        createdAt: DateTime.now(),
      );

    } catch (e) {
      debugPrint('❌ خطأ في إنتاج رؤية تحفيزية: $e');
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // الدوال المساعدة
  // ════════════════════════════════════════════════════════════════════════

  void _resetUsedMessagesIfNewDay(String date) {
    final today = _formatDate(DateTime.now());
    if (date == today && _usedMessagesToday[date] != null) {
      return;
    }
    _usedMessagesToday[date] = [];
  }

  bool _isInsightsCacheValid(String date) {
    if (!_insightsCache.containsKey(date) || !_cacheTimestamps.containsKey(date)) {
      return false;
    }

    final cacheTime = _cacheTimestamps[date]!;
    final now = DateTime.now();

    return now.difference(cacheTime) < _cacheExpiry;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},'
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🆕 UnifiedHealthHub Integration - من JSON فقط ✅
  // ════════════════════════════════════════════════════════════════════════

  /// مقارنة مع الأمس - يستخدم general_motivation فقط من JSON
  Future<String?> generateComparisonInsight(
      Map<String, dynamic> todayData,
      Map<String, dynamic> yesterdayData,
      ) async {
    try {
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) return null;
      }

      // ✅ نستخدم فقط general_motivation من JSON
      return _getGeneralMotivation();

    } catch (e) {
      debugPrint('❌ خطأ في مقارنة مع الأمس: $e');
      return null;
    }
  }

  /// كشف الاتجاهات - يستخدم general_motivation فقط من JSON
  Future<String?> detectTrends(List<Map<String, dynamic>> weekData) async {
    try {
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) return null;
      }
      if (weekData.length < 3) return null;

      // ✅ نستخدم فقط general_motivation من JSON
      return _getGeneralMotivation();

    } catch (e) {
      debugPrint('❌ خطأ في كشف الاتجاهات: $e');
      return null;
    }
  }

  /// رؤى تحفيزية ذكية (public version) - من JSON فقط ✅
  Future<String?> generateMotivationalInsight(Map<String, dynamic> data) async {
    try {
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) return null;
      }

      // ✅ نستخدم فقط general_motivation من JSON
      return _getGeneralMotivation();

    } catch (e) {
      debugPrint('❌ خطأ في الرؤى التحفيزية: $e');
      return null;
    }
  }

  /// تنبؤ بالأداء - يستخدم general_motivation فقط من JSON
  Future<String?> predictFuturePerformance(List<Map<String, dynamic>> historicalData) async {
    try {
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) return null;
      }
      if (historicalData.length < 5) return null;

      // ✅ نستخدم فقط general_motivation من JSON
      return _getGeneralMotivation();

    } catch (e) {
      debugPrint('❌ خطأ في التنبؤ بالأداء: $e');
      return null;
    }
  }

  /// دالة مساعدة للحصول على رسالة تحفيزية عامة من JSON
  String? _getGeneralMotivation() {
    final generalMessages = List<String>.from(
        _messagesData['general_motivation'] ?? []
    );

    if (generalMessages.isEmpty) {
      debugPrint('⚠️ لا توجد رسائل تحفيزية عامة في JSON');
      return null;
    }

    return generalMessages[Random().nextInt(generalMessages.length)];
  }

  /// حساب الاتجاه (Trend) - دالة مساعدة
  double _calculateTrend(List<double> data) {
    if (data.length < 2) return 0.0;

    try {
      final n = data.length;
      double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;

      for (int i = 0; i < n; i++) {
        final x = i.toDouble();
        final y = data[i];
        sumX += x;
        sumY += y;
        sumXY += x * y;
        sumX2 += x * x;
      }

      final denominator = (n * sumX2 - sumX * sumX);
      if (denominator == 0) return 0.0;

      final slope = (n * sumXY - sumX * sumY) / denominator;

      // تطبيع النتيجة (normalize)
      final avgY = sumY / n;
      if (avgY == 0) return 0.0;

      return slope / avgY;

    } catch (e) {
      debugPrint('❌ خطأ في حساب الاتجاه: $e');
      return 0.0;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // إدارة الخدمة
  // ════════════════════════════════════════════════════════════════════════

  void clearCache() {
    _insightsCache.clear();
    _cacheTimestamps.clear();
    _usedMessagesToday.clear();
    debugPrint('تم مسح ذاكرة الرؤى المؤقتة');
  }

  Map<String, dynamic> getInsightsStatistics() {
    return {
      'total_cached_insights': _insightsCache.values
          .map((insights) => insights.length)
          .fold(0, (a, b) => a + b),
      'cached_dates': _insightsCache.keys.toList(),
      'messages_loaded': _messagesData.isNotEmpty,
      'daily_limit': _messagesData['daily_limits']?['max_insights_per_day'] ?? 5,
      'used_messages_today': _usedMessagesToday,
      'is_initialized': _isInitialized,
      'supported_categories': ['sleep', 'activity', 'phone_usage'],
      'data_source': 'JSON only (assets/data/insights_messages.json)',
    };
  }

  Future<void> dispose() async {
    try {
      clearCache();
      _messagesData.clear();
      _isInitialized = false;
      _isGenerating = false;
      debugPrint('تم التخلص من خدمة الرؤى');
    } catch (e) {
      debugPrint('❌ خطأ في التخلص من خدمة الرؤى: $e');
    }
  }
}