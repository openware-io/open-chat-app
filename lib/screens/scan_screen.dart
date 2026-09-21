import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:gv_chat_app/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../core/api_failure.dart';
import '../core/gv_channel_code.dart';
import '../core/gv_automation_keys.dart';
import '../core/gv_chat_navigation.dart';
import '../core/gv_qr_image_decode.dart';
import '../core/gv_qr_login.dart';
import '../core/gv_scan_error_feedback.dart';
import '../core/gv_toast.dart';
import '../core/gv_uid.dart';

import 'package:gv_core/gv_core.dart';

import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/friend_provider.dart';
import '../services/im_api.dart';
import '../widgets/gv_dialog_actions.dart';
import '../widgets/gv_nav_bar.dart';

/// 扫码加好友流程中的可展示错误（文案已由 [AppLocalizations] 生成）。
class _ScanUserMessageException implements Exception {
  const _ScanUserMessageException(this.message);
  final String message;
}

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

/// 取景框：居中正方形，与 [MobileScanner.scanWindow] 使用同一套几何。
Rect _scanFrameRect(Size size) {
  final side = (size.shortestSide * 0.72).clamp(200.0, 300.0);
  return Rect.fromCenter(
    center: Offset(size.width / 2, size.height / 2),
    width: side,
    height: side,
  );
}

/// 半透明遮罩 + 中间透明「洞」+ 四角框线。
class _QrScanFramePainter extends CustomPainter {
  _QrScanFramePainter({required this.cutout, required this.cornerColor});

  final Rect cutout;
  final Color cornerColor;

  static const double _cornerLen = 28;
  static const double _stroke = 3.5;
  static const double _radius = 0;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Path()..addRect(Offset.zero & size);
    final inner = Path()
      ..addRRect(
        RRect.fromRectAndRadius(cutout, const Radius.circular(_radius)),
      );
    final mask = Path.combine(PathOperation.difference, outer, inner);
    canvas.drawPath(mask, Paint()..color = const Color(0x99000000));

    final p = Paint()
      ..color = cornerColor
      ..strokeWidth = _stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const l = _cornerLen;
    final r = cutout;

    void corner(
      double sx,
      double sy,
      double ex,
      double ey,
      double hx,
      double hy,
    ) {
      final path = Path()
        ..moveTo(sx, sy)
        ..lineTo(ex, ey)
        ..lineTo(hx, hy);
      canvas.drawPath(path, p);
    }

    corner(r.left, r.top + l, r.left, r.top, r.left + l, r.top);
    corner(r.right - l, r.top, r.right, r.top, r.right, r.top + l);
    corner(r.right, r.bottom - l, r.right, r.bottom, r.right - l, r.bottom);
    corner(r.left + l, r.bottom, r.left, r.bottom, r.left, r.bottom - l);
  }

  @override
  bool shouldRepaint(covariant _QrScanFramePainter oldDelegate) {
    return oldDelegate.cutout != cutout ||
        oldDelegate.cornerColor != cornerColor;
  }
}

class _ScanScreenState extends State<ScanScreen> {
  static const _rejectedCodeCooldown = Duration(seconds: 3);

  final MobileScannerController _controller = MobileScannerController();
  final GvScanErrorFeedback _errorFeedback = GvScanErrorFeedback();
  bool _handled = false;
  bool _selectingImage = false;
  String? _lastRejectedCode;
  DateTime? _lastRejectedAt;

  @override
  void dispose() {
    _controller.dispose();
    unawaited(_errorFeedback.dispose());
    super.dispose();
  }

  Future<void> _onDecoded(String text) async {
    if (_handled) return;

    final username = parseGvUidPayload(text);
    if (username != null) {
      await _handleFriendCode(username);
      return;
    }

    final channelCode = parseGvChannelCodePayload(text);
    if (channelCode != null) {
      await _handleChannelCode(channelCode);
      return;
    }

    final qrLoginToken = parseGvQrLoginPayload(text);
    if (qrLoginToken != null) {
      await _handleQrLogin(qrLoginToken);
      return;
    }

    if (mounted && _shouldReportRejectedCode(text)) {
      unawaited(_errorFeedback.play());
      GvToast.show(
        context,
        AppLocalizations.of(context)!.scanUnsupportedQrCode,
      );
    }
  }

