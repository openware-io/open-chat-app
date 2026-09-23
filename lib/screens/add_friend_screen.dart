import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:open_ui/open_ui.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/open_automation_keys.dart';
import '../core/open_toast.dart';
import '../models/im_user.dart';
import '../providers/auth_provider.dart';
import '../providers/friend_provider.dart';
import '../services/api_client.dart';
import '../widgets/open_avatar.dart';
import '../widgets/open_nav_bar.dart';
import '../widgets/open_search_bar.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final _search = TextEditingController();
  bool _searched = false;
  List<ImUser> _results = [];

  /// 仅防止连点。
  final _sending = <int>{};

  /// 本页已成功发出申请的用户 id（展示「已发送」；对方拒绝后仍可再点「添加」）。
  final _requestSentUserIds = <int>{};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _doSearch() async {
    final kw = _search.text.trim();
    if (kw.isEmpty) return;
    setState(() {
      _searched = true;
      _results = [];
      _requestSentUserIds.clear();
    });
    final f = context.read<FriendProvider>();
    final myId = context.read<AuthProvider>().user?.id;
    try {
      final raw = await f.searchUser(kw);
      setState(() {
        _results = raw
            .map((e) => ImUser.fromJson(Map<String, dynamic>.from(e as Map)))
            .where((u) => myId == null || u.id != myId)
            .toList();
      });
    } catch (_) {
      setState(() => _results = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final f = context.watch<FriendProvider>();

    return Scaffold(
      key: GvAutomationKeys.addFriendScreen,
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: GvNavBar(title: l10n.addFriendTitle, showBack: true),
      body: Column(
        children: [
          GvSearchBar(
            controller: _search,
            hint: l10n.addFriendSearchFieldHint,
            onChanged: (_) {},
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: GvSpacing.page),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                  onPressed: _doSearch, child: Text(l10n.commonSearch)),
            ),
          ),
          Expanded(
            child: !_searched
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.search,
                            size: 56,
                            color: AppColors.textHint
                                .resolveFrom(context)
                                .withValues(alpha: 0.5)),
                        const SizedBox(height: GvSpacing.sm),
                        Text(l10n.addFriendSearchPrompt,
                            style: GvTypography.caption(AppColors.textSecondary
                                .resolveFrom(context)
                                .withValues(alpha: 0.8))),
                      ],
                    ),
                  )
                : _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.user_x,
                                size: 56,
                                color: AppColors.textHint
                                    .resolveFrom(context)
                                    .withValues(alpha: 0.5)),
                            const SizedBox(height: GvSpacing.sm),
                            Text(l10n.addFriendNoUsers,
                                style: GvTypography.caption(AppColors
                                    .textSecondary
                                    .resolveFrom(context)
                                    .withValues(alpha: 0.8))),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          GvSpacing.page,
                          GvSpacing.page,
                          GvSpacing.page,
                          GvSpacing.page,
                        ),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: GvSpacing.sm),
                        itemBuilder: (_, i) {
                          final u = _results[i];
                          final isFriend =
                              f.friends.any((x) => x.friendId == u.id);
                          final requestSent =
                              _requestSentUserIds.contains(u.id);
                          return GvCardShell(
                            borderRadius: BorderRadius.circular(GvRadii.input),
                            child: Material(
                              color: AppColors.bgWhite.resolveFrom(context),
                              child: Padding(
                                padding: const EdgeInsets.all(GvSpacing.page),
                                child: Row(
                                  children: [
                                    GvAvatar(
                                        name: u.displayName,
                                        uid: u.id,
                                        src: u.avatar,
                                        size: 50),
                                    const SizedBox(width: GvSpacing.sm),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(u.displayName,
                                              style: GvTypography.navTitle(
                                                  AppColors.textPrimary
                                                      .resolveFrom(context))),
                                          Text('@${u.username}',
                                              style: GvTypography.caption(
                                                  AppColors.textSecondary
                                                      .resolveFrom(context))),
                                        ],
                                      ),
                                    ),
                                    if (isFriend)
                                      Text(l10n.addFriendAlreadyFriends,
                                          style: GvTypography.caption(AppColors
                                              .textHint
                                              .resolveFrom(context)))
                                    else if (requestSent)
                                      Text(l10n.addFriendRequestSent,
                                          style: GvTypography.caption(AppColors
                                              .textHint
                                              .resolveFrom(context)))
                                    else
                                      TextButton(
                                        onPressed: _sending.contains(u.id)
                                            ? null
                                            : () async {
                                                setState(
                                                    () => _sending.add(u.id));
                                                try {
                                                  await f.sendRequest(u.id, '');
                                                  if (!context.mounted) return;
                                                  setState(() {
                                                    _sending.remove(u.id);
                                                    _requestSentUserIds
                                                        .add(u.id);
                                                  });
                                                  GvToast.show(
                                                    context,
                                                    l10n.addFriendRequestSent,
                                                  );
                                                } catch (e) {
                                                  if (mounted) {
                                                    setState(() =>
                                                        _sending.remove(u.id));
                                                    final msg = context
                                                        .read<ApiClient>()
                                                        .extractErrorMessage(e)
                                                        .toLowerCase();
                                                    if (msg.contains('already') &&
                                                        msg.contains('friend')) {
                                                      GvToast.show(
                                                        context,
                                                        l10n
                                                            .addFriendAlreadyFriends,
                                                      );
                                                    }
                                                  }
                                                }
                                              },
                                        child: Text(l10n.addFriendAction),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
