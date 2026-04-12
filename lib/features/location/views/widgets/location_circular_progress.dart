// lib/features/location/widgets/location_circular_progress.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../../shared/theme/app_colors.dart';

class LocationCircularProgress extends StatelessWidget {
  final int totalVisits;
  final int uniquePlaces;
  final int homeVisits;
  final int workVisits;
  final bool isTracking;
  final String currentLocation;
  final double size;

  const LocationCircularProgress({
    Key? key,
    required this.totalVisits,
    required this.uniquePlaces,
    required this.homeVisits,
    required this.workVisits,
    required this.isTracking,
    required this.currentLocation,
    this.size = 180,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer circle - Total visits
          _buildOuterCircle(),

          // Middle circle - Unique places
          _buildMiddleCircle(),

          // Inner background
          _buildInnerBackground(),

          // Center content
          _buildCenterContent(),

          // Tracking indicator
          if (isTracking)
            _buildTrackingIndicator(),

          // Home/Work indicators
          _buildTypeIndicators(),
        ],
      ),
    );
  }

  Widget _buildOuterCircle() {
    final maxVisits = math.max(totalVisits, 10);
    final progress = (totalVisits / maxVisits).clamp(0.0, 1.0);

    return CustomPaint(
      size: Size(size, size),
      painter: CircularProgressPainter(
        progress: progress,
        strokeWidth: 12,
        backgroundColor: AppColors.border,
        progressColor: AppColors.primary,
        startAngle: -90,
      ),
    );
  }

  Widget _buildMiddleCircle() {
    final maxPlaces = math.max(uniquePlaces, 5);
    final progress = (uniquePlaces / maxPlaces).clamp(0.0, 1.0);

    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: CustomPaint(
          painter: CircularProgressPainter(
            progress: progress,
            strokeWidth: 8,
            backgroundColor: Colors.transparent,
            progressColor: AppColors.secondary,
            startAngle: -90,
          ),
        ),
      ),
    );
  }

  Widget _buildInnerBackground() {
    return Container(
      width: size - 60,
      height: size - 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.backgroundLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Location icon
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getLocationColor(),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getLocationIcon(),
            color: Colors.white,
            size: 20,
          ),
        ),

        const SizedBox(height: 8),

        // Total visits
        Text(
          '$totalVisits',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            height: 1.0,
          ),
        ),

        // Label
        Text(
          'زيارة',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 4),

        // Unique places
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$uniquePlaces مكان',
            style: const TextStyle(
              fontSize: 9,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Current location if tracking
        if (isTracking && currentLocation != 'غير معروف') ...[
          const SizedBox(height: 6),
          Container(
            constraints: BoxConstraints(maxWidth: size - 80),
            child: Text(
              currentLocation,
              style: TextStyle(
                fontSize: 8,
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTrackingIndicator() {
    return Positioned(
      top: 15,
      right: 15,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withOpacity(0.3),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.location_searching,
            size: 10,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIndicators() {
    return Positioned(
      bottom: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (homeVisits > 0)
            _buildTypeIndicator(
              Icons.home,
              '$homeVisits',
              AppColors.info,
              'بيت',
            ),
          if (homeVisits > 0 && workVisits > 0)
            const SizedBox(width: 16),
          if (workVisits > 0)
            _buildTypeIndicator(
              Icons.work,
              '$workVisits',
              AppColors.warning,
              'عمل',
            ),
        ],
      ),
    );
  }

  Widget _buildTypeIndicator(IconData icon, String count, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            count,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Color _getLocationColor() {
    if (isTracking) return AppColors.success;
    if (totalVisits > 10) return AppColors.primary;
    return AppColors.textSecondary;
  }

  IconData _getLocationIcon() {
    if (isTracking) return Icons.my_location;
    if (totalVisits > 0) return Icons.location_on;
    return Icons.location_off;
  }
}

// Painter for circular progress
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;
  final double startAngle;

  CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
    this.startAngle = -90,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);

    // Background circle
    if (backgroundColor != Colors.transparent) {
      final backgroundPaint = Paint()
        ..color = backgroundColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawCircle(center, radius, backgroundPaint);
    }

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        _degreeToRadians(startAngle),
        _degreeToRadians(360 * progress.clamp(0.0, 1.0)),
        false,
        progressPaint,
      );
    }
  }

  double _degreeToRadians(double degree) {
    return degree * math.pi / 180;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}