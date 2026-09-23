import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../app/app_routes.dart';
import '../models/points_account_binding.dart';
import '../screens/avatar_crop_screen.dart';

/// 打开设置。
void gvOpenSettings(BuildContext context) {
  context.push('/settings');
}

/// 从通讯录列表进详细资料。
void gvOpenContactFromContactsList(BuildContext context, String id) {
  context.push('/contacts/$id');
}

/// 打开好友资料。
/// [fromGroup] 标记「从群成员进入」，好友申请会带 source=group（触发隐私开关）；
/// [sourceGroupId] 携带来源群 id，用于群级「禁止添加群成员为好友」校验。
/// [hideAccountDetails] 用于群级隐私限制：资料页仅展示头像与显示名。
/// [hideFriendRequest] 用于群级隐私限制：资料页隐藏添加好友入口。
/// 返回 [Future]，完成于目标页弹出返回时（便于调用方在返回后刷新好友列表）。
Future<void> gvPushContactDetail(BuildContext context, String id,
    {bool fromGroup = false,
    int? sourceGroupId,
    bool hideAccountDetails = false,
    bool hideFriendRequest = false}) async {
  await context.push('/contacts/$id', extra: (
    fromGroup: fromGroup,
    sourceGroupId: sourceGroupId,
    hideAccountDetails: hideAccountDetails,
    hideFriendRequest: hideFriendRequest,
  ));
}

/// 打开群资料。
void gvPushGroupInfo(BuildContext context, String id) {
  context.push('/groups/$id');
}

void gvOpenAddFriend(BuildContext context) {
  context.push('/contacts/add');
}

void gvOpenFriendRequests(BuildContext context) {
  context.push('/contacts/requests');
}

void gvOpenBlacklist(BuildContext context) {
  context.push('/settings/blacklist');
}

void gvOpenFriendGroups(BuildContext context) {
  context.push('/contacts/friend-groups');
}

void gvOpenCreateGroup(BuildContext context) {
  context.push('/groups/create');
}

void gvOpenCreateSecretGroup(BuildContext context) {
  context.push('/groups/create-secret-group');
}

void gvPushInviteMembers(BuildContext context, String groupId) {
  context.push('/groups/$groupId/invite');
}

void gvPushChatHistoryContact(BuildContext context, String peerId) {
  context.push('/contacts/$peerId/chat-history');
}

void gvPushChatHistoryGroup(BuildContext context, String groupId) {
  context.push('/groups/$groupId/chat-history');
}

void gvOpenProfileEdit(BuildContext context) {
  context.push('/settings/profile');
}

Future<PointsAccountBinding?> gvPushPointsAccountBindingForResult(
  BuildContext context, {
  PointsAccountBinding? current,
}) {
  return context.push<PointsAccountBinding?>(
    AppRoutes.settingsPointsAccount,
    extra: current,
  );
}

void gvOpenChangePassword(BuildContext context) {
  context.push('/settings/password');
}

void gvOpenScan(BuildContext context) {
  context.push('/scan');
}

/// 裁剪页，返回裁剪后的字节。
///
/// [title] / [confirmButtonText] 为 null 时由 [AvatarCropScreen] 按语言填充；
/// [stickerCrop] 为 true 时用表情裁剪标题。
Future<Uint8List?> gvPushAvatarCropForResult(
  BuildContext context,
  Uint8List imageBytes, {
  String? title,
  String? confirmButtonText,
  bool stickerCrop = false,
}) async {
  return context.push<Uint8List?>(
    '/avatar-crop',
    extra: GvSquareCropExtra(
      imageBytes: imageBytes,
      title: title,
      confirmButtonText: confirmButtonText,
      stickerCrop: stickerCrop,
    ),
  );
}

/// 解散/退群/删好友后：先 pop 再 go 到通讯录。
void gvNavigateContactsAfterRemoveOnDesktop(BuildContext context) {
  final router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop();
  }
  router.go('/contacts');
}

/// 建群成功：pop 掉创建页后 push 全屏聊天。
///
/// 不可用 [GoRouter.go] 进聊天室：go 会清栈，返回键无法回到消息/通讯录。
/// 应先 [GoRouter.pop] 掉 /groups/create，再 [GoRouter.push] 全屏聊天（与 [gvOpenChat] 一致）。
void gvAfterCreateGroupNavigateToChat(
  BuildContext context, {
  required String groupId,
}) {
  final router = GoRouter.of(context);
  router.pop();
  router.push('/chat/group/$groupId');
}
