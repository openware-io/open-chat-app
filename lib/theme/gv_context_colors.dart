import 'package:flutter/cupertino.dart';

/// 从 [BuildContext] 解析 iOS 系统色（浅色 / 深色随系统）。
extension GvCupertinoColors on BuildContext {
  Color get gvLabel => CupertinoColors.label.resolveFrom(this);
  Color get gvSecondaryLabel =>
      CupertinoColors.secondaryLabel.resolveFrom(this);
  Color get gvTertiaryLabel => CupertinoColors.tertiaryLabel.resolveFrom(this);
  Color get gvQuaternaryLabel =>
      CupertinoColors.quaternaryLabel.resolveFrom(this);
  Color get gvSystemBlue => CupertinoColors.systemBlue.resolveFrom(this);
  Color get gvSystemRed => CupertinoColors.systemRed.resolveFrom(this);
  Color get gvSystemGreen => CupertinoColors.systemGreen.resolveFrom(this);
  Color get gvSystemBackground =>
      CupertinoColors.systemBackground.resolveFrom(this);
  Color get gvSystemGroupedBackground =>
      CupertinoColors.systemGroupedBackground.resolveFrom(this);
  Color get gvSecondarySystemGroupedBackground =>
      CupertinoColors.secondarySystemGroupedBackground.resolveFrom(this);
  Color get gvSeparator => CupertinoColors.separator.resolveFrom(this);
  Color get gvOpaqueSeparator =>
      CupertinoColors.opaqueSeparator.resolveFrom(this);
  Color get gvSystemFill => CupertinoColors.systemFill.resolveFrom(this);
  Color get gvSystemGrey5 => CupertinoColors.systemGrey5.resolveFrom(this);
  Color get gvSystemGrey4 => CupertinoColors.systemGrey4.resolveFrom(this);
}
