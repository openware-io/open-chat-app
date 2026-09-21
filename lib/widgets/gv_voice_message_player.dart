import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../core/gv_web_audio_blob_url.dart';
import '../core/gv_web_html_voice.dart';
import '../core/media_url.dart';
import '../core/playback_audio_context.dart';
import '../services/im_api.dart';

/// 与 H5 [VoiceMessagePlayer] 类似：点击播放、时长、简单波形；同时只播放一条。
final class VoicePlaybackCoordinator {
  VoicePlaybackCoordinator._();
  static final VoicePlaybackCoordinator instance = VoicePlaybackCoordinator._();

  final List<void Function()> _stoppers = [];

  void register(void Function() stop) => _stoppers.add(stop);

  void unregister(void Function() stop) => _stoppers.remove(stop);

  void stopAll() {
    for (final s in List<void Function()>.from(_stoppers)) {
      s();
    }
  }
}

class GvVoiceMessagePlayer extends StatefulWidget {
  const GvVoiceMessagePlayer({
    super.key,
    required this.url,
    required this.fromSelf,
    required this.color,
    this.imApi,
  });

  final String url;
  final bool fromSelf;
  final Color color;

  /// 传入时，远程 http(s) 语音先经 [ImApi.downloadFileToPath] 落盘再播，
  /// 使用对象存储签名 URL 并正确读取时长。
  final ImApi? imApi;

  @override
  State<GvVoiceMessagePlayer> createState() => _GvVoiceMessagePlayerState();
}

