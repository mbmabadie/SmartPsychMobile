// lib/features/sleep/widgets/pending_confirmations_card.dart
import 'package:flutter/material.dart';
import '../../../core/database/models/sleep_models.dart';
import '../screens/pending_confirmations_screen.dart'; // ✅ جديد
import 'session_confirmation_dialog.dart';

class PendingConfirmationsCard extends StatelessWidget {
  final List<SleepSession> sessions;
  final Future<void> Function(String sessionId, double quality) onConfirm;
  final Future<void> Function(String sessionId) onReject;

  const PendingConfirmationsCard({
    super.key,
    required this.sessions,
    required this.onConfirm,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.shade50,
              Colors.amber.shade50,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.notification_important,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'في انتظار التأكيد',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${sessions.length} ${sessions.length == 1 ? "جلسة" : "جلسات"}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${sessions.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Sessions List (أول 3 فقط)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length > 3 ? 3 : sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final session = sessions[index];
                return _buildSessionItem(context, session);
              },
            ),

            // ✅ View All Button - معدّل!
            if (sessions.length > 3)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PendingConfirmationsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: Text('عرض الكل (${sessions.length})'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange.shade700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionItem(BuildContext context, SleepSession session) {
    final duration = session.duration ?? Duration.zero;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time and Duration
          Row(
            children: [
              Icon(
                Icons.bedtime,
                size: 18,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                _formatTime(session.startTime),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward,
                size: 14,
                color: Colors.grey.shade400,
              ),
              const SizedBox(width: 8),
              Text(
                session.endTime != null
                    ? _formatTime(session.endTime!)
                    : 'الآن',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${hours}h ${minutes}m',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Confidence Badge
          Row(
            children: [
              Text(session.confidence.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                session.confidence.displayName,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showConfirmationDialog(
                      context,
                      session,
                      isConfirm: false,
                    );
                  },
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('رفض'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                    side: BorderSide(color: Colors.red.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showConfirmationDialog(
                      context,
                      session,
                      isConfirm: true,
                    );
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('تأكيد'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade500,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog(
      BuildContext context,
      SleepSession session,
      {required bool isConfirm}
      ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SessionConfirmationDialog(
        session: session,
        isConfirm: isConfirm,
        onConfirm: (quality) async {
          await onConfirm(session.id.toString(), quality);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ تم تأكيد جلسة النوم بنجاح'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        },
        onReject: () async {
          await onReject(session.id.toString());

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ تم رفض جلسة النوم'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.orange,
              ),
            );
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}