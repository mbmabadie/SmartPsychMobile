// lib/features/sleep/widgets/insights/insight_card.dart - النسخة البسيطة

import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../screens/sleep_insights_screen.dart';

class InsightCard extends StatelessWidget {
  final SleepInsight insight;

  const InsightCard({
    Key? key,
    required this.insight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: insight.color,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان مع الأيقونة
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: insight.color, width: 1),
                ),
                child: Icon(
                  insight.icon,
                  color: insight.color,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  insight.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _buildTypeBadge(),
            ],
          ),

          SizedBox(height: 16),

          // الرسالة
          Text(
            insight.message,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),

          // زر الإجراء (إذا وجد)
          if (insight.actionLabel != null) ...[
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: insight.onActionTap,
                icon: Icon(Icons.lightbulb_outline, size: 18),
                label: Text(insight.actionLabel!),
                style: OutlinedButton.styleFrom(
                  foregroundColor: insight.color,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: insight.color, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeBadge() {
    String emoji;
    switch (insight.type) {
      case InsightType.achievement:
        emoji = '🏆';
        break;
      case InsightType.warning:
        emoji = '⚠️';
        break;
      case InsightType.pattern:
        emoji = '📊';
        break;
      case InsightType.environment:
        emoji = '🌍';
        break;
      case InsightType.positive:
        emoji = '✅';
        break;
      case InsightType.improvement:
        emoji = '📈';
        break;
    }

    return Container(
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: insight.color, width: 1),
      ),
      child: Text(
        emoji,
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}