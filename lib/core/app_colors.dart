import 'package:flutter/cupertino.dart';

import '../theme/gv_tokens.dart';

export '../theme/gv_tokens.dart' show GvLayout, GvRadii, GvShadows, GvSpacing;

/// 语义色均指向 iOS [CupertinoColors]，随系统浅/深自动解析。
///
/// 布局尺寸（navbar / tabbar 高度等）已迁移至 [GvLayout]，请直接使用。
abstract final class AppColors {
  static const CupertinoDynamicColor primary = CupertinoColors.systemBlue;

  /// 地图选点与位置消息图钉（固定蓝色，不随 Material primary 等主题色变化）。
  static const Color locationMapPin = Color(0xFF1976D2);
  static const CupertinoDynamicColor danger = CupertinoColors.systemRed;
  static const CupertinoDynamicColor success = CupertinoColors.systemGreen;

  static const CupertinoDynamicColor bgPage =
      CupertinoColors.systemGroupedBackground;
  static const CupertinoDynamicColor bgWhite =
      CupertinoColors.secondarySystemGroupedBackground;

  static const CupertinoDynamicColor bgChat = CupertinoColors.systemGrey5;
  static const CupertinoDynamicColor bgInput = CupertinoColors.systemFill;
  static const CupertinoDynamicColor bgSearchField =
      CupertinoColors.systemGrey5;

  /// 加号菜单等深色浮层（保持深色质感，不随分组背景切换）。
  /// 值与 [bgInput] 的 darkColor 一致，仅用于始终暗底的弹层。
  static Color get bgDarkSecondary => bgInput.darkColor;

  static const CupertinoDynamicColor textPrimary = CupertinoColors.label;
  static const CupertinoDynamicColor textSecondary =
      CupertinoColors.secondaryLabel;
  static const CupertinoDynamicColor textHint = CupertinoColors.tertiaryLabel;

  static const CupertinoDynamicColor border = CupertinoColors.separator;

  static const CupertinoDynamicColor bubbleSelf = CupertinoColors.systemBlue;

  /// 对方文本气泡底色：浅色仍接近 [CupertinoColors.systemGrey5]；暗夜固定 #666（用户指定对比度）。
  static const Color _bubbleOtherLight = Color(0xFFE5E5EA);
  static const Color _bubbleOtherDark = Color(0xFF666666);
  static const CupertinoDynamicColor bubbleOther = CupertinoDynamicColor(
    debugLabel: 'bubbleOther',
    color: _bubbleOtherLight,
    darkColor: _bubbleOtherDark,
    highContrastColor: _bubbleOtherLight,
    darkHighContrastColor: _bubbleOtherDark,
    elevatedColor: _bubbleOtherLight,
    darkElevatedColor: _bubbleOtherDark,
    highContrastElevatedColor: _bubbleOtherLight,
    darkHighContrastElevatedColor: _bubbleOtherDark,
  );
  static const Color bubbleSelfText = CupertinoColors.white;
  static const CupertinoDynamicColor bubbleOtherText = CupertinoColors.label;
}
