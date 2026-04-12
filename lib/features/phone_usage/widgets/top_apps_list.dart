// lib/features/phone_usage/widgets/enhanced_top_apps_list.dart - النسخة مع ScreenUtil

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/database/models/app_usage_entry.dart';
import '../../../shared/theme/app_colors.dart';

class EnhancedTopAppsList extends StatefulWidget {
  final List<AppUsageEntry> apps;
  final Duration totalUsage;
  final Map<String, List<AppUsageEntry>> categorizedApps;

  const EnhancedTopAppsList({
    Key? key,
    required this.apps,
    required this.totalUsage,
    required this.categorizedApps,
  }) : super(key: key);

  @override
  State<EnhancedTopAppsList> createState() => _EnhancedTopAppsListState();
}

class _EnhancedTopAppsListState extends State<EnhancedTopAppsList> {
  String _selectedCategory = 'الكل';
  String _sortBy = 'usage'; // usage, opens, name
  bool _isAscending = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: AppColors.border,
          width: 1.w,
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildFiltersAndSort(),
          _buildAppsList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final filteredApps = _getFilteredApps();
    final totalUsageFiltered = filteredApps.fold<Duration>(
      const Duration(),
          (sum, app) => sum + app.totalUsageTime,
    );

    return Container(
      padding: EdgeInsets.all(20.w),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              Icons.apps,
              color: AppColors.primary,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'التطبيقات الأكثر استخداماً',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    SizedBox(width: 12.w),
                    Text(
                      '${filteredApps.length} تطبيقات',
                      style: TextStyle(
                        fontSize: 12.sp,
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
                _formatDuration(totalUsageFiltered),
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                _selectedCategory == 'الكل' ? 'إجمالي' : _selectedCategory,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersAndSort() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        border: Border(
          top: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildCategoryFilter(),
          ),
          SizedBox(width: 16.w),
          Expanded(
            flex: 2,
            child: _buildSortOptions(),
          ),
          SizedBox(width: 12.w),
          _buildSortDirectionButton(),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['الكل', ...widget.categorizedApps.keys];

    return Container(
      height: 36.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.textSecondary,
            size: 20.sp,
          ),
          style: TextStyle(fontSize: 12.sp, color: AppColors.textPrimary),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedCategory = newValue;
              });
            }
          },
          items: categories.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Row(
                  children: [
                    Icon(
                      _getCategoryIcon(value),
                      size: 16.sp,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 8.w),
                    Text(value),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSortOptions() {
    final sortOptions = {
      'usage': 'وقت الاستخدام',
      'opens': 'عدد الفتحات',
      'name': 'اسم التطبيق',
    };

    return Container(
      height: 36.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sortBy,
          isExpanded: true,
          icon: Icon(Icons.sort, color: AppColors.textSecondary, size: 20.sp),
          style: TextStyle(fontSize: 12.sp, color: AppColors.textPrimary),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _sortBy = newValue;
              });
            }
          },
          items: sortOptions.entries.map<DropdownMenuItem<String>>((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Text(entry.value),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSortDirectionButton() {
    return Container(
      height: 36.h,
      width: 36.w,
      decoration: BoxDecoration(
        color: _isAscending ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: _isAscending ? AppColors.primary : AppColors.border,
        ),
      ),
      child: IconButton(
        onPressed: () {
          setState(() {
            _isAscending = !_isAscending;
          });
        },
        icon: Icon(
          _isAscending ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          color: _isAscending ? Colors.white : AppColors.textSecondary,
          size: 20.sp,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildAppsList() {
    final filteredApps = _getFilteredApps();
    final sortedApps = _getSortedApps(filteredApps);

    if (sortedApps.isEmpty) {
      return _buildEmptyState();
    }

    // ✅ عرض أعلى 5 تطبيقات فقط
    final topApps = sortedApps.take(5).toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(20.w),
      itemCount: topApps.length,
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        return _buildAppItem(topApps[index], index);
      },
    );
  }

  Widget _buildAppItem(AppUsageEntry app, int index) {
    final usagePercentage = widget.totalUsage.inSeconds > 0
        ? (app.totalUsageTime.inSeconds / widget.totalUsage.inSeconds)
        : 0.0;

    final category = _getAppCategory(app);
    final categoryColor = _getCategoryColor(category);
    final isTopApp = index < 3;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isTopApp ? categoryColor : AppColors.border,
          width: isTopApp ? 2.w : 1.w,
        ),
      ),
      child: Row(
        children: [
          // App rank and icon
          _buildAppRankAndIcon(index, category, categoryColor, isTopApp),

          SizedBox(width: 16.w),

          // App details
          Expanded(
            child: _buildAppDetails(app, category, categoryColor),
          ),

          SizedBox(width: 16.w),

          // Usage statistics
          _buildUsageStats(app, usagePercentage, categoryColor),
        ],
      ),
    );
  }

  Widget _buildAppRankAndIcon(int index, String category, Color categoryColor, bool isTopApp) {
    return Stack(
      children: [
        Container(
          width: 50.w,
          height: 50.h,
          decoration: BoxDecoration(
            color: categoryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: categoryColor,
              width: isTopApp ? 2.w : 1.w,
            ),
          ),
          child: Icon(
            _getCategoryIcon(category),
            color: categoryColor,
            size: 24.sp,
          ),
        ),

        // Rank badge
        Positioned(
          top: -4.h,
          right: -4.w,
          child: Container(
            width: 20.w,
            height: 20.h,
            decoration: BoxDecoration(
              color: isTopApp ? _getRankColor(index) : AppColors.textMuted,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: Colors.white, width: 2.w),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

        // Top app crown
        if (index == 0)
          Positioned(
            top: -8.h,
            left: -8.w,
            child: Icon(
              Icons.emoji_events,
              color: AppColors.secondary,
              size: 20.sp,
            ),
          ),
      ],
    );
  }

  Widget _buildAppDetails(AppUsageEntry app, String category, Color categoryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                app.appName,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (app.lastUsedTime != null)
              Text(
                _getLastUsedText(app.lastUsedTime!),
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
        SizedBox(height: 4.h),
        Row(
          children: [
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 9.sp,
                  color: categoryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: 4.w),
            Text(
              '${app.openCount} فتحة',
              style: TextStyle(
                fontSize: 10.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUsageStats(AppUsageEntry app, double usagePercentage, Color categoryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _formatDuration(app.totalUsageTime),
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: categoryColor,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          '${(usagePercentage * 100).round()}%',
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: 60.w,
          height: 4.h,
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(2.r),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerRight,
            widthFactor: usagePercentage.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: categoryColor,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(40.w),
      child: Column(
        children: [
          Icon(
            Icons.apps_outage,
            size: 48.sp,
            color: AppColors.textMuted,
          ),
          SizedBox(height: 16.h),
          Text(
            'لا توجد تطبيقات في هذه الفئة',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'جرب تغيير الفئة أو خيارات الترتيب',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<AppUsageEntry> _getFilteredApps() {
    if (_selectedCategory == 'الكل') {
      return widget.apps;
    }
    return widget.categorizedApps[_selectedCategory] ?? [];
  }

  List<AppUsageEntry> _getSortedApps(List<AppUsageEntry> apps) {
    final sortedApps = List<AppUsageEntry>.from(apps);

    sortedApps.sort((a, b) {
      int comparison = 0;

      switch (_sortBy) {
        case 'usage':
          comparison = a.totalUsageTime.compareTo(b.totalUsageTime);
          break;
        case 'opens':
          comparison = a.openCount.compareTo(b.openCount);
          break;
        case 'name':
          comparison = a.appName.compareTo(b.appName);
          break;
      }

      return _isAscending ? comparison : -comparison;
    });

    return sortedApps;
  }

  String _getAppCategory(AppUsageEntry app) {
    for (final category in widget.categorizedApps.keys) {
      if (widget.categorizedApps[category]!.contains(app)) {
        return category;
      }
    }
    return 'عام';
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
      default:
        return AppColors.textMuted;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'الكل':
        return Icons.apps;
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
      default:
        return Icons.category;
    }
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return AppColors.secondary; // ذهبي
      case 1:
        return AppColors.textMuted; // فضي
      case 2:
        return AppColors.warning; // برونزي
      default:
        return AppColors.textMuted;
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

  String _getLastUsedText(DateTime lastUsed) {
    final now = DateTime.now();
    final difference = now.difference(lastUsed);

    if (difference.inMinutes < 1) return 'الآن';
    if (difference.inMinutes < 60) return '${difference.inMinutes}د';
    if (difference.inHours < 24) return '${difference.inHours}س';
    return '${difference.inDays}ي';
  }
}