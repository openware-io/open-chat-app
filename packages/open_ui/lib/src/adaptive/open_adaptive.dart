import 'package:flutter/widgets.dart';

import 'open_breakpoints.dart';

extension GvBuildContextAdaptive on BuildContext {
  double get gvScreenWidth => MediaQuery.sizeOf(this).width;

  GvWindowClass get gvWindowClass => GvBreakpoints.classify(gvScreenWidth);

  bool get gvIsCompact => gvWindowClass == GvWindowClass.compact;

  bool get gvIsMedium => gvWindowClass == GvWindowClass.medium;

  bool get gvIsExpanded => gvWindowClass == GvWindowClass.expanded;
}

class GvAdaptiveBuilder extends StatelessWidget {
  const GvAdaptiveBuilder({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
  });

  final WidgetBuilder compact;
  final WidgetBuilder? medium;
  final WidgetBuilder? expanded;

  @override
  Widget build(BuildContext context) {
    return switch (context.gvWindowClass) {
      GvWindowClass.compact => compact(context),
      GvWindowClass.medium => (medium ?? compact)(context),
      GvWindowClass.expanded => (expanded ?? medium ?? compact)(context),
    };
  }
}
