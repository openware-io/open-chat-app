import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:open_chat_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:open_ui/open_ui.dart';
import 'package:provider/provider.dart';

import '../app/app_routes.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/open_toast.dart';
import '../services/api_client.dart';
import '../services/im_api.dart';
import '../widgets/open_nav_bar.dart';

/// 忘记密码：支持三种找回方式——手机号(短信验证码)、邮箱(重置链接)、密保问题。
/// 手机号与密保问题在本地完成重置；邮箱走既有重置令牌链路。
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _ForgotMethod { phone, email, securityQuestion }

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  _ForgotMethod _method = _ForgotMethod.phone;
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _question = TextEditingController();
  final _answer = TextEditingController();
  final _newPassword = TextEditingController();
  bool _smsSent = false;
  bool _submitting = false;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    _email.dispose();
    _username.dispose();
    _question.dispose();
    _answer.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    final v = value.trim();
    if (v.isEmpty) return false;
    final at = v.indexOf('@');
    final dot = v.lastIndexOf('.');
    return at > 0 && dot > at + 1 && dot < v.length - 1;
  }

  bool _validNewPassword(String value) => value.length >= 6 && value.length <= 128;

  Future<void> _sendSms() async {
    final l10n = AppLocalizations.of(context)!;
    final phone = _phone.text.trim();
    if (phone.isEmpty) {
      GvToast.show(context, l10n.gvFaForgotPhoneRequired);
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await context.read<ImApi>().forgotPasswordBySms(phone: phone);
      if (!mounted) return;
      setState(() => _smsSent = true);
      GvToast.show(context, l10n.gvFaForgotSmsCodeSent);
    } catch (e) {
      if (mounted) {
        GvToast.show(context, context.read<ApiClient>().extractErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _resetBySms() async {
    final l10n = AppLocalizations.of(context)!;
    final phone = _phone.text.trim();
    final code = _code.text.trim();
    final newPassword = _newPassword.text;
    if (phone.isEmpty) {
      GvToast.show(context, l10n.gvFaResetPhoneRequired);
      return;
    }
    if (code.isEmpty) {
      GvToast.show(context, l10n.gvFaResetSmsCodeRequired);
      return;
    }
    if (!_validNewPassword(newPassword)) {
      GvToast.show(context, l10n.resetPasswordPasswordRequired);
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await context.read<ImApi>().resetPasswordBySms(
          phone: phone, code: code, newPassword: newPassword);
      if (!mounted) return;
      GvToast.show(context, l10n.resetPasswordDone);
      context.go(AppRoutes.login);
    } catch (e) {
      if (mounted) {
        GvToast.show(context, context.read<ApiClient>().extractErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _sendEmail() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _email.text.trim();
    if (email.isEmpty) {
      GvToast.show(context, l10n.forgotPasswordEmailRequired);
      return;
    }
    if (!_isValidEmail(email)) {
      GvToast.show(context, l10n.forgotPasswordEmailInvalid);
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await context.read<ImApi>().forgotPassword(email: email);
      if (!mounted) return;
      GvToast.show(context, l10n.forgotPasswordSent);
    } catch (e) {
      if (mounted) {
        GvToast.show(context, context.read<ApiClient>().extractErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _resetBySecurityQuestion() async {
    final l10n = AppLocalizations.of(context)!;
    final username = _username.text.trim();
    final question = _question.text.trim();
    final answer = _answer.text.trim();
    final newPassword = _newPassword.text;
    if (username.isEmpty) {
      GvToast.show(context, l10n.gvFaResetUsernameRequired);
      return;
    }
    if (question.isEmpty) {
      GvToast.show(context, l10n.gvFaResetSecurityQuestionRequired);
      return;
    }
    if (answer.isEmpty) {
      GvToast.show(context, l10n.gvFaResetSecurityAnswerRequired);
      return;
    }
    if (!_validNewPassword(newPassword)) {
      GvToast.show(context, l10n.resetPasswordPasswordRequired);
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await context.read<ImApi>().resetPasswordBySecurityQuestion(
          username: username,
          question: question,
          answer: answer,
          newPassword: newPassword);
      if (!mounted) return;
      GvToast.show(context, l10n.resetPasswordDone);
      context.go(AppRoutes.login);
    } catch (e) {
      if (mounted) {
        GvToast.show(context, context.read<ApiClient>().extractErrorMessage(e));
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
        title: l10n.forgotPasswordTitle,
        showBack: true,
        onBack: () => context.go(AppRoutes.login),
      ),
      body: ListView(
        padding: const EdgeInsets.all(GvSpacing.page),
        children: [
          SegmentedButton<_ForgotMethod>(
            segments: [
              ButtonSegment(
                  value: _ForgotMethod.phone,
                  label: Text(l10n.gvFaForgotMethodPhone)),
              ButtonSegment(
                  value: _ForgotMethod.email,
                  label: Text(l10n.gvFaForgotMethodEmail)),
              ButtonSegment(
                  value: _ForgotMethod.securityQuestion,
                  label: Text(l10n.gvFaForgotMethodSecurityQuestion)),
            ],
            selected: {_method},
            onSelectionChanged: (s) => setState(() {
              _method = s.first;
              _smsSent = false;
            }),
          ),
          const SizedBox(height: GvSpacing.page),
          if (_method == _ForgotMethod.phone) ..._phoneFields(l10n),
          if (_method == _ForgotMethod.email) ..._emailFields(l10n),
          if (_method == _ForgotMethod.securityQuestion)
            ..._securityQuestionFields(l10n),
        ],
      ),
    );
  }

  List<Widget> _phoneFields(AppLocalizations l10n) {
    return [
      TextField(
        controller: _phone,
        keyboardType: TextInputType.phone,
        decoration: _borderlessField(context).copyWith(
          labelText: l10n.gvFaForgotPhoneHint,
        ),
      ),
      if (!_smsSent) ...[
        const SizedBox(height: GvSpacing.page),
        FilledButton(
          onPressed: _submitting ? null : _sendSms,
          child: Text(l10n.gvFaForgotSendSmsCode,
              style: GvTypography.navTitle(CupertinoColors.white)),
        ),
      ] else ...[
        const SizedBox(height: GvSpacing.page),
        TextField(
          controller: _code,
          keyboardType: TextInputType.number,
          decoration: _borderlessField(context).copyWith(
            labelText: l10n.gvFaResetSmsCodeHint,
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
          onSubmitted: (_) => _resetBySms(),
        ),
        const SizedBox(height: GvSpacing.page),
        FilledButton(
          onPressed: _submitting ? null : _resetBySms,
          child: Text(l10n.resetPasswordSubmit,
              style: GvTypography.navTitle(CupertinoColors.white)),
        ),
      ],
    ];
  }

  List<Widget> _emailFields(AppLocalizations l10n) {
    return [
      TextField(
        controller: _email,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        decoration: _borderlessField(context).copyWith(
          labelText: l10n.forgotPasswordEmailHint,
        ),
        onSubmitted: (_) => _sendEmail(),
      ),
      const SizedBox(height: GvSpacing.page),
      FilledButton(
        onPressed: _submitting ? null : _sendEmail,
        child: Text(l10n.forgotPasswordSubmit,
            style: GvTypography.navTitle(CupertinoColors.white)),
      ),
    ];
  }

  List<Widget> _securityQuestionFields(AppLocalizations l10n) {
    return [
      TextField(
        controller: _username,
        decoration: _borderlessField(context).copyWith(
          labelText: l10n.gvFaResetUsernameHint,
        ),
      ),
      const SizedBox(height: GvSpacing.page),
      TextField(
        controller: _question,
        decoration: _borderlessField(context).copyWith(
          labelText: l10n.gvFaResetSecurityQuestionHint,
        ),
      ),
      const SizedBox(height: GvSpacing.page),
      TextField(
        controller: _answer,
        decoration: _borderlessField(context).copyWith(
          labelText: l10n.gvFaResetSecurityAnswerHint,
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
        onSubmitted: (_) => _resetBySecurityQuestion(),
      ),
      const SizedBox(height: GvSpacing.page),
      FilledButton(
        onPressed: _submitting ? null : _resetBySecurityQuestion,
        child: Text(l10n.resetPasswordSubmit,
            style: GvTypography.navTitle(CupertinoColors.white)),
      ),
    ];
  }
}
