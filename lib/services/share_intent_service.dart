import 'package:flutter/services.dart';

import '../models/shared_media_item.dart';

/// 接收系统「分享」进 App 的内容（原生 ACTION_SEND / ACTION_SEND_MULTIPLE）。
class ShareIntentService {
  static const MethodChannel _channel = MethodChannel('com.gv.chat/share_intent');

  /// 冷启动（分享直接拉起 App）时暂存的分享内容；[onSharedMediaReceived] 只用于热启动回调。
  List<SharedMediaItem>? _pending;
  List<SharedMediaItem>? get pending => _pending;

  /// 热启动（App 已在运行）时收到分享内容的回调。
  void Function(List<SharedMediaItem> items)? onSharedMediaReceived;

  Future<void> init() async {
    _channel.setMethodCallHandler(_handleCall);
    // 冷启动：从原生取回排队中的分享内容（原生在 configureFlutterEngine 已解析并存暂存）。
    try {
      final raw = await _channel.invokeMethod('getPendingShare');
      if (raw is List && raw.isNotEmpty) {
        _pending = _parse(raw);
      }
    } catch (_) {}
  }

  Future<dynamic> _handleCall(MethodCall call) async {
    if (call.method == 'onSharedMedia') {
      final args = call.arguments;
      if (args is List && args.isNotEmpty) {
        _pending = _parse(args);
        onSharedMediaReceived?.call(_pending!);
      }
    }
    return null;
  }

  void clear() {
    _pending = null;
  }

  List<SharedMediaItem> _parse(List<dynamic> raw) =>
      raw.whereType<Map>().map(SharedMediaItem.fromMap).toList();
}
