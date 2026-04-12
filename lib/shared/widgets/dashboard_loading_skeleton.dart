// lib/shared/widgets/dashboard_loading_skeleton.dart
import 'package:flutter/material.dart';

/// Skeleton لتحميل الداشبورد
class DashboardLoadingSkeleton extends StatefulWidget {
  final bool isTablet;

  const DashboardLoadingSkeleton({
    super.key,
    required this.isTablet,
  });

  @override
  State<DashboardLoadingSkeleton> createState() => _DashboardLoadingSkeletonState();
}

class _DashboardLoadingSkeletonState extends State<DashboardLoadingSkeleton>
    with SingleTickerProviderStateMixin {

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(widget.isTablet ? 24 : 16),
      child: Column(
        children: [
          // Summary Card Skeleton
          _buildSkeletonCard(height: widget.isTablet ? 120 : 100),

          SizedBox(height: widget.isTablet ? 20 : 16),

          // Stats Grid Skeleton
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.isTablet ? 4 : 2,
              mainAxisSpacing: widget.isTablet ? 16 : 12,
              crossAxisSpacing: widget.isTablet ? 16 : 12,
              childAspectRatio: widget.isTablet ? 1.2 : 1.1,
            ),
            itemCount: widget.isTablet ? 4 : 4,
            itemBuilder: (context, index) {
              return _buildSkeletonCard(height: null);
            },
          ),

          SizedBox(height: widget.isTablet ? 20 : 16),

          // Chart Card Skeleton
          _buildSkeletonCard(height: widget.isTablet ? 300 : 250),

          SizedBox(height: widget.isTablet ? 20 : 16),

          // Insights Skeleton
          _buildSkeletonCard(height: widget.isTablet ? 140 : 120),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard({double? height}) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(widget.isTablet ? 24 : 20),
            ),
            child: height != null ? _buildSkeletonContent() : _buildSmallSkeletonContent(),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonContent() {
    return Padding(
      padding: EdgeInsets.all(widget.isTablet ? 20 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity * 0.6,
            height: widget.isTablet ? 20 : 16,
            color: Colors.grey[400],
          ),
          SizedBox(height: widget.isTablet ? 12 : 8),
          Container(
            width: double.infinity * 0.4,
            height: widget.isTablet ? 16 : 12,
            color: Colors.grey[400],
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            height: widget.isTablet ? 60 : 50,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallSkeletonContent() {
    return Padding(
      padding: EdgeInsets.all(widget.isTablet ? 16 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: widget.isTablet ? 40 : 32,
                height: widget.isTablet ? 40 : 32,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  shape: BoxShape.circle,
                ),
              ),
              const Spacer(),
              Container(
                width: widget.isTablet ? 20 : 16,
                height: widget.isTablet ? 20 : 16,
                color: Colors.grey[400],
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: double.infinity * 0.7,
            height: widget.isTablet ? 24 : 20,
            color: Colors.grey[400],
          ),
          SizedBox(height: widget.isTablet ? 8 : 6),
          Container(
            width: double.infinity * 0.5,
            height: widget.isTablet ? 16 : 12,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }
}
