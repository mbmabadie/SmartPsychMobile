// lib/features/sleep/screens/sleep_quality_rating_screen.dart - النسخة البسيطة

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/sleep_tracking_provider.dart';
import '../../../shared/theme/app_colors.dart';

class SleepQualityRatingScreen extends StatefulWidget {
  final String sessionId;

  const SleepQualityRatingScreen({
    super.key,
    required this.sessionId,
  });

  @override
  State<SleepQualityRatingScreen> createState() => _SleepQualityRatingScreenState();
}

class _SleepQualityRatingScreenState extends State<SleepQualityRatingScreen> {
  double _qualityScore = 7.0;
  final Set<String> _selectedFactors = {};
  final TextEditingController _notesController = TextEditingController();

  final List<Map<String, dynamic>> _factors = [
    {'label': 'ضجيج', 'icon': '🔊', 'value': 'noise'},
    {'label': 'إضاءة', 'icon': '💡', 'value': 'light'},
    {'label': 'قلق', 'icon': '😰', 'value': 'anxiety'},
    {'label': 'مرض', 'icon': '🤒', 'value': 'sickness'},
    {'label': 'حرارة', 'icon': '🌡️', 'value': 'temperature'},
    {'label': 'كوابيس', 'icon': '😱', 'value': 'nightmares'},
    {'label': 'ألم', 'icon': '😣', 'value': 'pain'},
    {'label': 'توتر', 'icon': '😤', 'value': 'stress'},
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // المحتوى
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // المنزلق التفاعلي
                    _buildQualitySlider(),

                    const SizedBox(height: 32),

                    // العوامل المؤثرة
                    _buildFactorsSection(),

                    const SizedBox(height: 32),

                    // الملاحظات
                    _buildNotesSection(),

                    const SizedBox(height: 32),

                    // زر الحفظ
                    _buildSaveButton(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        border: Border(
          bottom: BorderSide(color: AppColors.primary, width: 3),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تقييم جودة النوم',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ساعدنا في تحسين تجربتك',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualitySlider() {
    final qualityColor = _getQualityColor(_qualityScore);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: qualityColor,
          width: 3,
        ),
      ),
      child: Column(
        children: [
          // الرمز التعبيري الكبير
          Text(
            _getQualityEmoji(_qualityScore),
            style: const TextStyle(fontSize: 80),
          ),

          const SizedBox(height: 16),

          // النص الوصفي
          Text(
            _getQualityText(_qualityScore),
            style: TextStyle(
              color: qualityColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // الدرجة
          Text(
            '${_qualityScore.toInt()} / 10',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 24),

          // المنزلق
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: qualityColor,
              inactiveTrackColor: AppColors.backgroundLight,
              thumbColor: qualityColor,
              overlayColor: qualityColor,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
              trackHeight: 8,
            ),
            child: Slider(
              value: _qualityScore,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (value) {
                setState(() {
                  _qualityScore = value;
                });
              },
            ),
          ),

          // المؤشرات
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'سيء جداً',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'ممتاز',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text('🔍', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text(
              'عوامل مؤثرة (اختياري)',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        const Text(
          'اختر العوامل التي أثرت على نومك',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),

        const SizedBox(height: 16),

        // Chips العوامل
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _factors.map((factor) {
            final isSelected = _selectedFactors.contains(factor['value']);

            return InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedFactors.remove(factor['value']);
                  } else {
                    _selectedFactors.add(factor['value']);
                  }
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      factor['icon'],
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      factor['label'],
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text('📝', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text(
              'ملاحظات (اختياري)',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        const Text(
          'أضف أي ملاحظات حول نومك',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),

        const SizedBox(height: 16),

        // حقل النص
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
          ),
          child: TextField(
            controller: _notesController,
            maxLines: 4,
            maxLength: 200,
            decoration: const InputDecoration(
              hintText: 'مثال: نمت جيداً لكن استيقظت مرتين...',
              hintStyle: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
              counterStyle: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveSleepQuality,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 24),
            SizedBox(width: 12),
            Text(
              'حفظ التقييم',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSleepQuality() async {
    final provider = context.read<SleepTrackingProvider>();

    // إضافة العوامل المؤثرة للملاحظات
    String fullNotes = _notesController.text.trim();
    List<String> factors = _selectedFactors.toList();

    if (_selectedFactors.isNotEmpty) {
      final factorsText = _selectedFactors.map((f) {
        final factor = _factors.firstWhere((item) => item['value'] == f);
        return '${factor['icon']} ${factor['label']}';
      }).join(', ');

      if (fullNotes.isNotEmpty) {
        fullNotes += '\n\nالعوامل المؤثرة: $factorsText';
      } else {
        fullNotes = 'العوامل المؤثرة: $factorsText';
      }
    }

    // حفظ التقييم
    await provider.confirmSleepSession(
      sessionId: widget.sessionId,
      qualityRating: _qualityScore,
      notes: fullNotes.isNotEmpty ? fullNotes : null,
      factors: factors.isNotEmpty ? factors : null,
    );

    if (!mounted) return;

    // إظهار رسالة نجاح
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Text('✅', style: TextStyle(fontSize: 20)),
            SizedBox(width: 12),
            Text('تم حفظ التقييم بنجاح!'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    // الرجوع
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    Navigator.pop(context);
    Navigator.pop(context);
  }

  Color _getQualityColor(double score) {
    if (score >= 8) return AppColors.success;
    if (score >= 6) return AppColors.warning;
    if (score >= 4) return AppColors.error;
    return AppColors.error;
  }

  String _getQualityEmoji(double score) {
    if (score >= 9) return '🌟';
    if (score >= 8) return '😊';
    if (score >= 7) return '🙂';
    if (score >= 6) return '😐';
    if (score >= 5) return '😕';
    if (score >= 4) return '😔';
    if (score >= 3) return '😞';
    if (score >= 2) return '😢';
    return '😫';
  }

  String _getQualityText(double score) {
    if (score >= 9) return 'ممتاز جداً!';
    if (score >= 8) return 'ممتاز';
    if (score >= 7) return 'جيد جداً';
    if (score >= 6) return 'جيد';
    if (score >= 5) return 'مقبول';
    if (score >= 4) return 'متوسط';
    if (score >= 3) return 'ضعيف';
    if (score >= 2) return 'سيء';
    return 'سيء جداً';
  }
}