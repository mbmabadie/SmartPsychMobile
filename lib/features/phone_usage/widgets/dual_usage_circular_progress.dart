// lib/features/phone_usage/widgets/dual_usage_circular_progress.dart
// ✅ تصميم سطر واحد - بسيط ومختصر

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../shared/theme/app_colors.dart';

class DualUsageCircularProgress extends StatelessWidget {
  final Duration currentUsage;
  final Duration unifiedUsage;
  final Duration targetUsage;
  final double syncAccuracy;
  final double size;
  final VoidCallback? onGoalTap;

  const DualUsageCircularProgress({
    Key? key,
    required this.currentUsage,
    required this.unifiedUsage,
    required this.targetUsage,
    required this.syncAccuracy,
    this.size = 180,
    this.onGoalTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentProgress = (currentUsage.inMinutes / targetUsage.inMinutes).clamp(0.0, 1.2);
    final isOverGoal = currentProgress > 1.0;
    final percentage = (currentUsage.inMinutes / targetUsage.inMinutes * 100).round();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: isOverGoal
              ? [Colors.red.shade50, Colors.white]
              : [Colors.blue.shade50, Colors.white],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isOverGoal
              ? AppColors.error.withOpacity(0.2)
              : AppColors.primary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // ✅ السطر الوحيد - كل شي فيه
          Row(
            children: [
              // الاستخدام
              Icon(
                Icons.access_time_rounded,
                size: 20.sp,
                color: isOverGoal ? AppColors.error : AppColors.primary,
              ),
              SizedBox(width: 6.w),
             /* Text(
                _formatDuration(currentUsage),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                  color: isOverGoal ? AppColors.error : AppColors.primary,
                ),
              ),

              SizedBox(width: 12.w),*/

              // النسبة المئوية
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: _getStatusColor(),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getStatusIcon(), size: 12.sp, color: Colors.white),
                    SizedBox(width: 4.w),
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              Spacer(),

              // الهدف
              Icon(
                Icons.flag_rounded,
                size: 18.sp,
                color: AppColors.secondary,
              ),
              SizedBox(width: 6.w),
              Text(
                _formatDuration(targetUsage),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondary,
                ),
              ),

              SizedBox(width: 12.w),

              // زر التعديل
              if (onGoalTap != null)
                GestureDetector(
                  onTap: onGoalTap,
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      size: 14.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: 12.h),

          // ✅ البروجرس بار
          Container(
            height: 6.h,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(3.r),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerRight,
              widthFactor: currentProgress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isOverGoal
                        ? [AppColors.error, AppColors.error.withOpacity(0.7)]
                        : _getProgressGradient(),
                  ),
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getProgressGradient() {
    final percentage = currentUsage.inMinutes / targetUsage.inMinutes;
    if (percentage >= 0.8) return [AppColors.warning, AppColors.warning.withOpacity(0.7)];
    return [AppColors.success, AppColors.success.withOpacity(0.7)];
  }

  Color _getStatusColor() {
    final isOverGoal = currentUsage > targetUsage;
    if (isOverGoal) return AppColors.error;
    final percentage = currentUsage.inMinutes / targetUsage.inMinutes;
    if (percentage >= 0.8) return AppColors.warning;
    return AppColors.success;
  }

  IconData _getStatusIcon() {
    final isOverGoal = currentUsage > targetUsage;
    if (isOverGoal) return Icons.warning_rounded;
    final percentage = currentUsage.inMinutes / targetUsage.inMinutes;
    if (percentage >= 0.8) return Icons.access_time_rounded;
    return Icons.check_circle_rounded;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) return '${hours}س ${minutes}د';
    return '${minutes}د';
  }
}
