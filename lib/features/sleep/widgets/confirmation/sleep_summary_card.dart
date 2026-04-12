// lib/features/sleep/widgets/confirmation/sleep_summary_card.dart - النسخة البسيطة

import 'package:flutter/material.dart';
import '../../../../core/database/models/sleep_models.dart';
import '../../../../shared/theme/app_colors.dart';

class SleepSummaryCard extends StatelessWidget {
  final SleepSession session;
  final VoidCallback? onEditTimePressed;

  const SleepSummaryCard({
    Key? key,
    required this.session,
    this.onEditTimePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final duration = session.duration ??
        (session.endTime?.difference(session.startTime) ?? Duration.zero);

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary, width: 3),
      ),
      child: Column(
        children: [
          // الأيقونة
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Text(
              '🌅',
              style: TextStyle(fontSize: 48),
            ),
          ),

          SizedBox(height: 16),

          // العنوان
          Text(
            'صباح الخير!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          SizedBox(height: 8),

          Text(
            'اكتشفنا أنك نمت من:',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),

          SizedBox(height: 24),

          // التفاصيل
          Container(
            padding: EdgeInsets.all(20),
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
                // وقت النوم
                _buildTimeRow(
                  icon: '🌙',
                  time: _formatTime(session.startTime),
                  label: 'نام',
                ),

                SizedBox(height: 16),

                // المدة
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.access_time,
                      color: AppColors.primary,
                      size: 32,
                    ),
                    SizedBox(width: 12),
                    Text(
                      '${duration.inHours} س ${duration.inMinutes.remainder(60)} د',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // وقت الاستيقاظ
                _buildTimeRow(
                  icon: '☀️',
                  time: session.endTime != null
                      ? _formatTime(session.endTime!)
                      : '--:--',
                  label: 'استيقظ',
                ),
              ],
            ),
          ),

          if (onEditTimePressed != null) ...[
            SizedBox(height: 16),
            TextButton.icon(
              onPressed: onEditTimePressed,
              icon: Icon(Icons.edit, color: Colors.white, size: 20),
              label: Text(
                'تعديل الأوقات',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.white, width: 1),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeRow({
    required String icon,
    required String time,
    required String label,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(icon, style: TextStyle(fontSize: 24)),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              time,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12
        ? time.hour - 12
        : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'مساءً' : 'صباحاً';
    return '$hour:$minute $period';
  }
}