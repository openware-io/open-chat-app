// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'WV Chat';

  @override
  String get appSubtitle => 'Secure, fast messaging';

  @override
  String get tabMessages => 'Chats';

  @override
  String get tabContacts => 'Contacts';

  @override
  String get tabServices => 'Services';

  @override
  String get tabMe => 'Me';

  @override
  String get addFriendTitle => 'Add friend';

  @override
  String get startGroupChatTitle => 'New group chat';

  @override
  String get scanQrTitle => 'Scan';

  @override
  String get scanSemanticsViewfinder =>
      'Scan area. Point a friend code or mini program code at the frame.';

  @override
  String get scanHintPlaceCodeInFrame =>
      'Place the friend or mini program code inside the frame';

  @override
  String get scanFlashlight => 'Flashlight';

  @override
  String get scanFriendRequestDialogTitle => 'Friend request';

  @override
  String scanFriendRequestDialogBody(String username) {
    return 'Send a friend request to $username?';
  }

  @override
  String get scanErrorUserNotFound => 'User not found';

  @override
  String get scanErrorCannotAddSelf => 'You can’t add yourself';

  @override
  String get scanErrorAlreadyFriend => 'Already friends with this user';

  @override
  String get scanFriendRequestNote => 'Added via scan';

  @override
  String scanFriendRequestNoteWithNick(String nick) {
    return 'Added via scan ($nick)';
  }

  @override
  String get scanPickQrImage => 'Choose QR image';

  @override
  String get scanWebCameraUnavailable =>
      'Camera scanning isn’t available (use HTTPS or localhost and allow camera access). You can pick an image that contains a QR code below.';

  @override
  String get scanNoQrFoundInImage => 'No QR code found in the image';

  @override
  String get scanCouldNotReadImage => 'Couldn’t read the selected image';

  @override
  String get scanUnsupportedQrCode => 'This QR code isn\'t supported';

  @override
  String tabBadgeUnread(int count) {
    return '$count unread messages';
  }

  @override
  String get tabBadgeDot => 'New activity';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get profileMyQrCode => 'My QR code';

  @override
  String get profileSaveQrCode => 'Save QR code';

  @override
  String get settingsProfile => 'Profile';

  @override
  String get settingsChangePassword => 'Change password';

  @override
  String get settingsCheckUpdate => 'Check for updates';

  @override
  String get settingsVersionCurrent => 'Current version';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotifyDetail => 'Offline push notifications';

  @override
  String get settingsNotifyPrivate => 'Private chat offline push';

  @override
  String get settingsNotifyGroup => 'Group offline push';

  @override
  String get settingsNotifyChannel => 'Channel offline push';

  @override
  String get settingsAllowGroupFriendRequest => 'Allow group members to add me';

  @override
  String get settingsHideGroupMemberInfo => 'Group member privacy';

  @override
  String get settingsHideGroupMemberInfoSubtitle =>
      'Hide usernames and avatars of members who aren\'t your friends';

  @override
  String get appAppearanceLight => 'Light';

  @override
  String get appAppearanceDark => 'Dark';

  @override
  String get settingsLanguageSubtitle => 'Follow system, Chinese, or English';

  @override
  String get langFollowSystem => 'Follow system';

  @override
  String get langChinese => '简体中文';

  @override
  String get langEnglish => 'English';

  @override
  String get settingsLogout => 'Log out';

  @override
  String get settingsLogoutConfirmTitle => 'Log out';

  @override
  String get settingsLogoutConfirmBody => 'Are you sure you want to log out?';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsDeleteAccountNoticeTitle =>
      'Before you delete your account';

  @override
  String get settingsDeleteAccountNoticeBody =>
      'Your account will be deactivated immediately. You will not be able to sign in again with this username and password. Your username may become available for others to register. Chat history and other data may remain on the server. This cannot be undone.';

  @override
  String get settingsDeleteAccountNoticeConfirm => 'I understand, continue';

  @override
  String get settingsDeleteAccountPasswordTitle => 'Verify password';

  @override
  String get settingsDeleteAccountPasswordHint => 'Enter your current password';

  @override
  String get settingsDeleteAccountSubmit => 'Delete account';

  @override
  String get toastDeleteAccountSuccess => 'Your account has been deleted';

  @override
  String get loginUsernameHint => 'Username';

  @override
  String get loginPasswordHint => 'Password';

  @override
  String get loginUsernamePasswordRequired =>
      'Please enter username and password';

  @override
  String get loginButton => 'Log in';

  @override
  String get loginLoading => 'Signing in...';

  @override
  String get loginNoAccount => 'No account yet?';

  @override
  String get loginRegister => 'Sign up';

  @override
  String get authAgreementPrefix => 'I have read and agree to the ';

  @override
  String get authAgreementUserTerms => 'User Agreement';

  @override
  String get authAgreementAnd => ' and ';

  @override
  String get authAgreementPrivacy => 'Privacy Policy';

  @override
  String get authAgreementRequired =>
      'Please read and agree to the User Agreement and Privacy Policy';

  @override
  String get updateChecking => 'Checking for updates…';

  @override
  String get updateUpToDate => 'You\'re on the latest version';

  @override
  String get updateNoReleaseInfo => 'No release information';

  @override
  String get updateMandatoryTitle => 'Update required';

  @override
  String get updateSuggestTitle => 'New version (recommended)';

  @override
  String get updateNewVersionTitle => 'New version';

  @override
  String get updateNoNotes => 'No release notes';

  @override
  String updateLatestVersionLine(String versionName, int versionCode) {
    return 'Latest: $versionName (build $versionCode)';
  }

  @override
  String get updateNoDownloadUrl =>
      'No download URL configured. Contact admin.';

  @override
  String get updateInvalidUrl => 'Invalid download URL';

  @override
  String get updateCannotOpenLink => 'Could not open link';

  @override
  String get updateLater => 'Later';

  @override
  String get updateNow => 'Update now';

  @override
  String get updateDownloading => 'Downloading update…';

  @override
  String updateDownloadFailed(String message) {
    return 'Update failed: $message';
  }

  @override
  String get updateReadyToInstallTitle => 'Ready to install';

  @override
  String get updateReadyToInstallBody =>
      'The installer has been downloaded. Tap OK to close the app; it will reopen when installation finishes.';

  @override
  String get updateInstallSucceeded => 'Update installed successfully.';

  @override
  String get updateInstallFailedTitle => 'Update failed';

  @override
  String get commonNetworkError => 'Network error';

  @override
  String get routeInvalidArguments => 'Invalid page parameters';

  @override
  String get commonOk => 'OK';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonDownload => 'Download';

  @override
  String get commonShare => 'Share';

  @override
  String reportTitle(String name) {
    return 'Report $name';
  }

  @override
  String get reportReasonObscene => 'Sexual or vulgar content';

  @override
  String get reportReasonHarassment => 'Harassment or abuse';

  @override
  String get reportReasonScam => 'Spam or fraud';

  @override
  String get reportReasonPolitical => 'Sensitive political content';

  @override
  String get reportReasonIllegal => 'Illegal content';

  @override
  String get reportReasonOther => 'Other';

  @override
  String get reportPickReason => 'Please select a reason';

  @override
  String get reportSubmitted => 'Report submitted. We’ll review it soon.';

  @override
  String get reportFailed => 'Couldn’t submit report. Try again later.';

  @override
  String get reportDescHint => 'Details (optional)';

  @override
  String get reportSubmit => 'Submit report';

  @override
  String get mapChooseApp => 'Open in maps';

  @override
  String get mapAppleMaps => 'Apple Maps';

  @override
  String get mapGoogleMaps => 'Google Maps';

  @override
  String get mapAmap => 'Amap';

  @override
  String get mapOpenInExternalApp => 'Open in maps app';

  @override
  String get chatFileDownloadExplain =>
      'The file will be saved to this app’s documents folder. You can open it from the system file manager.';

  @override
  String get chatFileSavedToast => 'Saved to app documents';

  @override
  String get chatFileDownloadFailedToast => 'Download failed';

  @override
  String get miniProgramTitle => 'Mini program';

  @override
  String get miniProgramNoIntro => 'No description';

  @override
  String get miniProgramViewFullIntro => 'View all';

  @override
  String get miniProgramShare => 'Share';

  @override
  String get miniProgramReenter => 'Restart';

  @override
  String get miniProgramAppIntro => 'About';

  @override
  String get miniProgramWebUnsupported =>
      'Built-in browser isn’t supported here';

  @override
  String get miniProgramCannotOpenUrl => 'Couldn’t open mini program link';

  @override
  String get miniProgramLoadSlow => 'Loading slowly — page is shown';

  @override
  String get composerHint => 'Message…';

  @override
  String get composerHoldToTalk => 'Hold to talk';

  @override
  String get bannerNewMessage => 'New message';

  @override
  String get toastQrSaveNotSupported =>
      'Saving to gallery isn’t supported on this platform';

  @override
  String get toastSearchFailed => 'Search failed';

  @override
  String get toastLoadMoreFailed => 'Couldn’t load more';

  @override
  String get toastChatHistoryFriendsOnly =>
      'Only friends can view chat history';

  @override
  String get toastChatHistoryGroupOnly =>
      'Only group members can view chat history';

  @override
  String get featurePrivateChatDisabled => 'Direct messages are turned off';

  @override
  String get featureGroupChatDisabled => 'Group chat is turned off';

  @override
  String get toastMessageNotFound => 'Message not found';

  @override
  String get toastMicPermissionRequired =>
      'Microphone access is required to send voice';

  @override
  String toastVoiceRecordStartFailed(String error) {
    return 'Couldn’t start recording: $error';
  }

  @override
  String get toastVoiceWebNoEncoder =>
      'This browser doesn’t support voice recording (no audio encoder).';

  @override
  String toastFileExceedsLimit(int mb) {
    return 'File exceeds limit ($mb MB)';
  }

  @override
  String get toastFilePickReadFailed =>
      'Couldn’t read the selected file, please try again';

  @override
  String get toastMapTilesNotConfigured =>
      'Map isn’t configured; can’t send location';

  @override
  String get toastVideoCallDisabled => 'Video calls are turned off';

  @override
  String get toastVoiceCallDisabled => 'Voice calls are turned off';

  @override
  String get toastCannotCallSelf => 'You can’t call yourself';

  @override
  String get toastAlreadyInCall => 'Already in a call';

  @override
  String get toastStickerAdded => 'Added to stickers';

  @override
  String get toastCouponsComingSoon => 'Coupons coming soon';

  @override
  String get toastServiceNoUrl => 'This service has no URL configured';

  @override
  String get toastFillNickname => 'Enter a display name';

  @override
  String get toastProfileSaved => 'Saved';

  @override
  String get toastMiniProgramNoShare =>
      'This mini program can’t share a code yet';

  @override
  String get toastEnterCurrentPassword => 'Enter your current password';

  @override
  String get toastNewPasswordMinLength =>
      'New password must be at least 6 characters';

  @override
  String get toastNewPasswordMismatch => 'New passwords don’t match';

  @override
  String get toastPasswordUpdated => 'Password updated';

  @override
  String get toastMembersAdded => 'Members added';

  @override
  String get toastMiniProgramNotFound => 'Mini program not found';

  @override
  String get toastMiniProgramNoEntry => 'Mini program has no entry URL';

  @override
  String get toastScanFriendOrMiniCode => 'Scan a friend or mini program code';

  @override
  String get toastScanFriendCode => 'Scan a friend code';

  @override
  String get toastFriendRequestSent => 'Request sent';

  @override
  String get toastGroupChatCleared => 'Local group chat history cleared';

  @override
  String get toastGroupDissolved => 'The group has been dissolved';

  @override
  String get chatPeerUnavailableToast =>
      'Not a contact or this group no longer exists';

  @override
  String get groupOwnerWelcomeMessage => 'Hello';

  @override
  String get groupOwnerBadge => 'Owner';

  @override
  String get groupAutoMessageDissolved => 'This group has been dissolved';

  @override
  String toastOperationFailed(String error) {
    return 'Something went wrong: $error';
  }

  @override
  String get toastEnterGroupName => 'Enter a group name';

  @override
  String get toastForwarded => 'Forwarded';

  @override
  String get toastSent => 'Sent';

  @override
  String get toastFriendRequestSentDetail => 'Friend request sent';

  @override
  String get toastPrivateChatCleared => 'Local chat history cleared';

  @override
  String toastAvatarCropFailed(String error) {
    return 'Couldn’t crop: $error';
  }

  @override
  String get toastImageSavedToDocuments => 'Saved to app documents';

  @override
  String get toastImageSaveFailed => 'Save failed. Check your network';

  @override
  String get errorLocationServiceDisabled => 'Location services are off';

  @override
  String get errorLocationPermissionDenied => 'Location permission denied';

  @override
  String get toastRetryShort => 'Please try again shortly';

  @override
  String get toastImageGenerateFailed => 'Couldn’t create image';

  @override
  String get toastGalleryPermissionRequired =>
      'Photo library access is required to save';

  @override
  String get toastSavedToGallery => 'Saved to Photos';

  @override
  String get toastSaveFailedShort => 'Save failed';

  @override
  String get galErrorAccessDenied => 'No photo library access';

  @override
  String get galErrorNotEnoughSpace => 'Not enough storage space';

  @override
  String get galErrorUnsupportedFormat => 'Unsupported image format';

  @override
  String get galErrorUnexpected =>
      'Couldn’t save. Allow Photos access in Settings → Privacy.';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSearch => 'Search';

  @override
  String displayUserIdLabel(String id) {
    return 'User';
  }

  @override
  String get contactDetailTitle => 'Contact';

  @override
  String contactAccountLine(String account) {
    return 'Account: $account';
  }

  @override
  String get contactSendMessage => 'Message';

  @override
  String get contactRemarkLabel => 'Remark';

  @override
  String get contactRemarkNotSet => 'Not set';

  @override
  String get contactRecommendToFriends => 'Recommend to friends';

  @override
  String get chatHistoryTitle => 'Chat history';

  @override
  String get contactClearChatTitle => 'Clear chat history';

  @override
  String get chatClearAlsoDeleteServer => 'Also delete on server';

  @override
  String get chatDeleteForMe => 'Delete for me';

  @override
  String get chatDeleteForEveryone => 'Delete for everyone';

  @override
  String get chatMultiSelect => 'Multi-select';

  @override
  String chatMultiSelectCount(Object count) {
    return 'Selected $count';
  }

  @override
  String get chatDeleteSelected => 'Delete selected';

  @override
  String get contactClearChatConfirmBody =>
      'Clear this chat on this device? This only affects the current account on this device and does not delete the other person’s or server history.';

  @override
  String get contactClearChatRow => 'Clear local chat history';

  @override
  String get contactBlockTitle => 'Block';

  @override
  String get contactBlockConfirmBody => 'Block this contact?';

  @override
  String get contactBlockAction => 'Block';

  @override
  String get contactDeleteFriendTitle => 'Delete friend';

  @override
  String get contactDeleteFriendConfirmBody =>
      'Remove this friend? Chat history will stay on your device.';

  @override
  String get contactDeleteFriendAction => 'Delete friend';

  @override
  String get contactReport => 'Report';

  @override
  String get contactUnblockTitle => 'Remove from blocklist';

  @override
  String get contactUnblockConfirmBody =>
      'Remove this contact from the blocklist?';

  @override
  String get contactUnblockAction => 'Unblock';

  @override
  String get blacklistTitle => 'Blocked List';

  @override
  String get blacklistEmpty => 'No blocked friends';

  @override
  String get blacklistLoadFailed => 'Failed to load';

  @override
  String get settingsBlacklist => 'Blocked list';

  @override
  String get friendGroupsTitle => 'Friend Groups';

  @override
  String get friendGroupCreate => 'New Group';

  @override
  String get friendGroupNoGroup => 'No group';

  @override
  String get setFriendGroupTitle => 'Set group';

  @override
  String get friendGroupNameHint => 'Group name';

  @override
  String get friendGroupEmpty => 'No groups';

  @override
  String friendGroupMemberCount(int count) {
    return '$count friends';
  }

  @override
  String get friendGroupCreateSuccess => 'Group created';

  @override
  String get friendGroupCreateFailed => 'Failed to create group';

  @override
  String get friendGroupRename => 'Rename';

  @override
  String get friendGroupDelete => 'Delete group';

  @override
  String get friendGroupDeleteConfirm =>
      'Friends in this group will become ungrouped.';

  @override
  String get friendGroupRenameSuccess => 'Group renamed';

  @override
  String get friendGroupDeleteSuccess => 'Group deleted';

  @override
  String get contactVoiceCall => 'Voice call';

  @override
  String get contactVideoCall => 'Video call';

  @override
  String get contactRemarkEditTitle => 'Edit remark';

  @override
  String get contactRemarkHint => 'Remark name';

  @override
  String get addFriendSearchFieldHint => 'Search by username or phone';

  @override
  String get addFriendSearchPrompt => 'Search by username or phone number';

  @override
  String get addFriendNoUsers => 'No users found';

  @override
  String get addFriendAlreadyFriends => 'Already friends';

  @override
  String get addFriendRequestSent => 'Sent';

  @override
  String get addFriendAction => 'Add';

  @override
  String get groupChatDefaultName => 'Group chat';

  @override
  String get groupClearHistoryTitle => 'Clear group chat history';

  @override
  String get groupClearHistoryConfirmBody =>
      'Clear this group chat on this device? This only affects the current account on this device and does not delete other members’ or server history.';

  @override
  String get groupClearHistoryRow => 'Clear local chat history';

  @override
  String get groupDissolveAction => 'Dissolve group';

  @override
  String get groupMuteAction => 'Mute';

  @override
  String get groupMute10Minutes => 'Mute 10 min';

  @override
  String get groupMute1Hour => 'Mute 1 hour';

  @override
  String get groupMute1Day => 'Mute 1 day';

  @override
  String get groupUnmuteAction => 'Unmute';

  @override
  String get groupSetAdminAction => 'Set as admin';

  @override
  String get groupUnsetAdminAction => 'Remove admin';

  @override
  String get groupMuteSuccess => 'Muted';

  @override
  String get groupUnmuteSuccess => 'Unmuted';

  @override
  String get groupSetAdminSuccess => 'Promoted to admin';

  @override
  String get groupUnsetAdminSuccess => 'Removed admin';

  @override
  String get groupLeaveAction => 'Leave group';

  @override
  String get groupDissolveConfirmBody => 'Dissolve this group?';

  @override
  String get groupLeaveConfirmBody => 'Leave this group?';

  @override
  String groupShowAllMembers(int count) {
    return 'View all $count members';
  }

  @override
  String get groupCollapseMembers => 'Show less';

  @override
  String get groupEditNameTitle => 'Edit group name';

  @override
  String get groupNameFieldHint => 'Group name';

  @override
  String get groupAnnouncementViewEmpty => 'No announcement';

  @override
  String get groupAnnouncementRowPlaceholder => 'Not set';

  @override
  String get groupAnnouncementLabel => 'Announcement';

  @override
  String get groupNameLabel => 'Group name';

  @override
  String get groupEditAnnouncementTitle => 'Edit announcement';

  @override
  String get groupAnnouncementFieldHint => 'Announcement (optional)';

  @override
  String groupRemoveMemberConfirm(String name) {
    return 'Remove \"$name\" from the group?';
  }

  @override
  String get groupRemoveMemberAction => 'Remove';

  @override
  String get groupMemberLongPressRemoveHint => ', long-press to remove';

  @override
  String get groupInvite => 'Invite';

  @override
  String get groupAllowMemberInvite => 'Allow members to invite';

  @override
  String get groupAllowMemberFriendRequest => 'Allow members to add each other';

  @override
  String get groupMemberFriendRequestDisabled =>
      'Adding group members as friends is disabled';

  @override
  String get inviteGroupMembersTitle => 'Invite members';

  @override
  String get chatHistoryNoPermission => 'No permission to view chat history';

  @override
  String get chatHistoryTabText => 'Text';

  @override
  String get chatHistoryTabFiles => 'Files';

  @override
  String get chatHistoryTabImages => 'Images';

  @override
  String get chatHistoryTabVideos => 'Videos';

  @override
  String get chatHistoryTabDate => 'Date';

  @override
  String get chatHistoryDateSelect => 'Tap a dotted date to view messages';

  @override
  String get chatHistoryDateEmpty => 'No messages on this date';

  @override
  String get chatHistoryWeekMon => 'Mon';

  @override
  String get chatHistoryWeekTue => 'Tue';

  @override
  String get chatHistoryWeekWed => 'Wed';

  @override
  String get chatHistoryWeekThu => 'Thu';

  @override
  String get chatHistoryWeekFri => 'Fri';

  @override
  String get chatHistoryWeekSat => 'Sat';

  @override
  String get chatHistoryWeekSun => 'Sun';

  @override
  String get chatHistoryAllLoaded => 'All chat history loaded';

  @override
  String get chatHistorySenderMe => 'Me';

  @override
  String get chatHistorySenderPeer => 'Contact';

  @override
  String get chatHistorySearchFieldHint =>
      'Keyword, then search (last 90 days)';

  @override
  String get chatHistorySearchScopeNote =>
      'Enter a keyword and tap search; only text from the last 90 days is searched';

  @override
  String get chatHistorySearchNoMatches => 'No matching messages';

  @override
  String get chatHistorySearchAllResultsShown => 'All results shown';

  @override
  String get chatHistoryEmptyFiles => 'No files';

  @override
  String get chatHistoryEmptyImages => 'No images';

  @override
  String get chatHistoryEmptyVideos => 'No videos';

  @override
  String chatHistoryMonthLabel(int year, int month) {
    return '$year-$month';
  }

  @override
  String get chatHistoryFileUnnamed => 'File';

  @override
  String get chatHistoryEmojiPlaceholder => '[sticker]';

  @override
  String get contactsNewFriends => 'New friends';

  @override
  String get friendRequestNotificationTitle => 'New friend request';

  @override
  String friendRequestNotificationBody(Object id) {
    return 'User $id wants to add you as a friend';
  }

  @override
  String get friendAcceptedNotificationTitle => 'Friend request accepted';

  @override
  String friendAcceptedNotificationBody(Object id) {
    return 'You are now friends with user $id';
  }

  @override
  String get contactsGroupChatEntry => 'Group chats';

  @override
  String contactsGroupSectionTitle(int count) {
    return 'Group chats ($count)';
  }

  @override
  String get contactsEmptyFriends => 'No contacts yet';

  @override
  String get contactsFriendRequestsEmpty => 'No pending requests';

  @override
  String contactsFriendRequestLine(String name) {
    return '$name sent a friend request';
  }

  @override
  String get contactsFriendRequestReject => 'Decline';

  @override
  String get contactsFriendRequestAccept => 'Accept';

  @override
  String get friendAcceptAutoGreeting => 'Hello';

  @override
  String createGroupDefaultName(int count) {
    return 'Group chat ($count)';
  }

  @override
  String get createGroupCreatedPreview => 'Group created';

  @override
  String createGroupDoneWithCount(int count) {
    return 'Done ($count)';
  }

  @override
  String get createGroupNameFieldLabel => 'Group name';

  @override
  String get createGroupSearchFriendsHint => 'Search friends';

  @override
  String get pointsMyPoints => 'My points';

  @override
  String get pointsLoadFailed => 'Load failed';

  @override
  String get pointsCardFootnote =>
      'Use points for events and redemptions (subject to platform rules).';

  @override
  String get pointsViewLedger => 'Details';

  @override
  String get pointsCoupons => 'Coupons';

  @override
  String pointsCouponsBadgeCount(int count) {
    return '$count';
  }

  @override
  String get pointsLedgerTitle => 'Points history';

  @override
  String get pointsCurrentTotal => 'Current balance';

  @override
  String get pointsFilterAll => 'All';

  @override
  String get pointsFilterCredit => 'Earned';

  @override
  String get pointsFilterDebit => 'Spent';

  @override
  String get pointsRetry => 'Retry';

  @override
  String get pointsLedgerEmpty => 'No entries yet';

  @override
  String get pointsLedgerEnd => 'All records shown';

  @override
  String get pointsReasonCreditDefault => 'Points added';

  @override
  String get pointsReasonDebitDefault => 'Points deducted';

  @override
  String pointsBalanceAfter(int balance) {
    return 'Bal. $balance';
  }

  @override
  String get coinDefaultName => 'Coins';

  @override
  String get coinCardFootnote =>
      'Use coins for in-platform spending and discounts (subject to platform rules).';

  @override
  String get coinViewLedger => 'Details';

  @override
  String get coinLedgerTitle => 'Coin history';

  @override
  String get coinCurrentTotal => 'Current coin balance';

  @override
  String get coinReasonCreditDefault => 'Coins added';

  @override
  String get coinReasonDebitDefault => 'Coins deducted';

  @override
  String coinBalanceAfter(int balance) {
    return 'Bal. $balance';
  }

  @override
  String get servicesEmptyList => 'No services yet';

  @override
  String get servicesSearchHint => 'Search mini programs';

  @override
  String get servicesSearchEmpty => 'No matching services';

  @override
  String get servicesPinnedTitle => 'Pinned shortcuts';

  @override
  String get servicesPin => 'Pin';

  @override
  String get servicesUnpin => 'Unpin';

  @override
  String get servicesPinnedReorderHint => 'Long-press to reorder';

  @override
  String get servicesUnnamedItem => 'Untitled';

  @override
  String get servicesMoreTitle => 'More services';

  @override
  String get servicesWalletCompanyName => 'A380';

  @override
  String get servicesWalletA380Coin => 'A380 Coin';

  @override
  String get servicesWalletPoints => 'Points';

  @override
  String get servicesPointsBalance => 'Points balance';

  @override
  String get servicesHotel => 'Hotel';

  @override
  String get servicesKtv => 'KTV';

  @override
  String get servicesKtvBusiness => 'KTV Business';

  @override
  String get servicesBar => 'Bar';

  @override
  String get servicesBilliards => 'Billiards';

  @override
  String get servicesFood => 'Food';

  @override
  String get servicesDelivery => 'Delivery';

  @override
  String get servicesFlashSale => 'Flash sale';

  @override
  String get servicesBoutique => 'Boutique';

  @override
  String get servicesMassage => 'Foot bath';

  @override
  String get servicesFlights => 'Flights';

  @override
  String get servicesTaxi => 'Ride-hailing';

  @override
  String get servicesComingSoon =>
      'This feature is being updated. Please check back soon.';

  @override
  String serviceDemoSearchHint(String service) {
    return 'Search $service';
  }

  @override
  String serviceDemoHeroTitle(String service) {
    return 'Featured $service';
  }

  @override
  String get serviceDemoHeroSubtitle =>
      'Discover popular services and confirm in a few taps';

  @override
  String serviceDemoFeaturedItem(String service) {
    return 'Featured $service';
  }

  @override
  String serviceDemoPopularItem(String service) {
    return 'Popular $service';
  }

  @override
  String serviceDemoValueItem(String service) {
    return 'Best value $service';
  }

  @override
  String serviceDemoNearbyItem(String service) {
    return 'Nearby $service';
  }

  @override
  String get serviceDemoQualityDescription =>
      'Quality assured · Flexible cancellation';

  @override
  String get serviceDemoFastDescription => 'Popular nearby · Fast confirmation';

  @override
  String get serviceDemoFilterRecommended => 'Recommended';

  @override
  String get serviceDemoFilterNearby => 'Nearby';

  @override
  String get serviceDemoFilterTopRated => 'Top rated';

  @override
  String get serviceDemoMockNotice =>
      'Local demo only. No real order or charge will be created.';

  @override
  String get serviceDemoNoResults => 'No matching services';

  @override
  String serviceDemoRating(String rating) {
    return '$rating rating';
  }

  @override
  String serviceDemoSold(int count) {
    return '$count sold';
  }

  @override
  String get serviceDemoFree => 'Free';

  @override
  String serviceDemoCouponAmount(String amount) {
    return '¥$amount';
  }

  @override
  String get serviceDemoAction => 'Try now';

  @override
  String get serviceDemoClaim => 'Claim';

  @override
  String get serviceDemoDone => 'Completed';

  @override
  String get serviceDemoConfirmTitle => 'Confirm demo';

  @override
  String serviceDemoConfirmBody(String item) {
    return 'Submit a demo order for “$item”?';
  }

  @override
  String get serviceDemoConfirm => 'Confirm';

  @override
  String serviceDemoSuccess(String item) {
    return '“$item” completed';
  }

  @override
  String get serviceDemoMyOrders => 'My demo orders';

  @override
  String get serviceDemoMyCoupons => 'My coupons';

  @override
  String get serviceDemoEmptyOrders => 'No records yet. Try a service first.';

  @override
  String get serviceDemoCouponNewUser => 'New user coupon';

  @override
  String get serviceDemoCouponDining => 'Dining coupon';

  @override
  String get serviceDemoCouponTravel => 'Travel coupon';

  @override
  String get serviceDemoCouponNoThreshold => 'No minimum · Sitewide';

  @override
  String serviceDemoCouponThreshold(String amount) {
    return 'Valid on ¥$amount+';
  }

  @override
  String serviceVenueSearchHint(String service) {
    return 'Search $service venues';
  }

  @override
  String get serviceVenueSmartSort => 'Smart sort';

  @override
  String get serviceVenueFilter => 'Filter';

  @override
  String get serviceVenueFeaturedMerchant => 'Featured';

  @override
  String get serviceVenueCleanTag => 'Comfortable';

  @override
  String serviceVenueDistance(String distance) {
    return '$distance km';
  }

  @override
  String serviceVenueReviews(int count) {
    return '$count reviews';
  }

  @override
  String get serviceVenueOpen => 'Open';

  @override
  String get serviceVenueOpenAllDay => 'Open all day · Walk-ins welcome';

  @override
  String get serviceVenueAddress => 'Address';

  @override
  String serviceVenueDealsTitle(int count) {
    return 'Deals ($count)';
  }

  @override
  String get serviceBookingHotelOptionsTitle => 'Rooms and prices';

  @override
  String get serviceBookingKtvOptionsTitle => 'Packages and prices';

  @override
  String get serviceBookingHotelOptionLabel => 'Room';

  @override
  String get serviceBookingKtvOptionLabel => 'Package';

  @override
  String serviceBookingPrice(int price) {
    return '¥$price';
  }

  @override
  String serviceBookingCashPrice(int price) {
    return 'Cash ¥$price';
  }

  @override
  String serviceBookingPointsPrice(int points) {
    return 'Redeem with $points points';
  }

  @override
  String get serviceBookingPayment => 'Booking method';

  @override
  String get serviceBookingHotelTimeLabel => 'Check-in time';

  @override
  String get serviceBookingKtvTimeLabel => 'Arrival time';

  @override
  String get serviceBookingChooseTime => 'Choose date and time';

  @override
  String get serviceBookingReserve => 'Reserve now';

  @override
  String get serviceBookingMockNotice =>
      'This is a local booking demo. It will not create a real order, deduct points, or charge you.';

  @override
  String get serviceBookingSuccessTitle => 'Reservation confirmed';

  @override
  String get serviceBookingSuccessBody =>
      'Your booking details are confirmed. Please arrive at the selected time.';

  @override
  String get serviceVenueBuyNow => 'Buy now';

  @override
  String get serviceVenueHotDeal => 'Popular deal';

  @override
  String get serviceVenueRefundAnytime => 'Refund anytime';

  @override
  String get serviceVenueValidAnytime => 'Expiry refund';

  @override
  String get serviceVenueDealDetailTitle => 'Deal details';

  @override
  String get serviceVenuePackageDetails => 'Package details';

  @override
  String get serviceVenueDuration => 'Duration';

  @override
  String get serviceVenueDurationValue => '2 hours';

  @override
  String get serviceVenueRoomType => 'Space';

  @override
  String get serviceVenueRoomTypeValue => 'Main hall / Booth';

  @override
  String get serviceVenueApplicable => 'Valid for';

  @override
  String get serviceVenueApplicableValue => 'All areas';

  @override
  String get serviceVenueAdditionalInfo => 'Additional information';

  @override
  String get serviceVenueAdditionalInfoBody =>
      'No reservation required. Show the mock order during opening hours. One package per order.';

  @override
  String get serviceVenueOrderNow => 'Order now';

  @override
  String get serviceVenueCheckoutTitle => 'Submit order';

  @override
  String get serviceVenueQuantity => 'Quantity';

  @override
  String get serviceVenueDecreaseQuantity => 'Decrease quantity';

  @override
  String get serviceVenueIncreaseQuantity => 'Increase quantity';

  @override
  String get serviceVenueTotal => 'Total';

  @override
  String get serviceVenueDiscount => 'Discount';

  @override
  String get serviceVenueFullDiscount => 'Fully discounted';

  @override
  String get serviceVenuePurchaseNotice => 'Purchase notice';

  @override
  String get serviceVenuePurchaseNoticeBody =>
      'This is a local mock demo. No payment or real charge will be made. Submitting immediately creates a successful order.';

  @override
  String get serviceVenueFreeOrderAction => 'Place free order';

  @override
  String get serviceVenueOrderSuccessTitle => 'Order successful';

  @override
  String get serviceVenueOrderSuccessBody =>
      'Your demo order is ready. Return to the list to try another venue.';

  @override
  String get serviceVenueOrderVenue => 'Venue';

  @override
  String get serviceVenueOrderItem => 'Package';

  @override
  String get serviceVenueOrderNumber => 'Order number';

  @override
  String get serviceVenueBackToList => 'Back to venues';

  @override
  String get serviceVenueBarName1 => 'Twilight Arcade Bar';

  @override
  String get serviceVenueBarName2 => 'Blue Note Thirteen';

  @override
  String get serviceVenueBarName3 => 'Cloud Terrace Bar';

  @override
  String get serviceVenueBarName4 => 'Urban Tipsy Lab';

  @override
  String get serviceVenuePoolName1 => 'Starry Billiards Club';

  @override
  String get serviceVenuePoolName2 => 'Daybreak Pool Hall';

  @override
  String get serviceVenuePoolName3 => 'Black Eight Club';

  @override
  String get serviceVenuePoolName4 => 'Brilliant Billiards';

  @override
  String get serviceVenueHotelName1 => 'Cloud Rest Hotel';

  @override
  String get serviceVenueHotelName2 => 'Galaxy International Hotel';

  @override
  String get serviceVenueHotelName3 => 'Riverside Joy Hotel';

  @override
  String get serviceVenueHotelName4 => 'City Lights Hotel';

  @override
  String get serviceVenueKtvName1 => 'Golden Stage KTV';

  @override
  String get serviceVenueKtvName2 => 'Star Party Karaoke';

  @override
  String get serviceVenueKtvName3 => 'Mic Wave Party KTV';

  @override
  String get serviceVenueKtvName4 => 'Cloud Karaoke';

  @override
  String get serviceVenueAddress1 => 'Level 2, Zone B, Galaxy Plaza';

  @override
  String get serviceVenueAddress2 => 'Creative Park, 88 Riverside Road';

  @override
  String get serviceVenueAddress3 => 'Level 5, Cloud Center, CBD';

  @override
  String get serviceVenueAddress4 => '19 Youth Street, Trend District';

  @override
  String get serviceVenueDescription1 =>
      'Refined setting and a relaxed atmosphere for friends';

  @override
  String get serviceVenueDescription2 =>
      'Well equipped, spacious and welcoming';

  @override
  String get serviceVenueDescription3 =>
      'City views, photo-friendly and comfortable';

  @override
  String get serviceVenueDescription4 =>
      'Stylish new venue with convenient transport';

  @override
  String get serviceVenueBarDeal1 => 'Drinks experience for two';

  @override
  String get serviceVenueBarDeal2 => 'Evening signature cocktail package';

  @override
  String get serviceVenueBarDeal3 => 'Terrace music party experience';

  @override
  String get serviceVenueFootBathDeal1 => 'Wellness foot bath package';

  @override
  String get serviceVenueFootBathDeal2 =>
      'Extended foot bath relaxation package';

  @override
  String get serviceVenueFootBathDeal3 => 'Foot bath leisure package for two';

  @override
  String get serviceVenuePoolDeal1 => '2-hour all-day billiards session';

  @override
  String get serviceVenuePoolDeal2 => 'Daytime Chinese billiards session';

  @override
  String get serviceVenuePoolDeal3 => 'Weekend friends pool package';

  @override
  String get serviceVenueHotelOption1 => 'Elegant king room';

  @override
  String get serviceVenueHotelOption2 => 'Deluxe twin room';

  @override
  String get serviceVenueHotelOption3 => 'Executive view suite';

  @override
  String get serviceVenueKtvOption1 => 'Karaoke for two';

  @override
  String get serviceVenueKtvOption2 => 'Friends gathering package';

  @override
  String get serviceVenueKtvOption3 => 'Party karaoke package';

  @override
  String get serviceVenueDealSubtitle1 => 'No reservation · Valid all day';

  @override
  String get serviceVenueDealSubtitle2 =>
      'Popular pick · Fast venue confirmation';

  @override
  String get profileEditChangeAvatar => 'Change photo';

  @override
  String get profileEditTakePhoto => 'Take photo';

  @override
  String get profileEditChooseFromGallery => 'Choose from gallery';

  @override
  String get profileFieldNickname => 'Nickname';

  @override
  String get profileFieldRequiredHint => 'Required';

  @override
  String get profileFieldPhone => 'Phone';

  @override
  String get profileFieldOptionalHint => 'Optional';

  @override
  String get profileFieldEmail => 'Email';

  @override
  String get profileFieldSignature => 'Bio';

  @override
  String get profileFieldSignatureHint => 'Say something…';

  @override
  String get pointsAccountEntryTitle => 'Points account';

  @override
  String get pointsAccountNotBound => 'Not linked';

  @override
  String get pointsAccountBindingTitle => 'Link points account';

  @override
  String get pointsAccountVerificationTitle => 'Security verification';

  @override
  String get pointsAccountStepAccount => 'Step 1';

  @override
  String get pointsAccountStepVerify => 'Verify identity';

  @override
  String get pointsAccountChooseHeading => 'Choose account type';

  @override
  String get pointsAccountChooseDescription =>
      'Choose how you sign in to your points account and enter the account details.';

  @override
  String get pointsAccountReplaceHeading => 'Change points account';

  @override
  String get pointsAccountReplaceDescription =>
      'The current account will be replaced after the new one is verified.';

  @override
  String get pointsAccountTypePhone => 'Phone';

  @override
  String get pointsAccountTypeEmail => 'Email';

  @override
  String get pointsAccountTypeAccount => 'Member no.';

  @override
  String get pointsAccountPhoneHint => 'Enter phone number';

  @override
  String get pointsAccountEmailHint => 'Enter email address';

  @override
  String get pointsAccountUsernameHint => 'Enter member number';

  @override
  String get pointsAccountPhoneInvalid =>
      'Enter a valid 6–15 digit phone number';

  @override
  String get pointsAccountEmailInvalid => 'Enter a valid email address';

  @override
  String get pointsAccountUsernameInvalid =>
      'Enter a 6–24 character letter or number member number';

  @override
  String get pointsAccountCodeToPhone =>
      'A verification code will be sent to this phone';

  @override
  String get pointsAccountCodeToEmail =>
      'A verification code will be sent to this email';

  @override
  String get pointsAccountCodeToSecurityContact =>
      'A code will be sent to the account\'s security contact';

  @override
  String get pointsAccountPrivacyNote =>
      'Your points account is only used for balance queries, earning, and redemption. The full account is never shown publicly.';

  @override
  String get pointsAccountRequestCode => 'Get verification code';

  @override
  String get pointsAccountCodeSent => 'Verification code sent';

  @override
  String get pointsAccountCodeResent => 'A new verification code was sent';

  @override
  String get pointsAccountEnterCode => 'Enter verification code';

  @override
  String get pointsAccountCodeSentTo => 'A 6-digit code was sent to';

  @override
  String get pointsAccountCodeFieldLabel => 'Six-digit verification code';

  @override
  String get pointsAccountCodeExpiryHint =>
      'Complete verification before the code expires';

  @override
  String get pointsAccountCodeInvalid => 'Incorrect code. Please try again';

  @override
  String get pointsAccountResendCode => 'Resend';

  @override
  String pointsAccountResendCountdown(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get pointsAccountDemoCodeLabel => 'Prototype verification code:';

  @override
  String get pointsAccountConfirmBinding => 'Confirm link';

  @override
  String get pointsAccountBindSuccess => 'Points account linked';

  @override
  String get pointsAccountBindSuccessDescription =>
      'Security verification is complete. Points services are now available.';

  @override
  String get pointsAccountReturnToProfile => 'Back to profile';

  @override
  String get pointsAccountSelectCountry => 'Choose country/region';

  @override
  String get pointsAccountSearchCountry => 'Search country, region, or code';

  @override
  String get pointsAccountNoCountryResults => 'No matching country or region';

  @override
  String pointsAccountPhoneInvalidForCountry(String country, String lengths) {
    return 'Enter a valid $country phone number ($lengths digits)';
  }

  @override
  String get pointsAccountEnterPassword => 'Enter password';

  @override
  String get pointsAccountPasswordNextHint =>
      'The next step verifies the member number password';

  @override
  String get pointsAccountPasswordVerificationTitle => 'Password verification';

  @override
  String get pointsAccountPasswordHeading => 'Verify with password';

  @override
  String pointsAccountPasswordDescription(String account) {
    return 'Enter the sign-in password for member number $account';
  }

  @override
  String get pointsAccountPasswordHint => 'Enter member number password';

  @override
  String get pointsAccountPasswordInvalid =>
      'Incorrect password. Please try again';

  @override
  String get pointsAccountDemoPasswordLabel => 'Prototype password:';

  @override
  String get passwordShowTooltip => 'Show password';

  @override
  String get passwordHideTooltip => 'Hide password';

  @override
  String get changePasswordCurrentLabel => 'Current password';

  @override
  String get changePasswordNewLabel => 'New password (min. 6 characters)';

  @override
  String get changePasswordConfirmLabel => 'Confirm new password';

  @override
  String get changePasswordSubmit => 'Update password';

  @override
  String get formLabelUsername => 'Username';

  @override
  String get formLabelPassword => 'Password';

  @override
  String get registerNicknameOptional => 'Nickname (optional)';

  @override
  String get registerSubmitting => 'Signing up...';

  @override
  String get avatarCropTitle => 'Crop avatar';

  @override
  String get avatarCropStickerTitle => 'Crop sticker';

  @override
  String get avatarCropDone => 'Done';

  @override
  String get avatarCropMissingData => 'Missing image data';

  @override
  String get recentMiniProgramsTitle => 'Recently used mini programs';

  @override
  String get recentMiniProgramsEmpty => 'No recent mini programs';

  @override
  String get commonClose => 'Close';

  @override
  String get commonSaveImage => 'Save image';

  @override
  String get commonSaveVideo => 'Save video';

  @override
  String get miniProgramQrCodeTitle => 'Mini program code';

  @override
  String get chatEmojiTab => 'Emoji';

  @override
  String get chatStickerPackTab => 'Stickers';

  @override
  String get chatStickerRecentTab => 'Recent';

  @override
  String get chatMoreImage => 'Photos';

  @override
  String get chatMoreTakePhoto => 'Take photo';

  @override
  String get chatMoreCamera => 'Photo / video';

  @override
  String get chatMoreCameraHint =>
      'Tap to take a photo. Press and hold to record a video.';

  @override
  String get chatCameraShutterHint => 'Tap for photo, hold for video';

  @override
  String get chatCameraRecordingHint => 'Release to stop recording';

  @override
  String get chatCameraInitializing => 'Opening camera…';

  @override
  String get chatCameraUnavailable =>
      'Camera unavailable. Check camera and microphone permissions.';

  @override
  String get chatCameraSwitchFlash => 'Change flash mode';

  @override
  String get chatMoreVideo => 'Video';

  @override
  String get chatMoreRecordVideo => 'Record video';

  @override
  String get chatMoreFile => 'Files';

  @override
  String get chatMoreLocation => 'Location';

  @override
  String get chatMoreVoiceCall => 'Voice call';

  @override
  String get chatMoreVideoCall => 'Video call';

  @override
  String chatReplyTo(String who) {
    return 'Reply to $who';
  }

  @override
  String get chatReplySelfShort => 'Me';

  @override
  String get chatReplyPeerShort => 'Them';

  @override
  String get chatDismissReplySemantics => 'Dismiss reply';

  @override
  String chatStickerCountShort(int count) {
    return '$count stickers';
  }

  @override
  String get chatStickerManage => 'Manage';

  @override
  String get chatStickerDoneEditing => 'Done';

  @override
  String get chatStickerMyEmptyHint =>
      'Tap + to add from your gallery, or long-press a sticker in chat to add it.';

  @override
  String get chatStickerEmptyList => 'No stickers yet';

  @override
  String get chatSemanticEmojiPicker => 'Emoji';

  @override
  String get imageViewerActualSizeTooltip => 'Actual size';

  @override
  String get chatVoiceCancelLabel => 'Cancel';

  @override
  String get chatVoiceReleaseToCancel => 'Release to cancel';

  @override
  String get chatVoiceReleaseToSend => 'Release to send · slide up to cancel';

  @override
  String get chatAddToStickers => 'Add to Stickers';

  @override
  String get chatStickerAddedToMine => 'Added to My Stickers';

  @override
  String get chatStickerAddFailed => 'Couldn’t add sticker';

  @override
  String get chatRecallConfirmBody => 'Recall this message?';

  @override
  String get chatDeleteMsgSendingBody =>
      'This message is still sending. Remove it only on this device?';

  @override
  String get chatDeleteMsgPrivateBody =>
      'Delete removes this message from the server and both devices. Copies already read, copied, forwarded, screenshotted, downloaded, or saved locally by the other side cannot be revoked. Delete?';

  @override
  String get chatDeleteMsgGroupBody =>
      'Delete removes this message from the server and group members\' devices. Copies already read, copied, forwarded, screenshotted, downloaded, or saved locally cannot be revoked. Delete?';

  @override
  String get chatDeleteMsgSecretBody =>
      'Secret chat messages are end-to-end encrypted. Deleting only removes it from this device; the other device is unaffected. Delete?';

  @override
  String get callTraceFallback => '[Call]';

  @override
  String callTraceVideoCompleted(String duration) {
    return 'Call duration $duration';
  }

  @override
  String callTraceAudioCompleted(String duration) {
    return 'Call duration $duration';
  }

  @override
  String get callTraceVideoCancelled => 'Video call canceled';

  @override
  String get callTraceAudioCancelled => 'Voice call canceled';

  @override
  String get callTraceVideoRejected => 'Video call declined';

  @override
  String get callTraceAudioRejected => 'Voice call declined';

  @override
  String get callTraceVideoBusy => 'Video call line busy';

  @override
  String get callTraceAudioBusy => 'Voice call line busy';

  @override
  String get callTraceVideoFailed => 'Video call not connected';

  @override
  String get callTraceAudioFailed => 'Voice call not connected';

  @override
  String get callTraceResolvedOtherDevice => 'Call answered on another device';

  @override
  String get callScreenUnknownRemote => 'Unknown';

  @override
  String get callStatusRinging => 'Calling…';

  @override
  String get callStatusWaitingForAnswer =>
      'Waiting for the other person to answer…';

  @override
  String get callStatusIncoming => 'Incoming…';

  @override
  String get callStatusConnecting => 'Connecting…';

  @override
  String get callStatusInCall => 'In call';

  @override
  String get callErrorMediaPermission =>
      'Can\'t access the camera or microphone. Check permissions and try again.';

  @override
  String get callErrorMediaNeedsHttps =>
      'Use HTTPS or localhost so your browser can use the camera and microphone.';

  @override
  String get callErrorSocketForCall =>
      'Can\'t reach the call service. Check your network and try again.';

  @override
  String get callErrorAcceptFailed => 'Couldn\'t answer. Please try again.';

  @override
  String get callErrorTimeout =>
      'Connection timed out. The other party may not have answered.';

  @override
  String get callActionBack => 'Back';

  @override
  String get callActionAnswer => 'Answer';

  @override
  String get callActionReject => 'Decline';

  @override
  String get callActionMute => 'Mute';

  @override
  String get callActionUnmute => 'Unmute';

  @override
  String get callActionMicrophoneOn => 'Microphone on';

  @override
  String get callActionMicrophoneOff => 'Microphone off';

  @override
  String get callActionSpeakerOn => 'Speaker on';

  @override
  String get callActionSpeakerOff => 'Speaker off';

  @override
  String get callActionSwitchCamera => 'Flip camera';

  @override
  String get callActionCameraOn => 'Camera on';

  @override
  String get callActionCameraOff => 'Camera off';

  @override
  String get callActionCameraEnabled => 'Camera on';

  @override
  String get callActionCameraDisabled => 'Camera off';

  @override
  String get callActionCancel => 'Cancel';

  @override
  String get callActionHangUp => 'Hang up';

  @override
  String get callActionMinimize => 'Minimize call';

  @override
  String get callActionReturnToCall => 'Return to call';

  @override
  String get callActionBackgroundBlurEnabled => 'Background blur on';

  @override
  String get callActionBackgroundBlurDisabled => 'Background blur off';

  @override
  String get callActionBackgroundBlurSettings => 'Background blur settings';

  @override
  String get callErrorBackgroundBlurUnavailable =>
      'Background blur isn\'t available on this device';

  @override
  String get forwardMessageTitle => 'Forward to friend';

  @override
  String get forwardMessageAction => 'Forward';

  @override
  String get recommendContactTitle => 'Recommend to friend';

  @override
  String get recommendContactAction => 'Send';

  @override
  String get friendsEmpty => 'No friends yet';

  @override
  String get friendsNoMatches => 'No matching friends';

  @override
  String get chatAnnouncementTitle => 'Announcement';

  @override
  String get chatListEmpty => 'No messages yet';

  @override
  String get chatPinConversation => 'Pin';

  @override
  String get chatUnpinConversation => 'Unpin';

  @override
  String get commonDelete => 'Delete';

  @override
  String chatGroupDefaultTitle(String id) {
    return 'Group $id';
  }

  @override
  String chatUserDefaultTitle(String id) {
    return 'User $id';
  }

  @override
  String chatMentionGroupNickname(String nickname) {
    return 'Group nickname: $nickname';
  }

  @override
  String get chatMentionGroupNicknameEmpty => 'Group nickname: None';

  @override
  String get chatTypingPeer => 'Typing...';

  @override
  String get chatActionCopy => 'Copy';

  @override
  String get chatMediaCopied => 'Media copied';

  @override
  String get chatMediaCopyFailed => 'Couldn’t copy this media';

  @override
  String get chatActionReply => 'Reply';

  @override
  String get chatActionForward => 'Forward';

  @override
  String get chatActionRecall => 'Recall';

  @override
  String get chatNewMessage => 'New messages';

  @override
  String get chatStickerPreview => '[Sticker]';

  @override
  String get chatMessageRecalledSelf => 'You recalled a message';

  @override
  String get chatMessageRecalledPeer => 'The other person recalled a message';

  @override
  String get chatSending => 'Sending...';

  @override
  String get chatVoiceMessage => 'Voice message';

  @override
  String get chatTapToDownload => 'Tap to download';

  @override
  String get chatNameCard => 'Contact card';

  @override
  String get chatPersonalNameCard => 'Personal card';

  @override
  String get composerKeyboardInput => 'Keyboard input';

  @override
  String get composerVoiceInput => 'Voice input';

  @override
  String get commonMore => 'More';

  @override
  String get chatImageCaptionTitle => 'Send image';

  @override
  String get chatImageCaptionHint =>
      'Add a caption (optional, up to 200 characters)';

  @override
  String get chatClipboardImageReadFailed =>
      'Couldn’t read the image from the clipboard';

  @override
  String get commonSend => 'Send';

  @override
  String get reservationTitle => 'Reservations';

  @override
  String get reservationEntrySubtitle =>
      'Book hotels, KTV and in-store services';

  @override
  String get reservationMine => 'My reservations';

  @override
  String get reservationMineSubtitle =>
      'View pending and completed reservations';

  @override
  String get reservationChooseService => 'Choose a service';

  @override
  String get reservationNoServices => 'No services available';

  @override
  String get reservationNoStores => 'No stores available for this service';

  @override
  String reservationCreateTitle(String service) {
    return 'Book $service';
  }

  @override
  String get reservationStoreLabel => 'Store';

  @override
  String get reservationStoreAddress => 'Address';

  @override
  String get reservationServiceTypeLabel => 'Service';

  @override
  String get reservationContactNameLabel => 'Contact name';

  @override
  String get reservationPhoneLabel => 'Phone number';

  @override
  String get reservationDateLabel => 'Date';

  @override
  String get reservationTimeLabel => 'Time';

  @override
  String get reservationPersonNumLabel => 'Guests';

  @override
  String reservationPersonNumValue(int count) {
    return '$count guests';
  }

  @override
  String get reservationDecreasePerson => 'Fewer guests';

  @override
  String get reservationIncreasePerson => 'More guests';

  @override
  String get reservationRemarkLabel => 'Notes (room type or other requests)';

  @override
  String get reservationSubmit => 'Submit reservation';

  @override
  String get reservationSubmitHint =>
      'Points are applied only when the store verifies the service';

  @override
  String get reservationSelectStoreError => 'Select a store';

  @override
  String get reservationContactNameError =>
      'Enter a contact name of 1-32 characters';

  @override
  String get reservationPhoneError =>
      'Enter a valid phone number of up to 30 digits';

  @override
  String get reservationRemarkError => 'Notes cannot exceed 512 characters';

  @override
  String get reservationCreatedSuccess =>
      'Reservation submitted. The store will verify it offline.';

  @override
  String get reservationPending => 'Pending';

  @override
  String get reservationVerified => 'Verified';

  @override
  String get reservationEmpty => 'No reservations yet';

  @override
  String reservationPointsDeducted(int points) {
    return '$points points used';
  }

  @override
  String get reservationDetailTitle => 'Reservation details';

  @override
  String get reservationPendingHint =>
      'Arrive at the selected time. The store will verify the service.';

  @override
  String get reservationVerifiedHint => 'This reservation has been verified';

  @override
  String get reservationServiceInfo => 'Reservation';

  @override
  String get reservationContactInfo => 'Contact';

  @override
  String get reservationSettlementInfo => 'Settlement';

  @override
  String get reservationOrderInfo => 'Order';

  @override
  String get reservationConsumeAmount => 'Amount spent';

  @override
  String get reservationVerifyTime => 'Verified at';

  @override
  String get reservationPointAmount => 'Points discount';

  @override
  String get reservationPointDeductFailed =>
      'Points deduction failed. Contact the store.';

  @override
  String get reservationOrderNo => 'Order number';

  @override
  String get reservationCreatedAt => 'Submitted at';

  @override
  String reservationCurrency(String amount) {
    return '¥$amount';
  }

  @override
  String get channelComposerReadOnlyHint => 'Only admins can post';

  @override
  String get groupDissolvedComposerReadOnlyHint =>
      'This group was dissolved. You can\'t send messages.';

  @override
  String get channelCreateConfirm => 'Create';

  @override
  String get channelCreateTitle => 'Create channel';

  @override
  String get channelInfoHint =>
      'Channels are one-way broadcasts: only admins can post; subscribers can read and receive notifications.';

  @override
  String get channelSearchTitle => 'Search channels';

  @override
  String get channelSearchHint => 'Type a channel name or paste a channel code';

  @override
  String get channelSearchEmptyHint => 'Type a channel name and press search';

  @override
  String get channelSearchNoResult => 'No channels found';

  @override
  String get channelJoinByCodeTitle => 'Join by channel code';

  @override
  String get channelJoinByCodeHint => 'Enter channel code (e.g. cABC2345)';

  @override
  String get channelJoinConfirm => 'Subscribe';

  @override
  String get channelJoined => 'Subscribed';

  @override
  String get channelInfoHintShort => 'Channel';

  @override
  String get channelShareTitle => 'Share channel';

  @override
  String get channelShareCodeLabel => 'Channel code';

  @override
  String get channelShareLinkLabel => 'Channel link';

  @override
  String get channelQrCodeTitle => 'Channel QR Code';

  @override
  String get channelQrCodeHint => 'Open the app and scan to subscribe';

  @override
  String get channelShareToChat => 'Share to chat';

  @override
  String get channelShareSectionFriends => 'Friends';

  @override
  String get channelShareSectionGroups => 'Groups';

  @override
  String get channelShareSectionChannels => 'Channels';

  @override
  String get channelShareSearchHint => 'Search';

  @override
  String get channelShareEmpty => 'No chats to share to';

  @override
  String get channelShareNoMatch => 'No matching chats';

  @override
  String get shareMediaTitle => 'Send to';

  @override
  String get channelUnsubscribeAction => 'Unsubscribe';

  @override
  String get channelUnsubscribeConfirmTitle => 'Unsubscribe';

  @override
  String get channelUnsubscribeConfirmBody =>
      'You will no longer receive messages from this channel. Unsubscribe?';

  @override
  String get channelEditAction => 'Edit Channel';

  @override
  String get channelEditNameLabel => 'Channel name';

  @override
  String get channelEditAnnouncementLabel => 'Announcement';

  @override
  String get channelEditAnnouncementHint => 'Channel announcement (optional)';

  @override
  String get channelDeleteAction => 'Delete Channel';

  @override
  String get channelDeleteConfirmTitle => 'Delete Channel';

  @override
  String get channelDeleteConfirmBody =>
      'All subscribers will lose access and this cannot be undone. Delete?';

  @override
  String get toastChannelShareCopied => 'Copied — share it with friends';

  @override
  String get toastChannelNotFound => 'Channel not found or dissolved';

  @override
  String get toastChannelUpdated => 'Channel updated';

  @override
  String get toastChannelDeleted => 'Channel deleted';

  @override
  String get toastChannelUnsubscribed => 'Unsubscribed';

  @override
  String get toastEnterChannelName => 'Please enter a channel name';

  @override
  String channelMemberCount(int count) {
    return '$count members';
  }

  @override
  String get channelNameHint => 'Channel name';

  @override
  String get channelRoleOwner => 'Channel admin';

  @override
  String get channelRoleSubscriber => 'Subscriber';

  @override
  String get channelSubtitle => 'Admins only';

  @override
  String chatChannelDefaultTitle(String id) {
    return 'Channel $id';
  }

  @override
  String chatSecretDefaultTitle(String id) {
    return 'Secret chat $id';
  }

  @override
  String get convTypeChannel => 'Channel';

  @override
  String get convTypeGroup => 'Group';

  @override
  String get convTypePrivate => 'Cloud chat';

  @override
  String get convTypeSecret => 'Secret chat';

  @override
  String get featureChannelDisabled => 'Channels are turned off';

  @override
  String get featureSecretChatDisabled => 'Secret chats are turned off';

  @override
  String get secretChatBanner =>
      'End-to-end encrypted · never synced to new devices';

  @override
  String get secretChatRecordingWarning =>
      'Screen recording detected. Please do not share secret chat content.';

  @override
  String get secretChatScreenshotWarning =>
      'Screenshot detected. Please do not share secret chat content.';

  @override
  String get secretChatDestroy1d => '1 day';

  @override
  String get secretChatDestroy1h => '1 hour';

  @override
  String get secretChatDestroy1m => '1 minute';

  @override
  String get secretChatDestroy1s => '1 second';

  @override
  String get secretChatDestroy1w => '1 week';

  @override
  String get secretChatDestroy2s => '2 seconds';

  @override
  String get secretChatDestroy30s => '30 seconds';

  @override
  String get secretChatDestroy5m => '5 minutes';

  @override
  String get secretChatDestroy5s => '5 seconds';

  @override
  String get secretChatDestroy10s => '10 seconds';

  @override
  String get secretChatDestroyOff => 'Off';

  @override
  String get secretChatDestroyTitle => 'Self-destruct timer';

  @override
  String get secretChatNoSyncHint =>
      'Secret chats are visible only on participating devices and never sync to new devices; the server only relays encrypted data.';

  @override
  String get secretChatSafeCodeIntro =>
      'Compare the codes on both devices to verify there is no man-in-the-middle.';

  @override
  String get secretChatSafeCodeTitle => 'Verification code';

  @override
  String get secretChatSafeCodeUnavailable =>
      'Generated automatically once the peer joins — used to verify encryption safety';

  @override
  String get secretChatSettingsTitle => 'Secret chat settings';

  @override
  String get secretChatStartTitle => 'Start secret chat';

  @override
  String get secretChatSubtitle => 'End-to-end encrypted';

  @override
  String get secretChatDeleteTitle => 'Delete secret chat';

  @override
  String get secretChatDeleteBody =>
      'This will remove the secret chat and all of its messages from both devices. This cannot be undone.';

  @override
  String get convTypeSecretGroup => 'Secret group';

  @override
  String get featureSecretGroupChatDisabled => 'Secret groups are turned off';

  @override
  String get secretGroupChatBanner =>
      'End-to-end encrypted · encrypted per member';

  @override
  String get secretGroupChatDefaultTitle => 'Secret group';

  @override
  String get secretGroupChatSettingsTitle => 'Secret group settings';

  @override
  String get secretGroupMembersTitle => 'Members';

  @override
  String get secretGroupChatStartTitle => 'New secret group';

  @override
  String get secretGroupChatSubtitle => 'End-to-end encrypted';

  @override
  String get secretGroupChatDeleteTitle => 'Delete secret group';

  @override
  String get secretGroupChatDeleteBody =>
      'This will remove the secret group chat from this device only.';

  @override
  String get toastSecretGroupChatCreated => 'Secret group created';

  @override
  String get toastChannelCreated => 'Channel created';

  @override
  String get toastChannelUnavailable => 'Channel is unavailable or was deleted';

  @override
  String get toastSecretChatCreated => 'Secret chat created';

  @override
  String get toastSecretChatDestroyUpdated => 'Self-destruct timer updated';

  @override
  String get toastSecretChatSafeCodeCopied => 'Verification code copied';

  @override
  String get toastSecretChatUnavailable =>
      'Secret chat is unavailable or was destroyed';

  @override
  String get toastSecretChatWaitingPeer =>
      'Encrypted messages can be sent once the peer joins';

  @override
  String get selfDestructTitle => 'Auto-clear chat history';

  @override
  String get selfDestructOff => 'Off';

  @override
  String get selfDestruct1mo => '1 month';

  @override
  String get selfDestruct3mo => '3 months';

  @override
  String get selfDestruct6mo => '6 months';

  @override
  String get selfDestruct1yr => '1 year';

  @override
  String get selfDestructHint =>
      'If you don’t sign in for the selected period, all of your chat records will be cleared automatically. Your account itself is kept and you can still sign in.';

  @override
  String get selfDestructUpdated => 'Auto-clear chat history policy updated';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get forgotPasswordTitle => 'Forgot password';

  @override
  String get forgotPasswordEmailHint => 'Enter your email';

  @override
  String get forgotPasswordEmailRequired => 'Please enter your email';

  @override
  String get forgotPasswordEmailInvalid => 'Please enter a valid email address';

  @override
  String get forgotPasswordSubmit => 'Send reset email';

  @override
  String get forgotPasswordSent => 'Email sent';

  @override
  String get resetPasswordTitle => 'Reset password';

  @override
  String get resetPasswordTokenHint => 'Reset token';

  @override
  String get resetPasswordTokenRequired => 'Please enter the reset token';

  @override
  String get resetPasswordNewPasswordHint => 'New password (6-128 characters)';

  @override
  String get resetPasswordPasswordRequired =>
      'New password must be 6-128 characters';

  @override
  String get resetPasswordSubmit => 'Reset password';

  @override
  String get resetPasswordDone => 'Password reset. Please sign in again';

  @override
  String get chatAtMentionYou => '@you';

  @override
  String get chatMuteConversation => 'Mute';

  @override
  String get chatUnmuteConversation => 'Unmute';

  @override
  String get chatDraftPrefix => '[Draft]';

  @override
  String get chatActionFavorite => 'Favorite';

  @override
  String get favoritesTitle => 'Favorites';

  @override
  String get favoritesEmpty => 'No favorites yet';

  @override
  String get favoritesLoadFailed => 'Failed to load';

  @override
  String get favoriteAdded => 'Added to favorites';

  @override
  String get favoriteAddFailed => 'Failed to favorite';

  @override
  String get favoriteRemoved => 'Removed from favorites';

  @override
  String get favoriteRemovedFailed => 'Failed to remove favorite';

  @override
  String get favoritesDetailTitle => 'Favorite details';

  @override
  String get favoritesViewOriginal => 'View original message';

  @override
  String get favoritesSourceMessageDeleted =>
      'The original message was deleted. Only the saved content is available.';

  @override
  String get favoritesSourceConversationUnavailable =>
      'The original conversation is unavailable. Only the saved content is available.';

  @override
  String get favoritesSourceNoPermission =>
      'You no longer have access to the original message. Only the saved content is available.';

  @override
  String get favoritesSourceLookupUnavailable =>
      'Can\'t confirm whether the original message is still available. Please try again later.';

  @override
  String get favoritesSourceConversationMissing =>
      'The original conversation can\'t be located, so it can\'t be opened.';

  @override
  String get favoritesContentEmpty =>
      'No saved content (the original message may have been deleted)';

  @override
  String get favoritesDetailTime => 'Time';

  @override
  String get favoritesFilterAll => 'All';

  @override
  String get favoritesFilterText => 'Text';

  @override
  String get favoritesFilterImage => 'Images';

  @override
  String get favoritesFilterVideo => 'Videos';

  @override
  String get favoritesFilterVoice => 'Voice';

  @override
  String get favoritesFilterFile => 'Files';

  @override
  String get favoritesFilterOther => 'Other';

  @override
  String get favoritesFilterEmpty => 'No favorites of this type';

  @override
  String get favoritesDeleteConfirm => 'Delete this favorite?';

  @override
  String favoritesBatchAdded(int count) {
    return 'Favorited $count messages';
  }

  @override
  String favoritesBatchAddedWithSkipped(int count, int skipped) {
    return 'Favorited $count messages, $skipped already saved';
  }

  @override
  String get favoritesBatchAlreadySaved =>
      'All selected messages were already favorited';

  @override
  String get favoritesBatchEmpty => 'No favoritable messages selected';

  @override
  String get favoritesBatchFailed => 'Failed to favorite';

  @override
  String get reservationChooseStore => 'Choose a store';

  @override
  String get reservationPackageLabel => 'Package';

  @override
  String get reservationTableTypeLabel => 'Seating type';

  @override
  String get reservationExactArrivalTime => 'Arrival time';

  @override
  String get reservationBarStandingPackage => 'Standing table package';

  @override
  String get reservationBarBoothPackage => 'Booth package';

  @override
  String get reservationBarRoomPackage => 'Private room package';

  @override
  String get reservationBilliardsStandardPackage => 'Standard table package';

  @override
  String get reservationBilliardsVipPackage => 'VIP table package';

  @override
  String get reservationBilliardsRoomPackage =>
      'Private billiards room package';

  @override
  String get reservationAreaStanding => 'Standing table';

  @override
  String get reservationAreaBooth => 'Booth';

  @override
  String get reservationAreaRoom => 'Private room';

  @override
  String get reservationAreaStandardTable => 'Standard table';

  @override
  String get reservationAreaVipTable => 'VIP table';

  @override
  String get travelMockNotice =>
      'Frontend demo only. Airports, flights, vehicles, and prices are mock data';

  @override
  String get travelDomestic => 'Domestic';

  @override
  String get travelInternational => 'International';

  @override
  String get travelRoundTrip => 'Round trip';

  @override
  String get travelMultiCity => 'Multi-city';

  @override
  String get travelSpecialFare => 'Special fares';

  @override
  String get travelInstantRide => 'Ride now';

  @override
  String get travelAirportPickup => 'Airport pickup';

  @override
  String get travelAirportDropoff => 'Airport drop-off';

  @override
  String get travelFrom => 'From';

  @override
  String get travelTo => 'To';

  @override
  String get travelSwap => 'Swap departure and arrival';

  @override
  String get travelDepartureDate => 'Departure date';

  @override
  String get travelPickupTime => 'Pickup time';

  @override
  String get travelPassengerCabin => 'Passengers and cabin';

  @override
  String get travelPassengerCount => 'Passengers';

  @override
  String get travelEconomyCabin => 'Economy · 1 adult';

  @override
  String get travelOnePassenger => '1 passenger · 1 bag';

  @override
  String get travelSearchFlights => 'Search flights';

  @override
  String get travelSearchRides => 'Search rides';

  @override
  String get travelSelectAirport => 'Select airport';

  @override
  String get travelSelectLocation => 'Select location';

  @override
  String get travelFlightResultsTitle => 'Flights';

  @override
  String get travelTaxiResultsTitle => 'Available rides';

  @override
  String get travelSmartSort => 'Smart sort';

  @override
  String get travelPriceSort => 'Price';

  @override
  String get travelDepartureSort => 'Departure';

  @override
  String get travelRecommended => 'Recommended';

  @override
  String get travelDirectFlight => 'Direct';

  @override
  String get travelTransfer => 'Transfer';

  @override
  String get travelDuration => 'Duration';

  @override
  String get travelBaggage => '20KG checked baggage included';

  @override
  String get travelRefundable => 'Changes and refunds available';

  @override
  String get travelFlightDetails => 'Flight details';

  @override
  String get travelRideDetails => 'Ride details';

  @override
  String get travelFareOptions => 'Choose a fare';

  @override
  String get travelBook => 'Book';

  @override
  String get travelEstimatedArrival => 'Estimated arrival';

  @override
  String get travelVehicleCapacity => 'Up to 4 passengers · 2 bags';

  @override
  String get travelIncludes => 'Included';

  @override
  String get travelDriverService =>
      'Professional driver · Fixed price · Basic waiting included';

  @override
  String get travelFreeCancellation =>
      'Free cancellation up to 2 hours before departure';

  @override
  String get travelFillOrder => 'Order details';

  @override
  String get travelTripSummary => 'Trip';

  @override
  String get travelPassengerInfo => 'Passenger information';

  @override
  String get travelBookerInfo => 'Booker information';

  @override
  String get travelPassengerName => 'Passenger name';

  @override
  String get travelBookerName => 'Booker name';

  @override
  String get travelIdNumber => 'ID number';

  @override
  String get travelPhone => 'Mobile number';

  @override
  String get travelRemark => 'Note (optional)';

  @override
  String get travelNameRequired => 'Enter a name';

  @override
  String get travelIdRequired => 'Enter an ID number';

  @override
  String get travelPhoneRequired => 'Enter a mobile number';

  @override
  String get travelPhoneInvalid => 'Enter a valid mobile number';

  @override
  String get travelSubmitOrder => 'Submit order';

  @override
  String get travelOrderSuccessTitle => 'Submitted';

  @override
  String get travelOrderSuccessBody =>
      'The order was submitted. This is a frontend demo and no real charge will be made';

  @override
  String get travelOrderNumber => 'Order number';

  @override
  String get travelItinerary => 'Itinerary';

  @override
  String get travelTraveler => 'Booker';

  @override
  String get travelTotal => 'Total';

  @override
  String get travelBackServices => 'Back to services';

  @override
  String get travelShenzhen => 'Shenzhen';

  @override
  String get travelChongqing => 'Chongqing';

  @override
  String get travelGuangzhou => 'Guangzhou';

  @override
  String get travelShanghai => 'Shanghai';

  @override
  String get travelShenzhenAirport =>
      'Shenzhen Bao\'an International Airport T3';

  @override
  String get travelChongqingAirport =>
      'Chongqing Jiangbei International Airport T3';

  @override
  String get travelGuangzhouAirport =>
      'Guangzhou Baiyun International Airport T2';

  @override
  String get travelShanghaiAirport =>
      'Shanghai Hongqiao International Airport T2';

  @override
  String get travelFutianCbd => 'Futian CBD';

  @override
  String get travelShenzhenNorthStation => 'Shenzhen North Railway Station';

  @override
  String get travelNanshanSciencePark => 'Nanshan Science Park';

  @override
  String get travelChinaSouthern => 'China Southern Airlines';

  @override
  String get travelShenzhenAirlines => 'Shenzhen Airlines';

  @override
  String get travelSpringAirlines => 'Spring Airlines';

  @override
  String get travelXiamenAir => 'XiamenAir';

  @override
  String get travelEconomyFlexible => 'Economy Flex';

  @override
  String get travelEconomyValue => 'Economy Saver';

  @override
  String get travelBusinessCabin => 'Business class';

  @override
  String get travelComfortCar => 'Comfort';

  @override
  String get travelBusinessCar => 'Business';

  @override
  String get travelPremiumCar => 'Premium';

  @override
  String get settingsChatStorage => 'Chat history storage';

  @override
  String get chatStorageTotalUsed => 'Local chat storage used';

  @override
  String get chatStorageLocalOnlyNote =>
      'Deletes local records only; cloud data is unaffected';

  @override
  String get chatStorageClear => 'Clear';

  @override
  String get chatStorageClearAll => 'Clear All';

  @override
  String get chatStorageClearAllRecords => 'Clear all records';

  @override
  String get chatStorageClearMediaOnly => 'Clear media cache only';

  @override
  String get chatStorageClearRecordsConfirmTitle => 'Clear all records';

  @override
  String get chatStorageClearRecordsConfirmBody =>
      'Clear all local records in this chat? This deletes local records only and does not affect the cloud.';

  @override
  String get chatStorageClearAllConfirmTitle => 'Clear all';

  @override
  String get chatStorageClearAllConfirmBody =>
      'Clear all local chat history and media cache? This deletes local records only and does not affect the cloud.';

  @override
  String get chatStorageCleared => 'Cleared';

  @override
  String get chatStorageEmpty => 'No local chat history';

  @override
  String get settingsChatBackup => 'Chat history backup & transfer';

  @override
  String get chatBackupExportSectionTitle => 'Back up chat history';

  @override
  String get chatBackupExportDesc =>
      'Export all local chat history of this account to a JSON file. Media is recorded as links (URL / object ID) only, without binaries.';

  @override
  String get chatBackupExportAction => 'Back up to file';

  @override
  String get chatBackupExporting => 'Backing up…';

  @override
  String get chatBackupExportSuccessTitle => 'Backup complete';

  @override
  String chatBackupExportSuccessBody(
      int conversations, int messages, String path) {
    return 'Backed up $conversations conversations and $messages messages. Saved to: $path';
  }

  @override
  String get chatBackupExportFailed => 'Backup failed';

  @override
  String get chatBackupExportEmpty => 'No local chat history to back up';

  @override
  String get chatBackupRestoreSectionTitle => 'Restore chat history';

  @override
  String get chatBackupRestoreDesc =>
      'Restore from a backup file. It merges into this device (deduplicated by message ID).';

  @override
  String get chatBackupRestoreAction => 'Restore from file';

  @override
  String get chatBackupRestoreConfirmTitle => 'Confirm restore';

  @override
  String get chatBackupRestoreConfirmBody =>
      'Restoring overwrite-merges local records (deduplicated by message ID) and cannot be undone. Continue?';

  @override
  String chatBackupRestoreSuccess(int conversations, int messages) {
    return 'Restored $conversations conversations and $messages messages';
  }

  @override
  String get chatBackupRestoreFailed => 'Restore failed';

  @override
  String get chatBackupRestoreInvalid =>
      'The selected file is not a valid chat history backup';

  @override
  String get gvFaGroupAllowMemberViewAccount =>
      'Allow members to view others\' accounts';

  @override
  String get gvFaForgotMethodEmail => 'Email';

  @override
  String get gvFaForgotMethodPhone => 'Phone';

  @override
  String get gvFaForgotMethodSecurityQuestion => 'Security question';

  @override
  String get gvFaForgotPhoneHint => 'Enter your phone number';

  @override
  String get gvFaForgotPhoneRequired => 'Please enter your phone number';

  @override
  String get gvFaForgotPhoneInvalid => 'Please enter a valid phone number';

  @override
  String get gvFaForgotSendSmsCode => 'Send SMS code';

  @override
  String get gvFaForgotSmsCodeSent => 'Verification code sent';

  @override
  String get gvFaResetMethodToken => 'Reset token (email)';

  @override
  String get gvFaResetMethodSms => 'SMS code';

  @override
  String get gvFaResetMethodSecurityQuestion => 'Security question';

  @override
  String get gvFaResetPhoneHint => 'Phone number';

  @override
  String get gvFaResetPhoneRequired => 'Please enter your phone number';

  @override
  String get gvFaResetSmsCodeHint => 'SMS verification code';

  @override
  String get gvFaResetSmsCodeRequired => 'Please enter the verification code';

  @override
  String get gvFaResetUsernameHint => 'Username';

  @override
  String get gvFaResetUsernameRequired => 'Please enter your username';

  @override
  String get gvFaResetSecurityQuestionHint => 'Security question';

  @override
  String get gvFaResetSecurityQuestionRequired =>
      'Please enter your security question';

  @override
  String get gvFaResetSecurityAnswerHint => 'Security answer';

  @override
  String get gvFaResetSecurityAnswerRequired =>
      'Please enter your security answer';

  @override
  String get gvFaDeviceManagementTitle => 'Logged-in devices';

  @override
  String get gvFaDeviceManagementEntry => 'Logged-in devices';

  @override
  String gvFaDeviceLoginMethod(String method) {
    return 'Login method: $method';
  }

  @override
  String gvFaDeviceLoginIp(String ip) {
    return 'Login IP: $ip';
  }

  @override
  String gvFaDeviceType(String type) {
    return 'Device type: $type';
  }

  @override
  String gvFaDeviceLastActive(String time) {
    return 'Last active: $time';
  }

  @override
  String gvFaDeviceStatus(String status) {
    return 'Status: $status';
  }

  @override
  String get gvFaDeviceKick => 'Kick out';

  @override
  String get gvFaDeviceLogout => 'Log out';

  @override
  String get gvFaDeviceKickConfirm => 'Kick out this device?';

  @override
  String get gvFaDeviceLogoutConfirm => 'Log out of this device?';

  @override
  String get gvFaDeviceEmpty => 'No logged-in devices';

  @override
  String get gvFaDeviceLoadFailed => 'Failed to load devices';

  @override
  String get gvFaDeviceStatusActive => 'Online';

  @override
  String get gvFaDeviceStatusKicked => 'Kicked out';

  @override
  String get gvFaDeviceStatusLogout => 'Logged out';

  @override
  String get gvFaLoginMethodPassword => 'Password';

  @override
  String get gvFaLoginMethodQrCode => 'QR code';

  @override
  String get gvFaLoginMethodSso => 'SSO';

  @override
  String get gvFaLoginMethodVerificationCode => 'SMS code';

  @override
  String get gvMbEdited => 'Edited';

  @override
  String get gvMbEditAction => 'Edit';

  @override
  String get gvMbEditMessage => 'Edit message';

  @override
  String get gvMbEditSave => 'Save';

  @override
  String get gvMbEditSuccess => 'Edited';

  @override
  String get gvMbMentionAll => 'All members';
}
