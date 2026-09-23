import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../providers/chat_provider.dart';
import '../providers/client_release_coordinator.dart';
import '../providers/friend_provider.dart';
import '../widgets/open_tab_bar.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final friend = context.watch<FriendProvider>();
    // 有新版本时「我」tab 显示小红点，避免用户必须进设置点一次才知道。
    final updateAvailable =
        context.select<ClientReleaseCoordinator, bool>((p) => p.updateAvailable);

    final tabBar = GvTabBarShell(
      currentIndex: navigationShell.currentIndex,
      onTap: (i) {
        navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        );
      },
      totalUnread: chat.totalUnread,
      pendingCount: friend.pendingCount,
      updateAvailable: updateAvailable,
    );

    // 与二三级页统一用 [ThemeData.scaffoldBackgroundColor]；body 下再铺一层同色，避免 iOS 嵌套 Navigator 透出偏深底。
    final shellBg = gvPageScaffoldBackground(context);
    return Scaffold(
      backgroundColor: shellBg,
      body: ColoredBox(color: shellBg, child: navigationShell),
      bottomNavigationBar: tabBar,
    );
  }
}
