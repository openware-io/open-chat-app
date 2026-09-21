/// VM / 非 Web 目标占位；语音播放走 [AudioPlayer]，不应调用。
void gvWebHtmlVoiceStopSync() {}

Future<void> gvWebHtmlVoicePlay(
  String src, {
  required void Function() onEnded,
}) async {}

Future<double?> gvWebHtmlVoiceProbeDurationSec(String src) async => null;
