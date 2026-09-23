import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../l10n/app_localizations.dart';

/// 服务页的固定快捷入口。
///
/// 入口本身只负责展示与传递点击意图，具体功能状态由页面决定。
class GvServiceShortcutGrid extends StatelessWidget {
  const GvServiceShortcutGrid({
    super.key,
    required this.onTap,
    this.embedded = false,
  });

  static const _gridGap = 4.0;
  static const _tileHeight = 74.0;

  final ValueChanged<GvServiceShortcutType> onTap;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = [
      _ServiceShortcut(
        type: GvServiceShortcutType.hotel,
        label: l10n.servicesHotel,
        icon: Icons.hotel,
      ),
      _ServiceShortcut(
        type: GvServiceShortcutType.bar,
        label: l10n.servicesBar,
        icon: Icons.local_bar,
      ),
      _ServiceShortcut(
        type: GvServiceShortcutType.billiards,
        label: l10n.servicesBilliards,
        icon: Icons.sports,
      ),
      _ServiceShortcut(
        type: GvServiceShortcutType.food,
        label: l10n.servicesFood,
        icon: Icons.restaurant,
      ),
      _ServiceShortcut(
        type: GvServiceShortcutType.delivery,
        label: l10n.servicesDelivery,
        icon: Icons.delivery_dining,
      ),
      _ServiceShortcut(
        type: GvServiceShortcutType.flashSale,
        label: l10n.servicesFlashSale,
        icon: Icons.flash_on,
      ),
      // 精品店入口暂时下线；保留类型与页面代码，后续恢复时取消注释即可。
      // _ServiceShortcut(
      //   type: GvServiceShortcutType.boutique,
      //   label: l10n.servicesBoutique,
      //   icon: Icons.storefront,
      // ),
      _ServiceShortcut(
        type: GvServiceShortcutType.massage,
        label: l10n.servicesMassage,
        icon: Icons.spa,
      ),
      _ServiceShortcut(
        type: GvServiceShortcutType.flights,
        label: l10n.servicesFlights,
        icon: Icons.flight,
      ),
      _ServiceShortcut(
        type: GvServiceShortcutType.taxi,
        label: l10n.servicesTaxi,
        icon: Icons.local_taxi,
      ),
      // 优惠券入口暂时下线；保留类型与页面代码，后续恢复时取消注释即可。
      // _ServiceShortcut(
      //   type: GvServiceShortcutType.coupons,
      //   label: l10n.pointsCoupons,
      //   icon: Icons.confirmation_number,
      // ),
    ];
    final cardColor = AppColors.bgWhite.resolveFrom(context);
    final textColor = embedded
        ? Colors.white.withValues(alpha: 0.88)
        : AppColors.textPrimary.resolveFrom(context);
    final iconColor = embedded
        ? const Color(0xFFFFD978)
        : AppColors.primary.resolveFrom(context);

    final content = Padding(
      padding: embedded ? EdgeInsets.zero : const EdgeInsets.all(GvSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!embedded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: GvSpacing.sm),
              child: Text(
                l10n.servicesMoreTitle,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = (constraints.maxWidth - _gridGap * 3) / 4;
              return GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: _gridGap,
                  crossAxisSpacing: _gridGap,
                  childAspectRatio: tileWidth / _tileHeight,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _ServiceShortcutTile(
                    item: item,
                    iconColor: iconColor,
                    textColor: textColor,
                    embedded: embedded,
                    onTap: () => onTap(item.type),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
    if (embedded) return content;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(GvRadii.cardLg),
        boxShadow: GvShadows.card,
      ),
      child: content,
    );
  }
}

class _ServiceShortcut {
  const _ServiceShortcut({
    required this.type,
    required this.label,
    required this.icon,
  });

  final GvServiceShortcutType type;
  final String label;
  final IconData icon;
}

enum GvServiceShortcutType {
  coupons,
  hotel,
  bar,
  billiards,
  food,
  delivery,
  flashSale,
  boutique,
  massage,
  flights,
  taxi,
}

class _ServiceShortcutTile extends StatelessWidget {
  const _ServiceShortcutTile({
    required this.item,
    required this.iconColor,
    required this.textColor,
    required this.embedded,
    required this.onTap,
  });

  final _ServiceShortcut item;
  final Color iconColor;
  final Color textColor;
  final bool embedded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: embedded ? 0.17 : 0.12),
                    borderRadius: BorderRadius.circular(embedded ? 12 : 99),
                    border: embedded
                        ? Border.all(
                            color: iconColor.withValues(alpha: 0.22),
                          )
                        : null,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(GvSpacing.sm),
                    child: Icon(item.icon, size: 23, color: iconColor),
                  ),
                ),
                const SizedBox(height: GvSpacing.xs),
                Text(
                  item.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
