// lib/features/sleep/widgets/quality/environment_quality_card.dart - النسخة البسيطة

import 'package:flutter/material.dart';
import '../../../../core/database/models/environmental_conditions.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../core/theme/sleep_theme.dart';

class EnvironmentQualityCard extends StatelessWidget {
  final EnvironmentalConditions conditions;
  final double qualityScore;

  const EnvironmentQualityCard({
    Key? key,
    required this.conditions,
    required this.qualityScore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary, width: 1),
                ),
                child: Text('🌍', style: TextStyle(fontSize: 24)),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'جودة البيئة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _getQualityText(qualityScore),
                      style: TextStyle(
                        fontSize: 14,
                        color: _getQualityColor(qualityScore),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // الدرجة الكلية
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getQualityColor(qualityScore),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: _getQualityColor(qualityScore),
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${qualityScore.toStringAsFixed(1)}/10',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getQualityColor(qualityScore),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          // العوامل البيئية
          _buildQualityBar(
            context,
            '🌑 الإضاءة',
            _calculateLightScore(conditions.lightLevel),
            Colors.deepPurple,
            '${conditions.lightLevel?.toStringAsFixed(0) ?? '--'} lux',
          ),

          SizedBox(height: 12),

          _buildQualityBar(
            context,
            '🔇 الضجيج',
            _calculateNoiseScore(conditions.noiseLevel),
            Colors.blue,
            '${conditions.noiseLevel?.toStringAsFixed(0) ?? '--'} dB',
          ),

          if (conditions.temperature != null) ...[
            SizedBox(height: 12),
            _buildQualityBar(
              context,
              '🌡️ درجة الحرارة',
              _calculateTemperatureScore(conditions.temperature),
              Colors.orange,
              '${conditions.temperature!.toStringAsFixed(1)}°C',
            ),
          ],

          if (conditions.humidity != null) ...[
            SizedBox(height: 12),
            _buildQualityBar(
              context,
              '💧 الرطوبة',
              _calculateHumidityScore(conditions.humidity),
              Colors.cyan,
              '${conditions.humidity!.toStringAsFixed(0)}%',
            ),
          ],

          SizedBox(height: 16),

          // التوصية
          if (!conditions.isOptimalForSleep) ...[
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tips_and_updates,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getRecommendation(conditions),
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQualityBar(
      BuildContext context,
      String label,
      double score,
      Color color,
      String value,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        Stack(
          children: [
            // الخلفية
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // التقدم
            FractionallySizedBox(
              widthFactor: score / 10,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  double _calculateLightScore(double? light) {
    if (light == null) return 5.0;
    if (light <= 5) return 10.0;
    if (light <= 15) return 8.0;
    if (light <= 30) return 6.0;
    if (light <= 50) return 4.0;
    return 2.0;
  }

  double _calculateNoiseScore(double? noise) {
    if (noise == null) return 5.0;
    if (noise <= 30) return 10.0;
    if (noise <= 40) return 8.0;
    if (noise <= 50) return 6.0;
    if (noise <= 60) return 4.0;
    return 2.0;
  }

  double _calculateTemperatureScore(double? temp) {
    if (temp == null) return 5.0;
    if (temp >= 18 && temp <= 22) return 10.0;
    if (temp >= 16 && temp <= 24) return 7.0;
    if (temp >= 14 && temp <= 26) return 5.0;
    return 3.0;
  }

  double _calculateHumidityScore(double? humidity) {
    if (humidity == null) return 5.0;
    if (humidity >= 40 && humidity <= 60) return 10.0;
    if (humidity >= 30 && humidity <= 70) return 7.0;
    if (humidity >= 20 && humidity <= 80) return 5.0;
    return 3.0;
  }

  String _getQualityText(double score) {
    if (score >= 9) return 'ممتازة';
    if (score >= 7) return 'جيدة جداً';
    if (score >= 5) return 'جيدة';
    if (score >= 3) return 'متوسطة';
    return 'تحتاج تحسين';
  }

  Color _getQualityColor(double score) {
    if (score >= 9) return SleepColors.qualityExcellent;
    if (score >= 7) return SleepColors.qualityGood;
    if (score >= 5) return SleepColors.qualityFair;
    return SleepColors.qualityPoor;
  }

  String _getRecommendation(EnvironmentalConditions conditions) {
    if (conditions.lightLevel != null && conditions.lightLevel! > 30) {
      return 'قلل الإضاءة للحصول على نوم أفضل';
    }
    if (conditions.noiseLevel != null && conditions.noiseLevel! > 40) {
      return 'حاول تقليل الضجيج المحيط';
    }
    if (conditions.temperature != null) {
      if (conditions.temperature! < 18) {
        return 'الغرفة باردة قليلاً، الحرارة المثالية 18-22°C';
      }
      if (conditions.temperature! > 22) {
        return 'الغرفة دافئة قليلاً، الحرارة المثالية 18-22°C';
      }
    }
    return 'البيئة مناسبة للنوم';
  }
}