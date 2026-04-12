// lib/features/sleep/widgets/insights/sleep_score_card.dart - النسخة البسيطة

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/providers/sleep_tracking_provider.dart';
import '../../../../shared/theme/app_colors.dart';

class SleepScoreCard extends StatelessWidget {
  final SleepTrackingProvider provider;

  const SleepScoreCard({
    Key? key,
    required this.provider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final score = _calculateOverallScore();
    final scoreData = _getScoreBreakdown();
    final scoreColor = _getScoreColor(score);

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scoreColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scoreColor, width: 3),
      ),
      child: Column(
        children: [
          // العنوان
          Text(
            'نقاط النوم الإجمالية',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          SizedBox(height: 24),

          // الدائرة التقدمية
          CustomPaint(
            size: Size(200, 200),
            painter: SleepScorePainter(
              score: score,
              color: Colors.white,
            ),
            child: Container(
              width: 200,
              height: 200,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    score.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '/100',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _getScoreLabel(score),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 32),

          // تفاصيل النقاط
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scoreColor,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                _buildScoreRow('الجودة', scoreData['quality']!, scoreColor),
                SizedBox(height: 8),
                _buildScoreRow('المدة', scoreData['duration']!, scoreColor),
                SizedBox(height: 8),
                _buildScoreRow('الانتظام', scoreData['consistency']!, scoreColor),
                SizedBox(height: 8),
                _buildScoreRow('البيئة', scoreData['environment']!, scoreColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String label, double value, Color color) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 8,
              backgroundColor: AppColors.backgroundLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        SizedBox(width: 8),
        SizedBox(
          width: 35,
          child: Text(
            '${value.toInt()}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  double _calculateOverallScore() {
    final breakdown = _getScoreBreakdown();
    final weights = {
      'quality': 0.35,
      'duration': 0.30,
      'consistency': 0.20,
      'environment': 0.15,
    };

    double total = 0.0;
    breakdown.forEach((key, value) {
      total += value * (weights[key] ?? 0.0);
    });

    return total.clamp(0.0, 100.0);
  }

  Map<String, double> _getScoreBreakdown() {
    final avgQuality = provider.state.averageQualityScore;
    final avgDuration = provider.state.averageSleepDuration;
    final goalHours = provider.state.sleepGoalHours;
    final sessions = provider.state.recentSessions;

    // جودة النوم (0-100)
    final qualityScore = (avgQuality / 10.0) * 100;

    // المدة (0-100)
    final actualHours = avgDuration.inMinutes / 60.0;
    final durationScore = (actualHours / goalHours) * 100;

    // الانتظام (0-100)
    final consistencyScore = _calculateConsistencyScore(sessions) * 100;

    // البيئة (0-100)
    final environmentScore = provider.state.environmentalQualityScore * 10;

    return {
      'quality': qualityScore.clamp(0.0, 100.0),
      'duration': durationScore.clamp(0.0, 100.0),
      'consistency': consistencyScore.clamp(0.0, 100.0),
      'environment': environmentScore.clamp(0.0, 100.0),
    };
  }

  double _calculateConsistencyScore(List sessions) {
    if (sessions.length < 3) return 0.5;

    final sleepTimes = sessions
        .map((s) => s.startTime.hour * 60 + s.startTime.minute)
        .toList();

    if (sleepTimes.isEmpty) return 0.5;

    final mean = sleepTimes.reduce((a, b) => a + b) / sleepTimes.length;
    final variance = sleepTimes
        .map((t) => math.pow(t - mean, 2))
        .reduce((a, b) => a + b) /
        sleepTimes.length;

    final stdDev = math.sqrt(variance);
    return (1.0 - (stdDev / 120)).clamp(0.0, 1.0);
  }

  String _getScoreLabel(double score) {
    if (score >= 90) return 'ممتاز';
    if (score >= 80) return 'جيد جداً';
    if (score >= 70) return 'جيد';
    if (score >= 60) return 'متوسط';
    return 'يحتاج تحسين';
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.primary;
    if (score >= 40) return AppColors.warning;
    return AppColors.error;
  }
}

// رسام الدائرة التقدمية
class SleepScorePainter extends CustomPainter {
  final double score;
  final Color color;

  SleepScorePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // الخلفية
    final backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(center, radius - 6, backgroundPaint);

    // التقدم
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (score / 100) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 6),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(SleepScorePainter oldDelegate) {
    return oldDelegate.score != score;
  }
}