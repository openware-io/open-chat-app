import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gv_chat_app/l10n/app_localizations.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:path_provider/path_provider.dart';

import '../core/gv_toast.dart';
import '../services/im_api.dart';

/// 与 H5 [ImageViewer.vue] 对齐：全屏暗底、工具栏（缩放比例、还原、保存、关闭）、
/// 双指缩放 / 拖拽；滚轮缩放（步进 1.2，范围 0.35～4）；关闭时重置变换。
void showGvImageViewer(
  BuildContext context, {
  required String imageUrl,
  required ImApi api,
}) {
  if (imageUrl.isEmpty) return;
  Navigator.of(context, rootNavigator: true).push<void>(
    PageRouteBuilder<void>(
      // 必须不透明：否则底层聊天室仍会布局/重绘，键盘收起或安全区变化时会透过遮罩产生「底部输入区位移」观感。
      opaque: true,
      fullscreenDialog: true,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => _GvImageViewerPage(
        imageUrl: imageUrl,
        api: api,
      ),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}

class _GvImageViewerPage extends StatefulWidget {
  const _GvImageViewerPage({
    required this.imageUrl,
    required this.api,
  });

  final String imageUrl;
  final ImApi api;

  @override
  State<_GvImageViewerPage> createState() => _GvImageViewerPageState();
}

class _GvImageViewerPageState extends State<_GvImageViewerPage> {
  static const double _scaleMin = 0.35;
  static const double _scaleMax = 4.0;
  static const double _wheelStep = 1.2;

  final TransformationController _tc = TransformationController();

  int _zoomPercent = 100;

  @override
  void initState() {
    super.initState();
    _tc.addListener(_onTransform);
  }

  void _onTransform() {
    final s = _tc.value.getMaxScaleOnAxis();
    final p = (s * 100).round();
    if (p != _zoomPercent) setState(() => _zoomPercent = p);
  }

  void _resetView() {
    _tc.value = Matrix4.identity();
  }

  void _closeViewer() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  void _onWheel(PointerScrollEvent e) {
    final m = _tc.value.clone();
    final s0 = m.getMaxScaleOnAxis();
    final zoomIn = e.scrollDelta.dy < 0;
    final factor = zoomIn ? _wheelStep : 1 / _wheelStep;
    var s1 = s0 * factor;
    if (s1 < _scaleMin) s1 = _scaleMin;
    if (s1 > _scaleMax) s1 = _scaleMax;
    if ((s1 - s0).abs() < 1e-6) return;
    final ratio = s1 / s0;

    final box = context.findRenderObject() as RenderBox?;
    final focal = box != null
        ? box.globalToLocal(e.position)
        : Offset(
            MediaQuery.sizeOf(context).width / 2,
            MediaQuery.sizeOf(context).height / 2,
          );

    final zoom = Matrix4.identity()
      ..translateByDouble(focal.dx, focal.dy, 0, 1)
      ..scaleByDouble(ratio, ratio, 1, 1)
      ..translateByDouble(-focal.dx, -focal.dy, 0, 1);
    _tc.value = zoom * m;
  }

  Future<void> _saveImage() async {
    final ext = _guessExt(widget.imageUrl);
    final name = 'image_${DateTime.now().millisecondsSinceEpoch}.$ext';
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final dir = await getApplicationDocumentsDirectory();
      if (!mounted) return;
      final folder = Directory('${dir.path}/gv_chat_downloads');
      if (!await folder.exists()) await folder.create(recursive: true);
      final path = '${folder.path}/$name';
      await widget.api.downloadFileToPath(widget.imageUrl, path);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      GvToast.show(context, AppLocalizations.of(context)!.chatFileSavedToast);
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      GvToast.show(context, AppLocalizations.of(context)!.toastImageSaveFailed);
    }
  }

  static String _guessExt(String url) {
    try {
      final path = Uri.parse(url).path.toLowerCase();
      if (path.endsWith('.png')) return 'png';
      if (path.endsWith('.webp')) return 'webp';
      if (path.endsWith('.gif')) return 'gif';
      if (path.endsWith('.jpeg')) return 'jpeg';
    } catch (_) {}
    return 'jpg';
  }

  @override
  void dispose() {
    _tc.removeListener(_onTransform);
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topPad = MediaQuery.paddingOf(context).top;
    final toolbarBg = Colors.black.withValues(alpha: 0.45);

    return Material(
      color: Colors.black.withValues(alpha: 0.92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(8, 10 + topPad, 8, 10),
            color: toolbarBg,
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  child: Text(
                    '$_zoomPercent%',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color.fromRGBO(255, 255, 255, 0.85),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.imageViewerActualSizeTooltip,
                  onPressed: _resetView,
                  icon: const Icon(LucideIcons.rotate_ccw,
                      color: Color.fromRGBO(255, 255, 255, 0.92), size: 22),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.14),
                    minimumSize: const Size(40, 40),
                    maximumSize: const Size(40, 40),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: l10n.commonSaveImage,
                  onPressed: _saveImage,
                  icon: const Icon(LucideIcons.download,
                      color: Colors.white, size: 22),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    minimumSize: const Size(40, 40),
                    maximumSize: const Size(40, 40),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: l10n.commonClose,
                  onPressed: _closeViewer,
                  icon: const Icon(LucideIcons.x,
                      color: Color.fromRGBO(255, 255, 255, 0.92), size: 22),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.14),
                    minimumSize: const Size(40, 40),
                    maximumSize: const Size(40, 40),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeViewer,
              child: Listener(
                onPointerSignal: (s) {
                  if (s is PointerScrollEvent) _onWheel(s);
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return InteractiveViewer(
                      transformationController: _tc,
                      minScale: _scaleMin,
                      maxScale: _scaleMax,
                      boundaryMargin: const EdgeInsets.all(160),
                      clipBehavior: Clip.none,
                      panEnabled: true,
                      scaleEnabled: true,
                      child: SizedBox(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        child: Center(
                          child: Image.network(
                            widget.imageUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (_, child, progress) {
                              if (progress == null) return child;
                              return const SizedBox(
                                width: 48,
                                height: 48,
                                child: CircularProgressIndicator(
                                  color: Colors.white54,
                                  strokeWidth: 2,
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => const Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                '图片加载失败',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
