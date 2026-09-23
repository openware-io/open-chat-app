import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/screens/chat_room/chat_room_media_helpers.dart';
import 'package:image/image.dart' as img;

void main() {
  test('normalizes a Windows clipboard BMP to JPEG', () async {
    final source = img.Image(width: 4, height: 3);
    img.fill(source, color: img.ColorRgb8(20, 80, 160));
    final bmp = Uint8List.fromList(img.encodeBmp(source));

    final normalized = await gvPrepareClipboardImageBytes(bmp);

    expect(normalized, isNotNull);
    expect(normalized, isNotEmpty);
    expect(normalized![0], 0xFF);
    expect(normalized[1], 0xD8);
    final decoded = img.decodeImage(normalized);
    expect(decoded?.width, 4);
    expect(decoded?.height, 3);
  });

  test('rejects non-image clipboard bytes', () async {
    final normalized = await gvPrepareClipboardImageBytes(
      Uint8List.fromList('not an image'.codeUnits),
    );

    expect(normalized, isNull);
  });
}
