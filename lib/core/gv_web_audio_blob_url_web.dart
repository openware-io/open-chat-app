import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// 将已下载音频字节交给 `<audio>` / audioplayers_web，避免 `data:` + `crossOrigin=anonymous` 导致无声。
String gvCreateBlobUrlForAudioBytes(Uint8List bytes, String mimeType) {
  final u8 = bytes.toJS;
  final parts = <web.BlobPart>[u8].toJS;
  final blob = web.Blob(
    parts,
    web.BlobPropertyBag(type: mimeType),
  );
  return web.URL.createObjectURL(blob);
}

void gvRevokeBlobUrlForAudio(String url) {
  if (url.startsWith('blob:')) {
    web.URL.revokeObjectURL(url);
  }
}
