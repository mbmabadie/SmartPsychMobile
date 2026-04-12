// lib/features/phone_usage/widgets/usage_insights_card.dart - النسخة النظيفة تماماً

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/providers/phone_usage_provider.dart';
import '../../../shared/theme/app_colors.dart';

class UsageInsightsCard extends StatelessWidget {
  final List<UsageAlert> alerts;
  final double wellnessScore;
  final Function(UsageAlert) onDismissAlert;

  const UsageInsightsCard({
    super.key,
    required this.alerts,
    required this.wellnessScore,
    required this.onDismissAlert,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (alerts.isNotEmpty) ...[
            Divider(height: 1, color: AppColors.border),
            _buildAlertsList(),
          ],
          _buildTipsSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: _getWellnessColor(),
                width: 2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    value: wellnessScore,
                    strokeWidth: 3,
                    backgroundColor: AppColors.backgroundLight,
                    valueColor: AlwaysStoppedAnimation<Color>(_getWellnessColor()),
                  ),
                ),
                Icon(
                  _getWellnessIcon(),
                  color: _getWellnessColor(),
                  size: 24,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تقييم الصحة الرقمية',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _getWellnessGrade(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _getWellnessColor(),
                      ),
                    ),
                    Text(
                      ' • ${(wellnessScore * 100).round()}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  _getWellnessDescription(),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (alerts.where((alert) => !alert.isShown).isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${alerts.where((alert) => !alert.isShown).length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAlertsList() {
    final unshownAlerts = alerts.where((alert) => !alert.isShown).toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: unshownAlerts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildAlertItem(unshownAlerts[index]);
      },
    );
  }

  Widget _buildAlertItem(UsageAlert alert) {
    return Dismissible(
      key: Key(alert.timestamp.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        HapticFeedback.lightImpact();
        onDismissAlert(alert);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getAlertColor(alert.severity),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getAlertColor(alert.severity),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getAlertIcon(alert.type),
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.message,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onDismissAlert(alert);
              },
              icon: Icon(
                Icons.close,
                color: AppColors.textMuted,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsSection() {
    final tips = _generateTips();

    if (tips.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'نصائح للتحسين',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Color _getWellnessColor() {
    if (wellnessScore >= 0.8) return AppColors.success;
    if (wellnessScore >= 0.6) return AppColors.warning;
    return AppColors.error;
  }

  IconData _getWellnessIcon() {
    if (wellnessScore >= 0.8) return Icons.sentiment_very_satisfied;
    if (wellnessScore >= 0.6) return Icons.sentiment_neutral;
    return Icons.sentiment_dissatisfied;
  }

  String _getWellnessGrade() {
    if (wellnessScore >= 0.9) return 'ممتاز';
    if (wellnessScore >= 0.8) return 'جيد جداً';
    if (wellnessScore >= 0.7) return 'جيد';
    if (wellnessScore >= 0.6) return 'مقبول';
    if (wellnessScore >= 0.5) return 'ضعيف';
    return 'ضعيف جداً';
  }

  String _getWellnessDescription() {
    if (wellnessScore >= 0.8) {
      return 'استخدام صحي ومتوازن للهاتف';
    } else if (wellnessScore >= 0.6) {
      return 'يمكن تحسين عادات الاستخدام';
    } else {
      return 'حاول تقليل وقت استخدام الهاتف';
    }
  }

  Color _getAlertColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return AppColors.info;
      case AlertSeverity.warning:
        return AppColors.warning;
      case AlertSeverity.critical:
        return AppColors.error;
    }
  }

  IconData _getAlertIcon(String type) {
    switch (type) {
      case 'excessive_usage':
        return Icons.schedule;
      case 'goal_exceeded':
        return Icons.flag;
      case 'night_usage':
        return Icons.nightlight_round;
      case 'excessive_pickups':
        return Icons.touch_app;
      default:
        return Icons.info;
    }
  }

  List<String> _generateTips() {
    final tips = <String>[];

    if (wellnessScore < 0.7) {
      tips.add('جرب تعيين هدف يومي أقل لاستخدام الهاتف');
      tips.add('استخدم وضع "عدم الإزعاج" أثناء فترات التركيز');
    }

    final hasNightUsage = alerts.any((alert) => alert.type == 'night_usage');
    if (hasNightUsage) {
      tips.add('تجنب استخدام الهاتف قبل النوم بساعة واحدة');
    }

    final hasExcessivePickups = alerts.any((alert) => alert.type == 'excessive_pickups');
    if (hasExcessivePickups) {
      tips.add('قم بإلغاء الإشعارات غير المهمة لتقليل مرات فتح الهاتف');
    }

    if (tips.isEmpty) {
      tips.add('استمر في الحفاظ على عادات الاستخدام الصحية');
    }

    return tips;
  }
}