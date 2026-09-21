// Unicode Emoji 字符列表（Unicode Standard）。发送内容仍为纯 Unicode 文本；
// 气泡等 [Text.rich]：仅 [kGvFluentEmojiCodepoints] 用 Fluent，其余 emoji 系统字体。
// iOS 输入框：[GvChatComposerEditingController] 在 [buildTextSpan] 内分段上 Fluent；其它平台仍可用整段 fallback。

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:gv_ui/gv_ui.dart' show GvTypographyScale;

import 'app_theme.dart';

final Map<String, TextStyle> _gvEmojiPickerStyleCache = {};

/// 常用表情与符号，供聊天输入选用。
const List<String> kUnicodeEmojiPalette = [
  // 笑脸与情绪
  '\u{1F600}', '\u{1F603}', '\u{1F604}', '\u{1F601}', '\u{1F606}', '\u{1F605}',
  '\u{1F923}', '\u{1F602}', '\u{1F642}', '\u{1F643}', '\u{1F609}', '\u{1F60A}',
  '\u{1F607}', '\u{1F970}', '\u{1F60D}', '\u{1F929}', '\u{1F618}', '\u{1F617}',
  '\u{263A}', '\u{1F61A}', '\u{1F619}', '\u{1F972}', '\u{1F60B}', '\u{1F61B}',
  '\u{1F61C}', '\u{1F92A}', '\u{1F61D}', '\u{1F911}', '\u{1F917}', '\u{1F92D}',
  '\u{1F92B}', '\u{1F914}', '\u{1F910}', '\u{1F928}', '\u{1F610}', '\u{1F611}',
  '\u{1F636}', '\u{1F60F}', '\u{1F612}', '\u{1F644}', '\u{1F62C}', '\u{1F925}',
  '\u{1F60C}', '\u{1F614}', '\u{1F62A}', '\u{1F924}', '\u{1F634}', '\u{1F637}',
  '\u{1F912}', '\u{1F915}', '\u{1F922}', '\u{1F92E}', '\u{1F927}', '\u{1F975}',
  '\u{1F976}', '\u{1F974}', '\u{1F635}', '\u{1F92F}', '\u{1F920}', '\u{1F973}',
  '\u{1F978}', '\u{1F60E}', '\u{1F913}', '\u{1F9D0}', '\u{1F615}', '\u{1F61F}',
  '\u{1F641}', '\u{2639}', '\u{1F62E}', '\u{1F62F}', '\u{1F632}', '\u{1F633}',
  '\u{1F97A}', '\u{1F626}', '\u{1F627}', '\u{1F628}', '\u{1F630}', '\u{1F625}',
  '\u{1F622}', '\u{1F62D}', '\u{1F631}', '\u{1F616}', '\u{1F623}', '\u{1F61E}',
  '\u{1F613}', '\u{1F629}', '\u{1F62B}', '\u{1F971}', '\u{1F624}', '\u{1F621}',
  '\u{1F620}', '\u{1F92C}', '\u{1F608}', '\u{1F47F}', '\u{1F480}', '\u{2620}',
  '\u{1F4A9}', '\u{1F921}', '\u{1F479}', '\u{1F47A}', '\u{1F47B}', '\u{1F47D}',
  '\u{1F47E}', '\u{1F916}', '\u{1F63A}', '\u{1F638}', '\u{1F639}', '\u{1F63B}',
  '\u{1F63C}', '\u{1F63D}', '\u{1F640}', '\u{1F63F}', '\u{1F63E}',
  // 手势与身体
  '\u{1F44B}', '\u{1F91A}', '\u{1F590}', '\u{270B}', '\u{1F596}', '\u{1F44C}',
  '\u{270C}', '\u{1F91E}', '\u{1F91F}', '\u{1F918}', '\u{1F919}', '\u{1F448}',
  '\u{1F449}', '\u{1F446}', '\u{1F447}', '\u{261D}', '\u{1F44D}', '\u{1F44E}',
  '\u{270A}', '\u{1F44A}', '\u{1F91B}', '\u{1F91C}', '\u{1F44F}', '\u{1F64C}',
  '\u{1F450}', '\u{1F932}', '\u{1F91D}', '\u{1F64F}', '\u{1F9B6}', '\u{1F9B5}',
  '\u{1F9CD}', '\u{1F9CE}', '\u{1F9CF}', '\u{1F9D1}', '\u{1F9D2}', '\u{1F9D3}',
  '\u{1F9D4}', '\u{1F9D5}', '\u{1F464}', '\u{1F465}', '\u{1F476}',
  // 心与装饰
  '\u{2764}', '\u{1F9E1}', '\u{1F49B}', '\u{1F49A}', '\u{1F499}', '\u{1F49C}',
  '\u{1F5A4}', '\u{1F90E}', '\u{1F494}', '\u{1F495}', '\u{1F49E}', '\u{1F493}',
  '\u{1F497}', '\u{1F496}', '\u{1F498}', '\u{1F49D}', '\u{2728}', '\u{2B50}',
  '\u{1F31F}', '\u{1F4AB}', '\u{1F4A5}', '\u{1F525}', '\u{1F4AF}', '\u{1F389}',
  '\u{1F38A}', '\u{1F388}', '\u{1F382}', '\u{1F381}',
];

