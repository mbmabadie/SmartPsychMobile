// lib/features/sleep/widgets/session_confirmation_dialog.dart
import 'package:flutter/material.dart';
import '../../../core/database/models/sleep_models.dart';

class SessionConfirmationDialog extends StatefulWidget {
  final SleepSession session;
  final bool isConfirm;
  final Future<void> Function(double quality) onConfirm; // ✅ Future
  final Future<void> Function() onReject; // ✅ Future

  const SessionConfirmationDialog({
    super.key,
    required this.session,
    required this.isConfirm,
    required this.onConfirm,
    required this.onReject,
  });

  @override
  State<SessionConfirmationDialog> createState() =>
      _SessionConfirmationDialogState();
}

class _SessionConfirmationDialogState extends State<SessionConfirmationDialog> {
  double _quality = 3.0;
  bool _isLoading = false; // ✅ متغير loading

  @override
  Widget build(BuildContext context) {
    final duration = widget.session.duration ?? Duration.zero;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.isConfirm
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.isConfirm ? Icons.check_circle : Icons.cancel,
                size: 48,
                color: widget.isConfirm
                    ? Colors.green.shade400
                    : Colors.red.shade400,
              ),
            ),

            const SizedBox(height: 16),

            // Title
            Text(
              widget.isConfirm ? 'تأكيد جلسة النوم' : 'رفض جلسة النوم',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Session Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${hours}h ${minutes}m',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_formatTime(widget.session.startTime)} - ${widget.session.endTime != null ? _formatTime(widget.session.endTime!) : "الآن"}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Confirmation Message
            if (widget.isConfirm) ...[
              Text(
                'كيف كانت جودة نومك؟',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Quality Slider
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQualityEmoji(1),
                      _buildQualityEmoji(2),
                      _buildQualityEmoji(3),
                      _buildQualityEmoji(4),
                      _buildQualityEmoji(5),
                    ],
                  ),
                  Slider(
                    value: _quality,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: _getQualityLabel(_quality.round()),
                    onChanged: _isLoading ? null : (value) { // ✅ تعطيل أثناء التحميل
                      setState(() {
                        _quality = value;
                      });
                    },
                  ),
                  Text(
                    _getQualityLabel(_quality.round()),
                    style: TextStyle(
                      color: _getQualityColor(_quality.round()),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'هل تريد فعلاً رفض هذه الجلسة؟',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'سيتم تصنيفها كـ "هاتف متروك"',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 24),

            // ✅ Action Buttons - التعديل الأساسي هنا!
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context), // ✅ تعطيل أثناء التحميل
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleAction, // ✅ async handler
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isConfirm
                          ? Colors.green.shade500
                          : Colors.red.shade500,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(widget.isConfirm ? 'تأكيد' : 'رفض'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ دالة async منفصلة للتعامل مع الأكشن
  Future<void> _handleAction() async {
    setState(() => _isLoading = true);

    try {
      if (widget.isConfirm) {
        debugPrint('⏳ [Dialog] بدء تأكيد الجلسة...');
        await widget.onConfirm(_quality);
        debugPrint('✅ [Dialog] تم التأكيد بنجاح');
      } else {
        debugPrint('⏳ [Dialog] بدء رفض الجلسة...');
        await widget.onReject();
        debugPrint('✅ [Dialog] تم الرفض بنجاح');
      }

      // ✅ الديالوغ سيُغلق من pending_confirmations_card.dart

    } catch (e) {
      debugPrint('❌ [Dialog] خطأ: $e');

      // ✅ إظهار رسالة خطأ
      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ حدث خطأ: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildQualityEmoji(int quality) {
    final isSelected = _quality.round() == quality;
    return GestureDetector(
      onTap: _isLoading ? null : () { // ✅ تعطيل أثناء التحميل
        setState(() {
          _quality = quality.toDouble();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? _getQualityColor(quality).withOpacity(0.1) : null,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? _getQualityColor(quality)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          _getQualityEmoji(quality),
          style: TextStyle(
            fontSize: isSelected ? 32 : 24,
          ),
        ),
      ),
    );
  }

  String _getQualityEmoji(int quality) {
    switch (quality) {
      case 1:
        return '😫';
      case 2:
        return '😕';
      case 3:
        return '😐';
      case 4:
        return '😊';
      case 5:
        return '😴';
      default:
        return '😐';
    }
  }

  String _getQualityLabel(int quality) {
    switch (quality) {
      case 1:
        return 'سيء جداً';
      case 2:
        return 'سيء';
      case 3:
        return 'متوسط';
      case 4:
        return 'جيد';
      case 5:
        return 'ممتاز';
      default:
        return 'متوسط';
    }
  }

  Color _getQualityColor(int quality) {
    switch (quality) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.amber;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.amber;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}