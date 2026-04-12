// lib/features/sleep/widgets/history/sleep_session_card.dart - النسخة البسيطة

import 'package:flutter/material.dart';
import '../../../../core/database/models/sleep_models.dart';
import '../../../../shared/theme/app_colors.dart';

class SleepSessionCard extends StatelessWidget {
  final SleepSession session;
  final VoidCallback? onTap;

  const SleepSessionCard({
    Key? key,
    required this.session,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final duration = session.duration ?? Duration.zero;
    final quality = session.qualityScore ?? 0.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // التاريخ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary, width: 1),
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      _formatDate(session.startTime),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                _buildStatusBadge(),
              ],
            ),

            SizedBox(height: 12),

            // الأوقات
            Row(
              children: [
                Expanded(
                  child: _buildTimeInfo(
                    icon: '😴',
                    time: _formatTime(session.startTime),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ),
                Expanded(
                  child: _buildTimeInfo(
                    icon: '☀️',
                    time: session.endTime != null
                        ? _formatTime(session.endTime!)
                        : '--:--',
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            Divider(height: 1, thickness: 2, color: AppColors.border),

            SizedBox(height: 12),

            // المدة والجودة
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    icon: Icons.access_time,
                    label:
                    '${duration.inHours} س ${duration.inMinutes.remainder(60)} د',
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    icon: Icons.star,
                    label: '${quality.toStringAsFixed(1)}/10',
                    color: _getQualityColor(quality),
                  ),
                ),
              ],
            ),

            // الانقطاعات (إذا وجدت)
            if ((session.totalInterruptions ?? 0) > 0) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_active,
                      size: 14,
                      color: AppColors.warning,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'انقطاعات: ${session.totalInterruptions}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final status = session.userConfirmationStatus ?? 'pending';
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'confirmed':
        color = AppColors.success;
        text = 'مؤكد';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = AppColors.error;
        text = 'مرفوض';
        icon = Icons.cancel;
        break;
      default:
        color = AppColors.warning;
        text = 'معلق';
        icon = Icons.pending;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo({required String icon, required String time}) {
    return Row(
      children: [
        Text(icon, style: TextStyle(fontSize: 18)),
        SizedBox(width: 6),
        Text(
          time,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final days = [
      'الأحد',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت'
    ];
    final months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];

    return '${days[date.weekday % 7]}، ${date.day} ${months[date.month - 1]}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12
        ? time.hour - 12
        : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'مساءً' : 'صباحاً';
    return '$hour:$minute $period';
  }

  Color _getQualityColor(double quality) {
    if (quality >= 8) return AppColors.success;
    if (quality >= 6) return AppColors.primary;
    if (quality >= 4) return AppColors.warning;
    return AppColors.error;
  }
}