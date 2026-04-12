// lib/core/database/models/nav_item_model.dart
import 'package:flutter/material.dart';

/// نموذج عنصر التنقل في الـ Bottom Navigation
@immutable
class NavItemModel {
  /// الأيقونة العادية
  final IconData icon;

  /// الأيقونة النشطة (عند التحديد)
  final IconData activeIcon;

  /// النص المعروض
  final String label;

  /// لون العنصر
  final Color color;

  /// شارة اختيارية (مثل عدد الإشعارات)
  final String? badge;

  /// دالة الضغط المطول (اختيارية)
  final VoidCallback? onLongPress;

  /// معرف فريد للعنصر (اختياري)
  final String? id;

  /// هل العنصر نشط أم لا
  final bool isEnabled;

  const NavItemModel({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
    this.badge,
    this.onLongPress,
    this.id,
    this.isEnabled = true,
  });

  /// إنشاء نسخة جديدة مع تعديل بعض القيم
  NavItemModel copyWith({
    IconData? icon,
    IconData? activeIcon,
    String? label,
    Color? color,
    String? badge,
    VoidCallback? onLongPress,
    String? id,
    bool? isEnabled,
  }) {
    return NavItemModel(
      icon: icon ?? this.icon,
      activeIcon: activeIcon ?? this.activeIcon,
      label: label ?? this.label,
      color: color ?? this.color,
      badge: badge ?? this.badge,
      onLongPress: onLongPress ?? this.onLongPress,
      id: id ?? this.id,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  /// إزالة الشارة
  NavItemModel removeBadge() {
    return copyWith(badge: null);
  }

  /// تحديث الشارة
  NavItemModel updateBadge(String? newBadge) {
    return copyWith(badge: newBadge);
  }

  /// تفعيل/إلغاء تفعيل العنصر
  NavItemModel toggleEnabled() {
    return copyWith(isEnabled: !isEnabled);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NavItemModel &&
        other.icon == icon &&
        other.activeIcon == activeIcon &&
        other.label == label &&
        other.color == color &&
        other.badge == badge &&
        other.id == id &&
        other.isEnabled == isEnabled;
  }

  @override
  int get hashCode {
    return Object.hash(
      icon,
      activeIcon,
      label,
      color,
      badge,
      id,
      isEnabled,
    );
  }

  @override
  String toString() {
    return 'NavItemModel('
        'icon: $icon, '
        'activeIcon: $activeIcon, '
        'label: $label, '
        'color: $color, '
        'badge: $badge, '
        'id: $id, '
        'isEnabled: $isEnabled'
        ')';
  }

  /// تحويل إلى Map للحفظ في قاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'icon': icon.codePoint,
      'activeIcon': activeIcon.codePoint,
      'label': label,
      'color': color.value,
      'badge': badge,
      'id': id,
      'isEnabled': isEnabled,
    };
  }

  /// إنشاء من Map
  factory NavItemModel.fromMap(Map<String, dynamic> map) {
    return NavItemModel(
      icon: IconData(map['icon'] as int, fontFamily: 'MaterialIcons'),
      activeIcon: IconData(map['activeIcon'] as int, fontFamily: 'MaterialIcons'),
      label: map['label'] as String,
      color: Color(map['color'] as int),
      badge: map['badge'] as String?,
      id: map['id'] as String?,
      isEnabled: map['isEnabled'] as bool? ?? true,
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() => toMap();

  /// إنشاء من JSON
  factory NavItemModel.fromJson(Map<String, dynamic> json) => NavItemModel.fromMap(json);
}

/// مجموعة من عناصر التنقل المحددة مسبقاً للاستخدام السريع
class PredefinedNavItems {
  static const home = NavItemModel(
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    label: 'الرئيسية',
    color: Color(0xFF229ECF), // AppColors.primary
    id: 'home',
  );

  static const phone = NavItemModel(
    icon: Icons.phone_android_outlined,
    activeIcon: Icons.phone_android_rounded,
    label: 'الهاتف',
    color: Color(0xFFFFC800), // AppColors.secondary
    id: 'phone',
  );

  static const sleep = NavItemModel(
    icon: Icons.bedtime_outlined,
    activeIcon: Icons.bedtime_rounded,
    label: 'النوم',
    color: Colors.purple,
    id: 'sleep',
  );

  static const activity = NavItemModel(
    icon: Icons.directions_run_outlined,
    activeIcon: Icons.directions_run_rounded,
    label: 'النشاط',
    color: Colors.green,
    id: 'activity',
  );

  static const nutrition = NavItemModel(
    icon: Icons.restaurant_outlined,
    activeIcon: Icons.restaurant_rounded,
    label: 'التغذية',
    color: Colors.orange,
    id: 'nutrition',
  );

  static const statistics = NavItemModel(
    icon: Icons.analytics_outlined,
    activeIcon: Icons.analytics_rounded,
    label: 'الإحصائيات',
    color: Color(0xFF011F37), // AppColors.accent
    id: 'statistics',
  );

  /// قائمة جميع العناصر الافتراضية للـ Dashboard مع 6 عناصر
  static List<NavItemModel> get defaultDashboardItems => [
    home,
    phone,
    sleep,
    activity,
    nutrition,
    statistics,
  ];

  /// قائمة مبسطة للشاشات الأساسية (4 عناصر)
  static List<NavItemModel> get basicItems => [
    home,
    phone,
    activity,
    statistics,
  ];

  /// قائمة للصحة العامة (5 عناصر)
  static List<NavItemModel> get healthItems => [
    home,
    sleep,
    activity,
    nutrition,
    statistics,
  ];
}