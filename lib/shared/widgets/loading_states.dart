// lib/shared/widgets/loading_states.dart - إنشاء class جديد

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class LoadingStates {
  static Widget modernLoading({
    String? message,
    Color? color,
    double? size,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color ?? AppColors.primary,
                    (color ?? AppColors.primary).withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                Icons.sync,
                color: Colors.white,
                size: size ?? 48,
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation(color ?? AppColors.primary),
                backgroundColor: (color ?? AppColors.primary).withOpacity(0.2),
              ),
            ),

            if (message != null) ...[
              const SizedBox(height: 24),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget shimmerLoading({
    Widget? child,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1500),
      tween: Tween(begin: -1.0, end: 1.0),
      builder: (context, value, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(value - 1, 0),
              end: Alignment(value + 1, 0),
              colors: [
                baseColor ?? Colors.grey[300]!,
                highlightColor ?? Colors.grey[100]!,
                baseColor ?? Colors.grey[300]!,
              ],
            ),
          ),
          child: child,
        );
      },
    );
  }

  static Widget pulseLoading({
    Widget? child,
    Duration? duration,
    Color? color,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration ?? const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.5, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: value,
            child: Container(
              decoration: BoxDecoration(
                color: (color ?? AppColors.primary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}