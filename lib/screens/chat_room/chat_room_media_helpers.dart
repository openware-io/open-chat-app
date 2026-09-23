import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:open_chat_app/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:gv_ui/gv_ui.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../core/app_colors.dart';
import '../../core/gv_toast.dart';
import '../../services/im_api.dart';
import 'chat_room_constants.dart';

/// 清理下载文件名中的非法文件系统字符，避免保存失败。
String gvSanitizeDownloadFileName(String name) {
  var s = name.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1f]'), '_').trim();
  if (s.isEmpty) s = 'file';
  return s;
}

/// 异步解码图片字节的像素宽高；失败时返回 `null`（用于气泡布局，Web 友好）。
Future<(int, int)?> gvDecodeImageSizeFromBytes(Uint8List bytes) async {
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final w = image.width;
    final h = image.height;
    image.dispose();
    return (w, h);
  } catch (_) {
    return null;
  }
}

/// 异步解码本地图片文件的像素宽高；失败时返回 `null`（用于气泡布局）。
Future<(int, int)?> gvDecodeImageSize(File file) async {
  try {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final w = image.width;
    final h = image.height;
    image.dispose();
    return (w, h);
  } catch (_) {
    return null;
  }
}

/// 自定义表情：裁切后若边长大于 400 则缩到 400 再编码为 JPEG。
Uint8List gvPrepareStickerBytes(Uint8List cropped) {
  try {
    final decoded = img.decodeImage(cropped);
    if (decoded == null) return cropped;
    if (decoded.width <= 400 && decoded.height <= 400) {
      return Uint8List.fromList(img.encodeJpg(decoded, quality: 88));
    }
    final resized = img.copyResize(decoded,
        width: 400, interpolation: img.Interpolation.linear);
    return Uint8List.fromList(img.encodeJpg(resized, quality: 88));
  } catch (_) {
    return cropped;
  }
}

/// 聊天上传图片：宽大于 750 时等比压到 750；否则原样返回字节（Web 等无需落盘）。
Future<Uint8List> gvPrepareChatImageBytesForUpload(Uint8List bytes) async {
  try {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    if (decoded.width <= 750) return bytes;
    final resized = img.copyResize(
      decoded,
      width: 750,
      interpolation: img.Interpolation.linear,
    );
    return Uint8List.fromList(img.encodeJpg(resized, quality: 88));
  } catch (_) {
    return bytes;
  }
}

/// Normalizes clipboard bitmap/file bytes to JPEG so Windows DIB/BMP data is
/// previewable and its upload filename matches the actual byte format.
Future<Uint8List?> gvPrepareClipboardImageBytes(Uint8List bytes) async {
  try {
    var decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    if (decoded.width > 750) {
      decoded = img.copyResize(
        decoded,
        width: 750,
        interpolation: img.Interpolation.linear,
      );
    }
    return Uint8List.fromList(img.encodeJpg(decoded, quality: 88));
  } catch (_) {
    return null;
  }
}

