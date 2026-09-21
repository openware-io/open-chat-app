import '../services/im_api.dart';
import '../services/socket_service.dart';
import 'call_repository.dart';

/// ImApi + SocketService 版本的通话仓库。
class ImCallRepository implements CallRepository {
  ImCallRepository(this._socket, this._api);

  final SocketService _socket;
  final ImApi _api;

  @override
  bool get signalingConnected => _socket.connected;

  @override
  Future<Map<String, dynamic>> rtcIceConfig() => _api.rtcIceConfig();

  @override
  void reconnectSignalingIfNeeded() => _socket.reconnectIfNeeded();

  @override
  void emitRtcSignal(Map<String, dynamic> payload) {
    _socket.emitChat('rtc:signal', payload);
  }
}
