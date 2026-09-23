import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:open_ui/open_ui.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../core/open_chat_navigation.dart';
import '../core/open_automation_keys.dart';
import '../core/open_secondary_navigation.dart';
import '../models/friend_models.dart';
import '../models/group_models.dart';
import '../providers/chat_provider.dart';
import '../providers/client_remote_config_provider.dart';
import '../providers/friend_provider.dart';
import '../providers/group_provider.dart';
import '../widgets/open_avatar.dart';
import '../widgets/open_nav_bar.dart';
import '../widgets/open_search_bar.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

/// 通讯录列表一行一项（[ListView.builder]），仅构建可见区域附近的 cell。
sealed class _ContactsSlot {
  const _ContactsSlot();
}

final class _SlotTop extends _ContactsSlot {
  const _SlotTop();
}

final class _SlotGroupHeader extends _ContactsSlot {
  const _SlotGroupHeader(this.count);
  final int count;
}

final class _SlotGroupRow extends _ContactsSlot {
  const _SlotGroupRow({
    required this.group,
    required this.isFirst,
    required this.isLast,
  });
  final GroupItem group;
  final bool isFirst;
  final bool isLast;
}

final class _SlotLetterHeader extends _ContactsSlot {
  const _SlotLetterHeader(this.letter);
  final String letter;
}

final class _SlotFriendRow extends _ContactsSlot {
  const _SlotFriendRow({
    required this.friend,
    required this.isFirst,
    required this.isLast,
  });
  final FriendItem friend;
  final bool isFirst;
  final bool isLast;
}

final class _SlotEmpty extends _ContactsSlot {
  const _SlotEmpty();
}

String _contactsIndexLetter(String displayName) {
  final name = displayName.trim();
  if (name.isEmpty) return '#';
  final first = name[0];
  if (ChineseHelper.isChinese(first)) {
    final py = PinyinHelper.getFirstWordPinyin(name);
    if (py.isEmpty) return '#';
    final initial = py[0].toUpperCase();
    if (RegExp(r'[A-Z]').hasMatch(initial)) return initial;
    return '#';
  }
  var letter = first.toUpperCase();
  if (!RegExp(r'[A-Z]').hasMatch(letter)) letter = '#';
  return letter;
}

/// 右侧索引条与好友分组字母排序一致：`'#'` 最前，其余 A–Z。
int _contactsLetterRank(String ch) => ch == '#' ? -1 : ch.codeUnitAt(0);

/// 点击的字母若无对应分组，跳到第一个「不小于」该字母的分组（与常见通讯录行为一致）。
String? _resolveIndexScrollTarget(String tapped, List<String> sortedKeys) {
  if (sortedKeys.isEmpty) return null;
  if (sortedKeys.contains(tapped)) return tapped;
  final t = _contactsLetterRank(tapped);
  for (final k in sortedKeys) {
    if (_contactsLetterRank(k) >= t) return k;
  }
  return sortedKeys.last;
}

class _ContactsScreenState extends State<ContactsScreen> {
  /// 右侧索引条顺序：# + A–Z
  static const List<String> _indexLetters = [
    '#',
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
  ];

  final _search = TextEditingController();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  /// 当前列表顶部「命中」的好友分组字母，与右侧索引条蓝色高亮同步。
  String? _activeIndexLetter;

  /// 最近一次 build 得到的好友索引 key 顺序（供滚动监听读取）。
  List<String> _sortedFriendKeysForIndex = [];

  /// 好友分组变化后补一次高亮同步（滚动监听在「未滚动」时不会触发）。
  String _lastFriendKeysSig = '';

  /// 与 [_onItemPositionsForIndexHighlight] 同步的扁平列表（懒加载下列头可能未挂载，不能用 GlobalKey）。
  List<_ContactsSlot> _lastBuiltSlots = [];

  bool _indexHighlightPostFrameScheduled = false;

