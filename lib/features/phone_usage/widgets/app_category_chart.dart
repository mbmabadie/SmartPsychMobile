// lib/features/phone_usage/widgets/app_category_chart.dart - دائرة أكبر في المنتصف

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/database/models/app_usage_entry.dart';
import '../../../shared/theme/app_colors.dart';

class AppCategoryChart extends StatefulWidget {
  final Map<String, List<AppUsageEntry>> categorizedApps;
  final Duration totalUsage;

  const AppCategoryChart({
    Key? key,
    required this.categorizedApps,
    required this.totalUsage,
  }) : super(key: key);

  @override
  State<AppCategoryChart> createState() => _AppCategoryChartState();
}

class _AppCategoryChartState extends State<AppCategoryChart> {
  int _selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final categoryStats = _calculateCategoryStats();

    if (categoryStats.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 24),

          // ✅ الدائرة في المنتصف - أكبر
          SizedBox(
            height: 280,
            child: Center(
              child: _buildPieChart(categoryStats),
            ),
          ),

          const SizedBox(height: 24),

          // ✅ الـ legend تحت الدائرة
          _buildLegend(categoryStats),

          if (_selectedIndex >= 0) ...[
            const SizedBox(height: 12),
            _buildCategoryDetails(categoryStats),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.pie_chart,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تصنيف التطبيقات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const SizedBox(width: 12),
                  Text(
                    '${widget.categorizedApps.length} فئات',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatDuration(widget.totalUsage),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            Text(
              'إجمالي الاستخدام',
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

  Widget _buildPieChart(List<CategoryStat> categoryStats) {
    return PieChart(
      PieChartData(
        sectionsSpace: 3, // ✅ مسافة أكبر شوي بين القطع
        centerSpaceRadius: 0, // ✅ دائرة كاملة بدون فراغ في المنتصف
        startDegreeOffset: -90,
        sections: categoryStats.asMap().entries.map((entry) {
          final index = entry.key;
          final stat = entry.value;
          final isSelected = _selectedIndex == index;

          return PieChartSectionData(
            color: stat.color,
            value: stat.percentage,
            title: '${stat.percentage.round()}%',
            radius: isSelected ? 120 : 100, // ✅ أكبر بكثير (كان 70/60)
            titleStyle: TextStyle(
              fontSize: isSelected ? 16 : 14, // ✅ نص أكبر
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            badgeWidget: isSelected ? _buildBadge(stat) : null,
            badgePositionPercentageOffset: 1.4, // ✅ البادج أبعد شوي
          );
        }).toList(),
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            if (event is FlTapUpEvent && pieTouchResponse != null) {
              final touchedSection = pieTouchResponse.touchedSection;
              if (touchedSection != null) {
                setState(() {
                  _selectedIndex = touchedSection.touchedSectionIndex;
                });
              }
            }
          },
        ),
      ),
    );
  }

  Widget _buildBadge(CategoryStat stat) {
    return Container(
      padding: const EdgeInsets.all(8), // ✅ أكبر شوي
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: stat.color, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getCategoryIcon(stat.name),
            color: stat.color,
            size: 18, // ✅ أكبر
          ),
          const SizedBox(height: 2),
          Text(
            '${stat.appsCount}',
            style: TextStyle(
              fontSize: 12, // ✅ أكبر
              fontWeight: FontWeight.bold,
              color: stat.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(List<CategoryStat> categoryStats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الفئات',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // ✅ Grid بدل ListView عشان يكون أفضل
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categoryStats.asMap().entries.map((entry) {
            final index = entry.key;
            final stat = entry.value;
            final isSelected = _selectedIndex == index;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = _selectedIndex == index ? -1 : index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? stat.color : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: stat.color,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getCategoryIcon(stat.name),
                      color: isSelected ? Colors.white : stat.color,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          stat.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${stat.percentage.round()}% • ${stat.appsCount} تطبيق',
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryDetails(List<CategoryStat> categoryStats) {
    if (_selectedIndex < 0 || _selectedIndex >= categoryStats.length) {
      return const SizedBox.shrink();
    }

    final stat = categoryStats[_selectedIndex];
    final apps = widget.categorizedApps[stat.name] ?? [];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: stat.color,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                _getCategoryIcon(stat.name),
                color: stat.color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                stat.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: stat.color,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: stat.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${stat.percentage.round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.timer,
                  label: 'إجمالي الوقت',
                  value: _formatDuration(stat.totalUsage),
                  color: stat.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.apps,
                  label: 'عدد التطبيقات',
                  value: '${stat.appsCount}',
                  color: stat.color,
                ),
              ),
            ],
          ),
          if (apps.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'أكثر التطبيقات استخداماً:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: apps.take(3).map((app) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: stat.color, width: 2),
                ),
                child: Text(
                  app.appName,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 14,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد بيانات للعرض',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'سيتم عرض تصنيف التطبيقات هنا عند توفر البيانات',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<CategoryStat> _calculateCategoryStats() {
    final stats = <CategoryStat>[];

    for (final category in widget.categorizedApps.keys) {
      final apps = widget.categorizedApps[category]!;
      if (apps.isEmpty) continue;

      final totalUsage = apps.fold<Duration>(
        const Duration(),
            (sum, app) => sum + app.totalUsageTime,
      );

      if (totalUsage.inSeconds == 0) continue;

      final percentage = widget.totalUsage.inSeconds > 0
          ? (totalUsage.inSeconds / widget.totalUsage.inSeconds) * 100
          : 0.0;

      stats.add(CategoryStat(
        name: category,
        totalUsage: totalUsage,
        percentage: percentage,
        appsCount: apps.length,
        color: _getCategoryColor(category),
      ));
    }

    stats.sort((a, b) => b.percentage.compareTo(a.percentage));
    return stats;
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'التواصل الاجتماعي':
        return AppColors.primary;
      case 'الترفيه':
        return AppColors.secondary;
      case 'الإنتاجية':
        return AppColors.success;
      case 'الألعاب':
        return AppColors.warning;
      case 'التسوق':
        return AppColors.error;
      case 'الأخبار':
        return AppColors.info;
      case 'التعليم':
        return AppColors.primaryVariant;
      case 'الصحة':
        return AppColors.primaryLight;
      case 'الطعام':
        return AppColors.secondary;
      case 'السفر':
        return AppColors.info;
      default:
        return AppColors.textMuted;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'التواصل الاجتماعي':
        return Icons.people;
      case 'الترفيه':
        return Icons.movie;
      case 'الإنتاجية':
        return Icons.work;
      case 'الألعاب':
        return Icons.games;
      case 'التسوق':
        return Icons.shopping_bag;
      case 'الأخبار':
        return Icons.newspaper;
      case 'التعليم':
        return Icons.school;
      case 'الصحة':
        return Icons.health_and_safety;
      case 'الطعام':
        return Icons.restaurant;
      case 'السفر':
        return Icons.flight;
      default:
        return Icons.category;
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}س ${minutes}د';
    } else {
      return '${minutes}د';
    }
  }

  String _formatDurationShort(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}س';
    } else {
      return '${minutes}د';
    }
  }
}

class CategoryStat {
  final String name;
  final Duration totalUsage;
  final double percentage;
  final int appsCount;
  final Color color;

  CategoryStat({
    required this.name,
    required this.totalUsage,
    required this.percentage,
    required this.appsCount,
    required this.color,
  });

  @override
  String toString() {
    return 'CategoryStat(name: $name, percentage: ${percentage.round()}%, apps: $appsCount)';
  }
}