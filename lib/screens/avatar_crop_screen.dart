import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/gv_toast.dart';
import 'package:gv_ui/gv_ui.dart' show GvTypography;
import '../widgets/gv_nav_bar.dart';

/// 裁剪参数：imageBytes；[title] / [confirmButtonText] 为 null 时用 [AppLocalizations]。
class GvSquareCropExtra {
  const GvSquareCropExtra({
    required this.imageBytes,
    this.title,
    this.confirmButtonText,
    this.stickerCrop = false,
  });
  final Uint8List imageBytes;
  final String? title;
  final String? confirmButtonText;

  /// `true` 时使用表情裁剪标题（否则为头像）。
  final bool stickerCrop;
}

/// 将相册原图裁成 **正方形** 后返回 [Uint8List]（`context.pop(cropped)`）。
class AvatarCropScreen extends StatefulWidget {
  const AvatarCropScreen({
    super.key,
    required this.imageBytes,
    this.title,
    this.confirmButtonText,
    this.stickerCrop = false,
  });

  final Uint8List imageBytes;
  final String? title;
  final String? confirmButtonText;
  final bool stickerCrop;

  @override
  State<AvatarCropScreen> createState() => _AvatarCropScreenState();
}

class _AvatarCropScreenState extends State<AvatarCropScreen> {
  final CropController _cropController = CropController();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = widget.title ??
        (widget.stickerCrop
            ? l10n.avatarCropStickerTitle
            : l10n.avatarCropTitle);
    final confirm = widget.confirmButtonText ?? l10n.avatarCropDone;
    final pageBg = gvPageScaffoldBackground(context);
    return Scaffold(
      backgroundColor: pageBg,
      appBar: GvNavBar(
        title: title,
        showBack: true,
        backgroundColor: pageBg,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: Column(
        children: [
          Expanded(
            child: Crop(
              image: widget.imageBytes,
              controller: _cropController,
              aspectRatio: 1,
              interactive: true,
              baseColor: pageBg,
              maskColor: Colors.black.withValues(alpha: 0.54),
              onCropped: (result) {
                switch (result) {
                  case CropSuccess(:final croppedImage):
                    if (context.mounted) {
                      Navigator.of(context).pop(croppedImage);
                    }
                  case CropFailure(:final cause):
                    if (context.mounted) {
                      GvToast.show(
                        context,
                        AppLocalizations.of(context)!
                            .toastAvatarCropFailed(cause.toString()),
                      );
                    }
                }
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                GvSpacing.page,
                GvSpacing.sm,
                GvSpacing.page,
                GvSpacing.page,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _cropController.crop(),
                  child: Text(
                    confirm,
                    style: GvTypography.navTitle(CupertinoColors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
