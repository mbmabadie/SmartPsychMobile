// lib/features/sleep/screens/sleep_confirmation_screen.dart - النسخة البسيطة

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/sleep_tracking_provider.dart';
import '../../../core/database/models/sleep_models.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/unified_app_bar.dart';
import '../widgets/confirmation/sleep_summary_card.dart';
import '../widgets/confirmation/sleep_rating_slider.dart';
import '../widgets/confirmation/sleep_factors_chips.dart';
import '../widgets/confirmation/time_adjustment_bottom_sheet.dart';

class SleepConfirmationScreen extends StatefulWidget {
  const SleepConfirmationScreen({Key? key}) : super(key: key);

  @override
  State<SleepConfirmationScreen> createState() => _SleepConfirmationScreenState();
}

class _SleepConfirmationScreenState extends State<SleepConfirmationScreen> {
  int _currentSessionIndex = 0;
  double _qualityRating = 7.0;
  final TextEditingController _notesController = TextEditingController();
  final List<String> _selectedFactors = [];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: UnifiedAppBar(
        greeting: 'تأكيد النوم',
        subtitle: 'قيّم جودة نومك',
        onNotificationTap: () {},
        onProfileTap: () {},
        hasNotificationBadge: false,
      ),
      body: Consumer<SleepTrackingProvider>(
        builder: (context, provider, _) {
          final pendingSessions = provider.state.pendingConfirmations;

          if (pendingSessions.isEmpty) {
            return _buildEmptyState();
          }

          final currentSession = pendingSessions[_currentSessionIndex];

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // مؤشر الجلسات المتعددة
                if (pendingSessions.length > 1)
                  _buildSessionIndicator(pendingSessions.length),

                SizedBox(height: 16),

                // ملخص الجلسة
                SleepSummaryCard(
                  session: currentSession,
                  onEditTimePressed: () => _showTimeAdjustment(
                    context,
                    currentSession,
                    provider,
                  ),
                ),

                SizedBox(height: 24),

                // سؤال التأكيد
                _buildConfirmationQuestion(currentSession, provider),

                SizedBox(height: 24),

                // تقييم الجودة
                _buildQualityRatingSection(),

                SizedBox(height: 24),

                // الملاحظات
                _buildNotesSection(),

                SizedBox(height: 24),

                // العوامل المؤثرة
                SleepFactorsChips(
                  selectedFactors: _selectedFactors,
                  onFactorsChanged: (factors) {
                    setState(() {
                      _selectedFactors.clear();
                      _selectedFactors.addAll(factors);
                    });
                  },
                ),

                SizedBox(height: 32),

                // أزرار الإجراءات
                _buildActionButtons(currentSession, provider, pendingSessions),

                SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionIndicator(int totalSessions) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'جلسة ${_currentSessionIndex + 1} من $totalSessions',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Row(
            children: List.generate(
              totalSessions,
                  (index) => Container(
                margin: EdgeInsets.symmetric(horizontal: 3),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: index == _currentSessionIndex
                      ? Colors.white
                      : AppColors.primarySurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationQuestion(
      SleepSession session,
      SleepTrackingProvider provider,
      ) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            'هل هذه المعلومات صحيحة؟',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // الانتقال لتقييم الجودة مباشرة
                  },
                  icon: Icon(Icons.check_circle),
                  label: Text('نعم، صحيح'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showTimeAdjustment(
                    context,
                    session,
                    provider,
                  ),
                  icon: Icon(Icons.edit),
                  label: Text('تعديل'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppColors.primary, width: 2),
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

  Widget _buildQualityRatingSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('⭐', style: TextStyle(fontSize: 24)),
              SizedBox(width: 8),
              Text(
                'كيف كانت جودة نومك؟',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          SleepRatingSlider(
            initialRating: _qualityRating,
            onRatingChanged: (rating) {
              setState(() {
                _qualityRating = rating;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('📝', style: TextStyle(fontSize: 24)),
              SizedBox(width: 8),
              Text(
                'ملاحظات (اختياري)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'مثال: نمت جيداً لكن استيقظت مرة بسبب ضجيج...',
              hintStyle: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
              filled: true,
              fillColor: AppColors.backgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      SleepSession session,
      SleepTrackingProvider provider,
      List<SleepSession> pendingSessions,
      ) {
    return Column(
      children: [
        // زر حفظ التقييم
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _saveConfirmation(session, provider, pendingSessions),
            icon: Icon(Icons.save, size: 24),
            label: Text(
              'حفظ التقييم',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        SizedBox(height: 12),
        // زر رفض الجلسة
        TextButton.icon(
          onPressed: () => _rejectSession(session, provider, pendingSessions),
          icon: Icon(Icons.close, color: AppColors.error),
          label: Text(
            'لم أنم في هذا الوقت',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.success, width: 3),
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 80,
              color: AppColors.success,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'رائع! 🎉',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'لا توجد جلسات تحتاج تأكيد',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back),
            label: Text('العودة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTimeAdjustment(
      BuildContext context,
      SleepSession session,
      SleepTrackingProvider provider,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TimeAdjustmentBottomSheet(
        session: session,
        onTimesAdjusted: (newStartTime, newEndTime) async {
          await provider.modifySleepTimes(
            sessionId: session.id.toString(),
            newStartTime: newStartTime,
            newEndTime: newEndTime,
          );
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ تم تعديل الأوقات بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveConfirmation(
      SleepSession session,
      SleepTrackingProvider provider,
      List<SleepSession> pendingSessions,
      ) async {
    try {
      await provider.confirmSleepSession(
        sessionId: session.id.toString(),
        qualityRating: _qualityRating,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        factors: _selectedFactors.isEmpty ? null : _selectedFactors,
      );

      if (!mounted) return;

      // الانتقال للجلسة التالية أو الرجوع
      if (_currentSessionIndex < pendingSessions.length - 1) {
        setState(() {
          _currentSessionIndex++;
          _qualityRating = 7.0;
          _notesController.clear();
          _selectedFactors.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم حفظ التقييم'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 تم تأكيد جميع الجلسات بنجاح!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ حدث خطأ في حفظ التقييم'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _rejectSession(
      SleepSession session,
      SleepTrackingProvider provider,
      List<SleepSession> pendingSessions,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            SizedBox(width: 8),
            Text('تأكيد الرفض'),
          ],
        ),
        content: Text(
          'هل أنت متأكد أنك تريد رفض هذه الجلسة؟\n'
              'سيتم حذفها من السجل.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text('نعم، رفض'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await provider.rejectSleepSession(
        session.id.toString(),
        reason: 'تم رفضها من قبل المستخدم',
      );

      if (!mounted) return;

      if (_currentSessionIndex < pendingSessions.length - 1) {
        setState(() {
          _qualityRating = 7.0;
          _notesController.clear();
          _selectedFactors.clear();
        });
      } else {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم رفض الجلسة'),
          backgroundColor: AppColors.warning,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ حدث خطأ في رفض الجلسة'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}