  void _scheduleIndexHighlightUpdate() {
    if (_indexHighlightPostFrameScheduled) return;
    _indexHighlightPostFrameScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _indexHighlightPostFrameScheduled = false;
      if (mounted) _syncIndexBarHighlightFromVisibleSlots();
    });
  }

  void _scrollToFriendLetter(String letter) {
    final keys = _sortedFriendKeysForIndex;
    final target = _resolveIndexScrollTarget(letter, keys);
    if (target == null) return;
    setState(() => _activeIndexLetter = target);

    final idx = _slotIndexForLetterHeader(target, _lastBuiltSlots);
    if (idx == null) return;

    void go() {
      if (!_itemScrollController.isAttached) return;
      _itemScrollController.scrollTo(
        index: idx,
        alignment: 0.05,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }

    go();
    if (!_itemScrollController.isAttached) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) go();
      });
    }
  }

  int? _slotIndexForLetterHeader(String letter, List<_ContactsSlot> slots) {
    for (var i = 0; i < slots.length; i++) {
      final s = slots[i];
      if (s is _SlotLetterHeader && s.letter == letter) return i;
    }
    return null;
  }

  /// [ScrollablePositionedList] 外传的位置只含「部分可见」的项，已滚出顶部的分组标题不会出现，
  /// 因此不能再用「标题是否在顶附近」判断；应从视口最靠上的可见槽位向前找到所属字母分组。
  void _syncIndexBarHighlightFromVisibleSlots() {
    if (!mounted) return;
    final keys = _sortedFriendKeysForIndex;
    if (keys.isEmpty) {
      if (_activeIndexLetter != null) {
        setState(() => _activeIndexLetter = null);
      }
      return;
    }

    final slots = _lastBuiltSlots;
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) {
      return;
    }

    ItemPosition? topmost;
    for (final p in positions) {
      if (topmost == null || p.itemLeadingEdge < topmost.itemLeadingEdge) {
        topmost = p;
      }
    }
    String? active;
    final start = topmost!.index.clamp(0, slots.length - 1);
    for (var i = start; i >= 0; i--) {
      final s = slots[i];
      if (s is _SlotLetterHeader) {
        active = s.letter;
        break;
      }
    }

    if (active != _activeIndexLetter) {
      setState(() => _activeIndexLetter = active);
    }
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions
        .removeListener(_scheduleIndexHighlightUpdate);
    _search.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _itemPositionsListener.itemPositions
        .addListener(_scheduleIndexHighlightUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendProvider>().loadFriends();
      context.read<FriendProvider>().loadPendingRequests();
      context.read<GroupProvider>().loadGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final f = context.watch<FriendProvider>();
    final g = context.watch<GroupProvider>();
    final groupChatOn =
        context.watch<ClientRemoteConfigProvider>().groupChatEnabled;
    final chat = context.read<ChatProvider>();

    final kw = _search.text.toLowerCase();
    List<FriendItem> friends = f.friends;
    if (kw.isNotEmpty) {
      friends = friends.where((x) {
        final n = x.displayName.toLowerCase();
        final u = (x.friendUser?.username ?? '').toLowerCase();
        return n.contains(kw) || u.contains(kw);
      }).toList();
    }

    final grouped = <String, List<FriendItem>>{};
    for (final fr in friends) {
      final letter = _contactsIndexLetter(fr.displayName);
      grouped.putIfAbsent(letter, () => []).add(fr);
    }
    final keys = grouped.keys.toList()..sort();
    _sortedFriendKeysForIndex = List<String>.from(keys);
    final hasMergedList =
        (groupChatOn && g.groups.isNotEmpty) || keys.isNotEmpty;
    final showIndexBar = keys.isNotEmpty && kw.isEmpty;

    final keysSig = keys.join('\u0001');
    if (keysSig != _lastFriendKeysSig) {
      _lastFriendKeysSig = keysSig;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncIndexBarHighlightFromVisibleSlots();
      });
    }

    final slots = <_ContactsSlot>[const _SlotTop()];
    if (hasMergedList) {
      if (groupChatOn && g.groups.isNotEmpty) {
        slots.add(_SlotGroupHeader(g.groups.length));
        for (var i = 0; i < g.groups.length; i++) {
          slots.add(_SlotGroupRow(
            group: g.groups[i],
            isFirst: i == 0,
            isLast: i == g.groups.length - 1,
          ));
        }
      }
      for (final k in keys) {
        slots.add(_SlotLetterHeader(k));
        final list = grouped[k]!;
        for (var i = 0; i < list.length; i++) {
          slots.add(_SlotFriendRow(
            friend: list[i],
            isFirst: i == 0,
            isLast: i == list.length - 1,
          ));
        }
      }
    }
    if (friends.isEmpty && kw.isEmpty && (!groupChatOn || g.groups.isEmpty)) {
      slots.add(const _SlotEmpty());
    }

    _lastBuiltSlots = slots;

    return SizedBox.expand(
      key: GvAutomationKeys.contactsScreen,
      child: ColoredBox(
        color: gvPageScaffoldBackground(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GvNavBar(
              title: l10n.tabContacts,
              showBottomShadow: false,
              right: IconButton(
                key: GvAutomationKeys.contactsAddFriend,
                style: IconButton.styleFrom(
                  foregroundColor: CupertinoColors.label.resolveFrom(context),
                ),
                padding: EdgeInsets.zero,
                icon: const Icon(LucideIcons.plus),
                onPressed: () => gvOpenAddFriend(context),
              ),
            ),
            GvSearchBar(
              key: GvAutomationKeys.contactsSearch,
              controller: _search,
              onChanged: (_) => setState(() {}),
              barBackgroundColor: AppColors.bgWhite.resolveFrom(context),
              fillColor: AppColors.bgSearchField.resolveFrom(context),
              padding: const EdgeInsets.fromLTRB(
                GvSpacing.page,
                GvSpacing.searchBarOuterV,
                GvSpacing.page,
                GvSpacing.searchBarOuterV,
              ),
              fieldVerticalPadding: 8,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, listConstraints) {
                  final listH = listConstraints.maxHeight;
                  final bottomInset = MediaQuery.paddingOf(context).bottom;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      NotificationListener<ScrollNotification>(
                        onNotification: (n) {
                          if (n is ScrollUpdateNotification ||
                              n is ScrollEndNotification) {
                            _scheduleIndexHighlightUpdate();
                          }
                          return false;
                        },
                        child: ScrollablePositionedList.builder(
                          itemScrollController: _itemScrollController,
                          itemPositionsListener: _itemPositionsListener,
                          itemCount: slots.length,
                          itemBuilder: (context, index) {
                            final slot = slots[index];
                            switch (slot) {
                              case _SlotTop():
                                return _topCells(context, f, groupChatOn, l10n);
                              case _SlotGroupHeader(:final count):
                                return _indexSectionTitle(context,
                                    l10n.contactsGroupSectionTitle(count));
                              case _SlotGroupRow(
                                  :final group,
                                  :final isFirst,
                                  :final isLast
                                ):
                                return Padding(
                                  padding: EdgeInsets.only(
                                      bottom: isLast ? GvSpacing.sm : 0),
                                  child: _flatCardRow(
                                    context,
                                    isFirst: isFirst,
                                    child: _groupRowInCard(
                                      context,
                                      group,
                                      chat,
                                      g,
                                    ),
                                  ),
                                );
                              case _SlotLetterHeader(:final letter):
                                return _indexSectionTitle(context, letter);
                              case _SlotFriendRow(
                                  :final friend,
                                  :final isFirst,
                                  :final isLast
                                ):
                                return Padding(
                                  padding: EdgeInsets.only(
                                      bottom: isLast ? GvSpacing.sm : 0),
                                  child: _flatCardRow(
                                    context,
                                    isFirst: isFirst,
                                    child: _friendRowInCard(context, friend, f),
                                  ),
                                );
                              case _SlotEmpty():
                                return Padding(
                                  padding: const EdgeInsets.all(48),
                                  child: Column(
                                    children: [
                                      Text(
                                        l10n.contactsEmptyFriends,
                                        style: GvTypography.caption(
                                          AppColors.textSecondary
                                              .resolveFrom(context)
                                              .withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                            }
                          },
                        ),
                      ),
                      if (showIndexBar)
                        Positioned(
                          right: 2,
                          bottom: bottomInset + 20,
                          height: listH * 2 / 3,
                          width: _ContactsIndexSidebar.trackWidth,
                          child: _ContactsIndexSidebar(
                            letters: _indexLetters,
                            activeLetter: _activeIndexLetter,
                            onLetter: _scrollToFriendLetter,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topCells(
    BuildContext context,
    FriendProvider f,
    bool groupChatEnabled,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: GvSpacing.sm),
      child: Material(
        color: AppColors.bgWhite.resolveFrom(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _cell(
              key: GvAutomationKeys.contactsFriendRequests,
              context: context,
              paintSurface: false,
              onTap: () => gvOpenFriendRequests(context),
              leading: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFFFF9F0A), Color(0xFFFF6723)]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.user_plus,
                    color: CupertinoColors.white),
              ),
              title: l10n.contactsNewFriends,
              trailing: f.pendingCount > 0
                  ? Container(
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(10)),
                      child: Text(
                          f.pendingCount > 99 ? '99+' : '${f.pendingCount}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    )
                  : null,
              inkBorderRadius: BorderRadius.zero,
            ),
            _contactsCardDivider(context),
            _cell(
              context: context,
              paintSurface: false,
              onTap: () => gvOpenFriendGroups(context),
              leading: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFF34C759), Color(0xFF30B0C7)]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.folder,
                    color: CupertinoColors.white),
              ),
              title: l10n.friendGroupsTitle,
              inkBorderRadius: BorderRadius.zero,
            ),
          /*  if (groupChatEnabled) ...[
              _contactsCardDivider(context),
              _cell(
                key: GvAutomationKeys.contactsCreateGroup,
                context: context,
                paintSurface: false,
                onTap: () => gvOpenCreateGroup(context),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color(0xFF409CFF), Color(0xFF007AFF)]),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.users_round,
                      color: CupertinoColors.white),
                ),
                title: l10n.contactsGroupChatEntry,
                inkBorderRadius: BorderRadius.zero,
              ),
            ],*/
          ],
        ),
      ),
    );
  }

  /// 与顶部「新的朋友 / 群聊」之间的分割线一致。
  Widget _contactsCardDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: AppColors.textHint.resolveFrom(context).withValues(alpha: 0.22),
    );
  }

  /// 好友/群聊行：分割线从名称左缘（头像 + 间距之后）到卡片右缘，与微信一致。
  Widget _contactsFriendRowDivider(BuildContext context) {
    const avatarW = 50.0;
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: GvSpacing.page + avatarW + GvSpacing.sm,
      endIndent: 0,
      color: AppColors.textHint.resolveFrom(context).withValues(alpha: 0.22),
    );
  }

  /// 索引区标题（非卡片，仅文案）。
  Widget _indexSectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GvSpacing.page + GvSpacing.xs,
        GvSpacing.page,
        GvSpacing.page,
        GvSpacing.xs,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: GvTypography.caption(
            AppColors.textSecondary.resolveFrom(context),
          ),
        ),
      ),
    );
  }

  /// 通栏白底行，无圆角无阴影；非首行自带分割线。
  Widget _flatCardRow(
    BuildContext context, {
    required bool isFirst,
    required Widget child,
  }) {
    return Material(
      color: AppColors.bgWhite.resolveFrom(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isFirst) _contactsFriendRowDivider(context),
          child,
        ],
      ),
    );
  }

  Widget _groupRowInCard(
    BuildContext context,
    GroupItem gr,
    ChatProvider chat,
    GroupProvider groupProvider,
  ) {
    final displayName = groupProvider.getGroupDisplayName(gr.id);
    return _cell(
      context: context,
      paintSurface: false,
      onTap: () {
        chat.upsertConversation('${gr.id}', 'group', '',
            incrementUnread: false, name: displayName);
        gvOpenChat(context, chatType: 'group', peerId: '${gr.id}');
      },
      leading: GvAvatar(name: displayName, uid: gr.id, size: 50),
      title: displayName,
      inkBorderRadius: BorderRadius.zero,
    );
  }

  Widget _friendRowInCard(
      BuildContext context, FriendItem fr, FriendProvider f) {
    return _cell(
      context: context,
      paintSurface: false,
      onTap: () => gvOpenContactFromContactsList(context, '${fr.friendId}'),
      leading: GvAvatar(
        name: fr.displayName,
        uid: fr.friendId,
        src: fr.friendUser?.avatar,
        size: 50,
      ),
      title: fr.displayName,
      trailing: f.onlineMap[fr.friendId] == true
          ? Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.success.resolveFrom(context),
                shape: BoxShape.circle,
              ),
            )
          : null,
      inkBorderRadius: BorderRadius.zero,
    );
  }

  static Color _cellHoverOverlay(BuildContext context) =>
      AppColors.textPrimary.resolveFrom(context).withValues(alpha: 0.06);

  Widget _cell({
    Key? key,
    required BuildContext context,
    required VoidCallback onTap,
    required Widget leading,
    required String title,
    Widget? trailing,
    BorderRadius? inkBorderRadius,
    bool paintSurface = true,
  }) {
    final br = inkBorderRadius ?? BorderRadius.circular(GvRadii.input);
    final hover = _cellHoverOverlay(context);
    final row = GvActionRow(
      key: key,
      title: title,
      titleStyle: GvTypography.navTitle(
        AppColors.textPrimary.resolveFrom(context),
      ),
      onTap: onTap,
      borderRadius: br,
      hoverColor: hover,
      highlightColor: hover,
      splashColor:
          AppColors.textPrimary.resolveFrom(context).withValues(alpha: 0.10),
      padding: const EdgeInsets.symmetric(
        horizontal: GvSpacing.page,
        vertical: GvSpacing.cellV,
      ),
      leading: leading,
      trailing: trailing,
    );
    if (!paintSurface) return row;
    return Material(
      color: AppColors.bgWhite.resolveFrom(context),
      child: row,
    );
  }
}

