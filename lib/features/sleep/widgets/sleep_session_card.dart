// lib/features/sleep/widgets/sleep_session_card.dart - النسخة المعدّلة مع التصنيف

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/sleep_tracking_provider.dart';
import '../../../core/database/models/sleep_confidence.dart';
import '../../../shared/theme/app_colors.dart';

class SleepSessionCard extends StatelessWidget {
  const SleepSessionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SleepTrackingProvider>(
      builder: (context, provider, child) {
        final session = provider.state.currentSession ??
            (provider.state.recentSessions.isNotEmpty
                ? provider.state.recentSessions.first
                : null);

        if (session == null) {
          return _buildEmptyState();
        }

        final isCompleted = session.isCompleted;

        // ✅ حساب المدة حسب حالة الجلسة
        final duration = isCompleted
            ? (session.duration ?? Duration.zero)
            : DateTime.now().difference(session.startTime);

        final quality = session.overallSleepQuality;
        final confidence = session.confidence;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.border,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // العنوان مع التصنيف
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary, width: 1),
                          ),
                          child: const Center(
                            child: Text('🛏️', style: TextStyle(fontSize: 20)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isCompleted ? 'آخر جلسة نوم' : 'جلسة حالية',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatDate(session.startTime),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // ✅ NEW: Badge التصنيف (أعلى من الجودة)
                    if (confidence != null)
                      _buildConfidenceBadge(confidence),
                  ],
                ),

                // ✅ NEW: Badge الجودة (تحت العنوان)
                if (isCompleted && quality > 0) ...[
                  const SizedBox(height: 12),
                  _buildQualityBadge(quality.toInt()),
                ],

                const SizedBox(height: 20),

                // التفاصيل
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary, width: 1),
                  ),
                  child: Column(
                    children: [
                      // الوقت والمدة
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDetailItem(
                            icon: '🌙',
                            label: 'البداية',
                            value: _formatTime(session.startTime),
                          ),
                          Container(
                            width: 2,
                            height: 40,
                            color: AppColors.primary,
                          ),
                          _buildDetailItem(
                            icon: '☀️',
                            label: 'النهاية',
                            value: session.endTime != null
                                ? _formatTime(session.endTime!)
                                : '--',
                          ),
                          Container(
                            width: 2,
                            height: 40,
                            color: AppColors.primary,
                          ),
                          _buildDetailItem(
                            icon: '⏱️',
                            label: 'المدة',
                            value: _formatDuration(duration),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      Divider(color: AppColors.primary, height: 1, thickness: 2),
                      const SizedBox(height: 16),

                      // إحصائيات إضافية
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            icon: '🔄',
                            label: 'الانقطاعات',
                            value: '${session.totalInterruptions}',
                            color: AppColors.warning,
                          ),
                          _buildStatItem(
                            icon: '📱',
                            label: 'استخدام الهاتف',
                            value: '${session.phoneActivations}',
                            color: AppColors.error,
                          ),
                          if (isCompleted && quality > 0)
                            _buildStatItem(
                              icon: '⭐',
                              label: 'الجودة',
                              value: '${quality.toStringAsFixed(1)}/10',
                              color: AppColors.success,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // الملاحظات
                if (session.notes != null && session.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('📝', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            session.notes!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // زر التقييم
                if (isCompleted && quality == 0) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: فتح شاشة التقييم
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('⭐', style: TextStyle(fontSize: 18)),
                          SizedBox(width: 8),
                          Text(
                            'تقييم جودة النوم',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════
  // ✅ NEW: Badge التصنيف
  // ════════════════════════════════════════════════════════════

  Widget _buildConfidenceBadge(SleepConfidence confidence) {
    final config = _getConfidenceConfig(confidence);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: config['backgroundColor'],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: config['borderColor'],
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            config['emoji'],
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 6),
          Text(
            config['displayName'],
            style: TextStyle(
              color: config['textColor'],
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getConfidenceConfig(SleepConfidence confidence) {
    switch (confidence) {
      case SleepConfidence.confirmed:
        return {
          'emoji': '💤',
          'displayName': 'نوم عميق',
          'backgroundColor': const Color(0xFFE8F5E9), // أخضر فاتح
          'borderColor': const Color(0xFF4CAF50),     // أخضر
          'textColor': const Color(0xFF2E7D32),       // أخضر غامق
        };

      case SleepConfidence.probable:
        return {
          'emoji': '😴',
          'displayName': 'قيلولة',
          'backgroundColor': const Color(0xFFFFF3E0), // برتقالي فاتح
          'borderColor': const Color(0xFFFF9800),     // برتقالي
          'textColor': const Color(0xFFE65100),       // برتقالي غامق
        };

      case SleepConfidence.uncertain:
        return {
          'emoji': '⏸️',
          'displayName': 'راحة قصيرة',
          'backgroundColor': const Color(0xFFFFF9C4), // أصفر فاتح
          'borderColor': const Color(0xFFFFEB3B),     // أصفر
          'textColor': const Color(0xFFF57F17),       // أصفر غامق
        };

      case SleepConfidence.phoneLeft:
        return {
          'emoji': '📱',
          'displayName': 'هاتف متروك',
          'backgroundColor': const Color(0xFFECEFF1), // رمادي فاتح
          'borderColor': const Color(0xFF90A4AE),     // رمادي
          'textColor': const Color(0xFF455A64),       // رمادي غامق
        };
    }
  }

  // ════════════════════════════════════════════════════════════
  // ✅ NEW: Badge الجودة (منفصل)
  // ════════════════════════════════════════════════════════════

  Widget _buildQualityBadge(int quality) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getQualityColor(quality),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getQualityBorderColor(quality),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getQualityEmoji(quality),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 6),
          Text(
            'جودة: ${quality}/10',
            style: TextStyle(
              color: _getQualityTextColor(quality),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // باقي الدوال
  // ════════════════════════════════════════════════════════════

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          const Text(
            '😴',
            style: TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد جلسات نوم بعد',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'سيبدأ التتبع التلقائي قريباً',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required String icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(icon, style: const TextStyle(fontSize: 18)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Color _getQualityColor(int quality) {
    if (quality >= 8) return const Color(0xFFE8F5E9);
    if (quality >= 5) return const Color(0xFFFFF3E0);
    return const Color(0xFFFFEBEE);
  }

  Color _getQualityBorderColor(int quality) {
    if (quality >= 8) return const Color(0xFF4CAF50);
    if (quality >= 5) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  Color _getQualityTextColor(int quality) {
    if (quality >= 8) return const Color(0xFF2E7D32);
    if (quality >= 5) return const Color(0xFFE65100);
    return const Color(0xFFC62828);
  }

  String _getQualityEmoji(int quality) {
    if (quality >= 9) return '🌟';
    if (quality >= 7) return '😊';
    if (quality >= 5) return '😐';
    if (quality >= 3) return '😔';
    return '😫';
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) {
      return 'اليوم';
    } else if (date == yesterday) {
      return 'أمس';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'م' : 'ص';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours == 0) return '${minutes}د';
    return '${hours}س ${minutes}د';
  }
}