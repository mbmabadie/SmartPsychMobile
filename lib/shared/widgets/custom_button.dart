// lib/shared/widgets/custom_button.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Theme
import '../theme/app_colors.dart';

/// زر مخصص مع أنماط مختلفة ورسوم متحركة
class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final CustomButtonStyle style;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;
  final EdgeInsets? padding;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Gradient? gradient;
  final BorderRadius? borderRadius;
  final double elevation;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style = CustomButtonStyle.filled,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
    this.padding,
    this.width,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
    this.gradient,
    this.borderRadius,
    this.elevation = 0,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// معالجة الضغط على الزر
  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() {
        _isPressed = true;
      });
      _animationController.forward();
      HapticFeedback.lightImpact();
    }
  }

  /// معالجة رفع الضغط عن الزر
  void _handleTapUp(TapUpDetails details) {
    _handleTapEnd();
  }

  /// معالجة إلغاء الضغط
  void _handleTapCancel() {
    _handleTapEnd();
  }

  /// إنهاء معالجة الضغط
  void _handleTapEnd() {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }

  /// معالجة النقر
  void _handleTap() {
    if (widget.onPressed != null && !widget.isLoading) {
      widget.onPressed!();
    }
  }

  /// الحصول على ألوان الزر حسب النمط
  ButtonColors _getButtonColors(ThemeData theme) {
    final bool isDark = theme.brightness == Brightness.dark;

    switch (widget.style) {
      case CustomButtonStyle.filled:
        return ButtonColors(
          backgroundColor: widget.backgroundColor ?? AppColors.primary,
          foregroundColor: widget.foregroundColor ?? Colors.white,
          borderColor: Colors.transparent,
        );

      case CustomButtonStyle.outline:
        return ButtonColors(
          backgroundColor: Colors.transparent,
          foregroundColor: widget.foregroundColor ?? AppColors.primary,
          borderColor: widget.backgroundColor ?? AppColors.primary,
        );

      case CustomButtonStyle.text:
        return ButtonColors(
          backgroundColor: Colors.transparent,
          foregroundColor: widget.foregroundColor ?? AppColors.primary,
          borderColor: Colors.transparent,
        );

      case CustomButtonStyle.ghost:
        return ButtonColors(
          backgroundColor: (widget.backgroundColor ?? AppColors.primary).withOpacity(0.1),
          foregroundColor: widget.foregroundColor ?? AppColors.primary,
          borderColor: Colors.transparent,
        );

      case CustomButtonStyle.danger:
        return ButtonColors(
          backgroundColor: widget.backgroundColor ?? AppColors.error,
          foregroundColor: widget.foregroundColor ?? Colors.white,
          borderColor: Colors.transparent,
        );

      case CustomButtonStyle.success:
        return ButtonColors(
          backgroundColor: widget.backgroundColor ?? AppColors.success,
          foregroundColor: widget.foregroundColor ?? Colors.white,
          borderColor: Colors.transparent,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _getButtonColors(theme);
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: GestureDetector(
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              onTapCancel: _handleTapCancel,
              onTap: _handleTap,
              child: Container(
                width: widget.isExpanded ? double.infinity : widget.width,
                height: widget.height ?? 56,
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  color: widget.gradient == null ? colors.backgroundColor : null,
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                  border: colors.borderColor != Colors.transparent
                      ? Border.all(color: colors.borderColor, width: 1.5)
                      : null,
                  boxShadow: widget.elevation > 0
                      ? [
                    BoxShadow(
                      color: colors.backgroundColor.withOpacity(0.3),
                      blurRadius: widget.elevation,
                      offset: Offset(0, widget.elevation / 2),
                    ),
                  ]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isEnabled ? _handleTap : null,
                    borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                    child: Container(
                      padding: widget.padding ?? const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: _buildButtonContent(colors, isEnabled),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// بناء محتوى الزر
  Widget _buildButtonContent(ButtonColors colors, bool isEnabled) {
    final contentColor = isEnabled
        ? colors.foregroundColor
        : colors.foregroundColor.withOpacity(0.5);

    if (widget.isLoading) {
      return _buildLoadingContent(contentColor);
    }

    if (widget.icon != null) {
      return _buildIconTextContent(contentColor);
    }

    return _buildTextContent(contentColor);
  }

  /// بناء محتوى التحميل
  Widget _buildLoadingContent(Color contentColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(contentColor),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'جاري التحميل...',
          style: TextStyle(
            color: contentColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// بناء محتوى الأيقونة والنص
  Widget _buildIconTextContent(Color contentColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          widget.icon,
          color: contentColor,
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          widget.text,
          style: TextStyle(
            color: contentColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// بناء محتوى النص فقط
  Widget _buildTextContent(Color contentColor) {
    return Text(
      widget.text,
      style: TextStyle(
        color: contentColor,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// أنماط الزر المخصص
enum CustomButtonStyle {
  filled,      // ممتلئ
  outline,     // مخطط
  text,        // نص فقط
  ghost,       // شبح (خلفية شفافة)
  danger,      // خطر
  success,     // نجاح
}

/// ألوان الزر
class ButtonColors {
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;

  const ButtonColors({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
  });
}