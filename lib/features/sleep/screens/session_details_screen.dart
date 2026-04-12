// lib/features/sleep/screens/session_details_screen.dart - النسخة المعدّلة الكاملة
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/database/models/sleep_models.dart';
import '../../../core/database/models/sleep_confidence.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/unified_app_bar.dart';

class SessionDetailsScreen extends StatelessWidget {
  final SleepSession session;

  const SessionDetailsScreen({
    super.key,
    required this.session,
  });

  // ════════════════════════════════════════════════════════════
  // دوال UnifiedAppBar
  // ════════════════════════════════════════════════════════════

  String _getGreeting() {
    return 'تفاصيل الجلسة';
  }

  String _getSubtitle() {
    final duration = session.duration ?? Duration.zero;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    // ✅ استخدام التسمية الموحدة
    String confidenceName;
    switch (session.confidence) {
      case SleepConfidence.confirmed:
        confidenceName = 'نوم عميق';
        break;
      case SleepConfidence.probable:
        confidenceName = 'قيلولة';
        break;
      case SleepConfidence.uncertain:
        confidenceName = 'راحة قصيرة';
        break;
      case SleepConfidence.phoneLeft:
        confidenceName = 'هاتف متروك';
        break;
      default:
        confidenceName = session.confidence.displayName;
    }

    return '${hours}h ${minutes}m - $confidenceName';
  }

