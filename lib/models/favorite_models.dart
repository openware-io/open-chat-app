import '../core/json_int.dart';

/// 「查看原消息」可用性状态，取值与后端 `GET /favorites/{msgId}/source` 的 `state` 一一对应。
enum FavoriteSourceState {
  /// 原消息仍可访问，此时才允许跳转到原会话/原消息。
  available('AVAILABLE'),

  /// 原消息已被删除（撤回 / 删除）。
  messageDeleted('MESSAGE_DELETED'),

  /// 原会话不可用（会话不存在、已退出、群已解散等）。
  conversationUnavailable('CONVERSATION_UNAVAILABLE'),

  /// 当前用户已无权限查看原消息。
  noPermission('NO_PERMISSION'),

  /// 查询本身失败（网络 / 服务端异常）：一律按不可跳转处理（fail closed）。
  lookupUnavailable('LOOKUP_UNAVAILABLE');

  const FavoriteSourceState(this.wireName);

  /// 与后端约定的枚举字面量。
  final String wireName;

  /// 解析服务端 `state`；未知或缺失一律落到 [lookupUnavailable]，避免任何形式的盲跳。
  static FavoriteSourceState fromWire(Object? value) {
    final raw = value?.toString().trim().toUpperCase() ?? '';
    for (final state in FavoriteSourceState.values) {
      if (state.wireName == raw) return state;
    }
    return FavoriteSourceState.lookupUnavailable;
  }
}

/// 原消息可用性查询结果。
///
/// 只有 [FavoriteSourceState.available] 才允许客户端跳转；其余状态都必须留在收藏详情页，
/// 收藏自身的内容不因任何状态而失效。
class FavoriteSource {
  const FavoriteSource({
    required this.state,
    this.conversationId,
    this.messageId,
  });

  final FavoriteSourceState state;

  /// 服务端归一化后的会话 id（如 `conv:private:1:2`），可能为空。
  final String? conversationId;

  /// 服务端返回的原消息 id，可能为空。
  final String? messageId;

  /// 查询失败时的保守结果：不携带任何可跳转信息。
  static const FavoriteSource unavailable = FavoriteSource(
    state: FavoriteSourceState.lookupUnavailable,
  );

  /// 是否允许跳转到原消息。
  bool get canOpenOriginal => state == FavoriteSourceState.available;

  factory FavoriteSource.fromJson(Map<String, dynamic> json) {
    String? text(Object? value) {
      final raw = value?.toString().trim() ?? '';
      return raw.isEmpty ? null : raw;
    }

    return FavoriteSource(
      state: FavoriteSourceState.fromWire(json['state']),
      conversationId: text(json['conversationId'] ?? json['conversation_id']),
      messageId: text(json['messageId'] ?? json['message_id']),
    );
  }
}

/// 批量收藏中单条消息的处理结果（`created` 为 false 表示已收藏过、本次跳过）。
class FavoriteBatchItem {
  const FavoriteBatchItem({required this.messageId, required this.created});

  final String messageId;
  final bool created;

  factory FavoriteBatchItem.fromJson(Map<String, dynamic> json) {
    return FavoriteBatchItem(
      messageId: (json['messageId'] ?? json['message_id'])?.toString() ?? '',
      created: json['created'] == true,
    );
  }
}

/// 批量收藏结果（`POST /favorites/batch`）。
///
/// 接口按消息 id 幂等：重复收藏同一条消息只计入 [skipped]，不会产生重复收藏。
class FavoriteBatchResult {
  const FavoriteBatchResult({
    required this.created,
    required this.skipped,
    this.items = const <FavoriteBatchItem>[],
  });

  /// 本次新建的收藏条数。
  final int created;

  /// 因已收藏过而跳过的条数。
  final int skipped;

  final List<FavoriteBatchItem> items;

  /// 请求覆盖的消息总数。
  int get total => created + skipped;

  /// 服务端未下发 created/skipped 汇总时，退化为按 items 统计。
  factory FavoriteBatchResult.fromJson(Map<String, dynamic> json) {
    final items = <FavoriteBatchItem>[];
    final rawItems = json['items'];
    if (rawItems is List) {
      for (final raw in rawItems) {
        if (raw is Map) {
          items.add(FavoriteBatchItem.fromJson(Map<String, dynamic>.from(raw)));
        }
      }
    }
    final created = jsonInt(json['created']) ??
        items.where((item) => item.created).length;
    final skipped = jsonInt(json['skipped']) ??
        items.where((item) => !item.created).length;
    return FavoriteBatchResult(
      created: created,
      skipped: skipped,
      items: items,
    );
  }
}
