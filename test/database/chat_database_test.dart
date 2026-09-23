import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/database/chat_database.dart';
import 'package:open_core/open_core.dart';

void main() {
  late ChatDatabase database;

  setUp(() {
    database = ChatDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('conversation cache is isolated by server and account scope', () async {
    final conversation = Conversation(
      id: '8',
      chatType: 'private',
      name: 'Alice',
      lastTime: DateTime.utc(2026, 7, 29),
    );

    await database.replaceConversations('https://a.example|1', [conversation]);

    expect(
      await database.loadConversations('https://a.example|1'),
      hasLength(1),
    );
    expect(
      await database.loadConversations('https://a.example|2'),
      isEmpty,
    );
    expect(
      await database.loadConversations('https://b.example|1'),
      isEmpty,
    );
  });

  test('server acknowledgement replaces optimistic message once', () async {
    const scope = 'https://a.example|1';
    const peerId = '8';
    final createdAt = DateTime.utc(2026, 7, 29, 10);
    final pending = ChatMessage(
      msgId: 'client-1',
      from: 1,
      toId: peerId,
      chatType: 'private',
      msgType: 'text',
      content: 'hello',
      timestamp: createdAt,
      clientMsgId: 'client-1',
      status: 'sending',
    );

    await database.savePendingMessage(scope, peerId, pending);
    expect(await database.loadPendingMessages(scope), hasLength(1));

    final confirmed = pending.copyWith(
      msgId: 'server-99',
      timestamp: createdAt.add(const Duration(seconds: 1)),
      seq: 41,
      status: 'sent',
    );
    await database.confirmPendingMessage(
      scope,
      peerId,
      'client-1',
      confirmed,
    );

    expect(await database.loadPendingMessages(scope), isEmpty);
    final messages = await database.loadLatestMessages(
      scope,
      peerId,
      'private',
    );
    expect(messages, hasLength(1));
    expect(messages.single.msgId, 'server-99');
    expect(messages.single.clientMsgId, 'client-1');
    expect(messages.single.seq, 41);
    expect(messages.single.status, 'sent');
  });

  test('clearing a session removes cached and pending messages', () async {
    const scope = 'https://a.example|1';
    const peerId = '8';
    final pending = ChatMessage(
      msgId: 'client-2',
      from: 1,
      toId: peerId,
      chatType: 'private',
      content: 'pending',
      timestamp: DateTime.utc(2026, 7, 29, 11),
      clientMsgId: 'client-2',
      status: 'sending',
    );
    await database.savePendingMessage(scope, peerId, pending);

    await database.clearSession(scope, peerId, 'private');

    expect(
      await database.loadLatestMessages(scope, peerId, 'private'),
      isEmpty,
    );
    expect(await database.loadPendingMessages(scope), isEmpty);
  });

  test('pending media object ids survive an app restart', () async {
    const scope = 'https://a.example|1';
    final pending = ChatMessage(
      msgId: 'client-media-1',
      from: 1,
      toId: '8',
      chatType: 'private',
      msgType: 'voice',
      content: 'http://media.example/voice.m4a?signature=1',
      timestamp: DateTime.utc(2026, 8, 4),
      clientMsgId: 'client-media-1',
      mediaObjectIds: const ['voice-object-1'],
      status: 'sending',
    );

    await database.savePendingMessage(scope, '8', pending);
    final restored = await database.loadPendingMessages(scope);

    expect(restored.single.mediaObjectIds, ['voice-object-1']);
  });

  test('message sync page commits messages conversations and watermark',
      () async {
    const scope = 'https://a.example|1';
    final timestamp = DateTime.utc(2026, 8, 17, 9);
    final message = ChatMessage(
      msgId: 'sync-7',
      from: 8,
      toId: '1',
      chatType: 'private',
      content: 'offline hello',
      timestamp: timestamp,
      seq: 12,
    );
    final conversation = Conversation(
      id: '8',
      chatType: 'private',
      name: 'Alice',
      lastMessage: 'offline hello',
      lastTime: timestamp,
      unread: 1,
    );

    await database.applyMessageSyncPage(
      scope,
      [(peerId: '8', message: message)],
      [conversation],
      7,
    );

    expect(await database.loadLastSyncedSyncSeq(scope), 7);
    expect(await database.loadLastSyncedSyncSeq('https://a.example|2'), 0);
    expect(
      (await database.loadLatestMessages(scope, '8', 'private')).single.msgId,
      'sync-7',
    );
    expect((await database.loadConversations(scope)).single.unread, 1);
  });

  test('message sync watermark never moves backwards', () async {
    const scope = 'https://a.example|1';
    await database.applyMessageSyncPage(scope, const [], const [], 9);

    await expectLater(
      database.applyMessageSyncPage(scope, const [], const [], 8),
      throwsStateError,
    );

    expect(await database.loadLastSyncedSyncSeq(scope), 9);
  });

  test('conversation muted and draft survive a round trip', () async {
    const scope = 'https://a.example|1';
    final conversation = Conversation(
      id: '8',
      chatType: 'group',
      name: 'Alpha',
      lastTime: DateTime.utc(2026, 7, 29),
      muted: true,
      draftText: 'hello draft',
    );

    await database.replaceConversations(scope, [conversation]);

    final loaded = (await database.loadConversations(scope)).single;
    expect(loaded.muted, isTrue);
    expect(loaded.draftText, 'hello draft');
  });

  test('updateConversationDraft clears on empty value', () async {
    const scope = 'https://a.example|1';
    final conversation = Conversation(
      id: '8',
      chatType: 'private',
      name: 'Alice',
      lastTime: DateTime.utc(2026, 7, 29),
    );
    await database.replaceConversations(scope, [conversation]);

    await database.updateConversationDraft(scope, '8', 'private', 'draft-x');
    expect(
      (await database.loadConversations(scope)).single.draftText,
      'draft-x',
    );

    await database.updateConversationDraft(scope, '8', 'private', '');
    expect(
      (await database.loadConversations(scope)).single.draftText,
      isNull,
    );
  });
}
