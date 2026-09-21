import 'chat_message.dart';
import 'conversation.dart';

/// 聊天记录备份/迁移的 JSON 文件模型（纯客户端、本地文件级）。
///
/// 备份只记录会话元数据与消息文本（媒体仅存 URL / objectId），不下载二进制。
class ChatBackup {
  const ChatBackup({
    required this.uid,
    required this.exportedAt,
    required this.conversations,
    required this.sessions,
  });

  static const String format = 'wv-chat-backup';
  static const int version = 1;

  /// 导出该备份的账号 uid（仅作为元信息；导入时写入当前登录账号）。
  final int? uid;

  /// 导出时间（UTC）。
  final DateTime exportedAt;

  /// 会话元数据（peerId / chatType / name / lastMessage / lastTime / pinned / muted / unread）。
  final List<Conversation> conversations;

  /// 按会话分组的消息内容。
  final List<ChatBackupSession> sessions;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'format': format,
        'version': version,
        'uid': uid,
        'exportedAt': exportedAt.toUtc().toIso8601String(),
        'conversations': conversations
            .map((conversation) => conversation.toJson())
            .toList(growable: false),
        'sessions': sessions
            .map((session) => session.toJson())
            .toList(growable: false),
      };

  /// 解析备份文件；格式不匹配或结构非法时返回 null（不做抛错）。
  static ChatBackup? tryParse(Object? value) {
    if (value is! Map) return null;
    final json = Map<String, dynamic>.from(value);
    if (json['format'] != format) return null;

    final conversations = <Conversation>[];
    final rawConversations = json['conversations'];
    if (rawConversations is List) {
      for (final item in rawConversations) {
        if (item is! Map) continue;
        try {
          final conversation =
              Conversation.fromJson(Map<String, dynamic>.from(item));
          if (conversation.id.trim().isNotEmpty) {
            conversations.add(conversation);
          }
        } catch (_) {
          // 跳过无法解析的会话项。
        }
      }
    }

    final sessions = <ChatBackupSession>[];
    final rawSessions = json['sessions'];
    if (rawSessions is List) {
      for (final item in rawSessions) {
        final session = ChatBackupSession.tryParse(item);
        if (session != null) sessions.add(session);
      }
    }

    return ChatBackup(
      uid: int.tryParse(json['uid']?.toString() ?? ''),
      exportedAt: DateTime.tryParse(json['exportedAt']?.toString() ?? '')
              ?.toUtc() ??
          DateTime.now().toUtc(),
      conversations: conversations,
      sessions: sessions,
    );
  }
}

/// 单个会话的备份消息分组。
class ChatBackupSession {
  const ChatBackupSession({
    required this.peerId,
    required this.chatType,
    required this.messages,
  });

  final String peerId;
  final String chatType;
  final List<ChatMessage> messages;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'peerId': peerId,
        'chatType': chatType,
        'messages':
            messages.map((message) => message.toJson()).toList(growable: false),
      };

  static ChatBackupSession? tryParse(Object? value) {
    if (value is! Map) return null;
    final json = Map<String, dynamic>.from(value);
    final peerId = json['peerId']?.toString().trim() ?? '';
    if (peerId.isEmpty) return null;
    final chatType = json['chatType']?.toString().trim() ?? '';
    final messages = <ChatMessage>[];
    final rawMessages = json['messages'];
    if (rawMessages is List) {
      for (final item in rawMessages) {
        if (item is! Map) continue;
        try {
          messages.add(ChatMessage.fromJson(Map<String, dynamic>.from(item)));
        } catch (_) {
          // 跳过无法解析的消息项。
        }
      }
    }
    return ChatBackupSession(
      peerId: peerId,
      chatType: chatType.isEmpty ? 'private' : chatType,
      messages: messages,
    );
  }
}
