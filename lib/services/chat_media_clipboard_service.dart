import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path_provider/path_provider.dart';

import 'im_api.dart';

/// 聊天媒体与系统剪贴板之间的适配层。
///
/// 图片使用系统位图剪贴板；视频使用桌面系统的文件剪贴板。移动端与
/// Web 的系统剪贴板不提供可靠的视频文件写入能力，因此不声明支持。
class GvChatMediaClipboardService {
  const GvChatMediaClipboardService();

  static final RegExp _imagePathPattern = RegExp(
    r'\.(?:png|jpe?g|jfif|gif|webp|bmp|tiff?)$',
    caseSensitive: false,
  );
  static final RegExp _videoPathPattern = RegExp(
    r'\.(?:mp4|m4v|mov|webm|avi|mkv|3gp)$',
    caseSensitive: false,
  );

  static bool get supportsImageCopy =>
      kIsWeb || defaultTargetPlatform != TargetPlatform.fuchsia;

  static bool get supportsVideoFileClipboard =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  static bool isImageFilePath(String value) =>
      _imagePathPattern.hasMatch(_pathWithoutQuery(value));

  static bool isVideoFilePath(String value) =>
      _videoPathPattern.hasMatch(_pathWithoutQuery(value));

  Future<Uint8List?> readImageBytes() async {
    try {
      final image = await Pasteboard.image;
      if (image != null && image.isNotEmpty) return image;
    } catch (error, stackTrace) {
      debugPrint('Failed to read clipboard bitmap: $error\n$stackTrace');
    }

    try {
      final paths = await Pasteboard.files();
      for (final path in paths) {
        if (!isImageFilePath(path)) continue;
        final bytes = await File(path).readAsBytes();
        if (bytes.isNotEmpty) return bytes;
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to read clipboard image file: $error\n$stackTrace');
    }
    return null;
  }

  Future<String?> readVideoFilePath() async {
    if (!supportsVideoFileClipboard) return null;
    try {
      final paths = await Pasteboard.files();
      for (final path in paths) {
        if (isVideoFilePath(path) && await File(path).exists()) return path;
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to read clipboard video file: $error\n$stackTrace');
    }
    return null;
  }

  Future<void> copyImage({
    required ImApi api,
    required String imageUrl,
  }) async {
    if (!supportsImageCopy) {
      throw UnsupportedError('Image clipboard is not supported');
    }
    // pasteboard 的 Linux 实现不支持位图写入；以文件形式写入后，本应用的
    // 粘贴逻辑仍可按图片读取并发送。
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
      final path = await _downloadToClipboardCache(
        api: api,
        mediaUrl: imageUrl,
        prefix: 'image',
        fallbackExtension: '.jpg',
      );
      final copied = await Pasteboard.writeFiles([path]);
      if (!copied) throw StateError('Failed to copy image file');
      return;
    }

    final bytes = await api.downloadFileBytes(imageUrl);
    if (bytes.isEmpty) throw StateError('Downloaded image is empty');
    await Pasteboard.writeImage(bytes);
  }

  Future<void> copyVideo({
    required ImApi api,
    required String videoUrl,
  }) async {
    if (!supportsVideoFileClipboard) {
      throw UnsupportedError('Video file clipboard is not supported');
    }
    final path = await _downloadToClipboardCache(
      api: api,
      mediaUrl: videoUrl,
      prefix: 'video',
      fallbackExtension: '.mp4',
    );
    final copied = await Pasteboard.writeFiles([path]);
    if (!copied) throw StateError('Failed to copy video file');
  }

  static Future<String> _downloadToClipboardCache({
    required ImApi api,
    required String mediaUrl,
    required String prefix,
    required String fallbackExtension,
  }) async {
    final temp = await getTemporaryDirectory();
    final folder = Directory('${temp.path}/gv_chat_clipboard');
    if (!await folder.exists()) await folder.create(recursive: true);
    final candidate = _fileExtension(mediaUrl);
    final supportedCandidate = prefix == 'image'
        ? candidate != null && isImageFilePath(candidate)
        : candidate != null && isVideoFilePath(candidate);
    final extension = supportedCandidate ? candidate : fallbackExtension;
    final path =
        '${folder.path}/${prefix}_${DateTime.now().microsecondsSinceEpoch}$extension';
    await api.downloadFileToPath(mediaUrl, path);
    if (!await File(path).exists() || await File(path).length() == 0) {
      throw StateError('Downloaded media is empty');
    }
    return path;
  }

  static String? _fileExtension(String value) {
    final path = _pathWithoutQuery(value);
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return null;
    final extension = path.substring(dot).toLowerCase();
    return RegExp(r'^\.[a-z0-9]{1,5}$').hasMatch(extension) ? extension : null;
  }

  static String _pathWithoutQuery(String value) {
    final uri = Uri.tryParse(value);
    return uri == null || uri.path.isEmpty ? value.split('?').first : uri.path;
  }
}
