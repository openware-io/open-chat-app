import 'dart:async';

import 'package:gv_core/gv_core.dart';

import '../../core/config.dart';
import '../../core/local_storage.dart';
import '../../database/chat_database.dart';
import '../../models/chat_session_storage_stat.dart';

/// 聊天模块的本地持久化边界。
///
/// ChatProvider 只维护运行时状态和 UI 通知；会话列表、隐藏消息、
/// 已读水位线和当前登录用户快照的存取都放在这里，避免 Provider 直接关心
/// SharedPreferences 的 key、JSON 结构和迁移细节。
class ChatLocalStore {
  ChatLocalStore(this._storage, this._database);

  final LocalStorage _storage;
  final ChatDatabase _database;

  int? get myId => jsonInt(_storage.userJson?['id']);

  /// 安装 ID（复用客户端发布安装标识，作为 E2EE 设备 ID）。
  String? get clientReleaseInstallationId =>
      _storage.clientReleaseInstallationId;

  String? get _scope {
    final userId = myId;
    if (userId == null) return null;
    return _scopeForUser(userId);
  }

  String _scopeForUser(int userId) => '${AppConfig.apiBase}|$userId';

  ImUser? get selfUser {
    final json = _storage.userJson;
    if (json == null) return null;
    try {
      return ImUser.fromJson(Map<String, dynamic>.from(json));
    } catch (_) {
      return null;
    }
  }

  /// 与 [ImUser.displayName] 一致，用于没有好友记录时展示当前用户名称。
  String? get selfDisplayName {
    final json = _storage.userJson;
    if (json == null) return null;
    final nick = json['nickname'];
    if (nick is String && nick.trim().isNotEmpty) return nick.trim();
    final username = json['username'];
    if (username is String && username.trim().isNotEmpty) {
      return username.trim();
    }
    return null;
  }

  Future<void> migrateLegacyChatKeysIfNeeded() {
    return _storage.migrateLegacyUnscopedChatKeysIfNeeded();
  }

  Future<List<Conversation>> loadConversations() async {
    final scope = _scope;
    if (scope == null) return [];
    var stored = <Conversation>[];
    try {
      stored = await _database.loadConversations(scope);
    } catch (_) {}
    if (stored.isNotEmpty) return stored;

    final legacy = <Conversation>[];
    for (final item in _storage.loadConversationsRaw()) {
      if (item is! Map) continue;
      try {
        legacy.add(
          Conversation.fromJson(Map<String, dynamic>.from(item)),
        );
      } catch (_) {}
    }
    if (legacy.isNotEmpty) {
      await _writeDatabase(
        () => _database.replaceConversations(scope, legacy),
      );
    }
    return legacy;
  }

  Future<void> saveConversations(List<Conversation> conversations) async {
    final scope = _scope;
    if (scope == null) return;
    await _storage.saveConversationsRaw(
      conversations.map((c) => c.toJson()).toList(),
    );
    await _writeDatabase(
      () => _database.replaceConversations(scope, conversations),
    );
  }

  /// 定向持久化单个会话的输入草稿（空值清除草稿）。
  Future<void> saveConversationDraft(
    String peerId,
    String chatType,
    String? draftText,
  ) {
    final scope = _scope;
    if (scope == null) return Future.value();
    return _writeDatabase(
      () => _database.updateConversationDraft(
        scope,
        peerId,
        chatType,
        draftText,
      ),
    );
  }

  Future<List<ChatMessage>> loadLatestMessages(
    String peerId,
    String chatType, {
    int limit = 100,
  }) async {
    final scope = _scope;
    if (scope == null) return const [];
    try {
      return await _database.loadLatestMessages(
        scope,
        peerId,
        chatType,
        limit: limit,
      );
    } catch (_) {
      return const [];
    }
  }

