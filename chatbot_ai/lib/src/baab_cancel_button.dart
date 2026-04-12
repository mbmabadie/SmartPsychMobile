import 'package:flutter/material.dart';

import 'colors.dart';
import 'extensions/extensions.dart' show ContextExtensions;


class BaabCancelButton extends StatelessWidget {
  const BaabCancelButton({
    required this.width,
    required this.height,
    required this.cancelText,
    this.isApply =false,
    super.key,
  });
  final double width;
  final double height;
  final bool isApply;
  final String cancelText;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: isApply?AppColors.primaryColor:context.theme.inputDecorationTheme.fillColor,
          side: BorderSide(
            color: isApply?AppColors.primaryColor:context.theme.inputDecorationTheme.fillColor!,
          ),
        ),
        onPressed: () {
          context.pop(false);
        },
        child: Text(cancelText),
      ),
    );
  }
}
