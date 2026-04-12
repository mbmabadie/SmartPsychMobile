// lib/features/sleep/widgets/insights/trend_chart_card.dart - النسخة البسيطة

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/providers/sleep_tracking_provider.dart';
import '../../../../shared/theme/app_colors.dart';

class TrendChartCard extends StatelessWidget {
  final SleepTrackingProvider provider;

  const TrendChartCard({
    Key? key,
    required this.provider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final trendData = _getTrendData();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      Icons.trending_up,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    '📈 اتجاه الجودة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              _buildTrendIndicator(trendData),
            ],
          ),

          SizedBox(height: 24),

          // الرسم البياني
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.border,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            _getDateLabel(value.toInt()),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 10,
                lineBarsData: [
                  LineChartBarData(
                    spots: trendData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value);
                    }).toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: AppColors.primary,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primarySurface,
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: AppColors.primary,
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(1)}/10',
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 16),

          // الملخص
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'المتوسط',
                  _calculateAverage(trendData).toStringAsFixed(1),
                  AppColors.primary,
                ),
                Container(
                  width: 2,
                  height: 30,
                  color: AppColors.primary,
                ),
                _buildSummaryItem(
                  'الأعلى',
                  _getHighest(trendData).toStringAsFixed(1),
                  AppColors.success,
                ),
                Container(
                  width: 2,
                  height: 30,
                  color: AppColors.primary,
                ),
                _buildSummaryItem(
                  'الأدنى',
                  _getLowest(trendData).toStringAsFixed(1),
                  AppColors.warning,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(List<double> data) {
    if (data.length < 2) {
      return Container();
    }

    final recent = data.sublist(data.length - 3).reduce((a, b) => a + b) / 3;
    final older = data.sublist(0, 3).reduce((a, b) => a + b) / 3;
    final trend = recent - older;

    IconData icon;
    Color color;
    String text;

    if (trend > 0.5) {
      icon = Icons.trending_up;
      color = AppColors.success;
      text = 'يتحسن';
    } else if (trend < -0.5) {
      icon = Icons.trending_down;
      color = AppColors.error;
      text = 'يتراجع';
    } else {
      icon = Icons.trending_flat;
      color = AppColors.warning;
      text = 'مستقر';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
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

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  List<double> _getTrendData() {
    final sessions = provider.state.recentSessions;
    if (sessions.isEmpty) {
      return List.filled(7, 7.0);
    }

    return List.generate(7, (index) {
      final date = DateTime.now().subtract(Duration(days: 6 - index));
      final daySessions = sessions.where((s) {
        return s.startTime.year == date.year &&
            s.startTime.month == date.month &&
            s.startTime.day == date.day;
      });

      if (daySessions.isEmpty) return 7.0;

      final avgQuality = daySessions
          .map((s) => s.qualityScore ?? 7.0)
          .reduce((a, b) => a + b) /
          daySessions.length;

      return avgQuality;
    });
  }

  String _getDateLabel(int index) {
    final date = DateTime.now().subtract(Duration(days: 6 - index));
    return '${date.day}/${date.month}';
  }

  double _calculateAverage(List<double> data) {
    if (data.isEmpty) return 0.0;
    return data.reduce((a, b) => a + b) / data.length;
  }

  double _getHighest(List<double> data) {
    if (data.isEmpty) return 0.0;
    return data.reduce((a, b) => a > b ? a : b);
  }

  double _getLowest(List<double> data) {
    if (data.isEmpty) return 0.0;
    return data.reduce((a, b) => a < b ? a : b);
  }
}