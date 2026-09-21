import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

typedef WebClipboardImageListenerDisposer = void Function();

WebClipboardImageListenerDisposer listenForWebClipboardImages({
  required bool Function() isEnabled,
  required void Function(Uint8List bytes) onImage,
}) {
  void handlePaste(web.Event event) {
    if (!isEnabled()) return;
    final clipboardEvent = event as web.ClipboardEvent;
    final clipboardData = clipboardEvent.clipboardData;
    if (clipboardData == null) return;

    final items = clipboardData.items;
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      if (item.kind != 'file' || !item.type.startsWith('image/')) continue;
      final file = item.getAsFile();
      if (file == null) continue;
      event
        ..preventDefault()
        ..stopPropagation();
      unawaited(_readImageFile(file, onImage));
      return;
    }
  }

  final listener = handlePaste.toJS;
  web.document.addEventListener('paste', listener, true.toJS);
  return () {
    web.document.removeEventListener('paste', listener, true.toJS);
  };
}

Future<void> _readImageFile(
  web.File file,
  void Function(Uint8List bytes) onImage,
) async {
  try {
    final buffer = await file.arrayBuffer().toDart;
    final bytes = buffer.toDart.asUint8List();
    if (bytes.isNotEmpty) onImage(bytes);
  } catch (error, stackTrace) {
    debugPrint('Failed to read pasted web image: $error\n$stackTrace');
  }
}