  bool _shouldReportRejectedCode(String code) {
    final now = DateTime.now();
    final lastAt = _lastRejectedAt;
    if (_lastRejectedCode == code &&
        lastAt != null &&
        now.difference(lastAt) < _rejectedCodeCooldown) {
      return false;
    }
    _lastRejectedCode = code;
    _lastRejectedAt = now;
    return true;
  }

  /// 扫码识别频道号：查频道 → 订阅 → 进入频道聊天室。
  Future<void> _handleChannelCode(String channelCode) async {
    _handled = true;
    if (!mounted) return;
    final loc = AppLocalizations.of(context)!;
    final chat = context.read<ChatProvider>();
    try {
      final info = await chat.channelByCode(channelCode);
      if (!info.subscribed && !info.isOwner) {
        await chat.subscribeChannel(info.id);
      }
      if (!mounted) return;
      GvToast.show(context, loc.channelJoined);
      Navigator.of(context).maybePop();
      gvOpenChat(context, chatType: 'channel', peerId: info.id);
    } catch (_) {
      if (mounted) {
        setState(() => _handled = false);
        unawaited(_errorFeedback.play());
        GvToast.show(context, loc.toastChannelNotFound);
      }
    }
  }

  /// 扫码登录：识别桌面端登录二维码 → 确认 → 调 /auth/qr-login/confirm。
  Future<void> _handleQrLogin(String qrToken) async {
    _handled = true;
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('登录确认'),
        content: const Text('确认在电脑端登录 GV Chat？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确认登录'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      try {
        await context.read<ImApi>().confirmQrLogin(qrToken);
        if (mounted) {
          GvToast.show(context, '已确认登录');
          Navigator.of(context).maybePop();
        }
      } catch (_) {
        if (mounted) {
          setState(() => _handled = false);
          GvToast.show(context, '确认失败，二维码可能已过期');
        }
      }
    } else if (mounted) {
      setState(() => _handled = false);
    }
  }

  Future<void> _handleFriendCode(String username) async {
    _handled = true;
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx)!;
        return AlertDialog(
          actionsPadding: EdgeInsets.zero,
          actionsAlignment: MainAxisAlignment.start,
          buttonPadding: EdgeInsets.zero,
          title: Text(loc.scanFriendRequestDialogTitle),
          content: Text(loc.scanFriendRequestDialogBody('@$username')),
          actions: [
            GvDialogActions.weChatFooter(
              ctx,
              secondaryText: loc.commonCancel,
              primaryText: loc.commonConfirm,
              onSecondary: () => Navigator.pop(ctx, false),
              onPrimary: () => Navigator.pop(ctx, true),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) {
      if (mounted) setState(() => _handled = false);
      return;
    }
    final friend = context.read<FriendProvider>();
    final auth = context.read<AuthProvider>();
    final loc = AppLocalizations.of(context)!;
    try {
      final list = await friend.searchUser(username);
      Map<String, dynamic>? u;
      for (final e in list) {
        final m = Map<String, dynamic>.from(e as Map);
        if (m['username'] == username) {
          u = m;
          break;
        }
      }
      if (u == null) throw _ScanUserMessageException(loc.scanErrorUserNotFound);
      final id = jsonIntRequired(u['id']);
      if (id == auth.user?.id) {
        throw _ScanUserMessageException(loc.scanErrorCannotAddSelf);
      }
      if (friend.friends.any((f) => f.friendId == id)) {
        throw _ScanUserMessageException(loc.scanErrorAlreadyFriend);
      }
      final nick = auth.user?.nickname ?? auth.user?.username ?? '';
      final note = nick.isNotEmpty
          ? loc.scanFriendRequestNoteWithNick(nick)
          : loc.scanFriendRequestNote;
      await friend.sendRequest(id, note);
      if (mounted) {
        GvToast.show(
          context,
          AppLocalizations.of(context)!.toastFriendRequestSent,
        );
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _handled = false);
        final dialogL10n = AppLocalizations.of(context)!;
        final msg = e is _ScanUserMessageException
            ? e.message
            : dialogL10n.toastOperationFailed(ApiFailure.messageOf(e));
        GvToast.show(context, msg);
      }
    }
  }

