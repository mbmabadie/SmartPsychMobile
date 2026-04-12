// lib/features/activity/widgets/activity_chart_widget.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math' as math;
import 'dart:async';

import '../../../../core/providers/activity_tracking_provider.dart';
import '../../../../core/database/repositories/activity_repository.dart';
import '../../../../shared/theme/app_colors.dart';

extension DateTimeExtension on DateTime {
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}

class ActivityChartWidget extends StatefulWidget {
  final ActivityTrackingProvider provider;

  const ActivityChartWidget({
    Key? key,
    required this.provider,
  }) : super(key: key);

  @override
  State<ActivityChartWidget> createState() => _ActivityChartWidgetState();
}

class _ActivityChartWidgetState extends State<ActivityChartWidget> {
  late ActivityRepository _activityRepo;

  List<Map<String, dynamic>> _chartData = [];
  bool _isLoading = false;
  String _selectedMetric = 'steps';
  String _selectedFilter = 'today';
  DateTime? _customDate;
  int? _selectedDataPoint;
  Timer? _autoHideTimer;

  @override
  void initState() {
    super.initState();
    _activityRepo = ActivityRepository();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChartData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 380.h,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          SizedBox(height: 12.h),
          Expanded(
            child: _isLoading ? _buildLoadingChart() : _buildChart(),
          ),
          if (!_isLoading) ...[
            SizedBox(height: 6.h),
            _buildLegend(),
            AnimatedContainer(
              duration: Duration(milliseconds: 200),
              height: _selectedDataPoint != null ? 70.h : 0,
              margin: EdgeInsets.only(top: _selectedDataPoint != null ? 6.h : 0),
              child: _selectedDataPoint != null
                  ? _buildTooltip(_selectedDataPoint!)
                  : SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.bar_chart_rounded,
                color: Colors.white,
                size: 18.sp,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getChartTitle(),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _getPeriodLabel(),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            _buildCustomDateButton(),
          ],
        ),
        SizedBox(height: 12.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterButton('اليوم', 'today', AppColors.primary),
              SizedBox(width: 6.w),
              _buildFilterButton('أمس', 'yesterday', AppColors.secondary),
              SizedBox(width: 6.w),
              _buildFilterButton('الأسبوع', 'week', AppColors.info),
              SizedBox(width: 6.w),
              _buildFilterButton('الشهر', 'month', AppColors.success),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomDateButton() {
    final isCustom = _selectedFilter == 'custom';

    return GestureDetector(
      onTap: _selectCustomDate,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: isCustom ? AppColors.warning : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isCustom ? AppColors.warning : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 14.sp,
              color: isCustom ? Colors.white : AppColors.warning,
            ),
            SizedBox(width: 4.w),
            Text(
              isCustom ? _formatCustomDate() : 'تاريخ',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: isCustom ? Colors.white : AppColors.warning,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, String filter, Color color) {
    final isSelected = _selectedFilter == filter;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
          if (filter != 'custom') {
            _customDate = null;
          }
          _selectedDataPoint = null;
        });
        _loadChartData();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (_chartData.isEmpty) {
      return _buildNoDataWidget();
    }

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
                  _selectedDataPoint = spot.touchedBarGroupIndex;
                  _startAutoHideTimer();
                });
              }
            }
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) => null,
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
              reservedSize: 30.h,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: _buildLeftTitles,
              reservedSize: 35.w,
              interval: _getMaxY() / 4,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: _buildBarGroups(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _getMaxY() / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.border,
              strokeWidth: 1,
              dashArray: [3, 3],
            );
          },
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return _chartData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;

      final value = _getValueForMetric(data);
      final color = _getBarColor(data, value);
      final isSelected = _selectedDataPoint == index;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: isSelected ? color : color,
            width: _getBarWidth(),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(4.r),
              topRight: Radius.circular(4.r),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _getMaxY(),
              color: AppColors.surfaceLight,
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildBottomTitles(double value, TitleMeta meta) {
    final intValue = value.toInt();

    if (intValue < 0 || intValue >= _chartData.length) {
      return const SizedBox.shrink();
    }

    final data = _chartData[intValue];
    String label = '';

    if (_selectedFilter == 'today' || _selectedFilter == 'yesterday') {
      final hour = data['hour'] ?? 0;
      if (hour % 6 == 0) {
        label = '${hour}ص';
        if (hour == 12) label = '12م';
        else if (hour > 12) label = '${hour - 12}م';
      }
    } else if (_selectedFilter == 'week') {
      final dayName = data['day_name'] as String? ?? '';
      label = dayName.length > 3 ? dayName.substring(0, 3) : dayName;
    } else if (_selectedFilter == 'month') {
      final day = data['day'] ?? 0;
      if (day % 5 == 1 || day == 1) {
        label = day.toString();
      }
    }

    if (label.isEmpty) return const SizedBox.shrink();

    final isCurrent = data['is_current'] == true || data['is_today'] == true;

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: isCurrent ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isCurrent ? Colors.white : AppColors.textSecondary,
            fontSize: 9.sp,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLeftTitles(double value, TitleMeta meta) {
    String text = '';

    switch (_selectedMetric) {
      case 'steps':
        if (value >= 1000) {
          text = '${(value / 1000).toStringAsFixed(0)}k';
        } else {
          text = value.toInt().toString();
        }
        break;
      case 'distance':
        text = '${value.toStringAsFixed(1)}';
        break;
      case 'calories':
        text = '${value.toInt()}';
        break;
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 8.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getBarColor(Map<String, dynamic> data, double value) {
    final isCurrent = data['is_current'] == true || data['is_today'] == true;
    final isFuture = data['is_future'] == true;

    if (isFuture) {
      return AppColors.border;
    }

    if (isCurrent) {
      return AppColors.primary;
    }

    final maxValue = _getMaxY();
    final intensity = maxValue > 0 ? (value / maxValue) : 0.0;

    if (intensity > 0.7) {
      return AppColors.success;
    } else if (intensity > 0.4) {
      return AppColors.warning;
    } else if (value > 0) {
      return AppColors.info;
    } else {
      return AppColors.border;
    }
  }

  Widget _buildTooltip(int index) {
    if (index >= _chartData.length) return const SizedBox.shrink();

    final data = _chartData[index];
    final steps = (data['steps'] as num?)?.toInt() ?? 0;
    final calories = (data['calories'] as num?)?.toDouble() ?? 0.0;
    final distance = (data['distance'] as num?)?.toDouble() ?? 0.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getTooltipTitle(data),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _buildTooltipItem(
                  icon: Icons.directions_walk,
                  value: '$steps',
                  label: 'خطوة',
                ),
              ),
              Container(width: 1.w, height: 25.h, color: Colors.white30),
              Expanded(
                child: _buildTooltipItem(
                  icon: Icons.local_fire_department,
                  value: calories > 0 ? '${calories.toInt()}' : '0',
                  label: 'سعرة',
                ),
              ),
              Container(width: 1.w, height: 25.h, color: Colors.white30),
              Expanded(
                child: _buildTooltipItem(
                  icon: Icons.straighten,
                  value: distance > 0 ? '${distance.toStringAsFixed(1)}' : '0.0',
                  label: 'كم',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTooltipItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12.sp, color: Colors.white),
        SizedBox(height: 1.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 9.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          maxLines: 1,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 7.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
          maxLines: 1,
        ),
      ],
    );
  }

  String _getTooltipTitle(Map<String, dynamic> data) {
    if (_selectedFilter == 'today' || _selectedFilter == 'yesterday') {
      final hour = data['hour'] ?? 0;
      final endHour = hour + 1;
      return '${hour.toString().padLeft(2, '0')}:00 - ${endHour.toString().padLeft(2, '0')}:00';
    } else if (_selectedFilter == 'week') {
      return data['day_name'] ?? '';
    } else if (_selectedFilter == 'month') {
      return 'اليوم ${data['day']}';
    }
    return '';
  }

  Widget _buildLegend() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem(AppColors.success, 'عالي'),
          _buildLegendItem(AppColors.warning, 'متوسط'),
          _buildLegendItem(AppColors.primary, 'الحالي'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 4.w,
          height: 4.w,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 3.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 8.sp,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingChart() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20.w,
              height: 20.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'جاري تحميل البيانات...',
              style: TextStyle(
                fontSize: 10.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bar_chart_outlined,
              size: 28.sp,
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'لا توجد بيانات',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'لم يتم تسجيل أي نشاط في ${_getPeriodLabel()}',
            style: TextStyle(
              fontSize: 10.sp,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _selectCustomDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _customDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      setState(() {
        _selectedFilter = 'custom';
        _customDate = selectedDate;
        _selectedDataPoint = null;
      });
      _loadChartData();
    }
  }

  String _formatCustomDate() {
    if (_customDate == null) return 'تاريخ';
    return '${_customDate!.day}/${_customDate!.month}';
  }

  String _getChartTitle() {
    switch (_selectedMetric) {
      case 'steps':
        return 'إحصائيات الخطوات';
      case 'distance':
        return 'إحصائيات المسافة';
      case 'calories':
        return 'إحصائيات السعرات';
      default:
        return 'إحصائيات النشاط';
    }
  }

  String _getPeriodLabel() {
    switch (_selectedFilter) {
      case 'today':
        return 'اليوم';
      case 'yesterday':
        return 'أمس';
      case 'week':
        return 'هذا الأسبوع';
      case 'month':
        return 'هذا الشهر';
      case 'custom':
        return 'تاريخ مخصص';
      default:
        return 'الفترة الحالية';
    }
  }

  double _getValueForMetric(Map<String, dynamic> data) {
    switch (_selectedMetric) {
      case 'steps':
        return (data['steps'] as num?)?.toDouble() ?? 0.0;
      case 'distance':
        return (data['distance'] as num?)?.toDouble() ?? 0.0;
      case 'calories':
        return (data['calories'] as num?)?.toDouble() ?? 0.0;
      default:
        return 0.0;
    }
  }

  double _getMaxY() {
    if (_chartData.isEmpty) return 100.0;

    final maxValue = _chartData
        .map((data) => _getValueForMetric(data))
        .reduce(math.max);

    if (maxValue == 0) {
      switch (_selectedMetric) {
        case 'steps':
          return 1000.0;
        case 'distance':
          return 1.0;
        case 'calories':
          return 50.0;
        default:
          return 100.0;
      }
    }

    final maxWithMargin = maxValue * 1.15;

    switch (_selectedMetric) {
      case 'steps':
        if (maxWithMargin <= 500) return 500;
        if (maxWithMargin <= 1000) return 1000;
        if (maxWithMargin <= 2000) return 2000;
        return ((maxWithMargin / 1000).ceil() * 1000).toDouble();

      case 'distance':
        if (maxWithMargin <= 1) return 1;
        if (maxWithMargin <= 2) return 2;
        if (maxWithMargin <= 5) return 5;
        return maxWithMargin.ceilToDouble();

      case 'calories':
        if (maxWithMargin <= 50) return 50;
        if (maxWithMargin <= 100) return 100;
        if (maxWithMargin <= 200) return 200;
        return ((maxWithMargin / 50).ceil() * 50).toDouble();

      default:
        return maxWithMargin;
    }
  }

  double _getBarWidth() {
    if (_selectedFilter == 'month') {
      return 6.0;
    } else if (_selectedFilter == 'week') {
      return 12.0;
    } else {
      return 8.0;
    }
  }

  void _startAutoHideTimer() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _selectedDataPoint != null) {
        setState(() {
          _selectedDataPoint = null;
        });
      }
    });
  }

  Future<void> _loadChartData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> data = [];

      switch (_selectedFilter) {
        case 'today':
          data = await _generateTodayData();
          break;
        case 'yesterday':
          data = await _generateYesterdayData();
          break;
        case 'week':
          data = await _generateWeekData();
          break;
        case 'month':
          data = await _generateMonthData();
          break;
        case 'custom':
          data = _generateCustomData();
          break;
        default:
          data = await _generateTodayData();
      }

      setState(() {
        _chartData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _chartData = [];
      });
    }
  }

  Future<List<Map<String, dynamic>>> _generateTodayData() async {
    final stats = widget.provider.getQuickStats();
    int totalSteps = stats['today_steps'] as int? ?? 0;
    double totalDistance = stats['today_distance'] as double? ?? 0.0;
    double totalCalories = stats['today_calories'] as double? ?? 0.0;

    final currentHour = DateTime.now().hour;
    return _distributeDataToHours(totalSteps, totalDistance, totalCalories, currentHour + 1);
  }

  Future<List<Map<String, dynamic>>> _generateYesterdayData() async {
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    final yesterdayStr = _formatDate(yesterday);

    try {
      final activity = await _activityRepo.getDailyActivityForDate(yesterdayStr);

      int steps = 0;
      double distance = 0.0;
      double calories = 0.0;

      if (activity != null) {
        steps = activity.totalSteps;
        distance = activity.distance;
        calories = activity.caloriesBurned;
      }

      return _distributeDataToHours(steps, distance, calories, 24);
    } catch (e) {
      return _distributeDataToHours(0, 0.0, 0.0, 24);
    }
  }

  Future<List<Map<String, dynamic>>> _generateWeekData() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weeklyData = <Map<String, dynamic>>[];

    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final isToday = date.isSameDay(now);
      final isFuture = date.isAfter(now);

      int steps = 0;
      double distance = 0.0;
      double calories = 0.0;

      if (isToday) {
        final stats = widget.provider.getQuickStats();
        steps = stats['today_steps'] as int? ?? 0;
        distance = stats['today_distance'] as double? ?? 0.0;
        calories = stats['today_calories'] as double? ?? 0.0;
      } else if (!isFuture) {
        final dateStr = _formatDate(date);
        final activity = await _activityRepo.getDailyActivityForDate(dateStr);

        if (activity != null) {
          steps = activity.totalSteps;
          distance = activity.distance;
          calories = activity.caloriesBurned;
        }
      }

      weeklyData.add({
        'date': date,
        'day': i + 1,
        'steps': steps,
        'distance': distance,
        'calories': calories,
        'is_today': isToday,
        'is_future': isFuture,
        'day_name': _getDayName(date.weekday),
      });
    }

    return weeklyData;
  }

  Future<List<Map<String, dynamic>>> _generateMonthData() async {
    final now = DateTime.now();
    final data = <Map<String, dynamic>>[];

    for (int day = 1; day <= now.day; day++) {
      final date = DateTime(now.year, now.month, day);
      final isToday = day == now.day;

      int steps = 0;
      double distance = 0.0;
      double calories = 0.0;

      if (isToday) {
        final stats = widget.provider.getQuickStats();
        steps = stats['today_steps'] as int? ?? 0;
        distance = stats['today_distance'] as double? ?? 0.0;
        calories = stats['today_calories'] as double? ?? 0.0;
      } else {
        final dateStr = _formatDate(date);
        final activity = await _activityRepo.getDailyActivityForDate(dateStr);

        if (activity != null) {
          steps = activity.totalSteps;
          distance = activity.distance;
          calories = activity.caloriesBurned;
        }
      }

      data.add({
        'day': day,
        'date': date,
        'steps': steps,
        'distance': distance,
        'calories': calories,
        'is_today': isToday,
        'day_name': _getDayName(date.weekday),
      });
    }

    return data;
  }

  List<Map<String, dynamic>> _generateCustomData() {
    if (_customDate == null) return [];

    final isToday = _customDate!.isSameDay(DateTime.now());

    int steps = 0;
    double distance = 0.0;
    double calories = 0.0;

    if (isToday) {
      final stats = widget.provider.getQuickStats();
      steps = stats['today_steps'] as int? ?? 0;
      distance = stats['today_distance'] as double? ?? 0.0;
      calories = stats['today_calories'] as double? ?? 0.0;
    }

    final maxHour = isToday ? DateTime.now().hour + 1 : 24;
    return _distributeDataToHours(steps, distance, calories, maxHour);
  }

  List<Map<String, dynamic>> _distributeDataToHours(
      int totalSteps, double totalDistance, double totalCalories, int maxHour) {
    final data = <Map<String, dynamic>>[];

    double totalFactors = 0.0;
    for (int h = 0; h < maxHour; h++) {
      totalFactors += _getHourActivityFactor(h);
    }

    for (int hour = 0; hour < 24; hour++) {
      final isFuture = hour >= maxHour;
      final isCurrent = hour == maxHour - 1 && maxHour < 24;

      int hourSteps = 0;
      double hourDistance = 0.0;
      double hourCalories = 0.0;

      if (!isFuture && totalSteps > 0 && totalFactors > 0) {
        final activityFactor = _getHourActivityFactor(hour);
        hourSteps = ((totalSteps * activityFactor) / totalFactors).round();
        hourDistance = (totalDistance * activityFactor) / totalFactors;
        hourCalories = (totalCalories * activityFactor) / totalFactors;
      }

      data.add({
        'hour': hour,
        'steps': hourSteps,
        'distance': hourDistance,
        'calories': hourCalories,
        'is_current': isCurrent,
        'is_future': isFuture,
      });
    }

    return data;
  }

  double _getHourActivityFactor(int hour) {
    const hourlyFactors = {
      0: 0.1, 1: 0.1, 2: 0.1, 3: 0.1, 4: 0.1, 5: 0.2,
      6: 0.8, 7: 1.2, 8: 1.0, 9: 0.7, 10: 0.8, 11: 0.9,
      12: 1.1, 13: 0.8, 14: 0.6, 15: 0.7, 16: 0.9, 17: 1.3,
      18: 1.4, 19: 1.2, 20: 1.0, 21: 0.8, 22: 0.6, 23: 0.3,
    };
    return hourlyFactors[hour] ?? 0.5;
  }

  String _getDayName(int weekday) {
    const days = ['', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    return days[weekday];
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    super.dispose();
  }
}