// lib/features/sleep/widgets/confirmation/time_adjustment_bottom_sheet.dart - النسخة البسيطة

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../core/database/models/sleep_models.dart';
import '../../../../shared/theme/app_colors.dart';

class TimeAdjustmentBottomSheet extends StatefulWidget {
  final SleepSession session;
  final Function(DateTime startTime, DateTime endTime) onTimesAdjusted;

  const TimeAdjustmentBottomSheet({
    Key? key,
    required this.session,
    required this.onTimesAdjusted,
  }) : super(key: key);

  @override
  State<TimeAdjustmentBottomSheet> createState() =>
      _TimeAdjustmentBottomSheetState();
}

class _TimeAdjustmentBottomSheetState extends State<TimeAdjustmentBottomSheet> {
  late DateTime _startTime;
  late DateTime _endTime;
  bool _showStartPicker = false;
  bool _showEndPicker = false;

  @override
  void initState() {
    super.initState();
    _startTime = widget.session.startTime;
    _endTime = widget.session.endTime ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final duration = _endTime.difference(_startTime);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    child: Icon(
                      Icons.edit_calendar,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    '⏰ تصحيح أوقات النوم',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // وقت النوم
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _buildTimeCard(
                title: 'وقت النوم',
                icon: '🌙',
                time: _startTime,
                onTap: () {
                  setState(() {
                    _showStartPicker = true;
                    _showEndPicker = false;
                  });
                },
              ),
            ),

            SizedBox(height: 12),

            // وقت الاستيقاظ
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _buildTimeCard(
                title: 'وقت الاستيقاظ',
                icon: '☀️',
                time: _endTime,
                onTap: () {
                  setState(() {
                    _showEndPicker = true;
                    _showStartPicker = false;
                  });
                },
              ),
            ),

            SizedBox(height: 20),

            // المدة الجديدة
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.access_time,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'المدة الجديدة: ',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${duration.inHours} س ${duration.inMinutes.remainder(60)} د',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Time Picker
            if (_showStartPicker || _showEndPicker) ...[
              SizedBox(height: 20),
              Container(
                height: 200,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: false,
                  initialDateTime: _showStartPicker ? _startTime : _endTime,
                  onDateTimeChanged: (DateTime newTime) {
                    setState(() {
                      if (_showStartPicker) {
                        _startTime = DateTime(
                          _startTime.year,
                          _startTime.month,
                          _startTime.day,
                          newTime.hour,
                          newTime.minute,
                        );
                      } else {
                        _endTime = DateTime(
                          _endTime.year,
                          _endTime.month,
                          _endTime.day,
                          newTime.hour,
                          newTime.minute,
                        );
                      }
                    });
                  },
                ),
              ),
            ],

            SizedBox(height: 20),

            // الأزرار
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('إلغاء'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppColors.border, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        widget.onTimesAdjusted(_startTime, _endTime);
                      },
                      icon: Icon(Icons.check),
                      label: Text('تأكيد التعديل'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard({
    required String title,
    required String icon,
    required DateTime time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary, width: 1),
              ),
              child: Text(icon, style: TextStyle(fontSize: 28)),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _formatTime(time),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit,
              color: AppColors.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12
        ? time.hour - 12
        : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'مساءً' : 'صباحاً';
    return '$hour:$minute $period';
  }
}