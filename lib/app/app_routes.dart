class AppRoutes {
  const AppRoutes._();

  static const login = '/login';
  static const register = '/register';
  static const chats = '/chats';
  static const contacts = '/contacts';
  static const services = '/services';
  static const serviceDemo = '/services/demo/:category';
  static const ktvOAuth = '/services/ktv/oauth';
  static const profile = '/profile';
  static const chat = '/chat/:chatType/:peerId';
  static const forwardMessage = '/forward-message';
  static const shareChannel = '/share-channel';
  static const shareMedia = '/share-media';
  static const recommendContact = '/recommend-contact';
  static const contactsAdd = '/contacts/add';
  static const contactsRequests = '/contacts/requests';
  static const contactDetail = '/contacts/:id';
  static const friendGroups = '/contacts/friend-groups';
  static const groupsCreate = '/groups/create';
  static const secretGroupsCreate = '/groups/create-secret-group';
  static const groupInvite = '/groups/:id/invite';
  static const groupDetail = '/groups/:id';
  static const settings = '/settings';
  static const favorites = '/favorites';

  /// 收藏详情页（`extra` 传收藏记录 [ChatMessage]，渲染收藏自身保存的内容）。
  static const favoriteDetail = '/favorites/detail';
  static const settingsProfile = '/settings/profile';
  static const settingsPointsAccount = '/settings/profile/points-account';
  static const settingsBlacklist = '/settings/blacklist';
  static const avatarCrop = '/avatar-crop';
  static const settingsPassword = '/settings/password';
  static const settingsDevices = '/settings/devices';
  static const notificationSettings = '/settings/notifications';
  static const selfDestruct = '/settings/self-destruct';
  static const chatStorage = '/settings/storage';
  static const chatBackup = '/settings/chat-backup';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const scan = '/scan';
  static const call = '/call';

  // B端（商家 / 门店）路由。
  static const businessPrefix = '/business';
  static const businessLogin = '/business/login';
  static const ktvDashboard = '/business/ktv/dashboard';
  static const ktvQuickOpen = '/business/ktv/quick-open';
  static const ktvTiming = '/business/ktv/timing';
  static const ktvSettle = '/business/ktv/settle';
  static const ktvCashier = '/business/ktv/cashier';
  static const ktvShift = '/business/ktv/shift';

  /// 客户「待确认加项」集中处理页（B 端 / A380 收银端）。
  static const ktvPendingApproval = '/business/ktv/pending-approval';

  static const chatHistorySegment = 'chat-history';

  static String chatRoom({
    required String chatType,
    required String peerId,
    String? anchorMsgId,
  }) {
    final base = '/chat/$chatType/$peerId';
    if (anchorMsgId == null || anchorMsgId.isEmpty) return base;
    return '$base?msg=$anchorMsgId';
  }

  static String serviceDemoPath(String category) =>
      '/services/demo/${Uri.encodeComponent(category)}';
}
