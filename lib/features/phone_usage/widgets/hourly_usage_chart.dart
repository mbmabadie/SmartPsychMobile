// lib/features/phone_usage/widgets/hourly_usage_chart.dart - النسخة البسيطة

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

import '../../../shared/theme/app_colors.dart';

class HourlyUsageChart extends StatefulWidget {
  final Duration todaysUsage;
  final List<dynamic> patterns;
  final List<Map<String, dynamic>> hourlyData;

  const HourlyUsageChart({
    Key? key,
    required this.todaysUsage,
    required this.patterns,
    required this.hourlyData,
  }) : super(key: key);

  @override
  State<HourlyUsageChart> createState() => _HourlyUsageChartState();
}

class _HourlyUsageChartState extends State<HourlyUsageChart> {
  int? _selectedHour;

  @override
  Widget build(BuildContext context) {
    final isDataLoaded = widget.hourlyData.isNotEmpty &&
        widget.hourlyData.any((h) => (h['usage_minutes'] as double? ?? 0.0) > 0);

    return Container(
      height: _selectedHour != null ? 550 : 450,
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
          const SizedBox(height: 20),
          Expanded(
            child: isDataLoaded ? _buildChart() : _buildNoDataState(),
          ),
          const SizedBox(height: 16),
          _buildLegend(),
          if (_selectedHour != null) ...[
            const SizedBox(height: 16),
            _buildHourDetails(_selectedHour!),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final totalMinutes = widget.hourlyData.fold<double>(
      0.0,
          (sum, hour) => sum + (hour['usage_minutes'] as double? ?? 0.0),
    );

    final hoursWithData = widget.hourlyData
        .where((h) => (h['usage_minutes'] as double? ?? 0.0) > 0)
        .length;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.timeline,
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
                'الاستخدام خلال اليوم',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.success,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified,
                          size: 12,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'بيانات اليوم',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$hoursWithData ساعات نشطة',
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
              _formatDuration(Duration(minutes: totalMinutes.round())),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            Text(
              'إجمالي اليوم',
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

  Widget _buildChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceEvenly,
        maxY: _getMaxY(),
        barTouchData: BarTouchData(
          enabled: true,
          touchCallback: (FlTouchEvent event, barTouchResponse) {
            if (event is FlTapUpEvent && barTouchResponse != null) {
              final spot = barTouchResponse.spot;
              if (spot != null) {
                setState(() {
                  _selectedHour = spot.touchedBarGroupIndex;
                });
              }
            }
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final hour = group.x;
              final hourData = widget.hourlyData.firstWhere(
                    (h) => h['hour'] == hour,
                orElse: () => {'usage_minutes': 0.0, 'pickups': 0},
              );

              final usage = (hourData['usage_minutes'] as double? ?? 0.0).round();
              final pickups = hourData['pickups'] as int? ?? 0;

              return BarTooltipItem(
                'الساعة ${hour.toString().padLeft(2, '0')}:00\n'
                    'الاستخدام: ${usage}د\n'
                    'فتحات: $pickups',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
            tooltipBgColor: AppColors.textPrimary,
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.all(8),
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: _buildBottomTitles,
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: _buildLeftTitles,
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: _buildBarGroups(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _getMaxY() / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.border,
              strokeWidth: 1,
            );
          },
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    final now = DateTime.now();
    final currentHour = now.hour;

    return widget.hourlyData.asMap().entries.map((entry) {
      final hourData = entry.value;
      final hour = hourData['hour'] as int? ?? 0;
      final usage = hourData['usage_minutes'] as double? ?? 0.0;
      final isCurrent = hour == currentHour;
      final isFuture = hour > currentHour;
      final hasRealData = usage > 0;

      Color barColor;
      if (isFuture) {
        barColor = AppColors.backgroundLight;
      } else if (isCurrent) {
        barColor = AppColors.primary;
      } else if (hasRealData && usage > 0) {
        final intensity = (usage / _getMaxY()).clamp(0.0, 1.0);
        if (intensity > 0.7) {
          barColor = AppColors.error;
        } else if (intensity > 0.4) {
          barColor = AppColors.warning;
        } else {
          barColor = AppColors.success;
        }
      } else {
        barColor = AppColors.backgroundLight;
      }

      return BarChartGroupData(
        x: hour,
        barRods: [
          BarChartRodData(
            toY: usage,
            color: barColor,
            width: 12,
            borderRadius: BorderRadius.circular(6),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _getMaxY(),
              color: AppColors.backgroundLight,
            ),
          ),
        ],
        showingTooltipIndicators: _selectedHour == hour ? [0] : [],
      );
    }).toList();
  }

  double _getMaxY() {
    if (widget.hourlyData.isEmpty) return 60.0;

    final maxUsage = widget.hourlyData
        .map((h) => h['usage_minutes'] as double? ?? 0.0)
        .reduce(math.max);

    if (maxUsage == 0) return 60.0;

    final maxWithMargin = maxUsage * 1.2;

    if (maxWithMargin <= 30) return 30;
    if (maxWithMargin <= 60) return 60;
    if (maxWithMargin <= 120) return 120;
    if (maxWithMargin <= 180) return 180;

    return ((maxWithMargin / 60).ceil() * 60).toDouble();
  }

  Widget _buildBottomTitles(double value, TitleMeta meta) {
    final hour = value.toInt();
    final now = DateTime.now();

    if (hour % 4 != 0) {
      return const SizedBox.shrink();
    }

    final isCurrentHour = hour == now.hour;
    final isFutureHour = hour > now.hour;

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: isCurrentHour ? AppColors.primarySurface : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: isCurrentHour ? Border.all(color: AppColors.primary, width: 1) : null,
        ),
        child: Text(
          hour.toString().padLeft(2, '0'),
          style: TextStyle(
            color: isFutureHour
                ? AppColors.textMuted
                : isCurrentHour
                ? AppColors.primary
                : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isCurrentHour ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLeftTitles(double value, TitleMeta meta) {
    if (value % 30 != 0) {
      return const SizedBox.shrink();
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        '${value.toInt()}د',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildNoDataState() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline_outlined,
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
              'لم يتم استخدام الهاتف اليوم',
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

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem(
          color: AppColors.success,
          label: 'خفيف',
          icon: Icons.circle,
        ),
        _buildLegendItem(
          color: AppColors.warning,
          label: 'متوسط',
          icon: Icons.circle,
        ),
        _buildLegendItem(
          color: AppColors.error,
          label: 'مكثف',
          icon: Icons.circle,
        ),
        _buildLegendItem(
          color: AppColors.primary,
          label: 'الحالية',
          icon: Icons.radio_button_checked,
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required IconData icon,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: 12,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildHourDetails(int hour) {
    final hourData = widget.hourlyData.firstWhere(
          (h) => (h['hour'] as int? ?? -1) == hour,
      orElse: () => {
        'hour': hour,
        'usage_minutes': 0.0,
        'pickups': 0,
      },
    );

    final usage = (hourData['usage_minutes'] as double? ?? 0.0).round();
    final pickups = hourData['pickups'] as int? ?? 0;
    final isCurrent = hour == DateTime.now().hour;
    final isFuture = hour > DateTime.now().hour;
    final hasRealData = usage > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCurrent
                    ? Icons.access_time
                    : isFuture
                    ? Icons.schedule
                    : Icons.history,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'الساعة ${hour.toString().padLeft(2, '0')}:00',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'الحالية',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedHour = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border, width: 2),
                  ),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasRealData && !isFuture) ...[
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.timer,
                    label: 'وقت الاستخدام',
                    value: '${usage}د',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.touch_app,
                    label: 'عدد الفتحات',
                    value: '$pickups',
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ] else if (isFuture) ...[
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.textMuted,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'هذه الساعة لم تحدث بعد',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Icon(
                  Icons.access_time_filled_sharp,
                  color: AppColors.textMuted,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'لم يتم استخدام الهاتف في هذه الساعة',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
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
}