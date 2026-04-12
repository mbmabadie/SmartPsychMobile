import 'package:flutter/material.dart';

import 'extensions/context_extensions.dart';


class BaabButton extends StatelessWidget {
  const BaabButton({
    super.key,
    required this.onPressed,
    this.style,
    required this.child,
  });
  final VoidCallback onPressed;
  final ButtonStyle? style;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        gradient: LinearGradient(
          colors: [
            context.theme.colorScheme.primary.withOpacity(0.6),
            context.theme.colorScheme.primary.withOpacity(0.7),
            context.theme.colorScheme.primary,
          ],
        ),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: style,
        child: child,
      ),
    );
  }
}
