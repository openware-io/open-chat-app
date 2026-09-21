/// 通话信令和 TURN/ICE 配置边界。
///
/// WebRTC 状态机仍留在 CallProvider，网络通道和配置来源由 Repository 隔离。
abstract interface class CallRepository {
  bool get signalingConnected;

  Future<Map<String, dynamic>> rtcIceConfig();

  void reconnectSignalingIfNeeded();

  void emitRtcSignal(Map<String, dynamic> payload);
}
