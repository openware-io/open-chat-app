import 'package:flutter/material.dart';
import 'package:gv_chat_app/l10n/app_localizations.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/gv_automation_keys.dart';
import 'package:gv_ui/gv_ui.dart' show GvTypography;
import '../providers/auth_provider.dart';
import '../providers/call_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/friend_provider.dart';
import '../providers/group_provider.dart';
import '../services/local_network_preflight.dart';
import '../widgets/gv_auth_agreement_checkbox.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialUsername});

  final String? initialUsername;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _user;
  final _pass = TextEditingController();
  String? _error;
  bool _loading = false;
  bool _agreed = false;

  @override
  void initState() {
    super.initState();
    _user = TextEditingController(text: widget.initialUsername);
  }

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_user.text.isEmpty || _pass.text.isEmpty) {
      setState(() => _error = l10n.loginUsernamePasswordRequired);
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
      await LocalNetworkPreflight.requestIfNeeded();
      await auth.login(_user.text.trim(), _pass.text);
      if (!mounted) return;
      final call = context.read<CallProvider>();
      await call.reset();
      if (!mounted) return;
      context.read<ChatProvider>().resetForLogout();
      context.read<FriendProvider>().resetForLogout();
      context.read<GroupProvider>().resetForLogout();
      call.clearIcePrefetch();
      await context.read<ChatProvider>().hydrateFromDisk();
      if (mounted) context.go('/chats');
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
      key: GvAutomationKeys.loginScreen,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1C1C1E),
              Color(0xFF000000),
              Color(0xFF0A1628),
            ],
            stops: [0, 0.5, 1],
          ),
        ),
        // 【修改】仅顶部安全区；底部不预留 home indicator 区域。
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final kb = MediaQuery.viewInsetsOf(context).bottom;
              Widget scrollChild = ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 24),
                    Icon(LucideIcons.messages_square,
                        size: 56, color: Colors.white.withValues(alpha: 0.95)),
                    const SizedBox(height: 10),
                    Text(
                      l10n.appTitle,
                      style: GvTypography.headline(Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.appSubtitle,
                      style: GvTypography.body(
                          Colors.white.withValues(alpha: 0.4)),
                    ),
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: GvSpacing.page + GvSpacing.page,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _field(GvAutomationKeys.loginUsername, _user,
                              l10n.loginUsernameHint, false,
                              isFirst: true),
                          _field(GvAutomationKeys.loginPassword, _pass,
                              l10n.loginPasswordHint, true,
                              isFirst: false),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(_error!,
                                  style:
                                      GvTypography.caption(AppColors.danger)),
                            ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: FilledButton(
                              key: GvAutomationKeys.loginSubmit,
                              onPressed: _loading || !_agreed ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                disabledBackgroundColor:
                                    AppColors.primary.withValues(alpha: 0.5),
                              ),
                              child: Text(_loading
                                  ? l10n.loginLoading
                                  : l10n.loginButton),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.go('/forgot-password'),
                              child: Text(
                                l10n.forgotPassword,
                                style: GvTypography.caption(AppColors.primary),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GvAuthAgreementCheckbox(
                            checkboxKey: GvAutomationKeys.loginAgreement,
                            value: _agreed,
                            onChanged: (v) => setState(() {
                              _agreed = v ?? false;
                              if (_agreed &&
                                  _error == l10n.authAgreementRequired) {
                                _error = null;
                              }
                            }),
                            textColor: Colors.white.withValues(alpha: 0.65),
                            linkColor: AppColors.primary,
                            checkboxBorderColor:
                                Colors.white.withValues(alpha: 0.85),
                            checkboxCheckedFillColor: AppColors.primary,
                            checkboxCheckColor: Colors.white,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(l10n.loginNoAccount,
                                  style: GvTypography.caption(
                                      Colors.white.withValues(alpha: 0.4))),
                              TextButton(
                                onPressed: () => context.go('/register'),
                                child: Text(l10n.loginRegister,
                                    style: GvTypography.caption(
                                        AppColors.primary)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(bottom: kb + GvSpacing.page),
                child: scrollChild,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _field(Key key, TextEditingController c, String hint, bool obscure,
      {required bool isFirst}) {
    final r = isFirst
        ? const BorderRadius.vertical(
            top: Radius.circular(GvRadii.button),
            bottom: Radius.zero,
          )
        : const BorderRadius.vertical(
            top: Radius.zero,
            bottom: Radius.circular(GvRadii.button),
          );
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      height: 52,
      child: TextField(
        key: key,
        controller: c,
        obscureText: obscure,
        onSubmitted: (_) => _submit(),
        style: GvTypography.navTitle(Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.08),
          border:
              OutlineInputBorder(borderRadius: r, borderSide: BorderSide.none),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: GvSpacing.page),
        ),
      ),
    );
  }
}
