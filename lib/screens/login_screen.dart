import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_colors.dart';
import '../core/config.dart';
import '../core/open_automation_keys.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/call_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/friend_provider.dart';
import '../providers/group_provider.dart';
import '../services/local_network_preflight.dart';
import '../widgets/debug_server_settings.dart';
import '../widgets/open_auth_agreement_checkbox.dart';
import 'package:open_ui/open_ui.dart' show GvTypography;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialUsername});

  final String? initialUsername;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _user;
  final _pass = TextEditingController();
  final _passFocus = FocusNode();
  static const _rememberUsernameKey = 'im_remember_username';
  static const _lastUsernameKey = 'im_last_username';
  String? _error;
  bool _loading = false;
  bool _agreed = false;
  bool _rememberUsername = true;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _user = TextEditingController(text: widget.initialUsername);
    _restoreLoginPreferences();
  }

  Future<void> _restoreLoginPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_rememberUsernameKey) ?? true;
    final last = prefs.getString(_lastUsernameKey);
    if (!mounted) return;
    setState(() {
      _rememberUsername = remember;
      if (widget.initialUsername == null &&
          last != null &&
          last.isNotEmpty &&
          _user.text.isEmpty) {
        _user.text = last;
      }
    });
  }

  Future<void> _saveLoginPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberUsernameKey, _rememberUsername);
    if (_rememberUsername) {
      await prefs.setString(_lastUsernameKey, _user.text.trim());
    } else {
      await prefs.remove(_lastUsernameKey);
    }
  }

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    final l10n = AppLocalizations.of(context)!;
    FocusScope.of(context).unfocus();

    final formValid = _formKey.currentState?.validate() ?? false;
    if (!_agreed) {
      setState(() => _error = l10n.authAgreementRequired);
      return;
    }
    if (!formValid) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    var authenticated = false;
    try {
      await LocalNetworkPreflight.requestIfNeeded();
      await auth.login(_user.text.trim(), _pass.text);
      authenticated = true;
      TextInput.finishAutofillContext();
      await _saveLoginPreferences();

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
      if (!mounted) return;
      if (authenticated) {
        // Authentication succeeded; a local hydration failure must not put the
        // user back on the login form with an invalid "login failed" message.
        debugPrint('Post-login session initialization failed: $e');
        context.go('/chats');
      } else {
        final message = auth.apiError(e).trim();
        setState(() => _error = message.isEmpty
            ? '${l10n.loginServerUnreachable}: ${AppConfig.apiBase}'
            : message);
      }
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
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final kb = MediaQuery.viewInsetsOf(context).bottom;
              final scrollChild = ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 24),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        'assets/app_icon.png',
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.appTitle,
                      style: GvTypography.headline(Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.appSubtitle,
                      style: GvTypography.body(
                          Colors.white.withValues(alpha: 0.55)),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      l10n.loginWelcomeBack,
                      style: GvTypography.caption(
                          Colors.white.withValues(alpha: 0.75)),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: GvSpacing.page + GvSpacing.page,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Form(
                            key: _formKey,
                            child: AutofillGroup(
                              child: Column(
                                children: [
                                  _field(
                                    key: GvAutomationKeys.loginUsername,
                                    controller: _user,
                                    hint: l10n.loginUsernameHint,
                                    obscure: false,
                                    isFirst: true,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [
                                      AutofillHints.username
                                    ],
                                    onSubmitted: (_) =>
                                        _passFocus.requestFocus(),
                                  ),
                                  _field(
                                    key: GvAutomationKeys.loginPassword,
                                    controller: _pass,
                                    hint: l10n.loginPasswordHint,
                                    obscure: _obscurePassword,
                                    isFirst: false,
                                    focusNode: _passFocus,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [
                                      AutofillHints.password
                                    ],
                                    onSubmitted: (_) => _submit(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_error != null)
                            Semantics(
                              liveRegion: true,
                              child: Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.danger
                                      .withValues(alpha: 0.10),
                                  borderRadius:
                                      BorderRadius.circular(GvRadii.input),
                                  border: Border.all(
                                      color: AppColors.danger
                                          .withValues(alpha: 0.45)),
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.error_outline,
                                        size: 18,
                                        color: AppColors.danger),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: GvTypography.caption(
                                            AppColors.danger),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberUsername,
                                onChanged: _loading
                                    ? null
                                    : (value) => setState(() =>
                                        _rememberUsername = value ?? false),
                                side: BorderSide(
                                    color: Colors.white
                                        .withValues(alpha: 0.75)),
                                checkColor: Colors.white,
                                fillColor:
                                    WidgetStateProperty.resolveWith((states) {
                                  if (states
                                      .contains(WidgetState.selected)) {
                                    return AppColors.primary;
                                  }
                                  return Colors.transparent;
                                }),
                                visualDensity: VisualDensity.compact,
                              ),
                              Text(
                                l10n.loginRememberUsername,
                                style: GvTypography.caption(
                                    Colors.white.withValues(alpha: 0.75)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: FilledButton(
                              key: GvAutomationKeys.loginSubmit,
                              onPressed: _loading ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                disabledBackgroundColor:
                                    AppColors.primary.withValues(alpha: 0.5),
                              ),
                              child: _loading
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(l10n.loginLoading),
                                      ],
                                    )
                                  : Text(l10n.loginButton),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _loading
                                  ? null
                                  : () => context.go('/forgot-password'),
                              child: Text(
                                l10n.forgotPassword,
                                style:
                                    GvTypography.caption(AppColors.primary),
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
                            textColor: Colors.white.withValues(alpha: 0.78),
                            linkColor: AppColors.primary,
                            checkboxBorderColor:
                                Colors.white.withValues(alpha: 0.9),
                            checkboxCheckedFillColor: AppColors.primary,
                            checkboxCheckColor: Colors.white,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(l10n.loginNoAccount,
                                  style: GvTypography.caption(
                                      Colors.white.withValues(alpha: 0.55))),
                              TextButton(
                                onPressed: _loading
                                    ? null
                                    : () => context.go('/register'),
                                child: Text(l10n.loginRegister,
                                    style: GvTypography.caption(
                                        AppColors.primary)),
                              ),
                            ],
                          ),
                          const DebugServerFooter(),
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

  Widget _field({
    required Key key,
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required bool isFirst,
    required TextInputAction textInputAction,
    required List<String> autofillHints,
    required ValueChanged<String> onSubmitted,
    FocusNode? focusNode,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final radius = isFirst
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
      constraints: const BoxConstraints(minHeight: 52),
      child: TextFormField(
        key: key,
        controller: controller,
        focusNode: focusNode,
        enabled: !_loading,
        obscureText: obscure,
        keyboardType: TextInputType.text,
        textInputAction: textInputAction,
        textCapitalization: TextCapitalization.none,
        autocorrect: false,
        enableSuggestions: false,
        autofillHints: autofillHints,
        onFieldSubmitted: onSubmitted,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return isFirst
                ? l10n.loginUsernameRequired
                : l10n.loginPasswordRequired;
          }
          return null;
        },
        style: GvTypography.navTitle(Colors.white),
        decoration: InputDecoration(
          labelText: hint,
          hintText: hint,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
          floatingLabelStyle: const TextStyle(color: Colors.white),
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.10),
          border:
              OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: radius, borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.9), width: 1.4),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: const BorderSide(color: AppColors.danger, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: GvSpacing.page),
          suffixIcon: obscure
              ? IconButton(
                  tooltip: _obscurePassword
                      ? l10n.loginShowPassword
                      : l10n.loginHidePassword,
                  onPressed: _loading
                      ? null
                      : () => setState(
                          () => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
