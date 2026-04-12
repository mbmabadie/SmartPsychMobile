// lib/features/sleep/widgets/confidence_statistics_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/providers/sleep_tracking_provider.dart';
import '../../../core/database/models/sleep_confidence.dart';

class ConfidenceStatisticsWidget extends StatefulWidget {
  const ConfidenceStatisticsWidget({super.key});

  @override
  State<ConfidenceStatisticsWidget> createState() =>
      _ConfidenceStatisticsWidgetState();
}

class _ConfidenceStatisticsWidgetState
    extends State<ConfidenceStatisticsWidget> {
  int _selectedDays = 30;

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
            // Header with Days Filter
            Row(
              children: [
                Icon(
                  Icons.pie_chart,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'إحصائيات التصنيف',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildDaysFilter(),
              ],
            ),

            const SizedBox(height: 20),

            // Chart and Stats
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadConfidenceStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final stats = snapshot.data!;
                return Column(
                  children: [
                    // Pie Chart
                    SizedBox(
                      height: 200,
                      child: _buildPieChart(stats),
                    ),

                    const SizedBox(height: 20),

                    // Legend & Details
                    _buildStatsList(stats),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaysFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedDays,
          isDense: true,
          items: const [
            DropdownMenuItem(value: 7, child: Text('7 أيام')),
            DropdownMenuItem(value: 30, child: Text('30 يوم')),
            DropdownMenuItem(value: 90, child: Text('90 يوم')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedDays = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildPieChart(List<Map<String, dynamic>> stats) {
    final total = stats.fold<int>(0, (sum, stat) => sum + (stat['count'] as int));

    if (total == 0) return _buildEmptyState();

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 50,
        sections: stats.map((stat) {
          final confidence = SleepConfidence.fromString(stat['confidence']);
          final count = stat['count'] as int;
          final percentage = (count / total * 100);

          return PieChartSectionData(
            color: _getConfidenceColor(confidence),
            value: count.toDouble(),
            title: '${percentage.toStringAsFixed(0)}%',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsList(List<Map<String, dynamic>> stats) {
    return Column(
      children: stats.map((stat) {
        final confidence = SleepConfidence.fromString(stat['confidence']);
        final count = stat['count'] as int;
        final avgHours = (stat['avg_hours'] as double?) ?? 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildStatRow(
            confidence: confidence,
            count: count,
            avgHours: avgHours,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatRow({
    required SleepConfidence confidence,
    required int count,
    required double avgHours,
  }) {
    final color = _getConfidenceColor(confidence);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Color Indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),

          // Emoji & Name
          Text(
            confidence.emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              confidence.displayName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$count ${count == 1 ? "جلسة" : "جلسات"}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (avgHours > 0)
                Text(
                  'متوسط: ${avgHours.toStringAsFixed(1)}h',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
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
            Icons.show_chart,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد بيانات كافية',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ✅✅✅ الدالة الصحيحة - استدعاء عبر Provider فقط
  Future<List<Map<String, dynamic>>> _loadConfidenceStats() async {
    try {
      final provider = context.read<SleepTrackingProvider>();
      final stats = await provider.getConfidenceStatistics(days: _selectedDays);
      return stats;
    } catch (e) {
      debugPrint('❌ خطأ في تحميل إحصائيات التصنيف: $e');
      return [];
    }
  }

  Color _getConfidenceColor(SleepConfidence confidence) {
    switch (confidence) {
      case SleepConfidence.confirmed:
        return Colors.green;
      case SleepConfidence.probable:
        return Colors.amber;
      case SleepConfidence.phoneLeft:
        return Colors.red;
      case SleepConfidence.uncertain:
        return Colors.grey;
    }
  }
}