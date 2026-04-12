// lib/features/location/widgets/location_insights_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/theme/app_colors.dart';

class LocationInsightsCard extends StatelessWidget {
  final List<Map<String, dynamic>> insights;
  final Map<String, dynamic> analytics;

  const LocationInsightsCard({
    Key? key,
    required this.insights,
    required this.analytics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with location score
          _buildHeader(),

          // Insights list
          if (insights.isNotEmpty) ...[
            Divider(height: 1, color: AppColors.border),
            _buildInsightsList(),
          ],

          // Tips and recommendations
          _buildTipsSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final totalVisits = analytics['total_visits'] ?? 0;
    final uniquePlaces = analytics['unique_places'] ?? 0;
    final mobilityScore = _calculateMobilityScore();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Mobility indicator
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _getMobilityColor(),
              shape: BoxShape.circle,
              border: Border.all(
                color: _getMobilityColor(),
                width: 2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Progress circle
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    value: mobilityScore,
                    strokeWidth: 3,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),

                // Icon
                Icon(
                  _getMobilityIcon(),
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Mobility info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تحليل الحركة والنشاط',
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
                      _getMobilityGrade(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _getMobilityColor(),
                      ),
                    ),
                    Text(
                      ' • ${(mobilityScore * 100).round()}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$totalVisits زيارة • $uniquePlaces مكان',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Insights count
          if (insights.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${insights.length}',
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

  Widget _buildInsightsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: insights.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildInsightItem(insights[index]),
    );
  }

  Widget _buildInsightItem(Map<String, dynamic> insight) {
    final type = insight['type'] as String;
    final title = insight['title'] as String;
    final description = insight['description'] as String;
    final value = insight['value'];
    final icon = insight['icon'] as String? ?? 'info';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getInsightColor(type),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Insight icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getInsightColor(type),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getInsightIcon(icon),
              color: Colors.white,
              size: 16,
            ),
          ),

          const SizedBox(width: 12),

          // Insight content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (value != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getInsightColor(type),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          value.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          // Action button (if needed)
          if (type == 'most_visited' || type == 'exploration')
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
              },
              icon: Icon(
                Icons.info_outline,
                color: AppColors.textMuted,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTipsSection() {
    final tips = _generateLocationTips();

    if (tips.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppColors.secondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'نصائح للحركة',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
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
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
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

  // Helper methods
  double _calculateMobilityScore() {
    final totalVisits = analytics['total_visits'] as int? ?? 0;
    final uniquePlaces = analytics['unique_places'] as int? ?? 0;
    final homeVisits = analytics['home_visits'] as int? ?? 0;
    final workVisits = analytics['work_visits'] as int? ?? 0;

    if (totalVisits == 0) return 0.0;

    // Calculate mobility based on variety and frequency
    double varietyScore = uniquePlaces > 0 ? (uniquePlaces / 20.0).clamp(0.0, 1.0) : 0.0;
    double activityScore = totalVisits > 0 ? (totalVisits / 50.0).clamp(0.0, 1.0) : 0.0;
    double routineBalance = 0.5;

    if (totalVisits > 0) {
      final routineVisits = homeVisits + workVisits;
      final routineRatio = routineVisits / totalVisits;
      // Good balance is around 60-70% routine
      if (routineRatio >= 0.6 && routineRatio <= 0.7) {
        routineBalance = 1.0;
      } else if (routineRatio >= 0.4 && routineRatio <= 0.8) {
        routineBalance = 0.8;
      } else {
        routineBalance = 0.4;
      }
    }

    return (varietyScore * 0.4 + activityScore * 0.3 + routineBalance * 0.3).clamp(0.0, 1.0);
  }

  Color _getMobilityColor() {
    final score = _calculateMobilityScore();
    if (score >= 0.8) return AppColors.success;
    if (score >= 0.6) return AppColors.warning;
    if (score >= 0.4) return AppColors.secondary;
    return AppColors.error;
  }

  IconData _getMobilityIcon() {
    final score = _calculateMobilityScore();
    if (score >= 0.8) return Icons.directions_walk;
    if (score >= 0.6) return Icons.explore;
    if (score >= 0.4) return Icons.location_on;
    return Icons.home;
  }

  String _getMobilityGrade() {
    final score = _calculateMobilityScore();
    if (score >= 0.9) return 'نشاط ممتاز';
    if (score >= 0.8) return 'نشاط جيد جداً';
    if (score >= 0.7) return 'نشاط جيد';
    if (score >= 0.6) return 'نشاط متوسط';
    if (score >= 0.4) return 'نشاط محدود';
    return 'نشاط قليل';
  }

  Color _getInsightColor(String type) {
    switch (type) {
      case 'most_visited':
        return AppColors.info;
      case 'time_analysis':
        return AppColors.success;
      case 'exploration':
        return AppColors.warning;
      case 'routine':
        return AppColors.primary;
      case 'no_data':
        return AppColors.textSecondary;
      default:
        return AppColors.primary;
    }
  }

  IconData _getInsightIcon(String icon) {
    switch (icon) {
      case 'location_on':
        return Icons.location_on;
      case 'schedule':
        return Icons.schedule;
      case 'explore':
        return Icons.explore;
      case 'home_work':
        return Icons.home_work;
      case 'info':
        return Icons.info;
      default:
        return Icons.lightbulb;
    }
  }

  List<String> _generateLocationTips() {
    final tips = <String>[];
    final mobilityScore = _calculateMobilityScore();
    final totalVisits = analytics['total_visits'] as int? ?? 0;
    final uniquePlaces = analytics['unique_places'] as int? ?? 0;
    final homeVisits = analytics['home_visits'] as int? ?? 0;

    if (mobilityScore < 0.5) {
      tips.add('حاول استكشاف أماكن جديدة في منطقتك');
      tips.add('امش لمسافات قصيرة بدلاً من الركوب أحياناً');
    }

    if (uniquePlaces < 5) {
      tips.add('زر متاجر أو مقاهي جديدة لكسر الروتين');
    }

    if (totalVisits > 0 && homeVisits / totalVisits > 0.8) {
      tips.add('خصص وقتاً للخروج من المنزل والاستمتاع بالطبيعة');
    }

    final hasExplorationInsight = insights.any((insight) => insight['type'] == 'exploration');
    if (hasExplorationInsight) {
      tips.add('واصل استكشاف الأماكن الجديدة لتحسين صحتك النفسية');
    }

    if (tips.isEmpty) {
      tips.add('حافظ على توازن جيد بين الروتين والاستكشاف');
      tips.add('التنقل والحركة مفيدان لصحتك الجسدية والنفسية');
    }

    return tips.take(3).toList();
  }
}