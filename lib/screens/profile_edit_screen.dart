import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/gv_automation_keys.dart';
import '../core/gv_secondary_navigation.dart';
import '../core/gv_toast.dart';
import '../models/points_account_binding.dart';
import '../providers/auth_provider.dart';
import '../services/im_api.dart';
import 'package:gv_ui/gv_ui.dart' show GvTypography;
import '../widgets/gv_avatar.dart';
import '../widgets/gv_nav_bar.dart';

InputDecoration _borderlessField(
  BuildContext context, {
  required String labelText,
  String? hintText,
}) {
  final fill = AppColors.bgSearchField.resolveFrom(context);
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    filled: true,
    fillColor: fill,
    contentPadding: const EdgeInsets.symmetric(
        horizontal: GvSpacing.fieldH, vertical: GvSpacing.fieldV),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(GvRadii.input),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(GvRadii.input),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(GvRadii.input),
      borderSide: BorderSide.none,
    ),
  );
}

String? _nullIfBlank(String s) {
  final t = s.trim();
  return t.isEmpty ? null : t;
}

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late TextEditingController _nick;
  late TextEditingController _sig;
  late TextEditingController _phone;
  late TextEditingController _email;

  Uint8List? _pickedAvatarBytes;
  PointsAccountBinding? _pointsAccountBinding;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().user;
    final nick = u?.nickname?.trim();
    _nick = TextEditingController(
      text: (nick != null && nick.isNotEmpty) ? nick : (u?.username ?? ''),
    );
    _sig = TextEditingController(text: u?.signature ?? '');
    _phone = TextEditingController(text: u?.phone ?? '');
    _email = TextEditingController(text: u?.email ?? '');
  }

  @override
  void dispose() {
    _nick.dispose();
    _sig.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  /// 先选来源（拍照 / 相册），再走裁剪与上传。
  Future<ImageSource?> _chooseAvatarSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx)!;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text(loc.profileEditTakePhoto),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(loc.profileEditChooseFromGallery),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAvatar() async {
    final source = await _chooseAvatarSource();
    if (source == null || !mounted) return;
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 88,
    );
    if (x == null || !mounted) return;
    final bytes = await x.readAsBytes();
    if (!mounted) return;
    final cropped = await gvPushAvatarCropForResult(context, bytes);
    if (!mounted) return;
    if (cropped != null) {
      setState(() => _pickedAvatarBytes = cropped);
    }
  }

  Future<void> _openPointsAccountBinding() async {
    final result = await gvPushPointsAccountBindingForResult(
      context,
      current: _pointsAccountBinding,
    );
    if (result != null && mounted) {
      setState(() => _pointsAccountBinding = result);
    }
  }

  Future<void> _save() async {
    final nick = _nick.text.trim();
    if (nick.isEmpty) {
      GvToast.show(context, AppLocalizations.of(context)!.toastFillNickname);
      return;
    }

    final auth = context.read<AuthProvider>();
    final api = context.read<ImApi>();
    setState(() => _saving = true);
    try {
      String? avatarObjectId;
      if (_pickedAvatarBytes != null) {
        final uploaded = await api.uploadBytes(
          _pickedAvatarBytes!,
          'avatar.jpg',
          scope: 'profile',
          mediaKind: 'image',
        );
        avatarObjectId = uploaded.objectId;
      }

      final body = <String, dynamic>{
        'nickname': nick,
        'signature': _sig.text.trim(),
        'phone': _nullIfBlank(_phone.text),
        'email': _nullIfBlank(_email.text),
      };
      if (avatarObjectId != null) {
        body['avatar'] = avatarObjectId;
      }

      await auth.updateProfile(body);
      if (!mounted) return;
      setState(() => _pickedAvatarBytes = null);
      GvToast.show(context, AppLocalizations.of(context)!.toastProfileSaved);
    } catch (e) {
      if (mounted) {
        GvToast.show(context, auth.apiError(e));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final u = auth.user;
    final name = u?.displayName ?? '';

    return Scaffold(
      key: GvAutomationKeys.profileEditScreen,
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: GvNavBar(title: l10n.settingsProfile, showBack: true),
      body: ListView(
        padding: const EdgeInsets.all(GvSpacing.page),
        children: [
          Center(
            child: Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _saving ? null : _pickAvatar,
                    customBorder: const CircleBorder(),
                    child: _pickedAvatarBytes != null
                        ? ClipOval(
                            child: Image.memory(
                              _pickedAvatarBytes!,
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                            ),
                          )
                        : GvAvatar(
                            name: name,
                            uid: u?.id ?? 0,
                            src: u?.avatar,
                            size: 88,
                          ),
                  ),
                ),
                const SizedBox(height: GvSpacing.xs),
                TextButton(
                  onPressed: _saving ? null : _pickAvatar,
                  child: Text(
                    l10n.profileEditChangeAvatar,
                    style: GvTypography.caption(
                      AppColors.primary.resolveFrom(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: GvSpacing.page),
          TextField(
            controller: _nick,
            decoration: _borderlessField(
              context,
              labelText: l10n.profileFieldNickname,
              hintText: l10n.profileFieldRequiredHint,
            ),
          ),
          const SizedBox(height: GvSpacing.page),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: _borderlessField(
              context,
              labelText: l10n.profileFieldPhone,
              hintText: l10n.profileFieldOptionalHint,
            ),
          ),
          const SizedBox(height: GvSpacing.page),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: _borderlessField(
              context,
              labelText: l10n.profileFieldEmail,
              hintText: l10n.profileFieldOptionalHint,
            ),
          ),
          const SizedBox(height: GvSpacing.page),
          TextField(
            controller: _sig,
            maxLines: 3,
            minLines: 1,
            decoration: _borderlessField(
              context,
              labelText: l10n.profileFieldSignature,
              hintText: l10n.profileFieldSignatureHint,
            ),
          ),
          const SizedBox(height: GvSpacing.page),
          Material(
            color: AppColors.bgWhite.resolveFrom(context),
            borderRadius: BorderRadius.circular(GvRadii.card),
            child: InkWell(
              key: GvAutomationKeys.pointsAccountEntry,
              onTap: _saving ? null : _openPointsAccountBinding,
              borderRadius: BorderRadius.circular(GvRadii.card),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: GvSpacing.page,
                  vertical: GvSpacing.page,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary
                            .resolveFrom(context)
                            .withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(GvRadii.input),
                      ),
                      child: Icon(
                        Icons.verified_user_outlined,
                        size: 22,
                        color: AppColors.primary.resolveFrom(context),
                      ),
                    ),
                    const SizedBox(width: GvSpacing.page),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.pointsAccountEntryTitle,
                            style: GvTypography.caption(
                              AppColors.textSecondary.resolveFrom(context),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              if (_pointsAccountBinding != null) ...[
                                Container(
                                  width: 7,
                                  height: 7,
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.success.resolveFrom(context),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                              Flexible(
                                child: Text(
                                  _pointsAccountBinding?.maskedAccount ??
                                      l10n.pointsAccountNotBound,
                                  overflow: TextOverflow.ellipsis,
                                  style: GvTypography.bodySmall(
                                    _pointsAccountBinding == null
                                        ? AppColors.textHint
                                            .resolveFrom(context)
                                        : AppColors.textPrimary
                                            .resolveFrom(context),
                                  ).copyWith(
                                    fontWeight: _pointsAccountBinding == null
                                        ? FontWeight.w400
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textHint.resolveFrom(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: GvSpacing.page),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: CupertinoColors.white,
                    ),
                  )
                : Text(
                    l10n.commonSave,
                    style: GvTypography.navTitle(CupertinoColors.white),
                  ),
          ),
        ],
      ),
    );
  }
}
