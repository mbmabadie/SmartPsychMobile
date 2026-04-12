// lib/features/location/views/location_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_psych/features/location/views/widgets/location_circular_progress.dart';
import 'package:smart_psych/features/location/views/widgets/location_insights_card.dart';
import 'package:smart_psych/features/location/views/widgets/location_timeline_chart.dart';
import 'package:smart_psych/features/location/views/widgets/top_places_list.dart';

import '../../../core/providers/location_provider.dart';
import '../../../core/database/models/activity_models.dart';
import '../../../core/services/location_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/loading_states.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({Key? key}) : super(key: key);

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen>
    with AutomaticKeepAliveClientMixin {

  bool _hasLocationPermission = false;
  bool _isCheckingPermission = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    if (!mounted) return;

    setState(() => _isCheckingPermission = true);

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _hasLocationPermission = true;
          _isCheckingPermission = false;
        });

        final provider = context.read<LocationProvider>();
        await provider.initialize();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasLocationPermission = false;
          _isCheckingPermission = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Consumer<LocationProvider>(
          builder: (context, provider, child) {
            return RefreshIndicator(
              onRefresh: () => provider.refresh(),
              color: AppColors.primary,
              backgroundColor: Colors.white,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (!_hasLocationPermission || _isCheckingPermission)
                    _buildPermissionSliver(),

                  if (_hasLocationPermission && provider.isLoading)
                    _buildLoadingSliver(),

                  if (_hasLocationPermission &&
                      !provider.isLoading &&
                      !_hasLocationData(provider))
                    _buildNoDataSliver(),

                  if (_hasLocationPermission &&
                      !provider.isLoading &&
                      _hasLocationData(provider)) ...[
                    _buildHeaderSliver(provider),
                    _buildMainContentSliver(provider),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderSliver(LocationProvider provider) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildMainLocationCard(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildMainLocationCard(LocationProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildLocationStatsHeader(provider),
          const SizedBox(height: 24),
          LocationCircularProgress(
            totalVisits: provider.visits.length,
            uniquePlaces: provider.analytics['unique_places'] ?? 0,
            homeVisits: provider.analytics['home_visits'] ?? 0,
            workVisits: provider.analytics['work_visits'] ?? 0,
            isTracking: provider.isTracking,
            currentLocation: provider.currentVisit?.placeName ?? 'غير معروف',
            size: 200,
          ),
          const SizedBox(height: 20),
          _buildLocationStatsGrid(provider),
        ],
      ),
    );
  }

  Widget _buildLocationStatsHeader(LocationProvider provider) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.location_on,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الأماكن المزارة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                provider.isTracking ? 'التتبع نشط' : 'التتبع متوقف',
                style: TextStyle(
                  fontSize: 12,
                  color: provider.isTracking ? AppColors.success : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (provider.isTracking)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'نشط',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLocationStatsGrid(LocationProvider provider) {
    final stats = provider.getQuickStats();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLocationDetail(
            'الزيارات',
            '${stats['total_visits']}',
            Icons.location_history,
            AppColors.primary,
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.border,
          ),
          _buildLocationDetail(
            'أماكن فريدة',
            '${stats['unique_places']}',
            Icons.place,
            AppColors.secondary,
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.border,
          ),
          _buildLocationDetail(
            'الوقت الإجمالي',
            '${(stats['total_time_hours'] as double).toStringAsFixed(1)}س',
            Icons.access_time,
            AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDetail(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
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

  Widget _buildMainContentSliver(LocationProvider provider) {
    final allVisits = <LocationVisit>[];

    if (provider.currentVisit != null) {
      allVisits.add(provider.currentVisit!);
    }

    allVisits.addAll(provider.visits);

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (provider.isTracking && provider.currentVisit != null) ...[
                _buildCurrentLocationCard(provider),
                const SizedBox(height: 24),
              ],

              if (allVisits.isNotEmpty) ...[
                _buildSectionTitle('الحركة خلال اليوم', Icons.timeline),
                const SizedBox(height: 12),
                LocationTimelineChart(
                  visits: allVisits,
                  currentVisit: provider.currentVisit,
                ),
                const SizedBox(height: 24),
              ],

              if (provider.frequentPlaces.isNotEmpty) ...[
                _buildSectionTitle('أكثر الأماكن زيارة', Icons.place),
                const SizedBox(height: 12),
                TopPlacesList(
                  places: provider.frequentPlaces,
                  savedPlaces: provider.savedPlaces,
                  onSetAsHome: (visitId) => provider.setAsHome(visitId),
                  onSetAsWork: (visitId) => provider.setAsWork(visitId),
                ),
                const SizedBox(height: 24),
              ],

              if (provider.insights.isNotEmpty) ...[
                _buildSectionTitle('رؤى المواقع', Icons.lightbulb_outline),
                const SizedBox(height: 12),
                LocationInsightsCard(
                  insights: provider.insights,
                  analytics: provider.analytics,
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ]),
      ),
    );
  }

  Widget _buildCurrentLocationCard(LocationProvider provider) {
    final currentVisit = provider.currentVisit!;
    final duration = DateTime.now().difference(currentVisit.arrivalTime);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.success, AppColors.success.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.my_location,
                  color: AppColors.success,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الموقع الحالي',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentVisit.placeName ?? 'موقع جديد',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'مدة البقاء',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white30),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'حتى الحفظ',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          duration.inMinutes >= 5
                              ? 'جاهز للحفظ ✓'
                              : '${5 - duration.inMinutes} دقيقة متبقية',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (duration.inMinutes / 5.0).clamp(0.0, 1.0),
                        backgroundColor: Colors.white30,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          duration.inMinutes >= 5 ? Colors.white : Colors.white70,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ✅ زر الحفظ المعدّل
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // ✅ فتح Dialog
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) => SaveLocationDialog(
                        currentLocation: provider.currentVisit,
                      ),
                    );

                    // ✅ تحديث البيانات إذا تم الحفظ
                    if (result == true && mounted) {
                      await provider.refresh();
                    }
                  },
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('حفظ الآن'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionSliver() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Container(
        color: AppColors.backgroundLight,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'إذن الوصول للموقع',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'نحتاج إذن الوصول لموقعك لتتبع الأماكن التي تزورها.\n'
                      'هذا الإذن آمن ولا يشارك موقعك مع أي طرف ثالث.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_isCheckingPermission)
                  CircularProgressIndicator(
                    color: AppColors.primary,
                  )
                else
                  Container(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSliver() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: LoadingStates.modernLoading(
        message: 'جاري تحميل بيانات المواقع...',
      ),
    );
  }

  Widget _buildNoDataSliver() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Consumer<LocationProvider>(
        builder: (context, provider, _) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: provider.isTracking
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.textSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Icon(
                      provider.isTracking ? Icons.location_searching : Icons.location_off,
                      size: 64,
                      color: provider.isTracking ? AppColors.success : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    provider.isTracking
                        ? 'جاري تتبع موقعك...'
                        : 'لا توجد بيانات مواقع',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  Text(
                    provider.isTracking
                        ? 'سيتم حفظ موقعك بعد البقاء 5 دقائق.\nأو يمكنك الحفظ يدوياً الآن.'
                        : 'ابدأ بتفعيل تتبع المواقع لترى الأماكن التي تزورها.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // ✅ زر الحفظ المعدّل
                  if (provider.isTracking)
                    ElevatedButton.icon(
                      onPressed: () async {
                        // ✅ فتح Dialog
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (context) => SaveLocationDialog(
                            currentLocation: provider.currentVisit,
                          ),
                        );

                        // ✅ تحديث البيانات إذا تم الحفظ
                        if (result == true && mounted) {
                          await provider.refresh();
                        }
                      },
                      icon: const Icon(Icons.save_alt),
                      label: const Text('حفظ الموقع الآن'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  bool _hasLocationData(LocationProvider provider) {
    return provider.visits.isNotEmpty ||
        provider.frequentPlaces.isNotEmpty ||
        provider.currentVisit != null;
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


// ════════════════════════════════════════════════════════════════
// ✅ SaveLocationDialog - مضاف في نفس الملف
// ════════════════════════════════════════════════════════════════

class SaveLocationDialog extends StatefulWidget {
  final LocationVisit? currentLocation;

  const SaveLocationDialog({
    Key? key,
    this.currentLocation,
  }) : super(key: key);

  @override
  State<SaveLocationDialog> createState() => _SaveLocationDialogState();
}

class _SaveLocationDialogState extends State<SaveLocationDialog> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedPlaceType;
  bool _isSaving = false;

  final List<PlaceTypeOption> _placeTypes = [
    PlaceTypeOption(
      type: 'home',
      icon: Icons.home,
      label: 'البيت',
      color: AppColors.info,
    ),
    PlaceTypeOption(
      type: 'work',
      icon: Icons.work,
      label: 'العمل',
      color: AppColors.warning,
    ),
    PlaceTypeOption(
      type: 'education',
      icon: Icons.school,
      label: 'الدراسة',
      color: AppColors.primary,
    ),
    PlaceTypeOption(
      type: 'healthcare',
      icon: Icons.local_hospital,
      label: 'العلاج',
      color: AppColors.error,
    ),
    PlaceTypeOption(
      type: 'family',
      icon: Icons.family_restroom,
      label: 'العائلة',
      color: Color(0xFFE91E63),
    ),
    PlaceTypeOption(
      type: 'shopping',
      icon: Icons.shopping_bag,
      label: 'تسوق',
      color: Color(0xFF9C27B0),
    ),
    PlaceTypeOption(
      type: 'food',
      icon: Icons.restaurant,
      label: 'طعام',
      color: Color(0xFFFF9800),
    ),
    PlaceTypeOption(
      type: 'recreation',
      icon: Icons.sports_esports,
      label: 'ترفيه',
      color: AppColors.success,
    ),
    PlaceTypeOption(
      type: 'transport',
      icon: Icons.directions_bus,
      label: 'مواصلات',
      color: Color(0xFF607D8B),
    ),
    PlaceTypeOption(
      type: 'worship',
      icon: Icons.mosque,
      label: 'عبادة',
      color: Color(0xFF00BCD4),
    ),
    PlaceTypeOption(
      type: 'other',
      icon: Icons.place,
      label: 'أخرى',
      color: AppColors.textSecondary,
    ),
  ];

  @override
  void initState() {
    super.initState();

    if (widget.currentLocation?.placeName != null) {
      _nameController.text = widget.currentLocation!.placeName!;
    }

    if (widget.currentLocation?.placeType != null) {
      _selectedPlaceType = widget.currentLocation!.placeType;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLocationInfo(),
                    const SizedBox(height: 24),
                    _buildNameField(),
                    const SizedBox(height: 24),
                    _buildPlaceTypeSection(),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.success, AppColors.success.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.save_alt,
              color: AppColors.success,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'حفظ الموقع',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'أضف معلومات عن هذا المكان',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo() {
    if (widget.currentLocation == null) {
      return const SizedBox.shrink();
    }

    final location = widget.currentLocation!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'إحداثيات الموقع',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'خط العرض',
                  location.latitude.toStringAsFixed(6),
                  Icons.height,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoItem(
                  'خط الطول',
                  location.longitude.toStringAsFixed(6),
                  Icons.swap_horiz,
                ),
              ),
            ],
          ),
          if (location.accuracy != null) ...[
            const SizedBox(height: 12),
            _buildInfoItem(
              'دقة GPS',
              '${location.accuracy!.round()} متر',
              Icons.gps_fixed,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.edit_location,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'اسم المكان',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'مطلوب',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'مثال: بيت جدتي، مستشفى الأمل، مكتبة الجامعة...',
            hintStyle: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
            prefixIcon: Icon(
              Icons.text_fields,
              color: AppColors.primary,
              size: 20,
            ),
            filled: true,
            fillColor: AppColors.backgroundLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          textInputAction: TextInputAction.next,
          autofocus: true,
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 14,
              color: AppColors.secondary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'اختر اسماً مميزاً ليسهل عليك تذكر هذا المكان',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.category,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'نوع المكان',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (_selectedPlaceType != null)
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
                      Icons.check_circle,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'تم الاختيار',
                      style: TextStyle(
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
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _placeTypes.length,
          itemBuilder: (context, index) {
            final placeType = _placeTypes[index];
            final isSelected = _selectedPlaceType == placeType.type;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPlaceType = placeType.type;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? placeType.color.withOpacity(0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? placeType.color : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: placeType.color.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: placeType.color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        placeType.icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      placeType.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? placeType.color
                            : AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 4),
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: placeType.color,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final canSave = _nameController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.border),
                ),
              ),
              child: Text(
                'إلغاء',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: canSave && !_isSaving ? _saveLocation : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canSave ? AppColors.success : AppColors.textMuted,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save, size: 20, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'حفظ الموقع',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: canSave ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveLocation() async {
    final placeName = _nameController.text.trim();

    if (placeName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('⚠️ يرجى إدخال اسم المكان'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final success = await LocationService.instance.forceCurrentLocationSave(
        customPlaceName: placeName,
        customPlaceType: _selectedPlaceType,
      );

      if (!mounted) return;

      if (success) {
        final provider = context.read<LocationProvider>();
        await provider.refresh();

        Navigator.of(context).pop(true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم حفظ "$placeName" بنجاح'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('❌ فشل في حفظ الموقع'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ خطأ: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

class PlaceTypeOption {
  final String type;
  final IconData icon;
  final String label;
  final Color color;

  const PlaceTypeOption({
    required this.type,
    required this.icon,
    required this.label,
    required this.color,
  });
}