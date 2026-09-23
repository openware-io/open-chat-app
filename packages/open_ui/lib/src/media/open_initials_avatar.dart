import 'package:flutter/material.dart';

/// Pure avatar renderer. Name parsing, URL resolution, and user id color
/// selection stay in the app layer.
class GvInitialsAvatar extends StatelessWidget {
  const GvInitialsAvatar({
    super.key,
    required this.initials,
    required this.gradientColors,
    required this.size,
    required this.semanticLabel,
    this.image,
    this.square = false,
  });

  final String initials;
  final List<Color> gradientColors;
  final double size;
  final String semanticLabel;
  final Widget? image;
  final bool square;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: image ??
          Center(
            child: Text(
              initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.4,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
    );

    final clipped = square
        ? ClipRRect(borderRadius: BorderRadius.circular(6), child: child)
        : ClipOval(child: child);
    return Semantics(
      label: semanticLabel,
      image: image != null,
      excludeSemantics: true,
      child: clipped,
    );
  }
}
