import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';

import '../core/unicode_emoji_palette.dart';

/// iOS 聊天输入：单一 [TextStyle] 无法既避免 Fluent 影响数字、又让白名单 emoji 用 Fluent。
/// 通过重写 [buildTextSpan] 与气泡相同的「按 grapheme 切段」逻辑，数字走 [gvIosChatUiFontFamily]，emoji 单独 [gvFluentEmojiClusterTextStyle]。
class GvChatComposerEditingController extends TextEditingController {
  bool get _useIosRichSpan =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (!_useIosRichSpan) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }

    assert(!value.composing.isValid ||
        !withComposing ||
        value.isComposingRangeValid);

    final composingRegionOutOfRange =
        !value.isComposingRangeValid || !withComposing;

    final base = style ?? const TextStyle();
    final plainStyle = base.copyWith(
      fontFamily: gvIosChatUiFontFamily,
      fontFeatures: const [FontFeature.proportionalFigures()],
      fontFamilyFallback: const <String>[],
    );
    final fluentStyle = gvFluentEmojiClusterTextStyle(
      TextStyle(
        color: base.color,
        fontSize: base.fontSize,
        height: base.height,
        letterSpacing: base.letterSpacing,
      ),
    );

    List<InlineSpan> spansForSegment(
      String segment,
      TextStyle? composingExtra,
    ) {
      if (segment.isEmpty) return const <InlineSpan>[];
      final parts = gvTextSpansWithFluentEmojiWhitelist(
        segment,
        plainStyle,
        fluentStyle,
      );
      if (composingExtra == null) return parts;
      return parts.map((span) {
        final merged = (span.style ?? plainStyle).merge(composingExtra);
        return TextSpan(
          text: span.text,
          style: merged,
          children: span.children,
        );
      }).toList();
    }

    if (composingRegionOutOfRange) {
      return TextSpan(
        style: plainStyle,
        children:
            gvTextSpansWithFluentEmojiWhitelist(text, plainStyle, fluentStyle),
      );
    }

    const underlineStyle = TextStyle(decoration: TextDecoration.underline);
    final before = value.composing.textBefore(value.text);
    final inside = value.composing.textInside(value.text);
    final after = value.composing.textAfter(value.text);

    return TextSpan(
      style: plainStyle,
      children: [
        ...spansForSegment(before, null),
        ...spansForSegment(inside, underlineStyle),
        ...spansForSegment(after, null),
      ],
    );
  }
}
