import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/core/open_qr_image_decode.dart';
import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

void main() {
  const payload = 'OPEN_UID:photo_scan_user';

  test('decodes a clean saved QR image', () async {
    final bytes = Uint8List.fromList(img.encodePng(_qrImage(payload)));

    expect(await gvDecodeQrFromImageBytes(bytes), payload);
  });

  test('decodes a QR from a compressed phone-screen photo', () async {
    final photo = img.Image(width: 1600, height: 1200, numChannels: 3);
    img.fill(photo, color: img.ColorRgb8(224, 228, 234));

    final qr = _qrImage(payload, moduleSize: 12);
    img.compositeImage(photo, qr, dstX: 470, dstY: 250);
    final rotated = img.copyRotate(
      photo,
      angle: 2.5,
      interpolation: img.Interpolation.linear,
    );
    final bytes = Uint8List.fromList(img.encodeJpg(rotated, quality: 62));

    expect(await gvDecodeQrFromImageBytes(bytes), payload);
  });

  test('returns null for an image without a QR code', () async {
    final image = img.Image(width: 320, height: 240, numChannels: 3);
    img.fill(image, color: img.ColorRgb8(90, 140, 190));

    final bytes = Uint8List.fromList(img.encodeJpg(image));

    expect(await gvDecodeQrFromImageBytes(bytes), isNull);
  });
}

img.Image _qrImage(
  String payload, {
  int moduleSize = 8,
  int quietZoneModules = 4,
}) {
  final matrix = Encoder.encode(payload, ErrorCorrectionLevel.h).matrix!;
  final side = (matrix.width + quietZoneModules * 2) * moduleSize;
  final image = img.Image(width: side, height: side, numChannels: 3);
  img.fill(image, color: img.ColorRgb8(255, 255, 255));

  for (var y = 0; y < matrix.height; y++) {
    for (var x = 0; x < matrix.width; x++) {
      if (matrix.get(x, y) != 1) continue;
      final left = (x + quietZoneModules) * moduleSize;
      final top = (y + quietZoneModules) * moduleSize;
      img.fillRect(
        image,
        x1: left,
        y1: top,
        x2: left + moduleSize - 1,
        y2: top + moduleSize - 1,
        color: img.ColorRgb8(0, 0, 0),
      );
    }
  }
  return image;
}
