// lib/features/location/widgets/location_timeline_chart.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import '../../../../core/database/models/activity_models.dart';
import '../../../../core/providers/location_provider.dart';
import '../../../../shared/theme/app_colors.dart';

class LocationTimelineChart extends StatefulWidget {
  final List<LocationVisit> visits;
  final LocationVisit? currentVisit;
  final VoidCallback? onRefresh;

  const LocationTimelineChart({
    Key? key,
    required this.visits,
    this.currentVisit,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<LocationTimelineChart> createState() => _LocationTimelineChartState();
}

class _LocationTimelineChartState extends State<LocationTimelineChart> {
  LocationVisit? _selectedVisit;
  final ScrollController _timelineScrollController = ScrollController();
  final TextEditingController _editNameController = TextEditingController();

  @override
  void dispose() {
    _timelineScrollController.dispose();
    _editNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _selectedVisit != null ? 700 : 550,
      padding: const EdgeInsets.all(20),
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
          const SizedBox(height: 20),
          Expanded(
            child: widget.visits.isEmpty
                ? _buildEmptyState()
                : _buildScrollableTimeline(),
          ),
          if (_selectedVisit != null) ...[
            const SizedBox(height: 16),
            _buildEnhancedVisitDetails(_selectedVisit!),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final totalTime = widget.visits.fold<Duration>(
      Duration.zero,
          (sum, visit) => sum + (visit.duration ?? Duration.zero),
    );

    final uniquePlaces = widget.visits
        .map((v) => v.placeName ?? 'غير معروف')
        .toSet()
        .length;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.timeline,
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
                'الحركة خلال اليوم',
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
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified,
                          size: 12,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'مباشر',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$uniquePlaces أماكن',
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
              _formatDuration(totalTime),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
            Text(
              'إجمالي الوقت',
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

  Widget _buildScrollableTimeline() {
    final sortedVisits = List<LocationVisit>.from(widget.visits)
      ..sort((a, b) => a.arrivalTime.compareTo(b.arrivalTime));

    return Scrollbar(
      controller: _timelineScrollController,
      thumbVisibility: sortedVisits.length > 5,
      child: RefreshIndicator(
        onRefresh: () async {
          widget.onRefresh?.call();
        },
        child: SingleChildScrollView(
          controller: _timelineScrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height * 0.3,
            ),
            child: Column(
              children: [
                if (widget.currentVisit != null)
                  _buildCurrentLocationItem(widget.currentVisit!),

                ...sortedVisits.asMap().entries.map((entry) {
                  final index = entry.key;
                  final visit = entry.value;
                  final isLast = index == sortedVisits.length - 1;

                  return _buildTimelineItem(visit, isLast, index);
                }),

                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentLocationItem(LocationVisit currentVisit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.success,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.my_location,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: currentVisit.id != null
                            ? () => _showEditPlaceNameDialog(currentVisit)
                            : null,
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                currentVisit.placeName ?? 'الموقع الحالي',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (currentVisit.id != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'الآن',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'منذ ${_formatDuration(DateTime.now().difference(currentVisit.arrivalTime))}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _openLocationInMaps(currentVisit),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.map,
                              size: 12,
                              color: AppColors.info,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'خرائط',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.info,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(LocationVisit visit, bool isLast, int index) {
    final isSelected = _selectedVisit?.id == visit.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedVisit = isSelected ? null : visit;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getVisitColor(visit),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? _getVisitColor(visit)
                          : Colors.white,
                      width: isSelected ? 3 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getVisitColor(visit).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getVisitIcon(visit),
                    color: Colors.white,
                    size: 20,
                  ),
                ),

                if (!isLast)
                  Container(
                    width: 2,
                    height: 30,
                    color: _getVisitColor(visit),
                  ),
              ],
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primarySurface
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? _getVisitColor(visit)
                        : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showEditPlaceNameDialog(visit),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    visit.placeName ?? 'اضغط لتسمية المكان',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: visit.placeName != null
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (visit.isHome || visit.isWork)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: visit.isHome
                                  ? AppColors.info
                                  : AppColors.warning,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  visit.isHome ? Icons.home : Icons.work,
                                  size: 10,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  visit.isHome ? 'بيت' : 'عمل',
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimeRange(visit),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (visit.duration != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDuration(visit.duration!),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getVisitColor(visit),
                            ),
                          ),
                        ],
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _openLocationInMaps(visit),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.info,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.map,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedVisitDetails(LocationVisit visit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getVisitColor(visit),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getVisitIcon(visit),
                color: _getVisitColor(visit),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showEditPlaceNameDialog(visit),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          visit.placeName ?? 'اضغط لتسمية المكان',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getVisitColor(visit),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _getVisitColor(visit),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _openLocationInMaps(visit),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.info,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.map,
                            size: 16,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'خرائط',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedVisit = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'إغلاق',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.login,
                  label: 'وقت الوصول',
                  value: _formatTime(visit.arrivalTime),
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDetailItem(
                  icon: visit.departureTime != null ? Icons.logout : Icons.schedule,
                  label: visit.departureTime != null ? 'وقت المغادرة' : 'لا يزال هنا',
                  value: visit.departureTime != null
                      ? _formatTime(visit.departureTime!)
                      : 'مستمر',
                  color: visit.departureTime != null ? AppColors.error : AppColors.warning,
                ),
              ),
            ],
          ),

          if (visit.duration != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.timer,
                    label: 'مدة الزيارة',
                    value: _formatDuration(visit.duration!),
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.repeat,
                    label: 'عدد الزيارات',
                    value: '${visit.visitFrequency}',
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],

          if (visit.placeType != null || visit.accuracy != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (visit.placeType != null)
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.category,
                      label: 'نوع المكان',
                      value: _getPlaceTypeArabic(visit.placeType!),
                      color: AppColors.secondary,
                    ),
                  ),
                if (visit.placeType != null && visit.accuracy != null)
                  const SizedBox(width: 16),
                if (visit.accuracy != null)
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.gps_fixed,
                      label: 'دقة GPS',
                      value: '${visit.accuracy!.round()}م',
                      color: AppColors.primary,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
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
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditPlaceNameDialog(LocationVisit visit) {
    if (visit.id == null) return;

    _editNameController.text = visit.placeName ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسمية المكان'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _editNameController,
              decoration: const InputDecoration(
                hintText: 'أدخل اسم المكان',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit_location),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            Text(
              'سيتم تحديث جميع الزيارات المشابهة لهذا المكان',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _editNameController.clear();
              Navigator.pop(context);
            },
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newName = _editNameController.text.trim();
              if (newName.isNotEmpty) {
                final locationProvider = context.read<LocationProvider>();
                final success = await locationProvider.updatePlaceName(visit.id!, newName);

                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم تحديث اسم المكان إلى "$newName"'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );

                  if (_selectedVisit?.id == visit.id) {
                    setState(() {
                      _selectedVisit = _selectedVisit!.copyWith(placeName: newName);
                    });
                  }

                  widget.onRefresh?.call();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('فشل في تحديث اسم المكان'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _openLocationInMaps(LocationVisit visit) {
    final locationProvider = context.read<LocationProvider>();
    locationProvider.openLocationInGoogleMaps(
      visit.latitude,
      visit.longitude,
      placeName: visit.placeName,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد زيارات اليوم',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بالتنقل لترى تحركاتك هنا',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: widget.onRefresh,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('تحديث'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Helper methods مع التعديلات
  Color _getVisitColor(LocationVisit visit) {
    if (visit.isHome) return AppColors.info;
    if (visit.isWork) return AppColors.warning;

    switch (visit.placeType) {
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
      case 'family':                    // ✅ إضافة
        return Color(0xFFE91E63);       // ✅ Pink
      default:
        return AppColors.primary;
    }
  }

  IconData _getVisitIcon(LocationVisit visit) {
    if (visit.isHome) return Icons.home;
    if (visit.isWork) return Icons.work;

    switch (visit.placeType) {
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
      case 'family':                    // ✅ إضافة
        return Icons.family_restroom;   // ✅
      default:
        return Icons.place;
    }
  }

  String _getPlaceTypeArabic(String placeType) {
    switch (placeType) {
      case 'home':
        return 'منزل';
      case 'work':
        return 'عمل';
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
      case 'family':          // ✅ إضافة
        return 'عائلة';       // ✅
      default:
        return placeType;
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeRange(LocationVisit visit) {
    final start = _formatTime(visit.arrivalTime);
    final end = visit.departureTime != null
        ? _formatTime(visit.departureTime!)
        : 'مستمر';
    return '$start - $end';
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