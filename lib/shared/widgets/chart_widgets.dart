// lib/shared/widgets/chart_widgets.dart
// هذا الملف يحتوي على widgets بديلة للرسوم البيانية في حالة عدم توفر fl_chart

import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Custom Line Chart Widget - بديل لـ fl_chart
class CustomLineChart extends StatefulWidget {
  final List<ChartDataPoint> data;
  final Color lineColor;
  final Color fillColor;
  final double strokeWidth;
  final bool showDots;
  final bool showFill;
  final bool animated;

  const CustomLineChart({
    super.key,
    required this.data,
    this.lineColor = Colors.blue,
    this.fillColor = Colors.blue,
    this.strokeWidth = 3.0,
    this.showDots = true,
    this.showFill = true,
    this.animated = true,
  });

  @override
  State<CustomLineChart> createState() => _CustomLineChartState();
}

class _CustomLineChartState extends State<CustomLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    if (widget.animated) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, double.infinity),
          painter: LineChartPainter(
            data: widget.data,
            lineColor: widget.lineColor,
            fillColor: widget.fillColor,
            strokeWidth: widget.strokeWidth,
            showDots: widget.showDots,
            showFill: widget.showFill,
            animationValue: widget.animated ? _animation.value : 1.0,
          ),
        );
      },
    );
  }
}

/// Custom Chart Data Point
class ChartDataPoint {
  final double x;
  final double y;
  final String? label;

  const ChartDataPoint({
    required this.x,
    required this.y,
    this.label,
  });
}

/// Line Chart Painter
class LineChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final Color lineColor;
  final Color fillColor;
  final double strokeWidth;
  final bool showDots;
  final bool showFill;
  final double animationValue;

  LineChartPainter({
    required this.data,
    required this.lineColor,
    required this.fillColor,
    required this.strokeWidth,
    required this.showDots,
    required this.showFill,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = fillColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    // Calculate bounds
    final minX = data.map((e) => e.x).reduce(math.min);
    final maxX = data.map((e) => e.x).reduce(math.max);
    final minY = data.map((e) => e.y).reduce(math.min);
    final maxY = data.map((e) => e.y).reduce(math.max);

    final padding = 20.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;

    // Convert data points to screen coordinates
    List<Offset> points = data.map((point) {
      final x = padding + (point.x - minX) / (maxX - minX) * chartWidth;
      final y = padding + (1 - (point.y - minY) / (maxY - minY)) * chartHeight;
      return Offset(x, y);
    }).toList();

    // Apply animation
    final animatedPointCount = (points.length * animationValue).round();
    final animatedPoints = points.take(animatedPointCount).toList();

    if (animatedPoints.length < 2) return;

    // Draw fill area
    if (showFill && animatedPoints.length > 1) {
      final fillPath = Path();
      fillPath.moveTo(animatedPoints.first.dx, size.height - padding);
      fillPath.lineTo(animatedPoints.first.dx, animatedPoints.first.dy);

      for (int i = 1; i < animatedPoints.length; i++) {
        fillPath.lineTo(animatedPoints[i].dx, animatedPoints[i].dy);
      }

      fillPath.lineTo(animatedPoints.last.dx, size.height - padding);
      fillPath.close();

      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw line
    final linePath = Path();
    linePath.moveTo(animatedPoints.first.dx, animatedPoints.first.dy);

    for (int i = 1; i < animatedPoints.length; i++) {
      linePath.lineTo(animatedPoints[i].dx, animatedPoints[i].dy);
    }

    canvas.drawPath(linePath, paint);

    // Draw dots
    if (showDots) {
      for (final point in animatedPoints) {
        canvas.drawCircle(point, 4, dotPaint);
        canvas.drawCircle(point, 4, Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

/// Simple Bar Chart Widget
class SimpleBarChart extends StatefulWidget {
  final List<BarData> data;
  final Color barColor;
  final bool animated;

  const SimpleBarChart({
    super.key,
    required this.data,
    this.barColor = Colors.blue,
    this.animated = true,
  });

  @override
  State<SimpleBarChart> createState() => _SimpleBarChartState();
}

class _SimpleBarChartState extends State<SimpleBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    if (widget.animated) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, double.infinity),
          painter: BarChartPainter(
            data: widget.data,
            barColor: widget.barColor,
            animationValue: widget.animated ? _animation.value : 1.0,
          ),
        );
      },
    );
  }
}

/// Bar Chart Data
class BarData {
  final String label;
  final double value;
  final Color? color;

  const BarData({
    required this.label,
    required this.value,
    this.color,
  });
}

/// Bar Chart Painter
class BarChartPainter extends CustomPainter {
  final List<BarData> data;
  final Color barColor;
  final double animationValue;

