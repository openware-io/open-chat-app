import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/gv_automation_keys.dart';
import '../core/gv_toast.dart';
import '../providers/auth_provider.dart';
import 'package:gv_ui/gv_ui.dart' show GvTypography;
import '../widgets/gv_nav_bar.dart';

InputDecoration _borderlessField(
  BuildContext context, {
  required String labelText,
}) {
  final fill = AppColors.bgSearchField.resolveFrom(context);
  return InputDecoration(
    labelText: labelText,
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

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _pwdCurrent = TextEditingController();
  final _pwdNew = TextEditingController();
  final _pwdNew2 = TextEditingController();

  @override
  void dispose() {
    _pwdCurrent.dispose();
    _pwdNew.dispose();
    _pwdNew2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      key: GvAutomationKeys.changePasswordScreen,
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: GvNavBar(title: l10n.settingsChangePassword, showBack: true),
      body: ListView(
        padding: const EdgeInsets.all(GvSpacing.page),
        children: [
          TextField(
            controller: _pwdCurrent,
            obscureText: true,
            decoration: _borderlessField(context,
                labelText: l10n.changePasswordCurrentLabel),
            autofillHints: const [AutofillHints.password],
          ),
          const SizedBox(height: GvSpacing.page),
          TextField(
            controller: _pwdNew,
            obscureText: true,
            decoration: _borderlessField(
              context,
              labelText: l10n.changePasswordNewLabel,
            ),
            autofillHints: const [AutofillHints.newPassword],
          ),
          const SizedBox(height: GvSpacing.page),
          TextField(
            controller: _pwdNew2,
            obscureText: true,
            decoration: _borderlessField(context,
                labelText: l10n.changePasswordConfirmLabel),
            autofillHints: const [AutofillHints.newPassword],
          ),
          const SizedBox(height: GvSpacing.page),
          FilledButton(
            onPressed: () async {
              if (_pwdCurrent.text.isEmpty) {
                GvToast.show(
                  context,
                  l10n.toastEnterCurrentPassword,
                );
                return;
              }
              if (_pwdNew.text.length < 6) {
                GvToast.show(
                  context,
                  l10n.toastNewPasswordMinLength,
                );
                return;
              }
              if (_pwdNew.text != _pwdNew2.text) {
                GvToast.show(context, l10n.toastNewPasswordMismatch);
                return;
              }
              try {
                await auth.changePassword(
                  currentPassword: _pwdCurrent.text,
                  newPassword: _pwdNew.text,
                );
                _pwdCurrent.clear();
                _pwdNew.clear();
                _pwdNew2.clear();
                if (context.mounted) {
                  GvToast.show(
                    context,
                    l10n.toastPasswordUpdated,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  GvToast.show(context, auth.apiError(e));
                }
              }
            },
            child: Text(
              l10n.changePasswordSubmit,
              style: GvTypography.navTitle(CupertinoColors.white),
            ),
          ),
        ],
      ),
    );
  }
}