/// 通讯录右侧 # + A–Z 快速定位条（点击 / 纵向滑动）。
/// 可点区域在文字左右各扩 [kIndexHitPadding]，避免误触底部 Tab；全宽 [HitTestBehavior.opaque] 吞掉指针。
class _ContactsIndexSidebar extends StatelessWidget {
  const _ContactsIndexSidebar({
    required this.letters,
    required this.activeLetter,
    required this.onLetter,
  });

  /// 字母列宽约 22，左右各 [kIndexHitPadding] 为扩展命中区。
  static const double kIndexHitPadding = 0;
  static const double kIndexLabelWidth = 22;
  static const double kIndexVerticalPadding = 8;

  static double get trackWidth => kIndexLabelWidth + kIndexHitPadding * 2;

  final List<String> letters;
  final String? activeLetter;
  final ValueChanged<String> onLetter;

  void _pickLetter(Offset local, double totalHeight) {
    if (totalHeight <= 0 || letters.isEmpty) return;
    final innerH = totalHeight - 2 * kIndexVerticalPadding;
    if (innerH <= 0) return;
    final dy = (local.dy - kIndexVerticalPadding).clamp(0.0, innerH);
    final i =
        (dy / innerH * letters.length).floor().clamp(0, letters.length - 1);
    onLetter(letters[i]);
  }

  @override
  Widget build(BuildContext context) {
    final hint = AppColors.textSecondary.resolveFrom(context);
    final primary = AppColors.primary.resolveFrom(context);

    final radius = BorderRadius.circular(GvRadii.input);

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        return SizedBox(
          width: trackWidth,
          height: h,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.bgWhite.resolveFrom(context),
              borderRadius: radius,
              boxShadow: GvShadows.card,
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => _pickLetter(d.localPosition, h),
                onTap: () {},
                onVerticalDragDown: (d) => _pickLetter(d.localPosition, h),
                onVerticalDragUpdate: (d) => _pickLetter(d.localPosition, h),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    kIndexHitPadding,
                    kIndexVerticalPadding,
                    kIndexHitPadding,
                    kIndexVerticalPadding,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: kIndexLabelWidth,
                      height: h - 2 * kIndexVerticalPadding,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: letters
                            .map(
                              (ch) => Text(
                                ch,
                                textAlign: TextAlign.center,
                                style: GvTypography.tabLabel(
                                  ch == activeLetter ? primary : hint,
                                ).copyWith(height: 1.0),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
