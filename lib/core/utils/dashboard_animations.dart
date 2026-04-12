

// lib/core/utils/dashboard_animations.dart
import 'package:flutter/material.dart';

/// مجموعة أنيميشن مخصصة للداشبورد
class DashboardAnimations {

  /// أنيميشن دخول البطاقات
  static Widget slideInCard({
    required Widget child,
    required int delay,
    Duration duration = const Duration(milliseconds: 600),
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: duration.inMilliseconds + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// أنيميشن نبضة للعناصر المهمة
  static Widget pulseWidget({
    required Widget child,
    Duration duration = const Duration(seconds: 2),
    double scale = 1.05,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 1.0, end: scale),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      onEnd: () {
        // Reverse animation
      },
      child: child,
    );
  }

  /// أنيميشن تموج للنقر
  static Widget rippleOnTap({
    required Widget child,
    required VoidCallback onTap,
    Color rippleColor = Colors.blue,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: rippleColor.withOpacity(0.3),
        highlightColor: rippleColor.withOpacity(0.1),
        child: child,
      ),
    );
  }

  /// أنيميشن شريط التقدم المتحرك
  static Widget animatedProgressBar({
    required double progress,
    Color backgroundColor = Colors.grey,
    Color progressColor = Colors.blue,
    double height = 6,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 0.0, end: progress),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: FractionallySizedBox(
            widthFactor: value,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: progressColor,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
        );
      },
    );
  }

  /// أنيميشن عد تصاعدي للأرقام
  static Widget countUpNumber({
    required int endValue,
    int startValue = 0,
    Duration duration = const Duration(milliseconds: 2000),
    TextStyle? style,
  }) {
    return TweenAnimationBuilder<int>(
      duration: duration,
      tween: IntTween(begin: startValue, end: endValue),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Text(
          value.toString(),
          style: style,
        );
      },
    );
  }
}