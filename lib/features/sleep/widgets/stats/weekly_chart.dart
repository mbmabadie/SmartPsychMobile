// lib/features/sleep/widgets/stats/weekly_chart.dart - النسخة البسيطة

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/providers/sleep_tracking_provider.dart';
import '../../../../shared/theme/app_colors.dart';

class WeeklyChart extends StatelessWidget {
  final SleepTrackingProvider provider;

  const WeeklyChart({
    Key? key,
    required this.provider,
  }) : super(key: key);

  Widget build(BuildContext context) {
    final weekData = _getWeekData();
    final hasData = weekData.any((value) => value > 0);

    if (!hasData) {
      // عرض رسم بياني فارغ مع رسالة
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 2),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: AppColors.primary),
                SizedBox(width: 12),
                Text(
                  '📊 نظرة أسبوعية',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 32),
            Icon(
              Icons.timeline,
              size: 64,
              color: AppColors.textMuted,
            ),
            SizedBox(height: 16),
            Text(
              'لا توجد بيانات كافية',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'سيظهر الرسم البياني بعد 3 أيام من التتبع',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
          width: 2,
        ),
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
                      Icons.bar_chart,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    '📊 نظرة أسبوعية',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary, width: 1),
                ),
                child: Text(
                  '7 أيام',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 24),

          // الرسم البياني
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 12,
                minY: 0,
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
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            _getDayName(value.toInt()),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
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
                          '${value.toInt()}h',
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
                barGroups: weekData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final hours = entry.value;
                  final goalHours = provider.state.sleepGoalHours.toDouble();

                  // تحديد اللون حسب تحقيق الهدف
                  final barColor = hours >= goalHours
                      ? AppColors.success
                      : hours >= goalHours * 0.8
                      ? AppColors.primary
                      : AppColors.warning;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: hours,
                        color: barColor,
                        width: 20,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),

          SizedBox(height: 20),

          // ملخص الأسبوع
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'متوسط',
                  '${_calculateAverage(weekData).toStringAsFixed(1)} س',
                  AppColors.primary,
                ),
                Container(
                  width: 2,
                  height: 30,
                  color: AppColors.primary,
                ),
                _buildSummaryItem(
                  'الهدف',
                  '${provider.state.sleepGoalHours} س',
                  AppColors.success,
                ),
                Container(
                  width: 2,
                  height: 30,
                  color: AppColors.primary,
                ),
                _buildSummaryItem(
                  'التحقيق',
                  '${_calculateAchievement(weekData, provider.state.sleepGoalHours).toStringAsFixed(0)}%',
                  AppColors.primary,
                ),
              ],
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

  List<double> _getWeekData() {
    final sessions = provider.state.recentSessions;

    // لا بيانات وهمية - فقط صفر
    final weekData = List<double>.filled(7, 0.0);

    if (sessions.isEmpty) return weekData;

    // حساب البيانات الحقيقية
    for (var i = 0; i < 7; i++) {
      final date = DateTime.now().subtract(Duration(days: 6 - i));
      final daySessions = sessions.where((session) {
        return session.startTime.year == date.year &&
            session.startTime.month == date.month &&
            session.startTime.day == date.day &&
            session.duration != null;
      });

      if (daySessions.isNotEmpty) {
        final totalMinutes = daySessions.fold<int>(
          0,
              (sum, session) => sum + (session.duration!.inMinutes),
        );
        weekData[i] = totalMinutes / 60.0;
      }
    }

    return weekData;
  }

  String _getDayName(int index) {
    final days = ['سبت', 'أحد', 'اثن', 'ثلا', 'أرب', 'خمي', 'جمع'];
    return days[index % 7];
  }

  double _calculateAverage(List<double> data) {
    if (data.isEmpty) return 0.0;
    return data.reduce((a, b) => a + b) / data.length;
  }

  double _calculateAchievement(List<double> data, int goal) {
    if (data.isEmpty) return 0.0;
    final avg = _calculateAverage(data);
    return (avg / goal) * 100;
  }
}