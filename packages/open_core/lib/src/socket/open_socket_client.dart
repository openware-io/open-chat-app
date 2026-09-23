abstract interface class GvSocketClient {
  void Function(dynamic data)? get onChatReceive;
  set onChatReceive(void Function(dynamic data)? callback);

  void Function(dynamic data)? get onChatAck;
  set onChatAck(void Function(dynamic data)? callback);

  void Function(dynamic data)? get onReadNotify;
  set onReadNotify(void Function(dynamic data)? callback);

  void Function(dynamic data)? get onRecallNotify;
  set onRecallNotify(void Function(dynamic data)? callback);

  void Function(dynamic data)? get onMessageDeletedNotify;
  set onMessageDeletedNotify(void Function(dynamic data)? callback);
  void Function(dynamic data)? get onMessageEditedNotify;
  set onMessageEditedNotify(void Function(dynamic data)? callback);

  /// 私密消息销毁事件（服务端权威销毁后主动推送，客户端立即移除本地消息）。
  void Function(dynamic data)? get onChatSecretDestroyed;
  set onChatSecretDestroyed(void Function(dynamic data)? callback);

  /// 私密消息存储事件（在线接收方收到服务端轻量信号后，立即拉取密文）。
  void Function(dynamic data)? get onChatSecretStored;
  set onChatSecretStored(void Function(dynamic data)? callback);

  /// 私密聊天创建事件（对方新建私密聊天时推送，本端同步会话并完成握手）。
  void Function(dynamic data)? get onChatSecretCreated;
  set onChatSecretCreated(void Function(dynamic data)? callback);

  /// 私密聊天终止事件（对方删除私密聊天时推送，本端移除会话并清空本地消息）。
  void Function(dynamic data)? get onChatSecretDeleted;
  set onChatSecretDeleted(void Function(dynamic data)? callback);

  /// 私密群聊消息存储事件（在线接收方收到服务端轻量信号后，立即拉取密文）。
  void Function(dynamic data)? get onChatSecretGroupStored;
  set onChatSecretGroupStored(void Function(dynamic data)? callback);

  void Function(dynamic data)? get onTyping;
  set onTyping(void Function(dynamic data)? callback);

  void Function(dynamic data)? get onUserStatusChange;
  set onUserStatusChange(void Function(dynamic data)? callback);

  void Function(dynamic data)? get onFriendRequestNotify;
  set onFriendRequestNotify(void Function(dynamic data)? callback);

  void Function(dynamic data)? get onFriendAcceptNotify;
  set onFriendAcceptNotify(void Function(dynamic data)? callback);

  void Function(dynamic data)? get onClearPrivateChatNotify;
  set onClearPrivateChatNotify(void Function(dynamic data)? callback);

  void Function(dynamic data)? get onClearGroupChatNotify;
  set onClearGroupChatNotify(void Function(dynamic data)? callback);

  void Function(dynamic data)? get onGroupDissolveNotify;
  set onGroupDissolveNotify(void Function(dynamic data)? callback);
  void Function(dynamic data)? get onGroupNotify;
  set onGroupNotify(void Function(dynamic data)? callback);

  void Function(dynamic data)? get onRtcSignal;
  set onRtcSignal(void Function(dynamic data)? callback);

  void Function(dynamic data)? get onError;
  set onError(void Function(dynamic data)? callback);

  bool get connected;

  bool get hasClient;

  void connect(String token);

  void disconnect();

  void reconnectIfNeeded();

  void emitChat(String event, dynamic data);
}
