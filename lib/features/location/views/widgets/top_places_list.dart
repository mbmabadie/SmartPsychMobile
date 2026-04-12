// lib/features/location/widgets/top_places_list.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import '../../../../core/database/models/activity_models.dart';
import '../../../../shared/theme/app_colors.dart';

class TopPlacesList extends StatefulWidget {
  final List<Map<String, dynamic>> places;
  final Map<String, LocationVisit?> savedPlaces;
  final Function(int) onSetAsHome;
  final Function(int) onSetAsWork;

  const TopPlacesList({
    Key? key,
    required this.places,
    required this.savedPlaces,
    required this.onSetAsHome,
    required this.onSetAsWork,
  }) : super(key: key);

  @override
  State<TopPlacesList> createState() => _TopPlacesListState();
}

class _TopPlacesListState extends State<TopPlacesList> {
  String _sortBy = 'frequency';
  String _filterBy = 'all';
  bool _isAscending = false;

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
          _buildHeader(),
          _buildFiltersSection(),
          _buildPlacesList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final filteredPlaces = _getFilteredPlaces();
    final totalVisits = filteredPlaces.fold<int>(
      0,
          (sum, place) => sum + (place['total_visits'] as int),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.place,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أكثر الأماكن زيارة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${filteredPlaces.length} مكان • $totalVisits زيارة',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getFilterLabel(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
            child: _buildFilterDropdown(),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: _buildSortDropdown(),
          ),
          const SizedBox(width: 12),
          _buildSortDirectionButton(),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    final filterOptions = {
      'all': 'الكل',
      'home': 'البيت',
      'work': 'العمل',
      'frequent': 'الأكثر زيارة',
      'recent': 'الأحدث',
    };

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filterBy,
          isExpanded: true,
          icon: Icon(Icons.filter_list, color: AppColors.textSecondary, size: 20),
          style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _filterBy = newValue;
              });
            }
          },
          items: filterOptions.entries.map<DropdownMenuItem<String>>((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(
                      _getFilterIcon(entry.key),
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(entry.value),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    final sortOptions = {
      'frequency': 'عدد الزيارات',
      'time': 'الوقت المقضي',
      'name': 'اسم المكان',
      'recent': 'آخر زيارة',
    };

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sortBy,
          isExpanded: true,
          icon: Icon(Icons.sort, color: AppColors.textSecondary, size: 20),
          style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
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
                padding: const EdgeInsets.symmetric(horizontal: 12),
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
      height: 36,
      width: 36,
      decoration: BoxDecoration(
        color: _isAscending ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          size: 20,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildPlacesList() {
    // ✅ ترتيب حسب الوقت مباشرة
    final places = List<Map<String, dynamic>>.from(_getFilteredPlaces());

    // ✅ فرز حسب total_time_hours (من الأكبر للأصغر)
    places.sort((a, b) {
      final timeA = a['total_time_hours'] as double;
      final timeB = b['total_time_hours'] as double;
      return timeB.compareTo(timeA);  // ✅ الأكبر أولاً
    });

    if (places.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: math.min(places.length, 3),  // ✅ أكثر 3 أماكن
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildPlaceItem(places[index], index);
      },
    );
  }
  
  Widget _buildPlaceItem(Map<String, dynamic> place, int index) {
    final isTopPlace = index < 3;
    final placeColor = _getPlaceColor(place);
    final isHome = place['is_home'] == true;
    final isWork = place['is_work'] == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTopPlace
              ? placeColor
              : AppColors.border,
          width: isTopPlace ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: placeColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildPlaceRankAndIcon(index, place, placeColor, isTopPlace),
          const SizedBox(width: 16),
          Expanded(
            child: _buildPlaceDetails(place, placeColor, isHome, isWork),
          ),
          const SizedBox(width: 16),
          _buildPlaceStats(place, placeColor),
        ],
      ),
    );
  }

  Widget _buildPlaceRankAndIcon(int index, Map<String, dynamic> place, Color placeColor, bool isTopPlace) {
    return Stack(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: placeColor,
              width: isTopPlace ? 2 : 1,
            ),
          ),
          child: Icon(
            _getPlaceIcon(place),
            color: placeColor,
            size: 24,
          ),
        ),

        Positioned(
          top: -4,
          right: -4,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isTopPlace
                  ? _getRankColor(index)
                  : AppColors.textSecondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

        if (index == 0)
          Positioned(
            top: -8,
            left: -8,
            child: Icon(
              Icons.emoji_events,
              color: AppColors.secondary,
              size: 20,
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceDetails(Map<String, dynamic> place, Color placeColor, bool isHome, bool isWork) {
    final placeName = place['place_name'] as String? ?? 'مكان غير معروف';
    final placeType = place['place_type'] as String?;
    final lastVisit = place['last_visit'] as DateTime?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                placeName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (lastVisit != null)
              Text(
                _getLastVisitText(lastVisit),
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (isHome || isWork)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isHome ? AppColors.info : AppColors.warning),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isHome ? Icons.home : Icons.work,
                      size: 10,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      isHome ? 'بيت' : 'عمل',
                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            if ((isHome || isWork) && placeType != null)
              const SizedBox(width: 8),
            if (placeType != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: placeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getPlaceTypeArabic(placeType),
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceStats(Map<String, dynamic> place, Color placeColor) {
    final totalVisits = place['total_visits'] as int;
    final totalTimeHours = place['total_time_hours'] as double;
    final visitFrequency = place['visit_frequency'] as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _sortBy == 'time'
              ? '${totalTimeHours.toStringAsFixed(1)}س'
              : '$totalVisits',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: placeColor,
          ),
        ),
        Text(
          _sortBy == 'time' ? 'ساعات' : 'زيارات',
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: 8),

        Container(
          width: 60,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerRight,
            widthFactor: (visitFrequency / 20.0).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: placeColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!(place['is_home'] == true))
              _buildActionButton(
                Icons.home_outlined,
                AppColors.info,
                    () => _showSetAsHomeDialog(place),
              ),
            if (!(place['is_home'] == true) && !(place['is_work'] == true))
              const SizedBox(width: 8),
            if (!(place['is_work'] == true))
              _buildActionButton(
                Icons.work_outline,
                AppColors.warning,
                    () => _showSetAsWorkDialog(place),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.place_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد أماكن في هذا الفلتر',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'جرب تغيير الفلتر أو خيارات الترتيب',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredPlaces() {
    switch (_filterBy) {
      case 'home':
        return widget.places.where((place) => place['is_home'] == true).toList();
      case 'work':
        return widget.places.where((place) => place['is_work'] == true).toList();
      case 'frequent':
        return widget.places.where((place) => (place['visit_frequency'] as int) > 5).toList();
      case 'recent':
        final recentDate = DateTime.now().subtract(const Duration(days: 7));
        return widget.places.where((place) {
          final lastVisit = place['last_visit'] as DateTime?;
          return lastVisit != null && lastVisit.isAfter(recentDate);
        }).toList();
      case 'all':
      default:
        return widget.places;
    }
  }

  List<Map<String, dynamic>> _getSortedPlaces() {
    final places = _getFilteredPlaces();

    places.sort((a, b) {
      int comparison = 0;

      switch (_sortBy) {
        case 'frequency':
          comparison = (a['visit_frequency'] as int).compareTo(b['visit_frequency'] as int);
          break;
        case 'time':
          comparison = (a['total_time_hours'] as double).compareTo(b['total_time_hours'] as double);
          break;
        case 'name':
          final nameA = a['place_name'] as String? ?? '';
          final nameB = b['place_name'] as String? ?? '';
          comparison = nameA.compareTo(nameB);
          break;
        case 'recent':
          final lastVisitA = a['last_visit'] as DateTime?;
          final lastVisitB = b['last_visit'] as DateTime?;
          if (lastVisitA == null && lastVisitB == null) comparison = 0;
          else if (lastVisitA == null) comparison = 1;
          else if (lastVisitB == null) comparison = -1;
          else comparison = lastVisitA.compareTo(lastVisitB);
          break;
      }

      return _isAscending ? comparison : -comparison;
    });

    return places;
  }

  void _showSetAsHomeDialog(Map<String, dynamic> place) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.home, color: AppColors.info),
            const SizedBox(width: 8),
            const Text('تحديد كبيت'),
          ],
        ),
        content: Text(
          'هل تريد تحديد "${place['place_name']}" كموقع البيت؟',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final placeId = place['id'] as int? ?? 0;
              widget.onSetAsHome(placeId);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم تحديد "${place['place_name']}" كبيت'),
                  backgroundColor: AppColors.info,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  void _showSetAsWorkDialog(Map<String, dynamic> place) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.work, color: AppColors.warning),
            const SizedBox(width: 8),
            const Text('تحديد كعمل'),
          ],
        ),
        content: Text(
          'هل تريد تحديد "${place['place_name']}" كموقع العمل؟',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final placeId = place['id'] as int? ?? 0;
              widget.onSetAsWork(placeId);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم تحديد "${place['place_name']}" كعمل'),
                  backgroundColor: AppColors.warning,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  // ✅ Helper methods مع التعديلات
  Color _getPlaceColor(Map<String, dynamic> place) {
    if (place['is_home'] == true) return AppColors.info;
    if (place['is_work'] == true) return AppColors.warning;

    final placeType = place['place_type'] as String?;
    switch (placeType) {
      case 'shopping':
        return AppColors.error;
      case 'food':
        return AppColors.error;
      case 'recreation':
        return AppColors.success;
      case 'healthcare':
        return AppColors.primary;
      case 'education':
        return AppColors.primary;
      case 'transport':
        return AppColors.info;
      case 'family':                  // ✅ إضافة
        return Color(0xFFE91E63);     // ✅ Pink
      default:
        return AppColors.primary;
    }
  }

  IconData _getPlaceIcon(Map<String, dynamic> place) {
    if (place['is_home'] == true) return Icons.home;
    if (place['is_work'] == true) return Icons.work;

    final placeType = place['place_type'] as String?;
    switch (placeType) {
      case 'shopping':
        return Icons.shopping_bag;
      case 'food':
        return Icons.restaurant;
      case 'recreation':
        return Icons.sports_esports;
      case 'healthcare':
        return Icons.local_hospital;
      case 'education':
        return Icons.school;
      case 'transport':
        return Icons.directions_bus;
      case 'worship':
        return Icons.mosque;
      case 'family':                  // ✅ إضافة
        return Icons.family_restroom; // ✅
      default:
        return Icons.place;
    }
  }

  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'all':
        return Icons.all_inclusive;
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      case 'frequent':
        return Icons.trending_up;
      case 'recent':
        return Icons.schedule;
      default:
        return Icons.filter_list;
    }
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return AppColors.secondary;
      case 1:
        return AppColors.textSecondary;
      case 2:
        return AppColors.warning;
      default:
        return AppColors.textMuted;
    }
  }

  String _getFilterLabel() {
    switch (_filterBy) {
      case 'all':
        return 'الكل';
      case 'home':
        return 'البيت';
      case 'work':
        return 'العمل';
      case 'frequent':
        return 'الأكثر زيارة';
      case 'recent':
        return 'الأحدث';
      default:
        return 'مفلتر';
    }
  }

  String _getPlaceTypeArabic(String placeType) {
    switch (placeType) {
      case 'shopping':
        return 'تسوق';
      case 'food':
        return 'طعام';
      case 'recreation':
        return 'ترفيه';
      case 'healthcare':
        return 'صحة';
      case 'education':
        return 'تعليم';
      case 'transport':
        return 'مواصلات';
      case 'worship':
        return 'عبادة';
      case 'family':        // ✅ إضافة
        return 'عائلة';     // ✅
      default:
        return placeType;
    }
  }

  String _getLastVisitText(DateTime lastVisit) {
    final now = DateTime.now();
    final difference = now.difference(lastVisit);

    if (difference.inMinutes < 60) return '${difference.inMinutes}د';
    if (difference.inHours < 24) return '${difference.inHours}س';
    if (difference.inDays < 7) return '${difference.inDays}ي';
    return '${(difference.inDays / 7).floor()}أ';
  }
}