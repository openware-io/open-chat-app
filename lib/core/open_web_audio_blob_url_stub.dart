import 'dart:typed_data';

/// Stub：仅在非 js_interop 目标（VM）下参与编译；语音播放走原生路径，不应调用。
String gvCreateBlobUrlForAudioBytes(Uint8List bytes, String mimeType) {
  throw UnsupportedError('gvCreateBlobUrlForAudioBytes is web-only');
}

void gvRevokeBlobUrlForAudio(String url) {}
