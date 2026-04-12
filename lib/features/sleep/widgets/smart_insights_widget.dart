// lib/features/sleep/widgets/smart_insights_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/sleep_tracking_provider.dart';
import '../../../shared/theme/app_colors.dart';

class SmartInsightsWidget extends StatelessWidget {
  const SmartInsightsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lightbulb,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'الرؤى الذكية',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Insights List
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadInsights(context),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final insights = snapshot.data!;
                return Column(
                  children: insights.map((insight) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildInsightCard(
                        context,
                        insight: insight,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ✅ الكارد المعدّل - النص يظهر كاملاً بدون نقاط
  Widget _buildInsightCard(
      BuildContext context, {
        required Map<String, dynamic> insight,
      }) {
    final type = insight['type'] as String;
    final message = insight['message'] as String;
    final value = insight['value'] as String?;
    final priority = insight['priority'] as String; // high, medium, low

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getInsightColor(priority).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getInsightColor(priority).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row للأيقونة والـ Badge
          Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getInsightColor(priority).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getInsightIcon(type),
                  color: _getInsightColor(priority),
                  size: 20,
                ),
              ),

              const Spacer(),

              // Priority Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getInsightColor(priority),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getPriorityText(priority),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ✅ Content - النص كاملاً بدون تقطيع
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),

          if (value != null) ...[
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.auto_awesome,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد رؤى متاحة حالياً',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'جمّع المزيد من البيانات للحصول على رؤى ذكية',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadInsights(BuildContext context) async {
    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('💡 [SmartInsights] جلب الرؤى الذكية...');

      final provider = context.read<SleepTrackingProvider>();
      final insights = await provider.getSmartInsights();

      debugPrint('✅ [SmartInsights] تم جلب ${insights.length} رؤية');
      for (var i = 0; i < insights.length; i++) {
        debugPrint('   ${i + 1}. ${insights[i]['message']}');
      }
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      return insights;

    } catch (e, stack) {
      debugPrint('❌ [SmartInsights] خطأ في تحميل الرؤى: $e');
      debugPrint('Stack: $stack');
      return [];
    }
  }

  Color _getInsightColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red.shade600;
      case 'medium':
        return Colors.orange.shade600;
      case 'low':
        return AppColors.primary;
      default:
        return AppColors.primary;
    }
  }

  IconData _getInsightIcon(String type) {
    switch (type) {
      case 'sleep_debt':
        return Icons.warning;
      case 'consistency':
        return Icons.trending_up;
      case 'quality':
        return Icons.star;
      case 'pattern':
        return Icons.auto_graph;
      case 'recommendation':
        return Icons.tips_and_updates;
      default:
        return Icons.lightbulb;
    }
  }

  String _getPriorityText(String priority) {
    switch (priority) {
      case 'high':
        return 'مهم';
      case 'medium':
        return 'متوسط';
      case 'low':
        return 'عادي';
      default:
        return '';
    }
  }
}