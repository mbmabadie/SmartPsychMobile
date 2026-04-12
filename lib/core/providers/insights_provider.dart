// lib/core/providers/insights_provider.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../database/repositories/insights_repository.dart';
import 'base/base_state.dart';
import 'base/base_provider.dart';
import '../services/insights_service.dart';
import '../services/notification_service.dart';
import 'statistics_provider.dart';

/// Insight Priority enum - أولوية الرؤية
enum InsightPriority {
  low('منخفضة', Colors.grey),
  medium('متوسطة', Colors.orange),
  high('عالية', Colors.red),
  critical('حرجة', Colors.deepOrange);

  const InsightPriority(this.displayName, this.color);
  final String displayName;
  final Color color;
}

/// Insight Action Type enum - نوع إجراء الرؤية
enum InsightActionType {
  none('لا يوجد'),
  reminder('تذكير'),
  goal('تحديد هدف'),
  habit('تكوين عادة'),
  medical('استشارة طبية'),
  lifestyle('تغيير نمط الحياة');

  const InsightActionType(this.displayName);
  final String displayName;
}

/// Personalized Insight class - فئة الرؤية المخصصة (محدثة)
@immutable
class PersonalizedInsight {
  final String id;
  final String title;
  final String message;
  final String category;
  final String? subcategory;
  final InsightType type;
  final InsightPriority priority;
  final double confidenceScore;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isShown;
  final bool isActedUpon;
  final Map<String, dynamic> relatedData;
  final List<String> actionableSteps;
  final InsightActionType actionType;
  final String? deepLinkAction;

