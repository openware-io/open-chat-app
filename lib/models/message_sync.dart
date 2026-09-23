import 'package:open_core/open_core.dart';

class MessageSyncItem {
  const MessageSyncItem({
    required this.syncSeq,
    required this.message,
    required this.readAt,
  });

  final int syncSeq;
  final Map<String, dynamic> message;
  final DateTime? readAt;

  factory MessageSyncItem.fromJson(Map<String, dynamic> json) {
    final syncSeq = _requiredInt(json['syncSeq'], 'syncSeq');
    final rawMessage = json['message'];
    if (rawMessage is! Map) {
      throw const FormatException('message sync item is missing message');
    }
    final message = Map<String, dynamic>.from(rawMessage);
    final rawReadAt = json['readAt'];
    final readAt = parseUtcDateTime(rawReadAt);
    if (rawReadAt != null && readAt == null) {
      throw const FormatException('invalid readAt');
    }
    if (readAt != null) {
      message['status'] = 'read';
    }
    return MessageSyncItem(
      syncSeq: syncSeq,
      message: message,
      readAt: readAt,
    );
  }
}

class MessageSyncPage {
  const MessageSyncPage({
    required this.items,
    required this.nextSyncSeq,
    required this.hasMore,
    this.clearedConversations = const <ClearedConversation>[],
    this.deletedMessages = const <DeletedMessage>[],
  });

  final List<MessageSyncItem> items;
  final int nextSyncSeq;
  final bool hasMore;

  /// 服务端记录的「会话已被清空」标记。
  ///
  /// 清空的实时 WS 通知在**本端离线时会丢失**（服务端走 Redis 房间广播），
  /// 而消息已被删除、增量同步又不会告知删除，因此每次同步都带上该标记，
  /// 客户端据此删除本地早于 [ClearedConversation.clearedAt] 的消息，
  /// 让离线/换端/重装后的本地记录自愈。
  final List<ClearedConversation> clearedConversations;

  /// 本端「删除仅我」的墓碑：同步虽已排除这些消息，但排除只能阻止重新插入，
  /// 无法清掉**设备上已存在的旧副本**（同一账号多设备、或本机通过其它入口删除时）。
  ///
  /// 必须携带会话定位信息：客户端在**未打开该会话**时内存里没有消息，
  /// 仅凭 msgId 无法定位要清理的会话预览（真机实测到的缺陷）。
  final List<DeletedMessage> deletedMessages;

  factory MessageSyncPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List) {
      throw const FormatException('message sync response is missing items');
    }
    final hasMore = json['hasMore'];
    if (hasMore is! bool) {
      throw const FormatException('message sync response is missing hasMore');
    }
    final rawCleared = json['clearedConversations'];
    return MessageSyncPage(
      items: rawItems.map((item) {
        if (item is! Map) {
          throw const FormatException('invalid message sync item');
        }
        return MessageSyncItem.fromJson(Map<String, dynamic>.from(item));
      }).toList(growable: false),
      nextSyncSeq: _requiredInt(json['nextSyncSeq'], 'nextSyncSeq'),
      hasMore: hasMore,
      clearedConversations: rawCleared is List
          ? rawCleared
              .whereType<Map>()
              .map((item) =>
                  ClearedConversation.fromJson(Map<String, dynamic>.from(item)))
              .toList(growable: false)
          : const <ClearedConversation>[],
      deletedMessages: json['deletedMessages'] is List
          ? (json['deletedMessages'] as List)
              .whereType<Map>()
              .map((e) => DeletedMessage.fromJson(Map<String, dynamic>.from(e)))
              .toList(growable: false)
          : const <DeletedMessage>[],
    );
  }
}

/// 某个会话在本端被清空到哪个时刻（服务端持久标记）。
class ClearedConversation {
  const ClearedConversation({
    required this.conversationId,
    required this.chatType,
    required this.clearedAt,
  });

  final String conversationId;
  final String chatType;
  final DateTime clearedAt;

  factory ClearedConversation.fromJson(Map<String, dynamic> json) {
    final epochMs = json['clearedAtEpochMs'];
    final millis = switch (epochMs) {
      int value => value,
      num value => value.toInt(),
      String value => int.tryParse(value.trim()) ?? 0,
      _ => 0,
    };
    return ClearedConversation(
      conversationId: '${json['conversationId'] ?? ''}',
      chatType: '${json['chatType'] ?? ''}'.toLowerCase(),
      // 服务端用 epoch 毫秒传输，避免时区解析歧义。
      clearedAt: DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true),
    );
  }
}

int _requiredInt(Object? value, String field) {
  final parsed = switch (value) {
    int value => value,
    num value => value.toInt(),
    String value => int.tryParse(value.trim()),
    _ => null,
  };
  if (parsed == null || parsed < 0) {
    throw FormatException('invalid $field');
  }
  return parsed;
}

/// 一条「删除仅我」墓碑：含会话定位信息，便于客户端清理本地副本与该会话预览。
class DeletedMessage {
  const DeletedMessage({
    required this.msgId,
    required this.conversationId,
    required this.chatType,
  });

  final String msgId;
  final String conversationId;
  final String chatType;

  factory DeletedMessage.fromJson(Map<String, dynamic> json) {
    return DeletedMessage(
      msgId: '${json['msgId'] ?? ''}',
      conversationId: '${json['conversationId'] ?? ''}',
      chatType: '${json['chatType'] ?? ''}'.toLowerCase(),
    );
  }
}