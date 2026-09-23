import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../models/chat_message.dart';

/// 打开聊天室：push 全屏页面。
void gvOpenChat(
  BuildContext context, {
  required String chatType,
  required String peerId,
  String? anchorMsgId,
  ChatMessage? anchorSeedMessage,
}) {
  var path = '/chat/$chatType/$peerId';
  if (anchorMsgId != null) {
    path += '?msg=${Uri.encodeComponent(anchorMsgId)}';
  }
  context.push(path, extra: anchorSeedMessage);
}
