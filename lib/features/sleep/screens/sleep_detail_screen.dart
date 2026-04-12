// lib/features/sleep/screens/sleep_detail_screen.dart - النسخة البسيطة

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/database/models/sleep_models.dart';
import '../../../core/providers/sleep_tracking_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/unified_app_bar.dart';
import '../widgets/confirmation/time_adjustment_bottom_sheet.dart';
import 'package:share_plus/share_plus.dart';

class SleepDetailScreen extends StatelessWidget {
  final SleepSession session;

  const SleepDetailScreen({
    Key? key,
    required this.session,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final duration = session.duration ?? Duration.zero;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: UnifiedAppBar(
        greeting: _formatDate(session.startTime),
        subtitle: 'تفاصيل جلسة النوم',
        onNotificationTap: () {},
        onProfileTap: () {},
        hasNotificationBadge: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            _buildHeroSection(context),

            SizedBox(height: 16),

            // التوقيت
            _buildTimingCard(context),

            SizedBox(height: 16),

            // تفاصيل النوم
            _buildSleepDetailsCard(context, duration),

            SizedBox(height: 16),

            // الانقطاعات
            if ((session.totalInterruptions ?? 0) > 0)
              _buildInterruptionsCard(context),

            if ((session.totalInterruptions ?? 0) > 0)
              SizedBox(height: 16),

            // البيئة
            _buildEnvironmentCard(context),

            SizedBox(height: 16),

            // الملاحظات
            if (session.notes != null && session.notes!.isNotEmpty)
              _buildNotesCard(context),

            if (session.notes != null && session.notes!.isNotEmpty)
              SizedBox(height: 16),

            // الأزرار
            _buildActionButtons(context),

            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final quality = session.qualityScore ?? 0.0;
    final qualityColor = _getQualityColor(quality);

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: qualityColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: qualityColor, width: 3),
      ),
      child: Column(
        children: [
          // الأيقونة
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Text(
              _getQualityEmoji(quality),
              style: TextStyle(fontSize: 64),
            ),
          ),

          SizedBox(height: 16),

          // العنوان
          Text(
            _getQualityText(quality),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          SizedBox(height: 24),

          // التقييم
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
                ...List.generate(5, (index) {
                  return Icon(
                    index < (quality / 2).round()
                        ? Icons.star
                        : Icons.star_border,
                    color: qualityColor,
                    size: 28,
                  );
                }),
                SizedBox(width: 12),
                Text(
                  '${quality.toStringAsFixed(1)}/10',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: qualityColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingCard(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary, width: 1),
                ),
                child: Icon(
                  Icons.schedule,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                '📅 التوقيت',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildTimeInfo(
                  icon: '🌙',
                  label: 'نام',
                  time: _formatTime(session.startTime),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.arrow_forward,
                  color: AppColors.textMuted,
                ),
              ),
              Expanded(
                child: _buildTimeInfo(
                  icon: '☀️',
                  label: 'استيقظ',
                  time: session.endTime != null
                      ? _formatTime(session.endTime!)
                      : '--:--',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo({
    required String icon,
    required String label,
    required String time,
  }) {
    return Column(
      children: [
        Text(icon, style: TextStyle(fontSize: 32)),
        SizedBox(height: 8),
        Text(
          time,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSleepDetailsCard(BuildContext context, Duration duration) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary, width: 1),
                ),
                child: Icon(
                  Icons.insights,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                '📊 تفاصيل النوم',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          _buildProgressBar(
            label: '💤 نوم عميق',
            percentage: 0.65,
            color: AppColors.primary,
          ),

          SizedBox(height: 12),

          _buildProgressBar(
            label: '😴 نوم خفيف',
            percentage: 0.32,
            color: AppColors.info,
          ),

          SizedBox(height: 12),

          _buildProgressBar(
            label: '😮 مستيقظ',
            percentage: 0.03,
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar({
    required String label,
    required double percentage,
    required Color color,
  }) {
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
              ),
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: AppColors.backgroundLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildInterruptionsCard(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.notifications_active,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                '🔄 الانقطاعات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          _buildInterruptionItem(
            time: '12:30 صباحاً',
            reason: 'رسالة واتساب',
            icon: '📱',
          ),

          SizedBox(height: 12),

          _buildInterruptionItem(
            time: '3:15 صباحاً',
            reason: 'تململ',
            icon: '🔄',
          ),
        ],
      ),
    );
  }

  Widget _buildInterruptionItem({
    required String time,
    required String reason,
    required String icon,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warning,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(icon, style: TextStyle(fontSize: 20)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reason,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentCard(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.wb_sunny,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                '🌍 البيئة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          _buildEnvironmentRow('🌑', 'الإضاءة', 'ممتازة (3 lux)'),
          SizedBox(height: 12),
          _buildEnvironmentRow('🔇', 'الضجيج', 'هادئ جداً (18 dB)'),
          SizedBox(height: 12),
          _buildEnvironmentRow('🌡️', 'الحرارة', 'مثالية (20°C)'),
        ],
      ),
    );
  }

  Widget _buildEnvironmentRow(String icon, String label, String value) {
    return Row(
      children: [
        Text(icon, style: TextStyle(fontSize: 24)),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesCard(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary, width: 1),
                ),
                child: Icon(
                  Icons.notes,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                '📝 ملاحظاتك',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              session.notes ?? '',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final provider = context.read<SleepTrackingProvider>();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showEditDialog(context, provider),
              icon: Icon(Icons.edit),
              label: Text('تعديل'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: AppColors.primary, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          SizedBox(width: 12),

          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _shareSession(context),
              icon: Icon(Icons.share),
              label: Text('مشاركة'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.info,
                padding: EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: AppColors.info, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          SizedBox(width: 12),

          OutlinedButton(
            onPressed: () => _showDeleteDialog(context, provider),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              padding: EdgeInsets.all(16),
              side: BorderSide(color: AppColors.error, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Icon(Icons.delete),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
      BuildContext context,
      SleepTrackingProvider provider,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TimeAdjustmentBottomSheet(
        session: session,
        onTimesAdjusted: (newStartTime, newEndTime) async {
          await provider.modifySleepTimes(
            sessionId: session.id.toString(),
            newStartTime: newStartTime,
            newEndTime: newEndTime,
          );
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ تم تعديل الأوقات بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
        },
      ),
    );
  }

  void _shareSession(BuildContext context) {
    final duration = session.duration ?? Duration.zero;
    final quality = session.qualityScore ?? 0.0;

    final text = '''
🌙 سجل نومي - ${_formatDate(session.startTime)}

⏱️ المدة: ${duration.inHours} ساعات ${duration.inMinutes.remainder(60)} دقيقة
⭐ الجودة: ${quality.toStringAsFixed(1)}/10
🌙 نام: ${_formatTime(session.startTime)}
☀️ استيقظ: ${session.endTime != null ? _formatTime(session.endTime!) : '--'}

#تتبع_النوم #صحة
    ''';

    Share.share(text);
  }

  void _showDeleteDialog(
      BuildContext context,
      SleepTrackingProvider provider,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('حذف الجلسة'),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف هذه الجلسة؟\n'
              'لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              await provider.rejectSleepSession(
                session.id.toString(),
                reason: 'حذف من قبل المستخدم',
              );
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم حذف الجلسة'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text('حذف'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final days = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
    final months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];

    return '${days[date.weekday % 7]}، ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'مساءً' : 'صباحاً';
    return '$hour:$minute $period';
  }

  String _getQualityEmoji(double quality) {
    if (quality >= 9) return '🤩';
    if (quality >= 7) return '😊';
    if (quality >= 5) return '🙂';
    if (quality >= 3) return '😐';
    return '😴';
  }

  String _getQualityText(double quality) {
    if (quality >= 9) return 'نوم رائع!';
    if (quality >= 7) return 'نوم جيد جداً';
    if (quality >= 5) return 'نوم جيد';
    if (quality >= 3) return 'نوم متوسط';
    return 'نوم ضعيف';
  }

  Color _getQualityColor(double quality) {
    if (quality >= 8) return AppColors.success;
    if (quality >= 6) return AppColors.primary;
    if (quality >= 4) return AppColors.warning;
    return AppColors.error;
  }
}