  @override
  Widget build(BuildContext context) {
    final duration = session.duration ?? Duration.zero;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          // UnifiedAppBar
          UnifiedAppBar(
            greeting: _getGreeting(),
            subtitle: _getSubtitle(),
            onNotificationTap: () {
              // TODO: عرض الإشعارات
            },
            onProfileTap: () {
              Navigator.pushNamed(context, '/profile');
            },
            hasNotificationBadge: false,
            showBackButton: true,
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header Card
                  _buildHeaderCard(context),

                  const SizedBox(height: 16),

                  // Duration Card
                  _buildDurationCard(context, hours, minutes),

                  const SizedBox(height: 16),

                  // Classification Card
                  _buildClassificationCard(context),

                  const SizedBox(height: 16),

                  // Evidence Card
                  _buildEvidenceCard(context),

                  const SizedBox(height: 16),

                  // Details Card
                  _buildDetailsCard(context),

                  const SizedBox(height: 16),

                  // Environmental Data
                  _buildEnvironmentalCard(context),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // Header Card
  // ════════════════════════════════════════════════════════════

  Widget _buildHeaderCard(BuildContext context) {
    // ✅ استخدام الإيموجي الموحد
    String emoji;
    switch (session.confidence) {
      case SleepConfidence.confirmed:
        emoji = '💤';
        break;
      case SleepConfidence.probable:
        emoji = '😴';
        break;
      case SleepConfidence.uncertain:
        emoji = '⏸️';
        break;
      case SleepConfidence.phoneLeft:
        emoji = '📱';
        break;
      default:
        emoji = session.confidence.emoji;
    }

    String displayName;
    switch (session.confidence) {
      case SleepConfidence.confirmed:
        displayName = 'نوم عميق';
        break;
      case SleepConfidence.probable:
        displayName = 'قيلولة';
        break;
      case SleepConfidence.uncertain:
        displayName = 'راحة قصيرة';
        break;
      case SleepConfidence.phoneLeft:
        displayName = 'هاتف متروك';
        break;
      default:
        displayName = session.confidence.displayName;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.primaryLight.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            // Emoji
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 48),
              ),
            ),

            const SizedBox(height: 16),

            // Confidence Name
            Text(
              displayName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            // Date
            Text(
              _formatDate(session.startTime),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationCard(BuildContext context, int hours, int minutes) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppColors.primarySurface,
              AppColors.primaryLight.withOpacity(0.1),
            ],
          ),
        ),
        child: Column(
          children: [
            Text(
              'مدة النوم',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${hours}h ${minutes}m',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  '${_formatTime(session.startTime)} - ${session.endTime != null ? _formatTime(session.endTime!) : "مستمر"}',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassificationCard(BuildContext context) {
    // ✅ التسمية الموحدة
    String displayName;
    switch (session.confidence) {
      case SleepConfidence.confirmed:
        displayName = 'نوم عميق';
        break;
      case SleepConfidence.probable:
        displayName = 'قيلولة';
        break;
      case SleepConfidence.uncertain:
        displayName = 'راحة قصيرة';
        break;
      case SleepConfidence.phoneLeft:
        displayName = 'هاتف متروك';
        break;
      default:
        displayName = session.confidence.displayName;
    }

    String emoji;
    switch (session.confidence) {
      case SleepConfidence.confirmed:
        emoji = '💤';
        break;
      case SleepConfidence.probable:
        emoji = '😴';
        break;
      case SleepConfidence.uncertain:
        emoji = '⏸️';
        break;
      case SleepConfidence.phoneLeft:
        emoji = '📱';
        break;
      default:
        emoji = session.confidence.emoji;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildSectionHeader(
                  context,
                  icon: Icons.psychology,
                  title: 'التصنيف الذكي',
                ),
                const Spacer(),
                // زر معلومات
                IconButton(
                  icon: Icon(Icons.info_outline, color: AppColors.primary),
                  onPressed: () => _showConfidenceInfo(context, session.confidence),
                  tooltip: 'شرح التصنيف',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              label: 'التصنيف',
              value: displayName,
              trailing: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
            const Divider(height: 24, color: AppColors.divider),
            _buildDetailRow(
              context,
              label: 'نوع الجلسة',
              value: _isNighttime(session.startTime) ? 'نوم ليلي' : 'نوم نهاري',
              icon: _isNighttime(session.startTime) ? Icons.nightlight : Icons.wb_sunny,
            ),
            if (session.detectionConfidence != null) ...[
              const Divider(height: 24, color: AppColors.divider),
              _buildDetailRow(
                context,
                label: 'ثقة الكشف',
                value: '${(session.detectionConfidence! * 100).toStringAsFixed(0)}%',
                icon: Icons.analytics,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // ✅ دالة _showConfidenceInfo المعدّلة بالكامل
  // ════════════════════════════════════════════════════════════

  void _showConfidenceInfo(BuildContext context, SleepConfidence confidence) {
    String title;
    String description;
    String explanation;
    IconData icon;
    Color color;

    switch (confidence) {
      case SleepConfidence.confirmed:
        title = '💤 نوم عميق';
        description = 'جلسة نوم حقيقية بنسبة ثقة عالية';
        explanation = '''
معايير التصنيف:

🌙 نوم ليلي (21:00-07:00):
  • مدة ≥ 3 ساعات

☀️ نوم نهاري (07:00-21:00):
  • مدة ≥ 2 ساعات
  • وجود دلائل نشاط بشري

🔍 دلائل النشاط:
  • استخدام الهاتف (آخر 15 دقيقة قبل النوم)
  • خطوات مشي (>10 خطوات)

مثال:
  استخدمت الهاتف الساعة 1:50 ظهراً
  ثم نمت من 2:00 إلى 4:15 (2h 15m)
  → نوم عميق ✅
      ''';
        icon = Icons.bedtime;
        color = const Color(0xFF4CAF50);  // أخضر
        break;

      case SleepConfidence.probable:
        title = '😴 قيلولة';
        description = 'على الأرجح نوم حقيقي، قد يحتاج تأكيد';
        explanation = '''
معايير التصنيف:

🌙 نوم ليلي:
  • مدة: 30 دقيقة - 3 ساعات

☀️ نوم نهاري:
  • مدة: 20 دقيقة - 2 ساعات
  • وجود دلائل نشاط بشري

💭 أسباب التصنيف كقيلولة:
  • مدة أقصر من النوم العميق
  • قد تكون قيلولة قصيرة
  • قد يكون نوم متقطع

✅ يُحتسب في إحصائيات النوم

مثال:
  نمت من 2:00 إلى 2:45 ظهراً (45 دقيقة)
  مع استخدام هاتف قبلها
  → قيلولة 😴
      ''';
        icon = Icons.airline_seat_individual_suite;
        color = const Color(0xFFFF9800);  // برتقالي
        break;

      case SleepConfidence.uncertain:
        title = '⏸️ راحة قصيرة';
        description = 'جلسة قصيرة أو غير واضحة - يُفضل التأكيد';
        explanation = '''
أسباب التصنيف:

⏱️ المدة:
  • نهاراً: أقل من 20 دقيقة
  • ليلاً: أقل من 30 دقيقة

📊 البيانات:
  • بيانات غير كافية للتأكيد
  • نمط نوم غير واضح

💡 ما يجب فعله:
  • قم بتأكيد الجلسة إذا كنت نائماً فعلاً
  • أو رفضها إذا لم تكن نائماً
  • سيساعد هذا في تحسين دقة النظام

⚠️ لا تُحتسب حتى التأكيد

مثال:
  سكون لمدة 15 دقيقة فقط
  → راحة قصيرة ⏸️
      ''';
        icon = Icons.pause_circle_outline;
        color = const Color(0xFFFFEB3B);  // أصفر
        break;

      case SleepConfidence.phoneLeft:
        title = '📱 هاتف متروك';
        description = 'الهاتف كان ثابتاً بدون نشاط بشري';
        explanation = '''
لماذا تم التصنيف كـ "هاتف متروك"؟

❌ لم يتم الكشف عن نشاط بشري:
  • لا استخدام للهاتف (آخر 15 دقيقة)
  • لا خطوات مشي
  • الهاتف كان ثابت تماماً

⚠️ هذا يحدث عندما:
  • الهاتف على الشاحن وأنت في مكان آخر
  • الهاتف في السيارة
  • الهاتف في الحقيبة أو الدرج
  • نسيت الهاتف في الغرفة

📵 ليس نوم:
  • هذه الجلسات لا تُحتسب في إحصائيات النوم
  • لكن تبقى مسجلة للمراجعة

مثال:
  الهاتف ثابت من 1:00 إلى 4:00 ظهراً
  بدون أي استخدام أو حركة قبلها
  → هاتف متروك 📱
      ''';
        icon = Icons.phone_disabled;
        color = const Color(0xFF90A4AE);  // رمادي
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  description,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: color.withOpacity(0.9),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                explanation,
                style: const TextStyle(
                  height: 1.6,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: color.withOpacity(0.1),
              foregroundColor: color,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'فهمت',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceCard(BuildContext context) {
    final hasEvidence = session.hasPreSleepActivity ?? false;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              context,
              icon: Icons.insights,
              title: 'دلائل النشاط البشري',
            ),
            const SizedBox(height: 16),

            // Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasEvidence
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasEvidence
                      ? Colors.green.shade200
                      : Colors.red.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasEvidence ? Icons.check_circle : Icons.cancel,
                    color: hasEvidence ? Colors.green.shade600 : Colors.red.shade600,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hasEvidence
                          ? 'تم الكشف عن نشاط بشري قبل النوم'
                          : 'لم يتم الكشف عن نشاط بشري',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: hasEvidence
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Details
            if (session.lastPhoneUsage != null)
              _buildEvidenceItem(
                context,
                icon: Icons.phone_android,
                label: 'آخر استخدام للهاتف',
                value: _formatTimeAgo(
                  session.lastPhoneUsage!,
                  session.startTime,
                ),
                isPositive: true,
              ),

            if (session.lastStepsCount != null) ...[
              const SizedBox(height: 12),
              _buildEvidenceItem(
                context,
                icon: Icons.directions_walk,
                label: 'عدد الخطوات (آخر 15 دقيقة)',
                value: '${session.lastStepsCount} خطوة',
                isPositive: session.lastStepsCount! > 10,
              ),
            ],

            if (session.lastPhoneUsage == null && session.lastStepsCount == null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'لا توجد بيانات متاحة',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              context,
              icon: Icons.info_outline,
              title: 'التفاصيل',
            ),
            const SizedBox(height: 16),

            _buildDetailRow(
              context,
              label: 'نوع التتبع',
              value: session.sleepType == 'automatic' ? 'تلقائي' : 'يدوي',
              icon: session.sleepType == 'automatic'
                  ? Icons.auto_awesome
                  : Icons.touch_app,
            ),

            const Divider(height: 24, color: AppColors.divider),

            _buildDetailRow(
              context,
              label: 'حالة التأكيد',
              value: _getConfirmationStatus(),
              icon: _getConfirmationIcon(),
            ),

            if (session.qualityScore != null) ...[
              const Divider(height: 24, color: AppColors.divider),
              _buildDetailRow(
                context,
                label: 'جودة النوم',
                value: '${session.qualityScore!.toStringAsFixed(1)}/5',
                icon: Icons.star,
                trailing: _buildStarRating(session.qualityScore!),
              ),
            ],

            if (session.notes != null && session.notes!.isNotEmpty) ...[
              const Divider(height: 24, color: AppColors.divider),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.note, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'ملاحظات',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.borderLight,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      session.notes!,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentalCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              context,
              icon: Icons.thermostat,
              title: 'البيانات البيئية',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.borderLight,
                  width: 1,
                ),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.eco,
                      size: 48,
                      color: AppColors.primaryLight,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'قريباً',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'سيتم عرض البيانات البيئية هنا',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
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

  // ════════════════════════════════════════════════════════════
  // Helper Widgets
  // ════════════════════════════════════════════════════════════

  Widget _buildSectionHeader(
      BuildContext context, {
        required IconData icon,
        required String title,
      }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
      BuildContext context, {
        required String label,
        required String value,
        IconData? icon,
        Widget? trailing,
      }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing,
        ],
      ],
    );
  }

  Widget _buildEvidenceItem(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String value,
        required bool isPositive,
      }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPositive
            ? Colors.green.shade50
            : AppColors.primarySurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPositive
              ? Colors.green.shade200
              : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isPositive ? Colors.green.shade600 : AppColors.primaryLight,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isPositive ? Colors.green.shade800 : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          size: 16,
          color: Colors.amber.shade600,
        );
      }),
    );
  }

  // ════════════════════════════════════════════════════════════
  // Helper Methods
  // ════════════════════════════════════════════════════════════

  String _getConfirmationStatus() {
    switch (session.userConfirmationStatus) {
      case 'confirmed':
        return 'مؤكد';
      case 'rejected':
        return 'مرفوض';
      case 'pending':
        return 'معلق';
      default:
        return 'غير محدد';
    }
  }

  IconData _getConfirmationIcon() {
    switch (session.userConfirmationStatus) {
      case 'confirmed':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
        return Icons.access_time;
      default:
        return Icons.help;
    }
  }

  bool _isNighttime(DateTime time) {
    final hour = time.hour;
    return hour >= 21 || hour < 7;
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE، d MMMM yyyy', 'ar').format(date);
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeAgo(DateTime time, DateTime reference) {
    final diff = reference.difference(time);
    if (diff.inMinutes < 1) {
      return 'قبل لحظات';
    } else if (diff.inMinutes < 60) {
      return 'قبل ${diff.inMinutes} دقيقة';
    } else {
      return 'قبل ${diff.inHours} ساعة';
    }
  }
}