/// Fluent 彩色字体仅对这些 Unicode 标量（及同簇内的 VS16 / 肤色修饰符）生效。
final Set<int> kGvFluentEmojiCodepoints = {
  for (final s in kUnicodeEmojiPalette) ...s.runes,
};

/// pubspec 中 [FluentEmojiColor-Min.ttf] 的 family 名。
const String kGvFluentEmojiFontFamily = 'FluentEmojiColor';

/// 系统彩色 emoji 回退（不含 Fluent）。
const List<String> kGvSystemColorEmojiFontFallbacks = <String>[
  'Apple Color Emoji',
  'Segoe UI Emoji',
  'Noto Color Emoji',
];

/// 输入框等无法用 rich 分段的控件：主字体缺字形时先试 Fluent，再系统彩色 emoji。
const List<String> kGvFluentEmojiFontFallbacks = <String>[
  kGvFluentEmojiFontFamily,
  ...kGvSystemColorEmojiFontFallbacks,
];

/// 为 [TextField] 合并 Fluent + 系统彩色 emoji（整段同一套 fallback）。
///
/// **iOS 聊天输入框**请配合 [GvChatComposerEditingController]；勿仅用本函数（整段 fallback 仍可能影响数字）。
TextStyle gvWithFluentEmojiFallback(TextStyle base) {
  final extra = base.fontFamilyFallback;
  if (extra == null || extra.isEmpty) {
    return base.copyWith(fontFamilyFallback: kGvFluentEmojiFontFallbacks);
  }
  return base.copyWith(
    fontFamilyFallback: <String>[
      ...kGvFluentEmojiFontFallbacks,
      ...extra,
    ],
  );
}

/// 为 [Text] 等合并系统彩色 emoji 回退（不含 Fluent）。
TextStyle gvWithSystemColorEmojiFallback(TextStyle base) {
  final extra = base.fontFamilyFallback;
  if (extra == null || extra.isEmpty) {
    return base.copyWith(fontFamilyFallback: kGvSystemColorEmojiFontFallbacks);
  }
  return base.copyWith(
    fontFamilyFallback: <String>[
      ...kGvSystemColorEmojiFontFallbacks,
      ...extra,
    ],
  );
}

/// iOS 聊天气泡 / 输入框主文字：系统 UI 字体，数字与正文优先走此族，不与 Fluent 混在同一 [TextStyle] 的 fallback 链上。
const String gvIosChatUiFontFamily = '.SF Pro Text';

