import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_ui/open_ui.dart' show GvTypography;

import '../../app/app_routes.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../widgets/open_nav_bar.dart';

/// B端（商家 / 门店）登录占位页。
///
/// 门店号 / 手机号 + 密码表单，暂无真实鉴权；提交后直接进入 KTV 看板。
class BusinessLoginScreen extends StatefulWidget {
  const BusinessLoginScreen({super.key});

  @override
  State<BusinessLoginScreen> createState() => _BusinessLoginScreenState();
}

class _BusinessLoginScreenState extends State<BusinessLoginScreen> {
  final _account = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _account.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_account.text.trim().isEmpty || _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入门店号 / 手机号和密码')),
      );
      return;
    }
    context.go(AppRoutes.ktvDashboard);
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.bgWhite.resolveFrom(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GvRadii.input),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: GvSpacing.fieldH,
        vertical: GvSpacing.fieldV,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageBg = gvPageScaffoldBackground(context);
    final primary = AppColors.textPrimary.resolveFrom(context);
    final secondary = AppColors.textSecondary.resolveFrom(context);
    final accent = AppColors.primary.resolveFrom(context);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: GvNavBar(
        title: 'B端登录',
        showBack: true,
        backgroundColor: pageBg,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(GvSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Icon(Icons.storefront, size: 56, color: accent),
            const SizedBox(height: 12),
            Text(
              '商家管理端',
              textAlign: TextAlign.center,
              style: GvTypography.headline(primary),
            ),
            const SizedBox(height: 4),
            Text(
              'KTV 门店运营工作台（骨架）',
              textAlign: TextAlign.center,
              style: GvTypography.caption(secondary),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _account,
              keyboardType: TextInputType.phone,
              decoration: _decoration('门店号 / 手机号'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: _decoration('密码'),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(backgroundColor: accent),
                child: const Text('登录'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(AppRoutes.login),
              child: Text('返回 C端登录', style: GvTypography.caption(accent)),
            ),
          ],
        ),
      ),
    );
  }
}
