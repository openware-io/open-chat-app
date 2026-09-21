import '../models/chat_message.dart';
import '../models/favorite_models.dart';
import '../services/im_api.dart';
import 'favorite_repository.dart';

/// [ImApi] 版本的消息收藏仓库，把远端依赖从 UI 层隔离出来。
class ImFavoriteRepository implements FavoriteRepository {
  ImFavoriteRepository(this._api);

  final ImApi _api;

  @override
  Future<void> addFavorite({
    required String msgId,
    required String peerId,
    required String chatType,
  }) {
    return _api.addFavorite(
      msgId: msgId,
      peerId: peerId,
      chatType: chatType,
    );
  }

  @override
  Future<FavoriteBatchResult> addFavorites({
    required String peerId,
    required String chatType,
    required List<String> messageIds,
  }) {
    return _api.addFavoritesBatch(
      peerId: peerId,
      chatType: chatType,
      messageIds: messageIds,
    );
  }

  @override
  Future<void> removeFavorite(String msgId) {
    return _api.removeFavorite(msgId);
  }

  @override
  Future<List<ChatMessage>> listFavorites({
    int page = 1,
    int pageSize = 20,
  }) async {
    final data = await _api.listFavorites(page: page, pageSize: pageSize);
    final items = _extractItems(data);
    final result = <ChatMessage>[];
    for (final raw in items) {
      if (raw is! Map) continue;
      try {
        result.add(_favoriteMessageFromMap(Map<String, dynamic>.from(raw)));
      } catch (_) {
        // 单条解析失败不阻塞整页。
      }
    }
    return result;
  }

  /// 原消息可用性查询：调用失败绝不向上抛（也绝不放行跳转），统一按 LOOKUP_UNAVAILABLE 处理。
  @override
  Future<FavoriteSource> lookupSource(String msgId) async {
    try {
      return await _api.favoriteSource(msgId);
    } catch (_) {
      return FavoriteSource.unavailable;
    }
  }

  List<dynamic> _extractItems(Map<String, dynamic> data) {
    for (final key in const ['items', 'list', 'favorites', 'records']) {
      final value = data[key];
      if (value is List) return List<dynamic>.from(value);
    }
    return const <dynamic>[];
  }

  ChatMessage _favoriteMessageFromMap(Map<String, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);
    final msgType =
        (map['msgType'] ?? map['msg_type'])?.toString().trim() ?? '';
    if (msgType.isEmpty) {
      // 占位消息：原消息已撤回/删除，按墓碑展示。
      map['msgType'] = 'recall';
      map['status'] = 'recalled';
    }
    // 服务端收藏响应返回 senderId/senderUsername，而 ChatMessage.fromJson 只认 from/fromUserId；
    // 做一次字段归一化，否则列表因 jsonIntRequired(from) 抛异常被吞、整页恒空。
    if (map['from'] == null && map['fromUserId'] == null && map['from_user_id'] == null) {
      final sender = map['senderId'] ?? map['sender_id'];
      if (sender != null) map['from'] = sender;
    }
    if (map['fromUsername'] == null) {
      final uname = map['senderUsername'] ?? map['sender_username'];
      if (uname != null) map['fromUsername'] = uname;
    }
    // 收藏记录存储的是会话 peerId（而非消息 toId）；归一化用于列表页跳转对应会话。
    if (map['toId'] == null && map['to_id'] == null) {
      final peer = map['peerId'] ?? map['peer_id'];
      if (peer != null) map['toId'] = peer;
    }
    return ChatMessage.fromJson(map);
  }
}
