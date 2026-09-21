import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:gv_core/gv_core.dart';

import '../models/chat_session_storage_stat.dart';

part 'chat_database.g.dart';

class CachedConversations extends Table {
  TextColumn get scopeId => text()();
  TextColumn get peerId => text()();
  TextColumn get chatType => text()();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get avatar => text().withDefault(const Constant(''))();
  TextColumn get lastMessage => text().withDefault(const Constant(''))();
  DateTimeColumn get lastTime => dateTime()();
  IntColumn get unread => integer().withDefault(const Constant(0))();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  BoolColumn get muted => boolean().withDefault(const Constant(false))();
  TextColumn get draftText => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {scopeId, peerId, chatType};
}

class CachedMessages extends Table {
  TextColumn get scopeId => text()();
  TextColumn get msgId => text()();
  TextColumn get peerId => text()();
  IntColumn get fromUserId => integer()();
  TextColumn get fromUsername => text().nullable()();
  TextColumn get fromAvatar => text().nullable()();
  TextColumn get toId => text()();
  TextColumn get chatType => text()();
  TextColumn get msgType => text().withDefault(const Constant('text'))();
  TextColumn get content => text().withDefault(const Constant(''))();
  DateTimeColumn get timestamp => dateTime()();
  IntColumn get seq => integer().nullable()();
  TextColumn get clientMsgId => text().nullable()();
  TextColumn get replyMsgId => text().nullable()();
  TextColumn get atUsersJson => text().nullable()();
  TextColumn get mediaObjectIdsJson => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('sent'))();
  BoolColumn get edited => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {scopeId, msgId};
}

class ChatOutboxEntries extends Table {
  TextColumn get scopeId => text()();
  TextColumn get clientMsgId => text()();
  TextColumn get peerId => text()();
  TextColumn get toId => text()();
  TextColumn get chatType => text()();
  TextColumn get msgType => text()();
  TextColumn get content => text()();
  TextColumn get replyMsgId => text().nullable()();
  TextColumn get atUsersJson => text().nullable()();
  TextColumn get mediaObjectIdsJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {scopeId, clientMsgId};
}

class MessageSyncStates extends Table {
  TextColumn get scopeId => text()();
  IntColumn get lastSyncedSyncSeq => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {scopeId};
}

@DriftDatabase(
  tables: [
    CachedConversations,
    CachedMessages,
    ChatOutboxEntries,
    MessageSyncStates,
  ],
)
class ChatDatabase extends _$ChatDatabase {
  ChatDatabase()
      : super(
          driftDatabase(
            name: 'vvvchat',
            web: DriftWebOptions(
              sqlite3Wasm: Uri.parse('sqlite3.wasm'),
              driftWorker: Uri.parse('drift_worker.js'),
            ),
          ),
        );

  ChatDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement(
            'CREATE INDEX IF NOT EXISTS '
            'idx_cached_messages_session_time '
            'ON cached_messages '
            '(scope_id, chat_type, peer_id, timestamp)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS '
            'idx_cached_messages_client_id '
            'ON cached_messages (scope_id, client_msg_id)',
          );
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(cachedMessages, cachedMessages.seq);
          }
          if (from < 3) {
            await m.addColumn(
              cachedMessages,
              cachedMessages.mediaObjectIdsJson,
            );
            await m.addColumn(
              chatOutboxEntries,
              chatOutboxEntries.mediaObjectIdsJson,
            );
          }
          if (from < 4) {
            await m.createTable(messageSyncStates);
          }
          if (from < 5) {
            await m.addColumn(cachedConversations, cachedConversations.muted);
            await m.addColumn(
              cachedConversations,
              cachedConversations.draftText,
            );
          }
          if (from < 6) {
            await m.addColumn(cachedMessages, cachedMessages.edited);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<int> loadLastSyncedSyncSeq(String scope) async {
    final row = await (select(messageSyncStates)
          ..where((table) => table.scopeId.equals(scope))
          ..limit(1))
        .getSingleOrNull();
    return row?.lastSyncedSyncSeq ?? 0;
  }

  Future<void> applyMessageSyncPage(
    String scope,
    List<({String peerId, ChatMessage message})> messages,
    List<Conversation> conversations,
    int nextSyncSeq,
  ) {
    return transaction(() async {
      final current = await (select(messageSyncStates)
            ..where((table) => table.scopeId.equals(scope))
            ..limit(1))
          .getSingleOrNull();
      if (current != null && nextSyncSeq < current.lastSyncedSyncSeq) {
        throw StateError('message sync watermark cannot move backwards');
      }

      for (final item in messages) {
        final message = item.message;
        final clientId = message.clientMsgId?.trim();
        if (clientId != null && clientId.isNotEmpty) {
          await (delete(cachedMessages)
                ..where(
                  (table) =>
                      table.scopeId.equals(scope) &
                      table.clientMsgId.equals(clientId) &
                      table.msgId.equals(message.msgId).not(),
                ))
              .go();
          await (delete(chatOutboxEntries)
                ..where(
                  (table) =>
                      table.scopeId.equals(scope) &
                      table.clientMsgId.equals(clientId),
                ))
              .go();
        }
        await into(cachedMessages).insertOnConflictUpdate(
          _messageCompanion(scope, item.peerId, message),
        );
      }

      await (delete(cachedConversations)
            ..where((table) => table.scopeId.equals(scope)))
          .go();
      if (conversations.isNotEmpty) {
        await batch((batch) {
          batch.insertAll(
            cachedConversations,
            conversations
                .map((item) => _conversationCompanion(scope, item))
                .toList(growable: false),
          );
        });
      }

      await into(messageSyncStates).insertOnConflictUpdate(
        MessageSyncStatesCompanion.insert(
          scopeId: scope,
          lastSyncedSyncSeq: Value(nextSyncSeq),
        ),
      );
    });
  }

  Future<List<Conversation>> loadConversations(String scope) async {
    final rows = await (select(cachedConversations)
          ..where((t) => t.scopeId.equals(scope)))
        .get();
    return rows
        .map(
          (row) => Conversation(
            id: row.peerId,
            chatType: row.chatType,
            name: row.name,
            avatar: row.avatar,
            lastMessage: row.lastMessage,
            lastTime: row.lastTime,
            unread: row.unread,
            pinned: row.pinned,
            muted: row.muted,
            draftText: row.draftText,
          ),
        )
        .toList();
  }

  Future<void> replaceConversations(
    String scope,
    List<Conversation> conversations,
  ) {
    return transaction(() async {
      await (delete(cachedConversations)..where((t) => t.scopeId.equals(scope)))
          .go();
      if (conversations.isEmpty) return;
      await batch((batch) {
        batch.insertAll(
          cachedConversations,
          conversations
              .map(
                  (conversation) => _conversationCompanion(scope, conversation))
              .toList(),
        );
      });
    });
  }

  /// 定向更新单个会话的输入草稿（空串/空值表示清除草稿）。
  Future<void> updateConversationDraft(
    String scope,
    String peerId,
    String chatType,
    String? draftText,
  ) async {
    final normalized =
        (draftText == null || draftText.isEmpty) ? null : draftText;
    await (update(cachedConversations)
          ..where(
            (t) =>
                t.scopeId.equals(scope) &
                t.peerId.equals(peerId) &
                t.chatType.equals(chatType),
          ))
        .write(
      CachedConversationsCompanion(draftText: Value(normalized)),
    );
  }

  Future<List<ChatMessage>> loadLatestMessages(
    String scope,
    String peerId,
    String chatType, {
    int limit = 100,
  }) async {
    final rows = await (select(cachedMessages)
          ..where(
            (t) =>
                t.scopeId.equals(scope) &
                t.peerId.equals(peerId) &
                t.chatType.equals(chatType),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
          ..limit(limit))
        .get();
    return rows.reversed.map(_messageFromRow).toList();
  }

  /// 读取某会话全部本地缓存消息（时间升序），用于聊天记录备份导出（不分页）。
  Future<List<ChatMessage>> loadAllMessages(
    String scope,
    String peerId,
    String chatType,
  ) async {
    final rows = await (select(cachedMessages)
          ..where(
            (t) =>
                t.scopeId.equals(scope) &
                t.peerId.equals(peerId) &
                t.chatType.equals(chatType),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
        .get();
    return rows.map(_messageFromRow).toList();
  }

  Future<void> upsertMessages(
    String scope,
    String peerId,
    Iterable<ChatMessage> messages,
  ) async {
    final items = messages.toList();
    if (items.isEmpty) return;
    await transaction(() async {
      for (final message in items) {
        final clientId = message.clientMsgId?.trim();
        if (clientId != null && clientId.isNotEmpty) {
          await (delete(cachedMessages)
                ..where(
                  (t) =>
                      t.scopeId.equals(scope) &
                      t.clientMsgId.equals(clientId) &
                      t.msgId.equals(message.msgId).not(),
                ))
              .go();
        }
        await into(cachedMessages).insertOnConflictUpdate(
          _messageCompanion(scope, peerId, message),
        );
      }
    });
  }

  Future<void> savePendingMessage(
    String scope,
    String peerId,
    ChatMessage message,
  ) async {
    final clientId = message.clientMsgId?.trim();
    if (clientId == null || clientId.isEmpty) return;
    await transaction(() async {
      await into(cachedMessages).insertOnConflictUpdate(
        _messageCompanion(scope, peerId, message),
      );
      await into(chatOutboxEntries).insertOnConflictUpdate(
        ChatOutboxEntriesCompanion.insert(
          scopeId: scope,
          clientMsgId: clientId,
          peerId: peerId,
          toId: message.toId,
          chatType: message.chatType,
          msgType: message.msgType,
          content: message.content,
          replyMsgId: Value(message.replyMsgId),
          atUsersJson: Value(_encodeAtUsers(message.atUsers)),
          mediaObjectIdsJson: Value(_encodeList(message.mediaObjectIds)),
          createdAt: message.timestamp,
        ),
      );
    });
  }

  Future<List<ChatMessage>> loadPendingMessages(String scope) async {
    final rows = await (select(chatOutboxEntries)
          ..where((t) => t.scopeId.equals(scope))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    return rows
        .map(
          (row) => ChatMessage(
            msgId: row.clientMsgId,
            from: _scopeUserId(scope),
            toId: row.toId,
            chatType: row.chatType,
            msgType: row.msgType,
            content: row.content,
            timestamp: row.createdAt,
            clientMsgId: row.clientMsgId,
            replyMsgId: row.replyMsgId,
            atUsers: _decodeAtUsers(row.atUsersJson),
            mediaObjectIds: _decodeList(row.mediaObjectIdsJson),
            status: 'sending',
          ),
        )
        .toList();
  }

  Future<void> confirmPendingMessage(
    String scope,
    String peerId,
    String clientMsgId,
    ChatMessage confirmed,
  ) {
    return transaction(() async {
      await (delete(cachedMessages)
            ..where(
              (t) =>
                  t.scopeId.equals(scope) &
                  (t.clientMsgId.equals(clientMsgId) |
                      t.msgId.equals(clientMsgId)),
            ))
          .go();
      await (delete(chatOutboxEntries)
            ..where(
              (t) =>
                  t.scopeId.equals(scope) & t.clientMsgId.equals(clientMsgId),
            ))
          .go();
      await into(cachedMessages).insertOnConflictUpdate(
        _messageCompanion(scope, peerId, confirmed),
      );
    });
  }

  Future<void> removePendingMessage(String scope, String clientMsgId) {
    return transaction(() async {
      await (delete(cachedMessages)
            ..where(
              (t) =>
                  t.scopeId.equals(scope) &
                  (t.clientMsgId.equals(clientMsgId) |
                      t.msgId.equals(clientMsgId)),
            ))
          .go();
      await (delete(chatOutboxEntries)
            ..where(
              (t) =>
                  t.scopeId.equals(scope) & t.clientMsgId.equals(clientMsgId),
            ))
          .go();
    });
  }

  Future<void> updateMessage(String scope, ChatMessage message) async {
    final existing = await (select(cachedMessages)
          ..where(
            (t) => t.scopeId.equals(scope) & t.msgId.equals(message.msgId),
          )
          ..limit(1))
        .getSingleOrNull();
    if (existing == null) return;
    await into(cachedMessages).insertOnConflictUpdate(
      _messageCompanion(scope, existing.peerId, message),
    );
  }

  Future<void> deleteMessage(String scope, String msgId) {
    return transaction(() async {
      await (delete(cachedMessages)
            ..where(
              (t) => t.scopeId.equals(scope) & t.msgId.equals(msgId),
            ))
          .go();
      await (delete(chatOutboxEntries)
            ..where(
              (t) => t.scopeId.equals(scope) & t.clientMsgId.equals(msgId),
            ))
          .go();
    });
  }

  Future<void> clearSession(
    String scope,
    String peerId,
    String chatType,
  ) {
    return transaction(() async {
      await (delete(cachedMessages)
            ..where(
              (t) =>
                  t.scopeId.equals(scope) &
                  t.peerId.equals(peerId) &
                  t.chatType.equals(chatType),
            ))
          .go();
      await (delete(chatOutboxEntries)
            ..where(
              (t) =>
                  t.scopeId.equals(scope) &
                  t.peerId.equals(peerId) &
                  t.chatType.equals(chatType),
            ))
          .go();
    });
  }

  /// 按 (chatType, peerId) 聚合本地消息库的行数与字节数（仅当前 scope）。
  ///
  /// 字节数用 SQLite `LENGTH(CAST(col AS BLOB))` 估算各文本列的字节占用，
  /// 覆盖 content / msgType / msgId / clientMsgId / replyMsgId / atUsersJson /
  /// mediaObjectIdsJson / fromUsername / fromAvatar，作为「本机聊天记录占用」。
  Future<List<ChatSessionStorageStat>> loadSessionStorageStats(String scope) async {
    final rows = await customSelect(
      '''
      SELECT
        chat_type AS chatType,
        peer_id AS peerId,
        COUNT(*) AS messageCount,
        COALESCE(SUM(
          LENGTH(CAST(content AS BLOB)) +
          LENGTH(CAST(msg_type AS BLOB)) +
          LENGTH(CAST(msg_id AS BLOB)) +
          LENGTH(CAST(COALESCE(client_msg_id, '') AS BLOB)) +
          LENGTH(CAST(COALESCE(reply_msg_id, '') AS BLOB)) +
          LENGTH(CAST(COALESCE(at_users_json, '') AS BLOB)) +
          LENGTH(CAST(COALESCE(media_object_ids_json, '') AS BLOB)) +
          LENGTH(CAST(COALESCE(from_username, '') AS BLOB)) +
          LENGTH(CAST(COALESCE(from_avatar, '') AS BLOB))
        ), 0) AS totalBytes
      FROM cached_messages
      WHERE scope_id = ?
      GROUP BY chat_type, peer_id
      ''',
      variables: [Variable<String>(scope)],
      readsFrom: {cachedMessages},
    ).get();

    return rows
        .map(
          (row) => ChatSessionStorageStat(
            peerId: row.read<String>('peerId'),
            chatType: row.read<String>('chatType'),
            messageCount: row.read<int>('messageCount'),
            messageBytes: row.read<int>('totalBytes'),
          ),
        )
        .toList();
  }

  /// 清空当前 scope 下全部会话的本地消息与待发送队列（仅本机记录，不影响云端）。
  Future<void> clearAllSessions(String scope) {
    return transaction(() async {
      await (delete(cachedMessages)
            ..where((t) => t.scopeId.equals(scope)))
          .go();
      await (delete(chatOutboxEntries)
            ..where((t) => t.scopeId.equals(scope)))
          .go();
    });
  }

  CachedConversationsCompanion _conversationCompanion(
    String scope,
    Conversation conversation,
  ) {
    return CachedConversationsCompanion.insert(
      scopeId: scope,
      peerId: conversation.id,
      chatType: conversation.chatType,
      name: Value(conversation.name),
      avatar: Value(conversation.avatar),
      lastMessage: Value(conversation.lastMessage),
      lastTime: conversation.lastTime,
      unread: Value(conversation.unread),
      pinned: Value(conversation.pinned),
      muted: Value(conversation.muted),
      draftText: Value(conversation.draftText),
    );
  }

  CachedMessagesCompanion _messageCompanion(
    String scope,
    String peerId,
    ChatMessage message,
  ) {
    return CachedMessagesCompanion.insert(
      scopeId: scope,
      msgId: message.msgId,
      peerId: peerId,
      fromUserId: message.from,
      fromUsername: Value(message.fromUsername),
      fromAvatar: Value(message.fromAvatar),
      toId: message.toId,
      chatType: message.chatType,
      msgType: Value(message.msgType),
      content: Value(message.content),
      timestamp: message.timestamp,
      seq: Value(message.seq),
      clientMsgId: Value(message.clientMsgId),
      replyMsgId: Value(message.replyMsgId),
      atUsersJson: Value(_encodeAtUsers(message.atUsers)),
      mediaObjectIdsJson: Value(_encodeList(message.mediaObjectIds)),
      status: Value(message.status),
      edited: Value(message.edited),
    );
  }

  ChatMessage _messageFromRow(CachedMessage row) {
    return ChatMessage(
      msgId: row.msgId,
      from: row.fromUserId,
      fromUsername: row.fromUsername,
      fromAvatar: row.fromAvatar,
      toId: row.toId,
      chatType: row.chatType,
      msgType: row.msgType,
      content: row.content,
      timestamp: row.timestamp,
      seq: row.seq,
      clientMsgId: row.clientMsgId,
      replyMsgId: row.replyMsgId,
      atUsers: _decodeAtUsers(row.atUsersJson),
      mediaObjectIds: _decodeList(row.mediaObjectIdsJson),
      status: row.status,
      edited: row.edited,
    );
  }

  String? _encodeAtUsers(List<dynamic>? value) {
    if (value == null) return null;
    return jsonEncode(value);
  }

  String? _encodeList(List<dynamic>? value) {
    if (value == null) return null;
    return jsonEncode(value);
  }

  List<dynamic>? _decodeAtUsers(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      final decoded = jsonDecode(value);
      return decoded is List ? List<dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  List<dynamic>? _decodeList(String? value) => _decodeAtUsers(value);

  int _scopeUserId(String scope) {
    final separator = scope.lastIndexOf('|');
    return int.tryParse(
          separator < 0 ? scope : scope.substring(separator + 1),
        ) ??
        0;
  }
}
