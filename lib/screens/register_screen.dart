import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app/app_routes.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/local_network_preflight.dart';
import '../widgets/gv_auth_agreement_checkbox.dart';
import '../widgets/gv_nav_bar.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _email = TextEditingController();
  final _nick = TextEditingController();
  String? _error;
  bool _loading = false;
  bool _agreed = false;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    _email.dispose();
    _nick.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    final v = value.trim();
    if (v.isEmpty) return false;
    final at = v.indexOf('@');
    final dot = v.lastIndexOf('.');
    return at > 0 && dot > at + 1 && dot < v.length - 1;
  }

  static InputDecoration _inputDecoration(BuildContext context, String label) {
    final r = BorderRadius.circular(GvRadii.input);
    const side = BorderSide.none;
    final shape = OutlineInputBorder(borderRadius: r, borderSide: side);
    return InputDecoration(
      labelText: label,
      border: shape,
      enabledBorder: shape,
      focusedBorder: shape,
      errorBorder: shape,
      focusedErrorBorder: shape,
      disabledBorder: shape,
      filled: true,
      fillColor: AppColors.bgSearchField.resolveFrom(context),
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_user.text.isEmpty || _pass.text.isEmpty) {
      setState(() => _error = l10n.loginUsernamePasswordRequired);
      return;
    }
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = l10n.forgotPasswordEmailRequired);
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => _error = l10n.forgotPasswordEmailInvalid);
      return;
    }
    if (!_agreed) {
      setState(() => _error = l10n.authAgreementRequired);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    try {
      // 等待启动时的 iOS 网络授权预探测，避免注册 POST 被首次弹窗中断。
      await LocalNetworkPreflight.requestIfNeeded();
      final username = _user.text.trim();
      await auth.register(
          username, _pass.text, _email.text.trim(), _nick.text.trim());
      if (!mounted) return;
      context.go(AppRoutes.login, extra: username);
    } catch (e) {
      setState(() => _error = auth.apiError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: gvPageScaffoldBackground(context),
      body: Column(
        children: [
          GvNavBar(
            title: l10n.loginRegister,
            showBack: true,
            onBack: () => context.go(AppRoutes.login),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: double.infinity,
                ),
                child: ListView(
                  padding: const EdgeInsets.all(GvSpacing.page),
                  children: [
                    TextField(
                      controller: _user,
                      decoration: _inputDecoration(
                        context,
                        l10n.formLabelUsername,
                      ),
                    ),
                    const SizedBox(height: GvSpacing.page),
                    TextField(
                      controller: _pass,
                      obscureText: true,
                      decoration: _inputDecoration(
                        context,
                        l10n.formLabelPassword,
                      ),
                    ),
                    const SizedBox(height: GvSpacing.page),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: _inputDecoration(
                        context,
                        l10n.profileFieldEmail,
                      ),
                    ),
                    const SizedBox(height: GvSpacing.page),
                    TextField(
                      controller: _nick,
                      decoration: _inputDecoration(
                        context,
                        l10n.registerNicknameOptional,
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: GvSpacing.page),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: AppColors.danger.resolveFrom(context),
                        ),
                      ),
                    ],
                    const SizedBox(height: GvSpacing.page),
                    FilledButton(
                      onPressed: _loading || !_agreed ? null : _submit,
                      child: Text(
                        _loading ? l10n.registerSubmitting : l10n.loginRegister,
                      ),
                    ),
                    const SizedBox(height: GvSpacing.page),
                    GvAuthAgreementCheckbox(
                      value: _agreed,
                      onChanged: (v) => setState(() {
                        _agreed = v ?? false;
                        if (_agreed && _error == l10n.authAgreementRequired) {
                          _error = null;
                        }
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
