import 'dart:typed_data';

typedef WebClipboardImageListenerDisposer = void Function();

WebClipboardImageListenerDisposer listenForWebClipboardImages({
  required bool Function() isEnabled,
  required void Function(Uint8List bytes) onImage,
}) {
  return () {};
}