class _GvVoiceMessagePlayerState extends State<GvVoiceMessagePlayer>
    with SingleTickerProviderStateMixin {
  /// Web 上使用原生 `<audio>`（`gv_web_html_voice`），避免 `audioplayers_web` WebAudio 链路静音。
  AudioPlayer? _player;
  late final AnimationController _waveCtrl;

  bool _playing = false;
  bool _sourceReady = false;
  Duration _duration = Duration.zero;
  Uint8List? _cachedWebVoiceBytes;

  /// `audioplayers_web` 对 `data:` 源与 `crossOrigin=anonymous` 组合易无声，改用 `blob:`。
  String? _webVoiceBlobUrl;
  StreamSubscription<void>? _completeSub;
  StreamSubscription<Duration>? _durationSub;

  String get _playbackUrl => stripChatMediaDisplayQueryParams(widget.url);

  void _applyDurationFromQuery() {
    final sec = parseMediaDurationSecondsFromUrl(widget.url);
    if (sec != null && sec > 0) {
      _duration = Duration(seconds: sec);
    }
  }

  void _stopOthers() {
    if (kIsWeb) {
      gvWebHtmlVoiceStopSync();
    } else {
      unawaited(_player?.stop() ?? Future<void>.value());
    }
    // stop 后原生侧与 Dart 的 prepared 状态可能不一致；下次播放前必须重新 setSource。
    _sourceReady = false;
    if (mounted) setState(() => _playing = false);
  }

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..repeat(reverse: true);
    _waveCtrl.stop();
    VoicePlaybackCoordinator.instance.register(_stopOthers);
    if (!kIsWeb) {
      _player = AudioPlayer();
      _completeSub = _player!.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _playing = false);
        _waveCtrl.stop();
      });
      _durationSub = _player!.onDurationChanged.listen((d) {
        if (parseMediaDurationSecondsFromUrl(widget.url) != null) return;
        if (mounted && d > Duration.zero) setState(() => _duration = d);
      });
    }
    _applyDurationFromQuery();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => unawaited(_loadSourceAndDuration()));
  }

  static bool _isRemoteHttp(String u) =>
      u.startsWith('http://') || u.startsWith('https://');

  static String _extFromUrl(String url) {
    try {
      final seg = Uri.parse(url).pathSegments;
      if (seg.isEmpty) return '.m4a';
      final last = seg.last;
      final i = last.lastIndexOf('.');
      if (i > 0 && i < last.length - 1) {
        final ext = last.substring(i).toLowerCase();
        if (ext.length <= 6) return ext;
      }
    } catch (_) {}
    return '.m4a';
  }

  static String _voiceMimeFromPlaybackUrl(String url) {
    switch (_extFromUrl(url)) {
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.aac':
        return 'audio/aac';
      case '.ogg':
      case '.opus':
        return 'audio/ogg';
      case '.webm':
        return 'audio/webm';
      case '.m4a':
      case '.mp4':
      default:
        return 'audio/mp4';
    }
  }

  Future<Uint8List?> _ensureVoiceBytesCached() async {
    if (_cachedWebVoiceBytes != null) return _cachedWebVoiceBytes;
    final api = widget.imApi;
    final src = _playbackUrl;
    if (api == null || !_isRemoteHttp(src)) return null;
    final urlSnapshot = widget.url;
    final bytes = await api.downloadFileBytes(src);
    if (!mounted || widget.url != urlSnapshot) return null;
    _cachedWebVoiceBytes = bytes;
    return bytes;
  }

  void _revokeWebVoiceBlobUrl() {
    final u = _webVoiceBlobUrl;
    if (u != null) {
      gvRevokeBlobUrlForAudio(u);
      _webVoiceBlobUrl = null;
    }
  }

  Future<String?> _ensureWebBlobPlaybackUrl() async {
    if (_webVoiceBlobUrl != null) return _webVoiceBlobUrl;
    final bytes = await _ensureVoiceBytesCached();
    if (bytes == null || bytes.isEmpty) return null;
    final mime = _voiceMimeFromPlaybackUrl(_playbackUrl);
    final url = gvCreateBlobUrlForAudioBytes(bytes, mime);
    _webVoiceBlobUrl = url;
    return url;
  }

  Future<String?> _ensureDownloadedLocalPath() async {
    final api = widget.imApi;
    final src = _playbackUrl;
    if (api == null || !_isRemoteHttp(src)) return null;
    final dir = await getTemporaryDirectory();
    final ext = _extFromUrl(src);
    final sep = Platform.pathSeparator;
    final path = '${dir.path}${sep}gv_voice_${src.hashCode.abs()}$ext';
    final f = File(path);
    if (await f.exists()) {
      final len = await f.length();
      if (len > 0) return path;
    }
    final urlSnapshot = widget.url;
    await api.downloadFileToPath(src, path);
    if (!mounted || widget.url != urlSnapshot) return null;
    return path;
  }

  /// 预加载 URL 并解析时长，气泡上可直接显示秒数（与 H5 一致）；部分编码在播放前 [getDuration] 可能为 null，由 [onDurationChanged] 补齐。
  Future<void> _loadSourceAndDuration() async {
    if (_sourceReady || widget.url.isEmpty || !mounted) return;
    final urlSnapshot = widget.url;
    final play = _playbackUrl;
    try {
      if (kIsWeb) {
        if (widget.imApi != null && _isRemoteHttp(play)) {
          final blobUrl = await _ensureWebBlobPlaybackUrl();
          if (!mounted || widget.url != urlSnapshot) return;
          if (blobUrl != null &&
              blobUrl.isNotEmpty &&
              parseMediaDurationSecondsFromUrl(widget.url) == null) {
            final sec = await gvWebHtmlVoiceProbeDurationSec(blobUrl);
            if (!mounted || widget.url != urlSnapshot) return;
            if (sec != null && sec > 0) {
              setState(
                () => _duration = Duration(milliseconds: (sec * 1000).round()),
              );
            }
          }
          _sourceReady = blobUrl != null && blobUrl.isNotEmpty;
        } else {
          if (parseMediaDurationSecondsFromUrl(widget.url) == null) {
            final sec = await gvWebHtmlVoiceProbeDurationSec(play);
            if (!mounted || widget.url != urlSnapshot) return;
            if (sec != null && sec > 0) {
              setState(
                () => _duration = Duration(milliseconds: (sec * 1000).round()),
              );
            }
          }
          _sourceReady = true;
        }
        return;
      }

      final p = _player!;
      if (widget.imApi != null && _isRemoteHttp(play)) {
        final local = await _ensureDownloadedLocalPath();
        if (!mounted || widget.url != urlSnapshot) return;
        if (local != null) {
          await p.setSource(DeviceFileSource(local));
        } else {
          await p.setSourceUrl(play);
        }
      } else {
        await p.setSourceUrl(play);
      }
      if (!mounted || widget.url != urlSnapshot) return;
      if (parseMediaDurationSecondsFromUrl(widget.url) == null) {
        final d = await p.getDuration();
        if (!mounted || widget.url != urlSnapshot) return;
        if (d != null && d > Duration.zero) {
          setState(() => _duration = d);
        }
      }
      _sourceReady = true;
    } catch (_) {
      /* onDurationChanged 或首次播放后再补时长 */
    }
  }

  @override
  void didUpdateWidget(covariant GvVoiceMessagePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _stopOthers();
      _sourceReady = false;
      _revokeWebVoiceBlobUrl();
      _cachedWebVoiceBytes = null;
      _duration = Duration.zero;
      _applyDurationFromQuery();
      if (mounted) setState(() {});
      WidgetsBinding.instance
          .addPostFrameCallback((_) => unawaited(_loadSourceAndDuration()));
    }
  }

  Future<void> _toggle() async {
    if (widget.url.isEmpty) return;
    if (_playing) {
      if (kIsWeb) {
        gvWebHtmlVoiceStopSync();
      } else {
        await _player!.stop();
      }
      if (mounted) setState(() => _playing = false);
      _waveCtrl.stop();
      return;
    }
    VoicePlaybackCoordinator.instance.stopAll();
    // stopAll 里对 stop() 是 unawaited，若立刻 play 会与 stop 竞态 → 无声音、不完播。
    if (kIsWeb) {
      gvWebHtmlVoiceStopSync();
    } else {
      await _player!.stop();
    }
    await _loadSourceAndDuration();
    if (!mounted) return;
    if (!kIsWeb) {
      await applyPlaybackSpeakerRoute(_player!);
    }
    setState(() => _playing = true);
    _waveCtrl.repeat(reverse: true);
    try {
      if (kIsWeb) {
        final play = _playbackUrl;
        final String src;
        if (widget.imApi != null && _isRemoteHttp(play)) {
          final blobUrl = await _ensureWebBlobPlaybackUrl();
          if (!mounted) return;
          if (blobUrl == null || blobUrl.isEmpty) {
            throw StateError('voice blob url empty');
          }
          src = blobUrl;
        } else {
          src = play;
        }
        await gvWebHtmlVoicePlay(
          src,
          onEnded: () {
            if (!mounted) return;
            setState(() => _playing = false);
            _waveCtrl.stop();
          },
        );
      } else {
        final p = _player!;
        if (_sourceReady) {
          await p.seek(Duration.zero);
          await p.resume();
        } else {
          if (widget.imApi != null && _isRemoteHttp(_playbackUrl)) {
            final local = await _ensureDownloadedLocalPath();
            if (!mounted) return;
            if (local != null) {
              await p.play(DeviceFileSource(local));
              _sourceReady = true;
            } else {
              await p.play(UrlSource(_playbackUrl));
            }
          } else {
            await p.play(UrlSource(_playbackUrl));
          }
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _playing = false);
        _waveCtrl.stop();
      }
    }
  }

  @override
  void dispose() {
    gvWebHtmlVoiceStopSync();
    _revokeWebVoiceBlobUrl();
    VoicePlaybackCoordinator.instance.unregister(_stopOthers);
    unawaited(_completeSub?.cancel());
    unawaited(_durationSub?.cancel());
    if (_player != null) unawaited(_player!.dispose());
    _waveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sec = _duration.inMilliseconds > 0
        ? math.max(1, (_duration.inMilliseconds / 1000).round())
        : 0;
    final wave = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        return AnimatedBuilder(
          animation: _waveCtrl,
          builder: (context, child) {
            final t = _playing ? _waveCtrl.value : 0.0;
            final scale = _playing ? 0.35 + t * 0.65 : 0.4;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Transform.scale(
                scaleY: scale,
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color:
                        widget.color.withValues(alpha: _playing ? 0.95 : 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );

    final meta = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          sec == 0 ? '···' : '$sec″',
          style: TextStyle(
            color: widget.color,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: _toggle,
        borderRadius: BorderRadius.circular(6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.fromSelf
                ? [meta, const SizedBox(width: 8), wave]
                : [wave, const SizedBox(width: 8), meta],
          ),
        ),
      ),
    );
  }
}