  const PersonalizedInsight({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    this.subcategory,
    required this.type,
    this.priority = InsightPriority.medium,
    required this.confidenceScore,
    required this.createdAt,
    this.expiresAt,
    this.isShown = false,
    this.isActedUpon = false,
    this.relatedData = const {},
    this.actionableSteps = const [],
    this.actionType = InsightActionType.none,
    this.deepLinkAction,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isHighConfidence => confidenceScore >= 0.8;
  bool get isActionable => actionableSteps.isNotEmpty;
  bool get needsAttention => priority.index >= InsightPriority.high.index;

  String get priorityEmoji {
    switch (priority) {
      case InsightPriority.low:
        return '💡';
      case InsightPriority.medium:
        return '⚠️';
      case InsightPriority.high:
        return '🔥';
      case InsightPriority.critical:
        return '🚨';
    }
  }

  String get typeEmoji {
    switch (type) {
      case InsightType.positive:
        return '✅';
      case InsightType.negative:
        return '⚠️';
      case InsightType.neutral:
        return 'ℹ️';
    }
  }

  /// تحويل من Insight الجديد إلى PersonalizedInsight
  factory PersonalizedInsight.fromInsight(Insight insight) {
    return PersonalizedInsight(
      id: '${insight.date}_${insight.category}_${insight.subcategory ?? 'general'}_${insight.createdAt.millisecondsSinceEpoch}',
      title: insight.title,
      message: insight.message,
      category: insight.category,
      subcategory: insight.subcategory,
      type: insight.insightType,
      priority: _determinePriorityFromInsight(insight),
      confidenceScore: insight.confidenceScore,
      createdAt: insight.createdAt,
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      relatedData: insight.metadata ?? {},
      actionableSteps: _generateActionableSteps(insight),
      actionType: _determineActionType(insight),
    );
  }

  static InsightPriority _determinePriorityFromInsight(Insight insight) {
    if (insight.confidenceScore >= 0.9) {
      if (insight.subcategory == 'severe_insomnia' ||
          insight.subcategory == 'dangerous_inactivity' ||
          insight.subcategory == 'underweight' ||
          insight.subcategory == 'obese' ||
          insight.subcategory == 'excessive_usage') {
        return InsightPriority.critical;
      }
      return InsightPriority.high;
    } else if (insight.confidenceScore >= 0.8) {
      return InsightPriority.medium;
    } else {
      return InsightPriority.low;
    }
  }

  static InsightActionType _determineActionType(Insight insight) {
    switch (insight.category) {
      case 'sleep':
        return InsightActionType.habit;
      case 'activity':
        return InsightActionType.goal;
      case 'phone_usage':
        return InsightActionType.lifestyle;
      case 'bmi':
        return InsightActionType.medical;
      default:
        return InsightActionType.reminder;
    }
  }

  static List<String> _generateActionableSteps(Insight insight) {
    final steps = <String>[];

    switch (insight.category) {
      case 'sleep':
        if (insight.insightType == InsightType.negative) {
          steps.addAll([
            'ضع روتين نوم ثابت',
            'تجنب الكافيين بعد العصر',
            'أطفئ الشاشات قبل النوم بساعة'
          ]);
        } else {
          steps.addAll([
            'حافظ على روتين النوم الحالي',
            'استمر في نفس مواعيد النوم'
          ]);
        }
        break;

      case 'activity':
        if (insight.insightType == InsightType.negative) {
          steps.addAll([
            'اصعد الدرج بدلاً من المصعد',
            'امشِ 10 دقائق إضافية يومياً',
            'اخرج من المنزل ولو لفترة قصيرة'
          ]);
        } else {
          steps.addAll([
            'استمر في نشاطك الحالي',
            'جرب إضافة نشاط جديد'
          ]);
        }
        break;

      case 'phone_usage':
        if (insight.insightType == InsightType.negative) {
          steps.addAll([
            'ضع الهاتف في غرفة أخرى ليلاً',
            'استخدم تطبيقات تحديد وقت الشاشة',
            'ضع فترات راحة رقمية'
          ]);
        } else {
          steps.addAll([
            'حافظ على استخدامك المتوازن',
            'استمر في تجنب الاستخدام الليلي'
          ]);
        }
        break;

      case 'bmi':
        if (insight.insightType == InsightType.negative) {
          steps.addAll([
            'استشر طبيب تغذية',
            'ضع خطة غذائية متوازنة',
            'راقب وزنك بانتظام'
          ]);
        } else {
          steps.addAll([
            'حافظ على وزنك الصحي',
            'استمر في نمط حياتك الحالي'
          ]);
        }
        break;

      default:
        steps.add('تابع مع مختص إذا لزم الأمر');
    }

    return steps;
  }

  PersonalizedInsight copyWith({
    String? id,
    String? title,
    String? message,
    String? category,
    String? subcategory,
    InsightType? type,
    InsightPriority? priority,
    double? confidenceScore,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isShown,
    bool? isActedUpon,
    Map<String, dynamic>? relatedData,
    List<String>? actionableSteps,
    InsightActionType? actionType,
    String? deepLinkAction,
  }) {
    return PersonalizedInsight(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isShown: isShown ?? this.isShown,
      isActedUpon: isActedUpon ?? this.isActedUpon,
      relatedData: relatedData ?? this.relatedData,
      actionableSteps: actionableSteps ?? this.actionableSteps,
      actionType: actionType ?? this.actionType,
      deepLinkAction: deepLinkAction ?? this.deepLinkAction,
    );
  }

  @override
  String toString() {
    return 'PersonalizedInsight($priorityEmoji $title - ${priority.displayName})';
  }
}

/// Weekly Insights Summary class - ملخص الرؤى الأسبوعي
@immutable
class WeeklyInsightsSummary {
  final DateTime weekStart;
  final DateTime weekEnd;
  final List<PersonalizedInsight> insights;
  final Map<String, int> categoryBreakdown;
  final Map<InsightType, int> typeBreakdown;
  final double overallWellnessScore;
  final List<String> keyHighlights;
  final List<String> recommendations;
  final List<String> achievements;

  const WeeklyInsightsSummary({
    required this.weekStart,
    required this.weekEnd,
    required this.insights,
    this.categoryBreakdown = const {},
    this.typeBreakdown = const {},
    required this.overallWellnessScore,
    this.keyHighlights = const [],
    this.recommendations = const [],
    this.achievements = const [],
  });

  String get weekDescription {
    return '${weekStart.day}/${weekStart.month} - ${weekEnd.day}/${weekEnd.month}';
  }

  int get totalInsights => insights.length;
  int get positiveInsights => typeBreakdown[InsightType.positive] ?? 0;
  int get negativeInsights => typeBreakdown[InsightType.negative] ?? 0;
  int get actionableInsights => insights.where((i) => i.isActionable).length;

  String get wellnessGrade {
    if (overallWellnessScore >= 0.9) return 'ممتاز';
    if (overallWellnessScore >= 0.8) return 'جيد جداً';
    if (overallWellnessScore >= 0.7) return 'جيد';
    if (overallWellnessScore >= 0.6) return 'مقبول';
    if (overallWellnessScore >= 0.5) return 'يحتاج تحسين';
    return 'ضعيف';
  }

  @override
  String toString() {
    return 'WeeklyInsightsSummary($weekDescription: $totalInsights insights, $wellnessGrade)';
  }
}

/// Insights Tracking State class - فئة حالة تتبع الرؤى
class InsightsTrackingState extends BaseState {
  final List<PersonalizedInsight> currentInsights;
  final List<PersonalizedInsight> unshownInsights;
  final List<PersonalizedInsight> criticalInsights;
  final WeeklyInsightsSummary? currentWeekSummary;
  final Map<String, List<PersonalizedInsight>> insightsByCategory;
  final bool autoGenerationEnabled;
  final DateTime? lastGenerationTime;
  final int dailyInsightLimit;
  final List<String> preferredCategories;
  final List<WeeklyInsightsSummary> recentWeeklySummaries;

  InsightsTrackingState({
    super.loadingState,
    super.error,
    super.lastUpdated,
    super.hasData,
    super.successMessage,
    this.currentInsights = const [],
    this.unshownInsights = const [],
    this.criticalInsights = const [],
    this.currentWeekSummary,
    this.insightsByCategory = const {},
    this.autoGenerationEnabled = true,
    this.lastGenerationTime,
    this.dailyInsightLimit = 5,
    this.preferredCategories = const [],
    this.recentWeeklySummaries = const [],
  });

  factory InsightsTrackingState.initial() {
    return InsightsTrackingState(
      loadingState: LoadingState.idle,
      hasData: false,
    );
  }

  bool get hasInsights => currentInsights.isNotEmpty;
  bool get hasUnshownInsights => unshownInsights.isNotEmpty;
  bool get hasCriticalInsights => criticalInsights.isNotEmpty;
  bool get hasWeeklySummary => currentWeekSummary != null;

  int get totalInsights => currentInsights.length;
  int get positiveInsights => currentInsights.where((i) => i.type == InsightType.positive).length;
  int get negativeInsights => currentInsights.where((i) => i.type == InsightType.negative).length;
  int get actionableInsights => currentInsights.where((i) => i.isActionable).length;
  int get highPriorityInsights => currentInsights.where((i) => i.priority.index >= InsightPriority.high.index).length;

  List<PersonalizedInsight> get todaysInsights {
    final today = DateTime.now();
    return currentInsights.where((insight) {
      final insightDate = insight.createdAt;
      return insightDate.year == today.year &&
          insightDate.month == today.month &&
          insightDate.day == today.day;
    }).toList();
  }

  double get overallInsightScore {
    if (currentInsights.isEmpty) return 0.0;

    final positiveWeight = positiveInsights * 1.0;
    final negativeWeight = negativeInsights * -0.5;
    final totalWeight = positiveWeight + negativeWeight;

    return (totalWeight / currentInsights.length).clamp(-1.0, 1.0);
  }

  String get insightScoreDescription {
    final score = overallInsightScore;
    if (score >= 0.6) return 'رؤى إيجابية غالبة';
    if (score >= 0.2) return 'رؤى متوازنة';
    if (score >= -0.2) return 'رؤى محايدة';
    if (score >= -0.6) return 'رؤى تحتاج انتباه';
    return 'رؤى تحتاج تدخل فوري';
  }

  InsightsTrackingState copyWith({
    LoadingState? loadingState,
    AppError? error,
    DateTime? lastUpdated,
    bool? hasData,
    String? successMessage,
    List<PersonalizedInsight>? currentInsights,
    List<PersonalizedInsight>? unshownInsights,
    List<PersonalizedInsight>? criticalInsights,
    WeeklyInsightsSummary? currentWeekSummary,
    Map<String, List<PersonalizedInsight>>? insightsByCategory,
    bool? autoGenerationEnabled,
    DateTime? lastGenerationTime,
    int? dailyInsightLimit,
    List<String>? preferredCategories,
    List<WeeklyInsightsSummary>? recentWeeklySummaries,
  }) {
    return InsightsTrackingState(
      loadingState: loadingState ?? this.loadingState,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      hasData: hasData ?? this.hasData,
      successMessage: successMessage ?? this.successMessage,
      currentInsights: currentInsights ?? this.currentInsights,
      unshownInsights: unshownInsights ?? this.unshownInsights,
      criticalInsights: criticalInsights ?? this.criticalInsights,
      currentWeekSummary: currentWeekSummary ?? this.currentWeekSummary,
      insightsByCategory: insightsByCategory ?? this.insightsByCategory,
      autoGenerationEnabled: autoGenerationEnabled ?? this.autoGenerationEnabled,
      lastGenerationTime: lastGenerationTime ?? this.lastGenerationTime,
      dailyInsightLimit: dailyInsightLimit ?? this.dailyInsightLimit,
      preferredCategories: preferredCategories ?? this.preferredCategories,
      recentWeeklySummaries: recentWeeklySummaries ?? this.recentWeeklySummaries,
    );
  }
}

/// Insights Tracking Provider class - مزود تتبع الرؤى الذكية (محدث)
class InsightsTrackingProvider extends BaseProvider<InsightsTrackingState>
    with PeriodicUpdateMixin<InsightsTrackingState>, CacheMixin<InsightsTrackingState> {

  final InsightsRepository _insightsRepo;
  final InsightsService _insightsService;
  final NotificationService _notificationService;
  final StatisticsProvider? _statisticsProvider;

  Timer? _dailyGenerationTimer;
  Timer? _weeklyAnalysisTimer;

  bool _isGenerating = false;

  InsightsTrackingProvider({
    InsightsRepository? insightsRepo,
    InsightsService? insightsService,
    NotificationService? notificationService,
    StatisticsProvider? statisticsProvider,
  })  : _insightsRepo = insightsRepo ?? InsightsRepository(),
        _insightsService = insightsService ?? InsightsService.instance,
        _notificationService = notificationService ?? NotificationService.instance,
        _statisticsProvider = statisticsProvider,
        super(InsightsTrackingState.initial()) {

    debugPrint('💡 تهيئة InsightsTrackingProvider مع الخدمة الجديدة');
    _initializeProvider();
  }

  @override
  InsightsTrackingState _createLoadingState(bool isRefreshing) {
    return state.copyWith(
      loadingState: isRefreshing ? LoadingState.refreshing : LoadingState.loading,
      error: null,
      successMessage: null,
    );
  }

  @override
  InsightsTrackingState _createSuccessState() {
    return state.copyWith(
      loadingState: LoadingState.success,
      error: null,
      hasData: true,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  InsightsTrackingState _createErrorState(AppError error) {
    return state.copyWith(
      loadingState: LoadingState.error,
      error: error,
      successMessage: null,
    );
  }

  @override
  InsightsTrackingState _createIdleState() {
    return state.copyWith(
      loadingState: LoadingState.idle,
      error: null,
      successMessage: null,
    );
  }

  @override
  Future<void> refreshData() async {
    await _loadInitialData();
    await generateDailyInsights();
  }

  @override
  Future<void> performPeriodicUpdate() async {
    if (state.autoGenerationEnabled) {
      final now = DateTime.now();
      final lastGeneration = state.lastGenerationTime;

      if (lastGeneration == null || now.difference(lastGeneration).inHours >= 6) {
        await generateDailyInsights();
      }

      final validInsights = state.currentInsights.where((i) => !i.isExpired).toList();
      if (validInsights.length != state.currentInsights.length) {
        setState(state.copyWith(currentInsights: validInsights));
      }
    }
  }

  Future<void> _initializeProvider() async {
    try {
      debugPrint('💡 بدء تهيئة InsightsProvider...');

      setState(state.copyWith(
        loadingState: LoadingState.loading,
        error: null,
      ));

      await _insightsService.initialize();
      await _loadInitialData();
      await _scheduleAutomaticGeneration();

      setState(state.copyWith(
        loadingState: LoadingState.success,
        error: null,
        hasData: true,
        lastGenerationTime: DateTime.now(),
        lastUpdated: DateTime.now(),
      ));

      debugPrint('💡 تم تهيئة مزود الرؤى الذكية');

    } catch (e, stack) {
      debugPrint('❌ خطأ في تهيئة InsightsProvider: $e');
      debugPrint('Stack: $stack');

      setState(state.copyWith(
        loadingState: LoadingState.error,
        error: ServiceError(
          message: 'فشل في تهيئة الرؤى: $e',
          originalError: e,
          stackTrace: stack,
        ),
      ));
    }
  }

  /// توليد الرؤى اليومية
  Future<void> generateDailyInsights({String? targetDate}) async {
    if (_isGenerating) {
      debugPrint('⏳ توليد الرؤى جاري بالفعل، تخطي...');
      debugPrint('   - الرؤى الحالية في state: ${state.currentInsights.length}');
      return;
    }

    try {
      _isGenerating = true;

      final date = targetDate ?? _formatDate(DateTime.now());

      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('💡 [START] إنتاج الرؤى اليومية...');
      debugPrint('💡 التاريخ المستهدف: $date');
      debugPrint('💡 الرؤى الحالية قبل التوليد: ${state.currentInsights.length}');

      setState(state.copyWith(
        loadingState: LoadingState.loading,
        error: null,
      ));

      final rawInsights = await _insightsService.generateDailyInsights(date);

      debugPrint('💡 تم جلب ${rawInsights.length} رؤية من الخدمة');

      if (rawInsights.isEmpty) {
        debugPrint('⚠️ لا توجد رؤى من الخدمة!');

        if (state.currentInsights.isNotEmpty) {
          debugPrint('✅ الاحتفاظ بـ ${state.currentInsights.length} رؤية موجودة');

          setState(state.copyWith(
            loadingState: LoadingState.success,
            error: null,
            lastGenerationTime: DateTime.now(),
            lastUpdated: DateTime.now(),
          ));

          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
          return;
        }

        setState(state.copyWith(
          loadingState: LoadingState.success,
          error: null,
          lastGenerationTime: DateTime.now(),
          lastUpdated: DateTime.now(),
          successMessage: 'لا توجد رؤى متاحة حالياً',
        ));

        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
        return;
      }

      for (var i = 0; i < rawInsights.length; i++) {
        debugPrint('   ${i + 1}. ${rawInsights[i].title} (${rawInsights[i].category})');
      }

      final personalizedInsights = rawInsights
          .map((insight) => PersonalizedInsight.fromInsight(insight))
          .toList();

      debugPrint('💡 تم تحويل ${personalizedInsights.length} رؤية شخصية');

      final filteredInsights = await _applyQualityFilters(personalizedInsights);
      debugPrint('💡 بعد الفلترة: ${filteredInsights.length} رؤية');

      final limitedInsights = _applyDailyLimit(filteredInsights);
      debugPrint('💡 بعد التحديد اليومي: ${limitedInsights.length} رؤية');

      if (limitedInsights.isEmpty) {
        debugPrint('⚠️ لا توجد رؤى بعد الفلترة والتحديد!');

        if (state.currentInsights.isNotEmpty) {
          debugPrint('✅ الاحتفاظ بـ ${state.currentInsights.length} رؤية موجودة');

          setState(state.copyWith(
            loadingState: LoadingState.success,
            error: null,
            lastGenerationTime: DateTime.now(),
            lastUpdated: DateTime.now(),
          ));

          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
          return;
        }
      } else {
        debugPrint('✅ الرؤى النهائية:');
        for (var i = 0; i < limitedInsights.length; i++) {
          debugPrint('   ${i + 1}. ${limitedInsights[i].title}');
        }
      }

      // ✅ تحديث حالة الرؤى - بدون setState إضافي بعدها
      await _updateInsightsState(
        limitedInsights,
        lastGenerationTime: DateTime.now(),
        successMessage: limitedInsights.isNotEmpty
            ? 'تم إنتاج ${limitedInsights.length} رؤية جديدة'
            : null,
      );

      await _sendInsightNotifications(limitedInsights);

      debugPrint('✅ تم إنتاج ${limitedInsights.length} رؤية شخصية بنجاح');
      debugPrint('📊 إجمالي الرؤى الحالية في state: ${state.currentInsights.length}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    } catch (e, stack) {
      debugPrint('❌ خطأ في إنتاج الرؤى: $e');
      debugPrint('Stack: $stack');

      if (state.currentInsights.isNotEmpty) {
        debugPrint('✅ الاحتفاظ بـ ${state.currentInsights.length} رؤية موجودة عند حدوث خطأ');

        setState(state.copyWith(
          loadingState: LoadingState.error,
          error: ServiceError(
            message: 'فشل في إنتاج الرؤى: $e',
            originalError: e,
            stackTrace: stack,
            code: 'INSIGHTS_GENERATION_ERROR',
          ),
          lastUpdated: DateTime.now(),
        ));
        return;
      }

      setState(state.copyWith(
        loadingState: LoadingState.error,
        error: ServiceError(
          message: 'فشل في إنتاج الرؤى: $e',
          originalError: e,
          stackTrace: stack,
          code: 'INSIGHTS_GENERATION_ERROR',
        ),
        lastUpdated: DateTime.now(),
      ));

    } finally {
      _isGenerating = false;
      debugPrint('🔓 تم تحرير قفل التوليد (_isGenerating = false)');
    }
  }

  Future<void> markInsightAsShown(String insightId) async {
    try {
      final updatedInsights = state.currentInsights.map((insight) {
        if (insight.id == insightId) {
          return insight.copyWith(isShown: true);
        }
        return insight;
      }).toList();

      final updatedUnshown = state.unshownInsights.where((i) => i.id != insightId).toList();

      setState(state.copyWith(
        currentInsights: updatedInsights,
        unshownInsights: updatedUnshown,
      ));

    } catch (e) {
      debugPrint('❌ خطأ في تحديث حالة الرؤية: $e');
    }
  }

  Future<void> markInsightAsActedUpon(String insightId) async {
    try {
      final updatedInsights = state.currentInsights.map((insight) {
        if (insight.id == insightId) {
          return insight.copyWith(isActedUpon: true, isShown: true);
        }
        return insight;
      }).toList();

      setState(state.copyWith(currentInsights: updatedInsights));

    } catch (e) {
      debugPrint('❌ خطأ في تحديث حالة تنفيذ الرؤية: $e');
    }
  }

  List<PersonalizedInsight> getInsightsByCategory(String category) {
    return state.currentInsights.where((i) => i.category == category).toList();
  }

  List<PersonalizedInsight> getInsightsByPriority(InsightPriority priority) {
    return state.currentInsights.where((i) => i.priority == priority).toList();
  }

  Map<String, dynamic> getInsightsStatistics() {
    final serviceStats = _insightsService.getInsightsStatistics();

    return {
      ...serviceStats,
      'current_insights_count': state.totalInsights,
      'positive_insights': state.positiveInsights,
      'negative_insights': state.negativeInsights,
      'critical_insights': state.criticalInsights.length,
      'unshown_insights': state.unshownInsights.length,
      'todays_insights': state.todaysInsights.length,
      'overall_score': state.overallInsightScore,
      'score_description': state.insightScoreDescription,
    };
  }

  Future<void> _loadInitialData() async {
    try {
      debugPrint('📂 تحميل البيانات الأولية للرؤى...');
      setState(state.copyWith(hasData: true));
      debugPrint('✅ تم تحميل البيانات الأولية');
    } catch (e) {
      debugPrint('❌ خطأ في تحميل البيانات الأولية: $e');
    }
  }

  Future<void> _scheduleAutomaticGeneration() async {
    if (!state.autoGenerationEnabled) return;

    try {
      _dailyGenerationTimer = Timer.periodic(const Duration(hours: 6), (timer) async {
        if (!isDisposed && state.autoGenerationEnabled) {
          await generateDailyInsights();
        }
      });

      _weeklyAnalysisTimer = Timer.periodic(const Duration(days: 7), (timer) async {
        if (!isDisposed && state.autoGenerationEnabled) {
          await _generateWeeklySummary();
        }
      });

      debugPrint('⏰ تم جدولة التوليد التلقائي للرؤى');

    } catch (e) {
      debugPrint('❌ خطأ في جدولة التوليد التلقائي: $e');
    }
  }

  Future<List<PersonalizedInsight>> _applyQualityFilters(List<PersonalizedInsight> insights) async {
    debugPrint('🔍 تطبيق فلاتر الجودة...');
    debugPrint('   - رؤى قبل الفلترة: ${insights.length}');

    final filtered = insights.where((insight) {
      final hasGoodConfidence = insight.confidenceScore >= 0.6;
      final hasMessage = insight.message.trim().isNotEmpty;
      final notExpired = !insight.isExpired;

      if (!hasGoodConfidence) {
        debugPrint('   ✗ رؤية مرفوضة (confidence منخفض): ${insight.title} (${insight.confidenceScore})');
      }
      if (!hasMessage) {
        debugPrint('   ✗ رؤية مرفوضة (رسالة فارغة): ${insight.title}');
      }
      if (!notExpired) {
        debugPrint('   ✗ رؤية مرفوضة (منتهية الصلاحية): ${insight.title}');
      }

      return hasGoodConfidence && hasMessage && notExpired;
    }).toList();

    debugPrint('   - رؤى بعد الفلترة: ${filtered.length}');
    return filtered;
  }

  List<PersonalizedInsight> _applyDailyLimit(List<PersonalizedInsight> insights) {
    debugPrint('📊 تطبيق الحد اليومي (${state.dailyInsightLimit})...');

    insights.sort((a, b) {
      if (a.priority.index != b.priority.index) {
        return b.priority.index.compareTo(a.priority.index);
      }
      return b.confidenceScore.compareTo(a.confidenceScore);
    });

    final limited = insights.take(state.dailyInsightLimit).toList();
    debugPrint('   - رؤى بعد التحديد: ${limited.length}');

    return limited;
  }

  /// تحديث حالة الرؤى - ✅ محدّثة
  Future<void> _updateInsightsState(
      List<PersonalizedInsight> newInsights, {
        DateTime? lastGenerationTime,
        String? successMessage,
      }) async {
    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🔄 تحديث حالة الرؤى...');
      debugPrint('   - رؤى جديدة: ${newInsights.length}');
      debugPrint('   - رؤى حالية في state: ${state.currentInsights.length}');

      final existingIds = state.currentInsights.map((i) => i.id).toSet();
      debugPrint('   - IDs موجودة: ${existingIds.length}');

      final uniqueNewInsights = newInsights.where((i) => !existingIds.contains(i.id)).toList();

      debugPrint('   - رؤى فريدة جديدة: ${uniqueNewInsights.length}');

      if (uniqueNewInsights.isNotEmpty) {
        debugPrint('   ✅ رؤى جديدة للإضافة:');
        for (var i = 0; i < uniqueNewInsights.length; i++) {
          debugPrint('      ${i + 1}. ${uniqueNewInsights[i].title}');
        }
      } else {
        debugPrint('   ⚠️ لا توجد رؤى جديدة فريدة للإضافة');
      }

      final allInsights = [...state.currentInsights, ...uniqueNewInsights];
      final unshownInsights = allInsights.where((i) => !i.isShown).toList();
      final criticalInsights = allInsights.where((i) => i.priority == InsightPriority.critical).toList();

      final insightsByCategory = <String, List<PersonalizedInsight>>{};
      for (final insight in allInsights) {
        insightsByCategory[insight.category] = insightsByCategory[insight.category] ?? [];
        insightsByCategory[insight.category]!.add(insight);
      }

      // ✅ تحديث كل حاجة مرة واحدة
      setState(state.copyWith(
        loadingState: LoadingState.success,
        error: null,
        currentInsights: allInsights,
        unshownInsights: unshownInsights,
        criticalInsights: criticalInsights,
        insightsByCategory: insightsByCategory,
        lastGenerationTime: lastGenerationTime ?? state.lastGenerationTime,
        lastUpdated: DateTime.now(),
        successMessage: successMessage,
      ));

      debugPrint('✅ تم التحديث بنجاح:');
      debugPrint('   - إجمالي الرؤى: ${allInsights.length}');
      debugPrint('   - غير مُشاهدة: ${unshownInsights.length}');
      debugPrint('   - حرجة: ${criticalInsights.length}');
      debugPrint('   - حسب الفئة: ${insightsByCategory.length} فئات');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    } catch (e, stack) {
      debugPrint('❌ خطأ في تحديث حالة الرؤى: $e');
      debugPrint('Stack: $stack');
    }
  }

  Future<void> _sendInsightNotifications(List<PersonalizedInsight> insights) async {
    try {
      final criticalInsights = insights.where((i) => i.priority.index >= InsightPriority.high.index).toList();

      if (criticalInsights.isEmpty) {
        debugPrint('ℹ️ لا توجد رؤى حرجة لإرسال إشعارات');
        return;
      }

      debugPrint('📤 إرسال ${criticalInsights.length} إشعار للرؤى الحرجة...');

      for (final insight in criticalInsights) {
        await _notificationService.showNotification(
          id: 5000 + insight.id.hashCode,
          title: '${insight.priorityEmoji} ${insight.title}',
          body: insight.message,
          channelId: NotificationService.channelInsights,
          payload: {
            'type': 'insight',
            'insight_id': insight.id,
            'category': insight.category,
            'priority': insight.priority.name,
          },
        );

        await Future.delayed(const Duration(seconds: 1));
      }

      debugPrint('✅ تم إرسال ${criticalInsights.length} إشعار بنجاح');

    } catch (e) {
      debugPrint('❌ خطأ في إرسال إشعارات الرؤى: $e');
    }
  }

  Future<void> _generateWeeklySummary() async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));

      final weekInsights = state.currentInsights.where((insight) {
        return insight.createdAt.isAfter(weekStart) && insight.createdAt.isBefore(weekEnd);
      }).toList();

      if (weekInsights.isEmpty) return;

      final categoryBreakdown = <String, int>{};
      final typeBreakdown = <InsightType, int>{};

      for (final insight in weekInsights) {
        categoryBreakdown[insight.category] = (categoryBreakdown[insight.category] ?? 0) + 1;
        typeBreakdown[insight.type] = (typeBreakdown[insight.type] ?? 0) + 1;
      }

      final positiveCount = typeBreakdown[InsightType.positive] ?? 0;
      final negativeCount = typeBreakdown[InsightType.negative] ?? 0;
      final totalCount = weekInsights.length;

      final wellnessScore = totalCount > 0
          ? (positiveCount - (negativeCount * 0.5)) / totalCount
          : 0.0;

      final weeklySummary = WeeklyInsightsSummary(
        weekStart: weekStart,
        weekEnd: weekEnd,
        insights: weekInsights,
        categoryBreakdown: categoryBreakdown,
        typeBreakdown: typeBreakdown,
        overallWellnessScore: wellnessScore.clamp(0.0, 1.0),
        keyHighlights: [],
        recommendations: [],
        achievements: [],
      );

      final updatedWeeklySummaries = [weeklySummary, ...state.recentWeeklySummaries].take(4).toList();

      setState(state.copyWith(
        currentWeekSummary: weeklySummary,
        recentWeeklySummaries: updatedWeeklySummaries,
      ));

      debugPrint('📊 تم إنتاج الملخص الأسبوعي: ${weeklySummary.wellnessGrade}');

    } catch (e) {
      debugPrint('❌ خطأ في إنتاج الملخص الأسبوعي: $e');
    }
  }

