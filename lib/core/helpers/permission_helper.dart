// lib/core/helpers/permission_helper.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:app_settings/app_settings.dart';

class PermissionHelper {
  /// Check if usage stats permission is granted
  static Future<bool> hasUsageStatsPermission() async {
    try {
      debugPrint('🔍 فحص صلاحيات Usage Stats...');

      if (!Platform.isAndroid) {
        debugPrint('⚠️ iOS لا يحتاج صلاحيات Usage Stats خاصة');
        return true; // iOS doesn't need explicit usage stats permission
      }

      // للأندرويد - فحص مباشر
      final hasPermission = await UsageStats.checkUsagePermission();
      debugPrint('📱 حالة صلاحية Usage Stats: $hasPermission');

      return hasPermission ?? false;

    } catch (e) {
      debugPrint('❌ خطأ في فحص إذن إحصائيات الاستخدام: $e');

      // محاولة فحص بديلة عبر محاولة جلب البيانات
      try {
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));

        final stats = await UsageStats.queryUsageStats(yesterday, now);
        final hasData = stats.isNotEmpty;

        debugPrint('🔄 فحص بديل عبر جلب البيانات: $hasData');
        return hasData;

      } catch (e2) {
        debugPrint('❌ فشل الفحص البديل أيضاً: $e2');
        return false;
      }
    }
  }

  /// Request usage stats permission by opening settings
  static Future<bool> requestUsageStatsPermission() async {
    try {
      debugPrint('📱 طلب صلاحيات Usage Stats...');

      if (!Platform.isAndroid) {
        debugPrint('✅ iOS لا يحتاج طلب صلاحيات');
        return true;
      }

      // الطريقة الأولى: استخدام usage_stats package
      try {
        await UsageStats.grantUsagePermission();
        debugPrint('✅ تم فتح إعدادات Usage Stats عبر Package');

        // انتظار قليل للمستخدم
        await Future.delayed(const Duration(seconds: 1));

        return await hasUsageStatsPermission();

      } catch (e) {
        debugPrint('⚠️ فشل usage_stats package: $e');
      }

      // الطريقة الثانية: فتح الإعدادات العامة
      try {
        await AppSettings.openAppSettings(type: AppSettingsType.settings);
        debugPrint('✅ تم فتح إعدادات التطبيق العامة');

        await Future.delayed(const Duration(seconds: 1));
        return await hasUsageStatsPermission();

      } catch (e) {
        debugPrint('⚠️ فشل في فتح إعدادات التطبيق: $e');
      }

      // الطريقة الثالثة: محاولة فتح Usage Access مباشرة
      try {
        const platform = MethodChannel('usage_access_channel');
        await platform.invokeMethod('openUsageAccessSettings');
        debugPrint('✅ تم فتح Usage Access عبر Native Channel');

        await Future.delayed(const Duration(seconds: 1));
        return await hasUsageStatsPermission();

      } catch (e) {
        debugPrint('⚠️ فشل Native Channel: $e');
      }

      debugPrint('❌ فشلت جميع طرق فتح الإعدادات');
      return false;

    } catch (e) {
      debugPrint('❌ خطأ في طلب إذن إحصائيات الاستخدام: $e');
      return false;
    }
  }

  /// Show permission explanation dialog
  static Future<bool?> showPermissionDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.security,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'إذن الوصول للبيانات',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'للحصول على بيانات دقيقة حول استخدام الهاتف، نحتاج إلى إذن الوصول لإحصائيات الاستخدام.',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              SizedBox(height: 16),
              Text(
                'هذا الإذن آمن ولا يسمح بالوصول إلى:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '• محتوى التطبيقات أو الرسائل\n'
                    '• الصور أو الملفات الشخصية\n'
                    '• كلمات المرور أو البيانات الحساسة',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              SizedBox(height: 16),
              Text(
                'فقط إحصائيات الاستخدام مثل المدة الزمنية لكل تطبيق.',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'ليس الآن',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'منح الإذن',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show detailed instructions dialog
  static Future<void> showPermissionInstructionsDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                'خطوات منح الإذن',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'لمنح إذن الوصول لإحصائيات الاستخدام:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

                // خطوات مفصلة
                _buildInstructionStep(
                  '1',
                  'افتح الإعدادات',
                  'Settings > Apps > Special access',
                ),
                _buildInstructionStep(
                  '2',
                  'ابحث عن "Usage access"',
                  'أو "Device usage data" حسب نوع الجهاز',
                ),
                _buildInstructionStep(
                  '3',
                  'اختر تطبيقك',
                  'Smart Psych من القائمة',
                ),
                _buildInstructionStep(
                  '4',
                  'فعّل الإذن',
                  'اضغط على المفتاح لتفعيله',
                ),

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'بعد التفعيل، ارجع للتطبيق وسيبدأ جمع البيانات تلقائياً',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('فهمت'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await requestUsageStatsPermission();
              },
              child: const Text('فتح الإعدادات'),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildInstructionStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Check permission and handle UI flow
  static Future<bool> handlePermissionFlow(BuildContext context) async {
    debugPrint('🔄 بدء معالجة صلاحيات Usage Stats...');

    // Check if permission is already granted
    final hasPermission = await hasUsageStatsPermission();
    if (hasPermission) {
      debugPrint('✅ الصلاحيات ممنوحة بالفعل');
      return true;
    }

    // Show explanation dialog
    final shouldRequest = await showPermissionDialog(context);
    if (shouldRequest != true) {
      debugPrint('❌ المستخدم رفض منح الصلاحيات');
      return false;
    }

    // Show instructions first
    await showPermissionInstructionsDialog(context);

    // Request permission
    final granted = await requestUsageStatsPermission();

    if (granted) {
      debugPrint('🎉 تم منح الصلاحيات بنجاح!');
      return true;
    } else {
      debugPrint('❌ لم يتم منح الصلاحيات');

      // Show retry option
      final retry = await _showRetryDialog(context);
      if (retry == true) {
        return await handlePermissionFlow(context);
      }

      return false;
    }
  }

  static Future<bool?> _showRetryDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('لم يتم منح الإذن'),
        content: const Text(
            'يبدو أن الإذن لم يتم منحه بعد. هل تريد المحاولة مرة أخرى؟'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لاحقاً'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  /// Periodic permission check
  static Future<void> startPeriodicPermissionCheck({
    required VoidCallback onPermissionGranted,
    required VoidCallback onPermissionLost,
    Duration interval = const Duration(minutes: 1),
  }) async {
    bool lastPermissionState = await hasUsageStatsPermission();

    Timer.periodic(interval, (timer) async {
      try {
        final currentPermissionState = await hasUsageStatsPermission();

        if (currentPermissionState != lastPermissionState) {
          debugPrint('🔄 تغيرت حالة الصلاحيات: $currentPermissionState');

          if (currentPermissionState) {
            onPermissionGranted();
          } else {
            onPermissionLost();
          }
          lastPermissionState = currentPermissionState;
        }
      } catch (e) {
        debugPrint('❌ خطأ في فحص الأذونات الدوري: $e');
      }
    });
  }

  /// Get device and app info for better permission handling
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        return {
          'platform': 'Android',
          'brand': androidInfo.brand,
          'model': androidInfo.model,
          'version': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
          'manufacturer': androidInfo.manufacturer,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        return {
          'platform': 'iOS',
          'model': iosInfo.model,
          'version': iosInfo.systemVersion,
          'name': iosInfo.name,
        };
      }
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على معلومات الجهاز: $e');
    }

    return {'platform': 'Unknown'};
  }

  /// Advanced permission check with device-specific handling
  static Future<bool> checkUsagePermissionAdvanced() async {
    try {
      final deviceInfo = await getDeviceInfo();
      debugPrint('📱 معلومات الجهاز: $deviceInfo');

      final hasPermission = await hasUsageStatsPermission();

      if (!hasPermission && deviceInfo['platform'] == 'Android') {
        debugPrint('⚠️ نصائح خاصة بـ ${deviceInfo['brand']}:');

        switch (deviceInfo['brand']?.toLowerCase()) {
          case 'samsung':
            debugPrint('🔧 Samsung: تأكد من إيقاف "Device Care" optimization');
            break;
          case 'xiaomi':
            debugPrint('🔧 Xiaomi: فعّل "Autostart" و "Background app refresh"');
            break;
          case 'huawei':
            debugPrint('🔧 Huawei: اذهب إلى "Phone Manager" > "Protected apps"');
            break;
          case 'oppo':
          case 'oneplus':
            debugPrint('🔧 OPPO/OnePlus: فعّل "Allow background activity"');
            break;
        }
      }

      return hasPermission;
    } catch (e) {
      debugPrint('❌ خطأ في الفحص المتقدم: $e');
      return await hasUsageStatsPermission();
    }
  }
}

// Helper widget for permission UI
class PermissionRequiredWidget extends StatelessWidget {
  final VoidCallback? onRequestPermission;
  final String? customMessage;

  const PermissionRequiredWidget({
    super.key,
    this.onRequestPermission,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security,
              size: 80,
              color: Theme.of(context).primaryColor.withOpacity(0.6),
            ),
            const SizedBox(height: 24),
            Text(
              'إذن مطلوب',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              customMessage ??
                  'نحتاج إلى إذن الوصول لإحصائيات الاستخدام لتتبع استخدامك للهاتف وتقديم رؤى مفيدة.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRequestPermission ?? () async {
                await PermissionHelper.handlePermissionFlow(context);
              },
              icon: const Icon(Icons.security),
              label: const Text('منح الإذن'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                final deviceInfo = await PermissionHelper.getDeviceInfo();
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('معلومات الجهاز'),
                      content: Text(deviceInfo.toString()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('إغلاق'),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: const Text(
                'معلومات الجهاز',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}