// lib/core/utils/permission_utils.dart - ✅ النسخة المُحسّنة

import 'package:android_intent_plus/android_intent.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/background_location_disclosure.dart';

class PermissionUtils {
  static bool _isRequestingPermissions = false;
  static DateTime? _lastRequestTime;
  static const Duration _requestCooldown = Duration(seconds: 30);

  static bool _usageAccessRequested = false;
  static const String _usageAccessKey = 'usage_access_requested';

  static bool _accessibilityRequested = false;
  static const String _accessibilityKey = 'accessibility_requested';

  static const String _locationDisclosureKey = 'location_disclosure_shown';

  // ✅ جديد - MIUI/EMUI/ColorOS detection
  static Future<bool> isMiuiDevice() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final manufacturer = androidInfo.manufacturer.toLowerCase();

      return manufacturer.contains('xiaomi') ||
          manufacturer.contains('redmi') ||
          manufacturer.contains('poco');
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isHuaweiDevice() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.manufacturer.toLowerCase().contains('huawei');
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isOppoDevice() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final manufacturer = androidInfo.manufacturer.toLowerCase();
      return manufacturer.contains('oppo') || manufacturer.contains('realme');
    } catch (e) {
      return false;
    }
  }

  /// ═══════════════════════════════════════════════════════════
  /// ✅ طلب جميع الصلاحيات الأساسية + الإضافية
  /// ═══════════════════════════════════════════════════════════
  static Future<Map<String, PermissionStatus>> requestAllEssentialPermissions(
      BuildContext context, {
        bool requestUsageAccess = false,
        bool requestAccessibility = false,
        bool showMiuiDialog = true, // ✅ جديد
      }) async {
    if (_isRequestingPermissions) return {};
    if (_lastRequestTime != null &&
        DateTime.now().difference(_lastRequestTime!) < _requestCooldown) {
      return {};
    }

    _isRequestingPermissions = true;
    _lastRequestTime = DateTime.now();
    Map<String, PermissionStatus> results = {};
    debugPrint('🔄 طلب الصلاحيات الأساسية');

    try {
      // 1️⃣ الإشعارات
      final notifStatus = await Permission.notification.request();
      results['notification'] = notifStatus;
      debugPrint('   📱 الإشعارات: ${notifStatus.isGranted ? "✅" : "❌"}');

      // 2️⃣ الحساسات
      final sensorsStatus = await Permission.sensors.request();
      results['sensors'] = sensorsStatus;
      debugPrint('   📊 الحساسات: ${sensorsStatus.isGranted ? "✅" : "❌"}');

      if (Platform.isAndroid) {
        // 3️⃣ النشاط
        final activityStatus = await Permission.activityRecognition.request();
        results['activity_recognition'] = activityStatus;
        debugPrint('   🏃 النشاط: ${activityStatus.isGranted ? "✅" : "❌"}');

        // 4️⃣ البطارية
        final batteryStatus = await Permission.ignoreBatteryOptimizations.request();
        results['battery_optimization'] = batteryStatus;
        debugPrint('   🔋 البطارية: ${batteryStatus.isGranted ? "✅" : "❌"}');

        // 5️⃣ المنبهات الدقيقة
        final alarmStatus = await Permission.scheduleExactAlarm.request();
        results['exact_alarm'] = alarmStatus;
        debugPrint('   ⏰ المنبهات: ${alarmStatus.isGranted ? "✅" : "❌"}');

        // ✅ 6️⃣ Display over other apps (جديد)
        final overlayStatus = await Permission.systemAlertWindow.request();
        results['system_alert_window'] = overlayStatus;
        debugPrint('   🪟 العرض فوق التطبيقات: ${overlayStatus.isGranted ? "✅" : "❌"}');

        // 7️⃣ الموقع — إفصاح مرة وحدة + whileInUse + always (Google Play policy)
        final locationGranted = await _requestLocationWithDisclosure(context);
        results['location'] = locationGranted
            ? PermissionStatus.granted
            : PermissionStatus.denied;

        // 8️⃣ Usage Access
        if (requestUsageAccess && !_usageAccessRequested) {
          final shouldRequest = await _shouldRequestUsageAccess();
          if (shouldRequest) {
            await _requestUsageAccess(context);
            await _markUsageAccessAsRequested();
          }
        }

        // 9️⃣ Accessibility
        if (requestAccessibility && !_accessibilityRequested) {
          final shouldRequest = await _shouldRequestAccessibility();
          if (shouldRequest) {
            await _requestAccessibility(context);
            await _markAccessibilityAsRequested();
          }
        }

        // ✅ 🔟 MIUI/EMUI/ColorOS Autostart Dialog
        if (showMiuiDialog) {
          await _showDeviceSpecificPermissionsDialog(context);
        }
      }

      return results;
    } finally {
      _isRequestingPermissions = false;
    }
  }


  /// ═══════════════════════════════════════════════════════════
  /// 📍 Location: إفصاح مرة وحدة ← whileInUse ← always
  /// ═══════════════════════════════════════════════════════════
  static Future<bool> _requestLocationWithDisclosure(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final disclosureShown = prefs.getBool(_locationDisclosureKey) ?? false;

    // ── خطوة 1: الإفصاح البارز (مرة وحدة بس) ────────────────
    if (!disclosureShown) {
      final accepted = await BackgroundLocationDisclosure.show(context);
      if (!accepted) {
        debugPrint('   📍 الموقع: المستخدم رفض الإفصاح');
        return false;
      }
      await prefs.setBool(_locationDisclosureKey, true);
    }

    // ── خطوة 2: whileInUse ───────────────────────────────────
    var locationStatus = await Permission.location.status;
    if (!locationStatus.isGranted) {
      locationStatus = await Permission.location.request();
    }

    if (!locationStatus.isGranted) {
      debugPrint('   📍 الموقع (whileInUse): ❌');
      return false;
    }
    debugPrint('   📍 الموقع (whileInUse): ✅');

    // ── خطوة 3: always (background) — dialog مختصر أولاً ─────
    var alwaysStatus = await Permission.locationAlways.status;
    if (!alwaysStatus.isGranted) {
      final wantsAlways = await _showAlwaysLocationDialog(context);
      if (wantsAlways) {
        alwaysStatus = await Permission.locationAlways.request();
        debugPrint('   📍 الموقع (always): ${alwaysStatus.isGranted ? "✅" : "❌"}');
      } else {
        debugPrint('   📍 الموقع (always): تجاوز من المستخدم');
      }
    }

    return true;
  }

  /// Dialog مختصر يشرح ليش بدنا "دائماً في الخلفية"
  static Future<bool> _showAlwaysLocationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final cs = theme.colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.location_on, color: cs.primary),
              const SizedBox(width: 8),
              const Expanded(child: Text('Allow in Background?')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To track your sleep location and daily movement patterns, '
                    'Smart Psych needs location access even when the app is closed.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'On the next screen, choose "Allow all the time".',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Skip'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  /// ═══════════════════════════════════════════════════════════
  /// ✅ MIUI/EMUI/ColorOS Permissions Dialog
  /// ═══════════════════════════════════════════════════════════
  static Future<void> _showDeviceSpecificPermissionsDialog(BuildContext context) async {
    final isMiui = await isMiuiDevice();
    final isHuawei = await isHuaweiDevice();
    final isOppo = await isOppoDevice();

    if (!isMiui && !isHuawei && !isOppo) {
      debugPrint('✅ جهاز عادي - لا حاجة لإعدادات إضافية');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getString('device_permissions_dialog_shown');

    if (lastShown != null) {
      final lastDate = DateTime.tryParse(lastShown);
      if (lastDate != null &&
          DateTime.now().difference(lastDate) < Duration(days: 7)) {
        debugPrint('ℹ️ تم عرض Dialog مؤخراً');
        return;
      }
    }

    String deviceName = 'جهازك';
    if (isMiui) deviceName = 'Xiaomi/Redmi';
    if (isHuawei) deviceName = 'Huawei';
    if (isOppo) deviceName = 'Oppo/Realme';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.security, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'إعدادات $deviceName الإضافية',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'جهاز $deviceName يحتاج إعدادات إضافية يدوية',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                Text(
                  '⚠️ بدون هذه الإعدادات:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 8),
                _buildWarningItem('الخطوات لن تُحسب في الخلفية'),
                _buildWarningItem('التتبع سيتوقف عند إغلاق التطبيق'),
                _buildWarningItem('لن تصلك إشعارات في الوقت المناسب'),

                SizedBox(height: 16),

                Text(
                  '✅ الإعدادات المطلوبة:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 8),

                if (isMiui) ..._buildMiuiSteps(),
                if (isHuawei) ..._buildHuaweiSteps(),
                if (isOppo) ..._buildOppoSteps(),

                SizedBox(height: 16),

                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ستُفتح الإعدادات - فعّل الخيارات المطلوبة',
                          style: TextStyle(fontSize: 12),
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
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('لاحقاً'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: Text('فتح الإعدادات'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      if (isMiui) await _openMiuiPermissions(context);
      if (isHuawei) await _openHuaweiPermissions(context);
      if (isOppo) await _openOppoPermissions(context);

      await prefs.setString(
        'device_permissions_dialog_shown',
        DateTime.now().toIso8601String(),
      );
    }
  }

  static Widget _buildWarningItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('  • ', style: TextStyle(color: Colors.red, fontSize: 13)),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  static List<Widget> _buildMiuiSteps() {
    return [
      _buildStep('1', 'Autostart → تفعيل'),
      _buildStep('2', 'Battery Saver → No restrictions'),
      _buildStep('3', 'Display pop-up window → تفعيل'),
    ];
  }

  static List<Widget> _buildHuaweiSteps() {
    return [
      _buildStep('1', 'Launch → تفعيل'),
      _buildStep('2', 'Power Intensive Prompt → تعطيل'),
      _buildStep('3', 'Keep running after screen off → تفعيل'),
    ];
  }

  static List<Widget> _buildOppoSteps() {
    return [
      _buildStep('1', 'Startup Manager → تفعيل'),
      _buildStep('2', 'Background Freeze → تعطيل'),
    ];
  }

  static Widget _buildStep(String number, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════
  /// فتح إعدادات الأجهزة المختلفة
  /// ═══════════════════════════════════════════════════════════

  static Future<void> _openMiuiPermissions(BuildContext context) async {
    try {
      debugPrint('🔄 فتح إعدادات MIUI...');

      // محاولة 1: فتح صفحة App Info مباشرة
      try {
        const AndroidIntent intent = AndroidIntent(
          action: 'miui.intent.action.APP_PERM_EDITOR',
          arguments: {
            'extra_pkgname': 'com.smart_psych.smart_psych',
          },
        );
        await intent.launch();
        debugPrint('✅ تم فتح MIUI App Permissions');
        return;
      } catch (e) {
        debugPrint('⚠️ فشل MIUI intent: $e');
      }

      // محاولة 2: فتح App Settings العادي
      await openAppSettings();
      debugPrint('✅ تم فتح App Settings');

    } catch (e) {
      debugPrint('❌ فشل فتح إعدادات MIUI: $e');
    }
  }

  static Future<void> _openHuaweiPermissions(BuildContext context) async {
    try {
      debugPrint('🔄 فتح إعدادات Huawei...');

      // Huawei uses standard app settings usually
      await openAppSettings();
      debugPrint('✅ تم فتح App Settings');

    } catch (e) {
      debugPrint('❌ فشل فتح إعدادات Huawei: $e');
    }
  }

  static Future<void> _openOppoPermissions(BuildContext context) async {
    try {
      debugPrint('🔄 فتح إعدادات Oppo...');

      // Oppo uses standard app settings
      await openAppSettings();
      debugPrint('✅ تم فتح App Settings');

    } catch (e) {
      debugPrint('❌ فشل فتح إعدادات Oppo: $e');
    }
  }

  /// ═══════════════════════════════════════════════════════════
  /// Usage Access (بدون تغيير)
  /// ═══════════════════════════════════════════════════════════

  static Future<bool> _shouldRequestUsageAccess() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRequestDate = prefs.getString(_usageAccessKey);
      if (lastRequestDate == null) return true;

      final lastRequest = DateTime.tryParse(lastRequestDate);
      if (lastRequest == null) return true;

      final weekAgo = DateTime.now().subtract(Duration(days: 7));
      return lastRequest.isBefore(weekAgo);
    } catch (e) {
      return false;
    }
  }

  static Future<void> _markUsageAccessAsRequested() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_usageAccessKey, DateTime.now().toIso8601String());
      _usageAccessRequested = true;
      debugPrint('✅ تم تسجيل طلب Usage Access');
    } catch (e) {
      debugPrint('❌ خطأ في تسجيل Usage Access: $e');
    }
  }

  static Future<void> _requestUsageAccess(BuildContext context) async {
    if (!Platform.isAndroid) return;

    try {
      debugPrint('🔄 محاولة فتح Usage Access Settings');
      const AndroidIntent intent = AndroidIntent(
        action: 'android.settings.USAGE_ACCESS_SETTINGS',
      );
      await intent.launch();
      debugPrint('✅ تم فتح Usage Access Settings بنجاح');
    } catch (e) {
      debugPrint('❌ فشل فتح Usage Access: $e');
      try {
        await openAppSettings();
        debugPrint('✅ تم فتح App Settings كحل بديل');
      } catch (e2) {
        debugPrint('❌ فشل في فتح App Settings أيضاً: $e2');
      }
    }
  }

  /// ═══════════════════════════════════════════════════════════
  /// Accessibility (بدون تغيير)
  /// ═══════════════════════════════════════════════════════════

  static Future<bool> _shouldRequestAccessibility() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRequestDate = prefs.getString(_accessibilityKey);
      if (lastRequestDate == null) return true;

      final lastRequest = DateTime.tryParse(lastRequestDate);
      if (lastRequest == null) return true;

      final weekAgo = DateTime.now().subtract(Duration(days: 7));
      return lastRequest.isBefore(weekAgo);
    } catch (e) {
      return false;
    }
  }

  static Future<void> _markAccessibilityAsRequested() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessibilityKey, DateTime.now().toIso8601String());
      _accessibilityRequested = true;
      debugPrint('✅ تم تسجيل طلب Accessibility');
    } catch (e) {
      debugPrint('❌ خطأ في تسجيل Accessibility: $e');
    }
  }

  static Future<void> _requestAccessibility(BuildContext context) async {
    if (!Platform.isAndroid) return;

    final confirmed = await _showAccessibilityDialog(context);
    if (confirmed != true) return;

    try {
      debugPrint('🔄 محاولة فتح Accessibility Settings');
      const AndroidIntent intent = AndroidIntent(
        action: 'android.settings.ACCESSIBILITY_SETTINGS',
      );
      await intent.launch();
      debugPrint('✅ تم فتح Accessibility Settings بنجاح');
    } catch (e) {
      debugPrint('❌ فشل فتح Accessibility: $e');
      try {
        await openAppSettings();
        debugPrint('✅ تم فتح App Settings كحل بديل');
      } catch (e2) {
        debugPrint('❌ فشل في فتح App Settings أيضاً: $e2');
      }
    }
  }

  static Future<bool?> _showAccessibilityDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.accessibility_new, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(child: Text('تتبع دقيق 100%')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'للحصول على تتبع دقيق 100%، يجب تفعيل خدمة إمكانية الوصول.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✅ ما سنجمعه:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.green.shade700,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text('• اسم التطبيق النشط فقط', style: TextStyle(fontSize: 13)),
                      Text('• وقت الاستخدام بالضبط', style: TextStyle(fontSize: 13)),
                      Text('• عدد مرات الفتح (دقيق 100%)', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '❌ ما لن نجمعه أبداً:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.red.shade700,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text('• محتوى الشاشة', style: TextStyle(fontSize: 13)),
                      Text('• كلمات المرور', style: TextStyle(fontSize: 13)),
                      Text('• الرسائل الخاصة', style: TextStyle(fontSize: 13)),
                      Text('• الصور أو الملفات', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('لا، شكراً'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: Text('فتح الإعدادات'),
            ),
          ],
        );
      },
    );
  }

  /// ═══════════════════════════════════════════════════════════
  /// فحص حالة جميع الصلاحيات
  /// ═══════════════════════════════════════════════════════════

  static Future<Map<String, bool>> checkAllPermissions() async {
    Map<String, bool> status = {};
    try {
      status['notifications'] = await Permission.notification.isGranted;
      status['sensors'] = await Permission.sensors.isGranted;

      if (Platform.isAndroid) {
        status['activity_recognition'] = await Permission.activityRecognition.isGranted;
        status['battery_optimization'] = await Permission.ignoreBatteryOptimizations.isGranted;
        status['exact_alarm'] = await Permission.scheduleExactAlarm.isGranted;
        status['system_alert_window'] = await Permission.systemAlertWindow.isGranted;
        status['location'] = await Permission.location.isGranted;
      }

      return status;
    } catch (e) {
      debugPrint('❌ خطأ في فحص الصلاحيات: $e');
      return {};
    }
  }

  /// ═══════════════════════════════════════════════════════════
  /// عرض حالة الصلاحيات
  /// ═══════════════════════════════════════════════════════════

  static Future<void> showPermissionsDialog(BuildContext context) async {
    final permissions = await checkAllPermissions();
    final isMiui = await isMiuiDevice();
    final isHuawei = await isHuaweiDevice();
    final isOppo = await isOppoDevice();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('🔍 حالة الصلاحيات'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الصلاحيات العادية
                  ...permissions.entries.map((entry) {
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        entry.value ? Icons.check_circle : Icons.cancel,
                        color: entry.value ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      title: Text(
                        getPermissionDisplayName(entry.key),
                        style: TextStyle(fontSize: 13),
                      ),
                      trailing: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (entry.value ? Colors.green : Colors.red)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          entry.value ? 'ممنوح' : 'مرفوض',
                          style: TextStyle(
                            fontSize: 10,
                            color: entry.value
                                ? Colors.green[700]
                                : Colors.red[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),

                  if (isMiui || isHuawei || isOppo) ...[
                    Divider(),
                    ListTile(
                      dense: true,
                      leading: Icon(Icons.security, color: Colors.orange),
                      title: Text(
                        'إعدادات ${isMiui ? "MIUI" : isHuawei ? "EMUI" : "ColorOS"}',
                        style: TextStyle(fontSize: 13),
                      ),
                      subtitle: Text('(إعدادات يدوية)', style: TextStyle(fontSize: 11)),
                      trailing: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showDeviceSpecificPermissionsDialog(context);
                        },
                        child: Text('فتح', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],

                  Divider(),

                  // Usage Access
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.apps, color: Colors.blue),
                    title: Text(
                      'الوصول لبيانات التطبيقات',
                      style: TextStyle(fontSize: 13),
                    ),
                    subtitle: Text('(اختياري)', style: TextStyle(fontSize: 11)),
                    trailing: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        requestUsageAccessManually(context);
                      },
                      child: Text('طلب', style: TextStyle(fontSize: 11)),
                    ),
                  ),

                  // Accessibility
                  if (Platform.isAndroid)
                    ListTile(
                      dense: true,
                      leading: Icon(Icons.accessibility_new, color: Colors.orange),
                      title: Text(
                        'التتبع الدقيق 100%',
                        style: TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        '(اختياري - دقة 99%)',
                        style: TextStyle(fontSize: 11),
                      ),
                      trailing: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          requestAccessibilityManually(context);
                        },
                        child: Text('طلب', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('إغلاق'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: Text('إعدادات التطبيق'),
            ),
          ],
        );
      },
    );
  }

  /// ═══════════════════════════════════════════════════════════
  /// طلب Usage Access يدوياً
  /// ═══════════════════════════════════════════════════════════

  static Future<void> requestUsageAccessManually(BuildContext context) async {
    final shouldRequest = await _shouldRequestUsageAccess();

    if (!shouldRequest) {
      _showUsageAccessAlreadyRequestedDialog(context);
      return;
    }

    final confirmed = await _showUsageAccessConfirmationDialog(context);
    if (confirmed == true) {
      await _requestUsageAccess(context);
      await _markUsageAccessAsRequested();
    }
  }

  static Future<bool?> _showUsageAccessConfirmationDialog(
      BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.apps, color: Colors.blue),
              SizedBox(width: 8),
              Expanded(child: Text('الوصول لبيانات التطبيقات')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'هل تريد فتح إعدادات الوصول لاستخدام التطبيقات؟',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 هذا الإذن يُستخدم لـ:',
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    SizedBox(height: 6),
                    Text('• مراقبة استخدام الهاتف',
                        style: TextStyle(fontSize: 13)),
                    Text('• تحليل أنماط النوم', style: TextStyle(fontSize: 13)),
                    Text('• إحصائيات التطبيقات',
                        style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Text(
                'يمكنك تخطي هذا الإذن والاستمرار في استخدام التطبيق.',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('تخطي'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('فتح الإعدادات'),
            ),
          ],
        );
      },
    );
  }

  static void _showUsageAccessAlreadyRequestedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info, color: Colors.blue),
              SizedBox(width: 8),
              Text('تم الطلب مسبقاً'),
            ],
          ),
          content: Text(
            'تم طلب إذن الوصول لبيانات التطبيقات مؤخراً. يمكنك الوصول للإعدادات يدوياً إذا أردت تغيير الإعدادات.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('حسناً'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: Text('فتح الإعدادات'),
            ),
          ],
        );
      },
    );
  }

  /// ═══════════════════════════════════════════════════════════
  /// طلب Accessibility يدوياً
  /// ═══════════════════════════════════════════════════════════

  static Future<void> requestAccessibilityManually(BuildContext context) async {
    if (!Platform.isAndroid) {
      _showIOSUnsupportedDialog(context);
      return;
    }

    final shouldRequest = await _shouldRequestAccessibility();

    if (!shouldRequest) {
      _showAccessibilityAlreadyRequestedDialog(context);
      return;
    }

    final confirmed = await _showAccessibilityDialog(context);
    if (confirmed == true) {
      await _requestAccessibility(context);
      await _markAccessibilityAsRequested();
    }
  }

  static void _showIOSUnsupportedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text('غير متاح في iOS'),
            ],
          ),
          content: Text(
            'نظام iOS لا يدعم التتبع الدقيق 100%.\n\n'
                'سيستخدم التطبيق التقديرات المتاحة (دقة 60-70%).\n\n'
                'هذا القيد موجود في جميع تطبيقات iOS.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('حسناً'),
            ),
          ],
        );
      },
    );
  }

  static void _showAccessibilityAlreadyRequestedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('تم الطلب مسبقاً'),
            ],
          ),
          content: Text(
            'تم طلب صلاحية التتبع الدقيق مؤخراً.\n\n'
                'يمكنك فتح الإعدادات يدوياً إذا أردت تغيير الإعدادات.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('حسناً'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  const AndroidIntent intent = AndroidIntent(
                    action: 'android.settings.ACCESSIBILITY_SETTINGS',
                  );
                  await intent.launch();
                } catch (e) {
                  await openAppSettings();
                }
              },
              child: Text('فتح الإعدادات'),
            ),
          ],
        );
      },
    );
  }

  /// ═══════════════════════════════════════════════════════════
  /// ترجمة أسماء الصلاحيات
  /// ═══════════════════════════════════════════════════════════

  static String getPermissionDisplayName(String key) {
    switch (key) {
      case 'notifications':
        return 'الإشعارات';
      case 'sensors':
        return 'الحساسات';
      case 'activity_recognition':
        return 'مراقبة النشاط';
      case 'battery_optimization':
        return 'تحسين البطارية';
      case 'exact_alarm':
        return 'المنبهات الدقيقة';
      case 'system_alert_window':
        return 'العرض فوق التطبيقات';
      case 'location':
        return 'الموقع';
      default:
        return key;
    }
  }

  /// ═══════════════════════════════════════════════════════════
  /// إعادة تعيين
  /// ═══════════════════════════════════════════════════════════

  static void resetRequestState() {
    _isRequestingPermissions = false;
    _lastRequestTime = null;
    debugPrint('🔄 تم إعادة تعيين حالة طلب الأذونات');
  }

  static Future<void> resetUsageAccessState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_usageAccessKey);
      _usageAccessRequested = false;
      debugPrint('🔄 تم إعادة تعيين حالة Usage Access');
    } catch (e) {
      debugPrint('❌ خطأ في إعادة تعيين Usage Access: $e');
    }
  }

  static Future<void> resetAccessibilityState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessibilityKey);
      _accessibilityRequested = false;
      debugPrint('🔄 تم إعادة تعيين حالة Accessibility');
    } catch (e) {
      debugPrint('❌ خطأ في إعادة تعيين Accessibility: $e');
    }
  }
}