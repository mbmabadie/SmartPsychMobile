// lib/features/activity/widgets/InsightsWidget.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/database/models/common_models.dart';
import '../../../../core/providers/activity_tracking_provider.dart';
import '../../../../core/services/insights_service.dart';
import '../../../../shared/theme/app_colors.dart';

class InsightsWidget extends StatelessWidget {
  const InsightsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityTrackingProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withOpacity(0.1),
                blurRadius: 20.r,
                offset: Offset(0, 10.h),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: 16.h),
              _buildInsightsContent(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            Icons.lightbulb_rounded,
            color: Colors.white,
            size: 24.sp,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            'الرؤى والتوصيات الذكية',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsContent(ActivityTrackingProvider provider) {
    final insights = provider.state.insights;

    if (insights == null || insights.isEmpty) {
      return _buildNoInsights(provider);
    }

    return Column(
      children: [
        ...insights.take(3).map((insight) => _buildInsightCard(insight)).toList(),

        if (insights.length > 3) ...[
          SizedBox(height: 12.h),
          _buildMoreInsightsButton(insights.length - 3),
        ],
      ],
    );
  }

  Widget _buildNoInsights(ActivityTrackingProvider provider) {
    final hasData = provider.state.todaysSummary?.totalSteps != null &&
        provider.state.todaysSummary!.totalSteps > 0;

    return Center(
      child: Column(
        children: [
          Icon(
            hasData ? Icons.insights_rounded : Icons.trending_up_rounded,
            size: 48.sp,
            color: AppColors.textMuted,
          ),
          SizedBox(height: 16.h),
          Text(
            hasData ? 'لا توجد رؤى جديدة' : 'ابدأ النشاط لتحصل على رؤى',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            hasData
                ? 'استمر في النشاط لتحصل على رؤى ذكية'
                : 'ابدأ المشي أو أي نشاط بدني',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (!hasData) ...[
            SizedBox(height: 16.h),
            _buildStartActivityButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildStartActivityButton() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: 16.sp,
          ),
          SizedBox(width: 4.w),
          Text(
            'ابدأ النشاط',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(Insight insight) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _getInsightColor(insight.insightType),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: _getInsightColor(insight.insightType),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  _getInsightIcon(insight.insightType),
                  color: Colors.white,
                  size: 16.sp,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  insight.title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: _getInsightColor(insight.insightType),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '${(insight.confidenceScore * 100).round()}%',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            insight.message,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textSecondary,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  insight.category,
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              /*SizedBox(width: 6.w),
              if (insight.subcategory != null) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: _getInsightColor(insight.insightType),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    insight.subcategory!,
                    style: TextStyle(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
              Spacer(),
              Text(
                _formatTime(insight.createdAt),
                style: TextStyle(
                  fontSize: 9.sp,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),*/
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoreInsightsButton(int remainingCount) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.secondary),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        'عرض $remainingCount رؤية إضافية',
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.secondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Color _getInsightColor(InsightType type) {
    switch (type) {
      case InsightType.positive:
        return AppColors.success;
      case InsightType.negative:
        return AppColors.error;
      case InsightType.neutral:
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getInsightIcon(InsightType type) {
    switch (type) {
      case InsightType.positive:
        return Icons.trending_up_rounded;
      case InsightType.negative:
        return Icons.warning_rounded;
      case InsightType.neutral:
        return Icons.info_rounded;
      default:
        return Icons.lightbulb_outline_rounded;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inHours < 1) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inDays < 1) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return 'منذ ${difference.inDays} يوم';
    }
  }
}

class DetailedInsightCard extends StatelessWidget {
  final Insight insight;
  final VoidCallback? onTap;

  const DetailedInsightCard({
    Key? key,
    required this.insight,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: _getInsightColor(insight.insightType),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _getInsightColor(insight.insightType).withOpacity(0.1),
              blurRadius: 20.r,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: _getInsightColor(insight.insightType),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    _getInsightIcon(insight.insightType),
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.title,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: _getInsightColor(insight.insightType),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              insight.category,
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'دقة ${(insight.confidenceScore * 100).round()}%',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              insight.message,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDetailedTime(insight.createdAt),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16.sp,
                    color: _getInsightColor(insight.insightType),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getInsightColor(InsightType type) {
    switch (type) {
      case InsightType.positive:
        return AppColors.success;
      case InsightType.negative:
        return AppColors.error;
      case InsightType.neutral:
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getInsightIcon(InsightType type) {
    switch (type) {
      case InsightType.positive:
        return Icons.trending_up_rounded;
      case InsightType.negative:
        return Icons.warning_rounded;
      case InsightType.neutral:
        return Icons.info_rounded;
      default:
        return Icons.lightbulb_outline_rounded;
    }
  }

  String _formatDetailedTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 5) {
      return 'منذ لحظات';
    } else if (difference.inHours < 1) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inDays < 1) {
      final hour = time.hour;
      final minute = time.minute.toString().padLeft(2, '0');
      return 'اليوم ${hour}:${minute}';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else {
      return 'منذ ${difference.inDays} أيام';
    }
  }
}