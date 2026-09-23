enum GvWindowClass {
  compact,
  medium,
  expanded,
}

class GvBreakpoints {
  const GvBreakpoints._();

  static const double compactMax = 599;
  static const double mediumMin = 600;
  static const double expandedMin = 1024;

  static GvWindowClass classify(double width) {
    if (width >= expandedMin) return GvWindowClass.expanded;
    if (width >= mediumMin) return GvWindowClass.medium;
    return GvWindowClass.compact;
  }
}
