// lib/shared/widgets/loading_overlay.dart
import 'package:flutter/material.dart';

// Theme
import '../theme/app_colors.dart';

/// غلاف التحميل مع رسوم متحركة جميلة
class LoadingOverlay extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final String? loadingText;
  final Color? overlayColor;
  final Color? progressColor;
  final double overlayOpacity;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingText,
    this.overlayColor,
    this.progressColor,
    this.overlayOpacity = 0.7,
  });

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay>
    with TickerProviderStateMixin {

  late AnimationController _fadeController;
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Fade Animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Rotation Animation
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    // Pulse Animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start animations if loading
    if (widget.isLoading) {
      _startAnimations();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
  }

  /// بدء الرسوم المتحركة
  void _startAnimations() {
    _fadeController.forward();
    _rotationController.repeat();
    _pulseController.repeat(reverse: true);
  }

  /// إيقاف الرسوم المتحركة
  void _stopAnimations() {
    _fadeController.reverse();
    _rotationController.stop();
    _pulseController.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // المحتوى الأساسي
        widget.child,

        // غلاف التحميل
        if (widget.isLoading)
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: _buildLoadingOverlay(context),
              );
            },
          ),
      ],
    );
  }

  /// بناء غلاف التحميل
  Widget _buildLoadingOverlay(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: (widget.overlayColor ?? Colors.black).withOpacity(widget.overlayOpacity),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // مؤشر التحميل المتحرك
              _buildAnimatedProgress(),

              const SizedBox(height: 24),

              // نص التحميل
              if (widget.loadingText != null)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Text(
                        widget.loadingText!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: widget.progressColor ?? AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء مؤشر التحميل المتحرك
  Widget _buildAnimatedProgress() {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value * 2 * 3.14159,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.progressColor ?? AppColors.primary,
                    (widget.progressColor ?? AppColors.primary).withOpacity(0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  Icons.refresh,
                  color: widget.progressColor ?? AppColors.primary,
                  size: 28,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// نسخة مبسطة من LoadingOverlay للاستخدام السريع
class SimpleLoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;

  const SimpleLoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: isLoading,
      loadingText: 'جاري التحميل...',
      child: child,
    );
  }
}

/// LoadingOverlay للحوارات
class DialogLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final String? loadingText;

  const DialogLoadingOverlay({
    super.key,
    required this.isLoading,
    this.loadingText,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return const SizedBox.shrink();

    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                loadingText ?? 'جاري التحميل...',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}