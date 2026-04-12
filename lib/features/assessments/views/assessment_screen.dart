// lib/features/assessments/views/assessment_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/assessment_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/unified_app_bar.dart';

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({Key? key}) : super(key: key);

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssessmentProvider>().fetchActiveAssessment();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: UnifiedAppBar(
        greeting: 'الاختبارات النفسية',
        subtitle: 'قيّم حالتك',
        onNotificationTap: () {},
        onProfileTap: () {},
      ),
      body: Consumer<AssessmentProvider>(
        builder: (context, provider, _) {
          switch (provider.status) {
            case AssessmentStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case AssessmentStatus.error:
              return _buildError(provider);
            case AssessmentStatus.submitted:
              return _buildResult(provider);
            case AssessmentStatus.loaded:
            case AssessmentStatus.submitting:
              if (provider.activeAssessment == null) return _buildEmpty();
              if (provider.activeAssessment!.alreadyCompleted) return _buildAlreadyDone();
              return _buildAssessment(context, provider);
            default:
              return _buildEmpty();
          }
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // الحالات المختلفة
  // ═══════════════════════════════════════════════════════════

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 80, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text('لا يوجد اختبار نشط حالياً', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('سيتم إشعارك عند توفر اختبار جديد', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildAlreadyDone() {
    final provider = context.read<AssessmentProvider>();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_outline, size: 80, color: AppColors.success),
            ),
            const SizedBox(height: 24),
            const Text('أحسنت! لقد أكملت هذا الاختبار', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('سيتوفر اختبار جديد قريباً', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => provider.loadMyResults(),
              icon: const Icon(Icons.history),
              label: const Text('نتائجي السابقة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(AssessmentProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(provider.errorMessage ?? 'حدث خطأ', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.fetchActiveAssessment(),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(AssessmentProvider provider) {
    final result = provider.lastResult;
    if (result == null) return _buildEmpty();

    final percentage = result.scorePercentage;
    Color scoreColor;
    String scoreLabel;
    IconData scoreIcon;

    if (percentage >= 75) {
      scoreColor = AppColors.success;
      scoreLabel = 'ممتاز';
      scoreIcon = Icons.sentiment_very_satisfied;
    } else if (percentage >= 50) {
      scoreColor = AppColors.warning;
      scoreLabel = 'متوسط';
      scoreIcon = Icons.sentiment_neutral;
    } else {
      scoreColor = AppColors.error;
      scoreLabel = 'يحتاج متابعة';
      scoreIcon = Icons.sentiment_dissatisfied;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: scoreColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(scoreIcon, size: 80, color: scoreColor),
            ),
            const SizedBox(height: 24),
            const Text('تم إرسال إجاباتك بنجاح!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('${percentage.toStringAsFixed(0)}%', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: scoreColor)),
            Text(scoreLabel, style: TextStyle(fontSize: 18, color: scoreColor)),
            const SizedBox(height: 8),
            Text('${result.totalScore.toStringAsFixed(0)} / ${result.maxPossibleScore.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => provider.reset(),
              child: const Text('العودة'),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // عرض الاختبار
  // ═══════════════════════════════════════════════════════════

  Widget _buildAssessment(BuildContext context, AssessmentProvider provider) {
    final assessment = provider.activeAssessment!;
    final question = assessment.questions[provider.currentQuestionIndex];
    final isLast = provider.currentQuestionIndex == assessment.questions.length - 1;

    return Column(
      children: [
        // شريط التقدم + العنوان
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          color: AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('${provider.currentQuestionIndex + 1}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  Text(' / ${assessment.questions.length}', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                  const Spacer(),
                  Text('${(provider.progress * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: provider.progress,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),

        // السؤال
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // نص السؤال
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    question.questionTextAr ?? question.questionText,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.6),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),

                // الخيارات حسب نوع العرض
                _buildQuestionOptions(provider, question),
              ],
            ),
          ),
        ),

        // أزرار التنقل
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
          ),
          child: Row(
            children: [
              if (provider.currentQuestionIndex > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () { HapticFeedback.lightImpact(); provider.previousQuestion(); },
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    label: const Text('السابق'),
                  ),
                ),
              if (provider.currentQuestionIndex > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: isLast
                    ? (provider.allQuestionsAnswered && provider.status != AssessmentStatus.submitting
                        ? () { HapticFeedback.mediumImpact(); provider.submitResponses(); }
                        : null)
                    : () { HapticFeedback.lightImpact(); provider.nextQuestion(); },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLast ? AppColors.success : AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: provider.status == AssessmentStatus.submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(isLast ? 'إرسال الإجابات' : 'التالي', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 5 أشكال عرض مختلفة
  // ═══════════════════════════════════════════════════════════

  Widget _buildQuestionOptions(AssessmentProvider provider, AssessmentQuestion question) {
    switch (question.displayType) {
      case 'card_select':
        return _buildCardSelect(provider, question);
      case 'emoji_scale':
        return _buildEmojiScale(provider, question);
      case 'slider_select':
        return _buildSliderSelect(provider, question);
      case 'image_cards':
        return _buildImageCards(provider, question);
      case 'radio_list':
      default:
        return _buildRadioList(provider, question);
    }
  }

  // ─── 1. Radio List (قائمة عمودية) ───
  Widget _buildRadioList(AssessmentProvider provider, AssessmentQuestion question) {
    final selectedId = provider.selectedAnswers[question.id];

    return Column(
      children: question.options.map((option) {
        final isSelected = selectedId == option.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () => provider.selectAnswer(question.id, option.id, option.optionValue),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      border: Border.all(color: isSelected ? AppColors.primary : AppColors.textMuted, width: 2),
                    ),
                    child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(option.optionTextAr ?? option.optionText,
                      style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary)),
                  ),
                  if (option.emoji != null)
                    Text(option.emoji!, style: const TextStyle(fontSize: 20)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── 2. Card Select (بطاقات أفقية) ───
  Widget _buildCardSelect(AssessmentProvider provider, AssessmentQuestion question) {
    final selectedId = provider.selectedAnswers[question.id];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: question.options.map((option) {
        final isSelected = selectedId == option.id;
        return GestureDetector(
          onTap: () => provider.selectAnswer(question.id, option.id, option.optionValue),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: (MediaQuery.of(context).size.width - 60) / 2,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 2 : 1),
              boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))] : null,
            ),
            child: Column(
              children: [
                if (option.emoji != null)
                  Text(option.emoji!, style: const TextStyle(fontSize: 32)),
                if (option.emoji != null) const SizedBox(height: 8),
                Text(option.optionTextAr ?? option.optionText,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textPrimary),
                  textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── 3. Emoji Scale (مقياس إيموجي) ───
  Widget _buildEmojiScale(AssessmentProvider provider, AssessmentQuestion question) {
    final selectedId = provider.selectedAnswers[question.id];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: question.options.map((option) {
        final isSelected = selectedId == option.id;
        return GestureDetector(
          onTap: () => provider.selectAnswer(question.id, option.id, option.optionValue),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent, width: 3),
            ),
            child: Column(
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.3 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(option.emoji ?? '${option.optionValue}', style: const TextStyle(fontSize: 36)),
                ),
                const SizedBox(height: 6),
                Text(option.optionTextAr ?? option.optionText,
                  style: TextStyle(fontSize: 10, color: isSelected ? AppColors.primary : AppColors.textMuted, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400),
                  textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── 4. Slider Select (شريط تمرير) ───
  Widget _buildSliderSelect(AssessmentProvider provider, AssessmentQuestion question) {
    if (question.options.isEmpty) return const SizedBox();

    final selectedId = provider.selectedAnswers[question.id];
    final values = question.options.map((o) => o.optionValue.toDouble()).toList();
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);

    // العثور على القيمة الحالية
    double currentValue = minVal;
    if (selectedId != null) {
      final selected = question.options.where((o) => o.id == selectedId);
      if (selected.isNotEmpty) currentValue = selected.first.optionValue.toDouble();
    }

    // العثور على أقرب خيار
    QuestionOption currentOption = question.options.first;
    for (final o in question.options) {
      if ((o.optionValue.toDouble() - currentValue).abs() < (currentOption.optionValue.toDouble() - currentValue).abs()) {
        currentOption = o;
      }
    }

    return Column(
      children: [
        // التسمية الحالية
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Container(
            key: ValueKey(currentOption.id),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (currentOption.emoji != null) Text(currentOption.emoji!, style: const TextStyle(fontSize: 24)),
                if (currentOption.emoji != null) const SizedBox(width: 8),
                Text(currentOption.optionTextAr ?? currentOption.optionText,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // الشريط
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.2),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
          ),
          child: Slider(
            value: currentValue,
            min: minVal,
            max: maxVal,
            divisions: question.options.length - 1,
            onChanged: (value) {
              // العثور على أقرب خيار
              QuestionOption nearest = question.options.first;
              for (final o in question.options) {
                if ((o.optionValue.toDouble() - value).abs() < (nearest.optionValue.toDouble() - value).abs()) {
                  nearest = o;
                }
              }
              provider.selectAnswer(question.id, nearest.id, nearest.optionValue);
            },
          ),
        ),

        // التسميات تحت الشريط
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: question.options.map((o) => Text(
              o.emoji ?? '${o.optionValue}',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            )).toList(),
          ),
        ),
      ],
    );
  }

  // ─── 5. Image Cards (بطاقات بأيقونات) ───
  Widget _buildImageCards(AssessmentProvider provider, AssessmentQuestion question) {
    final selectedId = provider.selectedAnswers[question.id];

    // أيقونات افتراضية حسب القيمة
    final defaultIcons = [Icons.sentiment_very_dissatisfied, Icons.sentiment_dissatisfied, Icons.sentiment_neutral, Icons.sentiment_satisfied, Icons.sentiment_very_satisfied];

    return Column(
      children: question.options.asMap().entries.map((entry) {
        final i = entry.key;
        final option = entry.value;
        final isSelected = selectedId == option.id;
        final icon = i < defaultIcons.length ? defaultIcons[i] : Icons.circle;

        // ألوان متدرجة
        final colors = [AppColors.error, Color(0xFFFF7043), AppColors.warning, Color(0xFF66BB6A), AppColors.success];
        final color = i < colors.length ? colors[i] : AppColors.primary;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () => provider.selectAnswer(question.id, option.id, option.optionValue),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.12) : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? color : AppColors.border, width: isSelected ? 2 : 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.2) : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 28, color: isSelected ? color : AppColors.textMuted),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(option.optionTextAr ?? option.optionText,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isSelected ? color : AppColors.textPrimary)),
                        if (option.emoji != null)
                          Text(option.emoji!, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: color, size: 24),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
