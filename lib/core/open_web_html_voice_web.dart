import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// 原生 `<audio>` 直连扬声器；不使用 Web Audio 的 [MediaElementAudioSourceNode]，
/// 避免 `audioplayers_web` 在无声音频图下「进度走、UI 动但不发声」。
web.HTMLAudioElement? _gvWebVoiceEl;
StreamSubscription<web.Event>? _gvWebVoiceEndedSub;
void Function()? _gvWebVoiceOnEnded;

void gvWebHtmlVoiceStopSync() {
  unawaited(_gvWebVoiceEndedSub?.cancel() ?? Future<void>.value());
  _gvWebVoiceEndedSub = null;
  _gvWebVoiceOnEnded = null;
  final e = _gvWebVoiceEl;
  _gvWebVoiceEl = null;
  if (e != null) {
    e.pause();
    e.removeAttribute('src');
    e.remove();
  }
}

Future<void> gvWebHtmlVoicePlay(
  String src, {
  required void Function() onEnded,
}) async {
  gvWebHtmlVoiceStopSync();
  _gvWebVoiceOnEnded = onEnded;
  final a = web.HTMLAudioElement();
  a.src = src;
  a.volume = 1.0;
  _gvWebVoiceEl = a;
  _gvWebVoiceEndedSub = a.onEnded.listen((_) {
    final cb = _gvWebVoiceOnEnded;
    _gvWebVoiceOnEnded = null;
    gvWebHtmlVoiceStopSync();
    cb?.call();
  });
  await a.play().toDart;
}

Future<double?> gvWebHtmlVoiceProbeDurationSec(String src) async {
  final a = web.HTMLAudioElement();
  final done = Completer<double?>();
  late final StreamSubscription<web.Event> sub;
  var finished = false;

  void finish(double? sec) {
    if (finished) return;
    finished = true;
    unawaited(sub.cancel());
    a.pause();
    a.removeAttribute('src');
    a.remove();
    if (!done.isCompleted) done.complete(sec);
  }

  sub = a.onLoadedMetadata.listen((_) {
    final d = a.duration;
    if (d.isFinite && d > 0) {
      finish(d);
    } else {
      finish(null);
    }
  });

  final timer = Timer(const Duration(seconds: 6), () => finish(null));
  a.src = src;
  try {
    final r = await done.future;
    return r;
  } finally {
    timer.cancel();
  }
}
