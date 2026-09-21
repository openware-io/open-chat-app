import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gv_chat_app/l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../core/gv_toast.dart';
import '../services/im_api.dart';

/// 全屏视频播放（与 [showGvImageViewer] 相同进栈方式：不透明路由 + 淡入）。
///
/// 默认 [VideoPlayerController.networkUrl] 流式播放；若初始化失败再回退到
/// [Dio.download] 落盘后以 [VideoPlayerController.file] 本地播放。
void showGvVideoViewer(
  BuildContext context, {
  required String videoUrl,
  required ImApi api,
  Map<String, String>? httpHeaders,
}) {
  if (videoUrl.isEmpty) return;
  Navigator.of(context, rootNavigator: true).push<void>(
    PageRouteBuilder<void>(
      opaque: true,
      fullscreenDialog: true,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => _GvVideoViewerPage(
        videoUrl: videoUrl,
        api: api,
        httpHeaders: httpHeaders,
      ),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}

class _GvVideoViewerPage extends StatefulWidget {
  const _GvVideoViewerPage({
    required this.videoUrl,
    required this.api,
    this.httpHeaders,
  });

  final String videoUrl;
  final ImApi api;
  final Map<String, String>? httpHeaders;

  @override
  State<_GvVideoViewerPage> createState() => _GvVideoViewerPageState();
}

class _GvVideoViewerPageState extends State<_GvVideoViewerPage> {
  static const Duration _kInitTimeout = Duration(seconds: 30);

  VideoPlayerController? _controller;
  String? _tempVideoPath;
  bool _ready = false;
  bool _error = false;
  bool _saving = false;
  String? _errorDetail;

  static bool _isRemoteHttpUrl(String url) {
    final u = Uri.tryParse(url);
    if (u == null) return false;
    return u.scheme == 'http' || u.scheme == 'https';
  }

  static String _tempVideoSuffix(String url) {
    try {
      final path = Uri.parse(url).path.toLowerCase();
      if (path.endsWith('.mp4')) return '.mp4';
      if (path.endsWith('.webm')) return '.webm';
      if (path.endsWith('.mov')) return '.mov';
      if (path.endsWith('.m4v')) return '.m4v';
    } catch (_) {}
    return '.mp4';
  }

  @override
  void initState() {
    super.initState();
    _startPlayback();
  }

  void _startPlayback() {
    if (kIsWeb) return;
    debugPrint('[GvVideo] url=${widget.videoUrl}  '
        'headers=${widget.httpHeaders?.keys.join(",")}');
    if (_isRemoteHttpUrl(widget.videoUrl)) {
      unawaited(_initMobileNetworkWithDownloadFallback());
      return;
    }
    _initNetworkPlayback();
  }

  void _initNetworkPlayback() {
    final c = _createNetworkController();
    _controller = c;
    c.addListener(_onTick);
    unawaited(_runInitialize(c));
  }

  VideoPlayerController _createNetworkController() {
    final uri = Uri.parse(widget.videoUrl);
    final h = widget.httpHeaders;
    if (h != null && h.isNotEmpty) {
      return VideoPlayerController.networkUrl(uri, httpHeaders: h);
    }
    return VideoPlayerController.networkUrl(uri);
  }

  /// 移动端：优先直连流式播放；失败时再下载本地播放。
  Future<void> _initMobileNetworkWithDownloadFallback() async {
    debugPrint('[GvVideo] mobile: trying networkUrl …');
    final c = _createNetworkController();
    _controller = c;
    c.addListener(_onTick);
    try {
      await c.initialize().timeout(_kInitTimeout);
      if (!mounted) return;
      debugPrint('[GvVideo] mobile networkUrl OK');
      setState(() => _ready = true);
      await c.play();
    } catch (e) {
      debugPrint(
          '[GvVideo] mobile networkUrl FAILED: $e — falling back to download');
      c.removeListener(_onTick);
      try {
        await c.dispose();
      } catch (_) {}
      _controller = null;
      if (!mounted) return;
      await _initRemoteDownloadFilePlayback();
    }
  }

  Future<void> _initRemoteDownloadFilePlayback() async {
    debugPrint('[GvVideo] download: ${widget.videoUrl}');
    try {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/gv_video_view_${DateTime.now().millisecondsSinceEpoch}${_tempVideoSuffix(widget.videoUrl)}';
      final f = File(path);
      if (await f.exists()) {
        try {
          await f.delete();
        } catch (_) {}
      }
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 10),
        ),
      );
      final h = widget.httpHeaders;
      await dio.download(
        widget.videoUrl,
        path,
        options: Options(
          headers: (h != null && h.isNotEmpty) ? h : null,
          receiveTimeout: const Duration(minutes: 10),
        ),
      );
      if (!mounted) {
        try {
          await File(path).delete();
        } catch (_) {}
        return;
      }
      final len = await File(path).length();
      debugPrint('[GvVideo] downloaded $len bytes → $path');
      if (len == 0) {
        try {
          await File(path).delete();
        } catch (_) {}
        if (mounted) {
          setState(() {
            _error = true;
            _errorDetail = 'download 0 bytes';
          });
        }
        return;
      }
      _tempVideoPath = path;
      final c = VideoPlayerController.file(File(path));
      _controller = c;
      c.addListener(_onTick);
      await _runInitialize(c);
    } catch (e) {
      debugPrint('[GvVideo] download+file error: $e');
      if (mounted) {
        setState(() {
          _error = true;
          _errorDetail = e.toString();
        });
      }
    }
  }

  Future<void> _runInitialize(VideoPlayerController c) async {
    try {
      await c.initialize().timeout(_kInitTimeout);
      if (!mounted) return;
      debugPrint('[GvVideo] controller initialized OK');
      setState(() => _ready = true);
      await c.play();
    } catch (e) {
      debugPrint('[GvVideo] initialize error: $e');
      if (mounted) {
        setState(() {
          _error = true;
          _errorDetail = e.toString();
        });
      }
    }
  }

  void _onTick() {
    if (!mounted || _controller == null) return;
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    final p = _tempVideoPath;
    if (p != null) {
      unawaited(Future<void>(() async {
        try {
          await File(p).delete();
        } catch (_) {}
      }));
    }
    super.dispose();
  }

  void _togglePlay() {
    final c = _controller;
    if (!_ready || c == null) return;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      c.play();
    }
  }

  void _retry() {
    _controller?.removeListener(_onTick);
    try {
      _controller?.dispose();
    } catch (_) {}
    final p = _tempVideoPath;
    if (p != null) {
      unawaited(Future<void>(() async {
        try {
          await File(p).delete();
        } catch (_) {}
      }));
    }
    setState(() {
      _controller = null;
      _tempVideoPath = null;
      _ready = false;
      _error = false;
      _errorDetail = null;
    });
    _startPlayback();
  }

  Future<void> _saveVideo() async {
    if (_saving || kIsWeb) return;
    setState(() => _saving = true);
    String? outputPath;
    try {
      final documents = await getApplicationDocumentsDirectory();
      final folder = Directory('${documents.path}/gv_chat_downloads');
      if (!await folder.exists()) await folder.create(recursive: true);
      outputPath =
          '${folder.path}/video_${DateTime.now().millisecondsSinceEpoch}${_tempVideoSuffix(widget.videoUrl)}';

      final cachedPath = _tempVideoPath;
      if (cachedPath != null && await File(cachedPath).exists()) {
        await File(cachedPath).copy(outputPath);
      } else {
        final localSource = _localVideoFile(widget.videoUrl);
        if (localSource != null && await localSource.exists()) {
          await localSource.copy(outputPath);
        } else {
          await widget.api.downloadFileToPath(widget.videoUrl, outputPath);
        }
      }
      if (!mounted) return;
      GvToast.show(context, AppLocalizations.of(context)!.chatFileSavedToast);
    } catch (error, stackTrace) {
      debugPrint('Failed to save video: $error\n$stackTrace');
      final path = outputPath;
      if (path != null) {
        try {
          final partial = File(path);
          if (await partial.exists()) await partial.delete();
        } catch (_) {}
      }
      if (!mounted) return;
      GvToast.show(
        context,
        AppLocalizations.of(context)!.chatFileDownloadFailedToast,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static File? _localVideoFile(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme.isEmpty) return File(value);
    return uri.scheme == 'file' ? File.fromUri(uri) : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final top = MediaQuery.paddingOf(context).top;
    final c = _controller;
    return Material(
      color: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: top),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  tooltip: l10n.commonClose,
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                  icon:
                      const Icon(LucideIcons.x, color: Colors.white, size: 26),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                const Spacer(),
                if (_ready && !_error && c != null)
                  AnimatedBuilder(
                    animation: c,
                    builder: (context, _) {
                      final v = c.value;
                      return Text(
                        '${_fmt(v.position)} / ${_fmt(v.duration)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      );
                    },
                  ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: l10n.commonSaveVideo,
                  onPressed: _saving || kIsWeb ? null : _saveVideo,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          LucideIcons.download,
                          color: Colors.white,
                          size: 22,
                        ),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    disabledBackgroundColor:
                        Colors.white.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: _error
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '视频无法播放',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                          if (_errorDetail != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _errorDetail!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 11),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 20),
                          TextButton.icon(
                            onPressed: _retry,
                            icon: const Icon(LucideIcons.refresh_cw,
                                size: 16, color: Colors.white70),
                            label: const Text('重试',
                                style: TextStyle(color: Colors.white70)),
                          ),
                        ],
                      ),
                    )
                  : !_ready || c == null
                      ? const CircularProgressIndicator(color: Colors.white54)
                      : GestureDetector(
                          onTap: _togglePlay,
                          child: AspectRatio(
                            aspectRatio: c.value.aspectRatio == 0
                                ? 16 / 9
                                : c.value.aspectRatio,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                VideoPlayer(c),
                                if (!c.value.isPlaying)
                                  Icon(
                                    LucideIcons.circle_play,
                                    size: 72,
                                    color: Colors.white.withValues(alpha: 0.92),
                                  ),
                              ],
                            ),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$m:$s';
    }
    return '$m:$s';
  }
}
