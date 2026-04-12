// lib/screens/dialogs/activity_selection_dialog.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/models/activity_models.dart';
import '../../../../shared/theme/app_colors.dart';

class ActivitySelectionDialog extends StatefulWidget {
  const ActivitySelectionDialog({Key? key}) : super(key: key);

  @override
  State<ActivitySelectionDialog> createState() => _ActivitySelectionDialogState();
}

class _ActivitySelectionDialogState extends State<ActivitySelectionDialog> {
  ActivityType? _selectedActivity;
  bool _isStarting = false;

  final List<ActivityOption> _activities = [
    ActivityOption(
      type: ActivityType.walking,
      icon: Icons.directions_walk,
      title: 'المشي',
      description: 'نشاط خفيف ومناسب لجميع الأعمار',
      color: AppColors.walking,
      calories: '5-8 سعرة/دقيقة',
    ),
    ActivityOption(
      type: ActivityType.running,
      icon: Icons.directions_run,
      title: 'الجري',
      description: 'نشاط عالي الكثافة لحرق السعرات',
      color: AppColors.running,
      calories: '10-15 سعرة/دقيقة',
    ),
    ActivityOption(
      type: ActivityType.cycling,
      icon: Icons.directions_bike,
      title: 'ركوب الدراجة',
      description: 'نشاط ممتع ومفيد للساقين',
      color: AppColors.cycling,
      calories: '8-12 سعرة/دقيقة',
    ),
    ActivityOption(
      type: ActivityType.other,
      icon: Icons.fitness_center,
      title: 'تمرين رياضي',
      description: 'تمارين القوة واللياقة البدنية',
      color: AppColors.workout,
      calories: '6-10 سعرة/دقيقة',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: _buildDialogContent(),
    );
  }

  Widget _buildDialogContent() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 600),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          Flexible(
            child: _buildActivityList(),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.directions_run,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'اختر نوع النشاط',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ابدأ تتبع نشاطك البدني الآن',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: AppColors.textSecondary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceLight,
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      itemCount: _activities.length,
      itemBuilder: (context, index) {
        final activity = _activities[index];
        final isSelected = _selectedActivity == activity.type;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _selectActivity(activity.type),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activity.color.withOpacity(0.1)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? activity.color
                        : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: activity.color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        activity.icon,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                activity.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? activity.color
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: activity.color,
                                  size: 20,
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activity.description,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: activity.color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              activity.calories,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'نصيحة: يمكنك تغيير نوع النشاط أثناء التتبع',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _selectedActivity != null && !_isStarting
                      ? _startActivity
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedActivity != null
                        ? _getSelectedActivityColor()
                        : AppColors.textMuted,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isStarting
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
                      Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'بدء النشاط',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
    );
  }

  void _selectActivity(ActivityType activityType) {
    setState(() {
      _selectedActivity = activityType;
    });
  }

  Future<void> _startActivity() async {
    if (_selectedActivity == null) return;

    setState(() {
      _isStarting = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      Navigator.of(context).pop(_selectedActivity);
    }
  }

  Color _getSelectedActivityColor() {
    if (_selectedActivity == null) return AppColors.primary;

    final activity = _activities.firstWhere(
          (a) => a.type == _selectedActivity,
      orElse: () => _activities.first,
    );

    return activity.color;
  }
}

class ActivityOption {
  final ActivityType type;
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final String calories;

  const ActivityOption({
    required this.type,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.calories,
  });
}