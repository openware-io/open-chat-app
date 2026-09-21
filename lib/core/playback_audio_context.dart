import 'package:audioplayers/audioplayers.dart';

/// 聊天语音、来电铃声等应在扬声器外放的场景；避免 iOS 在通话/WebRTC 后仍走听筒路由。
Future<void> applyPlaybackSpeakerRoute(AudioPlayer player) async {
  try {
    await player.setAudioContext(
      AudioContextConfig(
        route: AudioContextConfigRoute.speaker,
        focus: AudioContextConfigFocus.gain,
      ).build(),
    );
  } catch (_) {
    // 会话被占用时可能失败，不阻断后续 play
  }
}
