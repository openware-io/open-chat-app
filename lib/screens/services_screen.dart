import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:open_chat_app/l10n/app_localizations.dart';
import 'package:open_core/open_core.dart';
import 'package:open_ui/open_ui.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/config.dart';
import '../core/open_automation_keys.dart';
import '../core/open_http_headers.dart';
import '../core/open_toast.dart';
import '../core/local_storage.dart';
import '../providers/mini_app_services_provider.dart';
import '../widgets/open_nav_bar.dart';
import 'protocol_webview_screen.dart';
import '../core/app_environment.dart';

// 暂时隐藏由后端动态返回、尚未开放的服务分类；预约服务入口仍正常保留。
const _hiddenServiceCategoryNames = <String>{
  '生活娱乐',
  '酒店出行',
};

const double _serviceIconTileSize = 64;
const double _serviceIconSize = 35;
const double _serviceCellAspectRatio = 0.76;

bool _shouldHideServiceCategory(String name) =>
    _hiddenServiceCategoryNames.contains(name.trim());

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchKeyword = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<MiniAppServicesProvider>();
      provider.hydrateServiceOrdersFromCache();
      provider.hydratePinnedFromCache();
      provider.refresh();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await context
        .read<MiniAppServicesProvider>()
        .refresh(silentIfHasCache: true);
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchKeyword = value;
    });
    _searchDebounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      context.read<MiniAppServicesProvider>().clearSearch();
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      context.read<MiniAppServicesProvider>().search(trimmed);
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _searchKeyword = '';
    });
    context.read<MiniAppServicesProvider>().clearSearch();
  }

  /// 打开小程序服务项：operator / consumer 统一按 item.link（外部链接）用 WebView 打开。
  void _openSearchResult(MiniAppServiceItem item) {
    const baseUrl = AppConfig.apiBase;
    final authHdrs = gvBearerHeaders(context.read<LocalStorage>());
    _openMiniProgram(context, item, baseUrl, authHdrs);
  }

  void _togglePin(MiniAppServiceItem item) {
    context.read<MiniAppServicesProvider>().togglePin(item);
  }

  Widget _buildPinnedSection(
    BuildContext context,
    MiniAppServicesProvider prov,
  ) {
    if (prov.pinnedItems.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final itemColor = AppColors.textPrimary.resolveFrom(context);
    final bgCard = AppColors.bgWhite.resolveFrom(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GvSpacing.lg,
        GvSpacing.sm,
        GvSpacing.lg,
        GvSpacing.xs,
      ),
      child: DecoratedBox(
        decoration: _serviceCardDecoration(context, bgCard),
        child: Padding(
          padding: const EdgeInsets.all(GvSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ServiceSectionHeader(
                title: l10n.servicesPinnedTitle,
                titleColor: AppColors.textPrimary.resolveFrom(context),
              ),
              const SizedBox(height: GvSpacing.page),
              SizedBox(
                height: 104,
                child: ReorderableListView.builder(
                  scrollDirection: Axis.horizontal,
                  buildDefaultDragHandles: false,
                  padding: EdgeInsets.zero,
                  onReorderItem: (oldIndex, newIndex) {
                    prov.reorderPinned(oldIndex, newIndex);
                  },
                  itemCount: prov.pinnedItems.length,
                  itemBuilder: (context, i) {
                    final item = prov.pinnedItems[i];
                    return ReorderableDelayedDragStartListener(
                      key: ValueKey(item.id),
                      index: i,
                      child: SizedBox(
                        width: 78,
                        child: _ServiceCell(
                          item: item,
                          categoryName: '',
                          itemColor: itemColor,
                          pinned: true,
                          onTogglePin: () => _togglePin(item),
                          onOpenMiniProgram: () => _openSearchResult(item),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bg = AppColors.bgWhite.resolveFrom(context);
    final hint = AppColors.textHint.resolveFrom(context);
    final fg = AppColors.textPrimary.resolveFrom(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GvSpacing.lg,
        GvSpacing.xs,
        GvSpacing.lg,
        GvSpacing.xs,
      ),
      child: DecoratedBox(
        decoration: _serviceCardDecoration(
          context,
          bg,
          radius: GvRadii.button,
        ),
        child: TextField(
          key: GvAutomationKeys.servicesSearch,
          controller: _searchController,
          focusNode: _searchFocusNode,
          textInputAction: TextInputAction.search,
          onChanged: _onSearchChanged,
          style: TextStyle(color: fg, fontSize: 13),
          decoration: InputDecoration(
            hintText: l10n.servicesSearchHint,
            hintStyle: TextStyle(color: hint, fontSize: 13),
            prefixIcon: Icon(LucideIcons.search, size: 17, color: hint),
            prefixIconConstraints: const BoxConstraints(minWidth: 42),
            suffixIcon: _searchKeyword.isEmpty
                ? null
                : IconButton(
                    icon: Icon(LucideIcons.x, size: 18, color: hint),
                    onPressed: _clearSearch,
                  ),
            suffixIconConstraints: const BoxConstraints(minWidth: 42),
            isDense: true,
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GvRadii.button),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GvRadii.button),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GvRadii.button),
              borderSide: BorderSide(
                color: AppColors.primary
                    .resolveFrom(context)
                    .withValues(alpha: 0.45),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    MiniAppServicesProvider prov,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final secondary = AppColors.textSecondary.resolveFrom(context);
    final pending = prov.lastSearchKeyword != _searchKeyword.trim();

    if (prov.searching || pending) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (prov.searchError != null && prov.searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(GvSpacing.page),
          child: Text(
            prov.searchError!,
            textAlign: TextAlign.center,
            style: GvTypography.caption(secondary),
          ),
        ),
      );
    }
    if (prov.searchResults.isEmpty) {
      return Center(
        child: Text(
          l10n.servicesSearchEmpty,
          style: GvTypography.body(secondary),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        GvSpacing.lg,
        GvSpacing.xs,
        GvSpacing.lg,
        GvSpacing.lg,
      ),
      itemCount: prov.searchResults.length,
      itemBuilder: (context, index) {
        final item = prov.searchResults[index];
        return _SearchResultTile(
          item: item,
          pinned: prov.isPinned(item.id),
          onTogglePin: () => _togglePin(item),
          onTap: () => _openSearchResult(item),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MiniAppServicesProvider>();
    final pageBackground = gvPageScaffoldBackground(context);
    final bgCard = AppColors.bgWhite.resolveFrom(context);
    final secondary = AppColors.textSecondary.resolveFrom(context);
    const baseUrl = AppConfig.apiBase;
    final authHdrs = gvBearerHeaders(context.read<LocalStorage>());

    final visible = prov.categories
        .where((c) =>
            c.items.isNotEmpty && !_shouldHideServiceCategory(c.typeName))
        .toList(growable: false);

    final l10n = AppLocalizations.of(context)!;
    final searchActive = _searchKeyword.trim().isNotEmpty;

    return SizedBox.expand(
      key: GvAutomationKeys.servicesScreen,
      child: ColoredBox(
        color: pageBackground,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GvNavBar(
              title: l10n.tabServices,
              backgroundColor: pageBackground,
              showBottomShadow: false,
            ),
            _buildSearchField(context),
            Expanded(
              child: searchActive
                  ? _buildSearchResults(context, prov)
                  : RefreshIndicator(
                      color: AppColors.primary.resolveFrom(context),
                      onRefresh: _onRefresh,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: _buildPinnedSection(context, prov),
                          ),
                          if (prov.loading && visible.isEmpty)
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child:
                                  Center(child: CupertinoActivityIndicator()),
                            )
                          else if (prov.loadError != null && visible.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(GvSpacing.page),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.cloud_off,
                                        size: 44,
                                        color: secondary.withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        prov.loadError!,
                                        textAlign: TextAlign.center,
                                        style: GvTypography.caption(secondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else if (visible.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Text(
                                  l10n.servicesEmptyList,
                                  style: GvTypography.body(secondary),
                                ),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.only(
                                bottom: GvSpacing.lg,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final cat = visible[index];
                                    return _ServiceSection(
                                      category: cat,
                                      bgCard: bgCard,
                                      baseUrl: baseUrl,
                                      authHdrs: authHdrs,
                                      isPinned: (item) =>
                                          prov.isPinned(item.id),
                                      onTogglePin: _togglePin,
                                      onReorder: (oldIndex, newIndex) =>
                                          prov.reorderCategoryItem(
                                        cat.typeName,
                                        oldIndex,
                                        newIndex,
                                      ),
                                    );
                                  },
                                  childCount: visible.length,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

void _openMiniProgram(
  BuildContext context,
  MiniAppServiceItem item,
  String baseUrl,
  Map<String, String>? authHdrs,
) {
  final l10n = AppLocalizations.of(context)!;
  final entry = item.entryUrl.trim();
  if (entry.isEmpty) {
    GvToast.show(context, l10n.toastServiceNoUrl);
    return;
  }
  final url = normalizeMiniProgramUrl(
    entry.startsWith('http') ? entry : resolveMediaUrl(baseUrl, entry),
  );
  // 通过原生 GVBridge.login() 出授权码：JWT 只留在 App，不拼进 URL、不进 H5 JS。
  final token = _bearerToken(authHdrs);
  ProtocolWebViewScreen.open(
    context,
    title: item.name.isEmpty ? l10n.miniProgramTitle : item.name,
    url: url,
    imToken: token,
    useRootNavigator: true,
  );
}

String normalizeMiniProgramUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !(uri.path == '/a380' || uri.path == '/a380/' || uri.path == '/b' || uri.path == '/b/')) {
    return url;
  }
  const testOrigin = String.fromEnvironment('OPEN_HYBRID_TEST_ORIGIN');
  final debugPath = uri.path.startsWith('/b') ? '/b/' : '/a380/';
  if (!AppEnvironment.isProduction && testOrigin.isNotEmpty) {
    final local = Uri.tryParse(testOrigin);
    if (local != null && local.hasAuthority && local.host.isNotEmpty) {
      return local.replace(path: debugPath, query: '', fragment: '').toString();
    }
  }
  return uri
      .replace(
        host: uri.host == 'www.miniservice.dev.example.com' ||
                uri.host == 'admin.dev.example.com'
            ? 'miniservice.dev.example.com'
            : uri.host,
        path: debugPath,
      )
      .toString();
}

String? _bearerToken(Map<String, String>? headers) {
  final auth = headers?['Authorization'];
  if (auth == null || auth.isEmpty || !auth.startsWith('Bearer ')) return null;
  return auth.substring('Bearer '.length).trim();
}

BoxDecoration _serviceCardDecoration(
  BuildContext context,
  Color background, {
  double radius = GvRadii.cardLg,
}) {
  final border = AppColors.border.resolveFrom(context);
  final shadow = AppColors.textPrimary.resolveFrom(context);
  final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  return BoxDecoration(
    color: background,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: border.withValues(alpha: dark ? 0.14 : 0.08),
    ),
    boxShadow: [
      BoxShadow(
        color: shadow.withValues(alpha: dark ? 0.035 : 0.02),
        offset: const Offset(0, 2),
        blurRadius: 8,
      ),
    ],
  );
}

class _ServiceSectionHeader extends StatelessWidget {
  const _ServiceSectionHeader({
    required this.title,
    required this.titleColor,
  });

  final String title;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GvTypography.bodySmall(titleColor).copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ExcludeSemantics(
            child: Icon(
              LucideIcons.chevron_right,
              size: 15,
              color: AppColors.textHint.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceSection extends StatelessWidget {
  const _ServiceSection({
    required this.category,
    required this.bgCard,
    required this.baseUrl,
    required this.authHdrs,
    required this.isPinned,
    required this.onTogglePin,
    required this.onReorder,
  });

  final MiniAppServiceCategory category;
  final Color bgCard;
  final String baseUrl;
  final Map<String, String>? authHdrs;
  final bool Function(MiniAppServiceItem item) isPinned;
  final void Function(MiniAppServiceItem item) onTogglePin;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    final titleColor = AppColors.textPrimary.resolveFrom(context);
    final itemColor = AppColors.textPrimary.resolveFrom(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GvSpacing.lg,
        GvSpacing.xs,
        GvSpacing.lg,
        0,
      ),
      child: DecoratedBox(
        decoration: _serviceCardDecoration(context, bgCard),
        child: Padding(
          padding: const EdgeInsets.all(GvSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ServiceSectionHeader(
                title: category.typeName,
                titleColor: titleColor,
              ),
              const SizedBox(height: GvSpacing.page),
              GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: GvSpacing.lg,
                  crossAxisSpacing: GvSpacing.sm,
                  childAspectRatio: _serviceCellAspectRatio,
                ),
                itemCount: category.items.length,
                itemBuilder: (context, i) {
                  final item = category.items[i];
                  return _ReorderableServiceCell(
                    item: item,
                    itemIndex: i,
                    categoryName: category.typeName,
                    itemColor: itemColor,
                    pinned: isPinned(item),
                    onTogglePin: () => onTogglePin(item),
                    onOpenMiniProgram: () =>
                        _openMiniProgram(context, item, baseUrl, authHdrs),
                    onReorder: onReorder,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceDragData {
  const _ServiceDragData({
    required this.categoryName,
    required this.itemIndex,
  });

  final String categoryName;
  final int itemIndex;
}

class _ReorderableServiceCell extends StatelessWidget {
  const _ReorderableServiceCell({
    required this.item,
    required this.itemIndex,
    required this.categoryName,
    required this.itemColor,
    required this.pinned,
    required this.onTogglePin,
    required this.onOpenMiniProgram,
    required this.onReorder,
  });

  final MiniAppServiceItem item;
  final int itemIndex;
  final String categoryName;
  final Color itemColor;
  final bool pinned;
  final VoidCallback onTogglePin;
  final VoidCallback onOpenMiniProgram;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    final data = _ServiceDragData(
      categoryName: categoryName,
      itemIndex: itemIndex,
    );
    final cell = _ServiceCell(
      item: item,
      categoryName: categoryName,
      itemColor: itemColor,
      pinned: pinned,
      onTogglePin: onTogglePin,
      onOpenMiniProgram: onOpenMiniProgram,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return DragTarget<_ServiceDragData>(
          onWillAcceptWithDetails: (details) =>
              details.data.categoryName == categoryName &&
              details.data.itemIndex != itemIndex,
          onAcceptWithDetails: (details) {
            onReorder(details.data.itemIndex, itemIndex);
          },
          builder: (context, candidateData, rejectedData) {
            final highlighted = candidateData.any(
              (candidate) =>
                  candidate?.categoryName == categoryName &&
                  candidate?.itemIndex != itemIndex,
            );
            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                color: highlighted
                    ? AppColors.primary
                        .resolveFrom(context)
                        .withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(GvRadii.card),
                border: Border.all(
                  color: highlighted
                      ? AppColors.primary
                          .resolveFrom(context)
                          .withValues(alpha: 0.35)
                      : Colors.transparent,
                ),
              ),
              child: LongPressDraggable<_ServiceDragData>(
                data: data,
                dragAnchorStrategy: pointerDragAnchorStrategy,
                feedback: Material(
                  type: MaterialType.transparency,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: ExcludeSemantics(
                      child: _ServiceCell(
                        item: item,
                        categoryName: categoryName,
                        itemColor: itemColor,
                        pinned: pinned,
                        onTogglePin: () {},
                        onOpenMiniProgram: () {},
                      ),
                    ),
                  ),
                ),
                childWhenDragging: Opacity(opacity: 0.25, child: cell),
                child: cell,
              ),
            );
          },
        );
      },
    );
  }
}

class _ServiceCell extends StatelessWidget {
  const _ServiceCell({
    required this.item,
    required this.categoryName,
    required this.itemColor,
    required this.pinned,
    required this.onTogglePin,
    required this.onOpenMiniProgram,
  });

  final MiniAppServiceItem item;
  final String categoryName;
  final Color itemColor;
  final bool pinned;
  final VoidCallback onTogglePin;
  final VoidCallback onOpenMiniProgram;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = item.name.isEmpty ? l10n.servicesUnnamedItem : item.name;
    final accent = _serviceAccentFor(context, item, categoryName);
    final iconUrl = _resolveServiceIconUrl(item.iconPath);

    return Semantics(
      button: true,
      label: label,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        pressedOpacity: 0.6,
        minimumSize: const Size(0, 0),
        onPressed: onOpenMiniProgram,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: GvSpacing.xs),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                width: _serviceIconTileSize + 10,
                height: _serviceIconTileSize,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    _ServiceIconTile(
                      icon: _serviceIconFor(categoryName, label),
                      imageUrl: iconUrl,
                      httpHeaders: _serviceIconHeaders(context, iconUrl),
                      accent: accent,
                      size: _serviceIconTileSize,
                      iconSize: _serviceIconSize,
                    ),
                    Positioned(
                      top: -4,
                      right: -1,
                      child: _PinToggle(
                        pinned: pinned,
                        onToggle: onTogglePin,
                        size: 13,
                        withBackground: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: GvSpacing.xs),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GvTypography.tabLabel(itemColor).copyWith(
                  fontSize: 12,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceAccent {
  const _ServiceAccent({
    required this.foreground,
    required this.background,
    required this.border,
  });

  final Color foreground;
  final Color background;
  final Color border;
}

_ServiceAccent _serviceAccentFor(
  BuildContext context,
  MiniAppServiceItem item,
  String categoryName,
) {
  const palette = <CupertinoDynamicColor>[
    CupertinoColors.systemIndigo,
    CupertinoColors.systemPink,
    CupertinoColors.systemOrange,
    CupertinoColors.systemPurple,
    CupertinoColors.systemGreen,
    CupertinoColors.systemTeal,
    CupertinoColors.systemCyan,
    CupertinoColors.systemBlue,
  ];
  final source = '${item.id}|${item.name}|$categoryName';
  final paletteIndex = source.codeUnits.fold<int>(
        0,
        (sum, value) => sum + value,
      ) %
      palette.length;
  final foreground = palette[paletteIndex].resolveFrom(context);
  final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  return _ServiceAccent(
    foreground: foreground,
    background: foreground.withValues(alpha: dark ? 0.18 : 0.09),
    border: foreground.withValues(alpha: dark ? 0.28 : 0.14),
  );
}

class _ServiceIconTile extends StatelessWidget {
  const _ServiceIconTile({
    required this.icon,
    this.imageUrl,
    this.httpHeaders,
    required this.accent,
    required this.size,
    required this.iconSize,
  });

  final IconData icon;
  final String? imageUrl;
  final Map<String, String>? httpHeaders;
  final _ServiceAccent accent;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final image = imageUrl?.trim() ?? '';
    final iconWidget = image.isEmpty
        ? Icon(icon, size: iconSize, color: accent.foreground)
        : CachedNetworkImage(
            imageUrl: image,
            httpHeaders: httpHeaders,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholder: (_, __) => Icon(
              icon,
              size: iconSize,
              color: accent.foreground,
            ),
            errorWidget: (_, __, ___) => Icon(
              icon,
              size: iconSize,
              color: accent.foreground,
            ),
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.background,
        borderRadius: BorderRadius.circular(GvRadii.cardLg),
        border: Border.all(color: accent.border),
      ),
      child: SizedBox.square(
        dimension: size,
        child: image.isEmpty
            ? iconWidget
            : ClipRRect(
                borderRadius: BorderRadius.circular(GvRadii.cardLg),
                child: iconWidget,
              ),
      ),
    );
  }
}

String _resolveServiceIconUrl(String rawIconPath) {
  final value = rawIconPath.trim();
  if (value.isEmpty) return '';

  // Service icons are normally managed-media URLs. Keep the same host
  // validation used elsewhere in the app, while accepting API-host URLs for
  // deployments that serve uploads from the API origin.
  for (final baseUrl in [AppConfig.mediaBase, AppConfig.apiBase]) {
    final resolved = resolveMediaUrl(baseUrl, value);
    if (resolved.isNotEmpty) return resolved;
  }

  // Older API responses may contain a relative upload path instead of a
  // fully-qualified URL. Try both configured origins while keeping the
  // response controlled by the backend.
  if (!value.startsWith('//') && !value.contains('://')) {
    final path = value.startsWith('/') ? value : '/$value';
    for (final baseUrl in [AppConfig.mediaBase, AppConfig.apiBase]) {
      final base = Uri.tryParse(baseUrl);
      if (base != null && base.hasScheme && base.host.isNotEmpty) {
        return base.resolve(path).toString();
      }
    }
  }
  return '';
}

Map<String, String>? _serviceIconHeaders(
  BuildContext context,
  String iconUrl,
) {
  if (iconUrl.isEmpty) return null;
  return gvMediaRequestHeaders(
    iconUrl,
    gvBearerHeaders(context.read<LocalStorage>()),
  );
}

IconData _serviceIconFor(String categoryName, String itemName) {
  final value = '$categoryName $itemName'.trim().toLowerCase();
  if (value.contains('ktv') ||
      value.contains('karaoke') ||
      value.contains('唱歌') ||
      value.contains('欢唱')) {
    return LucideIcons.mic_vocal;
  }
  if (value.contains('打车') ||
      value.contains('出租车') ||
      value.contains('网约车') ||
      value.contains('taxi')) {
    return LucideIcons.car_taxi_front;
  }
  if (value.contains('机票') ||
      value.contains('飞机') ||
      value.contains('航班') ||
      value.contains('flight')) {
    return LucideIcons.plane_takeoff;
  }
  if (value.contains('酒店') || value.contains('宾馆') || value.contains('hotel')) {
    return LucideIcons.hotel;
  }
  if (value.contains('足浴') ||
      value.contains('足疗') ||
      value.contains('按摩') ||
      value.contains('spa')) {
    return LucideIcons.footprints;
  }
  if (value.contains('酒吧') || value.contains('酒馆') || value.contains('bar')) {
    return LucideIcons.martini;
  }
  if (value.contains('餐饮') || value.contains('美食') || value.contains('餐厅')) {
    return LucideIcons.utensils;
  }
  if (value.contains('购物') || value.contains('商城')) {
    return LucideIcons.shopping_bag;
  }
  if (value.contains('a380') || value.contains('小程序')) {
    return LucideIcons.grid_2x2;
  }
  if (value.contains('出行') || value.contains('交通')) {
    return LucideIcons.navigation;
  }
  if (value.contains('搜索')) {
    return LucideIcons.search;
  }
  return LucideIcons.app_window;
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.item,
    required this.pinned,
    required this.onTogglePin,
    required this.onTap,
  });

  final MiniAppServiceItem item;
  final bool pinned;
  final VoidCallback onTogglePin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = item.name.isEmpty ? l10n.servicesUnnamedItem : item.name;
    final cardColor = AppColors.bgWhite.resolveFrom(context);
    final primary = AppColors.textPrimary.resolveFrom(context);
    final secondary = AppColors.textSecondary.resolveFrom(context);
    final accent = _serviceAccentFor(context, item, '');
    final iconUrl = _resolveServiceIconUrl(item.iconPath);

    return Padding(
      padding: const EdgeInsets.only(bottom: GvSpacing.sm),
      child: Material(
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GvRadii.cardLg),
          side: BorderSide(
            color:
                AppColors.border.resolveFrom(context).withValues(alpha: 0.08),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GvRadii.cardLg),
          child: Padding(
            padding: const EdgeInsets.all(GvSpacing.page),
            child: Row(
              children: [
                _ServiceIconTile(
                  icon: _serviceIconFor('', label),
                  imageUrl: iconUrl,
                  httpHeaders: _serviceIconHeaders(context, iconUrl),
                  accent: accent,
                  size: 46,
                  iconSize: 25,
                ),
                const SizedBox(width: GvSpacing.page),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GvTypography.bodySmall(primary).copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (item.introduction.trim().isNotEmpty) ...[
                        const SizedBox(height: GvSpacing.xs),
                        Text(
                          item.introduction,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GvTypography.small(secondary),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: GvSpacing.sm),
                _PinToggle(
                  pinned: pinned,
                  onToggle: onTogglePin,
                  size: 20,
                ),
                const SizedBox(width: 2),
                Icon(LucideIcons.chevron_right, size: 18, color: secondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PinToggle extends StatelessWidget {
  const _PinToggle({
    required this.pinned,
    required this.onToggle,
    this.size = 20,
    this.withBackground = false,
  });

  final bool pinned;
  final VoidCallback onToggle;
  final double size;
  final bool withBackground;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = pinned
        ? AppColors.primary.resolveFrom(context)
        : AppColors.textHint.resolveFrom(context);
    final icon = Icon(LucideIcons.pin, size: size, color: color);
    final content = withBackground
        ? DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.bgWhite.resolveFrom(context),
              shape: BoxShape.circle,
            ),
            child: Padding(padding: const EdgeInsets.all(2), child: icon),
          )
        : Padding(padding: const EdgeInsets.all(4), child: icon);

    return Semantics(
      button: true,
      label: pinned ? l10n.servicesUnpin : l10n.servicesPin,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        pressedOpacity: 0.6,
        minimumSize: const Size(0, 0),
        onPressed: onToggle,
        child: content,
      ),
    );
  }
}
