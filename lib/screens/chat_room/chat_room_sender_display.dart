import '../../core/local_storage.dart';
import '../../l10n/app_localizations.dart';
import '../../models/chat_message.dart';
import '../../providers/chat_provider.dart';
import '../../providers/friend_provider.dart';
import '../../providers/group_provider.dart';

/// 根据会话类型与好友/群成员缓存，解析消息气泡左侧/右侧展示的发送者显示名。
///
/// - 自己：固定返回「我」。
/// - 私聊：优先通讯录备注/名称，其次消息携带的用户名，最后兜底 `用户{id}`。
/// - 群聊：优先群成员昵称，其余与私聊类似。
String messageTileSenderName(
  ChatMessage msg,
  int myId,
  ChatProvider chat,
  FriendProvider friend,
  GroupProvider group,
  String roomChatType,
  AppLocalizations l10n, {
  bool anonymousEnabled = false,
}) {
  if (msg.from == myId) return l10n.chatReplySelfShort;
  // 匿名/群级隐私：他人消息发送者身份对成员隐藏（仅显示「群成员」）。
  // 私密群「匿名发言」对所有人隐藏；普通群「禁止互加好友」仅对非好友隐藏，好友仍显示真实昵称。
  if (roomChatType == 'secret_group' && anonymousEnabled) {
    return '群成员';
  }
  if (roomChatType == 'group' &&
      anonymousEnabled &&
      friend.getFriendDisplay(msg.from) == null) {
    return '群成员';
  }
  if (roomChatType == 'private') {
    final fd = friend.getFriendDisplay(msg.from);
    final n = fd?.name.trim();
    if (n != null && n.isNotEmpty) return n;
  }
  if (roomChatType == 'group') {
    final fd = friend.getFriendDisplay(msg.from);
    final n = fd?.name.trim();
    if (n != null && n.isNotEmpty) return n;
    final m = group.memberByUserId(msg.from);
    if (m != null) {
      final groupNick = m.nickname?.trim();
      if (groupNick != null && groupNick.isNotEmpty) return groupNick;
      final fd = friend.getFriendDisplay(msg.from);
      final globalNick = fd?.name.trim();
      if (globalNick != null && globalNick.isNotEmpty) return globalNick;
      return l10n.chatUserDefaultTitle('${msg.from}');
    }
    // 群内隐私：未命中群成员缓存时不回落到账号（username），用通用兜底。
    return l10n.chatUserDefaultTitle('${msg.from}');
  }
  if (roomChatType == 'secret_group') {
    // 私密群聊：复用好友通讯录昵称回填发送方。
    final fd = friend.getFriendDisplay(msg.from);
    final n = fd?.name.trim();
    if (n != null && n.isNotEmpty) return n;
    return l10n.chatUserDefaultTitle('${msg.from}');
  }
  final u = msg.fromUsername?.trim();
  if (u != null && u.isNotEmpty) return u;
  return l10n.chatUserDefaultTitle('${msg.from}');
}

/// 解析头像 URL：自己读本地 [LocalStorage]；他人优先消息内联头像，再查好友/群资料。
String? messageTileSenderAvatar(
  ChatMessage msg,
  int myId,
  ChatProvider chat,
  FriendProvider friend,
  GroupProvider group,
  LocalStorage storage,
  String roomChatType, {
  bool anonymousEnabled = false,
}) {
  if (msg.from == myId) {
    final j = storage.userJson;
    final av = j?['avatar'];
    if (av is String && av.trim().isNotEmpty) return av.trim();
    return null;
  }
  // 匿名/群级隐私：隐藏发送者头像，走通用占位头像。
  // 私密群「匿名发言」对所有人隐藏；普通群「禁止互加好友」仅对非好友隐藏。
  if (roomChatType == 'secret_group' && anonymousEnabled) {
    return null;
  }
  if (roomChatType == 'group' &&
      anonymousEnabled &&
      friend.getFriendDisplay(msg.from) == null) {
    return null;
  }
  final a = msg.fromAvatar?.trim();
  if (a != null && a.isNotEmpty) return a;
  if (roomChatType == 'private') {
    return friend.getFriendDisplay(msg.from)?.avatar;
  }
  if (roomChatType == 'group') {
    return group.memberByUserId(msg.from)?.avatar;
  }
  if (roomChatType == 'secret_group') {
    return friend.getFriendDisplay(msg.from)?.avatar;
  }
  return null;
}
