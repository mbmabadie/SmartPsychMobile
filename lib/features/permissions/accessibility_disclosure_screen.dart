// lib/features/permissions/accessibility_disclosure_screen.dart
// ✅ Prominent Disclosure لـ AccessibilityService - مطلوب من Google Play
// أضف هذا الملف وانتقل إليه قبل طلب Accessibility permission

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityDisclosureScreen extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const AccessibilityDisclosureScreen({
    Key? key,
    required this.onAccept,
    required this.onDecline,
  }) : super(key: key);

  static const String _disclosureShownKey = 'accessibility_disclosure_shown';

  /// استدعِ هذا قبل طلب Accessibility permission
  static Future<bool> shouldShowDisclosure() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_disclosureShownKey) ?? false);
  }

  static Future<void> markDisclosureShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_disclosureShownKey, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.accessibility_new,
                      color: Colors.orange,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'إذن إمكانية الوصول',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Main explanation
              const Text(
                'يستخدم تطبيق Smart Psych خدمة إمكانية الوصول (AccessibilityService) لتتبع أنماط استخدام هاتفك.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 24),

              // What we collect
              _buildSection(
                icon: Icons.check_circle,
                iconColor: Colors.green,
                title: 'ما نجمعه فقط:',
                items: [
                  'اسم التطبيق النشط حالياً',
                  'وقت استخدام كل تطبيق (بالدقائق)',
                  'عدد مرات فتح التطبيقات يومياً',
                  'أوقات الاستخدام الليلي (مؤشر للنوم)',
                ],
                color: Colors.green,
              ),

              const SizedBox(height: 16),

              // What we do NOT collect
              _buildSection(
                icon: Icons.cancel,
                iconColor: Colors.red,
                title: 'ما لا نجمعه أبداً:',
                items: [
                  'محتوى الرسائل أو المحادثات',
                  'كلمات المرور أو بيانات الدخول',
                  'الصور أو الملفات',
                  'أي معلومات داخل التطبيقات الأخرى',
                ],
                color: Colors.red,
              ),

              const SizedBox(height: 16),

              // Storage info
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock, color: Colors.blue, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'جميع البيانات تُحفظ محلياً على جهازك فقط — لا تُرسل إلى أي خادم خارجي.',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Policy link note
              const Text(
                'يمكنك إلغاء هذا الإذن في أي وقت من إعدادات الجهاز ← إمكانية الوصول.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await markDisclosureShown();
                    onAccept();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'فهمت — تفعيل الإذن',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () async {
                    await markDisclosureShown();
                    onDecline();
                  },
                  child: const Text(
                    'تخطي (دقة أقل في التتبع)',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<String> items,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ',
                    style: TextStyle(color: color.withOpacity(0.7))),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}