/// 聊天上传图片：宽大于 750 时等比压到 750；否则原图上传。
Future<File> gvPrepareChatImageForUpload(File file) async {
  try {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return file;
    if (decoded.width <= 750) return file;
    final resized = img.copyResize(
      decoded,
      width: 750,
      interpolation: img.Interpolation.linear,
    );
    final jpg = img.encodeJpg(resized, quality: 88);
    final dir = await getTemporaryDirectory();
    final out = File(
      '${dir.path}/chat_img_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await out.writeAsBytes(jpg);
    return out;
  } catch (_) {
    return file;
  }
}

/// 聊天上传视频：宽大于 750 时按 [VideoQuality.Res640x480Quality] 压一版（宽不超过 750）；否则原文件。
Future<File> gvPrepareChatVideoForUpload(File file) async {
  if (kIsWeb) return file;
  if (!Platform.isAndroid && !Platform.isIOS) return file;
  try {
    final info = await VideoCompress.getMediaInfo(file.path);
    final w = info.width;
    if (w == null || w <= 750) return file;
    final out = await VideoCompress.compressVideo(
      file.path,
      quality: VideoQuality.Res640x480Quality,
      deleteOrigin: false,
      includeAudio: true,
    );
    final p = out?.path;
    if (p == null || p.isEmpty) return file;
    final f = File(p);
    if (await f.exists() && await f.length() > 0) return f;
    return file;
  } catch (_) {
    return file;
  }
}

Future<int?> gvReadVideoDurationMs(File file) async {
  if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return null;
  try {
    final duration = (await VideoCompress.getMediaInfo(file.path)).duration;
    if (duration == null || duration <= 0) return null;
    return duration.round();
  } catch (_) {
    return null;
  }
}

/// 尝试删除临时文件；忽略一切错误，避免影响发送主流程。
Future<void> gvTryDeleteFile(File? f) async {
  try {
    if (f != null && await f.exists()) await f.delete();
  } catch (_) {}
}

/// 本地视频抽首帧：优先 [VideoThumbnail.thumbnailFile]，再退回 [thumbnailData]。
Future<File?> gvExtractVideoThumbnailFile(File videoFile) async {
  final dir = await getTemporaryDirectory();
  final abs = videoFile.absolute.path;
  try {
    final path = await VideoThumbnail.thumbnailFile(
      video: abs,
      thumbnailPath: dir.path,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 750,
      quality: 75,
    );
    if (path != null && path.isNotEmpty) {
      final f = File(path);
      if (await f.exists() && await f.length() > 0) return f;
    }
  } catch (_) {}

  try {
    final bytes = await VideoThumbnail.thumbnailData(
      video: abs,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 750,
      quality: 75,
    );
    if (bytes != null && bytes.isNotEmpty) {
      final f = File(
        '${dir.path}/vthumb_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await f.writeAsBytes(bytes);
      return f;
    }
  } catch (_) {}
  return null;
}

/// 图片 / 视频封面在气泡内的显示尺寸：宽在「屏幕 1/4～1/2」之间（且不超过 [maxOuter]）。
///
/// [missingAspect] 在无元数据时作为高/宽比使用。
({double dw, double dh}) gvChatBubbleMediaDisplaySize(
  BuildContext context,
  double maxOuter,
  int? iw,
  int? ih, {
  double missingAspect = 1.0,
}) {
  final sw = MediaQuery.sizeOf(context).width;
  final capHalf = sw * 0.5;
  final floorQuarter = sw * 0.25;
  var maxW = math.min(maxOuter, capHalf);
  var minW = floorQuarter;
  if (minW > maxW) minW = maxW;

  if (iw != null && ih != null && iw > 0 && ih > 0) {
    const pxLo = 200;
    const pxHi = 900;
    final t = ((iw - pxLo) / (pxHi - pxLo)).clamp(0.0, 1.0);
    final dw = minW + t * (maxW - minW);
    final dh = dw * ih / iw;
    return (dw: dw, dh: dh);
  }

  final dw = (minW + maxW) / 2;
  final dh = dw * missingAspect;
  return (dw: dw, dh: dh);
}

/// 将远端文件下载到应用文档目录，并弹出加载圈与结果 Toast。
Future<void> gvRunChatFileDownload(
  BuildContext context, {
  required ImApi api,
  required String fileName,
  required String fileUrl,
}) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  try {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/gv_chat_downloads');
    if (!await folder.exists()) await folder.create(recursive: true);
    final safe = gvSanitizeDownloadFileName(fileName);
    var path = '${folder.path}/$safe';
    if (await File(path).exists()) {
      final dot = safe.lastIndexOf('.');
      final stem = dot > 0 ? safe.substring(0, dot) : safe;
      final ext = dot > 0 ? safe.substring(dot) : '';
      path =
          '${folder.path}/${stem}_${DateTime.now().millisecondsSinceEpoch}$ext';
    }
    await api.downloadFileToPath(fileUrl, path);
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    GvToast.show(context, AppLocalizations.of(context)!.chatFileSavedToast);
  } catch (_) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    GvToast.show(
        context, AppLocalizations.of(context)!.chatFileDownloadFailedToast);
  }
}

/// 展示聊天文件信息 BottomSheet，用户确认后触发 [gvRunChatFileDownload]。
Future<void> gvShowChatFileDownloadSheet(
  BuildContext context, {
  required ImApi api,
  required String fileName,
  required String fileUrl,
}) async {
  if (fileUrl.isEmpty) return;
  await showGvIosModalBottomSheet<void>(
    context: context,
    builder: (sheetCtx) {
      final l10n = AppLocalizations.of(sheetCtx)!;
      final fg = AppColors.textPrimary.resolveFrom(sheetCtx);
      final hint = AppColors.textSecondary.resolveFrom(sheetCtx);
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(LucideIcons.file_text,
                  size: 44, color: kChatFileIconOrange),
              const SizedBox(height: 12),
              Text(
                fileName,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: fg,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.chatFileDownloadExplain,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, height: 1.35, color: hint),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(double.infinity, 48),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(l10n.commonCancel),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          unawaited(gvRunChatFileDownload(
                            context,
                            api: api,
                            fileName: fileName,
                            fileUrl: fileUrl,
                          ));
                        },
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(double.infinity, 48),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(l10n.commonDownload),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
