// lib/features/sleep/widgets/history/history_filters.dart - النسخة البسيطة

import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';

class HistoryFilters extends StatelessWidget {
  final String selectedQualityFilter;
  final String selectedDurationFilter;
  final DateTimeRange? dateRange;
  final ValueChanged<String> onQualityFilterChanged;
  final ValueChanged<String> onDurationFilterChanged;
  final ValueChanged<DateTimeRange?> onDateRangeChanged;
  final VoidCallback onClearFilters;

  const HistoryFilters({
    Key? key,
    required this.selectedQualityFilter,
    required this.selectedDurationFilter,
    this.dateRange,
    required this.onQualityFilterChanged,
    required this.onDurationFilterChanged,
    required this.onDateRangeChanged,
    required this.onClearFilters,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = selectedQualityFilter != 'الكل' ||
        selectedDurationFilter != 'الكل' ||
        dateRange != null;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 2,
          ),
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
                  Icon(
                    Icons.filter_list,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'الفلاتر',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (hasActiveFilters)
                TextButton.icon(
                  onPressed: onClearFilters,
                  icon: Icon(Icons.clear, size: 16),
                  label: Text('مسح'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    padding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
            ],
          ),

          SizedBox(height: 12),

          // الفلاتر
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // فلتر التاريخ
              _buildDateRangeChip(context),

              // فلتر الجودة
              _buildFilterChip(
                context,
                icon: Icons.star,
                label: selectedQualityFilter == 'الكل'
                    ? 'الجودة'
                    : selectedQualityFilter,
                isActive: selectedQualityFilter != 'الكل',
                onTap: () => _showQualityFilter(context),
              ),

              // فلتر المدة
              _buildFilterChip(
                context,
                icon: Icons.access_time,
                label: selectedDurationFilter == 'الكل'
                    ? 'المدة'
                    : _getDurationLabel(selectedDurationFilter),
                isActive: selectedDurationFilter != 'الكل',
                onTap: () => _showDurationFilter(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeChip(BuildContext context) {
    return InkWell(
      onTap: () => _showDateRangePicker(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: dateRange != null
              ? AppColors.backgroundLight
              : AppColors.primarySurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: dateRange != null ? AppColors.primary : AppColors.border,
            width: dateRange != null ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: dateRange != null
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            SizedBox(width: 6),
            Text(
              dateRange != null ? _formatDateRange(dateRange!) : 'التاريخ',
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                dateRange != null ? FontWeight.bold : FontWeight.normal,
                color: dateRange != null
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
            if (dateRange != null) ...[
              SizedBox(width: 6),
              GestureDetector(
                onTap: () => onDateRangeChanged(null),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
      BuildContext context, {
        required IconData icon,
        required String label,
        required bool isActive,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.backgroundLight
              : AppColors.primarySurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showDateRangePicker(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateRangeChanged(picked);
    }
  }

  void _showQualityFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterBottomSheet(
        title: 'تصفية حسب الجودة',
        icon: Icons.star,
        options: ['الكل', 'ممتاز', 'جيد', 'متوسط', 'ضعيف'],
        selectedOption: selectedQualityFilter,
        onOptionSelected: (value) {
          onQualityFilterChanged(value);
          Navigator.pop(context);
        },
        colors: {
          'ممتاز': AppColors.success,
          'جيد': AppColors.primary,
          'متوسط': AppColors.warning,
          'ضعيف': AppColors.error,
        },
      ),
    );
  }

  void _showDurationFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterBottomSheet(
        title: 'تصفية حسب المدة',
        icon: Icons.access_time,
        options: [
          'الكل',
          'أكثر من 8 ساعات',
          '6-8 ساعات',
          '4-6 ساعات',
          'أقل من 4 ساعات',
        ],
        selectedOption: selectedDurationFilter,
        onOptionSelected: (value) {
          onDurationFilterChanged(value);
          Navigator.pop(context);
        },
      ),
    );
  }

  String _formatDateRange(DateTimeRange range) {
    final start = '${range.start.day}/${range.start.month}';
    final end = '${range.end.day}/${range.end.month}';
    return '$start - $end';
  }

  String _getDurationLabel(String filter) {
    if (filter.length > 15) {
      return filter.substring(0, 12) + '...';
    }
    return filter;
  }
}

// Bottom Sheet للفلاتر
class _FilterBottomSheet extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> options;
  final String selectedOption;
  final ValueChanged<String> onOptionSelected;
  final Map<String, Color>? colors;

  const _FilterBottomSheet({
    Key? key,
    required this.title,
    required this.icon,
    required this.options,
    required this.selectedOption,
    required this.onOptionSelected,
    this.colors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // المقبض
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            SizedBox(height: 20),

            // العنوان
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary, width: 1),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 20),
                  ),
                  SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // الخيارات
            ...options.map((option) {
              final isSelected = option == selectedOption;
              final color = colors?[option] ?? AppColors.primary;

              return InkWell(
                onTap: () => onOptionSelected(option),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.backgroundLight
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? color : AppColors.border,
                            width: 2,
                          ),
                          color: isSelected ? color : Colors.transparent,
                        ),
                        child: isSelected
                            ? Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                            : null,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? color : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (colors != null && colors![option] != null)
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: colors![option]!, width: 1),
                          ),
                          child: Icon(
                            Icons.circle,
                            size: 12,
                            color: colors![option],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}