  Future<void> _pickQrImageAndDecode() async {
    if (_selectingImage) return;
    setState(() => _selectingImage = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      Uint8List? bytes;
      if (kIsWeb) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true,
        );
        if (result == null || result.files.isEmpty) return;
        bytes = result.files.single.bytes;
      } else {
        final image = await ImagePicker().pickImage(
          source: ImageSource.gallery,
        );
        if (image == null) return;
        bytes = await image.readAsBytes();
      }

      if (!mounted) return;
      if (bytes == null || bytes.isEmpty) {
        GvToast.show(context, l10n.scanCouldNotReadImage);
        return;
      }
      final text = await gvDecodeQrFromImageBytes(bytes);
      if (!mounted) return;
      if (text == null || text.isEmpty) {
        GvToast.show(context, l10n.scanNoQrFoundInImage);
        return;
      }
      await _onDecoded(text);
    } catch (_) {
      if (mounted) GvToast.show(context, l10n.scanCouldNotReadImage);
    } finally {
      if (mounted) setState(() => _selectingImage = false);
    }
  }

  Widget _buildScanErrorUi(BuildContext context, MobileScannerException error) {
    final l10n = AppLocalizations.of(context)!;
    final webFallback =
        kIsWeb &&
        (error.errorCode == MobileScannerErrorCode.unsupported ||
            error.errorCode == MobileScannerErrorCode.permissionDenied);
    return ColoredBox(
      color: Colors.black,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.qr_code_scanner_outlined,
                  color: Colors.white70,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  webFallback
                      ? l10n.scanWebCameraUnavailable
                      : error.errorCode.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, height: 1.35),
                ),
                if (!webFallback && error.errorDetails?.message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    error.errorDetails!.message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => unawaited(_pickQrImageAndDecode()),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(l10n.scanPickQrImage),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      key: GvAutomationKeys.scanScreen,
      backgroundColor: Colors.black,
      appBar: GvNavBar(
        title: l10n.scanQrTitle,
        showBack: true,
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: Semantics(
              label: l10n.scanSemanticsViewfinder,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final frameRect = _scanFrameRect(constraints.biggest);
                  return MobileScanner(
                    controller: _controller,
                    scanWindow: kIsWeb ? null : frameRect,
                    errorBuilder: _buildScanErrorUi,
                    overlayBuilder: (ctx, c) {
                      return IgnorePointer(
                        child: CustomPaint(
                          painter: _QrScanFramePainter(
                            cutout: _scanFrameRect(c.biggest),
                            cornerColor: Colors.white,
                          ),
                          size: Size(c.maxWidth, c.maxHeight),
                        ),
                      );
                    },
                    onDetect: (capture) {
                      if (_selectingImage) return;
                      final codes = capture.barcodes;
                      if (codes.isEmpty) return;
                      final raw = codes.first.rawValue;
                      if (raw != null) _onDecoded(raw);
                    },
                  );
                },
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    l10n.scanHintPlaceCodeInFrame,
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ValueListenableBuilder<MobileScannerState>(
                        valueListenable: _controller,
                        builder: (context, state, _) {
                          final torch = state.torchState;
                          final available = torch != TorchState.unavailable;
                          final on = torch == TorchState.on;
                          return IconButton(
                            tooltip: l10n.scanFlashlight,
                            onPressed: available
                                ? () => unawaited(_controller.toggleTorch())
                                : null,
                            icon: Icon(
                              on ? Icons.flash_on : Icons.flash_off,
                              color: on ? Colors.amber : Colors.white70,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 24),
                      TextButton.icon(
                        onPressed: _selectingImage
                            ? null
                            : () => unawaited(_pickQrImageAndDecode()),
                        icon: _selectingImage
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white70,
                                ),
                              )
                            : const Icon(
                                Icons.photo_library_outlined,
                                color: Colors.white70,
                              ),
                        label: Text(
                          l10n.scanPickQrImage,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
