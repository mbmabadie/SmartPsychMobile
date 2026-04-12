// lib/core/providers/assessment_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';

/// بيانات الاختبار النشط
@immutable
class ActiveAssessment {
  final int assessmentId;
  final int rotationId;
  final String? title;
  final String? titleAr;
  final String? description;
  final String? descriptionAr;
  final String? category;
  final String? scoringType;
  final double? maxScore;
  final String? startDate;
  final String? endDate;
  final bool alreadyCompleted;
  final List<AssessmentQuestion> questions;

  const ActiveAssessment({
    required this.assessmentId,
    required this.rotationId,
    this.title,
    this.titleAr,
    this.description,
    this.descriptionAr,
    this.category,
    this.scoringType,
    this.maxScore,
    this.startDate,
    this.endDate,
    this.alreadyCompleted = false,
    this.questions = const [],
  });
}

/// سؤال مع خيارات وشكل العرض
@immutable
class AssessmentQuestion {
  final int id;
  final String questionText;
  final String? questionTextAr;
  final String displayType; // radio_list, card_select, emoji_scale, slider_select, image_cards
  final int displayOrder;
  final bool isRequired;
  final List<QuestionOption> options;

  const AssessmentQuestion({
    required this.id,
    required this.questionText,
    this.questionTextAr,
    this.displayType = 'radio_list',
    this.displayOrder = 0,
    this.isRequired = true,
    this.options = const [],
  });
}

/// خيار إجابة
@immutable
class QuestionOption {
  final int id;
  final String optionText;
  final String? optionTextAr;
  final int optionValue;
  final int optionOrder;
  final String? emoji;
  final String? iconName;
  final String? colorHex;

  const QuestionOption({
    required this.id,
    required this.optionText,
    this.optionTextAr,
    required this.optionValue,
    this.optionOrder = 0,
    this.emoji,
    this.iconName,
    this.colorHex,
  });
}

/// نتيجة اختبار
@immutable
class AssessmentResult {
  final int sessionId;
  final double totalScore;
  final double maxPossibleScore;
  final double scorePercentage;
  final DateTime? completedAt;

  const AssessmentResult({
    required this.sessionId,
    required this.totalScore,
    required this.maxPossibleScore,
    required this.scorePercentage,
    this.completedAt,
  });
}

/// حالة الاختبار
enum AssessmentStatus { idle, loading, loaded, submitting, submitted, error }

class AssessmentProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;
  final SyncService _sync = SyncService.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  AssessmentStatus _status = AssessmentStatus.idle;
  ActiveAssessment? _activeAssessment;
  AssessmentResult? _lastResult;
  String? _errorMessage;
  Map<int, int> _selectedAnswers = {}; // questionId → optionId
  Map<int, int> _answerValues = {};    // questionId → value
  Map<int, int> _answerTimes = {};     // questionId → seconds
  int _currentQuestionIndex = 0;
  DateTime? _questionStartTime;
  List<AssessmentResult> _myResults = [];

  // Getters
  AssessmentStatus get status => _status;
  ActiveAssessment? get activeAssessment => _activeAssessment;
  AssessmentResult? get lastResult => _lastResult;
  String? get errorMessage => _errorMessage;
  Map<int, int> get selectedAnswers => _selectedAnswers;
  int get currentQuestionIndex => _currentQuestionIndex;
  List<AssessmentResult> get myResults => _myResults;

  bool get hasActiveAssessment => _activeAssessment != null && !_activeAssessment!.alreadyCompleted;
  bool get allQuestionsAnswered {
    if (_activeAssessment == null) return false;
    final required = _activeAssessment!.questions.where((q) => q.isRequired).toList();
    return required.every((q) => _selectedAnswers.containsKey(q.id));
  }

  int get answeredCount => _selectedAnswers.length;
  int get totalQuestions => _activeAssessment?.questions.length ?? 0;
  double get progress => totalQuestions > 0 ? answeredCount / totalQuestions : 0;

  // ═══════════════════════════════════════════════════════════
  // جلب الاختبار النشط
  // ═══════════════════════════════════════════════════════════

  Future<void> fetchActiveAssessment() async {
    _status = AssessmentStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // أولاً: حاول من السيرفر
      if (_api.isAuthenticated) {
        final data = await _sync.fetchAndCacheActiveAssessment();
        if (data != null) {
          _parseAssessmentData(data);
          _status = AssessmentStatus.loaded;
          notifyListeners();
          return;
        }
      }

      // ثانياً: من الكاش المحلي
      await _loadFromCache();

      _status = _activeAssessment != null ? AssessmentStatus.loaded : AssessmentStatus.idle;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ خطأ في جلب الاختبار: $e');
      _errorMessage = 'فشل في جلب الاختبار';
      _status = AssessmentStatus.error;
      notifyListeners();
    }
  }

  void _parseAssessmentData(Map<String, dynamic> data) {
    final questionsData = data['questions'] as List<dynamic>? ?? [];

    _activeAssessment = ActiveAssessment(
      assessmentId: data['assessment_id'] ?? 0,
      rotationId: data['rotation_id'] ?? 0,
      title: data['title'],
      titleAr: data['title_ar'],
      description: data['description'],
      descriptionAr: data['description_ar'],
      category: data['category'],
      scoringType: data['scoring_type'],
      maxScore: (data['max_score'] as num?)?.toDouble(),
      startDate: data['start_date'],
      endDate: data['end_date'],
      alreadyCompleted: data['already_completed'] == true,
      questions: questionsData.map((q) {
        final optionsData = q['options'] as List<dynamic>? ?? [];
        return AssessmentQuestion(
          id: q['question_id'] ?? q['id'] ?? 0,
          questionText: q['question_text'] ?? '',
          questionTextAr: q['question_text_ar'],
          displayType: q['display_type'] ?? 'radio_list',
          displayOrder: q['display_order'] ?? 0,
          isRequired: q['is_required'] != 0 && q['is_required'] != false,
          options: optionsData.map((o) => QuestionOption(
            id: o['id'] ?? 0,
            optionText: o['option_text'] ?? '',
            optionTextAr: o['option_text_ar'],
            optionValue: o['option_value'] ?? 0,
            optionOrder: o['option_order'] ?? 0,
            emoji: o['emoji'],
            iconName: o['icon_name'],
            colorHex: o['color_hex'],
          )).toList(),
        );
      }).toList(),
    );

    _selectedAnswers = {};
    _answerValues = {};
    _answerTimes = {};
    _currentQuestionIndex = 0;
  }

  Future<void> _loadFromCache() async {
    try {
      final db = await _dbHelper.database;
      final assessments = await db.query('cached_assessments', limit: 1);
      if (assessments.isEmpty) return;

      final a = assessments.first;
      final questions = await db.query('cached_questions',
        where: 'assessment_id = ?', whereArgs: [a['id']], orderBy: 'display_order ASC');

      final questionsList = <AssessmentQuestion>[];
      for (final q in questions) {
        final options = await db.query('cached_options',
          where: 'question_id = ?', whereArgs: [q['id']], orderBy: 'option_order ASC');

        questionsList.add(AssessmentQuestion(
          id: q['id'] as int,
          questionText: q['question_text'] as String,
          questionTextAr: q['question_text_ar'] as String?,
          displayType: q['display_type'] as String? ?? 'radio_list',
          displayOrder: q['display_order'] as int? ?? 0,
          isRequired: (q['is_required'] as int?) == 1,
          options: options.map((o) => QuestionOption(
            id: o['id'] as int,
            optionText: o['option_text'] as String,
            optionTextAr: o['option_text_ar'] as String?,
            optionValue: o['option_value'] as int,
            optionOrder: o['option_order'] as int? ?? 0,
            emoji: o['emoji'] as String?,
            iconName: o['icon_name'] as String?,
            colorHex: o['color_hex'] as String?,
          )).toList(),
        ));
      }

      _activeAssessment = ActiveAssessment(
        assessmentId: a['id'] as int,
        rotationId: a['rotation_id'] as int,
        title: a['title'] as String?,
        titleAr: a['title_ar'] as String?,
        description: a['description'] as String?,
        descriptionAr: a['description_ar'] as String?,
        category: a['category'] as String?,
        maxScore: (a['max_score'] as num?)?.toDouble(),
        questions: questionsList,
      );
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الكاش: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // اختيار إجابة
  // ═══════════════════════════════════════════════════════════

  void selectAnswer(int questionId, int optionId, int value) {
    _selectedAnswers[questionId] = optionId;
    _answerValues[questionId] = value;

    // حساب وقت الإجابة
    if (_questionStartTime != null) {
      final seconds = DateTime.now().difference(_questionStartTime!).inSeconds;
      _answerTimes[questionId] = seconds;
    }

    notifyListeners();
  }

  void goToQuestion(int index) {
    if (index >= 0 && index < totalQuestions) {
      _currentQuestionIndex = index;
      _questionStartTime = DateTime.now();
      notifyListeners();
    }
  }

  void nextQuestion() {
    if (_currentQuestionIndex < totalQuestions - 1) {
      goToQuestion(_currentQuestionIndex + 1);
    }
  }

  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      goToQuestion(_currentQuestionIndex - 1);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // إرسال الإجابات
  // ═══════════════════════════════════════════════════════════

  Future<bool> submitResponses() async {
    if (_activeAssessment == null || !allQuestionsAnswered) return false;

    _status = AssessmentStatus.submitting;
    notifyListeners();

    try {
      final now = DateTime.now();

      // حساب النتيجة
      double totalScore = 0;
      double maxPossible = 0;
      for (final q in _activeAssessment!.questions) {
        if (_answerValues.containsKey(q.id)) {
          totalScore += _answerValues[q.id]!;
        }
        final maxOption = q.options.isEmpty ? 0 : q.options.map((o) => o.optionValue).reduce((a, b) => a > b ? a : b);
        maxPossible += maxOption;
      }
      final percentage = maxPossible > 0 ? (totalScore / maxPossible) * 100 : 0;

      // 1. حفظ محلياً
      final db = await _dbHelper.database;
      final sessionId = await db.insert('assessment_sessions', {
        'rotation_id': _activeAssessment!.rotationId,
        'total_score': totalScore,
        'max_possible_score': maxPossible,
        'score_percentage': percentage,
        'is_completed': 1,
        'started_at': now.subtract(Duration(minutes: totalQuestions * 2)).millisecondsSinceEpoch,
        'completed_at': now.millisecondsSinceEpoch,
        'synced': 0,
      });

      final responses = <Map<String, dynamic>>[];
      for (final entry in _selectedAnswers.entries) {
        final responseData = {
          'session_id': sessionId,
          'question_id': entry.key,
          'selected_option_id': entry.value,
          'response_value': _answerValues[entry.key] ?? 0,
          'response_time_seconds': _answerTimes[entry.key],
          'answered_at': now.millisecondsSinceEpoch,
        };
        await db.insert('assessment_responses', responseData);
        responses.add({
          'question_id': entry.key,
          'selected_option_id': entry.value,
          'response_value': _answerValues[entry.key] ?? 0,
          'response_time_seconds': _answerTimes[entry.key],
        });
      }

      // 2. محاولة الرفع للسيرفر
      if (_api.isAuthenticated) {
        try {
          final result = await _api.submitAssessmentResponses({
            'rotation_id': _activeAssessment!.rotationId,
            'responses': responses,
          });

          if (result['success'] == true) {
            await db.update('assessment_sessions', {'synced': 1, 'last_sync_time': now.millisecondsSinceEpoch},
              where: 'id = ?', whereArgs: [sessionId]);
            debugPrint('✅ تم رفع الإجابات للسيرفر');
          }
        } catch (e) {
          debugPrint('⚠️ فشل الرفع - ستتم المزامنة لاحقاً: $e');
        }
      }

      _lastResult = AssessmentResult(
        sessionId: sessionId,
        totalScore: totalScore,
        maxPossibleScore: maxPossible,
        scorePercentage: percentage,
        completedAt: now,
      );

      _status = AssessmentStatus.submitted;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في إرسال الإجابات: $e');
      _errorMessage = 'فشل في حفظ الإجابات';
      _status = AssessmentStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // نتائجي السابقة
  // ═══════════════════════════════════════════════════════════

  Future<void> loadMyResults() async {
    try {
      final db = await _dbHelper.database;
      final sessions = await db.query('assessment_sessions',
        where: 'is_completed = 1', orderBy: 'completed_at DESC', limit: 20);

      _myResults = sessions.map((s) => AssessmentResult(
        sessionId: s['id'] as int,
        totalScore: (s['total_score'] as num?)?.toDouble() ?? 0,
        maxPossibleScore: (s['max_possible_score'] as num?)?.toDouble() ?? 0,
        scorePercentage: (s['score_percentage'] as num?)?.toDouble() ?? 0,
        completedAt: s['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(s['completed_at'] as int)
          : null,
      )).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('❌ خطأ في تحميل النتائج: $e');
    }
  }

  /// إعادة تهيئة للاختبار التالي
  void reset() {
    _selectedAnswers = {};
    _answerValues = {};
    _answerTimes = {};
    _currentQuestionIndex = 0;
    _lastResult = null;
    _status = AssessmentStatus.idle;
    notifyListeners();
  }
}
