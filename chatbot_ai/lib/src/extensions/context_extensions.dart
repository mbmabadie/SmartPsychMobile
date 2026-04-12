import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

extension ContextExtensions<T> on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  void push(Widget page) async {
    await Future.delayed(Duration.zero);
    if (mounted) {
      await Navigator.of(this).push(
        MaterialPageRoute(
          builder: (context) => page,
        ),
      );
    }
  }

  /// This is to make the user not feel like navigating to new screen
  void pushWithoutTransition(Widget page) async {
    await Navigator.of(this).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void pushAndRemoveOthers(Widget page) async {
    await Future.delayed(Duration.zero);
    if (mounted) {
      await Navigator.of(this).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => page,
        ),
        (route) => false,
      );
    }
  }

  void pushReplacement(Widget page) async {
    await Future.delayed(Duration.zero);
    if (mounted) {
      await Navigator.of(this).pushReplacement(
        MaterialPageRoute(
          builder: (context) => page,
        ),
      );
    }
  }

  /// Pop the top-most route off the navigator that most tightly encloses the
  ///  given context.
  void pop([T? result]) => Navigator.pop(this, result);

  SnackBar _snackbarContent({
    required Color backgroundColor,
    required String message,
    required String icon,
  }) {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: backgroundColor,
      content: Row(
        children: [
          Expanded(
            flex: 10,
            child: Text(
              message,
              style: theme.textTheme.labelMedium!.copyWith(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(child: SvgPicture.asset(icon)),
        ],
      ),
    );
  }


}
