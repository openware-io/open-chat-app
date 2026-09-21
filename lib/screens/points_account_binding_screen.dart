import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gv_ui/gv_ui.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/gv_automation_keys.dart';
import '../core/gv_toast.dart';
import '../l10n/app_localizations.dart';
import '../models/points_account_binding.dart';
import '../widgets/gv_nav_bar.dart';

class PointsAccountBindingScreen extends StatefulWidget {
  const PointsAccountBindingScreen({
    super.key,
    this.initialBinding,
  });

  final PointsAccountBinding? initialBinding;

  @override
  State<PointsAccountBindingScreen> createState() =>
      _PointsAccountBindingScreenState();
}

class _PointsAccountBindingScreenState
    extends State<PointsAccountBindingScreen> {
  static const _mockVerificationCode = '548682';
  static const _mockPassword = '123456';

  late PointsAccountType _type;
  late PhoneCountry _phoneCountry;
  final _accountController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  Timer? _countdownTimer;
  bool _isVerifying = false;
  bool _accountHasError = false;
  bool _otpHasError = false;
  bool _passwordHasError = false;
  bool _passwordObscured = true;
  int _countdown = 59;

  @override
  void initState() {
    super.initState();
    _type = widget.initialBinding?.type ?? PointsAccountType.phone;
    _phoneCountry = kPhoneCountries.first;
    _otpController.addListener(_handleOtpChanged);
    _passwordController.addListener(_handlePasswordChanged);
    _otpFocusNode.addListener(_handleOtpFocusChanged);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _accountController.dispose();
    _otpController
      ..removeListener(_handleOtpChanged)
      ..dispose();
    _passwordController
      ..removeListener(_handlePasswordChanged)
      ..dispose();
    _otpFocusNode
      ..removeListener(_handleOtpFocusChanged)
      ..dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _handleOtpChanged() {
    if (!mounted) return;
    setState(() {
      _otpHasError = false;
    });
  }

  void _handleOtpFocusChanged() {
    if (mounted) setState(() {});
  }

  void _handlePasswordChanged() {
    if (!mounted) return;
    setState(() => _passwordHasError = false);
  }

  void _selectType(PointsAccountType value) {
    if (_type == value) return;
    setState(() {
      _type = value;
      _accountHasError = false;
      _accountController.clear();
    });
  }

  Future<void> _selectPhoneCountry() async {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final searchController = TextEditingController();
    final selected = await showModalBottomSheet<PhoneCountry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final keyword = searchController.text.trim().toLowerCase();
            final countries = kPhoneCountries.where((country) {
              if (keyword.isEmpty) return true;
              return country.nameFor(locale).toLowerCase().contains(keyword) ||
                  country.nameZh.contains(keyword) ||
                  country.nameEn.toLowerCase().contains(keyword) ||
                  country.dialCode.contains(keyword);
            }).toList();
            return SafeArea(
              child: Container(
                height: MediaQuery.sizeOf(context).height * 0.78,
                decoration: BoxDecoration(
                  color: AppColors.bgPage.resolveFrom(context),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.pointsAccountSelectCountry,
                              style: GvTypography.title(
                                AppColors.textPrimary.resolveFrom(context),
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            tooltip: l10n.commonClose,
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: TextField(
                        controller: searchController,
                        autofocus: true,
                        onChanged: (_) => setSheetState(() {}),
                        decoration: InputDecoration(
                          hintText: l10n.pointsAccountSearchCountry,
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor:
                              AppColors.bgSearchField.resolveFrom(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(GvRadii.input),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: countries.isEmpty
                          ? Center(
                              child: Text(
                                l10n.pointsAccountNoCountryResults,
                                style: GvTypography.caption(
                                  AppColors.textSecondary.resolveFrom(context),
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                              itemCount: countries.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                indent: 58,
                              ),
                              itemBuilder: (context, index) {
                                final country = countries[index];
                                final isSelected =
                                    country.code == _phoneCountry.code;
                                return ListTile(
                                  leading: Text(
                                    country.flag,
                                    style: const TextStyle(fontSize: 23),
                                  ),
                                  title: Text(country.nameFor(locale)),
                                  subtitle: Text(country.dialCode),
                                  trailing: isSelected
                                      ? Icon(
                                          Icons.check,
                                          color: AppColors.primary
                                              .resolveFrom(context),
                                        )
                                      : null,
                                  onTap: () => Navigator.pop(context, country),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    searchController.dispose();
    if (selected != null && mounted) {
      setState(() {
        _phoneCountry = selected;
        _accountHasError = false;
      });
    }
  }

  void _continueToVerification() {
    final isValid = _type == PointsAccountType.phone
        ? isValidPhoneForCountry(_phoneCountry, _accountController.text)
        : isValidPointsAccount(_type, _accountController.text);
    if (!isValid) {
      setState(() => _accountHasError = true);
      return;
    }

    setState(() {
      _isVerifying = true;
      _otpHasError = false;
      _passwordHasError = false;
      _passwordObscured = true;
      _otpController.clear();
      _passwordController.clear();
    });
    final usesPassword = _type == PointsAccountType.account;
    if (!usesPassword) {
      _startCountdown();
      GvToast.show(
        context,
        AppLocalizations.of(context)!.pointsAccountCodeSent,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (usesPassword) {
        _passwordFocusNode.requestFocus();
      } else {
        _otpFocusNode.requestFocus();
      }
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _countdown = 59);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown <= 1) {
        timer.cancel();
        setState(() => _countdown = 0);
      } else {
        setState(() => _countdown -= 1);
      }
    });
  }

  void _resendCode() {
    if (_countdown > 0) return;
    _otpController.clear();
    _startCountdown();
    _otpFocusNode.requestFocus();
    GvToast.show(
      context,
      AppLocalizations.of(context)!.pointsAccountCodeResent,
    );
  }

  void _handleBack() {
    if (_isVerifying) {
      _countdownTimer?.cancel();
      setState(() {
        _isVerifying = false;
        _otpHasError = false;
        _passwordHasError = false;
        _otpController.clear();
        _passwordController.clear();
      });
      return;
    }
    Navigator.maybePop(context);
  }

  Future<void> _confirmBinding() async {
    if (_type == PointsAccountType.account) {
      if (_passwordController.text != _mockPassword) {
        setState(() => _passwordHasError = true);
        _passwordFocusNode.requestFocus();
        return;
      }
    } else {
      if (_otpController.text != _mockVerificationCode) {
        setState(() => _otpHasError = true);
        _otpFocusNode.requestFocus();
        return;
      }
    }

    _countdownTimer?.cancel();
    final result = PointsAccountBinding(
      type: _type,
      account: _accountController.text.trim(),
    );
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              margin: const EdgeInsets.only(bottom: GvSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.success.resolveFrom(context).withValues(
                      alpha: 0.12,
                    ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.check,
                size: 34,
                color: AppColors.success.resolveFrom(context),
              ),
            ),
            Text(
              l10n.pointsAccountBindSuccess,
              textAlign: TextAlign.center,
              style: GvTypography.title(
                AppColors.textPrimary.resolveFrom(context),
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          l10n.pointsAccountBindSuccessDescription,
          textAlign: TextAlign.center,
          style: GvTypography.caption(
            AppColors.textSecondary.resolveFrom(context),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: FilledButton(
              key: GvAutomationKeys.pointsAccountSuccessReturn,
              onPressed: () => Navigator.pop(dialogContext),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(l10n.pointsAccountReturnToProfile),
            ),
          ),
        ],
      ),
    );
    if (mounted) Navigator.pop(context, result);
  }

  String _typeLabel(AppLocalizations l10n, PointsAccountType type) =>
      switch (type) {
        PointsAccountType.phone => l10n.pointsAccountTypePhone,
        PointsAccountType.email => l10n.pointsAccountTypeEmail,
        PointsAccountType.account => l10n.pointsAccountTypeAccount,
      };

  String _inputHint(AppLocalizations l10n) => switch (_type) {
        PointsAccountType.phone => l10n.pointsAccountPhoneHint,
        PointsAccountType.email => l10n.pointsAccountEmailHint,
        PointsAccountType.account => l10n.pointsAccountUsernameHint,
      };

  String _invalidMessage(AppLocalizations l10n) => switch (_type) {
        PointsAccountType.phone => l10n.pointsAccountPhoneInvalidForCountry(
            _phoneCountry.nameFor(
              Localizations.localeOf(context).languageCode,
            ),
            phoneNumberLengthLabel(_phoneCountry),
          ),
        PointsAccountType.email => l10n.pointsAccountEmailInvalid,
        PointsAccountType.account => l10n.pointsAccountUsernameInvalid,
      };

  String _deliveryHint(AppLocalizations l10n) => switch (_type) {
        PointsAccountType.phone => l10n.pointsAccountCodeToPhone,
        PointsAccountType.email => l10n.pointsAccountCodeToEmail,
        PointsAccountType.account => l10n.pointsAccountPasswordNextHint,
      };

  TextInputType get _keyboardType => switch (_type) {
        PointsAccountType.phone => TextInputType.phone,
        PointsAccountType.email => TextInputType.emailAddress,
        PointsAccountType.account => TextInputType.text,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = AppColors.primary.resolveFrom(context);
    return PopScope(
      canPop: !_isVerifying,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isVerifying) _handleBack();
      },
      child: Scaffold(
        key: GvAutomationKeys.pointsAccountBindingScreen,
        backgroundColor: gvPageScaffoldBackground(context),
        appBar: GvNavBar(
          title: _isVerifying
              ? (_type == PointsAccountType.account
                  ? l10n.pointsAccountPasswordVerificationTitle
                  : l10n.pointsAccountVerificationTitle)
              : l10n.pointsAccountBindingTitle,
          showBack: true,
          onBack: _handleBack,
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _isVerifying
              ? _buildVerificationStep(l10n, primary)
              : _buildAccountStep(l10n, primary),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(
            GvSpacing.page,
            GvSpacing.sm,
            GvSpacing.page,
            GvSpacing.page,
          ),
          child: FilledButton(
            key: _isVerifying
                ? GvAutomationKeys.pointsAccountConfirm
                : GvAutomationKeys.pointsAccountRequestCode,
            onPressed: _isVerifying
                ? (_type == PointsAccountType.account
                    ? (_passwordController.text.length >= 6
                        ? _confirmBinding
                        : null)
                    : (_otpController.text.length == 6
                        ? _confirmBinding
                        : null))
                : _continueToVerification,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: Text(
              _isVerifying
                  ? l10n.pointsAccountConfirmBinding
                  : (_type == PointsAccountType.account
                      ? l10n.pointsAccountEnterPassword
                      : l10n.pointsAccountRequestCode),
              style: GvTypography.navTitle(CupertinoColors.white).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountStep(AppLocalizations l10n, Color primary) {
    final isReplacing = widget.initialBinding != null;
    return ListView(
      key: const ValueKey('points-account-step'),
      padding: const EdgeInsets.fromLTRB(
        GvSpacing.lg,
        24,
        GvSpacing.lg,
        GvSpacing.page,
      ),
      children: [
        _StepHeader(
          current: l10n.pointsAccountStepAccount,
          next: l10n.pointsAccountStepVerify,
        ),
        const SizedBox(height: 24),
        Text(
          isReplacing
              ? l10n.pointsAccountReplaceHeading
              : l10n.pointsAccountChooseHeading,
          style: GvTypography.title(
            AppColors.textPrimary.resolveFrom(context),
          ).copyWith(fontSize: 25, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: GvSpacing.xs),
        Text(
          isReplacing
              ? l10n.pointsAccountReplaceDescription
              : l10n.pointsAccountChooseDescription,
          style: GvTypography.caption(
            AppColors.textSecondary.resolveFrom(context),
          ),
        ),
        const SizedBox(height: 22),
        _AccountTypeTabs(
          selected: _type,
          labelFor: (type) => _typeLabel(l10n, type),
          onSelected: _selectType,
        ),
        const SizedBox(height: 22),
        Text(
          _typeLabel(l10n, _type),
          style: GvTypography.caption(
            AppColors.textPrimary.resolveFrom(context),
          ).copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: GvSpacing.sm),
        TextField(
          key: GvAutomationKeys.pointsAccountInput,
          controller: _accountController,
          keyboardType: _keyboardType,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: (_) {
            if (_accountHasError) setState(() => _accountHasError = false);
          },
          onSubmitted: (_) => _continueToVerification(),
          decoration: InputDecoration(
            hintText: _inputHint(l10n),
            prefixIcon: _type == PointsAccountType.phone
                ? _PhoneCountryPrefix(
                    country: _phoneCountry,
                    onTap: _selectPhoneCountry,
                  )
                : null,
            prefixIconConstraints: _type == PointsAccountType.phone
                ? const BoxConstraints(minWidth: 132, maxWidth: 132)
                : null,
            errorText: _accountHasError ? _invalidMessage(l10n) : null,
            helperText: _accountHasError ? null : _deliveryHint(l10n),
            fillColor: _accountHasError
                ? AppColors.danger.resolveFrom(context).withValues(alpha: 0.08)
                : AppColors.bgSearchField.resolveFrom(context),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GvRadii.input),
              borderSide: BorderSide(color: primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GvRadii.input),
              borderSide: BorderSide(
                color: AppColors.danger.resolveFrom(context),
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GvRadii.input),
              borderSide: BorderSide(
                color: AppColors.danger.resolveFrom(context),
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: GvSpacing.lg),
        Container(
          padding: const EdgeInsets.all(GvSpacing.page),
          decoration: BoxDecoration(
            color: AppColors.bgWhite.resolveFrom(context),
            borderRadius: BorderRadius.circular(GvRadii.card),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.lock_keyhole, size: 18, color: primary),
              const SizedBox(width: GvSpacing.sm),
              Expanded(
                child: Text(
                  l10n.pointsAccountPrivacyNote,
                  style: GvTypography.small(
                    AppColors.textSecondary.resolveFrom(context),
                  ).copyWith(height: 1.55),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationStep(AppLocalizations l10n, Color primary) {
    if (_type == PointsAccountType.account) {
      return _buildPasswordVerificationStep(l10n, primary);
    }
    final masked = maskPointsAccount(_type, _accountController.text);
    return ListView(
      key: const ValueKey('points-verify-step'),
      padding: const EdgeInsets.fromLTRB(
        GvSpacing.lg,
        28,
        GvSpacing.lg,
        GvSpacing.page,
      ),
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(GvRadii.cardLg),
          ),
          child: Icon(LucideIcons.mail_check, size: 27, color: primary),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.pointsAccountEnterCode,
          style: GvTypography.title(
            AppColors.textPrimary.resolveFrom(context),
          ).copyWith(fontSize: 25, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: GvSpacing.sm),
        Text.rich(
          TextSpan(
            text: '${l10n.pointsAccountCodeSentTo}\n',
            children: [
              TextSpan(
                text: _type == PointsAccountType.phone
                    ? '${_phoneCountry.dialCode} $masked'
                    : masked,
                style: TextStyle(
                  color: AppColors.textPrimary.resolveFrom(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          style: GvTypography.caption(
            AppColors.textSecondary.resolveFrom(context),
          ).copyWith(height: 1.7),
        ),
        const SizedBox(height: 28),
        _OtpField(
          controller: _otpController,
          focusNode: _otpFocusNode,
          hasError: _otpHasError,
        ),
        const SizedBox(height: GvSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _otpHasError
                    ? l10n.pointsAccountCodeInvalid
                    : l10n.pointsAccountCodeExpiryHint,
                style: GvTypography.small(
                  _otpHasError
                      ? AppColors.danger.resolveFrom(context)
                      : AppColors.textSecondary.resolveFrom(context),
                ),
              ),
            ),
            TextButton(
              onPressed: _countdown == 0 ? _resendCode : null,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _countdown == 0
                    ? l10n.pointsAccountResendCode
                    : l10n.pointsAccountResendCountdown(_countdown),
              ),
            ),
          ],
        ),
        const SizedBox(height: GvSpacing.lg),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: GvSpacing.page,
            vertical: GvSpacing.page,
          ),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(GvRadii.card),
          ),
          child: Text.rich(
            TextSpan(
              text: '${l10n.pointsAccountDemoCodeLabel} ',
              children: const [
                TextSpan(
                  text: _mockVerificationCode,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            style: GvTypography.caption(primary),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordVerificationStep(
    AppLocalizations l10n,
    Color primary,
  ) {
    final masked = maskPointsAccount(_type, _accountController.text);
    return ListView(
      key: const ValueKey('points-password-step'),
      padding: const EdgeInsets.fromLTRB(
        GvSpacing.lg,
        28,
        GvSpacing.lg,
        GvSpacing.page,
      ),
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(GvRadii.cardLg),
          ),
          child: Icon(LucideIcons.lock_keyhole, size: 27, color: primary),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.pointsAccountPasswordHeading,
          style: GvTypography.title(
            AppColors.textPrimary.resolveFrom(context),
          ).copyWith(fontSize: 25, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: GvSpacing.sm),
        Text(
          l10n.pointsAccountPasswordDescription(masked),
          style: GvTypography.caption(
            AppColors.textSecondary.resolveFrom(context),
          ).copyWith(height: 1.7),
        ),
        const SizedBox(height: 28),
        TextField(
          key: GvAutomationKeys.pointsAccountPasswordInput,
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          obscureText: _passwordObscured,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          enableSuggestions: false,
          onSubmitted: (_) {
            if (_passwordController.text.length >= 6) _confirmBinding();
          },
          decoration: InputDecoration(
            hintText: l10n.pointsAccountPasswordHint,
            prefixIcon: const Icon(LucideIcons.lock_keyhole),
            suffixIcon: IconButton(
              tooltip: _passwordObscured
                  ? l10n.passwordShowTooltip
                  : l10n.passwordHideTooltip,
              onPressed: () => setState(
                () => _passwordObscured = !_passwordObscured,
              ),
              icon: Icon(
                _passwordObscured ? LucideIcons.eye : LucideIcons.eye_off,
              ),
            ),
            errorText:
                _passwordHasError ? l10n.pointsAccountPasswordInvalid : null,
            filled: true,
            fillColor: _passwordHasError
                ? AppColors.danger.resolveFrom(context).withValues(alpha: 0.08)
                : AppColors.bgSearchField.resolveFrom(context),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GvRadii.input),
              borderSide: BorderSide(color: primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GvRadii.input),
              borderSide: BorderSide(
                color: AppColors.danger.resolveFrom(context),
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GvRadii.input),
              borderSide: BorderSide(
                color: AppColors.danger.resolveFrom(context),
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: GvSpacing.lg),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: GvSpacing.page,
            vertical: GvSpacing.page,
          ),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(GvRadii.card),
          ),
          child: Text.rich(
            TextSpan(
              text: '${l10n.pointsAccountDemoPasswordLabel} ',
              children: const [
                TextSpan(
                  text: _mockPassword,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            style: GvTypography.caption(primary),
          ),
        ),
      ],
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.current, required this.next});

  final String current;
  final String next;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary.resolveFrom(context);
    return Row(
      children: [
        Text(
          current,
          style: GvTypography.small(primary).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Container(
          width: 34,
          height: 2,
          margin: const EdgeInsets.symmetric(horizontal: GvSpacing.sm),
          color: AppColors.border.resolveFrom(context),
        ),
        Text(
          next,
          style: GvTypography.small(
            AppColors.textSecondary.resolveFrom(context),
          ),
        ),
      ],
    );
  }
}

class _AccountTypeTabs extends StatelessWidget {
  const _AccountTypeTabs({
    required this.selected,
    required this.labelFor,
    required this.onSelected,
  });

  final PointsAccountType selected;
  final String Function(PointsAccountType type) labelFor;
  final ValueChanged<PointsAccountType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bgSearchField.resolveFrom(context),
        borderRadius: BorderRadius.circular(GvRadii.card),
      ),
      child: Row(
        children: PointsAccountType.values.map((type) {
          final isSelected = type == selected;
          return Expanded(
            child: Semantics(
              selected: isSelected,
              button: true,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: ValueKey('points-account-type-${type.name}'),
                  onTap: () => onSelected(type),
                  borderRadius: BorderRadius.circular(GvRadii.input),
                  child: Container(
                    alignment: Alignment.center,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.bgWhite.resolveFrom(context)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(GvRadii.input),
                      boxShadow: isSelected ? GvShadows.card : null,
                    ),
                    child: Text(
                      labelFor(type),
                      style: GvTypography.caption(
                        isSelected
                            ? AppColors.textPrimary.resolveFrom(context)
                            : AppColors.textSecondary.resolveFrom(context),
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PhoneCountryPrefix extends StatelessWidget {
  const _PhoneCountryPrefix({
    required this.country,
    required this.onTap,
  });

  final PhoneCountry country;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.horizontal(
        left: Radius.circular(GvRadii.input),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 12, right: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(country.flag, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 5),
            Text(
              country.dialCode,
              style: GvTypography.caption(
                AppColors.textPrimary.resolveFrom(context),
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down,
              size: 17,
              color: AppColors.textSecondary.resolveFrom(context),
            ),
            Container(
              width: 1,
              height: 23,
              margin: const EdgeInsets.only(left: 7),
              color: AppColors.border.resolveFrom(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpField extends StatelessWidget {
  const _OtpField({
    required this.controller,
    required this.focusNode,
    required this.hasError,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary.resolveFrom(context);
    final danger = AppColors.danger.resolveFrom(context);
    return Semantics(
      label: AppLocalizations.of(context)!.pointsAccountCodeFieldLabel,
      textField: true,
      child: GestureDetector(
        onTap: focusNode.requestFocus,
        child: SizedBox(
          height: 58,
          child: Stack(
            children: [
              Row(
                children: List.generate(6, (index) {
                  final digit = index < controller.text.length
                      ? controller.text[index]
                      : '';
                  final active = focusNode.hasFocus &&
                      index == controller.text.length.clamp(0, 5);
                  return Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      margin: EdgeInsets.only(right: index == 5 ? 0 : 7),
                      decoration: BoxDecoration(
                        color: hasError
                            ? danger.withValues(alpha: 0.08)
                            : AppColors.bgWhite.resolveFrom(context),
                        borderRadius: BorderRadius.circular(GvRadii.input),
                        border: Border.all(
                          color: hasError
                              ? danger
                              : active
                                  ? primary
                                  : Colors.transparent,
                          width: 1.5,
                        ),
                        boxShadow: GvShadows.card,
                      ),
                      child: Text(
                        digit,
                        style: GvTypography.title(
                          AppColors.textPrimary.resolveFrom(context),
                        ).copyWith(fontSize: 24, fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                }),
              ),
              Opacity(
                opacity: 0.01,
                child: TextField(
                  key: GvAutomationKeys.pointsAccountOtpInput,
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
