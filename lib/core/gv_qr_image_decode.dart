import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

const int _maxWorkingDimension = 2048;
const int _retryDimension = 1400;
const List<int> _fullImageRetryDimensions = [1600, 1200, 900];

/// 从图片字节中解析首个 QR 码文本。
///
/// 解码会在后台 isolate 中完成，并依次尝试 EXIF 方向校正、多尺度、旋转、
/// 对比度增强和重叠裁剪，适用于保存的二维码以及手机拍摄屏幕得到的照片。
Future<String?> gvDecodeQrFromImageBytes(Uint8List bytes) {
  return compute(_decodeQrImage, bytes);
}

String? _decodeQrImage(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;

  final oriented = img.bakeOrientation(decoded);
  final working = _resizeToFit(oriented, _maxWorkingDimension);
  final attemptedSizes = <(int, int)>{};

  String? tryImage(img.Image candidate) {
    final key = (candidate.width, candidate.height);
    if (!attemptedSizes.add(key)) return null;
    return _decodeCandidate(candidate);
  }

  // 快速路径：清晰原图通常会在第一次尝试直接成功。
  var result = tryImage(working);
  if (result != null) return result;

  // 拍屏照片的摩尔纹会随缩放比例变化；尝试几个受控尺度往往比单次原图可靠。
  for (final dimension in _fullImageRetryDimensions) {
    result = tryImage(_resizeToFit(working, dimension));
    if (result != null) return result;
  }

  // 某些相册导出的图片没有可用 EXIF，显式尝试直角旋转作为兜底。
  final rotationBase = _resizeToFit(working, _retryDimension);
  for (final angle in const [90.0, 180.0, 270.0]) {
    result = _decodeCandidate(img.copyRotate(rotationBase, angle: angle));
    if (result != null) return result;
  }

  // 提升低对比度、反光或曝光不均照片中黑白模块的分离度。
  final enhancedBase = _resizeToFit(working, _retryDimension);
  for (final contrast in const [1.35, 1.7]) {
    final enhanced = img.adjustColor(
      img.grayscale(img.Image.from(enhancedBase)),
      contrast: contrast,
    );
    result = _decodeCandidate(enhanced);
    if (result != null) return result;
  }

  // 二维码通常位于照片中央。裁剪后再放大，可让较小的二维码模块达到可识别尺寸。
  for (final fraction in const [0.88, 0.72, 0.56]) {
    final crop = _centerCrop(working, fraction);
    result = _decodeCandidate(_resizeForRetry(crop));
    if (result != null) return result;
  }

  // 最后尝试四个彼此重叠的区域，兼容二维码没有严格居中的照片。
  for (final crop in _overlappingCrops(working)) {
    result = _decodeCandidate(_resizeForRetry(crop));
    if (result != null) return result;
  }

  return null;
}

String? _decodeCandidate(img.Image image) {
  if (image.width < 40 || image.height < 40) return null;

  final source = _rgbLuminanceSource(image);
  final hints = DecodeHints()..put(DecodeHintType.tryHarder);
  final reader = QRCodeReader();

  String? decode(BinaryBitmap bitmap) {
    try {
      final text = reader.decode(bitmap, hints: hints).text.trim();
      return text.isEmpty ? null : text;
    } catch (_) {
      reader.reset();
      return null;
    }
  }

  // Hybrid 对阴影/渐变更稳，Global 对低频、较平整图像有时更有效。
  var result = decode(BinaryBitmap(HybridBinarizer(source)));
  result ??= decode(BinaryBitmap(GlobalHistogramBinarizer(source)));
  result ??= decode(
    BinaryBitmap(HybridBinarizer(InvertedLuminanceSource(source))),
  );
  return result;
}

RGBLuminanceSource _rgbLuminanceSource(img.Image image) {
  final rgb =
      image.convert(numChannels: 3).getBytes(order: img.ChannelOrder.rgb);
  final pixels = Int32List(image.width * image.height);
  for (var pixelIndex = 0, byteIndex = 0;
      pixelIndex < pixels.length;
      pixelIndex++, byteIndex += 3) {
    pixels[pixelIndex] =
        (rgb[byteIndex] << 16) | (rgb[byteIndex + 1] << 8) | rgb[byteIndex + 2];
  }
  return RGBLuminanceSource(image.width, image.height, pixels);
}

img.Image _resizeToFit(img.Image source, int maxDimension) {
  final longest = math.max(source.width, source.height);
  if (longest <= maxDimension) return img.Image.from(source);
  final scale = maxDimension / longest;
  return img.copyResize(
    source,
    width: math.max(1, (source.width * scale).round()),
    height: math.max(1, (source.height * scale).round()),
    interpolation: img.Interpolation.linear,
  );
}

img.Image _resizeForRetry(img.Image source) {
  final longest = math.max(source.width, source.height);
  if (longest == _retryDimension) return source;
  final scale = _retryDimension / longest;
  return img.copyResize(
    source,
    width: math.max(1, (source.width * scale).round()),
    height: math.max(1, (source.height * scale).round()),
    interpolation: img.Interpolation.linear,
  );
}

img.Image _centerCrop(img.Image source, double fraction) {
  final side = (math.min(source.width, source.height) * fraction).round();
  return img.copyCrop(
    source,
    x: (source.width - side) ~/ 2,
    y: (source.height - side) ~/ 2,
    width: side,
    height: side,
  );
}

Iterable<img.Image> _overlappingCrops(img.Image source) sync* {
  final cropWidth = (source.width * 0.7).round();
  final cropHeight = (source.height * 0.7).round();
  final maxX = source.width - cropWidth;
  final maxY = source.height - cropHeight;
  for (final offset in [(0, 0), (maxX, 0), (0, maxY), (maxX, maxY)]) {
    yield img.copyCrop(
      source,
      x: offset.$1,
      y: offset.$2,
      width: cropWidth,
      height: cropHeight,
    );
  }
}
