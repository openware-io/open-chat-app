import 'package:flutter_test/flutter_test.dart';
import 'package:gv_core/gv_core.dart' show GvSocketClient;

import 'package:open_chat_app/models/chat_message.dart';
import 'package:open_chat_app/providers/chat/chat_outbound_message_coordinator.dart';

/// 普通消息「一直发送中」事故回归测试。
///
/// 背景：历史版本遗留的 secret pending 消息在重连时被 retryPendingMessages 以
/// `chat:send` 重发，服务端 ChatType 枚举无法解析 `secret` 并把整个 WebSocket
/// 连接以 1011 强踢，导致后续所有普通消息一直「发送中」。
///
/// 修复：私密消息走 HTTP /secret-messages（E2EE 密文链路），retryPendingMessages
/// 必须跳过并清理 secret pending，绝不通过 WS chat:send 重发。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingSocket socket;
  late Map<String, ChatMessage> pendingAcks;
  late Map<String, List<ChatMessage>> messageMap;
  late List<String> removedClientMsgIds;
  late ChatOutboundMessageCoordinator coordinator;

  ChatMessage message(String clientMsgId, String chatType) => ChatMessage(
        msgId: clientMsgId,
        from: 1,
        toId: '9',
        chatType: chatType,
        msgType: 'text',
        content: 'hello',
        timestamp: DateTime.utc(2026, 8, 19),
        clientMsgId: clientMsgId,
        status: 'sending',
      );

  setUp(() {
    socket = _RecordingSocket();
    pendingAcks = {};
    messageMap = {};
    removedClientMsgIds = [];
    coordinator = ChatOutboundMessageCoordinator(
      socket: socket,
      myId: () => 1,
      selfDisplayName: () => 'sender',
      chatKey: (chatType, peerId) => '$chatType:$peerId',
      messageMap: messageMap,
      pendingAcks: pendingAcks,
      upsertConversation: (peerId, chatType, lastMsg,
          {bool incrementUnread = false, String? name, DateTime? lastTime}) {},
      refreshConversationLastFromSession: (key) {},
      persistPendingMessage: (peerId, msg) {},
      confirmPendingMessage: (peerId, clientMsgId, confirmed) {},
      removePendingMessage: (clientMsgId) => removedClientMsgIds.add(clientMsgId),
      enqueueWsError: (_) {},
      notifyChanged: () {},
    );
  });

  test('重连重发时跳过并清理 secret pending，绝不通过 WS chat:send 重发', () {
    pendingAcks['secret-client-1'] = message('secret-client-1', 'secret');
    pendingAcks['normal-client-2'] = message('normal-client-2', 'private');

    coordinator.retryPendingMessages();

    // secret pending 被清理且未发出 WS 帧
    expect(pendingAcks.containsKey('secret-client-1'), isFalse);
    expect(removedClientMsgIds, contains('secret-client-1'));
    // 普通 pending 正常重发
    expect(socket.emitPayloads.map((p) => p['clientMsgId']), ['normal-client-2']);
    expect(socket.emitPayloads.single['chatType'], 'private');
  });

  test('secret pending 不应出现在 WS chat:send 载荷中（防服务端拒绝踢连接）', () {
    pendingAcks['secret-client-3'] = message('secret-client-3', 'secret');
    pendingAcks['group-client-4'] = message('group-client-4', 'group');

    coordinator.retryPendingMessages();

    final chatTypes = socket.emitPayloads.map((p) => p['chatType']).toList();
    expect(chatTypes, isNot(contains('secret')));
    expect(chatTypes, ['group']);
  });
}

/// 记录 emitChat 调用的最小 Socket 替身。
class _RecordingSocket implements GvSocketClient {
  final List<Map<String, dynamic>> emitPayloads = [];

  @override
  bool get connected => true;

  @override
  bool get hasClient => true;

  @override
  void emitChat(String event, dynamic payload) {
    emitPayloads.add(Map<String, dynamic>.from(payload as Map));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
