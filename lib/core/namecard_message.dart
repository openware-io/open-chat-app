import 'dart:convert';

/// 私聊消息类型 `namecard` 的 [content] JSON：个人名片。
class NamecardPayload {
  const NamecardPayload({
    required this.userId,
    required this.displayName,
    required this.username,
    this.avatar,
  });

  final int userId;
  final String displayName;
  final String username;
  final String? avatar;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'displayName': displayName,
        'username': username,
        if (avatar != null && avatar!.trim().isNotEmpty) 'avatar': avatar,
      };

  String encode() => jsonEncode(toMap());

  static NamecardPayload? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final dynamic j = jsonDecode(raw);
      if (j is! Map) return null;
      final m = Map<String, dynamic>.from(j);
      final uidRaw = m['userId'] ?? m['user_id'];
      final id =
          uidRaw is int ? uidRaw : int.tryParse(uidRaw?.toString() ?? '');
      if (id == null || id <= 0) return null;
      var dn = (m['displayName'] ?? m['nickname'] ?? m['name'] ?? '')
          .toString()
          .trim();
      if (dn.isEmpty) dn = '用户$id';
      final un = (m['username'] ?? '').toString();
      final av = m['avatar'] as String?;
      return NamecardPayload(
        userId: id,
        displayName: dn,
        username: un,
        avatar: (av != null && av.trim().isNotEmpty) ? av.trim() : null,
      );
    } catch (_) {
      return null;
    }
  }
}
