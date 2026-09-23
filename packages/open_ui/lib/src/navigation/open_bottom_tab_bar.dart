import 'package:flutter/cupertino.dart';

import '../tokens/open_tokens.dart';

class GvBottomTabBarItem {
  const GvBottomTabBarItem({
    required this.label,
    required this.icon,
    this.automationKey,
    IconData? activeIcon,
    this.badge = 0,
    this.dot = false,
    this.semanticBadgeLabel = '',
  }) : activeIcon = activeIcon ?? icon;

  final String label;
  final IconData icon;
  final Key? automationKey;
  final IconData activeIcon;
  final int badge;
  final bool dot;
  final String semanticBadgeLabel;
}

/// Generic bottom tab bar that keeps item layout and badges reusable.
class GvBottomTabBar extends StatelessWidget {
  const GvBottomTabBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    required this.activeColor,
    required this.idleColor,
    required this.dangerColor,
    required this.labelStyleBuilder,
    this.backgroundColor,
  });

  final int currentIndex;
  final List<GvBottomTabBarItem> items;
  final ValueChanged<int> onTap;
  final Color activeColor;
  final Color idleColor;
  final Color dangerColor;
  final TextStyle Function(Color color) labelStyleBuilder;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ??
        CupertinoColors.systemBackground.resolveFrom(context);
    return Container(
      decoration: BoxDecoration(color: bg, boxShadow: GvShadows.bar),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: GvLayout.tabbarHeight,
          child: Padding(
            padding: const EdgeInsets.only(
              top: GvLayout.tabbarPaddingTop,
              bottom: GvLayout.tabbarPaddingBottom,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (var i = 0; i < items.length; i++)
                  _BottomTabItem(
                    key: items[i].automationKey,
                    item: items[i],
                    active: currentIndex == i,
                    activeColor: activeColor,
                    idleColor: idleColor,
                    dangerColor: dangerColor,
                    labelStyleBuilder: labelStyleBuilder,
                    onTap: () => onTap(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomTabItem extends StatelessWidget {
  const _BottomTabItem({
    super.key,
    required this.item,
    required this.active,
    required this.activeColor,
    required this.idleColor,
    required this.dangerColor,
    required this.labelStyleBuilder,
    required this.onTap,
  });

  final GvBottomTabBarItem item;
  final bool active;
  final Color activeColor;
  final Color idleColor;
  final Color dangerColor;
  final TextStyle Function(Color color) labelStyleBuilder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : idleColor;
    return Expanded(
      child: Semantics(
        label:
            '${item.label}${item.semanticBadgeLabel.isNotEmpty ? '，${item.semanticBadgeLabel}' : ''}',
        button: true,
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          pressedOpacity: 0.6,
          onPressed: onTap,
          minimumSize: const Size(0, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    active ? item.activeIcon : item.icon,
                    size: 24,
                    color: color,
                  ),
                  if (item.badge > 0)
                    Positioned(
                      right: -10,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        constraints:
                            const BoxConstraints(minWidth: 18, minHeight: 18),
                        decoration: BoxDecoration(
                          color: dangerColor,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          item.badge > 99 ? '99+' : '${item.badge}',
                          style: const TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            height: 1,
                          ),
                        ),
                      ),
                    )
                  else if (item.dot)
                    Positioned(
                      right: -4,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: dangerColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(item.label, style: labelStyleBuilder(color)),
            ],
          ),
        ),
      ),
    );
  }
}
