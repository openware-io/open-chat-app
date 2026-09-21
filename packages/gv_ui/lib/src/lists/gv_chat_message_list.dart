import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../tokens/gv_tokens.dart';

/// Builds a single row in [GvChatMessageList].
typedef GvChatMessageItemBuilder<T> = Widget Function(
  BuildContext context,
  T message,
  int index,
);

/// Lightweight controller paired with [GvChatMessageList].
class GvChatMessageListController {
  GvChatMessageListController() : scroll = ScrollController();

  final ScrollController scroll;

  void applyInsertHeightViewportCompensation(double insertedExtentPixels) {
    if (insertedExtentPixels <= 0.5) return;
    if (!scroll.hasClients) return;
    scroll.jumpTo(scroll.offset + insertedExtentPixels);
  }
}

/// Generic reversed chat list.
///
/// [messages] must be ordered newest first; index 0 is shown at the visual
/// bottom because the internal [ListView] is reversed.
class GvChatMessageList<T> extends StatefulWidget {
  const GvChatMessageList({
    super.key,
    required this.controller,
    required this.messages,
    required this.itemBuilder,
    this.viewportKey,
    this.pagingEnabled = true,
    this.hasMoreOlder = true,
    this.hasMoreNewer = true,
    this.onLoadOlder,
    this.onLoadNewer,
    this.cacheExtent,
    this.shrinkWrap = false,
  });

  final GvChatMessageListController controller;
  final List<T> messages;
  final GvChatMessageItemBuilder<T> itemBuilder;
  final GlobalKey? viewportKey;
  final bool pagingEnabled;
  final bool hasMoreOlder;
  final bool hasMoreNewer;
  final Future<void> Function()? onLoadOlder;
  final Future<void> Function()? onLoadNewer;
  final double? cacheExtent;
  final bool shrinkWrap;

  static const double kLoadMoreEdgePx = 300;

  @override
  State<GvChatMessageList<T>> createState() => _GvChatMessageListState<T>();
}

class _GvChatMessageListState<T> extends State<GvChatMessageList<T>> {
  bool _olderInFlight = false;
  bool _newerInFlight = false;

  bool _onScrollNotification(ScrollNotification n) {
    if (!widget.pagingEnabled) return false;
    if (n is! ScrollUpdateNotification && n is! ScrollEndNotification) {
      return false;
    }
    final m = n.metrics;
    if (m.axis != Axis.vertical) return false;

    if (widget.hasMoreOlder &&
        widget.onLoadOlder != null &&
        m.maxScrollExtent > 0) {
      final distOlder = m.maxScrollExtent - m.pixels;
      if (distOlder <= GvChatMessageList.kLoadMoreEdgePx) {
        unawaited(_runLoadOlder());
      }
    }

    if (widget.hasMoreNewer && widget.onLoadNewer != null) {
      if (m.pixels <= GvChatMessageList.kLoadMoreEdgePx) {
        unawaited(_runLoadNewer());
      }
    }

    return false;
  }

  Future<void> _runLoadOlder() async {
    if (!mounted || _olderInFlight) return;
    final fn = widget.onLoadOlder;
    if (fn == null || !widget.hasMoreOlder || !widget.pagingEnabled) return;
    _olderInFlight = true;
    try {
      await fn();
    } finally {
      if (mounted) _olderInFlight = false;
    }
  }

  Future<void> _runLoadNewer() async {
    if (!mounted || _newerInFlight) return;
    final fn = widget.onLoadNewer;
    if (fn == null || !widget.hasMoreNewer || !widget.pagingEnabled) return;
    _newerInFlight = true;
    try {
      await fn();
    } finally {
      if (mounted) _newerInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: widget.viewportKey,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: ListView.builder(
          scrollCacheExtent: widget.cacheExtent == null
              ? null
              : ScrollCacheExtent.pixels(widget.cacheExtent!),
          controller: widget.controller.scroll,
          reverse: true,
          shrinkWrap: widget.shrinkWrap,
          padding: const EdgeInsets.fromLTRB(
            GvSpacing.sm,
            GvSpacing.sm,
            GvSpacing.sm,
            0,
          ),
          itemCount: widget.messages.length,
          itemBuilder: (context, i) =>
              widget.itemBuilder(context, widget.messages[i], i),
        ),
      ),
    );
  }
}
