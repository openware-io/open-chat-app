import 'package:flutter/material.dart';
import 'package:open_ui/open_ui.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/open_toast.dart';
import '../l10n/app_localizations.dart';
import '../services/im_oauth_service.dart';
import '../widgets/open_avatar.dart';
import '../widgets/open_nav_bar.dart';
import 'protocol_webview_screen.dart';

/// KTV 服务入口授权页（C 端服务 Tab）。
///
/// 展示「授权进入 KTV 业务」；点击「授权」走 IM 开放平台 OAuth 2.0
/// Authorization Code + PKCE：WebView 打开 /oauth/authorize，拦截自定义
/// scheme gvchat://oauth/callback 拿到 code，再 POST /oauth/token 换取
/// access_token，最后 GET /oauth/userinfo 展示用户信息（昵称/头像/脱敏手机号）。
///
/// 真实 SaaS KTV 业务 H5/深链尚未提供，「进入 KTV 业务」按钮暂以 toast 占位。
class KtvOAuthEntryScreen extends StatefulWidget {
  const KtvOAuthEntryScreen({super.key, this.service});

  /// 便于测试注入；为空时使用默认构造（AppConfig.apiBase）。
  final ImOAuthService? service;

  @override
  State<KtvOAuthEntryScreen> createState() => _KtvOAuthEntryScreenState();
}

class _KtvOAuthEntryScreenState extends State<KtvOAuthEntryScreen> {
  late final ImOAuthService _service = widget.service ?? ImOAuthService();

  bool _authorizing = false;
  String? _error;
  ImOAuthUserInfo? _userInfo;

  Future<void> _authorize() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _authorizing = true;
      _error = null;
    });
    try {
      final codeVerifier = _service.generateCodeVerifier();
      final state = _service.generateState();
      final authorizeUrl = _service.buildAuthorizeUrl(
        codeVerifier: codeVerifier,
        state: state,
      );
      final redirect = await ProtocolWebViewScreen.open(
        context,
        title: l10n.servicesKtv,
        url: authorizeUrl,
        interceptScheme: 'gvchat',
      );
      if (redirect == null || redirect.isEmpty) {
        // 用户未完成授权（返回/取消），回到未授权态。
        if (!mounted) return;
        setState(() => _authorizing = false);
        return;
      }
      final parsed = _service.parseRedirect(redirect);
      final code = parsed.code;
      if (code == null || code.isEmpty) {
        throw StateError('授权回调缺少 code');
      }
      if (parsed.state != null && parsed.state != state) {
        throw StateError('授权回调 state 校验失败');
      }
      final token = await _service.exchangeCode(
        code: code,
        codeVerifier: codeVerifier,
      );
      final userInfo = await _service.fetchUserInfo(token.accessToken);
      if (!mounted) return;
      setState(() {
        _userInfo = userInfo;
        _authorizing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _authorizing = false;
        _error = e.toString();
      });
      GvToast.show(context, 'KTV 授权失败，请重试');
    }
  }

  void _enterKtv() {
    GvToast.show(context, '真实 SaaS KTV 业务 H5 尚未提供，敬请期待');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = AppColors.primary.resolveFrom(context);
    final textPrimary = AppColors.textPrimary.resolveFrom(context);
    final textSecondary = AppColors.textSecondary.resolveFrom(context);
    final userInfo = _userInfo;

    return Scaffold(
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: GvNavBar(title: l10n.servicesKtv, showBack: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: GvLayout.desktopContentMaxWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.all(GvSpacing.page),
            children: [
              const SizedBox(height: GvSpacing.lg),
              _Hero(icon: Icons.mic_external_on_outlined, primary: primary),
              const SizedBox(height: GvSpacing.lg),
              Text(
                '授权进入 KTV 业务',
                textAlign: TextAlign.center,
                style: GvTypography.title(textPrimary).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: GvSpacing.sm),
              Text(
                '通过 IM 开放平台（OAuth 2.0）授权访问 SaaS KTV 业务',
                textAlign: TextAlign.center,
                style: GvTypography.body(textSecondary),
              ),
              const SizedBox(height: GvSpacing.lg),
              if (userInfo == null) ...[
                FilledButton(
                  onPressed: _authorizing ? null : _authorize,
                  child: _authorizing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('授权'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: GvSpacing.sm),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: GvTypography.caption(
                      AppColors.danger.resolveFrom(context),
                    ),
                  ),
                ],
              ] else
                _AuthorizedCard(
                  userInfo: userInfo,
                  onEnter: _enterKtv,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.icon, required this.primary});

  final IconData icon;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primary, primary.withValues(alpha: 0.72)],
          ),
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: const EdgeInsets.all(GvSpacing.lg),
          child: Icon(icon, color: Colors.white, size: 40),
        ),
      ),
    );
  }
}

class _AuthorizedCard extends StatelessWidget {
  const _AuthorizedCard({
    required this.userInfo,
    required this.onEnter,
  });

  final ImOAuthUserInfo userInfo;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimary.resolveFrom(context);
    final textSecondary = AppColors.textSecondary.resolveFrom(context);
    final nickname =
        userInfo.nickname.isEmpty ? 'KTV 用户' : userInfo.nickname;
    final phone = userInfo.phone.isEmpty ? '-' : userInfo.phone;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bgWhite.resolveFrom(context),
        borderRadius: BorderRadius.circular(GvRadii.cardLg),
        boxShadow: GvShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(GvSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                GvAvatar(
                  name: nickname,
                  uid: userInfo.openId,
                  src: userInfo.avatar.isEmpty ? null : userInfo.avatar,
                  size: 64,
                ),
                const SizedBox(width: GvSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nickname,
                        style: GvTypography.body(textPrimary).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: GvSpacing.xs),
                      Text(
                        'open_id: ${userInfo.openId}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GvTypography.small(textSecondary),
                      ),
                      const SizedBox(height: GvSpacing.xs),
                      Text(
                        '手机号: $phone',
                        style: GvTypography.small(textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: GvSpacing.lg),
            FilledButton(
              onPressed: onEnter,
              child: const Text('已授权，进入 KTV 业务'),
            ),
          ],
        ),
      ),
    );
  }
}
