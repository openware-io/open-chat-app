import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:open_chat_app/l10n/app_localizations.dart';

import '../core/app_colors.dart';
import '../core/legal_urls.dart';
import '../screens/protocol_webview_screen.dart';
import 'package:open_ui/open_ui.dart' show GvTypography;

/// 登录/注册页：已阅读并同意用户协议与隐私政策。
class GvAuthAgreementCheckbox extends StatelessWidget {
  const GvAuthAgreementCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.textColor,
    this.linkColor,
    this.checkboxBorderColor,
    this.checkboxCheckedFillColor,
    this.checkboxCheckColor,
    this.checkboxKey,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final Color? textColor;
  final Color? linkColor;

  /// 未勾选时边框颜色（登录深色背景请传浅色）。
  final Color? checkboxBorderColor;
  final Color? checkboxCheckedFillColor;
  final Color? checkboxCheckColor;
  final Key? checkboxKey;

  static const double _fontSize = 13;
  static const double _lineHeight = 1.3;
  static const double _checkboxSize = 18;

  static double get _textLineHeight => _fontSize * _lineHeight;

  CheckboxThemeData _checkboxTheme(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final border =
        checkboxBorderColor ?? scheme.onSurface.withValues(alpha: 0.45);
    final checkedFill =
        checkboxCheckedFillColor ?? AppColors.primary.resolveFrom(context);
    final check = checkboxCheckColor ?? Colors.white;

    return CheckboxThemeData(
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: WidgetStateBorderSide.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return BorderSide(color: checkedFill, width: 1.5);
        }
        return BorderSide(color: border, width: 1.5);
      }),
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return checkedFill;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(check),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final resolvedText = textColor ??
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65);
    final resolvedLink = linkColor ?? AppColors.primary.resolveFrom(context);
    final textStyle = GvTypography.caption(resolvedText);
    final textTopInset = (_checkboxSize - _textLineHeight) / 2;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _checkboxSize,
          height: _checkboxSize,
          child: Theme(
            data: Theme.of(context).copyWith(
              checkboxTheme: _checkboxTheme(context),
            ),
            child: Checkbox(
              key: checkboxKey,
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: textTopInset > 0 ? textTopInset : 0),
            child: Text.rich(
              TextSpan(
                style: textStyle,
                children: [
                  TextSpan(text: l10n.authAgreementPrefix),
                  TextSpan(
                    text: l10n.authAgreementUserTerms,
                    style: TextStyle(color: resolvedLink),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _openUserAgreement(context, l10n),
                  ),
                  TextSpan(text: l10n.authAgreementAnd),
                  TextSpan(
                    text: l10n.authAgreementPrivacy,
                    style: TextStyle(color: resolvedLink),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _openPrivacyPolicy(context, l10n),
                  ),
                ],
              ),
              strutStyle: const StrutStyle(
                fontSize: _fontSize,
                height: _lineHeight,
                forceStrutHeight: true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openUserAgreement(BuildContext context, AppLocalizations l10n) {
    ProtocolWebViewScreen.open(
      context,
      title: l10n.authAgreementUserTerms,
      url: LegalUrls.userAgreement,
    );
  }

  void _openPrivacyPolicy(BuildContext context, AppLocalizations l10n) {
    ProtocolWebViewScreen.open(
      context,
      title: l10n.authAgreementPrivacy,
      url: LegalUrls.privacyPolicy,
    );
  }
}