/// 白名单 emoji 单独使用的样式（Fluent + 系统彩色回退）；勿用于整段纯文本。
TextStyle gvFluentEmojiClusterTextStyle(TextStyle base) {
  return TextStyle(
    color: base.color,
    fontSize: base.fontSize,
    height: base.height,
    letterSpacing: base.letterSpacing,
    fontFamily: kGvFluentEmojiFontFamily,
    fontFamilyFallback: kGvSystemColorEmojiFontFallbacks,
  );
}

bool _gvClusterUsesFluentEmoji(String cluster) {
  if (cluster.isEmpty) return false;
  final it = cluster.runes.iterator;
  if (!it.moveNext()) return false;
  if (!kGvFluentEmojiCodepoints.contains(it.current)) return false;
  while (it.moveNext()) {
    final r = it.current;
    if (r == 0xFE0F || r == 0xFE0E) continue;
    if (r >= 0x1F3FB && r <= 0x1F3FF) continue;
    return false;
  }
  return true;
}

/// 与气泡 [Text.rich]、iOS [GvChatComposerEditingController] 共用：按 grapheme 切段，白名单 emoji 用 [fluentStyle]。
List<TextSpan> gvTextSpansWithFluentEmojiWhitelist(
  String text,
  TextStyle plainWithSystemEmoji,
  TextStyle fluentStyle,
) {
  if (text.isEmpty) {
    return const [TextSpan(text: '')];
  }
  final children = <TextSpan>[];
  final buf = StringBuffer();
  bool? lastFluent;

  void flush() {
    if (buf.isEmpty) return;
    final s = buf.toString();
    buf.clear();
    children.add(TextSpan(
      text: s,
      style: lastFluent! ? fluentStyle : null,
    ));
  }

  for (final g in text.characters) {
    final useFluent = _gvClusterUsesFluentEmoji(g);
    if (lastFluent != null && useFluent != lastFluent) {
      flush();
    }
    lastFluent = useFluent;
    buf.write(g);
  }
  flush();
  return children;
}

TextStyle _gvChatBubbleBodyBase(Color fg, {double fontSize = 16}) {
  final base = TextStyle(
    color: fg,
    fontSize: fontSize,
    letterSpacing: 0,
    height: 1.25,
  );
  if (!kIsWeb && Platform.isIOS) {
    return base.copyWith(
      fontFamily: gvIosChatUiFontFamily,
      fontFeatures: const [FontFeature.proportionalFigures()],
    );
  }
  // 非 iOS：[Text.rich] 根 [TextStyle] 若不带 fontFamily，仅设 emoji fallback 时引擎不会用 [ThemeData.fontFamily]，PC 上气泡仍为系统默认体。
  return base.copyWith(
    fontFamily: kGvGlobalUIFontFamily,
    fontFamilyFallback: kGvGlobalUIFontFallbacks,
  );
}

TextStyle _gvChatBubbleCaptionBase(
  Color fg, {
  double fontSize = GvTypographyScale.chatCaption,
}) {
  final base = TextStyle(
    color: fg,
    fontSize: fontSize,
    letterSpacing: 0,
    height: 1.2,
  );
  if (!kIsWeb && Platform.isIOS) {
    return base.copyWith(
      fontFamily: gvIosChatUiFontFamily,
      fontFeatures: const [FontFeature.proportionalFigures()],
    );
  }
  return base.copyWith(
    fontFamily: kGvGlobalUIFontFamily,
    fontFamilyFallback: kGvGlobalUIFontFallbacks,
  );
}

TextStyle _gvBubblePlainStyleForPlatform(TextStyle base) {
  if (!kIsWeb && Platform.isIOS) {
    // 不再挂 Apple Color Emoji 等 fallback：否则易与数字同段 shaping，出现「方盒字距」。
    // 非白名单 emoji 仍可由 CoreText 从系统 UI 字体级联到彩色 emoji。
    return base;
  }
  return gvWithSystemColorEmojiFallback(base);
}

