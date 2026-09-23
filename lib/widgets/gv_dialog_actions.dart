import 'package:flutter/material.dart';
import 'package:open_chat_app/l10n/app_localizations.dart';
import 'package:gv_ui/gv_ui.dart';

/// 统一 Alert / Confirm：底部微信式对半横条（左取消、右确定），单按钮为通栏。
///
/// 实现上**不用** [LayoutBuilder]：[AlertDialog] 会在 [IntrinsicWidth] 下对 actions 求固有尺寸，
/// LayoutBuilder 不支持，在 iOS 上会直接 assert（备注弹窗等）。
abstract final class GvDialogActions {
  static ButtonStyle cancelStyle(BuildContext context) {
    return GvDialogActionFooter.cancelStyle(context);
  }

  static ButtonStyle confirmStyle(BuildContext context) {
    return GvDialogActionFooter.confirmStyle(context);
  }

  /// 双按钮：顶部分割线 + 左右各半，中间竖线（微信样式）。
  static Widget weChatFooter(
    BuildContext context, {
    required VoidCallback onSecondary,
    required VoidCallback onPrimary,
    String? secondaryText,
    String? primaryText,
    Key? secondaryKey,
    Key? primaryKey,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final secondaryLabel = secondaryText ?? l10n.commonCancel;
    final primaryLabel = primaryText ?? l10n.commonConfirm;
    return GvDialogActionFooter.doubleAction(
      context,
      onSecondary: onSecondary,
      onPrimary: onPrimary,
      secondaryText: secondaryLabel,
      primaryText: primaryLabel,
      secondaryKey: secondaryKey,
      primaryKey: primaryKey,
    );
  }

  /// 单按钮：顶部分割线 + 通栏（如「知道了」）。
  static Widget weChatSingle(
    BuildContext context, {
    required VoidCallback onPressed,
    String? text,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final label = text ?? l10n.commonConfirm;
    return GvDialogActionFooter.singleAction(
      context,
      onPressed: onPressed,
      text: label,
    );
  }
}
