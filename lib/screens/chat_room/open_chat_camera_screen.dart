import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/open_automation_keys.dart';
import '../../l10n/app_localizations.dart';

enum GvChatCameraMediaType { photo, video }

class GvChatCameraCapture {
  const GvChatCameraCapture({required this.path, required this.type});

  final String path;
  final GvChatCameraMediaType type;

  bool get isVideo => type == GvChatCameraMediaType.video;
}

/// A chat camera whose single shutter behaves like common messaging apps:
/// tap for a photo, hold for video, and release to finish recording.
class GvChatCameraScreen extends StatefulWidget {
  const GvChatCameraScreen({
    super.key,
    this.maxVideoDuration = const Duration(seconds: 60),
  });

  final Duration maxVideoDuration;

  @override
  State<GvChatCameraScreen> createState() => _GvChatCameraScreenState();
}

class _GvChatCameraScreenState extends State<GvChatCameraScreen>
    with WidgetsBindingObserver {
  List<CameraDescription> _cameras = const [];
  CameraController? _controller;
  CameraDescription? _selectedCamera;
  Object? _initializationError;
  bool _initializing = true;
  bool _busy = false;
  bool _recording = false;
  bool _releaseRequested = false;
  bool _closing = false;
  int _initializationGeneration = 0;
  FlashMode _flashMode = FlashMode.off;
  DateTime? _recordingStartedAt;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadCameras());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_suspendCamera());
    } else if (state == AppLifecycleState.resumed && !_closing) {
      final camera = _selectedCamera;
      if (camera != null && _controller == null) {
        unawaited(_initializeCamera(camera));
      }
    }
  }

  Future<void> _loadCameras() async {
    if (mounted) {
      setState(() {
        _initializing = true;
        _initializationError = null;
      });
    }
    try {
      final cameras = await availableCameras();
      if (!mounted) return;
      if (cameras.isEmpty) throw CameraException('NoCamera', '');
      _cameras = cameras;
      final camera = cameras.firstWhere(
        (item) => item.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _selectedCamera = camera;
      await _initializeCamera(camera);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _initializationError = error;
      });
    }
  }

  Future<void> _initializeCamera(CameraDescription camera) async {
    final generation = ++_initializationGeneration;
    final previous = _controller;
    _controller = null;
    if (previous != null) await previous.dispose();
    if (!mounted || generation != _initializationGeneration) return;

    setState(() {
      _initializing = true;
      _initializationError = null;
      _flashMode = FlashMode.off;
    });
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: true,
    );
    try {
      await controller.initialize();
      if (!mounted || generation != _initializationGeneration || _closing) {
        await controller.dispose();
        return;
      }
      _controller = controller;
      _selectedCamera = camera;
      setState(() => _initializing = false);
    } catch (error) {
      await controller.dispose();
      if (!mounted || generation != _initializationGeneration) return;
      setState(() {
        _initializing = false;
        _initializationError = error;
      });
    }
  }

  Future<void> _suspendCamera() async {
    ++_initializationGeneration;
    _recordingTimer?.cancel();
    _recordingTimer = null;
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    if (_recording || controller.value.isRecordingVideo) {
      try {
        final discarded = await controller.stopVideoRecording();
        await File(discarded.path).delete();
      } catch (_) {}
    }
    await controller.dispose();
    if (mounted) {
      setState(() {
        _recording = false;
        _busy = false;
        _recordingDuration = Duration.zero;
      });
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.toastOperationFailed(error.toString()))),
    );
  }

  Future<void> _takePhoto() async {
    final controller = _controller;
    if (_busy ||
        _recording ||
        controller == null ||
        !controller.value.isInitialized) {
      return;
    }
    setState(() => _busy = true);
    try {
      final file = await controller.takePicture();
      if (!mounted || _closing) return;
      _popAfterBuild(
        GvChatCameraCapture(
          path: file.path,
          type: GvChatCameraMediaType.photo,
        ),
      );
    } catch (error) {
      _showError(error);
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startVideoRecording() async {
    final controller = _controller;
    if (_busy ||
        _recording ||
        controller == null ||
        !controller.value.isInitialized) {
      return;
    }
    _releaseRequested = false;
    setState(() => _busy = true);
    try {
      await controller.startVideoRecording();
      if (!mounted || _closing) {
        final discarded = await controller.stopVideoRecording();
        await File(discarded.path).delete();
        return;
      }
      _recordingStartedAt = DateTime.now();
      setState(() {
        _busy = false;
        _recording = true;
        _recordingDuration = Duration.zero;
      });
      unawaited(HapticFeedback.mediumImpact());
      _recordingTimer = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => _updateRecordingDuration(),
      );
      if (_releaseRequested) await _finishVideoRecording();
    } catch (error) {
      _showError(error);
      if (mounted) {
        setState(() {
          _busy = false;
          _recording = false;
        });
      }
    }
  }

  void _updateRecordingDuration() {
    final startedAt = _recordingStartedAt;
    if (!mounted || !_recording || startedAt == null) return;
    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed >= widget.maxVideoDuration) {
      setState(() => _recordingDuration = widget.maxVideoDuration);
      unawaited(_finishVideoRecording());
      return;
    }
    setState(() => _recordingDuration = elapsed);
  }

  void _requestStopVideoRecording() {
    _releaseRequested = true;
    if (_recording) unawaited(_finishVideoRecording());
  }

  Future<void> _finishVideoRecording({bool discard = false}) async {
    final controller = _controller;
    if (_busy || controller == null || !_recording) return;
    _recordingTimer?.cancel();
    _recordingTimer = null;
    setState(() {
      _busy = true;
      _recording = false;
    });
    try {
      final file = await controller.stopVideoRecording();
      if (discard || _closing || !mounted) {
        try {
          await File(file.path).delete();
        } catch (_) {}
        return;
      }
      unawaited(HapticFeedback.lightImpact());
      _popAfterBuild(
        GvChatCameraCapture(
          path: file.path,
          type: GvChatCameraMediaType.video,
        ),
      );
    } catch (error) {
      if (!discard) _showError(error);
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    if (_recording) await _finishVideoRecording(discard: true);
    _popAfterBuild();
  }

  void _popAfterBuild([GvChatCameraCapture? capture]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      Navigator.of(context).pop(capture);
    });
  }

  Future<void> _switchCamera() async {
    if (_busy || _recording || _cameras.length < 2) return;
    final current = _selectedCamera;
    final index = current == null ? -1 : _cameras.indexOf(current);
    final next = _cameras[(index + 1) % _cameras.length];
    await _initializeCamera(next);
  }

  Future<void> _cycleFlashMode() async {
    final controller = _controller;
    if (_busy || _recording || controller == null) return;
    final next = switch (_flashMode) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.always,
      _ => FlashMode.off,
    };
    try {
      await controller.setFlashMode(next);
      if (mounted) setState(() => _flashMode = next);
    } catch (error) {
      _showError(error);
    }
  }

  String _formattedDuration() {
    final seconds = _recordingDuration.inSeconds;
    final minutes = seconds ~/ 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${(seconds % 60).toString().padLeft(2, '0')}';
  }

  IconData get _flashIcon => switch (_flashMode) {
        FlashMode.auto => Icons.flash_auto_rounded,
        FlashMode.always => Icons.flash_on_rounded,
        _ => Icons.flash_off_rounded,
      };

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ++_initializationGeneration;
    _recordingTimer?.cancel();
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = _controller;
    return PopScope(
      canPop: !_recording,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_close());
      },
      child: Scaffold(
        key: GvAutomationKeys.chatCameraScreen,
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (controller != null && controller.value.isInitialized)
                _CameraPreviewCover(controller: controller)
              else
                _buildLoadingOrError(l10n),
              Positioned(
                left: 12,
                right: 12,
                top: 8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CameraActionButton(
                      icon: Icons.close_rounded,
                      tooltip:
                          MaterialLocalizations.of(context).closeButtonTooltip,
                      onPressed: _close,
                    ),
                    if (controller != null && controller.value.isInitialized)
                      _CameraActionButton(
                        icon: _flashIcon,
                        tooltip: l10n.chatCameraSwitchFlash,
                        onPressed: _busy || _recording ? null : _cycleFlashMode,
                      ),
                  ],
                ),
              ),
              if (_recording)
                Positioned(
                  top: 22,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.circle,
                                color: Colors.red, size: 10),
                            const SizedBox(width: 7),
                            Text(
                              _formattedDuration(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontFeatures: [FontFeature.tabularFigures()],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _recording
                          ? l10n.chatCameraRecordingHint
                          : l10n.chatCameraShutterHint,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(child: SizedBox()),
                        GvChatCameraShutter(
                          key: GvAutomationKeys.chatCameraShutter,
                          enabled: !_initializing &&
                              _initializationError == null &&
                              controller != null,
                          recording: _recording,
                          semanticsLabel: l10n.chatCameraShutterHint,
                          onTap: () => unawaited(_takePhoto()),
                          onLongPressStart: () =>
                              unawaited(_startVideoRecording()),
                          onLongPressEnd: _requestStopVideoRecording,
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: _cameras.length > 1
                                ? _CameraActionButton(
                                    icon: Icons.cameraswitch_rounded,
                                    tooltip: l10n.callActionSwitchCamera,
                                    onPressed: _busy || _recording
                                        ? null
                                        : _switchCamera,
                                  )
                                : const SizedBox(width: 48, height: 48),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOrError(AppLocalizations l10n) {
    if (_initializationError == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              l10n.chatCameraInitializing,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined,
                color: Colors.white70, size: 48),
            const SizedBox(height: 16),
            Text(
              l10n.chatCameraUnavailable,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: _loadCameras,
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
              child: Text(l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraPreviewCover extends StatelessWidget {
  const _CameraPreviewCover({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final preview = controller.value.previewSize;
          if (preview == null) return CameraPreview(controller);
          final portrait = constraints.maxHeight >= constraints.maxWidth;
          final width = portrait ? preview.height : preview.width;
          final height = portrait ? preview.width : preview.height;
          return ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: width,
                height: height,
                child: CameraPreview(controller),
              ),
            ),
          );
        },
      );
}

class _CameraActionButton extends StatelessWidget {
  const _CameraActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final FutureOr<void> Function()? onPressed;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
        onPressed: onPressed == null ? null : () => onPressed!(),
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: Colors.black45,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white38,
        ),
        icon: Icon(icon),
      );
}

class GvChatCameraShutter extends StatefulWidget {
  const GvChatCameraShutter({
    super.key,
    required this.enabled,
    required this.recording,
    required this.semanticsLabel,
    required this.onTap,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  final bool enabled;
  final bool recording;
  final String semanticsLabel;
  final VoidCallback onTap;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;

  @override
  State<GvChatCameraShutter> createState() => _GvChatCameraShutterState();
}

class _GvChatCameraShutterState extends State<GvChatCameraShutter> {
  bool _longPressActive = false;

  void _handleLongPressStart(LongPressStartDetails _) {
    _longPressActive = true;
    widget.onLongPressStart();
  }

  void _handleLongPressEnd([LongPressEndDetails? _]) {
    if (!_longPressActive) return;
    _longPressActive = false;
    widget.onLongPressEnd();
  }

  void _handlePointerRelease(PointerEvent _) => _handleLongPressEnd();

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        enabled: widget.enabled,
        label: widget.semanticsLabel,
        onTap: widget.enabled ? widget.onTap : null,
        excludeSemantics: true,
        child: Listener(
          // A raw pointer release still reaches the original hit-test path if
          // iOS cancels the long-press recognizer after the finger drifts away
          // from the animated shutter. Either release path must stop recording.
          onPointerUp: widget.enabled ? _handlePointerRelease : null,
          onPointerCancel: widget.enabled ? _handlePointerRelease : null,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.enabled ? widget.onTap : null,
            onLongPressStart: widget.enabled ? _handleLongPressStart : null,
            onLongPressEnd: widget.enabled ? _handleLongPressEnd : null,
            onLongPressCancel: widget.enabled ? _handleLongPressEnd : null,
            child: SizedBox.square(
              dimension: 92,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: widget.recording ? 92 : 78,
                  height: widget.recording ? 92 : 78,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.enabled ? Colors.white : Colors.white38,
                      width: 4,
                    ),
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    decoration: BoxDecoration(
                      color: widget.recording
                          ? Colors.red
                          : widget.enabled
                              ? Colors.white
                              : Colors.white38,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
