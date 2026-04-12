// lib/shared/widgets/unified_app_bar.dart
import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';

class UnifiedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? greeting;
  final String? subtitle;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onChatTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onLocationTap;
  final bool showBackButton;
  final String? title;
  final bool hasNotificationBadge;
  final Widget? customLeading;

  const UnifiedAppBar({
    Key? key,
    this.greeting,
    this.subtitle,
    this.onNotificationTap,
    this.onChatTap,
    this.onProfileTap,
    this.onLocationTap,
    this.showBackButton = false,
    this.title,
    this.hasNotificationBadge = true,
    this.customLeading,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(180);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 768;

    return Container(
      height: preferredSize.height,
      child: Stack(
        children: [
          // خلفية بسيطة مع المنحني الجمالي
          CustomPaint(
            painter: SimpleAppBarPainter(),
            size: Size(screenWidth, preferredSize.height),
          ),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 20 : 16,
                vertical: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // النص - واضح ومرئي
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // النص الرئيسي
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 20 : 16,
                            vertical: isTablet ? 12 : 10,
                          ),
                         /* decoration: BoxDecoration(
                            color: const Color(0xFFDDF0F8).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.6),
                              width: 1.5,
                            ),
                          ),*/
                          child: Text(
                            title ?? greeting ?? 'مرحبا بك',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 22 : 20,
                              fontWeight: FontWeight.w800,
                              /*shadows: [
                                Shadow(
                                  color: const Color(0xFF1197CC).withOpacity(0.3),
                                  offset: const Offset(0, 1),
                                  blurRadius: 3,
                                ),
                              ],*/
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        // النص الفرعي
                       /* if (subtitle != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 16 : 12,
                              vertical: isTablet ? 8 : 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDDF0F8).withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              subtitle!,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: isTablet ? 16 : 14,
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(
                                    color: const Color(0xFF1197CC).withOpacity(0.2),
                                    offset: const Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],*/
                      ],
                    ),
                  ),

                  const SizedBox(width: 20),

                  // الأزرار - كبيرة وتفاعلية
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // زر الإشعارات
                   /*   Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            debugPrint('🔔 Notification button pressed');
                            onNotificationTap?.call();
                          },
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            width: isTablet ? 50 : 46,
                            height: isTablet ? 50 : 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDDF0F8).withOpacity(0.8),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.7),
                                width: 2,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Icon(
                                    Icons.notifications,
                                    size: isTablet ? 20 : 18,
                                    color: Colors.white,
                                  ),
                                ),
                                if (hasNotificationBadge)
                                  Positioned(
                                    right: 10,
                                    top: 10,
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF28A1D1),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.primary,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
*/
                    /*  const SizedBox(width: 16),

                      // زر الدردشة
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            debugPrint('💬 Chat button pressed');
                            onChatTap?.call();
                          },
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            width: isTablet ? 56 : 50,
                            height: isTablet ? 56 : 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF56B5DB),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.5,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.chat_bubble,
                                size: isTablet ? 22 : 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),*/

                      const SizedBox(width: 16),

                      // زر الملف الشخصي
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            debugPrint('👤 Profile button pressed');
                            if (onProfileTap != null) {
                              onProfileTap!.call();
                            } else {
                              // الانتقال الافتراضي لشاشة الإعدادات
                              Navigator.of(context).pushNamed('/settings');
                            }
                          },
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            width: isTablet ? 52 : 48,
                            height: isTablet ? 52 : 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF28A1D1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.person,
                                size: isTablet ? 20 : 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// رسام بسيط مع منحني جمالي
class SimpleAppBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // اللون الأساسي الجديد
    final paint = Paint()
      ..color = const Color(0xFF1197CC)
      ..style = PaintingStyle.fill;

    // رسم المنحني الجمالي
    final path = Path();

    // البداية من الأعلى اليسار
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);

    // المنحني الممتد أكثر للأسفل
    path.lineTo(size.width, size.height * 0.6);

    // منحني ناعم وجمالي ممتد للأسفل
    path.quadraticBezierTo(
      size.width * 0.75, // نقطة التحكم الأولى
      size.height * 1.1, // ممتد أكثر للأسفل
      size.width * 0.5, // النقطة الوسطى
      size.height * 0.9, // أعمق من قبل
    );

    path.quadraticBezierTo(
      size.width * 0.25, // نقطة التحكم الثانية
      size.height * 0.7, // أعمق من قبل
      0, // العودة للجانب الأيسر
      size.height * 0.6, // نفس النقطة
    );

    path.close();

    // رسم الشكل الأساسي
    canvas.drawPath(path, paint);

    // إضافة طبقة شفافة للعمق
    final overlayPaint = Paint()
      ..color = const Color(0xFFDDF0F8).withOpacity(0.1)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, overlayPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}