// lib/features/sleep/screens/sleep_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/sleep_tracking_provider.dart';
import '../../../shared/theme/app_colors.dart';

class SleepSettingsScreen extends StatefulWidget {
  const SleepSettingsScreen({super.key});

  @override
  State<SleepSettingsScreen> createState() => _SleepSettingsScreenState();
}

class _SleepSettingsScreenState extends State<SleepSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('إعدادات النوم'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<SleepTrackingProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Status Card
              _buildStatusCard(provider),

              const SizedBox(height: 16),

              // Sleep Window Settings
              _buildSleepWindowSection(context, provider),

              const SizedBox(height: 16),

              // Goals Settings
              _buildGoalsSection(context, provider),

              const SizedBox(height: 16),

              // Advanced Settings
              _buildAdvancedSection(context, provider),

              const SizedBox(height: 100),
            ],
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // Status Card
  // ════════════════════════════════════════════════════════════

  Widget _buildStatusCard(SleepTrackingProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.green.shade50,
              Colors.teal.shade50,
            ],
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green.shade600,
            ),
            const SizedBox(height: 16),
            const Text(
              'التتبع التلقائي نشط',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'يعمل 24/7 بدون توقف',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: AppColors.info),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'النظام يعمل تلقائياً ولا يحتاج لتفعيل يدوي',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // Sleep Window Section
  // ════════════════════════════════════════════════════════════

  Widget _buildSleepWindowSection(
      BuildContext context,
      SleepTrackingProvider provider,
      ) {
    final startTime = provider.state.sleepWindowStart;
    final endTime = provider.state.sleepWindowEnd;
    final adaptive = provider.state.adaptiveWindowEnabled;

    return _buildSettingsSection(
      context,
      title: 'نافذة النوم',
      icon: Icons.access_time,
      description: 'الفترة الزمنية المتوقعة للنوم الليلي',
      children: [
        _buildSettingsTile(
          context,
          title: 'وقت البداية',
          subtitle: _formatTimeOfDay(startTime),
          icon: Icons.bedtime,
          iconColor: AppColors.primary,
          onTap: () => _selectTime(
            context,
            isStart: true,
            currentTime: startTime,
            onTimeSelected: (time) async {
              await provider.updateSleepWindow(
                startTime: time,
                endTime: endTime,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تحديث وقت البداية')),
                );
              }
            },
          ),
        ),
        const Divider(height: 1),
        _buildSettingsTile(
          context,
          title: 'وقت النهاية',
          subtitle: _formatTimeOfDay(endTime),
          icon: Icons.wb_sunny,
          iconColor: Colors.orange,
          onTap: () => _selectTime(
            context,
            isStart: false,
            currentTime: endTime,
            onTimeSelected: (time) async {
              await provider.updateSleepWindow(
                startTime: startTime,
                endTime: time,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تحديث وقت النهاية')),
                );
              }
            },
          ),
        ),
        const Divider(height: 1),
        SwitchListTile(
          secondary: Icon(Icons.auto_awesome, color: AppColors.primary),
          title: const Text('النافذة التكيفية'),
          subtitle: const Text('تعديل النافذة تلقائياً حسب نمط نومك'),
          value: adaptive,
          activeColor: AppColors.primary,
          onChanged: (value) async {
            await provider.updateSleepWindow(
              startTime: startTime,
              endTime: endTime,
              adaptiveEnabled: value,
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value ? 'تم تفعيل النافذة التكيفية' : 'تم إلغاء النافذة التكيفية',
                  ),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════
  // Goals Section
  // ════════════════════════════════════════════════════════════

  Widget _buildGoalsSection(
      BuildContext context,
      SleepTrackingProvider provider,
      ) {
    final goalHours = provider.state.sleepGoalHours;

    return _buildSettingsSection(
      context,
      title: 'الأهداف',
      icon: Icons.flag,
      description: 'حدد أهدافك اليومية للنوم',
      children: [
        _buildSettingsTile(
          context,
          title: 'هدف النوم اليومي',
          subtitle: '$goalHours ساعات',
          icon: Icons.schedule,
          iconColor: Colors.blue,
          onTap: () => _selectGoal(
            context,
            currentGoal: goalHours,
            onGoalSelected: (hours) async {
              await provider.setSleepGoal(hours);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم تحديث الهدف إلى $hours ساعات')),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════
  // Advanced Section
  // ════════════════════════════════════════════════════════════

  Widget _buildAdvancedSection(
      BuildContext context,
      SleepTrackingProvider provider,
      ) {
    return _buildSettingsSection(
      context,
      title: 'متقدم',
      icon: Icons.settings_suggest,
      description: 'إعدادات متقدمة للنظام',
      children: [
        _buildSettingsTile(
          context,
          title: 'حالة النظام',
          subtitle: 'عرض معلومات تقنية',
          icon: Icons.info,
          onTap: () => _showSystemStatus(context, provider),
        ),
        const Divider(height: 1),
        _buildSettingsTile(
          context,
          title: 'تحديث البيانات',
          subtitle: 'تحديث فوري لجميع البيانات',
          icon: Icons.refresh,
          onTap: () async {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('جاري التحديث...')),
            );
            await provider.refreshData();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم التحديث بنجاح')),
              );
            }
          },
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════
  // Helper Widgets
  // ════════════════════════════════════════════════════════════

  Widget _buildSettingsSection(
      BuildContext context, {
        required String title,
        required IconData icon,
        required String description,
        required List<Widget> children,
      }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        Color? iconColor,
        Widget? trailing,
        VoidCallback? onTap,
      }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.primary),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppColors.textSecondary),
      ),
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }

  // ════════════════════════════════════════════════════════════
  // Dialogs
  // ════════════════════════════════════════════════════════════

  void _selectTime(
      BuildContext context, {
        required bool isStart,
        required TimeOfDay currentTime,
        required Function(TimeOfDay) onTimeSelected,
      }) async {
    final time = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      onTimeSelected(time);
    }
  }

  void _selectGoal(
      BuildContext context, {
        required int currentGoal,
        required Function(int) onGoalSelected,
      }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('هدف النوم اليومي'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(9, (index) {
            final hours = index + 4; // 4-12 hours
            return RadioListTile<int>(
              title: Text('$hours ساعات'),
              value: hours,
              groupValue: currentGoal,
              activeColor: AppColors.primary,
              onChanged: (value) {
                if (value != null) {
                  onGoalSelected(value);
                  Navigator.pop(context);
                }
              },
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  void _showSystemStatus(BuildContext context, SleepTrackingProvider provider) {
    final status = provider.getSystemStatus();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حالة النظام'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusRow('التتبع التلقائي', status['sleep']['auto_tracking_active'] ? 'نشط' : 'متوقف'),
              _buildStatusRow('حالة النوم', status['sleep']['current_sleep_state']),
              _buildStatusRow('ثقة الكشف', '${(status['sleep']['detection_confidence'] * 100).toStringAsFixed(0)}%'),
              _buildStatusRow('في النافذة الزمنية', status['sleep']['in_sleep_window'] ? 'نعم' : 'لا'),
              _buildStatusRow('جلسة نشطة', status['sleep']['has_active_session'] ? 'نعم' : 'لا'),
              _buildStatusRow('تأكيدات معلقة', '${status['sleep']['pending_confirmations']}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // Helper Methods
  // ════════════════════════════════════════════════════════════

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}