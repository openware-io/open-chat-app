import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_ui/open_ui.dart' show GvTypography;

import '../../app/app_routes.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../repositories/business/admin_api_client.dart';
import '../../widgets/debug_server_settings.dart';
import '../../widgets/open_nav_bar.dart';

/// B 端（商家/门店）登录。
///
/// 员工身份登录成功后先读取门店上下文；多门店账号必须显式选择门店，
/// 不能默认使用第一个门店，避免经营数据进入错误范围。
class BusinessLoginScreen extends StatefulWidget {
  const BusinessLoginScreen({super.key});

  @override
  State<BusinessLoginScreen> createState() => _BusinessLoginScreenState();
}

class _BusinessLoginScreenState extends State<BusinessLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _account = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _account.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final contexts = await AdminApiClient.instance
          .login(_account.text.trim(), _password.text);
      if (!mounted) return;
      final selected = contexts.length == 1
          ? contexts.first
          : await _chooseStore(contexts);
      if (!mounted || selected == null) return;
      await AdminApiClient.instance.selectContext(selected);
      if (!mounted) return;
      context.go(AppRoutes.businessRoleHome);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('登录失败：$error')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<Map<String, dynamic>?> _chooseStore(
      List<Map<String, dynamic>> contexts) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('选择运营门店',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: contexts.length,
                  itemBuilder: (context, index) {
                    final item = contexts[index];
                    final roles =
                        (item['roles'] as List?)?.cast<String>() ?? const [];
                    return ListTile(
                      leading: const Icon(Icons.storefront_outlined),
                      title: Text(item['storeName']?.toString() ?? '未命名门店'),
                      subtitle: Text(roles.isEmpty ? '无运营角色' : roles.join(' / ')),
                      onTap: () => Navigator.of(sheetContext).pop(item),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  InputDecoration _decoration(String label, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      hintText: label,
      suffixIcon: suffix,
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
        child: Form(
          key: _formKey,
          child: AutofillGroup(
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
                  '门店运营、收银与前台工作台',
                  textAlign: TextAlign.center,
                  style: GvTypography.caption(secondary),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _account,
                  enabled: !_loading,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.none,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.username],
                  decoration: _decoration('门店号 / 手机号'),
                  onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? '请输入门店号或手机号'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  focusNode: _passwordFocus,
                  enabled: !_loading,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.password],
                  decoration: _decoration(
                    '密码',
                    suffix: IconButton(
                      tooltip: _obscurePassword ? '显示密码' : '隐藏密码',
                      onPressed: _loading
                          ? null
                          : () => setState(
                              () => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  onFieldSubmitted: (_) => _submit(),
                  validator: (value) =>
                      value == null || value.isEmpty ? '请输入密码' : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(backgroundColor: accent),
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('登录'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => context.go(AppRoutes.login),
                  child: Text('返回 C端登录',
                      style: GvTypography.caption(accent)),
                ),
                const DebugServerFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
