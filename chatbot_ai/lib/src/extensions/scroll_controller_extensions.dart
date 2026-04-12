import 'package:flutter/material.dart' show ScrollController, Curves;

extension ScrollControllerExtensions on ScrollController {
  void scrollToTop() async {
    final controller = this;
    return controller.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.fastOutSlowIn,
    );
  }
}
