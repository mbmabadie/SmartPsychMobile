// lib/features/sleep/widgets/hero_section/awake_status_card.dart - النسخة البسيطة

import 'package:flutter/material.dart';
import '../../../../core/database/models/sleep_models.dart';
import '../../../../shared/theme/app_colors.dart';

class AwakeStatusCard extends StatelessWidget {
  final SleepSession? lastSession;
  final bool hasPendingConfirmation;
  final VoidCallback? onConfirmPressed;

  const AwakeStatusCard({
    Key? key,
    this.lastSession,
    required this.hasPendingConfirmation,
    this.onConfirmPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.warning,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.warning, width: 3),
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            // أيقونة الاستيقاظ
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  '☀️',
                  style: TextStyle(fontSize: 60),
                ),
              ),
            ),

            SizedBox(height: 16),

            // النص
            Text(
              'مستيقظ',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            if (lastSession != null) ...[
              SizedBox(height: 24),

              // معلومات آخر نوم
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
                  children: [
                    Text(
                      'الليلة الماضية',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    SizedBox(height: 12),

                    // المدة
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bedtime,
                          color: AppColors.warning,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          _getDurationText(lastSession!.duration),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),

                    if (lastSession!.qualityScore != null) ...[
                      SizedBox(height: 8),

                      // الجودة
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'جودة: ',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          ...List.generate(
                            5,
                                (index) => Icon(
                              index < (lastSession!.qualityScore! / 2).round()
                                  ? Icons.star
                                  : Icons.star_border,
                              color: AppColors.warning,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${lastSession!.qualityScore!.toStringAsFixed(1)}/10',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],

                    SizedBox(height: 12),

                    // الأوقات
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              _formatTime(lastSession!.startTime),
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'نام',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        Icon(
                          Icons.arrow_forward,
                          color: AppColors.textSecondary,
                        ),

                        Column(
                          children: [
                            Text(
                              lastSession!.endTime != null
                                  ? _formatTime(lastSession!.endTime!)
                                  : '--:--',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'استيقظ',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            if (hasPendingConfirmation) ...[
              SizedBox(height: 20),

              // تحذير التأكيد
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.notification_important,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'يحتاج تأكيد وتقييم',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12),

              // زر التأكيد
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onConfirmPressed,
                  icon: Icon(Icons.check_circle_outline),
                  label: Text('تأكيد وتقييم الآن'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.warning,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],

            if (!hasPendingConfirmation && lastSession == null) ...[
              SizedBox(height: 20),

              // رسالة ترحيبية
              Text(
                'استمتع بيومك! 😊',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),

              SizedBox(height: 8),

              Text(
                'سنتتبع نومك تلقائياً الليلة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getDurationText(Duration? duration) {
    if (duration == null) return '--';
    return '${duration.inHours} س ${duration.inMinutes.remainder(60)} د';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'مساءً' : 'صباحاً';
    return '$hour:$minute $period';
  }
}