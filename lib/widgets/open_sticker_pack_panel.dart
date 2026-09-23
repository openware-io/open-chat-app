import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../core/config.dart';
import '../core/open_http_headers.dart';
import '../core/local_storage.dart';
import '../core/media_url.dart';
import '../services/im_api.dart';

const _kRecentKey = 'open_recent_stickers';
const _kMaxRecent = 20;

/// 外层 Tab 告诉本面板当前要显示哪个区域。
enum GvStickerPackSection { my, recent }

class StickerItem {
  StickerItem({required this.id, required this.url, required this.thumbnail});
  final int id;
  final String url;
  final String thumbnail;

  factory StickerItem.fromJson(Map<String, dynamic> json) {
    final url = json['url'] as String? ?? '';
    return StickerItem(
      id: json['id'] as int? ?? 0,
      url: url,
      thumbnail: json['thumbnail'] as String? ?? url,
    );
  }

  Map<String, dynamic> toJson() =>
      {'id': id, 'url': url, 'thumbnail': thumbnail};
}

/// 自定义表情包内容区（不含顶层 Tab）。
class GvStickerPackPanel extends StatefulWidget {
  const GvStickerPackPanel({
    super.key,
    required this.section,
    required this.imApi,
    required this.storage,
    required this.onSendSticker,
  });

  final GvStickerPackSection section;
  final ImApi imApi;
  final LocalStorage storage;
  final void Function(String stickerUrl) onSendSticker;

  @override
  State<GvStickerPackPanel> createState() => GvStickerPackPanelState();
}

class GvStickerPackPanelState extends State<GvStickerPackPanel> {
  List<StickerItem> _recent = [];
  List<StickerItem> _myStickers = [];
  bool _loadingMy = true;
  bool _myEditing = false;

  @override
  void initState() {
    super.initState();
    _loadRecent();
    _loadMyStickers();
  }

  @override
  void didUpdateWidget(covariant GvStickerPackPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section) {
      setState(() => _myEditing = false);
    }
  }

  Future<void> _loadRecent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kRecentKey);
      if (raw != null) {
        final list = (jsonDecode(raw) as List<dynamic>)
            .map((e) => StickerItem.fromJson(e as Map<String, dynamic>))
            .toList();
        if (mounted) setState(() => _recent = list);
      }
    } catch (_) {}
  }

  Future<void> _saveRecent(StickerItem item) async {
    _recent.removeWhere((s) => s.url == item.url);
    _recent.insert(0, item);
    if (_recent.length > _kMaxRecent) {
      _recent = _recent.sublist(0, _kMaxRecent);
    }
    setState(() {});
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kRecentKey,
        jsonEncode(_recent.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<void> _loadMyStickers() async {
    try {
      final data = await widget.imApi.getUserStickers();
      final items = data
          .map((e) => StickerItem.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _myStickers = items;
          _loadingMy = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMy = false);
    }
  }

  /// 上传新表情后重新拉列表。
  Future<void> reloadMyStickers() => _loadMyStickers();

  /// 外部调用：添加聊天中的表情到「我的」
  Future<bool> addToMyStickers(String url) async {
    try {
      final res = await widget.imApi.addUserSticker(url);
      final newItem = StickerItem(
        id: res['id'] as int? ?? 0,
        url: res['url'] as String? ?? url,
        thumbnail: (res['thumbnail'] as String?) ?? url,
      );
      if (mounted) {
        setState(() {
          _myStickers.removeWhere((s) => s.url == url);
          _myStickers.insert(0, newItem);
        });
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _removeMySticker(StickerItem item) async {
    try {
      await widget.imApi.removeUserSticker(item.id);
      if (mounted) {
        setState(() => _myStickers.removeWhere((s) => s.id == item.id));
      }
    } catch (_) {}
  }

  void _onTapSticker(StickerItem item) {
    if (widget.section == GvStickerPackSection.my && _myEditing) return;
    _saveRecent(item);
    widget.onSendSticker(item.url);
  }

  @override
  Widget build(BuildContext context) {
    const baseUrl = AppConfig.mediaBase;
    final authHdrs =
        gvBearerHeaders(widget.storage) ?? const <String, String>{};

    if (widget.section == GvStickerPackSection.my) {
      if (_loadingMy) {
        return const Center(child: CupertinoActivityIndicator());
      }
      return _buildMyBody(baseUrl, authHdrs);
    }
    return _buildGrid(_recent, baseUrl, authHdrs, deletable: false);
  }

  Widget _buildMyBody(String baseUrl, Map<String, String> authHdrs) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Text(
                l10n.chatStickerCountShort(_myStickers.length),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _myEditing = !_myEditing),
                child: Text(
                  _myEditing
                      ? l10n.chatStickerDoneEditing
                      : l10n.chatStickerManage,
                  style: TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.systemBlue,
                    fontWeight: _myEditing ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _myStickers.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      l10n.chatStickerMyEmptyHint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                )
              : _buildGrid(_myStickers, baseUrl, authHdrs,
                  deletable: _myEditing),
        ),
      ],
    );
  }

  Widget _buildGrid(
    List<StickerItem> items,
    String baseUrl,
    Map<String, String> authHdrs, {
    required bool deletable,
  }) {
    if (items.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return Center(
        child: Text(l10n.chatStickerEmptyList,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final url = resolveMediaUrl(
          baseUrl,
          item.thumbnail.isNotEmpty ? item.thumbnail : item.url,
        );
        return GestureDetector(
          onTap: () => _onTapSticker(item),
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(6),
                child: CachedNetworkImage(
                  imageUrl: url,
                  httpHeaders: authHdrs,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CupertinoActivityIndicator(radius: 8),
                    ),
                  ),
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.broken_image_outlined, size: 24),
                ),
              ),
              if (deletable)
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _removeMySticker(item),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