  BarChartPainter({
    required this.data,
    required this.barColor,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final padding = 20.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;
    final barWidth = chartWidth / data.length * 0.7;
    final spacing = chartWidth / data.length * 0.3;

    final maxValue = data.map((e) => e.value).reduce(math.max);

    for (int i = 0; i < data.length; i++) {
      final barData = data[i];
      final barHeight = (barData.value / maxValue) * chartHeight * animationValue;

      final barRect = Rect.fromLTWH(
        padding + i * (barWidth + spacing),
        size.height - padding - barHeight,
        barWidth,
        barHeight,
      );

      final paint = Paint()
        ..color = barData.color ?? barColor
        ..style = PaintingStyle.fill;

      final borderRadius = BorderRadius.circular(4);
      final rrect = RRect.fromRectAndCorners(
        barRect,
        topLeft: borderRadius.topLeft,
        topRight: borderRadius.topRight,
      );

      canvas.drawRRect(rrect, paint);

      // Draw label
      final textSpan = TextSpan(
        text: barData.label,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          barRect.left + (barRect.width - textPainter.width) / 2,
          size.height - padding + 5,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

/// Circular Progress Chart
class CircularProgressChart extends StatefulWidget {
  final double percentage;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;
  final bool animated;
  final Widget? centerWidget;

  const CircularProgressChart({
    super.key,
    required this.percentage,
    this.color = Colors.blue,
    this.backgroundColor = Colors.grey,
    this.strokeWidth = 8.0,
    this.animated = true,
    this.centerWidget,
  });

  @override
  State<CircularProgressChart> createState() => _CircularProgressChartState();
}

class _CircularProgressChartState extends State<CircularProgressChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    if (widget.animated) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(120, 120),
              painter: CircularProgressPainter(
                percentage: widget.percentage,
                color: widget.color,
                backgroundColor: widget.backgroundColor,
                strokeWidth: widget.strokeWidth,
                animationValue: widget.animated ? _animation.value : 1.0,
              ),
            ),
            if (widget.centerWidget != null) widget.centerWidget!,
          ],
        );
      },
    );
  }
}

/// Circular Progress Painter
class CircularProgressPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;
  final double animationValue;

  CircularProgressPainter({
    required this.percentage,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor.withOpacity(0.3)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (percentage / 100) * 2 * math.pi * animationValue;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

/// Chart Container Widget
class ChartContainer extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? subtitle;
  final bool isTablet;
  final Color? backgroundColor;
  final List<BoxShadow>? shadows;

  const ChartContainer({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.isTablet = false,
    this.backgroundColor,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
        boxShadow: shadows ?? [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null || subtitle != null) ...[
            if (title != null)
              Text(
                title!,
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            if (subtitle != null) ...[
              SizedBox(height: isTablet ? 4 : 2),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: isTablet ? 14 : 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
            SizedBox(height: isTablet ? 20 : 16),
          ],
          child,
        ],
      ),
    );
  }
}

/// Statistics Card Widget
class StatisticsCard extends StatefulWidget {
  final String title;
  final String value;
  final String? unit;
  final IconData icon;
  final Color color;
  final String? trend;
  final bool isTablet;
  final VoidCallback? onTap;

  const StatisticsCard({
    super.key,
    required this.title,
    required this.value,
    this.unit,
    required this.icon,
    required this.color,
    this.trend,
    this.isTablet = false,
    this.onTap,
  });

  @override
  State<StatisticsCard> createState() => _StatisticsCardState();
}

class _StatisticsCardState extends State<StatisticsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: EdgeInsets.all(widget.isTablet ? 20 : 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.color.withOpacity(0.1),
                    widget.color.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(widget.isTablet ? 20 : 16),
                border: Border.all(
                  color: widget.color.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: widget.isTablet ? 14 : 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(widget.isTablet ? 8 : 6),
                        decoration: BoxDecoration(
                          color: widget.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(widget.isTablet ? 10 : 8),
                        ),
                        child: Icon(
                          widget.icon,
                          size: widget.isTablet ? 20 : 16,
                          color: widget.color,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: widget.isTablet ? 12 : 8),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: widget.value,
                          style: TextStyle(
                            fontSize: widget.isTablet ? 24 : 20,
                            fontWeight: FontWeight.bold,
                            color: widget.color,
                            fontFamily: Theme.of(context).textTheme.headlineSmall?.fontFamily,
                          ),
                        ),
                        if (widget.unit != null)
                          TextSpan(
                            text: ' ${widget.unit!}',
                            style: TextStyle(
                              fontSize: widget.isTablet ? 14 : 12,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (widget.trend != null) ...[
                    SizedBox(height: widget.isTablet ? 8 : 4),
                    Row(
                      children: [
                        Icon(
                          widget.trend!.startsWith('+')
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          size: widget.isTablet ? 16 : 14,
                          color: widget.trend!.startsWith('+')
                              ? Colors.green
                              : Colors.red,
                        ),
                        SizedBox(width: widget.isTablet ? 4 : 2),
                        Text(
                          widget.trend!,
                          style: TextStyle(
                            fontSize: widget.isTablet ? 12 : 10,
                            fontWeight: FontWeight.w600,
                            color: widget.trend!.startsWith('+')
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Chart Legend Widget
class ChartLegend extends StatelessWidget {
  final List<LegendItem> items;
  final bool isTablet;
  final Axis direction;

  const ChartLegend({
    super.key,
    required this.items,
    this.isTablet = false,
    this.direction = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    final children = items.map((item) =>
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 8 : 6,
            vertical: isTablet ? 4 : 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isTablet ? 16 : 12,
                height: isTablet ? 16 : 12,
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
                ),
              ),
              SizedBox(width: isTablet ? 8 : 6),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: isTablet ? 14 : 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
    ).toList();

    return direction == Axis.horizontal
        ? Wrap(
      alignment: WrapAlignment.center,
      children: children,
    )
        : Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

/// Legend Item Data
class LegendItem {
  final String label;
  final Color color;

  const LegendItem({
    required this.label,
    required this.color,
  });
}