// lib/features/sleep/widgets/confirmation/sleep_rating_slider.dart - النسخة البسيطة

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/theme/app_colors.dart';

class SleepRatingSlider extends StatefulWidget {
  final double initialRating;
  final ValueChanged<double> onRatingChanged;

  const SleepRatingSlider({
    Key? key,
    required this.initialRating,
    required this.onRatingChanged,
  }) : super(key: key);

  @override
  State<SleepRatingSlider> createState() => _SleepRatingSliderState();
}

class _SleepRatingSliderState extends State<SleepRatingSlider> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  void _onRatingChanged(double rating) {
    setState(() {
      _currentRating = rating;
    });
    widget.onRatingChanged(rating);

    // اهتزاز خفيف
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // الإيموجي
        Text(
          _getEmoji(_currentRating),
          style: TextStyle(fontSize: 80),
        ),

        SizedBox(height: 20),

        // النص الوصفي
        Text(
          _getRatingText(_currentRating),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _getRatingColor(_currentRating),
          ),
        ),

        SizedBox(height: 24),

        // المنزلق
        Row(
          children: [
            // الأيقونة اليسرى
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error, width: 2),
              ),
              child: Text('😴', style: TextStyle(fontSize: 24)),
            ),

            SizedBox(width: 12),

            // المنزلق
            Expanded(
              child: Stack(
                children: [
                  // الخلفية الملونة
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: AppColors.backgroundLight,
                    ),
                  ),

                  // المنزلق نفسه
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 8,
                      activeTrackColor: _getRatingColor(_currentRating),
                      inactiveTrackColor: Colors.transparent,
                      thumbColor: Colors.white,
                      thumbShape: CustomSliderThumb(
                        rating: _currentRating,
                      ),
                      overlayColor: AppColors.backgroundLight,
                      overlayShape: RoundSliderOverlayShape(overlayRadius: 20),
                    ),
                    child: Slider(
                      value: _currentRating,
                      min: 1.0,
                      max: 10.0,
                      divisions: 9,
                      onChanged: _onRatingChanged,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 12),

            // الأيقونة اليمنى
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success, width: 2),
              ),
              child: Text('🤩', style: TextStyle(fontSize: 24)),
            ),
          ],
        ),

        SizedBox(height: 16),

        // المقياس الرقمي
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getRatingColor(_currentRating),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_currentRating.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: _getRatingColor(_currentRating),
                ),
              ),
              Text(
                '/10',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 12),

        // النجوم
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final filled = index < (_currentRating / 2).round();
            return Icon(
              filled ? Icons.star : Icons.star_border,
              color: filled
                  ? _getRatingColor(_currentRating)
                  : AppColors.textMuted,
              size: 28,
            );
          }),
        ),
      ],
    );
  }

  String _getEmoji(double rating) {
    if (rating <= 2) return '😴';
    if (rating <= 4) return '😐';
    if (rating <= 6) return '🙂';
    if (rating <= 8) return '😊';
    return '🤩';
  }

  String _getRatingText(double rating) {
    if (rating <= 2) return 'سيء جداً';
    if (rating <= 4) return 'سيء';
    if (rating <= 6) return 'متوسط';
    if (rating <= 8) return 'جيد';
    if (rating <= 9) return 'ممتاز';
    return 'رائع!';
  }

  Color _getRatingColor(double rating) {
    if (rating <= 4) return AppColors.error;
    if (rating <= 7) return AppColors.warning;
    return AppColors.success;
  }
}

// شكل مخصص للـ Thumb
class CustomSliderThumb extends SliderComponentShape {
  final double rating;

  CustomSliderThumb({required this.rating});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(32, 32);
  }

  @override
  void paint(
      PaintingContext context,
      Offset center, {
        required Animation<double> activationAnimation,
        required Animation<double> enableAnimation,
        required bool isDiscrete,
        required TextPainter labelPainter,
        required RenderBox parentBox,
        required SliderThemeData sliderTheme,
        required TextDirection textDirection,
        required double value,
        required double textScaleFactor,
        required Size sizeWithOverflow,
      }) {
    final canvas = context.canvas;

    // الدائرة الخارجية
    final outerPaint = Paint()
      ..color = _getColor(rating)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 16, outerPaint);

    // الحد الأبيض
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, 16, borderPaint);

    // الدائرة الداخلية
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 8, innerPaint);
  }

  Color _getColor(double rating) {
    if (rating <= 4) return AppColors.error;
    if (rating <= 7) return AppColors.warning;
    return AppColors.success;
  }
}