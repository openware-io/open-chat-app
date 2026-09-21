/// 本机结束、取消或拒绝通话后，用于写入一条 [msgType] 为 `call` 的摘要。
class OutgoingCallTrace {
  const OutgoingCallTrace({
    required this.peerId,
    required this.chatType,
    required this.media,
    required this.kind,
    required this.durationSec,
    this.callId,
  });

  final String peerId;
  final String chatType;
  final String? callId;

  /// `video` 或 `audio`（与 [CallProvider.mediaType] 一致）。
  final String media;

  /// `completed` | `cancelled` | `rejected` | `busy` | `failed` | `resolved`。
  final String kind;

  /// 已接通时通话时长（秒）；未接通为 0。
  final int durationSec;
}
