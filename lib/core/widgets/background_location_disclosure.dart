// lib/core/widgets/background_location_disclosure.dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

class BackgroundLocationDisclosure extends StatelessWidget {
  const BackgroundLocationDisclosure({super.key});

  static const String _privacyPolicyUrl = 'https://privacy.smartpsych.cloud/';

  /// يعرض الـ dialog ويرجع true لو المستخدم وافق.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const BackgroundLocationDisclosure(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.location_on, color: cs.onPrimaryContainer, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Location Access',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Smart Psych collects location data in the background to:',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _Bullet(icon: Icons.nightlight_round, text: 'Detect whether you slept at home or away to improve sleep insights.'),
            const SizedBox(height: 8),
            _Bullet(icon: Icons.directions_walk, text: 'Track daily movement patterns (work, gym, home) for activity analysis.'),
            const SizedBox(height: 8),
            _Bullet(icon: Icons.bar_chart, text: 'Build environmental context to personalise your mental wellness reports.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '⚠  This data is collected even when the app is closed or not in use.',
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(
                text: 'Collection and use are described in our ',
                style: theme.textTheme.bodySmall,
                children: [
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(color: cs.primary, decoration: TextDecoration.underline),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => launchUrl(
                        Uri.parse(_privacyPolicyUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('No thanks'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Allow'),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Bullet({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
      ],
    );
  }
}