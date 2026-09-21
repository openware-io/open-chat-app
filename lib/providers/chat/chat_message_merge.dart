import '../../models/chat_message.dart';

/// 优先按服务端会话序号排序；旧数据无序号时退回时间与消息 ID。
void sortChatMessagesChronological(List<ChatMessage> list) {
  list.sort((a, b) => compareChatMessagesChronological(a, b));
}

int compareChatMessagesChronological(ChatMessage a, ChatMessage b) {
  final aSeq = a.seq;
  final bSeq = b.seq;
  if (aSeq != null && bSeq != null) {
    final seqCompare = aSeq.compareTo(bSeq);
    if (seqCompare != 0) return seqCompare;
  }
  final c = a.timestamp.compareTo(b.timestamp);
  if (c != 0) return c;
  return a.msgId.compareTo(b.msgId);
}

/// 将 [msg] 按 (timestamp, msgId) 升序插入 [list]，与历史合并后的时间序一致。
///
/// 推送/离线入库不得一律 [List.add]：底部「向新分页」未拉全时，实时消息时间可能早于当前列表尾部。
void insertChatMessageChronologically(List<ChatMessage> list, ChatMessage msg) {
  final idx = list.indexWhere((x) {
    return compareChatMessagesChronological(x, msg) > 0;
  });
  if (idx < 0) {
    list.add(msg);
  } else {
    list.insert(idx, msg);
  }
}

/// 按 [ChatMessage.msgId] 去重后插入：已存在同 msgId 的消息则跳过，返回是否新增。
///
/// 用于密文轮询等「本地乐观插入 + 服务端拉取」双路径，避免同一消息重复展示。
bool insertChatMessageDeduplicated(List<ChatMessage> list, ChatMessage msg) {
  if (list.any((m) => m.msgId == msg.msgId)) return false;
  insertChatMessageChronologically(list, msg);
  return true;
}

/// [beforeMsgId] / [afterMsgId] 二选一，与 [loadHistory] 分页语义一致。
/// [merged] 为 null 时表示锚点不在当前 [latest] 中，调用方不得写入 [messageMap]。
({int added, int serverCount, List<ChatMessage>? merged})
    mergeBeforeOrAfterHistoryPage(
  List<ChatMessage> latest,
  List<ChatMessage> parsed, {
  String? beforeMsgId,
  String? afterMsgId,
}) {
  assert(beforeMsgId == null || afterMsgId == null,
      'beforeMsgId and afterMsgId cannot both be set');
  assert(beforeMsgId != null || afterMsgId != null,
      'beforeMsgId or afterMsgId is required');
  final serverCount = parsed.length;
  final ids = latest.map((m) => m.msgId).toSet();

  if (beforeMsgId != null) {
    return _mergeBeforeAnchor(latest, parsed, beforeMsgId, ids, serverCount);
  }
  return _mergeAfterAnchor(latest, parsed, afterMsgId!, ids, serverCount);
}

/// 向旧分页：锚点之前的新消息并入集合。
({int added, int serverCount, List<ChatMessage>? merged}) _mergeBeforeAnchor(
  List<ChatMessage> latest,
  List<ChatMessage> parsed,
  String beforeMsgId,
  Set<String> ids,
  int serverCount,
) {
  final b = beforeMsgId.trim();
  if (latest.isEmpty) {
    final newMsgs = parsed.where((m) => !ids.contains(m.msgId)).toList();
    final merged = List<ChatMessage>.from(newMsgs);
    sortChatMessagesChronological(merged);
    return (added: newMsgs.length, serverCount: serverCount, merged: merged);
  }
  final anchorIdx = latest.indexWhere((m) => m.msgId.trim() == b);
  if (anchorIdx < 0) {
    return (added: 0, serverCount: serverCount, merged: null);
  }
  final anchorMsg = latest[anchorIdx];
  final newMsgs = parsed.where((m) {
    if (ids.contains(m.msgId)) return false;
    return compareChatMessagesChronological(m, anchorMsg) < 0;
  }).toList();
  final merged = _unionByMsgId(latest, newMsgs);
  sortChatMessagesChronological(merged);
  return (added: newMsgs.length, serverCount: serverCount, merged: merged);
}

/// 向新分页：锚点之后的新消息并入集合。
({int added, int serverCount, List<ChatMessage>? merged}) _mergeAfterAnchor(
  List<ChatMessage> latest,
  List<ChatMessage> parsed,
  String afterMsgId,
  Set<String> ids,
  int serverCount,
) {
  final a = afterMsgId.trim();
  if (latest.isEmpty) {
    final newMsgs = parsed.where((m) => !ids.contains(m.msgId)).toList();
    final merged = List<ChatMessage>.from(newMsgs);
    sortChatMessagesChronological(merged);
    return (added: newMsgs.length, serverCount: serverCount, merged: merged);
  }
  final anchorIdx = latest.indexWhere((m) => m.msgId.trim() == a);
  if (anchorIdx < 0) {
    return (added: 0, serverCount: serverCount, merged: null);
  }
  final anchorMsg = latest[anchorIdx];
  final newMsgs = parsed.where((m) {
    if (ids.contains(m.msgId)) return false;
    return compareChatMessagesChronological(anchorMsg, m) < 0;
  }).toList();
  final merged = _unionByMsgId(latest, newMsgs);
  sortChatMessagesChronological(merged);
  return (added: newMsgs.length, serverCount: serverCount, merged: merged);
}

/// 以服务端权威合并：同 [msgId] 时默认保留本地（避免丢本地乐观状态），
/// 但当服务端消息已编辑且正文/标记与本地不同时，用服务端覆盖（编辑下行无 WS 事件，
/// 靠历史/同步补齐）。
ChatMessage mergeByMsgIdPreferringEdit(ChatMessage local, ChatMessage server) {
  if (server.edited && (!local.edited || local.content != server.content)) {
    return server;
  }
  return local;
}

List<ChatMessage> _unionByMsgId(
  List<ChatMessage> latest,
  List<ChatMessage> newMsgs,
) {
  final byId = <String, ChatMessage>{};
  for (final m in latest) {
    byId[m.msgId] = m;
  }
  for (final m in newMsgs) {
    final existing = byId[m.msgId];
    byId[m.msgId] = existing == null
        ? m
        : mergeByMsgIdPreferringEdit(existing, m);
  }
  return byId.values.toList();
}
