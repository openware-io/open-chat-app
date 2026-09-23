import 'package:flutter/material.dart';

/// Removes Material overscroll glow/stretch while preserving the platform scroll
/// physics selected by the surrounding [ScrollConfiguration].
class NoStretchScrollBehavior extends MaterialScrollBehavior {
  const NoStretchScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