/// iOS：[Text.rich] 与 Fluent/彩色 emoji 混排时，行高易被 emoji 字体撑大，数字随之像方块排版。
/// 强制 strut 与系统 UI 正文一致，避免整行采用 emoji 的 ascent/descent。
StrutStyle? gvChatBubbleStrutIosOnly({
  required double fontSize,
  required double height,
}) {
  if (kIsWeb || !Platform.isIOS) return null;
  return StrutStyle(
    fontFamily: gvIosChatUiFontFamily,
    fontSize: fontSize,
    height: height,
    leading: 0,
    forceStrutHeight: true,
  );
}

/// 聊天气泡正文。
TextStyle gvChatBubbleBodyTextStyle(
  Color fg, {
  double fontSize = GvTypographyScale.chatBody,
}) {
  return _gvBubblePlainStyleForPlatform(
    _gvChatBubbleBodyBase(fg, fontSize: fontSize),
  );
}

/// 气泡正文混排：白名单 emoji 用 Fluent；iOS 普通段不挂彩色 emoji fallback。
InlineSpan gvChatBubbleBodyRich(
  String text,
  Color fg, {
  double fontSize = GvTypographyScale.chatBody,
}) {
  final base = _gvChatBubbleBodyBase(fg, fontSize: fontSize);
  final plain = _gvBubblePlainStyleForPlatform(base);
  final fluent = gvFluentEmojiClusterTextStyle(base);
  return TextSpan(
    style: plain,
    children: gvTextSpansWithFluentEmojiWhitelist(text, plain, fluent),
  );
}

/// 气泡内较小说明文字（如引用预览）。
TextStyle gvChatBubbleCaptionTextStyle(
  Color fg, {
  double fontSize = GvTypographyScale.chatCaption,
}) {
  return _gvBubblePlainStyleForPlatform(
    _gvChatBubbleCaptionBase(fg, fontSize: fontSize),
  );
}

/// 气泡说明混排：白名单 emoji 用 Fluent。
InlineSpan gvChatBubbleCaptionRich(
  String text,
  Color fg, {
  double fontSize = GvTypographyScale.chatCaption,
}) {
  final base = _gvChatBubbleCaptionBase(fg, fontSize: fontSize);
  final plain = _gvBubblePlainStyleForPlatform(base);
  final fluent = gvFluentEmojiClusterTextStyle(base);
  return TextSpan(
    style: plain,
    children: gvTextSpansWithFluentEmojiWhitelist(text, plain, fluent),
  );
}

/// 聊天室底部 [TextField]（**非 iOS** 或 **未**使用 [GvChatComposerEditingController] 时）。
///
/// iOS 请使用 [GvChatComposerEditingController] + 裸 [TextStyle]（仅字号/行高/色），由 [buildTextSpan] 按段上 Fluent。
TextStyle gvChatComposerTextFieldStyle(TextStyle base) {
  if (kIsWeb) {
    return gvWithFluentEmojiFallback(
      base.copyWith(
        fontFamily: kGvGlobalUIFontFamily,
        fontFamilyFallback: kGvGlobalUIFontFallbacks,
      ),
    );
  }
  if (Platform.isIOS) {
    return base.copyWith(
      fontFamily: gvIosChatUiFontFamily,
      fontFeatures: const [FontFeature.proportionalFigures()],
      fontFamilyFallback: const <String>[],
    );
  }
  return gvWithFluentEmojiFallback(
    base.copyWith(
      fontFamily: kGvGlobalUIFontFamily,
      fontFamilyFallback: kGvGlobalUIFontFallbacks,
    ),
  );
}

/// 表情选择面板内 [Text] 样式：优先 Fluent Emoji TTF，再回退系统彩色表情字体。
TextStyle gvEmojiPickerCellStyle({double fontSize = 26}) {
  return _gvEmojiPickerStyleCache.putIfAbsent('$fontSize', () {
    return TextStyle(
      fontSize: fontSize,
      height: 1,
      fontFamily: kGvFluentEmojiFontFamily,
      fontFamilyFallback: const [
        'Apple Color Emoji',
        'Segoe UI Emoji',
        'Noto Color Emoji',
      ],
    );
  });
}
