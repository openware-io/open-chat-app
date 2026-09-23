import 'package:flutter/material.dart';

import '../tokens/open_tokens.dart';

/// Reusable card surface that centralizes radius clipping and card shadow.
class GvCardShell extends StatelessWidget {
  const GvCardShell({
    super.key,
    required this.borderRadius,
    required this.child,
  });

  final BorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: GvShadows.card,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}
