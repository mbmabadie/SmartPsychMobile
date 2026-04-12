// lib/shared/widgets/permission_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Theme
import '../theme/app_colors.dart';
// Enums
import '../enums/permission_enums.dart';

/// بطاقة عرض إذن واحد مع حالته وإجراءاته
class PermissionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final PermissionState state;
  final bool isEssential;
  final bool isCurrentStep;
  final VoidCallback? onTap;

  const PermissionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.state,
    this.isEssential = false,
    this.isCurrentStep = false,
    this.onTap,
  });

  @override
  State<PermissionCard> createState() => _PermissionCardState();
}

class _PermissionCardState extends State<PermissionCard>
    with SingleTickerProviderStateMixin {

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: _getStateColor().withOpacity(0.1),
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

  @override
  void didUpdateWidget(PermissionCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // تحريك البطاقة عند تغيير الحالة
    if (oldWidget.state != widget.state || oldWidget.isCurrentStep != widget.isCurrentStep) {
      _animateCard();
    }
  }

  /// تحريك البطاقة
  void _animateCard() {
    _animationController.forward().then((_) {
      if (mounted) {
        _animationController.reverse();
      }
    });
  }

  /// الحصول على لون الحالة
  Color _getStateColor() {
    switch (widget.state) {
      case PermissionState.granted:
        return AppColors.success;
      case PermissionState.denied:
      case PermissionState.permanentlyDenied:
        return AppColors.error;
      case PermissionState.requesting:
        return AppColors.primary;
      case PermissionState.restricted:
      case PermissionState.limited:
        return AppColors.warning;
      case PermissionState.provisional:
        return AppColors.info;
      case PermissionState.pending:
      default:
        return Colors.grey;
    }
  }

  /// الحصول على أيقونة الحالة
  IconData _getStateIcon() {
    switch (widget.state) {
      case PermissionState.granted:
        return Icons.check_circle;
      case PermissionState.denied:
        return Icons.cancel;
      case PermissionState.permanentlyDenied:
        return Icons.block;
      case PermissionState.requesting:
        return Icons.hourglass_empty;
      case PermissionState.restricted:
        return Icons.warning;
      case PermissionState.limited:
        return Icons.info;
      case PermissionState.provisional:
        return Icons.help;
      case PermissionState.pending:
      default:
        return Icons.radio_button_unchecked;
    }
  }

  /// الحصول على نص الحالة
  String _getStateText() {
    switch (widget.state) {
      case PermissionState.granted:
        return 'ممنوح';
      case PermissionState.denied:
        return 'مرفوض';
      case PermissionState.permanentlyDenied:
        return 'مرفوض نهائياً';
      case PermissionState.requesting:
        return 'جاري الطلب...';
      case PermissionState.restricted:
        return 'مقيد';
      case PermissionState.limited:
        return 'محدود';
      case PermissionState.provisional:
        return 'مؤقت';
      case PermissionState.pending:
      default:
        return 'في الانتظار';
    }
  }

  /// فحص إذا كانت البطاقة قابلة للنقر
  bool get _isClickable {
    return widget.onTap != null &&
        widget.state != PermissionState.granted &&
        widget.state != PermissionState.requesting;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stateColor = _getStateColor();

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: _colorAnimation.value ?? Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isClickable ? () {
                  HapticFeedback.lightImpact();
                  widget.onTap?.call();
                } : null,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.isCurrentStep
                          ? AppColors.primary.withOpacity(0.5)
                          : stateColor.withOpacity(0.2),
                      width: widget.isCurrentStep ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: stateColor.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header Row
                      Row(
                        children: [
                          // Permission Icon
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: stateColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              widget.icon,
                              color: stateColor,
                              size: 24,
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Title and Description
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.title,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ),

                                    // Essential Badge
                                    if (widget.isEssential) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'أساسي',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.error,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  widget.description,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 16),

                          // State Indicator
                          _buildStateIndicator(stateColor, theme),
                        ],
                      ),

                      // Progress Indicator (for current step)
                      if (widget.isCurrentStep && widget.state == PermissionState.requesting) ...[
                        const SizedBox(height: 16),
                        _buildProgressIndicator(),
                      ],

                      // Action Button (for denied/pending states)
                      if (_shouldShowActionButton()) ...[
                        const SizedBox(height: 16),
                        _buildActionButton(theme),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// بناء مؤشر الحالة
  Widget _buildStateIndicator(Color stateColor, ThemeData theme) {
    return Column(
      children: [
        // State Icon
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: stateColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: widget.state == PermissionState.requesting
              ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(stateColor),
            ),
          )
              : Icon(
            _getStateIcon(),
            color: stateColor,
            size: 18,
          ),
        ),

        const SizedBox(height: 4),

        // State Text
        Text(
          _getStateText(),
          style: TextStyle(
            fontSize: 10,
            color: stateColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// بناء مؤشر التقدم
  Widget _buildProgressIndicator() {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(2),
      ),
      child: LinearProgressIndicator(
        backgroundColor: Colors.transparent,
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// فحص إذا كان يجب عرض زر الإجراء
  bool _shouldShowActionButton() {
    return (widget.state == PermissionState.denied ||
        widget.state == PermissionState.pending ||
        widget.state == PermissionState.permanentlyDenied) &&
        _isClickable;
  }

  /// بناء زر الإجراء
  Widget _buildActionButton(ThemeData theme) {
    String buttonText;
    IconData buttonIcon;

    switch (widget.state) {
      case PermissionState.permanentlyDenied:
        buttonText = 'فتح الإعدادات';
        buttonIcon = Icons.settings;
        break;
      case PermissionState.denied:
        buttonText = 'إعادة المحاولة';
        buttonIcon = Icons.refresh;
        break;
      case PermissionState.pending:
      default:
        buttonText = 'طلب الإذن';
        buttonIcon = Icons.security;
        break;
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: widget.onTap,
        icon: Icon(buttonIcon, size: 16),
        label: Text(buttonText),
        style: OutlinedButton.styleFrom(
          foregroundColor: _getStateColor(),
          side: BorderSide(color: _getStateColor().withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }
}