  @override
  String get cacheKey => 'insights_tracking_state';

  @override
  Duration get cacheDuration => const Duration(hours: 1);

  @override
  Map<String, dynamic> serializeState(InsightsTrackingState state) {
    return {
      'auto_generation_enabled': state.autoGenerationEnabled,
      'daily_insight_limit': state.dailyInsightLimit,
      'last_generation_time': state.lastGenerationTime?.toIso8601String(),
    };
  }

  @override
  InsightsTrackingState deserializeState(Map<String, dynamic> data) {
    try {
      return state.copyWith(
        autoGenerationEnabled: data['auto_generation_enabled'] as bool? ?? true,
        dailyInsightLimit: data['daily_insight_limit'] as int? ?? 5,
        lastGenerationTime: data['last_generation_time'] != null
            ? DateTime.parse(data['last_generation_time'])
            : null,
      );
    } catch (e) {
      debugPrint('❌ خطأ في استرجاع الحالة من الذاكرة المؤقتة: $e');
      return state;
    }
  }

  @override
  Duration get updateInterval => const Duration(minutes: 30);

  @override
  bool get shouldAutoStart => true;

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    debugPrint('🗑️ تنظيف InsightsTrackingProvider');
    _dailyGenerationTimer?.cancel();
    _weeklyAnalysisTimer?.cancel();
    super.dispose();
  }
}