  /// 读取某会话全部本地消息（不分页），用于聊天记录备份导出。
  Future<List<ChatMessage>> loadAllMessages(
    String peerId,
    String chatType,
  ) async {
    final scope = _scope;
    if (scope == null) return const [];
    try {
      return await _database.loadAllMessages(scope, peerId, chatType);
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveMessages(
    String peerId,
    Iterable<ChatMessage> messages,
  ) {
    final scope = _scope;
    if (scope == null) return Future.value();
    return _writeDatabase(
      () => _database.upsertMessages(scope, peerId, messages),
    );
  }

  Future<int> loadLastSyncedSyncSeq(int accountId) async {
    try {
      return await _database.loadLastSyncedSyncSeq(
        _scopeForUser(accountId),
      );
    } catch (_) {
      return 0;
    }
  }

  /// A sync page is durable only when its messages, conversation previews and
  /// account watermark have all committed in the same database transaction.
  Future<void> applyMessageSyncPage({
    required int accountId,
    required List<({String peerId, ChatMessage message})> messages,
    required List<Conversation> conversations,
    required int nextSyncSeq,
  }) {
    return _database.applyMessageSyncPage(
      _scopeForUser(accountId),
      messages,
      conversations,
      nextSyncSeq,
    );
  }

  Future<void> savePendingMessage(
    String peerId,
    ChatMessage message,
  ) {
    final scope = _scope;
    if (scope == null) return Future.value();
    return _writeDatabase(
      () => _database.savePendingMessage(scope, peerId, message),
    );
  }

  Future<List<ChatMessage>> loadPendingMessages() async {
    final scope = _scope;
    if (scope == null) return const [];
    try {
      return await _database.loadPendingMessages(scope);
    } catch (_) {
      return const [];
    }
  }

  Future<void> confirmPendingMessage(
    String peerId,
    String clientMsgId,
    ChatMessage confirmed,
  ) {
    final scope = _scope;
    if (scope == null) return Future.value();
    return _writeDatabase(
      () => _database.confirmPendingMessage(
        scope,
        peerId,
        clientMsgId,
        confirmed,
      ),
    );
  }

  Future<void> removePendingMessage(String clientMsgId) {
    final scope = _scope;
    if (scope == null) return Future.value();
    return _writeDatabase(
      () => _database.removePendingMessage(scope, clientMsgId),
    );
  }

  Future<void> updateMessage(ChatMessage message) {
    final scope = _scope;
    if (scope == null) return Future.value();
    return _writeDatabase(() => _database.updateMessage(scope, message));
  }

  Future<void> deleteMessage(String msgId) {
    final scope = _scope;
    if (scope == null) return Future.value();
    return _writeDatabase(() => _database.deleteMessage(scope, msgId));
  }

  Future<void> clearSession(String peerId, String chatType) {
    final scope = _scope;
    if (scope == null) return Future.value();
    return _writeDatabase(
      () => _database.clearSession(scope, peerId, chatType),
    );
  }

  /// 按会话聚合本机消息库占用；读取失败时返回空列表（页面按 0 占用展示）。
  Future<List<ChatSessionStorageStat>> loadSessionStorageStats() async {
    final scope = _scope;
    if (scope == null) return const [];
    try {
      return await _database.loadSessionStorageStats(scope);
    } catch (_) {
      return const [];
    }
  }

  /// 清空全部会话的本机消息记录（仅当前 scope，不影响云端）。
  Future<void> clearAllSessionRecords() {
    final scope = _scope;
    if (scope == null) return Future.value();
    return _writeDatabase(() => _database.clearAllSessions(scope));
  }

  Future<void> _writeDatabase(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (_) {}
  }

  Map<String, List<dynamic>> loadHiddenMessages() {
    return _storage.loadHiddenMessagesMap().map(
          (key, value) => MapEntry(key, value is List ? value : []),
        );
  }

  Future<void> saveHiddenMessages(Map<String, List<dynamic>> hiddenMessages) {
    return _storage.saveHiddenMessagesMap(hiddenMessages);
  }

  Map<String, DateTime> loadReadWatermarks() {
    return _storage.loadChatReadWatermarks();
  }

  Future<void> saveReadWatermarks(Map<String, DateTime> watermarks) {
    return _storage.saveChatReadWatermarks(watermarks);
  }

  Map<String, DateTime> loadLocalClearWatermarks() {
    return _storage.loadChatLocalClearWatermarks();
  }

  Future<void> saveLocalClearWatermarks(Map<String, DateTime> watermarks) {
    return _storage.saveChatLocalClearWatermarks(watermarks);
  }

  /// fire-and-forget 存储：聊天状态变更频繁，不阻塞当前 UI 帧。
  void saveReadWatermarksLater(Map<String, DateTime> watermarks) {
    unawaited(saveReadWatermarks(watermarks));
  }
}
