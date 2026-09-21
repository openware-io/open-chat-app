/// 系统「分享」进 App 的单个内容项（图片/视频/文件/文本）。
class SharedMediaItem {
  const SharedMediaItem({
    required this.type,
    this.path,
    this.mimeType,
    this.displayName,
    this.text,
  });

  /// `text` / `image` / `video` / `file`。
  final String type;
  final String? path;
  final String? mimeType;
  final String? displayName;
  final String? text;

  factory SharedMediaItem.fromMap(Map<dynamic, dynamic> map) {
    String s(dynamic v) => v == null ? '' : '$v';
    return SharedMediaItem(
      type: s(map['type']),
      path: map['path'] == null ? null : s(map['path']),
      mimeType: map['mimeType'] == null ? null : s(map['mimeType']),
      displayName: map['displayName'] == null ? null : s(map['displayName']),
      text: map['text'] == null ? null : s(map['text']),
    );
  }

  /// 对应聊天消息类型：text / image / video / file。
  String get msgType => switch (type) {
        'image' => 'image',
        'video' => 'video',
        'text' => 'text',
        _ => 'file',
      };
}
