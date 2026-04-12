// lib/features/sleep/widgets/hero_section/sleep_status_card.dart - النسخة البسيطة

import 'package:flutter/material.dart';
import '../../../../core/database/models/sleep_models.dart';
import '../../../../core/database/models/environmental_conditions.dart';
import '../../../../core/providers/sleep_tracking_state.dart';
import '../../../../shared/theme/app_colors.dart';

class SleepStatusCard extends StatelessWidget {
  final SleepSession session;
  final SleepState currentState;
  final EnvironmentalConditions? environment;

  const SleepStatusCard({
    Key? key,
    required this.session,
    required this.currentState,
    this.environment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final duration = DateTime.now().difference(session.startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary, width: 3),
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            // أيقونة النوم
            Text(
              '😴',
              style: TextStyle(fontSize: 80),
            ),

            SizedBox(height: 16),

            // النص
            Text(
              _getStateText(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            SizedBox(height: 24),

            // المدة
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '$hours س $minutes د',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 12),

            // وقت البداية
            Text(
              'بدأ النوم: ${_formatTime(session.startTime)}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),

            if (environment != null) ...[
              SizedBox(height: 24),

              // بيانات البيئة
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🌍 بيئة النوم',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildEnvironmentRow(
                      '🌑',
                      'ظلام تام',
                      '${environment!.lightLevel?.toStringAsFixed(0) ?? 0} lux',
                    ),
                    SizedBox(height: 8),
                    _buildEnvironmentRow(
                      '🔇',
                      'هادئ جداً',
                      '${environment!.noiseLevel?.toStringAsFixed(0) ?? 0} dB',
                    ),
                    SizedBox(height: 8),
                    _buildEnvironmentRow(
                      '🛏️',
                      'حركة قليلة',
                      _getMovementText(environment!.movementIntensity),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 20),

            // زر الإيقاظ اليدوي (نادر الاستخدام)
            TextButton.icon(
              onPressed: () {
                _showWakeUpConfirmation(context);
              },
              icon: Icon(Icons.alarm_off, color: Colors.white),
              label: Text(
                'إيقاظ يدوي',
                style: TextStyle(color: Colors.white),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white, width: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentRow(String icon, String label, String value) {
    return Row(
      children: [
        Text(icon, style: TextStyle(fontSize: 20)),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getStateText() {
    switch (currentState) {
      case SleepState.sleeping:
        return 'نائم حالياً';
      case SleepState.falling:
        return 'يدخل في النوم';
      case SleepState.restless:
        return 'نوم متقطع';
      default:
        return 'نائم';
    }
  }

  String _getMovementText(double? intensity) {
    if (intensity == null) return 'قليلة جداً';
    if (intensity < 0.1) return 'قليلة جداً';
    if (intensity < 0.3) return 'قليلة';
    if (intensity < 0.5) return 'متوسطة';
    return 'كثيرة';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'مساءً' : 'صباحاً';
    return '$hour:$minute $period';
  }

  void _showWakeUpConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            SizedBox(width: 8),
            Text('تأكيد الإيقاظ'),
          ],
        ),
        content: Text(
          'هل أنت متأكد أنك تريد إنهاء جلسة النوم يدوياً؟\n\n'
              'عادةً يتم اكتشاف الاستيقاظ تلقائياً.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: إنهاء جلسة النوم
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            child: Text('نعم، إنهاء النوم'),
          ),
        ],
      ),
    );
  }
}