// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'WV Chat';

  @override
  String get appSubtitle => '安全、快速的即时通讯';

  @override
  String get tabMessages => '消息';

  @override
  String get tabContacts => '通讯录';

  @override
  String get tabServices => '服务';

  @override
  String get tabMe => '我';

  @override
  String get addFriendTitle => '添加好友';

  @override
  String get startGroupChatTitle => '发起群聊';

  @override
  String get scanQrTitle => '扫一扫';

  @override
  String get scanSemanticsViewfinder => '二维码扫描区域，请将好友码或小程序码对准取景框';

  @override
  String get scanHintPlaceCodeInFrame => '将好友码或小程序码放入框内';

  @override
  String get scanFlashlight => '手电筒';

  @override
  String get scanFriendRequestDialogTitle => '发出朋友申请';

  @override
  String scanFriendRequestDialogBody(String username) {
    return '是否向 $username 发送好友申请？';
  }

  @override
  String get scanErrorUserNotFound => '未找到该用户';

  @override
  String get scanErrorCannotAddSelf => '不能添加自己';

  @override
  String get scanErrorAlreadyFriend => '对方已是你的好友';

  @override
  String get scanFriendRequestNote => '扫一扫添加';

  @override
  String scanFriendRequestNoteWithNick(String nick) {
    return '扫一扫添加（$nick）';
  }

  @override
  String get scanPickQrImage => '从相册选取二维码';

  @override
  String get scanWebCameraUnavailable =>
      '无法使用摄像头扫码（请使用 HTTPS 或 localhost 打开页面，并允许相机权限）。也可从相册选择含二维码的图片识别。';

  @override
  String get scanNoQrFoundInImage => '未在图片中识别到二维码';

  @override
  String get scanCouldNotReadImage => '无法读取所选图片';

  @override
  String get scanUnsupportedQrCode => '无法识别此二维码';

  @override
  String tabBadgeUnread(int count) {
    return '$count条未读消息';
  }

  @override
  String get tabBadgeDot => '有新通知';

  @override
  String get settingsTitle => '设置';

  @override
  String get profileMyQrCode => '我的二维码';

  @override
  String get profileSaveQrCode => '保存二维码';

  @override
  String get settingsProfile => '个人信息';

  @override
  String get settingsChangePassword => '修改密码';

  @override
  String get settingsCheckUpdate => '检查更新';

  @override
  String get settingsVersionCurrent => '当前版本';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsNotifications => '消息通知';

  @override
  String get settingsNotifyDetail => '离线推送通知';

  @override
  String get settingsNotifyPrivate => '私聊离线推送';

  @override
  String get settingsNotifyGroup => '群聊离线推送';

  @override
  String get settingsNotifyChannel => '频道离线推送';

  @override
  String get settingsAllowGroupFriendRequest => '允许通过群聊添加我为好友';

  @override
  String get settingsHideGroupMemberInfo => '群成员隐私保护';

  @override
  String get settingsHideGroupMemberInfoSubtitle => '隐藏非好友成员的用户名和头像';

  @override
  String get appAppearanceLight => '浅色';

  @override
  String get appAppearanceDark => '深色';

  @override
  String get settingsLanguageSubtitle => '跟随系统、简体中文或 English';

  @override
  String get langFollowSystem => '跟随系统';

  @override
  String get langChinese => '简体中文';

  @override
  String get langEnglish => 'English';

  @override
  String get settingsLogout => '退出登录';

  @override
  String get settingsLogoutConfirmTitle => '退出登录';

  @override
  String get settingsLogoutConfirmBody => '确定退出登录吗？';

  @override
  String get settingsDeleteAccount => '注销账号';

  @override
  String get settingsDeleteAccountNoticeTitle => '注销须知';

  @override
  String get settingsDeleteAccountNoticeBody =>
      '注销后账号将立即停用，无法使用当前用户名和密码再次登录；用户名可能被释放供他人注册。聊天记录等数据可能仍保留在服务端。此操作不可撤销，请谨慎确认。';

  @override
  String get settingsDeleteAccountNoticeConfirm => '我已知晓，继续注销';

  @override
  String get settingsDeleteAccountPasswordTitle => '验证密码';

  @override
  String get settingsDeleteAccountPasswordHint => '请输入当前登录密码';

  @override
  String get settingsDeleteAccountSubmit => '确认注销';

  @override
  String get toastDeleteAccountSuccess => '账号已注销';

  @override
  String get loginUsernameHint => '请输入用户名';

  @override
  String get loginPasswordHint => '请输入密码';

  @override
  String get loginUsernamePasswordRequired => '请输入用户名和密码';

  @override
  String get loginButton => '登录';

  @override
  String get loginLoading => '登录中...';

  @override
  String get loginNoAccount => '还没有账号？';

  @override
  String get loginRegister => '注册';

  @override
  String get authAgreementPrefix => '已阅读并同意';

  @override
  String get authAgreementUserTerms => '用户协议';

  @override
  String get authAgreementAnd => '和';

  @override
  String get authAgreementPrivacy => '隐私政策';

  @override
  String get authAgreementRequired => '请先阅读并同意用户协议和隐私政策';

  @override
  String get updateChecking => '正在检查更新…';

  @override
  String get updateUpToDate => '当前已是最新版本';

  @override
  String get updateNoReleaseInfo => '暂无发布信息';

  @override
  String get updateMandatoryTitle => '需要更新';

  @override
  String get updateSuggestTitle => '发现新版本（建议更新）';

  @override
  String get updateNewVersionTitle => '发现新版本';

  @override
  String get updateNoNotes => '暂无更新说明';

  @override
  String updateLatestVersionLine(String versionName, int versionCode) {
    return '最新版本：$versionName（构建 $versionCode）';
  }

  @override
  String get updateNoDownloadUrl => '未配置下载或商店地址，请联系管理员';

  @override
  String get updateInvalidUrl => '无效的下载地址';

  @override
  String get updateCannotOpenLink => '无法打开链接';

  @override
  String get updateLater => '稍后';

  @override
  String get updateNow => '立即更新';

  @override
  String get updateDownloading => '正在下载更新…';

  @override
  String updateDownloadFailed(String message) {
    return '更新失败：$message';
  }

  @override
  String get updateReadyToInstallTitle => '准备安装';

  @override
  String get updateReadyToInstallBody => '安装包已下载完成。点击确定后应用将关闭，安装结束后会自动重新打开。';

  @override
  String get updateInstallSucceeded => '更新已成功安装。';

  @override
  String get updateInstallFailedTitle => '更新失败';

  @override
  String get commonNetworkError => '网络错误';

  @override
  String get routeInvalidArguments => '参数错误';

  @override
  String get commonOk => '知道了';

  @override
  String get commonConfirm => '确定';

  @override
  String get commonCancel => '取消';

  @override
  String get commonRetry => '重试';

  @override
  String get commonDownload => '下载';

  @override
  String get commonShare => '分享';

  @override
  String reportTitle(String name) {
    return '举报 $name';
  }

  @override
  String get reportReasonObscene => '色情低俗';

  @override
  String get reportReasonHarassment => '骚扰辱骂';

  @override
  String get reportReasonScam => '广告欺诈';

  @override
  String get reportReasonPolitical => '政治敏感';

  @override
  String get reportReasonIllegal => '违法信息';

  @override
  String get reportReasonOther => '其他';

  @override
  String get reportPickReason => '请选择举报原因';

  @override
  String get reportSubmitted => '举报已提交，我们会尽快处理';

  @override
  String get reportFailed => '举报失败，请稍后重试';

  @override
  String get reportDescHint => '补充说明（选填）';

  @override
  String get reportSubmit => '提交举报';

  @override
  String get mapChooseApp => '选择地图应用';

  @override
  String get mapAppleMaps => 'Apple 地图';

  @override
  String get mapGoogleMaps => 'Google 地图';

  @override
  String get mapAmap => '高德地图';

  @override
  String get mapOpenInExternalApp => '在地图应用中打开';

  @override
  String get chatFileDownloadExplain => '下载文件到本机应用文档目录，可在系统文件管理器中查看。';

  @override
  String get chatFileSavedToast => '已保存到应用文档目录';

  @override
  String get chatFileDownloadFailedToast => '下载失败';

  @override
  String get miniProgramTitle => '小程序';

  @override
  String get miniProgramNoIntro => '暂无介绍';

  @override
  String get miniProgramViewFullIntro => '查看全部';

  @override
  String get miniProgramShare => '分享';

  @override
  String get miniProgramReenter => '重新进入';

  @override
  String get miniProgramAppIntro => '应用介绍';

  @override
  String get miniProgramWebUnsupported => '当前环境不支持内置网页';

  @override
  String get miniProgramCannotOpenUrl => '无法打开小程序链接';

  @override
  String get miniProgramLoadSlow => '加载偏慢，已显示网页内容';

  @override
  String get composerHint => '输入消息...';

  @override
  String get composerHoldToTalk => '按住 说话';

  @override
  String get bannerNewMessage => '收到新消息';

  @override
  String get toastQrSaveNotSupported => '当前平台不支持保存到相册';

  @override
  String get toastSearchFailed => '检索失败';

  @override
  String get toastLoadMoreFailed => '加载更多失败';

  @override
  String get toastChatHistoryFriendsOnly => '仅好友可查看聊天记录';

  @override
  String get toastChatHistoryGroupOnly => '仅群成员可查看聊天记录';

  @override
  String get featurePrivateChatDisabled => '单聊功能已关闭';

  @override
  String get featureGroupChatDisabled => '群聊功能已关闭';

  @override
  String get toastMessageNotFound => '未找到该消息';

  @override
  String get toastMicPermissionRequired => '需要麦克风权限才能发送语音';

  @override
  String toastVoiceRecordStartFailed(String error) {
    return '无法开始录音：$error';
  }

  @override
  String get toastVoiceWebNoEncoder => '当前浏览器不支持语音录制（无可用编码格式）';

  @override
  String toastFileExceedsLimit(int mb) {
    return '文件超过限制（${mb}MB）';
  }

  @override
  String get toastFilePickReadFailed => '无法读取所选文件，请重新选择';

  @override
  String get toastMapTilesNotConfigured => '当前未配置地图瓦片，无法发送位置';

  @override
  String get toastVideoCallDisabled => '视频通话已关闭';

  @override
  String get toastVoiceCallDisabled => '语音通话已关闭';

  @override
  String get toastCannotCallSelf => '不能与自己通话';

  @override
  String get toastAlreadyInCall => '当前已在通话中';

  @override
  String get toastStickerAdded => '已添加到表情包';

  @override
  String get toastCouponsComingSoon => '优惠券功能即将上线';

  @override
  String get toastServiceNoUrl => '该服务未配置访问地址';

  @override
  String get toastFillNickname => '请填写昵称';

  @override
  String get toastProfileSaved => '已保存';

  @override
  String get toastMiniProgramNoShare => '该小程序暂不支持分享码';

  @override
  String get toastEnterCurrentPassword => '请输入当前密码';

  @override
  String get toastNewPasswordMinLength => '新密码至少 6 位';

  @override
  String get toastNewPasswordMismatch => '两次新密码不一致';

  @override
  String get toastPasswordUpdated => '密码已更新';

  @override
  String get toastMembersAdded => '已添加成员';

  @override
  String get toastMiniProgramNotFound => '未找到该小程序';

  @override
  String get toastMiniProgramNoEntry => '该小程序未配置入口';

  @override
  String get toastScanFriendOrMiniCode => '请扫描好友码或小程序码';

  @override
  String get toastScanFriendCode => '请扫描好友码';

  @override
  String get toastFriendRequestSent => '申请已发送';

  @override
  String get toastGroupChatCleared => '已清空本地群聊天记录';

  @override
  String get toastGroupDissolved => '群聊已解散';

  @override
  String get chatPeerUnavailableToast => '不是好友或此群已解散';

  @override
  String get groupOwnerWelcomeMessage => '你好';

  @override
  String get groupOwnerBadge => '群主';

  @override
  String get groupAutoMessageDissolved => '此群已解散';

  @override
  String toastOperationFailed(String error) {
    return '操作失败：$error';
  }

  @override
  String get toastEnterGroupName => '请输入群名称';

  @override
  String get toastForwarded => '已转发';

  @override
  String get toastSent => '已发送';

  @override
  String get toastFriendRequestSentDetail => '好友申请已发送';

  @override
  String get toastPrivateChatCleared => '已清空本地聊天记录';

  @override
  String toastAvatarCropFailed(String error) {
    return '裁剪失败：$error';
  }

  @override
  String get toastImageSavedToDocuments => '已保存到应用文档目录';

  @override
  String get toastImageSaveFailed => '保存失败，请检查网络';

  @override
  String get errorLocationServiceDisabled => '位置服务未开启';

  @override
  String get errorLocationPermissionDenied => '缺少定位权限';

  @override
  String get toastRetryShort => '请稍后重试';

  @override
  String get toastImageGenerateFailed => '生成图片失败';

  @override
  String get toastGalleryPermissionRequired => '需要相册权限才能保存';

  @override
  String get toastSavedToGallery => '已保存到相册';

  @override
  String get toastSaveFailedShort => '保存失败';

  @override
  String get galErrorAccessDenied => '没有相册访问权限';

  @override
  String get galErrorNotEnoughSpace => '存储空间不足';

  @override
  String get galErrorUnsupportedFormat => '不支持的图片格式';

  @override
  String get galErrorUnexpected => '保存失败，请允许相册权限后重试（设置 → 隐私 → 照片）';

  @override
  String get commonSave => '保存';

  @override
  String get commonSearch => '搜索';

  @override
  String displayUserIdLabel(String id) {
    return '用户';
  }

  @override
  String get contactDetailTitle => '详细资料';

  @override
  String contactAccountLine(String account) {
    return '账号：$account';
  }

  @override
  String get contactSendMessage => '发消息';

  @override
  String get contactRemarkLabel => '备注';

  @override
  String get contactRemarkNotSet => '未设置';

  @override
  String get contactRecommendToFriends => '推荐给好友';

  @override
  String get chatHistoryTitle => '聊天记录';

  @override
  String get contactClearChatTitle => '清空聊天记录';

  @override
  String get chatClearAlsoDeleteServer => '同时删除服务端';

  @override
  String get chatDeleteForMe => '删除仅我';

  @override
  String get chatDeleteForEveryone => '删除所有人';

  @override
  String get chatMultiSelect => '多选';

  @override
  String chatMultiSelectCount(Object count) {
    return '已选 $count 条';
  }

  @override
  String get chatDeleteSelected => '删除所选';

  @override
  String get contactClearChatConfirmBody =>
      '确定要清空本机的聊天记录吗？该操作只影响当前账号在本机的显示，不会删除对方或服务端的记录。';

  @override
  String get contactClearChatRow => '清空本地聊天记录';

  @override
  String get contactBlockTitle => '加入黑名单';

  @override
  String get contactBlockConfirmBody => '确定要拉黑该好友吗？';

  @override
  String get contactBlockAction => '加入黑名单';

  @override
  String get contactDeleteFriendTitle => '删除好友';

  @override
  String get contactDeleteFriendConfirmBody => '确定要删除该好友吗？删除后聊天记录将保留。';

  @override
  String get contactDeleteFriendAction => '删除好友';

  @override
  String get contactReport => '举报';

  @override
  String get contactUnblockTitle => '移出黑名单';

  @override
  String get contactUnblockConfirmBody => '确定要将该好友移出黑名单吗？';

  @override
  String get contactUnblockAction => '移出黑名单';

  @override
  String get blacklistTitle => '黑名单';

  @override
  String get blacklistEmpty => '暂无被拉黑的好友';

  @override
  String get blacklistLoadFailed => '加载失败';

  @override
  String get settingsBlacklist => '黑名单';

  @override
  String get friendGroupsTitle => '好友分组';

  @override
  String get friendGroupCreate => '新建分组';

  @override
  String get friendGroupNoGroup => '无分组';

  @override
  String get setFriendGroupTitle => '设置分组';

  @override
  String get friendGroupNameHint => '输入分组名称';

  @override
  String get friendGroupEmpty => '暂无分组';

  @override
  String friendGroupMemberCount(int count) {
    return '共 $count 位好友';
  }

  @override
  String get friendGroupCreateSuccess => '分组创建成功';

  @override
  String get friendGroupCreateFailed => '分组创建失败，请稍后重试';

  @override
  String get friendGroupRename => '重命名';

  @override
  String get friendGroupDelete => '删除分组';

  @override
  String get friendGroupDeleteConfirm => '删除该分组后，分组内好友将变为无分组。';

  @override
  String get friendGroupRenameSuccess => '分组已重命名';

  @override
  String get friendGroupDeleteSuccess => '分组已删除';

  @override
  String get contactVoiceCall => '语音通话';

  @override
  String get contactVideoCall => '视频通话';

  @override
  String get contactRemarkEditTitle => '设置备注';

  @override
  String get contactRemarkHint => '输入备注名';

  @override
  String get addFriendSearchFieldHint => '输入用户名/手机号搜索';

  @override
  String get addFriendSearchPrompt => '搜索用户名或手机号';

  @override
  String get addFriendNoUsers => '未找到用户';

  @override
  String get addFriendAlreadyFriends => '已是好友';

  @override
  String get addFriendRequestSent => '已发送';

  @override
  String get addFriendAction => '添加';

  @override
  String get groupChatDefaultName => '群聊';

  @override
  String get groupClearHistoryTitle => '清空群聊天记录';

  @override
  String get groupClearHistoryConfirmBody =>
      '确定要清空本机的群聊天记录吗？该操作只影响当前账号在本机的显示，不会删除其他成员或服务端的记录。';

  @override
  String get groupClearHistoryRow => '清空本地聊天记录';

  @override
  String get groupDissolveAction => '解散群聊';

  @override
  String get groupMuteAction => '禁言';

  @override
  String get groupMute10Minutes => '禁言 10 分钟';

  @override
  String get groupMute1Hour => '禁言 1 小时';

  @override
  String get groupMute1Day => '禁言 1 天';

  @override
  String get groupUnmuteAction => '取消禁言';

  @override
  String get groupSetAdminAction => '设为管理员';

  @override
  String get groupUnsetAdminAction => '取消管理员';

  @override
  String get groupMuteSuccess => '已禁言';

  @override
  String get groupUnmuteSuccess => '已取消禁言';

  @override
  String get groupSetAdminSuccess => '已设为管理员';

  @override
  String get groupUnsetAdminSuccess => '已取消管理员';

  @override
  String get groupLeaveAction => '退出群聊';

  @override
  String get groupDissolveConfirmBody => '确定解散群聊？';

  @override
  String get groupLeaveConfirmBody => '确定退出群聊？';

  @override
  String groupShowAllMembers(int count) {
    return '查看全部 $count 位成员';
  }

  @override
  String get groupCollapseMembers => '收起';

  @override
  String get groupEditNameTitle => '修改群聊名称';

  @override
  String get groupNameFieldHint => '请输入群名称';

  @override
  String get groupAnnouncementViewEmpty => '暂无公告';

  @override
  String get groupAnnouncementRowPlaceholder => '未设置';

  @override
  String get groupAnnouncementLabel => '群公告';

  @override
  String get groupNameLabel => '群聊名称';

  @override
  String get groupEditAnnouncementTitle => '编辑群公告';

  @override
  String get groupAnnouncementFieldHint => '填写群公告（可留空）';

  @override
  String groupRemoveMemberConfirm(String name) {
    return '将「$name」移出群聊？';
  }

  @override
  String get groupRemoveMemberAction => '移出';

  @override
  String get groupMemberLongPressRemoveHint => '，长按移除成员';

  @override
  String get groupInvite => '邀请';

  @override
  String get groupAllowMemberInvite => '允许群成员邀请';

  @override
  String get groupAllowMemberFriendRequest => '允许群成员互加好友';

  @override
  String get groupMemberFriendRequestDisabled => '已禁用添加群成员为好友';

  @override
  String get inviteGroupMembersTitle => '邀请成员';

  @override
  String get chatHistoryNoPermission => '暂无权限查看聊天记录';

  @override
  String get chatHistoryTabText => '文本';

  @override
  String get chatHistoryTabFiles => '文件';

  @override
  String get chatHistoryTabImages => '图片';

  @override
  String get chatHistoryTabVideos => '视频';

  @override
  String get chatHistoryTabDate => '日期';

  @override
  String get chatHistoryDateSelect => '点击有圆点的日期查看聊天记录';

  @override
  String get chatHistoryDateEmpty => '该日期暂无消息';

  @override
  String get chatHistoryWeekMon => '一';

  @override
  String get chatHistoryWeekTue => '二';

  @override
  String get chatHistoryWeekWed => '三';

  @override
  String get chatHistoryWeekThu => '四';

  @override
  String get chatHistoryWeekFri => '五';

  @override
  String get chatHistoryWeekSat => '六';

  @override
  String get chatHistoryWeekSun => '日';

  @override
  String get chatHistoryAllLoaded => '已加载全部聊天记录';

  @override
  String get chatHistorySenderMe => '我';

  @override
  String get chatHistorySenderPeer => '对方';

  @override
  String get chatHistorySearchFieldHint => '输入关键词，点右侧搜索（近 90 天）';

  @override
  String get chatHistorySearchScopeNote => '输入关键词后点击搜索；仅检索近 90 天内文本';

  @override
  String get chatHistorySearchNoMatches => '未找到匹配消息';

  @override
  String get chatHistorySearchAllResultsShown => '已显示全部检索结果';

  @override
  String get chatHistoryEmptyFiles => '暂无文件';

  @override
  String get chatHistoryEmptyImages => '暂无图片';

  @override
  String get chatHistoryEmptyVideos => '暂无视频';

  @override
  String chatHistoryMonthLabel(int year, int month) {
    return '$year年$month月';
  }

  @override
  String get chatHistoryFileUnnamed => '文件';

  @override
  String get chatHistoryEmojiPlaceholder => '[表情]';

  @override
  String get contactsNewFriends => '新的朋友';

  @override
  String get friendRequestNotificationTitle => '新的好友申请';

  @override
  String friendRequestNotificationBody(Object id) {
    return '用户 $id 请求添加你为好友';
  }

  @override
  String get friendAcceptedNotificationTitle => '好友申请已通过';

  @override
  String friendAcceptedNotificationBody(Object id) {
    return '你已与用户 $id 成为好友';
  }

  @override
  String get contactsGroupChatEntry => '群聊';

  @override
  String contactsGroupSectionTitle(int count) {
    return '群聊 ($count)';
  }

  @override
  String get contactsEmptyFriends => '暂无好友';

  @override
  String get contactsFriendRequestsEmpty => '暂无请求';

  @override
  String contactsFriendRequestLine(String name) {
    return '$name 请求加好友';
  }

  @override
  String get contactsFriendRequestReject => '拒绝';

  @override
  String get contactsFriendRequestAccept => '接受';

  @override
  String get friendAcceptAutoGreeting => '你好';

  @override
  String createGroupDefaultName(int count) {
    return '群聊($count)';
  }

  @override
  String get createGroupCreatedPreview => '群聊已创建';

  @override
  String createGroupDoneWithCount(int count) {
    return '完成($count)';
  }

  @override
  String get createGroupNameFieldLabel => '群名称';

  @override
  String get createGroupSearchFriendsHint => '搜索好友';

  @override
  String get pointsMyPoints => '我的积分';

  @override
  String get pointsLoadFailed => '加载失败';

  @override
  String get pointsCardFootnote => '积分可参与活动与兑换（以平台规则为准）';

  @override
  String get pointsViewLedger => '查看明细';

  @override
  String get pointsCoupons => '优惠券';

  @override
  String pointsCouponsBadgeCount(int count) {
    return '$count 张';
  }

  @override
  String get pointsLedgerTitle => '积分明细';

  @override
  String get pointsCurrentTotal => '当前总积分';

  @override
  String get pointsFilterAll => '全部';

  @override
  String get pointsFilterCredit => '收入';

  @override
  String get pointsFilterDebit => '支出';

  @override
  String get pointsRetry => '重试';

  @override
  String get pointsLedgerEmpty => '暂无明细';

  @override
  String get pointsLedgerEnd => '已展示全部记录';

  @override
  String get pointsReasonCreditDefault => '积分收入';

  @override
  String get pointsReasonDebitDefault => '积分支出';

  @override
  String pointsBalanceAfter(int balance) {
    return '余 $balance';
  }

  @override
  String get coinDefaultName => '代币';

  @override
  String get coinCardFootnote => '代币可用于平台内消费与抵扣（以平台规则为准）';

  @override
  String get coinViewLedger => '查看明细';

  @override
  String get coinLedgerTitle => '代币明细';

  @override
  String get coinCurrentTotal => '当前代币余额';

  @override
  String get coinReasonCreditDefault => '代币收入';

  @override
  String get coinReasonDebitDefault => '代币支出';

  @override
  String coinBalanceAfter(int balance) {
    return '余 $balance';
  }

  @override
  String get servicesEmptyList => '暂无服务';

  @override
  String get servicesSearchHint => '搜索小程序';

  @override
  String get servicesSearchEmpty => '未找到相关服务';

  @override
  String get servicesPinnedTitle => '固定快捷入口';

  @override
  String get servicesPin => '固定';

  @override
  String get servicesUnpin => '取消固定';

  @override
  String get servicesPinnedReorderHint => '长按拖动排序';

  @override
  String get servicesUnnamedItem => '未命名';

  @override
  String get servicesMoreTitle => '更多服务';

  @override
  String get servicesWalletCompanyName => 'A380';

  @override
  String get servicesWalletA380Coin => 'A380币';

  @override
  String get servicesWalletPoints => '积分';

  @override
  String get servicesPointsBalance => '积分余额';

  @override
  String get servicesHotel => '酒店';

  @override
  String get servicesKtv => 'KTV';

  @override
  String get servicesKtvBusiness => 'KTV 业务';

  @override
  String get servicesBar => '酒吧';

  @override
  String get servicesBilliards => '台球厅';

  @override
  String get servicesFood => '美食';

  @override
  String get servicesDelivery => '外卖';

  @override
  String get servicesFlashSale => '闪购';

  @override
  String get servicesBoutique => '精品店';

  @override
  String get servicesMassage => '足浴';

  @override
  String get servicesFlights => '机票';

  @override
  String get servicesTaxi => '打车';

  @override
  String get servicesComingSoon => '功能更新中，敬请期待';

  @override
  String serviceDemoSearchHint(String service) {
    return '搜索$service';
  }

  @override
  String serviceDemoHeroTitle(String service) {
    return '精选$service';
  }

  @override
  String get serviceDemoHeroSubtitle => '热门服务一站式发现，快速确认更省心';

  @override
  String serviceDemoFeaturedItem(String service) {
    return '$service精选推荐';
  }

  @override
  String serviceDemoPopularItem(String service) {
    return '$service人气榜';
  }

  @override
  String serviceDemoValueItem(String service) {
    return '$service超值套餐';
  }

  @override
  String serviceDemoNearbyItem(String service) {
    return '附近优选$service';
  }

  @override
  String get serviceDemoQualityDescription => '品质保障 · 随时可退';

  @override
  String get serviceDemoFastDescription => '本地热门 · 快速确认';

  @override
  String get serviceDemoFilterRecommended => '推荐';

  @override
  String get serviceDemoFilterNearby => '附近';

  @override
  String get serviceDemoFilterTopRated => '好评优先';

  @override
  String get serviceDemoMockNotice => '当前为本地演示，操作不会产生真实订单或费用';

  @override
  String get serviceDemoNoResults => '没有找到相关服务';

  @override
  String serviceDemoRating(String rating) {
    return '$rating 分';
  }

  @override
  String serviceDemoSold(int count) {
    return '已售 $count';
  }

  @override
  String get serviceDemoFree => '免费';

  @override
  String serviceDemoCouponAmount(String amount) {
    return '¥$amount';
  }

  @override
  String get serviceDemoAction => '立即体验';

  @override
  String get serviceDemoClaim => '领取';

  @override
  String get serviceDemoDone => '已完成';

  @override
  String get serviceDemoConfirmTitle => '确认体验';

  @override
  String serviceDemoConfirmBody(String item) {
    return '确认提交“$item”演示订单？';
  }

  @override
  String get serviceDemoConfirm => '确认提交';

  @override
  String serviceDemoSuccess(String item) {
    return '“$item”操作成功';
  }

  @override
  String get serviceDemoMyOrders => '我的演示订单';

  @override
  String get serviceDemoMyCoupons => '我的优惠券';

  @override
  String get serviceDemoEmptyOrders => '暂无记录，先去体验一下吧';

  @override
  String get serviceDemoCouponNewUser => '新人专享券';

  @override
  String get serviceDemoCouponDining => '餐饮通用券';

  @override
  String get serviceDemoCouponTravel => '出行优惠券';

  @override
  String get serviceDemoCouponNoThreshold => '无门槛 · 全场可用';

  @override
  String serviceDemoCouponThreshold(String amount) {
    return '满 $amount 可用';
  }

  @override
  String serviceVenueSearchHint(String service) {
    return '搜索$service商家';
  }

  @override
  String get serviceVenueSmartSort => '智能排序';

  @override
  String get serviceVenueFilter => '筛选';

  @override
  String get serviceVenueFeaturedMerchant => '精选商家';

  @override
  String get serviceVenueCleanTag => '环境舒适';

  @override
  String serviceVenueDistance(String distance) {
    return '${distance}km';
  }

  @override
  String serviceVenueReviews(int count) {
    return '$count 条评价';
  }

  @override
  String get serviceVenueOpen => '营业中';

  @override
  String get serviceVenueOpenAllDay => '全天营业 · 到店直接使用';

  @override
  String get serviceVenueAddress => '门店地址';

  @override
  String serviceVenueDealsTitle(int count) {
    return '优惠套餐（$count）';
  }

  @override
  String get serviceBookingHotelOptionsTitle => '房型与价格';

  @override
  String get serviceBookingKtvOptionsTitle => '套餐与价格';

  @override
  String get serviceBookingHotelOptionLabel => '房型';

  @override
  String get serviceBookingKtvOptionLabel => '套餐';

  @override
  String serviceBookingPrice(int price) {
    return '¥$price';
  }

  @override
  String serviceBookingCashPrice(int price) {
    return '现金 ¥$price';
  }

  @override
  String serviceBookingPointsPrice(int points) {
    return '$points 积分兑换';
  }

  @override
  String get serviceBookingPayment => '预约方式';

  @override
  String get serviceBookingHotelTimeLabel => '入住时间';

  @override
  String get serviceBookingKtvTimeLabel => '到场时间';

  @override
  String get serviceBookingChooseTime => '选择日期和时间';

  @override
  String get serviceBookingReserve => '立即预约';

  @override
  String get serviceBookingMockNotice => '当前为本地预约演示，不会生成真实订单、扣除积分或产生费用';

  @override
  String get serviceBookingSuccessTitle => '预约成功';

  @override
  String get serviceBookingSuccessBody => '预约信息已确认，请按选择的时间到店。';

  @override
  String get serviceVenueBuyNow => '抢购';

  @override
  String get serviceVenueHotDeal => '热门套餐';

  @override
  String get serviceVenueRefundAnytime => '随时退';

  @override
  String get serviceVenueValidAnytime => '过期退';

  @override
  String get serviceVenueDealDetailTitle => '套餐详情';

  @override
  String get serviceVenuePackageDetails => '套餐详情';

  @override
  String get serviceVenueDuration => '体验时长';

  @override
  String get serviceVenueDurationValue => '2 小时';

  @override
  String get serviceVenueRoomType => '空间类型';

  @override
  String get serviceVenueRoomTypeValue => '大厅 / 卡座';

  @override
  String get serviceVenueApplicable => '适用范围';

  @override
  String get serviceVenueApplicableValue => '全场通用';

  @override
  String get serviceVenueAdditionalInfo => '补充说明';

  @override
  String get serviceVenueAdditionalInfoBody =>
      '无需预约，营业时间内到店出示 mock 订单即可体验。单次订单限使用一份。';

  @override
  String get serviceVenueOrderNow => '立即下单';

  @override
  String get serviceVenueCheckoutTitle => '提交订单';

  @override
  String get serviceVenueQuantity => '购买数量';

  @override
  String get serviceVenueDecreaseQuantity => '减少数量';

  @override
  String get serviceVenueIncreaseQuantity => '增加数量';

  @override
  String get serviceVenueTotal => '合计';

  @override
  String get serviceVenueDiscount => '优惠';

  @override
  String get serviceVenueFullDiscount => '全额优惠';

  @override
  String get serviceVenuePurchaseNotice => '购买须知';

  @override
  String get serviceVenuePurchaseNoticeBody =>
      '本页面为本地 mock 演示，不会发起支付或产生真实费用。提交后直接生成成功状态。';

  @override
  String get serviceVenueFreeOrderAction => '免费下单';

  @override
  String get serviceVenueOrderSuccessTitle => '下单成功';

  @override
  String get serviceVenueOrderSuccessBody => '演示订单已生成，可返回列表继续体验其他门店。';

  @override
  String get serviceVenueOrderVenue => '门店';

  @override
  String get serviceVenueOrderItem => '套餐';

  @override
  String get serviceVenueOrderNumber => '订单号';

  @override
  String get serviceVenueBackToList => '返回门店列表';

  @override
  String get serviceVenueBarName1 => '暮色回廊酒吧';

  @override
  String get serviceVenueBarName2 => '蓝调十三号';

  @override
  String get serviceVenueBarName3 => '云端露台酒馆';

  @override
  String get serviceVenueBarName4 => '城市微醺研究所';

  @override
  String get serviceVenuePoolName1 => '星空里台球俱乐部';

  @override
  String get serviceVenuePoolName2 => '破晓桌球空间';

  @override
  String get serviceVenuePoolName3 => '黑八公馆';

  @override
  String get serviceVenuePoolName4 => '璀璨台球会所';

  @override
  String get serviceVenueHotelName1 => '云栖精选酒店';

  @override
  String get serviceVenueHotelName2 => '星河国际酒店';

  @override
  String get serviceVenueHotelName3 => '滨江悦居酒店';

  @override
  String get serviceVenueHotelName4 => '城市之光酒店';

  @override
  String get serviceVenueKtvName1 => '魅力金座 KTV';

  @override
  String get serviceVenueKtvName2 => '星聚会欢唱空间';

  @override
  String get serviceVenueKtvName3 => '麦浪派对 KTV';

  @override
  String get serviceVenueKtvName4 => '云端量贩 KTV';

  @override
  String get serviceVenueAddress1 => '星河广场 B 区 2 层';

  @override
  String get serviceVenueAddress2 => '滨江路 88 号创意园内';

  @override
  String get serviceVenueAddress3 => '中央商务区云端中心 5 层';

  @override
  String get serviceVenueAddress4 => '青年街 19 号潮流街区';

  @override
  String get serviceVenueDescription1 => '环境精致，氛围轻松，适合朋友聚会';

  @override
  String get serviceVenueDescription2 => '设备齐全，空间宽敞，服务热情';

  @override
  String get serviceVenueDescription3 => '城市景观出片，热门时段也很舒适';

  @override
  String get serviceVenueDescription4 => '新店开业，装修时尚，交通便利';

  @override
  String get serviceVenueBarDeal1 => '双人微醺畅饮体验';

  @override
  String get serviceVenueBarDeal2 => '夜间精选特调套餐';

  @override
  String get serviceVenueBarDeal3 => '露台音乐派对体验';

  @override
  String get serviceVenueFootBathDeal1 => '足浴养生舒缓套餐';

  @override
  String get serviceVenueFootBathDeal2 => '足浴加钟放松套餐';

  @override
  String get serviceVenueFootBathDeal3 => '双人足浴休闲套餐';

  @override
  String get serviceVenuePoolDeal1 => '全天通用畅打 2 小时';

  @override
  String get serviceVenuePoolDeal2 => '白天特惠中式台球体验';

  @override
  String get serviceVenuePoolDeal3 => '周末好友桌球套餐';

  @override
  String get serviceVenueHotelOption1 => '雅致大床房';

  @override
  String get serviceVenueHotelOption2 => '豪华双床房';

  @override
  String get serviceVenueHotelOption3 => '行政景观套房';

  @override
  String get serviceVenueKtvOption1 => '双人欢唱套餐';

  @override
  String get serviceVenueKtvOption2 => '好友聚会套餐';

  @override
  String get serviceVenueKtvOption3 => '派对畅唱套餐';

  @override
  String get serviceVenueDealSubtitle1 => '免预约 · 全时段可用';

  @override
  String get serviceVenueDealSubtitle2 => '热门推荐 · 到店快速确认';

  @override
  String get profileEditChangeAvatar => '更换头像';

  @override
  String get profileEditTakePhoto => '拍照';

  @override
  String get profileEditChooseFromGallery => '从相册选择';

  @override
  String get profileFieldNickname => '昵称';

  @override
  String get profileFieldRequiredHint => '必填';

  @override
  String get profileFieldPhone => '手机号';

  @override
  String get profileFieldOptionalHint => '可留空';

  @override
  String get profileFieldEmail => '邮箱';

  @override
  String get profileFieldSignature => '个性签名';

  @override
  String get profileFieldSignatureHint => '写点什么...';

  @override
  String get pointsAccountEntryTitle => '积分账号';

  @override
  String get pointsAccountNotBound => '未绑定';

  @override
  String get pointsAccountBindingTitle => '绑定积分账号';

  @override
  String get pointsAccountVerificationTitle => '安全验证';

  @override
  String get pointsAccountStepAccount => '第 1 步';

  @override
  String get pointsAccountStepVerify => '验证身份';

  @override
  String get pointsAccountChooseHeading => '选择账号类型';

  @override
  String get pointsAccountChooseDescription => '请选择积分账号的登录方式，并填写对应账号。';

  @override
  String get pointsAccountReplaceHeading => '更换积分账号';

  @override
  String get pointsAccountReplaceDescription => '验证新的积分账号后，将替换当前绑定。';

  @override
  String get pointsAccountTypePhone => '手机号';

  @override
  String get pointsAccountTypeEmail => '邮箱';

  @override
  String get pointsAccountTypeAccount => '会员号';

  @override
  String get pointsAccountPhoneHint => '请输入手机号';

  @override
  String get pointsAccountEmailHint => '请输入邮箱地址';

  @override
  String get pointsAccountUsernameHint => '请输入会员号';

  @override
  String get pointsAccountPhoneInvalid => '请输入 6–15 位有效手机号';

  @override
  String get pointsAccountEmailInvalid => '请输入有效的邮箱地址';

  @override
  String get pointsAccountUsernameInvalid => '请输入 6–24 位字母或数字会员号';

  @override
  String get pointsAccountCodeToPhone => '验证码将发送到该手机号';

  @override
  String get pointsAccountCodeToEmail => '验证码将发送到该邮箱';

  @override
  String get pointsAccountCodeToSecurityContact => '验证码将发送到账号绑定的安全联系方式';

  @override
  String get pointsAccountPrivacyNote => '积分账号仅用于积分查询、累计与兑换，不会公开显示完整账号信息。';

  @override
  String get pointsAccountRequestCode => '获取验证码';

  @override
  String get pointsAccountCodeSent => '验证码已发送';

  @override
  String get pointsAccountCodeResent => '新的验证码已发送';

  @override
  String get pointsAccountEnterCode => '输入验证码';

  @override
  String get pointsAccountCodeSentTo => '6 位验证码已发送至';

  @override
  String get pointsAccountCodeFieldLabel => '六位验证码';

  @override
  String get pointsAccountCodeExpiryHint => '请在有效期内完成验证';

  @override
  String get pointsAccountCodeInvalid => '验证码错误，请重新输入';

  @override
  String get pointsAccountResendCode => '重新发送';

  @override
  String pointsAccountResendCountdown(int seconds) {
    return '${seconds}s 后重发';
  }

  @override
  String get pointsAccountDemoCodeLabel => '设计稿演示验证码：';

  @override
  String get pointsAccountConfirmBinding => '确认绑定';

  @override
  String get pointsAccountBindSuccess => '积分账号绑定成功';

  @override
  String get pointsAccountBindSuccessDescription => '已完成安全验证，积分服务现在可以使用。';

  @override
  String get pointsAccountReturnToProfile => '返回个人信息';

  @override
  String get pointsAccountSelectCountry => '选择国家/地区';

  @override
  String get pointsAccountSearchCountry => '搜索国家/地区或区号';

  @override
  String get pointsAccountNoCountryResults => '没有找到匹配的国家/地区';

  @override
  String pointsAccountPhoneInvalidForCountry(String country, String lengths) {
    return '请输入有效的$country手机号（$lengths位数字）';
  }

  @override
  String get pointsAccountEnterPassword => '输入密码';

  @override
  String get pointsAccountPasswordNextHint => '下一步将验证会员号登录密码';

  @override
  String get pointsAccountPasswordVerificationTitle => '密码验证';

  @override
  String get pointsAccountPasswordHeading => '输入密码验证';

  @override
  String pointsAccountPasswordDescription(String account) {
    return '请输入会员号 $account 对应的登录密码';
  }

  @override
  String get pointsAccountPasswordHint => '请输入会员号登录密码';

  @override
  String get pointsAccountPasswordInvalid => '密码错误，请重新输入';

  @override
  String get pointsAccountDemoPasswordLabel => '设计稿演示密码：';

  @override
  String get passwordShowTooltip => '显示密码';

  @override
  String get passwordHideTooltip => '隐藏密码';

  @override
  String get changePasswordCurrentLabel => '当前密码';

  @override
  String get changePasswordNewLabel => '新密码（至少 6 位）';

  @override
  String get changePasswordConfirmLabel => '确认新密码';

  @override
  String get changePasswordSubmit => '确认修改';

  @override
  String get formLabelUsername => '用户名';

  @override
  String get formLabelPassword => '密码';

  @override
  String get registerNicknameOptional => '昵称（可选）';

  @override
  String get registerSubmitting => '注册中...';

  @override
  String get avatarCropTitle => '裁剪头像';

  @override
  String get avatarCropStickerTitle => '裁剪表情';

  @override
  String get avatarCropDone => '完成';

  @override
  String get avatarCropMissingData => '缺少图片数据';

  @override
  String get recentMiniProgramsTitle => '最近使用的小程序';

  @override
  String get recentMiniProgramsEmpty => '暂无最近使用';

  @override
  String get commonClose => '关闭';

  @override
  String get commonSaveImage => '保存图片';

  @override
  String get commonSaveVideo => '保存视频';

  @override
  String get miniProgramQrCodeTitle => '小程序码';

  @override
  String get chatEmojiTab => '表情';

  @override
  String get chatStickerPackTab => '表情包';

  @override
  String get chatStickerRecentTab => '最近';

  @override
  String get chatMoreImage => '图片';

  @override
  String get chatMoreTakePhoto => '拍照';

  @override
  String get chatMoreCamera => '拍摄';

  @override
  String get chatMoreCameraHint => '点击进入拍摄，轻触快门拍照，长按快门录像';

  @override
  String get chatCameraShutterHint => '轻触拍照，长按录像';

  @override
  String get chatCameraRecordingHint => '松开结束录像';

  @override
  String get chatCameraInitializing => '正在打开相机…';

  @override
  String get chatCameraUnavailable => '无法使用相机，请检查相机和麦克风权限';

  @override
  String get chatCameraSwitchFlash => '切换闪光灯';

  @override
  String get chatMoreVideo => '视频';

  @override
  String get chatMoreRecordVideo => '拍视频';

  @override
  String get chatMoreFile => '文件';

  @override
  String get chatMoreLocation => '位置';

  @override
  String get chatMoreVoiceCall => '语音通话';

  @override
  String get chatMoreVideoCall => '视频通话';

  @override
  String chatReplyTo(String who) {
    return '回复 $who';
  }

  @override
  String get chatReplySelfShort => '我';

  @override
  String get chatReplyPeerShort => '对方';

  @override
  String get chatDismissReplySemantics => '关闭回复';

  @override
  String chatStickerCountShort(int count) {
    return '$count 个';
  }

  @override
  String get chatStickerManage => '管理';

  @override
  String get chatStickerDoneEditing => '完成';

  @override
  String get chatStickerMyEmptyHint => '点击右下角 + 从相册添加，或长按聊天中的表情添加';

  @override
  String get chatStickerEmptyList => '暂无表情';

  @override
  String get chatSemanticEmojiPicker => '表情';

  @override
  String get imageViewerActualSizeTooltip => '原始大小';

  @override
  String get chatVoiceCancelLabel => '取消';

  @override
  String get chatVoiceReleaseToCancel => '松开手指，取消发送';

  @override
  String get chatVoiceReleaseToSend => '松开发送，上移取消';

  @override
  String get chatAddToStickers => '添加到表情';

  @override
  String get chatStickerAddedToMine => '已添加到我的表情';

  @override
  String get chatStickerAddFailed => '添加失败';

  @override
  String get chatRecallConfirmBody => '确定撤回这条消息吗？';

  @override
  String get chatDeleteMsgSendingBody => '该消息仍在发送中，将仅从本机移除。确定？';

  @override
  String get chatDeleteMsgPrivateBody =>
      '删除将移除服务端记录及双方设备上的这条消息；对方已阅读、复制、转发、截图、下载或保存到本地的内容无法撤销。确定删除？';

  @override
  String get chatDeleteMsgGroupBody =>
      '删除将移除服务端记录及群成员设备上的这条消息；成员已阅读、复制、转发、截图、下载或保存到本地的内容无法撤销。确定删除？';

  @override
  String get chatDeleteMsgSecretBody =>
      '私密聊天消息采用端到端加密，删除后仅本机不可见，对方设备上的消息不受影响。确定删除？';

  @override
  String get callTraceFallback => '[通话]';

  @override
  String callTraceVideoCompleted(String duration) {
    return '通话时长 $duration';
  }

  @override
  String callTraceAudioCompleted(String duration) {
    return '通话时长 $duration';
  }

  @override
  String get callTraceVideoCancelled => '视频通话 已取消';

  @override
  String get callTraceAudioCancelled => '语音通话 已取消';

  @override
  String get callTraceVideoRejected => '视频通话 已拒绝';

  @override
  String get callTraceAudioRejected => '语音通话 已拒绝';

  @override
  String get callTraceVideoBusy => '视频通话 忙线中';

  @override
  String get callTraceAudioBusy => '语音通话 忙线中';

  @override
  String get callTraceVideoFailed => '视频通话 未接通';

  @override
  String get callTraceAudioFailed => '语音通话 未接通';

  @override
  String get callTraceResolvedOtherDevice => '来电已在其他设备处理';

  @override
  String get callScreenUnknownRemote => '未知';

  @override
  String get callStatusRinging => '呼叫中…';

  @override
  String get callStatusWaitingForAnswer => '等待对方接受邀请…';

  @override
  String get callStatusIncoming => '来电…';

  @override
  String get callStatusConnecting => '连接中…';

  @override
  String get callStatusInCall => '通话中';

  @override
  String get callErrorMediaPermission => '无法访问摄像头/麦克风，请检查系统权限后重试。';

  @override
  String get callErrorMediaNeedsHttps =>
      '当前非 HTTPS 环境，浏览器无法授权摄像头/麦克风。请使用 https:// 或 localhost 访问。';

  @override
  String get callErrorSocketForCall => '未连接到通话服务，请检查网络或稍后再试。';

  @override
  String get callErrorAcceptFailed => '接听失败，请重试';

  @override
  String get callErrorTimeout => '连接超时，对方可能未接听';

  @override
  String get callActionBack => '返回';

  @override
  String get callActionAnswer => '接听';

  @override
  String get callActionReject => '拒绝';

  @override
  String get callActionMute => '静音';

  @override
  String get callActionUnmute => '取消静音';

  @override
  String get callActionMicrophoneOn => '麦克风已开';

  @override
  String get callActionMicrophoneOff => '麦克风已关';

  @override
  String get callActionSpeakerOn => '扬声器已开';

  @override
  String get callActionSpeakerOff => '扬声器已关';

  @override
  String get callActionSwitchCamera => '切换镜头';

  @override
  String get callActionCameraOn => '开启摄像头';

  @override
  String get callActionCameraOff => '关闭摄像头';

  @override
  String get callActionCameraEnabled => '摄像头已开';

  @override
  String get callActionCameraDisabled => '摄像头已关';

  @override
  String get callActionCancel => '取消';

  @override
  String get callActionHangUp => '挂断';

  @override
  String get callActionMinimize => '最小化通话';

  @override
  String get callActionReturnToCall => '返回通话';

  @override
  String get callActionBackgroundBlurEnabled => '背景虚化已开';

  @override
  String get callActionBackgroundBlurDisabled => '背景虚化已关';

  @override
  String get callActionBackgroundBlurSettings => '背景虚化设置';

  @override
  String get callErrorBackgroundBlurUnavailable => '当前设备暂时无法启用背景虚化';

  @override
  String get forwardMessageTitle => '转发给好友';

  @override
  String get forwardMessageAction => '转发';

  @override
  String get recommendContactTitle => '推荐给好友';

  @override
  String get recommendContactAction => '发送';

  @override
  String get friendsEmpty => '暂无好友';

  @override
  String get friendsNoMatches => '无匹配好友';

  @override
  String get chatAnnouncementTitle => '公告';

  @override
  String get chatListEmpty => '暂无消息';

  @override
  String get chatPinConversation => '置顶';

  @override
  String get chatUnpinConversation => '取消置顶';

  @override
  String get commonDelete => '删除';

  @override
  String chatGroupDefaultTitle(String id) {
    return '群聊 $id';
  }

  @override
  String chatUserDefaultTitle(String id) {
    return '用户 $id';
  }

  @override
  String chatMentionGroupNickname(String nickname) {
    return '群昵称：$nickname';
  }

  @override
  String get chatMentionGroupNicknameEmpty => '群昵称：无';

  @override
  String get chatTypingPeer => '对方正在输入...';

  @override
  String get chatActionCopy => '复制';

  @override
  String get chatMediaCopied => '媒体已复制';

  @override
  String get chatMediaCopyFailed => '媒体复制失败';

  @override
  String get chatActionReply => '回复';

  @override
  String get chatActionForward => '转发';

  @override
  String get chatActionRecall => '撤回';

  @override
  String get chatNewMessage => '新消息';

  @override
  String get chatStickerPreview => '[表情包]';

  @override
  String get chatMessageRecalledSelf => '你撤回了一条消息';

  @override
  String get chatMessageRecalledPeer => '对方撤回了一条消息';

  @override
  String get chatSending => '发送中...';

  @override
  String get chatVoiceMessage => '语音消息';

  @override
  String get chatTapToDownload => '点击下载';

  @override
  String get chatNameCard => '名片';

  @override
  String get chatPersonalNameCard => '个人名片';

  @override
  String get composerKeyboardInput => '键盘输入';

  @override
  String get composerVoiceInput => '语音输入';

  @override
  String get commonMore => '更多';

  @override
  String get chatImageCaptionTitle => '发送图片';

  @override
  String get chatImageCaptionHint => '添加备注（可选，最多200字）';

  @override
  String get chatClipboardImageReadFailed => '无法读取剪贴板中的图片';

  @override
  String get commonSend => '发送';

  @override
  String get reservationTitle => '预约服务';

  @override
  String get reservationEntrySubtitle => '酒店、KTV 等到店服务在线预约';

  @override
  String get reservationMine => '我的预约';

  @override
  String get reservationMineSubtitle => '查看待核销和已完成的预约';

  @override
  String get reservationChooseService => '选择预约类型';

  @override
  String get reservationNoServices => '暂无可预约服务';

  @override
  String get reservationNoStores => '当前类型暂无可预约门店';

  @override
  String reservationCreateTitle(String service) {
    return '预约$service';
  }

  @override
  String get reservationStoreLabel => '预约门店';

  @override
  String get reservationStoreAddress => '门店地址';

  @override
  String get reservationServiceTypeLabel => '服务类型';

  @override
  String get reservationContactNameLabel => '联系人姓名';

  @override
  String get reservationPhoneLabel => '联系电话';

  @override
  String get reservationDateLabel => '预约日期';

  @override
  String get reservationTimeLabel => '预约时段';

  @override
  String get reservationPersonNumLabel => '预约人数';

  @override
  String reservationPersonNumValue(int count) {
    return '$count 人';
  }

  @override
  String get reservationDecreasePerson => '减少人数';

  @override
  String get reservationIncreasePerson => '增加人数';

  @override
  String get reservationRemarkLabel => '备注（房型、包厢或其他需求）';

  @override
  String get reservationSubmit => '提交预约';

  @override
  String get reservationSubmitHint => '提交预约不会扣除积分，核销时按实际消费结算';

  @override
  String get reservationSelectStoreError => '请选择预约门店';

  @override
  String get reservationContactNameError => '请输入 1-32 个字符的联系人姓名';

  @override
  String get reservationPhoneError => '请输入不超过 30 位的有效联系电话';

  @override
  String get reservationRemarkError => '备注不能超过 512 个字符';

  @override
  String get reservationCreatedSuccess => '预约成功，门店将线下核对服务';

  @override
  String get reservationPending => '待核销';

  @override
  String get reservationVerified => '已核销';

  @override
  String get reservationEmpty => '暂无预约记录';

  @override
  String reservationPointsDeducted(int points) {
    return '抵扣 $points 积分';
  }

  @override
  String get reservationDetailTitle => '预约详情';

  @override
  String get reservationPendingHint => '请按预约时间到店，门店服务完成后核销';

  @override
  String get reservationVerifiedHint => '本次预约已完成核销';

  @override
  String get reservationServiceInfo => '预约信息';

  @override
  String get reservationContactInfo => '联系信息';

  @override
  String get reservationSettlementInfo => '结算信息';

  @override
  String get reservationOrderInfo => '订单信息';

  @override
  String get reservationConsumeAmount => '消费金额';

  @override
  String get reservationVerifyTime => '核销时间';

  @override
  String get reservationPointAmount => '积分抵扣';

  @override
  String get reservationPointDeductFailed => '积分抵扣失败，请联系服务人员';

  @override
  String get reservationOrderNo => '预约单号';

  @override
  String get reservationCreatedAt => '提交时间';

  @override
  String reservationCurrency(String amount) {
    return '¥$amount';
  }

  @override
  String get channelComposerReadOnlyHint => '仅管理员可发布';

  @override
  String get groupDissolvedComposerReadOnlyHint => '群聊已解散，不能继续发消息';

  @override
  String get channelCreateConfirm => '创建';

  @override
  String get channelCreateTitle => '创建频道';

  @override
  String get channelInfoHint => '频道为单向广播：仅管理员可发布，订阅者可阅读并接收通知。';

  @override
  String get channelSearchTitle => '搜索频道';

  @override
  String get channelSearchHint => '输入频道名称或频道号搜索';

  @override
  String get channelSearchEmptyHint => '输入频道名称，回车搜索';

  @override
  String get channelSearchNoResult => '没有找到相关频道';

  @override
  String get channelJoinByCodeTitle => '输入频道号订阅';

  @override
  String get channelJoinByCodeHint => '输入频道号（如 cABC2345）';

  @override
  String get channelJoinConfirm => '订阅';

  @override
  String get channelJoined => '已订阅';

  @override
  String get channelInfoHintShort => '频道';

  @override
  String get channelShareTitle => '分享频道';

  @override
  String get channelShareCodeLabel => '频道号';

  @override
  String get channelShareLinkLabel => '频道链接';

  @override
  String get channelQrCodeTitle => '频道二维码';

  @override
  String get channelQrCodeHint => '打开 App 扫一扫，即可订阅频道';

  @override
  String get channelShareToChat => '转发到聊天';

  @override
  String get channelShareSectionFriends => '好友';

  @override
  String get channelShareSectionGroups => '群聊';

  @override
  String get channelShareSectionChannels => '频道';

  @override
  String get channelShareSearchHint => '搜索';

  @override
  String get channelShareEmpty => '暂无可分享的聊天';

  @override
  String get channelShareNoMatch => '没有匹配的聊天';

  @override
  String get shareMediaTitle => '发送给';

  @override
  String get channelUnsubscribeAction => '取消订阅';

  @override
  String get channelUnsubscribeConfirmTitle => '取消订阅';

  @override
  String get channelUnsubscribeConfirmBody => '取消订阅后将不再接收该频道的消息，确定取消吗？';

  @override
  String get channelEditAction => '编辑频道';

  @override
  String get channelEditNameLabel => '频道名称';

  @override
  String get channelEditAnnouncementLabel => '频道公告';

  @override
  String get channelEditAnnouncementHint => '填写频道公告（可留空）';

  @override
  String get channelDeleteAction => '删除频道';

  @override
  String get channelDeleteConfirmTitle => '删除频道';

  @override
  String get channelDeleteConfirmBody => '删除后所有订阅者将无法访问该频道，且不可恢复。确定删除吗？';

  @override
  String get toastChannelShareCopied => '已复制，快去分享吧';

  @override
  String get toastChannelNotFound => '频道不存在或已被解散';

  @override
  String get toastChannelUpdated => '频道已更新';

  @override
  String get toastChannelDeleted => '频道已删除';

  @override
  String get toastChannelUnsubscribed => '已取消订阅';

  @override
  String get toastEnterChannelName => '请输入频道名称';

  @override
  String channelMemberCount(int count) {
    return '$count 位成员';
  }

  @override
  String get channelNameHint => '频道名称';

  @override
  String get channelRoleOwner => '频道管理员';

  @override
  String get channelRoleSubscriber => '订阅者';

  @override
  String get channelSubtitle => '仅管理员可发布';

  @override
  String chatChannelDefaultTitle(String id) {
    return '频道 $id';
  }

  @override
  String chatSecretDefaultTitle(String id) {
    return '私密聊天 $id';
  }

  @override
  String get convTypeChannel => '频道';

  @override
  String get convTypeGroup => '群组';

  @override
  String get convTypePrivate => '云端单聊';

  @override
  String get convTypeSecret => '私密聊天';

  @override
  String get featureChannelDisabled => '频道功能已关闭';

  @override
  String get featureSecretChatDisabled => '私密聊天功能已关闭';

  @override
  String get secretChatBanner => '端到端加密 · 不同步到新设备';

  @override
  String get secretChatRecordingWarning => '检测到录屏，私密聊天内容请勿外传';

  @override
  String get secretChatScreenshotWarning => '检测到截图，私密聊天内容请勿外传';

  @override
  String get secretChatDestroy1d => '1 天';

  @override
  String get secretChatDestroy1h => '1 小时';

  @override
  String get secretChatDestroy1m => '1 分钟';

  @override
  String get secretChatDestroy1s => '1 秒';

  @override
  String get secretChatDestroy1w => '1 周';

  @override
  String get secretChatDestroy2s => '2 秒';

  @override
  String get secretChatDestroy30s => '30 秒';

  @override
  String get secretChatDestroy5m => '5 分钟';

  @override
  String get secretChatDestroy5s => '5 秒';

  @override
  String get secretChatDestroy10s => '10 秒';

  @override
  String get secretChatDestroyOff => '关闭';

  @override
  String get secretChatDestroyTitle => '定时销毁';

  @override
  String get secretChatNoSyncHint => '私密聊天仅参与设备可见，不会同步到新登录设备；服务端只转发密文。';

  @override
  String get secretChatSafeCodeIntro => '对比双方设备上的安全码，确认没有中间人攻击。';

  @override
  String get secretChatSafeCodeTitle => '安全码';

  @override
  String get secretChatSafeCodeUnavailable => '等待对方加入后自动生成，用于核验加密安全';

  @override
  String get secretChatSettingsTitle => '私密聊天设置';

  @override
  String get secretChatStartTitle => '发起私密聊天';

  @override
  String get secretChatSubtitle => '端到端加密';

  @override
  String get secretChatDeleteTitle => '删除私密聊天';

  @override
  String get secretChatDeleteBody => '删除后，双方设备都将移除该私密聊天及其全部消息，且不可恢复。';

  @override
  String get convTypeSecretGroup => '私密群聊';

  @override
  String get featureSecretGroupChatDisabled => '私密群聊功能已关闭';

  @override
  String get secretGroupChatBanner => '端到端加密 · 逐成员加密';

  @override
  String get secretGroupChatDefaultTitle => '私密群聊';

  @override
  String get secretGroupChatSettingsTitle => '私密群聊设置';

  @override
  String get secretGroupMembersTitle => '成员';

  @override
  String get secretGroupChatStartTitle => '发起私密群聊';

  @override
  String get secretGroupChatSubtitle => '端到端加密 · 逐成员加密';

  @override
  String get secretGroupChatDeleteTitle => '删除私密群聊';

  @override
  String get secretGroupChatDeleteBody => '删除后，本设备将移除该私密群聊；其他成员不受影响。';

  @override
  String get toastSecretGroupChatCreated => '已创建私密群聊';

  @override
  String get toastChannelCreated => '频道已创建';

  @override
  String get toastChannelUnavailable => '频道不可用或已被删除';

  @override
  String get toastSecretChatCreated => '已创建私密聊天';

  @override
  String get toastSecretChatDestroyUpdated => '销毁时间已更新';

  @override
  String get toastSecretChatSafeCodeCopied => '安全码已复制';

  @override
  String get toastSecretChatUnavailable => '私密聊天不可用或已被销毁';

  @override
  String get toastSecretChatWaitingPeer => '等待对方加入后即可发送加密消息';

  @override
  String get selfDestructTitle => '聊天记录自动清理';

  @override
  String get selfDestructOff => '关闭';

  @override
  String get selfDestruct1mo => '1 个月';

  @override
  String get selfDestruct3mo => '3 个月';

  @override
  String get selfDestruct6mo => '6 个月';

  @override
  String get selfDestruct1yr => '1 年';

  @override
  String get selfDestructHint =>
      '开启后，若账号在所选时长内未登录，将自动清除该账号的全部聊天记录。账号本身不会被注销，仍可正常登录。';

  @override
  String get selfDestructUpdated => '聊天记录自动清理策略已更新';

  @override
  String get forgotPassword => '忘记密码？';

  @override
  String get forgotPasswordTitle => '忘记密码';

  @override
  String get forgotPasswordEmailHint => '请输入邮箱';

  @override
  String get forgotPasswordEmailRequired => '请输入邮箱';

  @override
  String get forgotPasswordEmailInvalid => '请输入有效的邮箱地址';

  @override
  String get forgotPasswordSubmit => '发送重置邮件';

  @override
  String get forgotPasswordSent => '邮件已发送';

  @override
  String get resetPasswordTitle => '重置密码';

  @override
  String get resetPasswordTokenHint => '重置令牌';

  @override
  String get resetPasswordTokenRequired => '请输入重置令牌';

  @override
  String get resetPasswordNewPasswordHint => '新密码（6-128 位）';

  @override
  String get resetPasswordPasswordRequired => '新密码需为 6-128 位';

  @override
  String get resetPasswordSubmit => '重置密码';

  @override
  String get resetPasswordDone => '密码已重置，请重新登录';

  @override
  String get chatAtMentionYou => '「@你」';

  @override
  String get chatMuteConversation => '免打扰';

  @override
  String get chatUnmuteConversation => '取消免打扰';

  @override
  String get chatDraftPrefix => '[草稿]';

  @override
  String get chatActionFavorite => '收藏';

  @override
  String get favoritesTitle => '收藏';

  @override
  String get favoritesEmpty => '暂无收藏';

  @override
  String get favoritesLoadFailed => '加载失败';

  @override
  String get favoriteAdded => '已收藏';

  @override
  String get favoriteAddFailed => '收藏失败';

  @override
  String get favoriteRemoved => '已取消收藏';

  @override
  String get favoriteRemovedFailed => '取消收藏失败';

  @override
  String get favoritesDetailTitle => '收藏详情';

  @override
  String get favoritesViewOriginal => '查看原消息';

  @override
  String get favoritesSourceMessageDeleted => '原消息已被删除，只能查看收藏内容';

  @override
  String get favoritesSourceConversationUnavailable => '原会话已不可用，只能查看收藏内容';

  @override
  String get favoritesSourceNoPermission => '你已没有权限查看原消息，只能查看收藏内容';

  @override
  String get favoritesSourceLookupUnavailable => '暂时无法确认原消息是否可查看，请稍后重试';

  @override
  String get favoritesSourceConversationMissing => '无法定位原会话，暂不支持跳转';

  @override
  String get favoritesContentEmpty => '暂无收藏内容（原消息可能已删除）';

  @override
  String get favoritesDetailTime => '时间';

  @override
  String get favoritesFilterAll => '全部';

  @override
  String get favoritesFilterText => '文本';

  @override
  String get favoritesFilterImage => '图片';

  @override
  String get favoritesFilterVideo => '视频';

  @override
  String get favoritesFilterVoice => '语音';

  @override
  String get favoritesFilterFile => '文件';

  @override
  String get favoritesFilterOther => '其他';

  @override
  String get favoritesFilterEmpty => '该类型下暂无收藏';

  @override
  String get favoritesDeleteConfirm => '确定删除该收藏？';

  @override
  String favoritesBatchAdded(int count) {
    return '已收藏 $count 条';
  }

  @override
  String favoritesBatchAddedWithSkipped(int count, int skipped) {
    return '已收藏 $count 条，$skipped 条已收藏过';
  }

  @override
  String get favoritesBatchAlreadySaved => '所选消息都已收藏过';

  @override
  String get favoritesBatchEmpty => '没有可收藏的消息';

  @override
  String get favoritesBatchFailed => '收藏失败';

  @override
  String get reservationChooseStore => '选择门店';

  @override
  String get reservationPackageLabel => '套餐';

  @override
  String get reservationTableTypeLabel => '台位类型';

  @override
  String get reservationExactArrivalTime => '到场时间';

  @override
  String get reservationBarStandingPackage => '散台套餐';

  @override
  String get reservationBarBoothPackage => '卡座套餐';

  @override
  String get reservationBarRoomPackage => '包厢套餐';

  @override
  String get reservationBilliardsStandardPackage => '标准球台套餐';

  @override
  String get reservationBilliardsVipPackage => 'VIP 球台套餐';

  @override
  String get reservationBilliardsRoomPackage => '包厢球台套餐';

  @override
  String get reservationAreaStanding => '散台';

  @override
  String get reservationAreaBooth => '卡座';

  @override
  String get reservationAreaRoom => '包厢';

  @override
  String get reservationAreaStandardTable => '标准球台';

  @override
  String get reservationAreaVipTable => 'VIP 球台';

  @override
  String get travelMockNotice => '当前为前端演示，机场、航班、车辆和价格均为模拟数据';

  @override
  String get travelDomestic => '国内';

  @override
  String get travelInternational => '国际';

  @override
  String get travelRoundTrip => '往返';

  @override
  String get travelMultiCity => '多程';

  @override
  String get travelSpecialFare => '特价';

  @override
  String get travelInstantRide => '即时用车';

  @override
  String get travelAirportPickup => '接机';

  @override
  String get travelAirportDropoff => '送机';

  @override
  String get travelFrom => '出发';

  @override
  String get travelTo => '到达';

  @override
  String get travelSwap => '交换出发和到达地点';

  @override
  String get travelDepartureDate => '出发日期';

  @override
  String get travelPickupTime => '用车时间';

  @override
  String get travelPassengerCabin => '乘机人与舱位';

  @override
  String get travelPassengerCount => '乘车人数';

  @override
  String get travelEconomyCabin => '经济舱 · 1 成人';

  @override
  String get travelOnePassenger => '1 人 · 1 件行李';

  @override
  String get travelSearchFlights => '飞机票查询';

  @override
  String get travelSearchRides => '查询车辆';

  @override
  String get travelSelectAirport => '选择机场';

  @override
  String get travelSelectLocation => '选择地点';

  @override
  String get travelFlightResultsTitle => '航班列表';

  @override
  String get travelTaxiResultsTitle => '可选车辆';

  @override
  String get travelSmartSort => '智能排序';

  @override
  String get travelPriceSort => '价格';

  @override
  String get travelDepartureSort => '出发时间';

  @override
  String get travelRecommended => '推荐';

  @override
  String get travelDirectFlight => '直飞';

  @override
  String get travelTransfer => '中转';

  @override
  String get travelDuration => '飞行时长';

  @override
  String get travelBaggage => '免费托运行李 20KG';

  @override
  String get travelRefundable => '支持退改';

  @override
  String get travelFlightDetails => '航班详情';

  @override
  String get travelRideDetails => '用车详情';

  @override
  String get travelFareOptions => '选择价格方案';

  @override
  String get travelBook => '订';

  @override
  String get travelEstimatedArrival => '预计到达';

  @override
  String get travelVehicleCapacity => '可乘 4 人 · 可放 2 件行李';

  @override
  String get travelIncludes => '费用包含';

  @override
  String get travelDriverService => '专业司机 · 全程一口价 · 含基础等候时间';

  @override
  String get travelFreeCancellation => '出发前 2 小时可免费取消';

  @override
  String get travelFillOrder => '填写订单';

  @override
  String get travelTripSummary => '行程信息';

  @override
  String get travelPassengerInfo => '乘机人信息';

  @override
  String get travelBookerInfo => '预订人信息';

  @override
  String get travelPassengerName => '乘机人姓名';

  @override
  String get travelBookerName => '预订人姓名';

  @override
  String get travelIdNumber => '身份证号码';

  @override
  String get travelPhone => '手机号码';

  @override
  String get travelRemark => '备注（选填）';

  @override
  String get travelNameRequired => '请输入姓名';

  @override
  String get travelIdRequired => '请输入身份证号码';

  @override
  String get travelPhoneRequired => '请输入手机号码';

  @override
  String get travelPhoneInvalid => '请输入正确的手机号码';

  @override
  String get travelSubmitOrder => '提交订单';

  @override
  String get travelOrderSuccessTitle => '提交成功';

  @override
  String get travelOrderSuccessBody => '订单已提交，当前为前端模拟订单，不会产生真实费用';

  @override
  String get travelOrderNumber => '订单编号';

  @override
  String get travelItinerary => '行程';

  @override
  String get travelTraveler => '预订人';

  @override
  String get travelTotal => '合计';

  @override
  String get travelBackServices => '返回更多服务';

  @override
  String get travelShenzhen => '深圳';

  @override
  String get travelChongqing => '重庆';

  @override
  String get travelGuangzhou => '广州';

  @override
  String get travelShanghai => '上海';

  @override
  String get travelShenzhenAirport => '深圳宝安国际机场 T3';

  @override
  String get travelChongqingAirport => '重庆江北国际机场 T3';

  @override
  String get travelGuangzhouAirport => '广州白云国际机场 T2';

  @override
  String get travelShanghaiAirport => '上海虹桥国际机场 T2';

  @override
  String get travelFutianCbd => '福田中心区';

  @override
  String get travelShenzhenNorthStation => '深圳北站';

  @override
  String get travelNanshanSciencePark => '南山科技园';

  @override
  String get travelChinaSouthern => '南方航空';

  @override
  String get travelShenzhenAirlines => '深圳航空';

  @override
  String get travelSpringAirlines => '春秋航空';

  @override
  String get travelXiamenAir => '厦门航空';

  @override
  String get travelEconomyFlexible => '经济舱灵活退改';

  @override
  String get travelEconomyValue => '经济舱特惠';

  @override
  String get travelBusinessCabin => '公务舱';

  @override
  String get travelComfortCar => '舒适型';

  @override
  String get travelBusinessCar => '商务型';

  @override
  String get travelPremiumCar => '豪华型';

  @override
  String get settingsChatStorage => '聊天记录存储空间';

  @override
  String get chatStorageTotalUsed => '本机聊天记录占用';

  @override
  String get chatStorageLocalOnlyNote => '仅删除本机记录，不影响云端';

  @override
  String get chatStorageClear => '清理';

  @override
  String get chatStorageClearAll => '全部清理';

  @override
  String get chatStorageClearAllRecords => '清空全部记录';

  @override
  String get chatStorageClearMediaOnly => '仅清理媒体缓存';

  @override
  String get chatStorageClearRecordsConfirmTitle => '清空全部记录';

  @override
  String get chatStorageClearRecordsConfirmBody =>
      '确定要清空该会话的全部本机记录吗？仅删除本机记录，不影响云端。';

  @override
  String get chatStorageClearAllConfirmTitle => '全部清理';

  @override
  String get chatStorageClearAllConfirmBody =>
      '确定要清空全部本机聊天记录与媒体缓存吗？仅删除本机记录，不影响云端。';

  @override
  String get chatStorageCleared => '已清理';

  @override
  String get chatStorageEmpty => '暂无本地聊天记录';

  @override
  String get settingsChatBackup => '聊天记录备份与迁移';

  @override
  String get chatBackupExportSectionTitle => '备份聊天记录';

  @override
  String get chatBackupExportDesc =>
      '将当前账号全部本地聊天记录导出为 JSON 文件；媒体内容仅记录链接（URL / 对象 ID），不包含二进制文件。';

  @override
  String get chatBackupExportAction => '备份到文件';

  @override
  String get chatBackupExporting => '正在备份…';

  @override
  String get chatBackupExportSuccessTitle => '备份完成';

  @override
  String chatBackupExportSuccessBody(
      int conversations, int messages, String path) {
    return '已备份 $conversations 个会话、$messages 条消息，保存位置：$path';
  }

  @override
  String get chatBackupExportFailed => '备份失败';

  @override
  String get chatBackupExportEmpty => '暂无可备份的本地聊天记录';

  @override
  String get chatBackupRestoreSectionTitle => '恢复聊天记录';

  @override
  String get chatBackupRestoreDesc => '从备份文件恢复，将覆盖合并到本机（相同消息按消息 ID 去重）。';

  @override
  String get chatBackupRestoreAction => '从文件恢复';

  @override
  String get chatBackupRestoreConfirmTitle => '确认恢复';

  @override
  String get chatBackupRestoreConfirmBody =>
      '恢复将覆盖合并本机记录（相同消息按消息 ID 去重），且无法撤销。确定继续吗？';

  @override
  String chatBackupRestoreSuccess(int conversations, int messages) {
    return '恢复完成：$conversations 个会话、$messages 条消息';
  }

  @override
  String get chatBackupRestoreFailed => '恢复失败';

  @override
  String get chatBackupRestoreInvalid => '所选文件不是有效的聊天记录备份';

  @override
  String get gvFaGroupAllowMemberViewAccount => '允许群成员查看他人账号';

  @override
  String get gvFaForgotMethodEmail => '邮箱';

  @override
  String get gvFaForgotMethodPhone => '手机号';

  @override
  String get gvFaForgotMethodSecurityQuestion => '密保问题';

  @override
  String get gvFaForgotPhoneHint => '输入手机号';

  @override
  String get gvFaForgotPhoneRequired => '请输入手机号';

  @override
  String get gvFaForgotPhoneInvalid => '请输入有效的手机号';

  @override
  String get gvFaForgotSendSmsCode => '发送短信验证码';

  @override
  String get gvFaForgotSmsCodeSent => '验证码已发送';

  @override
  String get gvFaResetMethodToken => '重置令牌（邮箱）';

  @override
  String get gvFaResetMethodSms => '短信验证码';

  @override
  String get gvFaResetMethodSecurityQuestion => '密保问题';

  @override
  String get gvFaResetPhoneHint => '手机号';

  @override
  String get gvFaResetPhoneRequired => '请输入手机号';

  @override
  String get gvFaResetSmsCodeHint => '短信验证码';

  @override
  String get gvFaResetSmsCodeRequired => '请输入短信验证码';

  @override
  String get gvFaResetUsernameHint => '用户名';

  @override
  String get gvFaResetUsernameRequired => '请输入用户名';

  @override
  String get gvFaResetSecurityQuestionHint => '密保问题';

  @override
  String get gvFaResetSecurityQuestionRequired => '请输入密保问题';

  @override
  String get gvFaResetSecurityAnswerHint => '密保答案';

  @override
  String get gvFaResetSecurityAnswerRequired => '请输入密保答案';

  @override
  String get gvFaDeviceManagementTitle => '登录设备管理';

  @override
  String get gvFaDeviceManagementEntry => '登录设备管理';

  @override
  String gvFaDeviceLoginMethod(String method) {
    return '登录方式：$method';
  }

  @override
  String gvFaDeviceLoginIp(String ip) {
    return '登录IP：$ip';
  }

  @override
  String gvFaDeviceType(String type) {
    return '设备类型：$type';
  }

  @override
  String gvFaDeviceLastActive(String time) {
    return '最后活跃：$time';
  }

  @override
  String gvFaDeviceStatus(String status) {
    return '状态：$status';
  }

  @override
  String get gvFaDeviceKick => '踢出';

  @override
  String get gvFaDeviceLogout => '退出登录';

  @override
  String get gvFaDeviceKickConfirm => '确定踢出该设备？';

  @override
  String get gvFaDeviceLogoutConfirm => '确定退出该设备登录？';

  @override
  String get gvFaDeviceEmpty => '暂无登录设备';

  @override
  String get gvFaDeviceLoadFailed => '设备列表加载失败';

  @override
  String get gvFaDeviceStatusActive => '在线';

  @override
  String get gvFaDeviceStatusKicked => '已踢出';

  @override
  String get gvFaDeviceStatusLogout => '已退出';

  @override
  String get gvFaLoginMethodPassword => '密码登录';

  @override
  String get gvFaLoginMethodQrCode => '扫码登录';

  @override
  String get gvFaLoginMethodSso => 'SSO';

  @override
  String get gvFaLoginMethodVerificationCode => '短信验证码';

  @override
  String get gvMbEdited => '已编辑';

  @override
  String get gvMbEditAction => '编辑';

  @override
  String get gvMbEditMessage => '编辑消息';

  @override
  String get gvMbEditSave => '保存';

  @override
  String get gvMbEditSuccess => '已编辑';

  @override
  String get gvMbMentionAll => '所有人';
}
