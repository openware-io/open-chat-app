import 'package:flutter_test/flutter_test.dart';

import 'package:gv_chat_app/models/chat_message.dart';
import 'package:gv_chat_app/providers/chat/chat_message_merge.dart';

void main() {
  group('insertChatMessageDeduplicated', () {
    ChatMessage message(String msgId, {int? seq, String content = 'x'}) {
      return ChatMessage(
        msgId: msgId,
        from: 1,
        toId: '2',
        chatType: 'secret',
        content: content,
        timestamp: DateTime.utc(2026, 8, 19, 0, 0, seq ?? 1),
        seq: seq,
      );
    }

    test('同 msgId 第二次插入被跳过（发送乐观插入 + 轮询拉取去重）', () {
      final list = <ChatMessage>[];
      // 第一次：发送方本地乐观插入（无 seq）。
      final first = message('m1');
      expect(insertChatMessageDeduplicated(list, first), isTrue);
      // 第二次：轮询拉到同一条服务端消息（带 seq），不应重复。
      final fromServer = message('m1', seq: 1);
      expect(insertChatMessageDeduplicated(list, fromServer), isFalse);
      expect(list.length, 1);
      expect(list.single.msgId, 'm1');
    });

    test('不同 msgId 正常按序插入', () {
      final list = <ChatMessage>[];
      insertChatMessageDeduplicated(list, message('m2', seq: 2));
      insertChatMessageDeduplicated(list, message('m1', seq: 1));
      expect(list.length, 2);
      expect(list.map((m) => m.msgId).toList(), ['m1', 'm2']);
    });
  });
}
