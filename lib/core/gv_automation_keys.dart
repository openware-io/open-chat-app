import 'package:flutter/widgets.dart';

/// Stable widget identifiers used by integration tests and accessibility tools.
///
/// Keep these values independent from localized copy and visual layout so an
/// automation flow does not break when labels or spacing change.
abstract final class GvAutomationKeys {
  static const tabMessages = ValueKey<String>('automation.tab.messages');
  static const tabContacts = ValueKey<String>('automation.tab.contacts');
  static const tabServices = ValueKey<String>('automation.tab.services');
  static const tabProfile = ValueKey<String>('automation.tab.profile');

  static const loginScreen = ValueKey<String>('automation.login.screen');
  static const loginUsername = ValueKey<String>('automation.login.username');
  static const loginPassword = ValueKey<String>('automation.login.password');
  static const loginAgreement = ValueKey<String>('automation.login.agreement');
  static const loginSubmit = ValueKey<String>('automation.login.submit');

  static const chatListScreen = ValueKey<String>('automation.chatList.screen');
  static const chatListSearch = ValueKey<String>('automation.chatList.search');
  static const chatListAdd = ValueKey<String>('automation.chatList.add');
  static const chatListAddFriend =
      ValueKey<String>('automation.chatList.add.friend');
  static const chatListCreateGroup =
      ValueKey<String>('automation.chatList.add.group');
  static const chatListCreateChannel =
      ValueKey<String>('automation.chatList.add.channel');
  static const chatListSearchChannel =
      ValueKey<String>('automation.chatList.add.channelSearch');
  static const chatListJoinChannel =
      ValueKey<String>('automation.chatList.add.channelJoin');
  static const chatListScan = ValueKey<String>('automation.chatList.add.scan');

  static ValueKey<String> conversation(String chatType, String peerId) =>
      ValueKey<String>('automation.chatList.$chatType.$peerId');

  static const chatRoomScreen = ValueKey<String>('automation.chatRoom.screen');
  static const chatComposerInput =
      ValueKey<String>('automation.chatRoom.composer.input');
  static const chatComposerSend =
      ValueKey<String>('automation.chatRoom.composer.send');
  static const chatMoreCamera =
      ValueKey<String>('automation.chatRoom.more.camera');
  static const chatCameraScreen =
      ValueKey<String>('automation.chatRoom.camera.screen');
  static const chatCameraShutter =
      ValueKey<String>('automation.chatRoom.camera.shutter');
  static const pendingImageDraft =
      ValueKey<String>('automation.chatRoom.pendingImage');
  static const pendingImageCaption =
      ValueKey<String>('automation.chatRoom.pendingImage.caption');
  static const pendingImageCancel =
      ValueKey<String>('automation.chatRoom.pendingImage.cancel');
  static const messageDeleteMenu =
      ValueKey<String>('automation.chatRoom.message.delete');
  static const messageDeleteCancel =
      ValueKey<String>('automation.chatRoom.message.delete.cancel');
  static const messageDeleteConfirm =
      ValueKey<String>('automation.chatRoom.message.delete.confirm');

  static const contactsScreen = ValueKey<String>('automation.contacts.screen');
  static const contactsSearch = ValueKey<String>('automation.contacts.search');
  static const contactsAddFriend =
      ValueKey<String>('automation.contacts.addFriend');
  static const contactsFriendRequests =
      ValueKey<String>('automation.contacts.friendRequests');
  static const contactsCreateGroup =
      ValueKey<String>('automation.contacts.createGroup');

  static const servicesScreen = ValueKey<String>('automation.services.screen');
  static const servicesSearch = ValueKey<String>('automation.services.search');
  static const protocolWebViewScreen =
      ValueKey<String>('automation.protocolWebView.screen');

  static const profileScreen = ValueKey<String>('automation.profile.screen');
  static const profileQrCode = ValueKey<String>('automation.profile.qrCode');
  static const profileQrDialog =
      ValueKey<String>('automation.profile.qrDialog');
  static const profileQrClose =
      ValueKey<String>('automation.profile.qrDialog.close');
  static const profileFavorites =
      ValueKey<String>('automation.profile.favorites');
  static const profileSettings =
      ValueKey<String>('automation.profile.settings');

  static const settingsScreen = ValueKey<String>('automation.settings.screen');
  static const settingsProfile =
      ValueKey<String>('automation.settings.profile');
  static const settingsPassword =
      ValueKey<String>('automation.settings.password');
  static const settingsAppearance =
      ValueKey<String>('automation.settings.appearance');
  static const settingsLanguage =
      ValueKey<String>('automation.settings.language');
  static const settingsNotifications =
      ValueKey<String>('automation.settings.notifications');
  static const settingsLogout = ValueKey<String>('automation.settings.logout');

  static const addFriendScreen =
      ValueKey<String>('automation.addFriend.screen');
  static const friendRequestsScreen =
      ValueKey<String>('automation.friendRequests.screen');
  static const createGroupScreen =
      ValueKey<String>('automation.createGroup.screen');
  static const profileEditScreen =
      ValueKey<String>('automation.profileEdit.screen');
  static const pointsAccountEntry =
      ValueKey<String>('automation.profileEdit.pointsAccount');
  static const pointsAccountBindingScreen =
      ValueKey<String>('automation.pointsAccount.screen');
  static const pointsAccountInput =
      ValueKey<String>('automation.pointsAccount.input');
  static const pointsAccountRequestCode =
      ValueKey<String>('automation.pointsAccount.requestCode');
  static const pointsAccountOtpInput =
      ValueKey<String>('automation.pointsAccount.otp');
  static const pointsAccountPasswordInput =
      ValueKey<String>('automation.pointsAccount.password');
  static const pointsAccountConfirm =
      ValueKey<String>('automation.pointsAccount.confirm');
  static const pointsAccountSuccessReturn =
      ValueKey<String>('automation.pointsAccount.successReturn');
  static const changePasswordScreen =
      ValueKey<String>('automation.changePassword.screen');
  static const notificationSettingsScreen =
      ValueKey<String>('automation.notificationSettings.screen');
  static const scanScreen = ValueKey<String>('automation.scan.screen');

  /// 创建频道弹窗的名称输入框。
  static const channelNameField =
      ValueKey<String>('automation.channel.create.name');

  /// 频道搜索弹窗的关键字输入框。
  static const channelSearchField =
      ValueKey<String>('automation.channel.search.input');

  /// 输入频道号订阅弹窗的频道号输入框。
  static const channelJoinCodeField =
      ValueKey<String>('automation.channel.join.code');

  /// 频道信息弹层中的分享按钮。
  static const channelShareButton =
      ValueKey<String>('automation.channel.info.share');

  /// 频道信息弹层中的二维码按钮。
  static const channelQrButton = ValueKey<String>('automation.channel.info.qr');

  /// 频道信息弹层中的取消订阅按钮。
  static const channelUnsubscribeButton =
      ValueKey<String>('automation.channel.info.unsubscribe');

  /// 频道信息弹层中的编辑按钮。
  static const channelEditButton =
      ValueKey<String>('automation.channel.info.edit');

  /// 频道信息弹层中的删除按钮。
  static const channelDeleteButton =
      ValueKey<String>('automation.channel.info.delete');

  /// 私密聊天设置弹层中的安全码复制按钮。
  static const secretChatSafeCodeCopy =
      ValueKey<String>('automation.secretChat.safeCode.copy');
}
