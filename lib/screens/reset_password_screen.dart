import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:open_chat_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:gv_ui/gv_ui.dart';
import 'package:provider/provider.dart';

import '../app/app_routes.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/gv_toast.dart';
import '../services/api_client.dart';
import '../services/im_api.dart';
import '../widgets/gv_nav_bar.dart';

/// 重置密码：由邮件链接 token 进入（也支持手动输入 token），
/// 输入新密码 → `POST /auth/password/reset`。
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.initialToken});

  /// 邮件链接携带的短时令牌（可为 null，此时由用户手动输入）。
  final String? initialToken;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late final TextEditingController _token;
  final _newPassword = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _token = TextEditingController(text: widget.initialToken ?? '');
  }

  @override
  void dispose() {
    _token.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final token = _token.text.trim();
    final newPassword = _newPassword.text;
    if (token.isEmpty) {
      GvToast.show(context, l10n.resetPasswordTokenRequired);
      return;
    }
    if (newPassword.length < 6 || newPassword.length > 128) {
      GvToast.show(context, l10n.resetPasswordPasswordRequired);
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final api = context.read<ImApi>();
      await api.resetPassword(token: token, newPassword: newPassword);
      if (!mounted) return;
      GvToast.show(context, l10n.resetPasswordDone);
      context.go(AppRoutes.login);
    } catch (e) {
      if (mounted) {
        GvToast.show(
          context,
          context.read<ApiClient>().extractErrorMessage(e),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  InputDecoration _borderlessField(BuildContext context) {
    final fill = AppColors.bgSearchField.resolveFrom(context);
    return InputDecoration(
      filled: true,
      fillColor: fill,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GvRadii.input),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GvRadii.input),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GvRadii.input),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: GvNavBar(
        title: l10n.resetPasswordTitle,
        showBack: true,
        onBack: () => context.go(AppRoutes.login),
      ),
      body: ListView(
        padding: const EdgeInsets.all(GvSpacing.page),
        children: [
          TextField(
            controller: _token,
            decoration: _borderlessField(context).copyWith(
              labelText: l10n.resetPasswordTokenHint,
            ),
          ),
          const SizedBox(height: GvSpacing.page),
          TextField(
            controller: _newPassword,
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            decoration: _borderlessField(context).copyWith(
              labelText: l10n.resetPasswordNewPasswordHint,
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: GvSpacing.page),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: Text(
              l10n.resetPasswordSubmit,
              style: GvTypography.navTitle(CupertinoColors.white),
            ),
          ),
        ],
      ),
    );
  }
}
