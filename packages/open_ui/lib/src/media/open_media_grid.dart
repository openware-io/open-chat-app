import 'package:flutter/material.dart';

import '../lists/open_list_primitives.dart';
import '../tokens/open_tokens.dart';

/// Sliver section for grouped media grids.
class GvSliverMediaGridSection extends StatelessWidget {
  const GvSliverMediaGridSection({
    super.key,
    required this.header,
    required this.headerStyle,
    required this.itemCount,
    required this.itemBuilder,
    required this.gridDelegate,
    this.padding = const EdgeInsets.symmetric(horizontal: GvSpacing.page),
  });

  final String header;
  final TextStyle headerStyle;
  final int itemCount;
  final NullableIndexedWidgetBuilder itemBuilder;
  final SliverGridDelegate gridDelegate;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: GvSectionHeader(
            label: header,
            textStyle: headerStyle,
          ),
        ),
        SliverPadding(
          padding: padding,
          sliver: SliverGrid(
            gridDelegate: gridDelegate,
            delegate: SliverChildBuilderDelegate(
              itemBuilder,
              childCount: itemCount,
            ),
          ),
        ),
      ],
    );
  }
}

/// Clickable clipped surface for media thumbnails.
class GvMediaGridTile extends StatelessWidget {
  const GvMediaGridTile({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(GvRadii.compact),
    ),
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final clipped = ClipRRect(
      borderRadius: borderRadius,
      child: child,
    );
    if (onTap == null) return clipped;
    return GestureDetector(
      onTap: onTap,
      child: clipped,
    );
  }
}
