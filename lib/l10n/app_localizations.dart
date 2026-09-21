import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'WV Chat'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Secure, fast messaging'**
  String get appSubtitle;

  /// No description provided for @tabMessages.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get tabMessages;

  /// No description provided for @tabContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get tabContacts;

  /// No description provided for @tabServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get tabServices;

  /// No description provided for @tabMe.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get tabMe;

  /// No description provided for @addFriendTitle.
  ///
  /// In en, this message translates to:
  /// **'Add friend'**
  String get addFriendTitle;

  /// No description provided for @startGroupChatTitle.
  ///
  /// In en, this message translates to:
  /// **'New group chat'**
  String get startGroupChatTitle;

  /// No description provided for @scanQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scanQrTitle;

  /// No description provided for @scanSemanticsViewfinder.
  ///
  /// In en, this message translates to:
  /// **'Scan area. Point a friend code or mini program code at the frame.'**
  String get scanSemanticsViewfinder;

  /// No description provided for @scanHintPlaceCodeInFrame.
  ///
  /// In en, this message translates to:
  /// **'Place the friend or mini program code inside the frame'**
  String get scanHintPlaceCodeInFrame;

  /// No description provided for @scanFlashlight.
  ///
  /// In en, this message translates to:
  /// **'Flashlight'**
  String get scanFlashlight;

  /// No description provided for @scanFriendRequestDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Friend request'**
  String get scanFriendRequestDialogTitle;

  /// No description provided for @scanFriendRequestDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Send a friend request to {username}?'**
  String scanFriendRequestDialogBody(String username);

  /// No description provided for @scanErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get scanErrorUserNotFound;

  /// No description provided for @scanErrorCannotAddSelf.
  ///
  /// In en, this message translates to:
  /// **'You can’t add yourself'**
  String get scanErrorCannotAddSelf;

  /// No description provided for @scanErrorAlreadyFriend.
  ///
  /// In en, this message translates to:
  /// **'Already friends with this user'**
  String get scanErrorAlreadyFriend;

  /// No description provided for @scanFriendRequestNote.
  ///
  /// In en, this message translates to:
  /// **'Added via scan'**
  String get scanFriendRequestNote;

  /// No description provided for @scanFriendRequestNoteWithNick.
  ///
  /// In en, this message translates to:
  /// **'Added via scan ({nick})'**
  String scanFriendRequestNoteWithNick(String nick);

  /// No description provided for @scanPickQrImage.
  ///
  /// In en, this message translates to:
  /// **'Choose QR image'**
  String get scanPickQrImage;

  /// No description provided for @scanWebCameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera scanning isn’t available (use HTTPS or localhost and allow camera access). You can pick an image that contains a QR code below.'**
  String get scanWebCameraUnavailable;

  /// No description provided for @scanNoQrFoundInImage.
  ///
  /// In en, this message translates to:
  /// **'No QR code found in the image'**
  String get scanNoQrFoundInImage;

  /// No description provided for @scanCouldNotReadImage.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t read the selected image'**
  String get scanCouldNotReadImage;

  /// No description provided for @scanUnsupportedQrCode.
  ///
  /// In en, this message translates to:
  /// **'This QR code isn\'t supported'**
  String get scanUnsupportedQrCode;

  /// No description provided for @tabBadgeUnread.
  ///
  /// In en, this message translates to:
  /// **'{count} unread messages'**
  String tabBadgeUnread(int count);

  /// No description provided for @tabBadgeDot.
  ///
  /// In en, this message translates to:
  /// **'New activity'**
  String get tabBadgeDot;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @profileMyQrCode.
  ///
  /// In en, this message translates to:
  /// **'My QR code'**
  String get profileMyQrCode;

  /// No description provided for @profileSaveQrCode.
  ///
  /// In en, this message translates to:
  /// **'Save QR code'**
  String get profileSaveQrCode;

  /// No description provided for @settingsProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfile;

  /// No description provided for @settingsChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get settingsChangePassword;

  /// No description provided for @settingsCheckUpdate.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get settingsCheckUpdate;

  /// No description provided for @settingsVersionCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current version'**
  String get settingsVersionCurrent;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsNotifyDetail.
  ///
  /// In en, this message translates to:
  /// **'Offline push notifications'**
  String get settingsNotifyDetail;

  /// No description provided for @settingsNotifyPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private chat offline push'**
  String get settingsNotifyPrivate;

  /// No description provided for @settingsNotifyGroup.
  ///
  /// In en, this message translates to:
  /// **'Group offline push'**
  String get settingsNotifyGroup;

  /// No description provided for @settingsNotifyChannel.
  ///
  /// In en, this message translates to:
  /// **'Channel offline push'**
  String get settingsNotifyChannel;

  /// No description provided for @settingsAllowGroupFriendRequest.
  ///
  /// In en, this message translates to:
  /// **'Allow group members to add me'**
  String get settingsAllowGroupFriendRequest;

  /// No description provided for @settingsHideGroupMemberInfo.
  ///
  /// In en, this message translates to:
  /// **'Group member privacy'**
  String get settingsHideGroupMemberInfo;

  /// No description provided for @settingsHideGroupMemberInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hide usernames and avatars of members who aren\'t your friends'**
  String get settingsHideGroupMemberInfoSubtitle;

  /// No description provided for @appAppearanceLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appAppearanceLight;

  /// No description provided for @appAppearanceDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appAppearanceDark;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Follow system, Chinese, or English'**
  String get settingsLanguageSubtitle;

  /// No description provided for @langFollowSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get langFollowSystem;

  /// No description provided for @langChinese.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get langChinese;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @settingsLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get settingsLogout;

  /// No description provided for @settingsLogoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get settingsLogoutConfirmTitle;

  /// No description provided for @settingsLogoutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get settingsLogoutConfirmBody;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteAccountNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you delete your account'**
  String get settingsDeleteAccountNoticeTitle;

  /// No description provided for @settingsDeleteAccountNoticeBody.
  ///
  /// In en, this message translates to:
  /// **'Your account will be deactivated immediately. You will not be able to sign in again with this username and password. Your username may become available for others to register. Chat history and other data may remain on the server. This cannot be undone.'**
  String get settingsDeleteAccountNoticeBody;

  /// No description provided for @settingsDeleteAccountNoticeConfirm.
  ///
  /// In en, this message translates to:
  /// **'I understand, continue'**
  String get settingsDeleteAccountNoticeConfirm;

  /// No description provided for @settingsDeleteAccountPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify password'**
  String get settingsDeleteAccountPasswordTitle;

  /// No description provided for @settingsDeleteAccountPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password'**
  String get settingsDeleteAccountPasswordHint;

  /// No description provided for @settingsDeleteAccountSubmit.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccountSubmit;

  /// No description provided for @toastDeleteAccountSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted'**
  String get toastDeleteAccountSuccess;

  /// No description provided for @loginUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get loginUsernameHint;

  /// No description provided for @loginPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordHint;

  /// No description provided for @loginUsernamePasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter username and password'**
  String get loginUsernamePasswordRequired;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginButton;

  /// No description provided for @loginLoading.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get loginLoading;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'No account yet?'**
  String get loginNoAccount;

  /// No description provided for @loginRegister.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get loginRegister;

  /// No description provided for @authAgreementPrefix.
  ///
  /// In en, this message translates to:
  /// **'I have read and agree to the '**
  String get authAgreementPrefix;

  /// No description provided for @authAgreementUserTerms.
  ///
  /// In en, this message translates to:
  /// **'User Agreement'**
  String get authAgreementUserTerms;

  /// No description provided for @authAgreementAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get authAgreementAnd;

  /// No description provided for @authAgreementPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get authAgreementPrivacy;

  /// No description provided for @authAgreementRequired.
  ///
  /// In en, this message translates to:
  /// **'Please read and agree to the User Agreement and Privacy Policy'**
  String get authAgreementRequired;

  /// No description provided for @updateChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates…'**
  String get updateChecking;

  /// No description provided for @updateUpToDate.
  ///
  /// In en, this message translates to:
  /// **'You\'re on the latest version'**
  String get updateUpToDate;

  /// No description provided for @updateNoReleaseInfo.
  ///
  /// In en, this message translates to:
  /// **'No release information'**
  String get updateNoReleaseInfo;

  /// No description provided for @updateMandatoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get updateMandatoryTitle;

  /// No description provided for @updateSuggestTitle.
  ///
  /// In en, this message translates to:
  /// **'New version (recommended)'**
  String get updateSuggestTitle;

  /// No description provided for @updateNewVersionTitle.
  ///
  /// In en, this message translates to:
  /// **'New version'**
  String get updateNewVersionTitle;

  /// No description provided for @updateNoNotes.
  ///
  /// In en, this message translates to:
  /// **'No release notes'**
  String get updateNoNotes;

  /// No description provided for @updateLatestVersionLine.
  ///
  /// In en, this message translates to:
  /// **'Latest: {versionName} (build {versionCode})'**
  String updateLatestVersionLine(String versionName, int versionCode);

  /// No description provided for @updateNoDownloadUrl.
  ///
  /// In en, this message translates to:
  /// **'No download URL configured. Contact admin.'**
  String get updateNoDownloadUrl;

  /// No description provided for @updateInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid download URL'**
  String get updateInvalidUrl;

  /// No description provided for @updateCannotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get updateCannotOpenLink;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNow;

  /// No description provided for @updateDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading update…'**
  String get updateDownloading;

  /// No description provided for @updateDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed: {message}'**
  String updateDownloadFailed(String message);

  /// No description provided for @updateReadyToInstallTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to install'**
  String get updateReadyToInstallTitle;

  /// No description provided for @updateReadyToInstallBody.
  ///
  /// In en, this message translates to:
  /// **'The installer has been downloaded. Tap OK to close the app; it will reopen when installation finishes.'**
  String get updateReadyToInstallBody;

  /// No description provided for @updateInstallSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Update installed successfully.'**
  String get updateInstallSucceeded;

  /// No description provided for @updateInstallFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get updateInstallFailedTitle;

  /// No description provided for @commonNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get commonNetworkError;

  /// No description provided for @routeInvalidArguments.
  ///
  /// In en, this message translates to:
  /// **'Invalid page parameters'**
  String get routeInvalidArguments;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get commonDownload;

  /// No description provided for @commonShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonShare;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report {name}'**
  String reportTitle(String name);

  /// No description provided for @reportReasonObscene.
  ///
  /// In en, this message translates to:
  /// **'Sexual or vulgar content'**
  String get reportReasonObscene;

  /// No description provided for @reportReasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment or abuse'**
  String get reportReasonHarassment;

  /// No description provided for @reportReasonScam.
  ///
  /// In en, this message translates to:
  /// **'Spam or fraud'**
  String get reportReasonScam;

  /// No description provided for @reportReasonPolitical.
  ///
  /// In en, this message translates to:
  /// **'Sensitive political content'**
  String get reportReasonPolitical;

  /// No description provided for @reportReasonIllegal.
  ///
  /// In en, this message translates to:
  /// **'Illegal content'**
  String get reportReasonIllegal;

  /// No description provided for @reportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reportReasonOther;

  /// No description provided for @reportPickReason.
  ///
  /// In en, this message translates to:
  /// **'Please select a reason'**
  String get reportPickReason;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. We’ll review it soon.'**
  String get reportSubmitted;

  /// No description provided for @reportFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t submit report. Try again later.'**
  String get reportFailed;

  /// No description provided for @reportDescHint.
  ///
  /// In en, this message translates to:
  /// **'Details (optional)'**
  String get reportDescHint;

  /// No description provided for @reportSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get reportSubmit;

  /// No description provided for @mapChooseApp.
  ///
  /// In en, this message translates to:
  /// **'Open in maps'**
  String get mapChooseApp;

  /// No description provided for @mapAppleMaps.
  ///
  /// In en, this message translates to:
  /// **'Apple Maps'**
  String get mapAppleMaps;

  /// No description provided for @mapGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Google Maps'**
  String get mapGoogleMaps;

  /// No description provided for @mapAmap.
  ///
  /// In en, this message translates to:
  /// **'Amap'**
  String get mapAmap;

  /// No description provided for @mapOpenInExternalApp.
  ///
  /// In en, this message translates to:
  /// **'Open in maps app'**
  String get mapOpenInExternalApp;

  /// No description provided for @chatFileDownloadExplain.
  ///
  /// In en, this message translates to:
  /// **'The file will be saved to this app’s documents folder. You can open it from the system file manager.'**
  String get chatFileDownloadExplain;

  /// No description provided for @chatFileSavedToast.
  ///
  /// In en, this message translates to:
  /// **'Saved to app documents'**
  String get chatFileSavedToast;

  /// No description provided for @chatFileDownloadFailedToast.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get chatFileDownloadFailedToast;

  /// No description provided for @miniProgramTitle.
  ///
  /// In en, this message translates to:
  /// **'Mini program'**
  String get miniProgramTitle;

  /// No description provided for @miniProgramNoIntro.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get miniProgramNoIntro;

  /// No description provided for @miniProgramViewFullIntro.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get miniProgramViewFullIntro;

  /// No description provided for @miniProgramShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get miniProgramShare;

  /// No description provided for @miniProgramReenter.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get miniProgramReenter;

  /// No description provided for @miniProgramAppIntro.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get miniProgramAppIntro;

  /// No description provided for @miniProgramWebUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Built-in browser isn’t supported here'**
  String get miniProgramWebUnsupported;

  /// No description provided for @miniProgramCannotOpenUrl.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t open mini program link'**
  String get miniProgramCannotOpenUrl;

  /// No description provided for @miniProgramLoadSlow.
  ///
  /// In en, this message translates to:
  /// **'Loading slowly — page is shown'**
  String get miniProgramLoadSlow;

  /// No description provided for @composerHint.
  ///
  /// In en, this message translates to:
  /// **'Message…'**
  String get composerHint;

  /// No description provided for @composerHoldToTalk.
  ///
  /// In en, this message translates to:
  /// **'Hold to talk'**
  String get composerHoldToTalk;

  /// No description provided for @bannerNewMessage.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get bannerNewMessage;

  /// No description provided for @toastQrSaveNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Saving to gallery isn’t supported on this platform'**
  String get toastQrSaveNotSupported;

  /// No description provided for @toastSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed'**
  String get toastSearchFailed;

  /// No description provided for @toastLoadMoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load more'**
  String get toastLoadMoreFailed;

  /// No description provided for @toastChatHistoryFriendsOnly.
  ///
  /// In en, this message translates to:
  /// **'Only friends can view chat history'**
  String get toastChatHistoryFriendsOnly;

  /// No description provided for @toastChatHistoryGroupOnly.
  ///
  /// In en, this message translates to:
  /// **'Only group members can view chat history'**
  String get toastChatHistoryGroupOnly;

  /// No description provided for @featurePrivateChatDisabled.
  ///
  /// In en, this message translates to:
  /// **'Direct messages are turned off'**
  String get featurePrivateChatDisabled;

  /// No description provided for @featureGroupChatDisabled.
  ///
  /// In en, this message translates to:
  /// **'Group chat is turned off'**
  String get featureGroupChatDisabled;

  /// No description provided for @toastMessageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Message not found'**
  String get toastMessageNotFound;

  /// No description provided for @toastMicPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is required to send voice'**
  String get toastMicPermissionRequired;

  /// No description provided for @toastVoiceRecordStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t start recording: {error}'**
  String toastVoiceRecordStartFailed(String error);

  /// No description provided for @toastVoiceWebNoEncoder.
  ///
  /// In en, this message translates to:
  /// **'This browser doesn’t support voice recording (no audio encoder).'**
  String get toastVoiceWebNoEncoder;

  /// No description provided for @toastFileExceedsLimit.
  ///
  /// In en, this message translates to:
  /// **'File exceeds limit ({mb} MB)'**
  String toastFileExceedsLimit(int mb);

  /// No description provided for @toastFilePickReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t read the selected file, please try again'**
  String get toastFilePickReadFailed;

  /// No description provided for @toastMapTilesNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Map isn’t configured; can’t send location'**
  String get toastMapTilesNotConfigured;

  /// No description provided for @toastVideoCallDisabled.
  ///
  /// In en, this message translates to:
  /// **'Video calls are turned off'**
  String get toastVideoCallDisabled;

  /// No description provided for @toastVoiceCallDisabled.
  ///
  /// In en, this message translates to:
  /// **'Voice calls are turned off'**
  String get toastVoiceCallDisabled;

  /// No description provided for @toastCannotCallSelf.
  ///
  /// In en, this message translates to:
  /// **'You can’t call yourself'**
  String get toastCannotCallSelf;

  /// No description provided for @toastAlreadyInCall.
  ///
  /// In en, this message translates to:
  /// **'Already in a call'**
  String get toastAlreadyInCall;

  /// No description provided for @toastStickerAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to stickers'**
  String get toastStickerAdded;

  /// No description provided for @toastCouponsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coupons coming soon'**
  String get toastCouponsComingSoon;

  /// No description provided for @toastServiceNoUrl.
  ///
  /// In en, this message translates to:
  /// **'This service has no URL configured'**
  String get toastServiceNoUrl;

  /// No description provided for @toastFillNickname.
  ///
  /// In en, this message translates to:
  /// **'Enter a display name'**
  String get toastFillNickname;

  /// No description provided for @toastProfileSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get toastProfileSaved;

  /// No description provided for @toastMiniProgramNoShare.
  ///
  /// In en, this message translates to:
  /// **'This mini program can’t share a code yet'**
  String get toastMiniProgramNoShare;

  /// No description provided for @toastEnterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password'**
  String get toastEnterCurrentPassword;

  /// No description provided for @toastNewPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'New password must be at least 6 characters'**
  String get toastNewPasswordMinLength;

  /// No description provided for @toastNewPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'New passwords don’t match'**
  String get toastNewPasswordMismatch;

  /// No description provided for @toastPasswordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get toastPasswordUpdated;

  /// No description provided for @toastMembersAdded.
  ///
  /// In en, this message translates to:
  /// **'Members added'**
  String get toastMembersAdded;

  /// No description provided for @toastMiniProgramNotFound.
  ///
  /// In en, this message translates to:
  /// **'Mini program not found'**
  String get toastMiniProgramNotFound;

  /// No description provided for @toastMiniProgramNoEntry.
  ///
  /// In en, this message translates to:
  /// **'Mini program has no entry URL'**
  String get toastMiniProgramNoEntry;

  /// No description provided for @toastScanFriendOrMiniCode.
  ///
  /// In en, this message translates to:
  /// **'Scan a friend or mini program code'**
  String get toastScanFriendOrMiniCode;

  /// No description provided for @toastScanFriendCode.
  ///
  /// In en, this message translates to:
  /// **'Scan a friend code'**
  String get toastScanFriendCode;

  /// No description provided for @toastFriendRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get toastFriendRequestSent;

  /// No description provided for @toastGroupChatCleared.
  ///
  /// In en, this message translates to:
  /// **'Local group chat history cleared'**
  String get toastGroupChatCleared;

  /// No description provided for @toastGroupDissolved.
  ///
  /// In en, this message translates to:
  /// **'The group has been dissolved'**
  String get toastGroupDissolved;

  /// No description provided for @chatPeerUnavailableToast.
  ///
  /// In en, this message translates to:
  /// **'Not a contact or this group no longer exists'**
  String get chatPeerUnavailableToast;

  /// No description provided for @groupOwnerWelcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get groupOwnerWelcomeMessage;

  /// No description provided for @groupOwnerBadge.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get groupOwnerBadge;

  /// No description provided for @groupAutoMessageDissolved.
  ///
  /// In en, this message translates to:
  /// **'This group has been dissolved'**
  String get groupAutoMessageDissolved;

  /// No description provided for @toastOperationFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong: {error}'**
  String toastOperationFailed(String error);

  /// No description provided for @toastEnterGroupName.
  ///
  /// In en, this message translates to:
  /// **'Enter a group name'**
  String get toastEnterGroupName;

  /// No description provided for @toastForwarded.
  ///
  /// In en, this message translates to:
  /// **'Forwarded'**
  String get toastForwarded;

  /// No description provided for @toastSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get toastSent;

  /// No description provided for @toastFriendRequestSentDetail.
  ///
  /// In en, this message translates to:
  /// **'Friend request sent'**
  String get toastFriendRequestSentDetail;

  /// No description provided for @toastPrivateChatCleared.
  ///
  /// In en, this message translates to:
  /// **'Local chat history cleared'**
  String get toastPrivateChatCleared;

  /// No description provided for @toastAvatarCropFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t crop: {error}'**
  String toastAvatarCropFailed(String error);

  /// No description provided for @toastImageSavedToDocuments.
  ///
  /// In en, this message translates to:
  /// **'Saved to app documents'**
  String get toastImageSavedToDocuments;

  /// No description provided for @toastImageSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed. Check your network'**
  String get toastImageSaveFailed;

  /// No description provided for @errorLocationServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are off'**
  String get errorLocationServiceDisabled;

  /// No description provided for @errorLocationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get errorLocationPermissionDenied;

  /// No description provided for @toastRetryShort.
  ///
  /// In en, this message translates to:
  /// **'Please try again shortly'**
  String get toastRetryShort;

  /// No description provided for @toastImageGenerateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t create image'**
  String get toastImageGenerateFailed;

  /// No description provided for @toastGalleryPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Photo library access is required to save'**
  String get toastGalleryPermissionRequired;

  /// No description provided for @toastSavedToGallery.
  ///
  /// In en, this message translates to:
  /// **'Saved to Photos'**
  String get toastSavedToGallery;

  /// No description provided for @toastSaveFailedShort.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get toastSaveFailedShort;

  /// No description provided for @galErrorAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'No photo library access'**
  String get galErrorAccessDenied;

  /// No description provided for @galErrorNotEnoughSpace.
  ///
  /// In en, this message translates to:
  /// **'Not enough storage space'**
  String get galErrorNotEnoughSpace;

  /// No description provided for @galErrorUnsupportedFormat.
  ///
  /// In en, this message translates to:
  /// **'Unsupported image format'**
  String get galErrorUnsupportedFormat;

  /// No description provided for @galErrorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save. Allow Photos access in Settings → Privacy.'**
  String get galErrorUnexpected;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @displayUserIdLabel.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String displayUserIdLabel(String id);

  /// No description provided for @contactDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactDetailTitle;

  /// No description provided for @contactAccountLine.
  ///
  /// In en, this message translates to:
  /// **'Account: {account}'**
  String contactAccountLine(String account);

  /// No description provided for @contactSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get contactSendMessage;

  /// No description provided for @contactRemarkLabel.
  ///
  /// In en, this message translates to:
  /// **'Remark'**
  String get contactRemarkLabel;

  /// No description provided for @contactRemarkNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get contactRemarkNotSet;

  /// No description provided for @contactRecommendToFriends.
  ///
  /// In en, this message translates to:
  /// **'Recommend to friends'**
  String get contactRecommendToFriends;

  /// No description provided for @chatHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat history'**
  String get chatHistoryTitle;

  /// No description provided for @contactClearChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear chat history'**
  String get contactClearChatTitle;

  /// No description provided for @chatClearAlsoDeleteServer.
  ///
  /// In en, this message translates to:
  /// **'Also delete on server'**
  String get chatClearAlsoDeleteServer;

  /// No description provided for @chatDeleteForMe.
  ///
  /// In en, this message translates to:
  /// **'Delete for me'**
  String get chatDeleteForMe;

  /// No description provided for @chatDeleteForEveryone.
  ///
  /// In en, this message translates to:
  /// **'Delete for everyone'**
  String get chatDeleteForEveryone;

  /// No description provided for @chatMultiSelect.
  ///
  /// In en, this message translates to:
  /// **'Multi-select'**
  String get chatMultiSelect;

  /// No description provided for @chatMultiSelectCount.
  ///
  /// In en, this message translates to:
  /// **'Selected {count}'**
  String chatMultiSelectCount(Object count);

  /// No description provided for @chatDeleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get chatDeleteSelected;

  /// No description provided for @contactClearChatConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Clear this chat on this device? This only affects the current account on this device and does not delete the other person’s or server history.'**
  String get contactClearChatConfirmBody;

  /// No description provided for @contactClearChatRow.
  ///
  /// In en, this message translates to:
  /// **'Clear local chat history'**
  String get contactClearChatRow;

  /// No description provided for @contactBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get contactBlockTitle;

  /// No description provided for @contactBlockConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Block this contact?'**
  String get contactBlockConfirmBody;

  /// No description provided for @contactBlockAction.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get contactBlockAction;

  /// No description provided for @contactDeleteFriendTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete friend'**
  String get contactDeleteFriendTitle;

  /// No description provided for @contactDeleteFriendConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Remove this friend? Chat history will stay on your device.'**
  String get contactDeleteFriendConfirmBody;

  /// No description provided for @contactDeleteFriendAction.
  ///
  /// In en, this message translates to:
  /// **'Delete friend'**
  String get contactDeleteFriendAction;

  /// No description provided for @contactReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get contactReport;

  /// No description provided for @contactUnblockTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from blocklist'**
  String get contactUnblockTitle;

  /// No description provided for @contactUnblockConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Remove this contact from the blocklist?'**
  String get contactUnblockConfirmBody;

  /// No description provided for @contactUnblockAction.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get contactUnblockAction;

  /// No description provided for @blacklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Blocked List'**
  String get blacklistTitle;

  /// No description provided for @blacklistEmpty.
  ///
  /// In en, this message translates to:
  /// **'No blocked friends'**
  String get blacklistEmpty;

  /// No description provided for @blacklistLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get blacklistLoadFailed;

  /// No description provided for @settingsBlacklist.
  ///
  /// In en, this message translates to:
  /// **'Blocked list'**
  String get settingsBlacklist;

  /// No description provided for @friendGroupsTitle.
  ///
  /// In en, this message translates to:
  /// **'Friend Groups'**
  String get friendGroupsTitle;

  /// No description provided for @friendGroupCreate.
  ///
  /// In en, this message translates to:
  /// **'New Group'**
  String get friendGroupCreate;

  /// No description provided for @friendGroupNoGroup.
  ///
  /// In en, this message translates to:
  /// **'No group'**
  String get friendGroupNoGroup;

  /// No description provided for @setFriendGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set group'**
  String get setFriendGroupTitle;

  /// No description provided for @friendGroupNameHint.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get friendGroupNameHint;

  /// No description provided for @friendGroupEmpty.
  ///
  /// In en, this message translates to:
  /// **'No groups'**
  String get friendGroupEmpty;

  /// No description provided for @friendGroupMemberCount.
  ///
  /// In en, this message translates to:
  /// **'{count} friends'**
  String friendGroupMemberCount(int count);

  /// No description provided for @friendGroupCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Group created'**
  String get friendGroupCreateSuccess;

  /// No description provided for @friendGroupCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create group'**
  String get friendGroupCreateFailed;

  /// No description provided for @friendGroupRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get friendGroupRename;

  /// No description provided for @friendGroupDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get friendGroupDelete;

  /// No description provided for @friendGroupDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Friends in this group will become ungrouped.'**
  String get friendGroupDeleteConfirm;

  /// No description provided for @friendGroupRenameSuccess.
  ///
  /// In en, this message translates to:
  /// **'Group renamed'**
  String get friendGroupRenameSuccess;

  /// No description provided for @friendGroupDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Group deleted'**
  String get friendGroupDeleteSuccess;

  /// No description provided for @contactVoiceCall.
  ///
  /// In en, this message translates to:
  /// **'Voice call'**
  String get contactVoiceCall;

  /// No description provided for @contactVideoCall.
  ///
  /// In en, this message translates to:
  /// **'Video call'**
  String get contactVideoCall;

  /// No description provided for @contactRemarkEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit remark'**
  String get contactRemarkEditTitle;

  /// No description provided for @contactRemarkHint.
  ///
  /// In en, this message translates to:
  /// **'Remark name'**
  String get contactRemarkHint;

  /// No description provided for @addFriendSearchFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Search by username or phone'**
  String get addFriendSearchFieldHint;

  /// No description provided for @addFriendSearchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Search by username or phone number'**
  String get addFriendSearchPrompt;

  /// No description provided for @addFriendNoUsers.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get addFriendNoUsers;

  /// No description provided for @addFriendAlreadyFriends.
  ///
  /// In en, this message translates to:
  /// **'Already friends'**
  String get addFriendAlreadyFriends;

  /// No description provided for @addFriendRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get addFriendRequestSent;

  /// No description provided for @addFriendAction.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addFriendAction;

  /// No description provided for @groupChatDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Group chat'**
  String get groupChatDefaultName;

  /// No description provided for @groupClearHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear group chat history'**
  String get groupClearHistoryTitle;

  /// No description provided for @groupClearHistoryConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Clear this group chat on this device? This only affects the current account on this device and does not delete other members’ or server history.'**
  String get groupClearHistoryConfirmBody;

  /// No description provided for @groupClearHistoryRow.
  ///
  /// In en, this message translates to:
  /// **'Clear local chat history'**
  String get groupClearHistoryRow;

  /// No description provided for @groupDissolveAction.
  ///
  /// In en, this message translates to:
  /// **'Dissolve group'**
  String get groupDissolveAction;

  /// No description provided for @groupMuteAction.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get groupMuteAction;

  /// No description provided for @groupMute10Minutes.
  ///
  /// In en, this message translates to:
  /// **'Mute 10 min'**
  String get groupMute10Minutes;

  /// No description provided for @groupMute1Hour.
  ///
  /// In en, this message translates to:
  /// **'Mute 1 hour'**
  String get groupMute1Hour;

  /// No description provided for @groupMute1Day.
  ///
  /// In en, this message translates to:
  /// **'Mute 1 day'**
  String get groupMute1Day;

  /// No description provided for @groupUnmuteAction.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get groupUnmuteAction;

  /// No description provided for @groupSetAdminAction.
  ///
  /// In en, this message translates to:
  /// **'Set as admin'**
  String get groupSetAdminAction;

  /// No description provided for @groupUnsetAdminAction.
  ///
  /// In en, this message translates to:
  /// **'Remove admin'**
  String get groupUnsetAdminAction;

  /// No description provided for @groupMuteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get groupMuteSuccess;

  /// No description provided for @groupUnmuteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Unmuted'**
  String get groupUnmuteSuccess;

  /// No description provided for @groupSetAdminSuccess.
  ///
  /// In en, this message translates to:
  /// **'Promoted to admin'**
  String get groupSetAdminSuccess;

  /// No description provided for @groupUnsetAdminSuccess.
  ///
  /// In en, this message translates to:
  /// **'Removed admin'**
  String get groupUnsetAdminSuccess;

  /// No description provided for @groupLeaveAction.
  ///
  /// In en, this message translates to:
  /// **'Leave group'**
  String get groupLeaveAction;

  /// No description provided for @groupDissolveConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Dissolve this group?'**
  String get groupDissolveConfirmBody;

  /// No description provided for @groupLeaveConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Leave this group?'**
  String get groupLeaveConfirmBody;

  /// No description provided for @groupShowAllMembers.
  ///
  /// In en, this message translates to:
  /// **'View all {count} members'**
  String groupShowAllMembers(int count);

  /// No description provided for @groupCollapseMembers.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get groupCollapseMembers;

  /// No description provided for @groupEditNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit group name'**
  String get groupEditNameTitle;

  /// No description provided for @groupNameFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupNameFieldHint;

  /// No description provided for @groupAnnouncementViewEmpty.
  ///
  /// In en, this message translates to:
  /// **'No announcement'**
  String get groupAnnouncementViewEmpty;

  /// No description provided for @groupAnnouncementRowPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get groupAnnouncementRowPlaceholder;

  /// No description provided for @groupAnnouncementLabel.
  ///
  /// In en, this message translates to:
  /// **'Announcement'**
  String get groupAnnouncementLabel;

  /// No description provided for @groupNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupNameLabel;

  /// No description provided for @groupEditAnnouncementTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit announcement'**
  String get groupEditAnnouncementTitle;

  /// No description provided for @groupAnnouncementFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Announcement (optional)'**
  String get groupAnnouncementFieldHint;

  /// No description provided for @groupRemoveMemberConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\" from the group?'**
  String groupRemoveMemberConfirm(String name);

  /// No description provided for @groupRemoveMemberAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get groupRemoveMemberAction;

  /// No description provided for @groupMemberLongPressRemoveHint.
  ///
  /// In en, this message translates to:
  /// **', long-press to remove'**
  String get groupMemberLongPressRemoveHint;

  /// No description provided for @groupInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get groupInvite;

  /// No description provided for @groupAllowMemberInvite.
  ///
  /// In en, this message translates to:
  /// **'Allow members to invite'**
  String get groupAllowMemberInvite;

  /// No description provided for @groupAllowMemberFriendRequest.
  ///
  /// In en, this message translates to:
  /// **'Allow members to add each other'**
  String get groupAllowMemberFriendRequest;

  /// No description provided for @groupMemberFriendRequestDisabled.
  ///
  /// In en, this message translates to:
  /// **'Adding group members as friends is disabled'**
  String get groupMemberFriendRequestDisabled;

  /// No description provided for @inviteGroupMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite members'**
  String get inviteGroupMembersTitle;

  /// No description provided for @chatHistoryNoPermission.
  ///
  /// In en, this message translates to:
  /// **'No permission to view chat history'**
  String get chatHistoryNoPermission;

  /// No description provided for @chatHistoryTabText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get chatHistoryTabText;

  /// No description provided for @chatHistoryTabFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get chatHistoryTabFiles;

  /// No description provided for @chatHistoryTabImages.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get chatHistoryTabImages;

  /// No description provided for @chatHistoryTabVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get chatHistoryTabVideos;

  /// No description provided for @chatHistoryTabDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get chatHistoryTabDate;

  /// No description provided for @chatHistoryDateSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap a dotted date to view messages'**
  String get chatHistoryDateSelect;

  /// No description provided for @chatHistoryDateEmpty.
  ///
  /// In en, this message translates to:
  /// **'No messages on this date'**
  String get chatHistoryDateEmpty;

  /// No description provided for @chatHistoryWeekMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get chatHistoryWeekMon;

  /// No description provided for @chatHistoryWeekTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get chatHistoryWeekTue;

  /// No description provided for @chatHistoryWeekWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get chatHistoryWeekWed;

  /// No description provided for @chatHistoryWeekThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get chatHistoryWeekThu;

  /// No description provided for @chatHistoryWeekFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get chatHistoryWeekFri;

  /// No description provided for @chatHistoryWeekSat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get chatHistoryWeekSat;

  /// No description provided for @chatHistoryWeekSun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get chatHistoryWeekSun;

  /// No description provided for @chatHistoryAllLoaded.
  ///
  /// In en, this message translates to:
  /// **'All chat history loaded'**
  String get chatHistoryAllLoaded;

  /// No description provided for @chatHistorySenderMe.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get chatHistorySenderMe;

  /// No description provided for @chatHistorySenderPeer.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get chatHistorySenderPeer;

  /// No description provided for @chatHistorySearchFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Keyword, then search (last 90 days)'**
  String get chatHistorySearchFieldHint;

  /// No description provided for @chatHistorySearchScopeNote.
  ///
  /// In en, this message translates to:
  /// **'Enter a keyword and tap search; only text from the last 90 days is searched'**
  String get chatHistorySearchScopeNote;

  /// No description provided for @chatHistorySearchNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matching messages'**
  String get chatHistorySearchNoMatches;

  /// No description provided for @chatHistorySearchAllResultsShown.
  ///
  /// In en, this message translates to:
  /// **'All results shown'**
  String get chatHistorySearchAllResultsShown;

  /// No description provided for @chatHistoryEmptyFiles.
  ///
  /// In en, this message translates to:
  /// **'No files'**
  String get chatHistoryEmptyFiles;

  /// No description provided for @chatHistoryEmptyImages.
  ///
  /// In en, this message translates to:
  /// **'No images'**
  String get chatHistoryEmptyImages;

  /// No description provided for @chatHistoryEmptyVideos.
  ///
  /// In en, this message translates to:
  /// **'No videos'**
  String get chatHistoryEmptyVideos;

  /// No description provided for @chatHistoryMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'{year}-{month}'**
  String chatHistoryMonthLabel(int year, int month);

  /// No description provided for @chatHistoryFileUnnamed.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get chatHistoryFileUnnamed;

  /// No description provided for @chatHistoryEmojiPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'[sticker]'**
  String get chatHistoryEmojiPlaceholder;

  /// No description provided for @contactsNewFriends.
  ///
  /// In en, this message translates to:
  /// **'New friends'**
  String get contactsNewFriends;

  /// No description provided for @friendRequestNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'New friend request'**
  String get friendRequestNotificationTitle;

  /// No description provided for @friendRequestNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'User {id} wants to add you as a friend'**
  String friendRequestNotificationBody(Object id);

  /// No description provided for @friendAcceptedNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Friend request accepted'**
  String get friendAcceptedNotificationTitle;

  /// No description provided for @friendAcceptedNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'You are now friends with user {id}'**
  String friendAcceptedNotificationBody(Object id);

  /// No description provided for @contactsGroupChatEntry.
  ///
  /// In en, this message translates to:
  /// **'Group chats'**
  String get contactsGroupChatEntry;

  /// No description provided for @contactsGroupSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Group chats ({count})'**
  String contactsGroupSectionTitle(int count);

  /// No description provided for @contactsEmptyFriends.
  ///
  /// In en, this message translates to:
  /// **'No contacts yet'**
  String get contactsEmptyFriends;

  /// No description provided for @contactsFriendRequestsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No pending requests'**
  String get contactsFriendRequestsEmpty;

  /// No description provided for @contactsFriendRequestLine.
  ///
  /// In en, this message translates to:
  /// **'{name} sent a friend request'**
  String contactsFriendRequestLine(String name);

  /// No description provided for @contactsFriendRequestReject.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get contactsFriendRequestReject;

  /// No description provided for @contactsFriendRequestAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get contactsFriendRequestAccept;

  /// No description provided for @friendAcceptAutoGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get friendAcceptAutoGreeting;

  /// No description provided for @createGroupDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Group chat ({count})'**
  String createGroupDefaultName(int count);

  /// No description provided for @createGroupCreatedPreview.
  ///
  /// In en, this message translates to:
  /// **'Group created'**
  String get createGroupCreatedPreview;

  /// No description provided for @createGroupDoneWithCount.
  ///
  /// In en, this message translates to:
  /// **'Done ({count})'**
  String createGroupDoneWithCount(int count);

  /// No description provided for @createGroupNameFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get createGroupNameFieldLabel;

  /// No description provided for @createGroupSearchFriendsHint.
  ///
  /// In en, this message translates to:
  /// **'Search friends'**
  String get createGroupSearchFriendsHint;

  /// No description provided for @pointsMyPoints.
  ///
  /// In en, this message translates to:
  /// **'My points'**
  String get pointsMyPoints;

  /// No description provided for @pointsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Load failed'**
  String get pointsLoadFailed;

  /// No description provided for @pointsCardFootnote.
  ///
  /// In en, this message translates to:
  /// **'Use points for events and redemptions (subject to platform rules).'**
  String get pointsCardFootnote;

  /// No description provided for @pointsViewLedger.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get pointsViewLedger;

  /// No description provided for @pointsCoupons.
  ///
  /// In en, this message translates to:
  /// **'Coupons'**
  String get pointsCoupons;

  /// No description provided for @pointsCouponsBadgeCount.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String pointsCouponsBadgeCount(int count);

  /// No description provided for @pointsLedgerTitle.
  ///
  /// In en, this message translates to:
  /// **'Points history'**
  String get pointsLedgerTitle;

  /// No description provided for @pointsCurrentTotal.
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
  String get pointsCurrentTotal;

  /// No description provided for @pointsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get pointsFilterAll;

  /// No description provided for @pointsFilterCredit.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get pointsFilterCredit;

  /// No description provided for @pointsFilterDebit.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get pointsFilterDebit;

  /// No description provided for @pointsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get pointsRetry;

  /// No description provided for @pointsLedgerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get pointsLedgerEmpty;

  /// No description provided for @pointsLedgerEnd.
  ///
  /// In en, this message translates to:
  /// **'All records shown'**
  String get pointsLedgerEnd;

  /// No description provided for @pointsReasonCreditDefault.
  ///
  /// In en, this message translates to:
  /// **'Points added'**
  String get pointsReasonCreditDefault;

  /// No description provided for @pointsReasonDebitDefault.
  ///
  /// In en, this message translates to:
  /// **'Points deducted'**
  String get pointsReasonDebitDefault;

  /// No description provided for @pointsBalanceAfter.
  ///
  /// In en, this message translates to:
  /// **'Bal. {balance}'**
  String pointsBalanceAfter(int balance);

  /// No description provided for @coinDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Coins'**
  String get coinDefaultName;

  /// No description provided for @coinCardFootnote.
  ///
  /// In en, this message translates to:
  /// **'Use coins for in-platform spending and discounts (subject to platform rules).'**
  String get coinCardFootnote;

  /// No description provided for @coinViewLedger.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get coinViewLedger;

  /// No description provided for @coinLedgerTitle.
  ///
  /// In en, this message translates to:
  /// **'Coin history'**
  String get coinLedgerTitle;

  /// No description provided for @coinCurrentTotal.
  ///
  /// In en, this message translates to:
  /// **'Current coin balance'**
  String get coinCurrentTotal;

  /// No description provided for @coinReasonCreditDefault.
  ///
  /// In en, this message translates to:
  /// **'Coins added'**
  String get coinReasonCreditDefault;

  /// No description provided for @coinReasonDebitDefault.
  ///
  /// In en, this message translates to:
  /// **'Coins deducted'**
  String get coinReasonDebitDefault;

  /// No description provided for @coinBalanceAfter.
  ///
  /// In en, this message translates to:
  /// **'Bal. {balance}'**
  String coinBalanceAfter(int balance);

  /// No description provided for @servicesEmptyList.
  ///
  /// In en, this message translates to:
  /// **'No services yet'**
  String get servicesEmptyList;

  /// No description provided for @servicesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search mini programs'**
  String get servicesSearchHint;

  /// No description provided for @servicesSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No matching services'**
  String get servicesSearchEmpty;

  /// No description provided for @servicesPinnedTitle.
  ///
  /// In en, this message translates to:
  /// **'Pinned shortcuts'**
  String get servicesPinnedTitle;

  /// No description provided for @servicesPin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get servicesPin;

  /// No description provided for @servicesUnpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get servicesUnpin;

  /// No description provided for @servicesPinnedReorderHint.
  ///
  /// In en, this message translates to:
  /// **'Long-press to reorder'**
  String get servicesPinnedReorderHint;

  /// No description provided for @servicesUnnamedItem.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get servicesUnnamedItem;

  /// No description provided for @servicesMoreTitle.
  ///
  /// In en, this message translates to:
  /// **'More services'**
  String get servicesMoreTitle;

  /// No description provided for @servicesWalletCompanyName.
  ///
  /// In en, this message translates to:
  /// **'A380'**
  String get servicesWalletCompanyName;

  /// No description provided for @servicesWalletA380Coin.
  ///
  /// In en, this message translates to:
  /// **'A380 Coin'**
  String get servicesWalletA380Coin;

  /// No description provided for @servicesWalletPoints.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get servicesWalletPoints;

  /// No description provided for @servicesPointsBalance.
  ///
  /// In en, this message translates to:
  /// **'Points balance'**
  String get servicesPointsBalance;

  /// No description provided for @servicesHotel.
  ///
  /// In en, this message translates to:
  /// **'Hotel'**
  String get servicesHotel;

  /// No description provided for @servicesKtv.
  ///
  /// In en, this message translates to:
  /// **'KTV'**
  String get servicesKtv;

  /// No description provided for @servicesKtvBusiness.
  ///
  /// In en, this message translates to:
  /// **'KTV Business'**
  String get servicesKtvBusiness;

  /// No description provided for @servicesBar.
  ///
  /// In en, this message translates to:
  /// **'Bar'**
  String get servicesBar;

  /// No description provided for @servicesBilliards.
  ///
  /// In en, this message translates to:
  /// **'Billiards'**
  String get servicesBilliards;

  /// No description provided for @servicesFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get servicesFood;

  /// No description provided for @servicesDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get servicesDelivery;

  /// No description provided for @servicesFlashSale.
  ///
  /// In en, this message translates to:
  /// **'Flash sale'**
  String get servicesFlashSale;

  /// No description provided for @servicesBoutique.
  ///
  /// In en, this message translates to:
  /// **'Boutique'**
  String get servicesBoutique;

  /// No description provided for @servicesMassage.
  ///
  /// In en, this message translates to:
  /// **'Foot bath'**
  String get servicesMassage;

  /// No description provided for @servicesFlights.
  ///
  /// In en, this message translates to:
  /// **'Flights'**
  String get servicesFlights;

  /// No description provided for @servicesTaxi.
  ///
  /// In en, this message translates to:
  /// **'Ride-hailing'**
  String get servicesTaxi;

  /// No description provided for @servicesComingSoon.
  ///
  /// In en, this message translates to:
  /// **'This feature is being updated. Please check back soon.'**
  String get servicesComingSoon;

  /// No description provided for @serviceDemoSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search {service}'**
  String serviceDemoSearchHint(String service);

  /// No description provided for @serviceDemoHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Featured {service}'**
  String serviceDemoHeroTitle(String service);

  /// No description provided for @serviceDemoHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Discover popular services and confirm in a few taps'**
  String get serviceDemoHeroSubtitle;

  /// No description provided for @serviceDemoFeaturedItem.
  ///
  /// In en, this message translates to:
  /// **'Featured {service}'**
  String serviceDemoFeaturedItem(String service);

  /// No description provided for @serviceDemoPopularItem.
  ///
  /// In en, this message translates to:
  /// **'Popular {service}'**
  String serviceDemoPopularItem(String service);

  /// No description provided for @serviceDemoValueItem.
  ///
  /// In en, this message translates to:
  /// **'Best value {service}'**
  String serviceDemoValueItem(String service);

  /// No description provided for @serviceDemoNearbyItem.
  ///
  /// In en, this message translates to:
  /// **'Nearby {service}'**
  String serviceDemoNearbyItem(String service);

  /// No description provided for @serviceDemoQualityDescription.
  ///
  /// In en, this message translates to:
  /// **'Quality assured · Flexible cancellation'**
  String get serviceDemoQualityDescription;

  /// No description provided for @serviceDemoFastDescription.
  ///
  /// In en, this message translates to:
  /// **'Popular nearby · Fast confirmation'**
  String get serviceDemoFastDescription;

  /// No description provided for @serviceDemoFilterRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get serviceDemoFilterRecommended;

  /// No description provided for @serviceDemoFilterNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get serviceDemoFilterNearby;

  /// No description provided for @serviceDemoFilterTopRated.
  ///
  /// In en, this message translates to:
  /// **'Top rated'**
  String get serviceDemoFilterTopRated;

  /// No description provided for @serviceDemoMockNotice.
  ///
  /// In en, this message translates to:
  /// **'Local demo only. No real order or charge will be created.'**
  String get serviceDemoMockNotice;

  /// No description provided for @serviceDemoNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching services'**
  String get serviceDemoNoResults;

  /// No description provided for @serviceDemoRating.
  ///
  /// In en, this message translates to:
  /// **'{rating} rating'**
  String serviceDemoRating(String rating);

  /// No description provided for @serviceDemoSold.
  ///
  /// In en, this message translates to:
  /// **'{count} sold'**
  String serviceDemoSold(int count);

  /// No description provided for @serviceDemoFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get serviceDemoFree;

  /// No description provided for @serviceDemoCouponAmount.
  ///
  /// In en, this message translates to:
  /// **'¥{amount}'**
  String serviceDemoCouponAmount(String amount);

  /// No description provided for @serviceDemoAction.
  ///
  /// In en, this message translates to:
  /// **'Try now'**
  String get serviceDemoAction;

  /// No description provided for @serviceDemoClaim.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get serviceDemoClaim;

  /// No description provided for @serviceDemoDone.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get serviceDemoDone;

  /// No description provided for @serviceDemoConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm demo'**
  String get serviceDemoConfirmTitle;

  /// No description provided for @serviceDemoConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Submit a demo order for “{item}”?'**
  String serviceDemoConfirmBody(String item);

  /// No description provided for @serviceDemoConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get serviceDemoConfirm;

  /// No description provided for @serviceDemoSuccess.
  ///
  /// In en, this message translates to:
  /// **'“{item}” completed'**
  String serviceDemoSuccess(String item);

  /// No description provided for @serviceDemoMyOrders.
  ///
  /// In en, this message translates to:
  /// **'My demo orders'**
  String get serviceDemoMyOrders;

  /// No description provided for @serviceDemoMyCoupons.
  ///
  /// In en, this message translates to:
  /// **'My coupons'**
  String get serviceDemoMyCoupons;

  /// No description provided for @serviceDemoEmptyOrders.
  ///
  /// In en, this message translates to:
  /// **'No records yet. Try a service first.'**
  String get serviceDemoEmptyOrders;

  /// No description provided for @serviceDemoCouponNewUser.
  ///
  /// In en, this message translates to:
  /// **'New user coupon'**
  String get serviceDemoCouponNewUser;

  /// No description provided for @serviceDemoCouponDining.
  ///
  /// In en, this message translates to:
  /// **'Dining coupon'**
  String get serviceDemoCouponDining;

  /// No description provided for @serviceDemoCouponTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel coupon'**
  String get serviceDemoCouponTravel;

  /// No description provided for @serviceDemoCouponNoThreshold.
  ///
  /// In en, this message translates to:
  /// **'No minimum · Sitewide'**
  String get serviceDemoCouponNoThreshold;

  /// No description provided for @serviceDemoCouponThreshold.
  ///
  /// In en, this message translates to:
  /// **'Valid on ¥{amount}+'**
  String serviceDemoCouponThreshold(String amount);

  /// No description provided for @serviceVenueSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search {service} venues'**
  String serviceVenueSearchHint(String service);

  /// No description provided for @serviceVenueSmartSort.
  ///
  /// In en, this message translates to:
  /// **'Smart sort'**
  String get serviceVenueSmartSort;

  /// No description provided for @serviceVenueFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get serviceVenueFilter;

  /// No description provided for @serviceVenueFeaturedMerchant.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get serviceVenueFeaturedMerchant;

  /// No description provided for @serviceVenueCleanTag.
  ///
  /// In en, this message translates to:
  /// **'Comfortable'**
  String get serviceVenueCleanTag;

  /// No description provided for @serviceVenueDistance.
  ///
  /// In en, this message translates to:
  /// **'{distance} km'**
  String serviceVenueDistance(String distance);

  /// No description provided for @serviceVenueReviews.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String serviceVenueReviews(int count);

  /// No description provided for @serviceVenueOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get serviceVenueOpen;

  /// No description provided for @serviceVenueOpenAllDay.
  ///
  /// In en, this message translates to:
  /// **'Open all day · Walk-ins welcome'**
  String get serviceVenueOpenAllDay;

  /// No description provided for @serviceVenueAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get serviceVenueAddress;

  /// No description provided for @serviceVenueDealsTitle.
  ///
  /// In en, this message translates to:
  /// **'Deals ({count})'**
  String serviceVenueDealsTitle(int count);

  /// No description provided for @serviceBookingHotelOptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Rooms and prices'**
  String get serviceBookingHotelOptionsTitle;

  /// No description provided for @serviceBookingKtvOptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Packages and prices'**
  String get serviceBookingKtvOptionsTitle;

  /// No description provided for @serviceBookingHotelOptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get serviceBookingHotelOptionLabel;

  /// No description provided for @serviceBookingKtvOptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get serviceBookingKtvOptionLabel;

  /// No description provided for @serviceBookingPrice.
  ///
  /// In en, this message translates to:
  /// **'¥{price}'**
  String serviceBookingPrice(int price);

  /// No description provided for @serviceBookingCashPrice.
  ///
  /// In en, this message translates to:
  /// **'Cash ¥{price}'**
  String serviceBookingCashPrice(int price);

  /// No description provided for @serviceBookingPointsPrice.
  ///
  /// In en, this message translates to:
  /// **'Redeem with {points} points'**
  String serviceBookingPointsPrice(int points);

  /// No description provided for @serviceBookingPayment.
  ///
  /// In en, this message translates to:
  /// **'Booking method'**
  String get serviceBookingPayment;

  /// No description provided for @serviceBookingHotelTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Check-in time'**
  String get serviceBookingHotelTimeLabel;

  /// No description provided for @serviceBookingKtvTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Arrival time'**
  String get serviceBookingKtvTimeLabel;

  /// No description provided for @serviceBookingChooseTime.
  ///
  /// In en, this message translates to:
  /// **'Choose date and time'**
  String get serviceBookingChooseTime;

  /// No description provided for @serviceBookingReserve.
  ///
  /// In en, this message translates to:
  /// **'Reserve now'**
  String get serviceBookingReserve;

  /// No description provided for @serviceBookingMockNotice.
  ///
  /// In en, this message translates to:
  /// **'This is a local booking demo. It will not create a real order, deduct points, or charge you.'**
  String get serviceBookingMockNotice;

  /// No description provided for @serviceBookingSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Reservation confirmed'**
  String get serviceBookingSuccessTitle;

  /// No description provided for @serviceBookingSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Your booking details are confirmed. Please arrive at the selected time.'**
  String get serviceBookingSuccessBody;

  /// No description provided for @serviceVenueBuyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy now'**
  String get serviceVenueBuyNow;

  /// No description provided for @serviceVenueHotDeal.
  ///
  /// In en, this message translates to:
  /// **'Popular deal'**
  String get serviceVenueHotDeal;

  /// No description provided for @serviceVenueRefundAnytime.
  ///
  /// In en, this message translates to:
  /// **'Refund anytime'**
  String get serviceVenueRefundAnytime;

  /// No description provided for @serviceVenueValidAnytime.
  ///
  /// In en, this message translates to:
  /// **'Expiry refund'**
  String get serviceVenueValidAnytime;

  /// No description provided for @serviceVenueDealDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Deal details'**
  String get serviceVenueDealDetailTitle;

  /// No description provided for @serviceVenuePackageDetails.
  ///
  /// In en, this message translates to:
  /// **'Package details'**
  String get serviceVenuePackageDetails;

  /// No description provided for @serviceVenueDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get serviceVenueDuration;

  /// No description provided for @serviceVenueDurationValue.
  ///
  /// In en, this message translates to:
  /// **'2 hours'**
  String get serviceVenueDurationValue;

  /// No description provided for @serviceVenueRoomType.
  ///
  /// In en, this message translates to:
  /// **'Space'**
  String get serviceVenueRoomType;

  /// No description provided for @serviceVenueRoomTypeValue.
  ///
  /// In en, this message translates to:
  /// **'Main hall / Booth'**
  String get serviceVenueRoomTypeValue;

  /// No description provided for @serviceVenueApplicable.
  ///
  /// In en, this message translates to:
  /// **'Valid for'**
  String get serviceVenueApplicable;

  /// No description provided for @serviceVenueApplicableValue.
  ///
  /// In en, this message translates to:
  /// **'All areas'**
  String get serviceVenueApplicableValue;

  /// No description provided for @serviceVenueAdditionalInfo.
  ///
  /// In en, this message translates to:
  /// **'Additional information'**
  String get serviceVenueAdditionalInfo;

  /// No description provided for @serviceVenueAdditionalInfoBody.
  ///
  /// In en, this message translates to:
  /// **'No reservation required. Show the mock order during opening hours. One package per order.'**
  String get serviceVenueAdditionalInfoBody;

  /// No description provided for @serviceVenueOrderNow.
  ///
  /// In en, this message translates to:
  /// **'Order now'**
  String get serviceVenueOrderNow;

  /// No description provided for @serviceVenueCheckoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit order'**
  String get serviceVenueCheckoutTitle;

  /// No description provided for @serviceVenueQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get serviceVenueQuantity;

  /// No description provided for @serviceVenueDecreaseQuantity.
  ///
  /// In en, this message translates to:
  /// **'Decrease quantity'**
  String get serviceVenueDecreaseQuantity;

  /// No description provided for @serviceVenueIncreaseQuantity.
  ///
  /// In en, this message translates to:
  /// **'Increase quantity'**
  String get serviceVenueIncreaseQuantity;

  /// No description provided for @serviceVenueTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get serviceVenueTotal;

  /// No description provided for @serviceVenueDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get serviceVenueDiscount;

  /// No description provided for @serviceVenueFullDiscount.
  ///
  /// In en, this message translates to:
  /// **'Fully discounted'**
  String get serviceVenueFullDiscount;

  /// No description provided for @serviceVenuePurchaseNotice.
  ///
  /// In en, this message translates to:
  /// **'Purchase notice'**
  String get serviceVenuePurchaseNotice;

  /// No description provided for @serviceVenuePurchaseNoticeBody.
  ///
  /// In en, this message translates to:
  /// **'This is a local mock demo. No payment or real charge will be made. Submitting immediately creates a successful order.'**
  String get serviceVenuePurchaseNoticeBody;

  /// No description provided for @serviceVenueFreeOrderAction.
  ///
  /// In en, this message translates to:
  /// **'Place free order'**
  String get serviceVenueFreeOrderAction;

  /// No description provided for @serviceVenueOrderSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Order successful'**
  String get serviceVenueOrderSuccessTitle;

  /// No description provided for @serviceVenueOrderSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Your demo order is ready. Return to the list to try another venue.'**
  String get serviceVenueOrderSuccessBody;

  /// No description provided for @serviceVenueOrderVenue.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get serviceVenueOrderVenue;

  /// No description provided for @serviceVenueOrderItem.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get serviceVenueOrderItem;

  /// No description provided for @serviceVenueOrderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order number'**
  String get serviceVenueOrderNumber;

  /// No description provided for @serviceVenueBackToList.
  ///
  /// In en, this message translates to:
  /// **'Back to venues'**
  String get serviceVenueBackToList;

  /// No description provided for @serviceVenueBarName1.
  ///
  /// In en, this message translates to:
  /// **'Twilight Arcade Bar'**
  String get serviceVenueBarName1;

  /// No description provided for @serviceVenueBarName2.
  ///
  /// In en, this message translates to:
  /// **'Blue Note Thirteen'**
  String get serviceVenueBarName2;

  /// No description provided for @serviceVenueBarName3.
  ///
  /// In en, this message translates to:
  /// **'Cloud Terrace Bar'**
  String get serviceVenueBarName3;

  /// No description provided for @serviceVenueBarName4.
  ///
  /// In en, this message translates to:
  /// **'Urban Tipsy Lab'**
  String get serviceVenueBarName4;

  /// No description provided for @serviceVenuePoolName1.
  ///
  /// In en, this message translates to:
  /// **'Starry Billiards Club'**
  String get serviceVenuePoolName1;

  /// No description provided for @serviceVenuePoolName2.
  ///
  /// In en, this message translates to:
  /// **'Daybreak Pool Hall'**
  String get serviceVenuePoolName2;

  /// No description provided for @serviceVenuePoolName3.
  ///
  /// In en, this message translates to:
  /// **'Black Eight Club'**
  String get serviceVenuePoolName3;

  /// No description provided for @serviceVenuePoolName4.
  ///
  /// In en, this message translates to:
  /// **'Brilliant Billiards'**
  String get serviceVenuePoolName4;

  /// No description provided for @serviceVenueHotelName1.
  ///
  /// In en, this message translates to:
  /// **'Cloud Rest Hotel'**
  String get serviceVenueHotelName1;

  /// No description provided for @serviceVenueHotelName2.
  ///
  /// In en, this message translates to:
  /// **'Galaxy International Hotel'**
  String get serviceVenueHotelName2;

  /// No description provided for @serviceVenueHotelName3.
  ///
  /// In en, this message translates to:
  /// **'Riverside Joy Hotel'**
  String get serviceVenueHotelName3;

  /// No description provided for @serviceVenueHotelName4.
  ///
  /// In en, this message translates to:
  /// **'City Lights Hotel'**
  String get serviceVenueHotelName4;

  /// No description provided for @serviceVenueKtvName1.
  ///
  /// In en, this message translates to:
  /// **'Golden Stage KTV'**
  String get serviceVenueKtvName1;

  /// No description provided for @serviceVenueKtvName2.
  ///
  /// In en, this message translates to:
  /// **'Star Party Karaoke'**
  String get serviceVenueKtvName2;

  /// No description provided for @serviceVenueKtvName3.
  ///
  /// In en, this message translates to:
  /// **'Mic Wave Party KTV'**
  String get serviceVenueKtvName3;

  /// No description provided for @serviceVenueKtvName4.
  ///
  /// In en, this message translates to:
  /// **'Cloud Karaoke'**
  String get serviceVenueKtvName4;

  /// No description provided for @serviceVenueAddress1.
  ///
  /// In en, this message translates to:
  /// **'Level 2, Zone B, Galaxy Plaza'**
  String get serviceVenueAddress1;

  /// No description provided for @serviceVenueAddress2.
  ///
  /// In en, this message translates to:
  /// **'Creative Park, 88 Riverside Road'**
  String get serviceVenueAddress2;

  /// No description provided for @serviceVenueAddress3.
  ///
  /// In en, this message translates to:
  /// **'Level 5, Cloud Center, CBD'**
  String get serviceVenueAddress3;

  /// No description provided for @serviceVenueAddress4.
  ///
  /// In en, this message translates to:
  /// **'19 Youth Street, Trend District'**
  String get serviceVenueAddress4;

  /// No description provided for @serviceVenueDescription1.
  ///
  /// In en, this message translates to:
  /// **'Refined setting and a relaxed atmosphere for friends'**
  String get serviceVenueDescription1;

  /// No description provided for @serviceVenueDescription2.
  ///
  /// In en, this message translates to:
  /// **'Well equipped, spacious and welcoming'**
  String get serviceVenueDescription2;

  /// No description provided for @serviceVenueDescription3.
  ///
  /// In en, this message translates to:
  /// **'City views, photo-friendly and comfortable'**
  String get serviceVenueDescription3;

  /// No description provided for @serviceVenueDescription4.
  ///
  /// In en, this message translates to:
  /// **'Stylish new venue with convenient transport'**
  String get serviceVenueDescription4;

  /// No description provided for @serviceVenueBarDeal1.
  ///
  /// In en, this message translates to:
  /// **'Drinks experience for two'**
  String get serviceVenueBarDeal1;

  /// No description provided for @serviceVenueBarDeal2.
  ///
  /// In en, this message translates to:
  /// **'Evening signature cocktail package'**
  String get serviceVenueBarDeal2;

  /// No description provided for @serviceVenueBarDeal3.
  ///
  /// In en, this message translates to:
  /// **'Terrace music party experience'**
  String get serviceVenueBarDeal3;

  /// No description provided for @serviceVenueFootBathDeal1.
  ///
  /// In en, this message translates to:
  /// **'Wellness foot bath package'**
  String get serviceVenueFootBathDeal1;

  /// No description provided for @serviceVenueFootBathDeal2.
  ///
  /// In en, this message translates to:
  /// **'Extended foot bath relaxation package'**
  String get serviceVenueFootBathDeal2;

  /// No description provided for @serviceVenueFootBathDeal3.
  ///
  /// In en, this message translates to:
  /// **'Foot bath leisure package for two'**
  String get serviceVenueFootBathDeal3;

  /// No description provided for @serviceVenuePoolDeal1.
  ///
  /// In en, this message translates to:
  /// **'2-hour all-day billiards session'**
  String get serviceVenuePoolDeal1;

  /// No description provided for @serviceVenuePoolDeal2.
  ///
  /// In en, this message translates to:
  /// **'Daytime Chinese billiards session'**
  String get serviceVenuePoolDeal2;

  /// No description provided for @serviceVenuePoolDeal3.
  ///
  /// In en, this message translates to:
  /// **'Weekend friends pool package'**
  String get serviceVenuePoolDeal3;

  /// No description provided for @serviceVenueHotelOption1.
  ///
  /// In en, this message translates to:
  /// **'Elegant king room'**
  String get serviceVenueHotelOption1;

  /// No description provided for @serviceVenueHotelOption2.
  ///
  /// In en, this message translates to:
  /// **'Deluxe twin room'**
  String get serviceVenueHotelOption2;

  /// No description provided for @serviceVenueHotelOption3.
  ///
  /// In en, this message translates to:
  /// **'Executive view suite'**
  String get serviceVenueHotelOption3;

  /// No description provided for @serviceVenueKtvOption1.
  ///
  /// In en, this message translates to:
  /// **'Karaoke for two'**
  String get serviceVenueKtvOption1;

  /// No description provided for @serviceVenueKtvOption2.
  ///
  /// In en, this message translates to:
  /// **'Friends gathering package'**
  String get serviceVenueKtvOption2;

  /// No description provided for @serviceVenueKtvOption3.
  ///
  /// In en, this message translates to:
  /// **'Party karaoke package'**
  String get serviceVenueKtvOption3;

  /// No description provided for @serviceVenueDealSubtitle1.
  ///
  /// In en, this message translates to:
  /// **'No reservation · Valid all day'**
  String get serviceVenueDealSubtitle1;

  /// No description provided for @serviceVenueDealSubtitle2.
  ///
  /// In en, this message translates to:
  /// **'Popular pick · Fast venue confirmation'**
  String get serviceVenueDealSubtitle2;

  /// No description provided for @profileEditChangeAvatar.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get profileEditChangeAvatar;

  /// No description provided for @profileEditTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get profileEditTakePhoto;

  /// No description provided for @profileEditChooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get profileEditChooseFromGallery;

  /// No description provided for @profileFieldNickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get profileFieldNickname;

  /// No description provided for @profileFieldRequiredHint.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get profileFieldRequiredHint;

  /// No description provided for @profileFieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get profileFieldPhone;

  /// No description provided for @profileFieldOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get profileFieldOptionalHint;

  /// No description provided for @profileFieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileFieldEmail;

  /// No description provided for @profileFieldSignature.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get profileFieldSignature;

  /// No description provided for @profileFieldSignatureHint.
  ///
  /// In en, this message translates to:
  /// **'Say something…'**
  String get profileFieldSignatureHint;

  /// No description provided for @pointsAccountEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Points account'**
  String get pointsAccountEntryTitle;

  /// No description provided for @pointsAccountNotBound.
  ///
  /// In en, this message translates to:
  /// **'Not linked'**
  String get pointsAccountNotBound;

  /// No description provided for @pointsAccountBindingTitle.
  ///
  /// In en, this message translates to:
  /// **'Link points account'**
  String get pointsAccountBindingTitle;

  /// No description provided for @pointsAccountVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Security verification'**
  String get pointsAccountVerificationTitle;

  /// No description provided for @pointsAccountStepAccount.
  ///
  /// In en, this message translates to:
  /// **'Step 1'**
  String get pointsAccountStepAccount;

  /// No description provided for @pointsAccountStepVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify identity'**
  String get pointsAccountStepVerify;

  /// No description provided for @pointsAccountChooseHeading.
  ///
  /// In en, this message translates to:
  /// **'Choose account type'**
  String get pointsAccountChooseHeading;

  /// No description provided for @pointsAccountChooseDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose how you sign in to your points account and enter the account details.'**
  String get pointsAccountChooseDescription;

  /// No description provided for @pointsAccountReplaceHeading.
  ///
  /// In en, this message translates to:
  /// **'Change points account'**
  String get pointsAccountReplaceHeading;

  /// No description provided for @pointsAccountReplaceDescription.
  ///
  /// In en, this message translates to:
  /// **'The current account will be replaced after the new one is verified.'**
  String get pointsAccountReplaceDescription;

  /// No description provided for @pointsAccountTypePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get pointsAccountTypePhone;

  /// No description provided for @pointsAccountTypeEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get pointsAccountTypeEmail;

  /// No description provided for @pointsAccountTypeAccount.
  ///
  /// In en, this message translates to:
  /// **'Member no.'**
  String get pointsAccountTypeAccount;

  /// No description provided for @pointsAccountPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get pointsAccountPhoneHint;

  /// No description provided for @pointsAccountEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter email address'**
  String get pointsAccountEmailHint;

  /// No description provided for @pointsAccountUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter member number'**
  String get pointsAccountUsernameHint;

  /// No description provided for @pointsAccountPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 6–15 digit phone number'**
  String get pointsAccountPhoneInvalid;

  /// No description provided for @pointsAccountEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get pointsAccountEmailInvalid;

  /// No description provided for @pointsAccountUsernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a 6–24 character letter or number member number'**
  String get pointsAccountUsernameInvalid;

  /// No description provided for @pointsAccountCodeToPhone.
  ///
  /// In en, this message translates to:
  /// **'A verification code will be sent to this phone'**
  String get pointsAccountCodeToPhone;

  /// No description provided for @pointsAccountCodeToEmail.
  ///
  /// In en, this message translates to:
  /// **'A verification code will be sent to this email'**
  String get pointsAccountCodeToEmail;

  /// No description provided for @pointsAccountCodeToSecurityContact.
  ///
  /// In en, this message translates to:
  /// **'A code will be sent to the account\'s security contact'**
  String get pointsAccountCodeToSecurityContact;

  /// No description provided for @pointsAccountPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Your points account is only used for balance queries, earning, and redemption. The full account is never shown publicly.'**
  String get pointsAccountPrivacyNote;

  /// No description provided for @pointsAccountRequestCode.
  ///
  /// In en, this message translates to:
  /// **'Get verification code'**
  String get pointsAccountRequestCode;

  /// No description provided for @pointsAccountCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent'**
  String get pointsAccountCodeSent;

  /// No description provided for @pointsAccountCodeResent.
  ///
  /// In en, this message translates to:
  /// **'A new verification code was sent'**
  String get pointsAccountCodeResent;

  /// No description provided for @pointsAccountEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter verification code'**
  String get pointsAccountEnterCode;

  /// No description provided for @pointsAccountCodeSentTo.
  ///
  /// In en, this message translates to:
  /// **'A 6-digit code was sent to'**
  String get pointsAccountCodeSentTo;

  /// No description provided for @pointsAccountCodeFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Six-digit verification code'**
  String get pointsAccountCodeFieldLabel;

  /// No description provided for @pointsAccountCodeExpiryHint.
  ///
  /// In en, this message translates to:
  /// **'Complete verification before the code expires'**
  String get pointsAccountCodeExpiryHint;

  /// No description provided for @pointsAccountCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Incorrect code. Please try again'**
  String get pointsAccountCodeInvalid;

  /// No description provided for @pointsAccountResendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get pointsAccountResendCode;

  /// No description provided for @pointsAccountResendCountdown.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String pointsAccountResendCountdown(int seconds);

  /// No description provided for @pointsAccountDemoCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Prototype verification code:'**
  String get pointsAccountDemoCodeLabel;

  /// No description provided for @pointsAccountConfirmBinding.
  ///
  /// In en, this message translates to:
  /// **'Confirm link'**
  String get pointsAccountConfirmBinding;

  /// No description provided for @pointsAccountBindSuccess.
  ///
  /// In en, this message translates to:
  /// **'Points account linked'**
  String get pointsAccountBindSuccess;

  /// No description provided for @pointsAccountBindSuccessDescription.
  ///
  /// In en, this message translates to:
  /// **'Security verification is complete. Points services are now available.'**
  String get pointsAccountBindSuccessDescription;

  /// No description provided for @pointsAccountReturnToProfile.
  ///
  /// In en, this message translates to:
  /// **'Back to profile'**
  String get pointsAccountReturnToProfile;

  /// No description provided for @pointsAccountSelectCountry.
  ///
  /// In en, this message translates to:
  /// **'Choose country/region'**
  String get pointsAccountSelectCountry;

  /// No description provided for @pointsAccountSearchCountry.
  ///
  /// In en, this message translates to:
  /// **'Search country, region, or code'**
  String get pointsAccountSearchCountry;

  /// No description provided for @pointsAccountNoCountryResults.
  ///
  /// In en, this message translates to:
  /// **'No matching country or region'**
  String get pointsAccountNoCountryResults;

  /// No description provided for @pointsAccountPhoneInvalidForCountry.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid {country} phone number ({lengths} digits)'**
  String pointsAccountPhoneInvalidForCountry(String country, String lengths);

  /// No description provided for @pointsAccountEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get pointsAccountEnterPassword;

  /// No description provided for @pointsAccountPasswordNextHint.
  ///
  /// In en, this message translates to:
  /// **'The next step verifies the member number password'**
  String get pointsAccountPasswordNextHint;

  /// No description provided for @pointsAccountPasswordVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Password verification'**
  String get pointsAccountPasswordVerificationTitle;

  /// No description provided for @pointsAccountPasswordHeading.
  ///
  /// In en, this message translates to:
  /// **'Verify with password'**
  String get pointsAccountPasswordHeading;

  /// No description provided for @pointsAccountPasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter the sign-in password for member number {account}'**
  String pointsAccountPasswordDescription(String account);

  /// No description provided for @pointsAccountPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter member number password'**
  String get pointsAccountPasswordHint;

  /// No description provided for @pointsAccountPasswordInvalid.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password. Please try again'**
  String get pointsAccountPasswordInvalid;

  /// No description provided for @pointsAccountDemoPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Prototype password:'**
  String get pointsAccountDemoPasswordLabel;

  /// No description provided for @passwordShowTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get passwordShowTooltip;

  /// No description provided for @passwordHideTooltip.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get passwordHideTooltip;

  /// No description provided for @changePasswordCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get changePasswordCurrentLabel;

  /// No description provided for @changePasswordNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New password (min. 6 characters)'**
  String get changePasswordNewLabel;

  /// No description provided for @changePasswordConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get changePasswordConfirmLabel;

  /// No description provided for @changePasswordSubmit.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get changePasswordSubmit;

  /// No description provided for @formLabelUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get formLabelUsername;

  /// No description provided for @formLabelPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get formLabelPassword;

  /// No description provided for @registerNicknameOptional.
  ///
  /// In en, this message translates to:
  /// **'Nickname (optional)'**
  String get registerNicknameOptional;

  /// No description provided for @registerSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Signing up...'**
  String get registerSubmitting;

  /// No description provided for @avatarCropTitle.
  ///
  /// In en, this message translates to:
  /// **'Crop avatar'**
  String get avatarCropTitle;

  /// No description provided for @avatarCropStickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Crop sticker'**
  String get avatarCropStickerTitle;

  /// No description provided for @avatarCropDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get avatarCropDone;

  /// No description provided for @avatarCropMissingData.
  ///
  /// In en, this message translates to:
  /// **'Missing image data'**
  String get avatarCropMissingData;

  /// No description provided for @recentMiniProgramsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recently used mini programs'**
  String get recentMiniProgramsTitle;

  /// No description provided for @recentMiniProgramsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recent mini programs'**
  String get recentMiniProgramsEmpty;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonSaveImage.
  ///
  /// In en, this message translates to:
  /// **'Save image'**
  String get commonSaveImage;

  /// No description provided for @commonSaveVideo.
  ///
  /// In en, this message translates to:
  /// **'Save video'**
  String get commonSaveVideo;

  /// No description provided for @miniProgramQrCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Mini program code'**
  String get miniProgramQrCodeTitle;

  /// No description provided for @chatEmojiTab.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get chatEmojiTab;

  /// No description provided for @chatStickerPackTab.
  ///
  /// In en, this message translates to:
  /// **'Stickers'**
  String get chatStickerPackTab;

  /// No description provided for @chatStickerRecentTab.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get chatStickerRecentTab;

  /// No description provided for @chatMoreImage.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get chatMoreImage;

  /// No description provided for @chatMoreTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get chatMoreTakePhoto;

  /// No description provided for @chatMoreCamera.
  ///
  /// In en, this message translates to:
  /// **'Photo / video'**
  String get chatMoreCamera;

  /// No description provided for @chatMoreCameraHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to take a photo. Press and hold to record a video.'**
  String get chatMoreCameraHint;

  /// No description provided for @chatCameraShutterHint.
  ///
  /// In en, this message translates to:
  /// **'Tap for photo, hold for video'**
  String get chatCameraShutterHint;

  /// No description provided for @chatCameraRecordingHint.
  ///
  /// In en, this message translates to:
  /// **'Release to stop recording'**
  String get chatCameraRecordingHint;

  /// No description provided for @chatCameraInitializing.
  ///
  /// In en, this message translates to:
  /// **'Opening camera…'**
  String get chatCameraInitializing;

  /// No description provided for @chatCameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable. Check camera and microphone permissions.'**
  String get chatCameraUnavailable;

  /// No description provided for @chatCameraSwitchFlash.
  ///
  /// In en, this message translates to:
  /// **'Change flash mode'**
  String get chatCameraSwitchFlash;

  /// No description provided for @chatMoreVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get chatMoreVideo;

  /// No description provided for @chatMoreRecordVideo.
  ///
  /// In en, this message translates to:
  /// **'Record video'**
  String get chatMoreRecordVideo;

  /// No description provided for @chatMoreFile.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get chatMoreFile;

  /// No description provided for @chatMoreLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get chatMoreLocation;

  /// No description provided for @chatMoreVoiceCall.
  ///
  /// In en, this message translates to:
  /// **'Voice call'**
  String get chatMoreVoiceCall;

  /// No description provided for @chatMoreVideoCall.
  ///
  /// In en, this message translates to:
  /// **'Video call'**
  String get chatMoreVideoCall;

  /// No description provided for @chatReplyTo.
  ///
  /// In en, this message translates to:
  /// **'Reply to {who}'**
  String chatReplyTo(String who);

  /// No description provided for @chatReplySelfShort.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get chatReplySelfShort;

  /// No description provided for @chatReplyPeerShort.
  ///
  /// In en, this message translates to:
  /// **'Them'**
  String get chatReplyPeerShort;

  /// No description provided for @chatDismissReplySemantics.
  ///
  /// In en, this message translates to:
  /// **'Dismiss reply'**
  String get chatDismissReplySemantics;

  /// No description provided for @chatStickerCountShort.
  ///
  /// In en, this message translates to:
  /// **'{count} stickers'**
  String chatStickerCountShort(int count);

  /// No description provided for @chatStickerManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get chatStickerManage;

  /// No description provided for @chatStickerDoneEditing.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get chatStickerDoneEditing;

  /// No description provided for @chatStickerMyEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add from your gallery, or long-press a sticker in chat to add it.'**
  String get chatStickerMyEmptyHint;

  /// No description provided for @chatStickerEmptyList.
  ///
  /// In en, this message translates to:
  /// **'No stickers yet'**
  String get chatStickerEmptyList;

  /// No description provided for @chatSemanticEmojiPicker.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get chatSemanticEmojiPicker;

  /// No description provided for @imageViewerActualSizeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Actual size'**
  String get imageViewerActualSizeTooltip;

  /// No description provided for @chatVoiceCancelLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get chatVoiceCancelLabel;

  /// No description provided for @chatVoiceReleaseToCancel.
  ///
  /// In en, this message translates to:
  /// **'Release to cancel'**
  String get chatVoiceReleaseToCancel;

  /// No description provided for @chatVoiceReleaseToSend.
  ///
  /// In en, this message translates to:
  /// **'Release to send · slide up to cancel'**
  String get chatVoiceReleaseToSend;

  /// No description provided for @chatAddToStickers.
  ///
  /// In en, this message translates to:
  /// **'Add to Stickers'**
  String get chatAddToStickers;

  /// No description provided for @chatStickerAddedToMine.
  ///
  /// In en, this message translates to:
  /// **'Added to My Stickers'**
  String get chatStickerAddedToMine;

  /// No description provided for @chatStickerAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t add sticker'**
  String get chatStickerAddFailed;

  /// No description provided for @chatRecallConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Recall this message?'**
  String get chatRecallConfirmBody;

  /// No description provided for @chatDeleteMsgSendingBody.
  ///
  /// In en, this message translates to:
  /// **'This message is still sending. Remove it only on this device?'**
  String get chatDeleteMsgSendingBody;

  /// No description provided for @chatDeleteMsgPrivateBody.
  ///
  /// In en, this message translates to:
  /// **'Delete removes this message from the server and both devices. Copies already read, copied, forwarded, screenshotted, downloaded, or saved locally by the other side cannot be revoked. Delete?'**
  String get chatDeleteMsgPrivateBody;

  /// No description provided for @chatDeleteMsgGroupBody.
  ///
  /// In en, this message translates to:
  /// **'Delete removes this message from the server and group members\' devices. Copies already read, copied, forwarded, screenshotted, downloaded, or saved locally cannot be revoked. Delete?'**
  String get chatDeleteMsgGroupBody;

  /// No description provided for @chatDeleteMsgSecretBody.
  ///
  /// In en, this message translates to:
  /// **'Secret chat messages are end-to-end encrypted. Deleting only removes it from this device; the other device is unaffected. Delete?'**
  String get chatDeleteMsgSecretBody;

  /// No description provided for @callTraceFallback.
  ///
  /// In en, this message translates to:
  /// **'[Call]'**
  String get callTraceFallback;

  /// No description provided for @callTraceVideoCompleted.
  ///
  /// In en, this message translates to:
  /// **'Call duration {duration}'**
  String callTraceVideoCompleted(String duration);

  /// No description provided for @callTraceAudioCompleted.
  ///
  /// In en, this message translates to:
  /// **'Call duration {duration}'**
  String callTraceAudioCompleted(String duration);

  /// No description provided for @callTraceVideoCancelled.
  ///
  /// In en, this message translates to:
  /// **'Video call canceled'**
  String get callTraceVideoCancelled;

  /// No description provided for @callTraceAudioCancelled.
  ///
  /// In en, this message translates to:
  /// **'Voice call canceled'**
  String get callTraceAudioCancelled;

  /// No description provided for @callTraceVideoRejected.
  ///
  /// In en, this message translates to:
  /// **'Video call declined'**
  String get callTraceVideoRejected;

  /// No description provided for @callTraceAudioRejected.
  ///
  /// In en, this message translates to:
  /// **'Voice call declined'**
  String get callTraceAudioRejected;

  /// No description provided for @callTraceVideoBusy.
  ///
  /// In en, this message translates to:
  /// **'Video call line busy'**
  String get callTraceVideoBusy;

  /// No description provided for @callTraceAudioBusy.
  ///
  /// In en, this message translates to:
  /// **'Voice call line busy'**
  String get callTraceAudioBusy;

  /// No description provided for @callTraceVideoFailed.
  ///
  /// In en, this message translates to:
  /// **'Video call not connected'**
  String get callTraceVideoFailed;

  /// No description provided for @callTraceAudioFailed.
  ///
  /// In en, this message translates to:
  /// **'Voice call not connected'**
  String get callTraceAudioFailed;

  /// No description provided for @callTraceResolvedOtherDevice.
  ///
  /// In en, this message translates to:
  /// **'Call answered on another device'**
  String get callTraceResolvedOtherDevice;

  /// No description provided for @callScreenUnknownRemote.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get callScreenUnknownRemote;

  /// No description provided for @callStatusRinging.
  ///
  /// In en, this message translates to:
  /// **'Calling…'**
  String get callStatusRinging;

  /// No description provided for @callStatusWaitingForAnswer.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the other person to answer…'**
  String get callStatusWaitingForAnswer;

  /// No description provided for @callStatusIncoming.
  ///
  /// In en, this message translates to:
  /// **'Incoming…'**
  String get callStatusIncoming;

  /// No description provided for @callStatusConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get callStatusConnecting;

  /// No description provided for @callStatusInCall.
  ///
  /// In en, this message translates to:
  /// **'In call'**
  String get callStatusInCall;

  /// No description provided for @callErrorMediaPermission.
  ///
  /// In en, this message translates to:
  /// **'Can\'t access the camera or microphone. Check permissions and try again.'**
  String get callErrorMediaPermission;

  /// No description provided for @callErrorMediaNeedsHttps.
  ///
  /// In en, this message translates to:
  /// **'Use HTTPS or localhost so your browser can use the camera and microphone.'**
  String get callErrorMediaNeedsHttps;

  /// No description provided for @callErrorSocketForCall.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the call service. Check your network and try again.'**
  String get callErrorSocketForCall;

  /// No description provided for @callErrorAcceptFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t answer. Please try again.'**
  String get callErrorAcceptFailed;

  /// No description provided for @callErrorTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timed out. The other party may not have answered.'**
  String get callErrorTimeout;

  /// No description provided for @callActionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get callActionBack;

  /// No description provided for @callActionAnswer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get callActionAnswer;

  /// No description provided for @callActionReject.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get callActionReject;

  /// No description provided for @callActionMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get callActionMute;

  /// No description provided for @callActionUnmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get callActionUnmute;

  /// No description provided for @callActionMicrophoneOn.
  ///
  /// In en, this message translates to:
  /// **'Microphone on'**
  String get callActionMicrophoneOn;

  /// No description provided for @callActionMicrophoneOff.
  ///
  /// In en, this message translates to:
  /// **'Microphone off'**
  String get callActionMicrophoneOff;

  /// No description provided for @callActionSpeakerOn.
  ///
  /// In en, this message translates to:
  /// **'Speaker on'**
  String get callActionSpeakerOn;

  /// No description provided for @callActionSpeakerOff.
  ///
  /// In en, this message translates to:
  /// **'Speaker off'**
  String get callActionSpeakerOff;

  /// No description provided for @callActionSwitchCamera.
  ///
  /// In en, this message translates to:
  /// **'Flip camera'**
  String get callActionSwitchCamera;

  /// No description provided for @callActionCameraOn.
  ///
  /// In en, this message translates to:
  /// **'Camera on'**
  String get callActionCameraOn;

  /// No description provided for @callActionCameraOff.
  ///
  /// In en, this message translates to:
  /// **'Camera off'**
  String get callActionCameraOff;

  /// No description provided for @callActionCameraEnabled.
  ///
  /// In en, this message translates to:
  /// **'Camera on'**
  String get callActionCameraEnabled;

  /// No description provided for @callActionCameraDisabled.
  ///
  /// In en, this message translates to:
  /// **'Camera off'**
  String get callActionCameraDisabled;

  /// No description provided for @callActionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get callActionCancel;

  /// No description provided for @callActionHangUp.
  ///
  /// In en, this message translates to:
  /// **'Hang up'**
  String get callActionHangUp;

  /// No description provided for @callActionMinimize.
  ///
  /// In en, this message translates to:
  /// **'Minimize call'**
  String get callActionMinimize;

  /// No description provided for @callActionReturnToCall.
  ///
  /// In en, this message translates to:
  /// **'Return to call'**
  String get callActionReturnToCall;

  /// No description provided for @callActionBackgroundBlurEnabled.
  ///
  /// In en, this message translates to:
  /// **'Background blur on'**
  String get callActionBackgroundBlurEnabled;

  /// No description provided for @callActionBackgroundBlurDisabled.
  ///
  /// In en, this message translates to:
  /// **'Background blur off'**
  String get callActionBackgroundBlurDisabled;

  /// No description provided for @callActionBackgroundBlurSettings.
  ///
  /// In en, this message translates to:
  /// **'Background blur settings'**
  String get callActionBackgroundBlurSettings;

  /// No description provided for @callErrorBackgroundBlurUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Background blur isn\'t available on this device'**
  String get callErrorBackgroundBlurUnavailable;

  /// No description provided for @forwardMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Forward to friend'**
  String get forwardMessageTitle;

  /// No description provided for @forwardMessageAction.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get forwardMessageAction;

  /// No description provided for @recommendContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommend to friend'**
  String get recommendContactTitle;

  /// No description provided for @recommendContactAction.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get recommendContactAction;

  /// No description provided for @friendsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No friends yet'**
  String get friendsEmpty;

  /// No description provided for @friendsNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matching friends'**
  String get friendsNoMatches;

  /// No description provided for @chatAnnouncementTitle.
  ///
  /// In en, this message translates to:
  /// **'Announcement'**
  String get chatAnnouncementTitle;

  /// No description provided for @chatListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get chatListEmpty;

  /// No description provided for @chatPinConversation.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get chatPinConversation;

  /// No description provided for @chatUnpinConversation.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get chatUnpinConversation;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @chatGroupDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Group {id}'**
  String chatGroupDefaultTitle(String id);

  /// No description provided for @chatUserDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'User {id}'**
  String chatUserDefaultTitle(String id);

  /// No description provided for @chatMentionGroupNickname.
  ///
  /// In en, this message translates to:
  /// **'Group nickname: {nickname}'**
  String chatMentionGroupNickname(String nickname);

  /// No description provided for @chatMentionGroupNicknameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Group nickname: None'**
  String get chatMentionGroupNicknameEmpty;

  /// No description provided for @chatTypingPeer.
  ///
  /// In en, this message translates to:
  /// **'Typing...'**
  String get chatTypingPeer;

  /// No description provided for @chatActionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get chatActionCopy;

  /// No description provided for @chatMediaCopied.
  ///
  /// In en, this message translates to:
  /// **'Media copied'**
  String get chatMediaCopied;

  /// No description provided for @chatMediaCopyFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t copy this media'**
  String get chatMediaCopyFailed;

  /// No description provided for @chatActionReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get chatActionReply;

  /// No description provided for @chatActionForward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get chatActionForward;

  /// No description provided for @chatActionRecall.
  ///
  /// In en, this message translates to:
  /// **'Recall'**
  String get chatActionRecall;

  /// No description provided for @chatNewMessage.
  ///
  /// In en, this message translates to:
  /// **'New messages'**
  String get chatNewMessage;

  /// No description provided for @chatStickerPreview.
  ///
  /// In en, this message translates to:
  /// **'[Sticker]'**
  String get chatStickerPreview;

  /// No description provided for @chatMessageRecalledSelf.
  ///
  /// In en, this message translates to:
  /// **'You recalled a message'**
  String get chatMessageRecalledSelf;

  /// No description provided for @chatMessageRecalledPeer.
  ///
  /// In en, this message translates to:
  /// **'The other person recalled a message'**
  String get chatMessageRecalledPeer;

  /// No description provided for @chatSending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get chatSending;

  /// No description provided for @chatVoiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Voice message'**
  String get chatVoiceMessage;

  /// No description provided for @chatTapToDownload.
  ///
  /// In en, this message translates to:
  /// **'Tap to download'**
  String get chatTapToDownload;

  /// No description provided for @chatNameCard.
  ///
  /// In en, this message translates to:
  /// **'Contact card'**
  String get chatNameCard;

  /// No description provided for @chatPersonalNameCard.
  ///
  /// In en, this message translates to:
  /// **'Personal card'**
  String get chatPersonalNameCard;

  /// No description provided for @composerKeyboardInput.
  ///
  /// In en, this message translates to:
  /// **'Keyboard input'**
  String get composerKeyboardInput;

  /// No description provided for @composerVoiceInput.
  ///
  /// In en, this message translates to:
  /// **'Voice input'**
  String get composerVoiceInput;

  /// No description provided for @commonMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get commonMore;

  /// No description provided for @chatImageCaptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Send image'**
  String get chatImageCaptionTitle;

  /// No description provided for @chatImageCaptionHint.
  ///
  /// In en, this message translates to:
  /// **'Add a caption (optional, up to 200 characters)'**
  String get chatImageCaptionHint;

  /// No description provided for @chatClipboardImageReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t read the image from the clipboard'**
  String get chatClipboardImageReadFailed;

  /// No description provided for @commonSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get commonSend;

  /// No description provided for @reservationTitle.
  ///
  /// In en, this message translates to:
  /// **'Reservations'**
  String get reservationTitle;

  /// No description provided for @reservationEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Book hotels, KTV and in-store services'**
  String get reservationEntrySubtitle;

  /// No description provided for @reservationMine.
  ///
  /// In en, this message translates to:
  /// **'My reservations'**
  String get reservationMine;

  /// No description provided for @reservationMineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View pending and completed reservations'**
  String get reservationMineSubtitle;

  /// No description provided for @reservationChooseService.
  ///
  /// In en, this message translates to:
  /// **'Choose a service'**
  String get reservationChooseService;

  /// No description provided for @reservationNoServices.
  ///
  /// In en, this message translates to:
  /// **'No services available'**
  String get reservationNoServices;

  /// No description provided for @reservationNoStores.
  ///
  /// In en, this message translates to:
  /// **'No stores available for this service'**
  String get reservationNoStores;

  /// No description provided for @reservationCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Book {service}'**
  String reservationCreateTitle(String service);

  /// No description provided for @reservationStoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get reservationStoreLabel;

  /// No description provided for @reservationStoreAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get reservationStoreAddress;

  /// No description provided for @reservationServiceTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get reservationServiceTypeLabel;

  /// No description provided for @reservationContactNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact name'**
  String get reservationContactNameLabel;

  /// No description provided for @reservationPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get reservationPhoneLabel;

  /// No description provided for @reservationDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get reservationDateLabel;

  /// No description provided for @reservationTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get reservationTimeLabel;

  /// No description provided for @reservationPersonNumLabel.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get reservationPersonNumLabel;

  /// No description provided for @reservationPersonNumValue.
  ///
  /// In en, this message translates to:
  /// **'{count} guests'**
  String reservationPersonNumValue(int count);

  /// No description provided for @reservationDecreasePerson.
  ///
  /// In en, this message translates to:
  /// **'Fewer guests'**
  String get reservationDecreasePerson;

  /// No description provided for @reservationIncreasePerson.
  ///
  /// In en, this message translates to:
  /// **'More guests'**
  String get reservationIncreasePerson;

  /// No description provided for @reservationRemarkLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (room type or other requests)'**
  String get reservationRemarkLabel;

  /// No description provided for @reservationSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit reservation'**
  String get reservationSubmit;

  /// No description provided for @reservationSubmitHint.
  ///
  /// In en, this message translates to:
  /// **'Points are applied only when the store verifies the service'**
  String get reservationSubmitHint;

  /// No description provided for @reservationSelectStoreError.
  ///
  /// In en, this message translates to:
  /// **'Select a store'**
  String get reservationSelectStoreError;

  /// No description provided for @reservationContactNameError.
  ///
  /// In en, this message translates to:
  /// **'Enter a contact name of 1-32 characters'**
  String get reservationContactNameError;

  /// No description provided for @reservationPhoneError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number of up to 30 digits'**
  String get reservationPhoneError;

  /// No description provided for @reservationRemarkError.
  ///
  /// In en, this message translates to:
  /// **'Notes cannot exceed 512 characters'**
  String get reservationRemarkError;

  /// No description provided for @reservationCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reservation submitted. The store will verify it offline.'**
  String get reservationCreatedSuccess;

  /// No description provided for @reservationPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get reservationPending;

  /// No description provided for @reservationVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get reservationVerified;

  /// No description provided for @reservationEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reservations yet'**
  String get reservationEmpty;

  /// No description provided for @reservationPointsDeducted.
  ///
  /// In en, this message translates to:
  /// **'{points} points used'**
  String reservationPointsDeducted(int points);

  /// No description provided for @reservationDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Reservation details'**
  String get reservationDetailTitle;

  /// No description provided for @reservationPendingHint.
  ///
  /// In en, this message translates to:
  /// **'Arrive at the selected time. The store will verify the service.'**
  String get reservationPendingHint;

  /// No description provided for @reservationVerifiedHint.
  ///
  /// In en, this message translates to:
  /// **'This reservation has been verified'**
  String get reservationVerifiedHint;

  /// No description provided for @reservationServiceInfo.
  ///
  /// In en, this message translates to:
  /// **'Reservation'**
  String get reservationServiceInfo;

  /// No description provided for @reservationContactInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get reservationContactInfo;

  /// No description provided for @reservationSettlementInfo.
  ///
  /// In en, this message translates to:
  /// **'Settlement'**
  String get reservationSettlementInfo;

  /// No description provided for @reservationOrderInfo.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get reservationOrderInfo;

  /// No description provided for @reservationConsumeAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount spent'**
  String get reservationConsumeAmount;

  /// No description provided for @reservationVerifyTime.
  ///
  /// In en, this message translates to:
  /// **'Verified at'**
  String get reservationVerifyTime;

  /// No description provided for @reservationPointAmount.
  ///
  /// In en, this message translates to:
  /// **'Points discount'**
  String get reservationPointAmount;

  /// No description provided for @reservationPointDeductFailed.
  ///
  /// In en, this message translates to:
  /// **'Points deduction failed. Contact the store.'**
  String get reservationPointDeductFailed;

  /// No description provided for @reservationOrderNo.
  ///
  /// In en, this message translates to:
  /// **'Order number'**
  String get reservationOrderNo;

  /// No description provided for @reservationCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Submitted at'**
  String get reservationCreatedAt;

  /// No description provided for @reservationCurrency.
  ///
  /// In en, this message translates to:
  /// **'¥{amount}'**
  String reservationCurrency(String amount);

  /// No description provided for @channelComposerReadOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Only admins can post'**
  String get channelComposerReadOnlyHint;

  /// No description provided for @groupDissolvedComposerReadOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'This group was dissolved. You can\'t send messages.'**
  String get groupDissolvedComposerReadOnlyHint;

  /// No description provided for @channelCreateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get channelCreateConfirm;

  /// No description provided for @channelCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create channel'**
  String get channelCreateTitle;

  /// No description provided for @channelInfoHint.
  ///
  /// In en, this message translates to:
  /// **'Channels are one-way broadcasts: only admins can post; subscribers can read and receive notifications.'**
  String get channelInfoHint;

  /// No description provided for @channelSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search channels'**
  String get channelSearchTitle;

  /// No description provided for @channelSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Type a channel name or paste a channel code'**
  String get channelSearchHint;

  /// No description provided for @channelSearchEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Type a channel name and press search'**
  String get channelSearchEmptyHint;

  /// No description provided for @channelSearchNoResult.
  ///
  /// In en, this message translates to:
  /// **'No channels found'**
  String get channelSearchNoResult;

  /// No description provided for @channelJoinByCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Join by channel code'**
  String get channelJoinByCodeTitle;

  /// No description provided for @channelJoinByCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter channel code (e.g. cABC2345)'**
  String get channelJoinByCodeHint;

  /// No description provided for @channelJoinConfirm.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get channelJoinConfirm;

  /// No description provided for @channelJoined.
  ///
  /// In en, this message translates to:
  /// **'Subscribed'**
  String get channelJoined;

  /// No description provided for @channelInfoHintShort.
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get channelInfoHintShort;

  /// No description provided for @channelShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share channel'**
  String get channelShareTitle;

  /// No description provided for @channelShareCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Channel code'**
  String get channelShareCodeLabel;

  /// No description provided for @channelShareLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Channel link'**
  String get channelShareLinkLabel;

  /// No description provided for @channelQrCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Channel QR Code'**
  String get channelQrCodeTitle;

  /// No description provided for @channelQrCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Open the app and scan to subscribe'**
  String get channelQrCodeHint;

  /// No description provided for @channelShareToChat.
  ///
  /// In en, this message translates to:
  /// **'Share to chat'**
  String get channelShareToChat;

  /// No description provided for @channelShareSectionFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get channelShareSectionFriends;

  /// No description provided for @channelShareSectionGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get channelShareSectionGroups;

  /// No description provided for @channelShareSectionChannels.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get channelShareSectionChannels;

  /// No description provided for @channelShareSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get channelShareSearchHint;

  /// No description provided for @channelShareEmpty.
  ///
  /// In en, this message translates to:
  /// **'No chats to share to'**
  String get channelShareEmpty;

  /// No description provided for @channelShareNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching chats'**
  String get channelShareNoMatch;

  /// No description provided for @shareMediaTitle.
  ///
  /// In en, this message translates to:
  /// **'Send to'**
  String get shareMediaTitle;

  /// No description provided for @channelUnsubscribeAction.
  ///
  /// In en, this message translates to:
  /// **'Unsubscribe'**
  String get channelUnsubscribeAction;

  /// No description provided for @channelUnsubscribeConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsubscribe'**
  String get channelUnsubscribeConfirmTitle;

  /// No description provided for @channelUnsubscribeConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You will no longer receive messages from this channel. Unsubscribe?'**
  String get channelUnsubscribeConfirmBody;

  /// No description provided for @channelEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit Channel'**
  String get channelEditAction;

  /// No description provided for @channelEditNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Channel name'**
  String get channelEditNameLabel;

  /// No description provided for @channelEditAnnouncementLabel.
  ///
  /// In en, this message translates to:
  /// **'Announcement'**
  String get channelEditAnnouncementLabel;

  /// No description provided for @channelEditAnnouncementHint.
  ///
  /// In en, this message translates to:
  /// **'Channel announcement (optional)'**
  String get channelEditAnnouncementHint;

  /// No description provided for @channelDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete Channel'**
  String get channelDeleteAction;

  /// No description provided for @channelDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Channel'**
  String get channelDeleteConfirmTitle;

  /// No description provided for @channelDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'All subscribers will lose access and this cannot be undone. Delete?'**
  String get channelDeleteConfirmBody;

  /// No description provided for @toastChannelShareCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied — share it with friends'**
  String get toastChannelShareCopied;

  /// No description provided for @toastChannelNotFound.
  ///
  /// In en, this message translates to:
  /// **'Channel not found or dissolved'**
  String get toastChannelNotFound;

  /// No description provided for @toastChannelUpdated.
  ///
  /// In en, this message translates to:
  /// **'Channel updated'**
  String get toastChannelUpdated;

  /// No description provided for @toastChannelDeleted.
  ///
  /// In en, this message translates to:
  /// **'Channel deleted'**
  String get toastChannelDeleted;

  /// No description provided for @toastChannelUnsubscribed.
  ///
  /// In en, this message translates to:
  /// **'Unsubscribed'**
  String get toastChannelUnsubscribed;

  /// No description provided for @toastEnterChannelName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a channel name'**
  String get toastEnterChannelName;

  /// No description provided for @channelMemberCount.
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String channelMemberCount(int count);

  /// No description provided for @channelNameHint.
  ///
  /// In en, this message translates to:
  /// **'Channel name'**
  String get channelNameHint;

  /// No description provided for @channelRoleOwner.
  ///
  /// In en, this message translates to:
  /// **'Channel admin'**
  String get channelRoleOwner;

  /// No description provided for @channelRoleSubscriber.
  ///
  /// In en, this message translates to:
  /// **'Subscriber'**
  String get channelRoleSubscriber;

  /// No description provided for @channelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Admins only'**
  String get channelSubtitle;

  /// No description provided for @chatChannelDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Channel {id}'**
  String chatChannelDefaultTitle(String id);

  /// No description provided for @chatSecretDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Secret chat {id}'**
  String chatSecretDefaultTitle(String id);

  /// No description provided for @convTypeChannel.
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get convTypeChannel;

  /// No description provided for @convTypeGroup.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get convTypeGroup;

  /// No description provided for @convTypePrivate.
  ///
  /// In en, this message translates to:
  /// **'Cloud chat'**
  String get convTypePrivate;

  /// No description provided for @convTypeSecret.
  ///
  /// In en, this message translates to:
  /// **'Secret chat'**
  String get convTypeSecret;

  /// No description provided for @featureChannelDisabled.
  ///
  /// In en, this message translates to:
  /// **'Channels are turned off'**
  String get featureChannelDisabled;

  /// No description provided for @featureSecretChatDisabled.
  ///
  /// In en, this message translates to:
  /// **'Secret chats are turned off'**
  String get featureSecretChatDisabled;

  /// No description provided for @secretChatBanner.
  ///
  /// In en, this message translates to:
  /// **'End-to-end encrypted · never synced to new devices'**
  String get secretChatBanner;

  /// No description provided for @secretChatRecordingWarning.
  ///
  /// In en, this message translates to:
  /// **'Screen recording detected. Please do not share secret chat content.'**
  String get secretChatRecordingWarning;

  /// No description provided for @secretChatScreenshotWarning.
  ///
  /// In en, this message translates to:
  /// **'Screenshot detected. Please do not share secret chat content.'**
  String get secretChatScreenshotWarning;

  /// No description provided for @secretChatDestroy1d.
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get secretChatDestroy1d;

  /// No description provided for @secretChatDestroy1h.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get secretChatDestroy1h;

  /// No description provided for @secretChatDestroy1m.
  ///
  /// In en, this message translates to:
  /// **'1 minute'**
  String get secretChatDestroy1m;

  /// No description provided for @secretChatDestroy1s.
  ///
  /// In en, this message translates to:
  /// **'1 second'**
  String get secretChatDestroy1s;

  /// No description provided for @secretChatDestroy1w.
  ///
  /// In en, this message translates to:
  /// **'1 week'**
  String get secretChatDestroy1w;

  /// No description provided for @secretChatDestroy2s.
  ///
  /// In en, this message translates to:
  /// **'2 seconds'**
  String get secretChatDestroy2s;

  /// No description provided for @secretChatDestroy30s.
  ///
  /// In en, this message translates to:
  /// **'30 seconds'**
  String get secretChatDestroy30s;

  /// No description provided for @secretChatDestroy5m.
  ///
  /// In en, this message translates to:
  /// **'5 minutes'**
  String get secretChatDestroy5m;

  /// No description provided for @secretChatDestroy5s.
  ///
  /// In en, this message translates to:
  /// **'5 seconds'**
  String get secretChatDestroy5s;

  /// No description provided for @secretChatDestroy10s.
  ///
  /// In en, this message translates to:
  /// **'10 seconds'**
  String get secretChatDestroy10s;

  /// No description provided for @secretChatDestroyOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get secretChatDestroyOff;

  /// No description provided for @secretChatDestroyTitle.
  ///
  /// In en, this message translates to:
  /// **'Self-destruct timer'**
  String get secretChatDestroyTitle;

  /// No description provided for @secretChatNoSyncHint.
  ///
  /// In en, this message translates to:
  /// **'Secret chats are visible only on participating devices and never sync to new devices; the server only relays encrypted data.'**
  String get secretChatNoSyncHint;

  /// No description provided for @secretChatSafeCodeIntro.
  ///
  /// In en, this message translates to:
  /// **'Compare the codes on both devices to verify there is no man-in-the-middle.'**
  String get secretChatSafeCodeIntro;

  /// No description provided for @secretChatSafeCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get secretChatSafeCodeTitle;

  /// No description provided for @secretChatSafeCodeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Generated automatically once the peer joins — used to verify encryption safety'**
  String get secretChatSafeCodeUnavailable;

  /// No description provided for @secretChatSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Secret chat settings'**
  String get secretChatSettingsTitle;

  /// No description provided for @secretChatStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Start secret chat'**
  String get secretChatStartTitle;

  /// No description provided for @secretChatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'End-to-end encrypted'**
  String get secretChatSubtitle;

  /// No description provided for @secretChatDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete secret chat'**
  String get secretChatDeleteTitle;

  /// No description provided for @secretChatDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This will remove the secret chat and all of its messages from both devices. This cannot be undone.'**
  String get secretChatDeleteBody;

  /// No description provided for @convTypeSecretGroup.
  ///
  /// In en, this message translates to:
  /// **'Secret group'**
  String get convTypeSecretGroup;

  /// No description provided for @featureSecretGroupChatDisabled.
  ///
  /// In en, this message translates to:
  /// **'Secret groups are turned off'**
  String get featureSecretGroupChatDisabled;

  /// No description provided for @secretGroupChatBanner.
  ///
  /// In en, this message translates to:
  /// **'End-to-end encrypted · encrypted per member'**
  String get secretGroupChatBanner;

  /// No description provided for @secretGroupChatDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Secret group'**
  String get secretGroupChatDefaultTitle;

  /// No description provided for @secretGroupChatSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Secret group settings'**
  String get secretGroupChatSettingsTitle;

  /// No description provided for @secretGroupMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get secretGroupMembersTitle;

  /// No description provided for @secretGroupChatStartTitle.
  ///
  /// In en, this message translates to:
  /// **'New secret group'**
  String get secretGroupChatStartTitle;

  /// No description provided for @secretGroupChatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'End-to-end encrypted'**
  String get secretGroupChatSubtitle;

  /// No description provided for @secretGroupChatDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete secret group'**
  String get secretGroupChatDeleteTitle;

  /// No description provided for @secretGroupChatDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This will remove the secret group chat from this device only.'**
  String get secretGroupChatDeleteBody;

  /// No description provided for @toastSecretGroupChatCreated.
  ///
  /// In en, this message translates to:
  /// **'Secret group created'**
  String get toastSecretGroupChatCreated;

  /// No description provided for @toastChannelCreated.
  ///
  /// In en, this message translates to:
  /// **'Channel created'**
  String get toastChannelCreated;

  /// No description provided for @toastChannelUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Channel is unavailable or was deleted'**
  String get toastChannelUnavailable;

  /// No description provided for @toastSecretChatCreated.
  ///
  /// In en, this message translates to:
  /// **'Secret chat created'**
  String get toastSecretChatCreated;

  /// No description provided for @toastSecretChatDestroyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Self-destruct timer updated'**
  String get toastSecretChatDestroyUpdated;

  /// No description provided for @toastSecretChatSafeCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Verification code copied'**
  String get toastSecretChatSafeCodeCopied;

  /// No description provided for @toastSecretChatUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Secret chat is unavailable or was destroyed'**
  String get toastSecretChatUnavailable;

  /// No description provided for @toastSecretChatWaitingPeer.
  ///
  /// In en, this message translates to:
  /// **'Encrypted messages can be sent once the peer joins'**
  String get toastSecretChatWaitingPeer;

  /// No description provided for @selfDestructTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-clear chat history'**
  String get selfDestructTitle;

  /// No description provided for @selfDestructOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get selfDestructOff;

  /// No description provided for @selfDestruct1mo.
  ///
  /// In en, this message translates to:
  /// **'1 month'**
  String get selfDestruct1mo;

  /// No description provided for @selfDestruct3mo.
  ///
  /// In en, this message translates to:
  /// **'3 months'**
  String get selfDestruct3mo;

  /// No description provided for @selfDestruct6mo.
  ///
  /// In en, this message translates to:
  /// **'6 months'**
  String get selfDestruct6mo;

  /// No description provided for @selfDestruct1yr.
  ///
  /// In en, this message translates to:
  /// **'1 year'**
  String get selfDestruct1yr;

  /// No description provided for @selfDestructHint.
  ///
  /// In en, this message translates to:
  /// **'If you don’t sign in for the selected period, all of your chat records will be cleared automatically. Your account itself is kept and you can still sign in.'**
  String get selfDestructHint;

  /// No description provided for @selfDestructUpdated.
  ///
  /// In en, this message translates to:
  /// **'Auto-clear chat history policy updated'**
  String get selfDestructUpdated;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get forgotPasswordEmailHint;

  /// No description provided for @forgotPasswordEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get forgotPasswordEmailRequired;

  /// No description provided for @forgotPasswordEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get forgotPasswordEmailInvalid;

  /// No description provided for @forgotPasswordSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send reset email'**
  String get forgotPasswordSubmit;

  /// No description provided for @forgotPasswordSent.
  ///
  /// In en, this message translates to:
  /// **'Email sent'**
  String get forgotPasswordSent;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordTokenHint.
  ///
  /// In en, this message translates to:
  /// **'Reset token'**
  String get resetPasswordTokenHint;

  /// No description provided for @resetPasswordTokenRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the reset token'**
  String get resetPasswordTokenRequired;

  /// No description provided for @resetPasswordNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'New password (6-128 characters)'**
  String get resetPasswordNewPasswordHint;

  /// No description provided for @resetPasswordPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'New password must be 6-128 characters'**
  String get resetPasswordPasswordRequired;

  /// No description provided for @resetPasswordSubmit.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordSubmit;

  /// No description provided for @resetPasswordDone.
  ///
  /// In en, this message translates to:
  /// **'Password reset. Please sign in again'**
  String get resetPasswordDone;

  /// No description provided for @chatAtMentionYou.
  ///
  /// In en, this message translates to:
  /// **'@you'**
  String get chatAtMentionYou;

  /// No description provided for @chatMuteConversation.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get chatMuteConversation;

  /// No description provided for @chatUnmuteConversation.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get chatUnmuteConversation;

  /// No description provided for @chatDraftPrefix.
  ///
  /// In en, this message translates to:
  /// **'[Draft]'**
  String get chatDraftPrefix;

  /// No description provided for @chatActionFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get chatActionFavorite;

  /// No description provided for @favoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesTitle;

  /// No description provided for @favoritesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get favoritesEmpty;

  /// No description provided for @favoritesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get favoritesLoadFailed;

  /// No description provided for @favoriteAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get favoriteAdded;

  /// No description provided for @favoriteAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to favorite'**
  String get favoriteAddFailed;

  /// No description provided for @favoriteRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get favoriteRemoved;

  /// No description provided for @favoriteRemovedFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove favorite'**
  String get favoriteRemovedFailed;

  /// No description provided for @favoritesDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorite details'**
  String get favoritesDetailTitle;

  /// No description provided for @favoritesViewOriginal.
  ///
  /// In en, this message translates to:
  /// **'View original message'**
  String get favoritesViewOriginal;

  /// No description provided for @favoritesSourceMessageDeleted.
  ///
  /// In en, this message translates to:
  /// **'The original message was deleted. Only the saved content is available.'**
  String get favoritesSourceMessageDeleted;

  /// No description provided for @favoritesSourceConversationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The original conversation is unavailable. Only the saved content is available.'**
  String get favoritesSourceConversationUnavailable;

  /// No description provided for @favoritesSourceNoPermission.
  ///
  /// In en, this message translates to:
  /// **'You no longer have access to the original message. Only the saved content is available.'**
  String get favoritesSourceNoPermission;

  /// No description provided for @favoritesSourceLookupUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Can\'t confirm whether the original message is still available. Please try again later.'**
  String get favoritesSourceLookupUnavailable;

  /// No description provided for @favoritesSourceConversationMissing.
  ///
  /// In en, this message translates to:
  /// **'The original conversation can\'t be located, so it can\'t be opened.'**
  String get favoritesSourceConversationMissing;

  /// No description provided for @favoritesContentEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved content (the original message may have been deleted)'**
  String get favoritesContentEmpty;

  /// No description provided for @favoritesDetailTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get favoritesDetailTime;

  /// No description provided for @favoritesFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get favoritesFilterAll;

  /// No description provided for @favoritesFilterText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get favoritesFilterText;

  /// No description provided for @favoritesFilterImage.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get favoritesFilterImage;

  /// No description provided for @favoritesFilterVideo.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get favoritesFilterVideo;

  /// No description provided for @favoritesFilterVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get favoritesFilterVoice;

  /// No description provided for @favoritesFilterFile.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get favoritesFilterFile;

  /// No description provided for @favoritesFilterOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get favoritesFilterOther;

  /// No description provided for @favoritesFilterEmpty.
  ///
  /// In en, this message translates to:
  /// **'No favorites of this type'**
  String get favoritesFilterEmpty;

  /// No description provided for @favoritesDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this favorite?'**
  String get favoritesDeleteConfirm;

  /// No description provided for @favoritesBatchAdded.
  ///
  /// In en, this message translates to:
  /// **'Favorited {count} messages'**
  String favoritesBatchAdded(int count);

  /// No description provided for @favoritesBatchAddedWithSkipped.
  ///
  /// In en, this message translates to:
  /// **'Favorited {count} messages, {skipped} already saved'**
  String favoritesBatchAddedWithSkipped(int count, int skipped);

  /// No description provided for @favoritesBatchAlreadySaved.
  ///
  /// In en, this message translates to:
  /// **'All selected messages were already favorited'**
  String get favoritesBatchAlreadySaved;

  /// No description provided for @favoritesBatchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No favoritable messages selected'**
  String get favoritesBatchEmpty;

  /// No description provided for @favoritesBatchFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to favorite'**
  String get favoritesBatchFailed;

  /// No description provided for @reservationChooseStore.
  ///
  /// In en, this message translates to:
  /// **'Choose a store'**
  String get reservationChooseStore;

  /// No description provided for @reservationPackageLabel.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get reservationPackageLabel;

  /// No description provided for @reservationTableTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Seating type'**
  String get reservationTableTypeLabel;

  /// No description provided for @reservationExactArrivalTime.
  ///
  /// In en, this message translates to:
  /// **'Arrival time'**
  String get reservationExactArrivalTime;

  /// No description provided for @reservationBarStandingPackage.
  ///
  /// In en, this message translates to:
  /// **'Standing table package'**
  String get reservationBarStandingPackage;

  /// No description provided for @reservationBarBoothPackage.
  ///
  /// In en, this message translates to:
  /// **'Booth package'**
  String get reservationBarBoothPackage;

  /// No description provided for @reservationBarRoomPackage.
  ///
  /// In en, this message translates to:
  /// **'Private room package'**
  String get reservationBarRoomPackage;

  /// No description provided for @reservationBilliardsStandardPackage.
  ///
  /// In en, this message translates to:
  /// **'Standard table package'**
  String get reservationBilliardsStandardPackage;

  /// No description provided for @reservationBilliardsVipPackage.
  ///
  /// In en, this message translates to:
  /// **'VIP table package'**
  String get reservationBilliardsVipPackage;

  /// No description provided for @reservationBilliardsRoomPackage.
  ///
  /// In en, this message translates to:
  /// **'Private billiards room package'**
  String get reservationBilliardsRoomPackage;

  /// No description provided for @reservationAreaStanding.
  ///
  /// In en, this message translates to:
  /// **'Standing table'**
  String get reservationAreaStanding;

  /// No description provided for @reservationAreaBooth.
  ///
  /// In en, this message translates to:
  /// **'Booth'**
  String get reservationAreaBooth;

  /// No description provided for @reservationAreaRoom.
  ///
  /// In en, this message translates to:
  /// **'Private room'**
  String get reservationAreaRoom;

  /// No description provided for @reservationAreaStandardTable.
  ///
  /// In en, this message translates to:
  /// **'Standard table'**
  String get reservationAreaStandardTable;

  /// No description provided for @reservationAreaVipTable.
  ///
  /// In en, this message translates to:
  /// **'VIP table'**
  String get reservationAreaVipTable;

  /// No description provided for @travelMockNotice.
  ///
  /// In en, this message translates to:
  /// **'Frontend demo only. Airports, flights, vehicles, and prices are mock data'**
  String get travelMockNotice;

  /// No description provided for @travelDomestic.
  ///
  /// In en, this message translates to:
  /// **'Domestic'**
  String get travelDomestic;

  /// No description provided for @travelInternational.
  ///
  /// In en, this message translates to:
  /// **'International'**
  String get travelInternational;

  /// No description provided for @travelRoundTrip.
  ///
  /// In en, this message translates to:
  /// **'Round trip'**
  String get travelRoundTrip;

  /// No description provided for @travelMultiCity.
  ///
  /// In en, this message translates to:
  /// **'Multi-city'**
  String get travelMultiCity;

  /// No description provided for @travelSpecialFare.
  ///
  /// In en, this message translates to:
  /// **'Special fares'**
  String get travelSpecialFare;

  /// No description provided for @travelInstantRide.
  ///
  /// In en, this message translates to:
  /// **'Ride now'**
  String get travelInstantRide;

  /// No description provided for @travelAirportPickup.
  ///
  /// In en, this message translates to:
  /// **'Airport pickup'**
  String get travelAirportPickup;

  /// No description provided for @travelAirportDropoff.
  ///
  /// In en, this message translates to:
  /// **'Airport drop-off'**
  String get travelAirportDropoff;

  /// No description provided for @travelFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get travelFrom;

  /// No description provided for @travelTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get travelTo;

  /// No description provided for @travelSwap.
  ///
  /// In en, this message translates to:
  /// **'Swap departure and arrival'**
  String get travelSwap;

  /// No description provided for @travelDepartureDate.
  ///
  /// In en, this message translates to:
  /// **'Departure date'**
  String get travelDepartureDate;

  /// No description provided for @travelPickupTime.
  ///
  /// In en, this message translates to:
  /// **'Pickup time'**
  String get travelPickupTime;

  /// No description provided for @travelPassengerCabin.
  ///
  /// In en, this message translates to:
  /// **'Passengers and cabin'**
  String get travelPassengerCabin;

  /// No description provided for @travelPassengerCount.
  ///
  /// In en, this message translates to:
  /// **'Passengers'**
  String get travelPassengerCount;

  /// No description provided for @travelEconomyCabin.
  ///
  /// In en, this message translates to:
  /// **'Economy · 1 adult'**
  String get travelEconomyCabin;

  /// No description provided for @travelOnePassenger.
  ///
  /// In en, this message translates to:
  /// **'1 passenger · 1 bag'**
  String get travelOnePassenger;

  /// No description provided for @travelSearchFlights.
  ///
  /// In en, this message translates to:
  /// **'Search flights'**
  String get travelSearchFlights;

  /// No description provided for @travelSearchRides.
  ///
  /// In en, this message translates to:
  /// **'Search rides'**
  String get travelSearchRides;

  /// No description provided for @travelSelectAirport.
  ///
  /// In en, this message translates to:
  /// **'Select airport'**
  String get travelSelectAirport;

  /// No description provided for @travelSelectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select location'**
  String get travelSelectLocation;

  /// No description provided for @travelFlightResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Flights'**
  String get travelFlightResultsTitle;

  /// No description provided for @travelTaxiResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Available rides'**
  String get travelTaxiResultsTitle;

  /// No description provided for @travelSmartSort.
  ///
  /// In en, this message translates to:
  /// **'Smart sort'**
  String get travelSmartSort;

  /// No description provided for @travelPriceSort.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get travelPriceSort;

  /// No description provided for @travelDepartureSort.
  ///
  /// In en, this message translates to:
  /// **'Departure'**
  String get travelDepartureSort;

  /// No description provided for @travelRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get travelRecommended;

  /// No description provided for @travelDirectFlight.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get travelDirectFlight;

  /// No description provided for @travelTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get travelTransfer;

  /// No description provided for @travelDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get travelDuration;

  /// No description provided for @travelBaggage.
  ///
  /// In en, this message translates to:
  /// **'20KG checked baggage included'**
  String get travelBaggage;

  /// No description provided for @travelRefundable.
  ///
  /// In en, this message translates to:
  /// **'Changes and refunds available'**
  String get travelRefundable;

  /// No description provided for @travelFlightDetails.
  ///
  /// In en, this message translates to:
  /// **'Flight details'**
  String get travelFlightDetails;

  /// No description provided for @travelRideDetails.
  ///
  /// In en, this message translates to:
  /// **'Ride details'**
  String get travelRideDetails;

  /// No description provided for @travelFareOptions.
  ///
  /// In en, this message translates to:
  /// **'Choose a fare'**
  String get travelFareOptions;

  /// No description provided for @travelBook.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get travelBook;

  /// No description provided for @travelEstimatedArrival.
  ///
  /// In en, this message translates to:
  /// **'Estimated arrival'**
  String get travelEstimatedArrival;

  /// No description provided for @travelVehicleCapacity.
  ///
  /// In en, this message translates to:
  /// **'Up to 4 passengers · 2 bags'**
  String get travelVehicleCapacity;

  /// No description provided for @travelIncludes.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get travelIncludes;

  /// No description provided for @travelDriverService.
  ///
  /// In en, this message translates to:
  /// **'Professional driver · Fixed price · Basic waiting included'**
  String get travelDriverService;

  /// No description provided for @travelFreeCancellation.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation up to 2 hours before departure'**
  String get travelFreeCancellation;

  /// No description provided for @travelFillOrder.
  ///
  /// In en, this message translates to:
  /// **'Order details'**
  String get travelFillOrder;

  /// No description provided for @travelTripSummary.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get travelTripSummary;

  /// No description provided for @travelPassengerInfo.
  ///
  /// In en, this message translates to:
  /// **'Passenger information'**
  String get travelPassengerInfo;

  /// No description provided for @travelBookerInfo.
  ///
  /// In en, this message translates to:
  /// **'Booker information'**
  String get travelBookerInfo;

  /// No description provided for @travelPassengerName.
  ///
  /// In en, this message translates to:
  /// **'Passenger name'**
  String get travelPassengerName;

  /// No description provided for @travelBookerName.
  ///
  /// In en, this message translates to:
  /// **'Booker name'**
  String get travelBookerName;

  /// No description provided for @travelIdNumber.
  ///
  /// In en, this message translates to:
  /// **'ID number'**
  String get travelIdNumber;

  /// No description provided for @travelPhone.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get travelPhone;

  /// No description provided for @travelRemark.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get travelRemark;

  /// No description provided for @travelNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get travelNameRequired;

  /// No description provided for @travelIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an ID number'**
  String get travelIdRequired;

  /// No description provided for @travelPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a mobile number'**
  String get travelPhoneRequired;

  /// No description provided for @travelPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid mobile number'**
  String get travelPhoneInvalid;

  /// No description provided for @travelSubmitOrder.
  ///
  /// In en, this message translates to:
  /// **'Submit order'**
  String get travelSubmitOrder;

  /// No description provided for @travelOrderSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get travelOrderSuccessTitle;

  /// No description provided for @travelOrderSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'The order was submitted. This is a frontend demo and no real charge will be made'**
  String get travelOrderSuccessBody;

  /// No description provided for @travelOrderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order number'**
  String get travelOrderNumber;

  /// No description provided for @travelItinerary.
  ///
  /// In en, this message translates to:
  /// **'Itinerary'**
  String get travelItinerary;

  /// No description provided for @travelTraveler.
  ///
  /// In en, this message translates to:
  /// **'Booker'**
  String get travelTraveler;

  /// No description provided for @travelTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get travelTotal;

  /// No description provided for @travelBackServices.
  ///
  /// In en, this message translates to:
  /// **'Back to services'**
  String get travelBackServices;

  /// No description provided for @travelShenzhen.
  ///
  /// In en, this message translates to:
  /// **'Shenzhen'**
  String get travelShenzhen;

  /// No description provided for @travelChongqing.
  ///
  /// In en, this message translates to:
  /// **'Chongqing'**
  String get travelChongqing;

  /// No description provided for @travelGuangzhou.
  ///
  /// In en, this message translates to:
  /// **'Guangzhou'**
  String get travelGuangzhou;

  /// No description provided for @travelShanghai.
  ///
  /// In en, this message translates to:
  /// **'Shanghai'**
  String get travelShanghai;

  /// No description provided for @travelShenzhenAirport.
  ///
  /// In en, this message translates to:
  /// **'Shenzhen Bao\'an International Airport T3'**
  String get travelShenzhenAirport;

  /// No description provided for @travelChongqingAirport.
  ///
  /// In en, this message translates to:
  /// **'Chongqing Jiangbei International Airport T3'**
  String get travelChongqingAirport;

  /// No description provided for @travelGuangzhouAirport.
  ///
  /// In en, this message translates to:
  /// **'Guangzhou Baiyun International Airport T2'**
  String get travelGuangzhouAirport;

  /// No description provided for @travelShanghaiAirport.
  ///
  /// In en, this message translates to:
  /// **'Shanghai Hongqiao International Airport T2'**
  String get travelShanghaiAirport;

  /// No description provided for @travelFutianCbd.
  ///
  /// In en, this message translates to:
  /// **'Futian CBD'**
  String get travelFutianCbd;

  /// No description provided for @travelShenzhenNorthStation.
  ///
  /// In en, this message translates to:
  /// **'Shenzhen North Railway Station'**
  String get travelShenzhenNorthStation;

  /// No description provided for @travelNanshanSciencePark.
  ///
  /// In en, this message translates to:
  /// **'Nanshan Science Park'**
  String get travelNanshanSciencePark;

  /// No description provided for @travelChinaSouthern.
  ///
  /// In en, this message translates to:
  /// **'China Southern Airlines'**
  String get travelChinaSouthern;

  /// No description provided for @travelShenzhenAirlines.
  ///
  /// In en, this message translates to:
  /// **'Shenzhen Airlines'**
  String get travelShenzhenAirlines;

  /// No description provided for @travelSpringAirlines.
  ///
  /// In en, this message translates to:
  /// **'Spring Airlines'**
  String get travelSpringAirlines;

  /// No description provided for @travelXiamenAir.
  ///
  /// In en, this message translates to:
  /// **'XiamenAir'**
  String get travelXiamenAir;

  /// No description provided for @travelEconomyFlexible.
  ///
  /// In en, this message translates to:
  /// **'Economy Flex'**
  String get travelEconomyFlexible;

  /// No description provided for @travelEconomyValue.
  ///
  /// In en, this message translates to:
  /// **'Economy Saver'**
  String get travelEconomyValue;

  /// No description provided for @travelBusinessCabin.
  ///
  /// In en, this message translates to:
  /// **'Business class'**
  String get travelBusinessCabin;

  /// No description provided for @travelComfortCar.
  ///
  /// In en, this message translates to:
  /// **'Comfort'**
  String get travelComfortCar;

  /// No description provided for @travelBusinessCar.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get travelBusinessCar;

  /// No description provided for @travelPremiumCar.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get travelPremiumCar;

  /// No description provided for @settingsChatStorage.
  ///
  /// In en, this message translates to:
  /// **'Chat history storage'**
  String get settingsChatStorage;

  /// No description provided for @chatStorageTotalUsed.
  ///
  /// In en, this message translates to:
  /// **'Local chat storage used'**
  String get chatStorageTotalUsed;

  /// No description provided for @chatStorageLocalOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'Deletes local records only; cloud data is unaffected'**
  String get chatStorageLocalOnlyNote;

  /// No description provided for @chatStorageClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get chatStorageClear;

  /// No description provided for @chatStorageClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get chatStorageClearAll;

  /// No description provided for @chatStorageClearAllRecords.
  ///
  /// In en, this message translates to:
  /// **'Clear all records'**
  String get chatStorageClearAllRecords;

  /// No description provided for @chatStorageClearMediaOnly.
  ///
  /// In en, this message translates to:
  /// **'Clear media cache only'**
  String get chatStorageClearMediaOnly;

  /// No description provided for @chatStorageClearRecordsConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all records'**
  String get chatStorageClearRecordsConfirmTitle;

  /// No description provided for @chatStorageClearRecordsConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Clear all local records in this chat? This deletes local records only and does not affect the cloud.'**
  String get chatStorageClearRecordsConfirmBody;

  /// No description provided for @chatStorageClearAllConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get chatStorageClearAllConfirmTitle;

  /// No description provided for @chatStorageClearAllConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Clear all local chat history and media cache? This deletes local records only and does not affect the cloud.'**
  String get chatStorageClearAllConfirmBody;

  /// No description provided for @chatStorageCleared.
  ///
  /// In en, this message translates to:
  /// **'Cleared'**
  String get chatStorageCleared;

  /// No description provided for @chatStorageEmpty.
  ///
  /// In en, this message translates to:
  /// **'No local chat history'**
  String get chatStorageEmpty;

  /// No description provided for @settingsChatBackup.
  ///
  /// In en, this message translates to:
  /// **'Chat history backup & transfer'**
  String get settingsChatBackup;

  /// No description provided for @chatBackupExportSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Back up chat history'**
  String get chatBackupExportSectionTitle;

  /// No description provided for @chatBackupExportDesc.
  ///
  /// In en, this message translates to:
  /// **'Export all local chat history of this account to a JSON file. Media is recorded as links (URL / object ID) only, without binaries.'**
  String get chatBackupExportDesc;

  /// No description provided for @chatBackupExportAction.
  ///
  /// In en, this message translates to:
  /// **'Back up to file'**
  String get chatBackupExportAction;

  /// No description provided for @chatBackupExporting.
  ///
  /// In en, this message translates to:
  /// **'Backing up…'**
  String get chatBackupExporting;

  /// No description provided for @chatBackupExportSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup complete'**
  String get chatBackupExportSuccessTitle;

  /// No description provided for @chatBackupExportSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Backed up {conversations} conversations and {messages} messages. Saved to: {path}'**
  String chatBackupExportSuccessBody(
      int conversations, int messages, String path);

  /// No description provided for @chatBackupExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed'**
  String get chatBackupExportFailed;

  /// No description provided for @chatBackupExportEmpty.
  ///
  /// In en, this message translates to:
  /// **'No local chat history to back up'**
  String get chatBackupExportEmpty;

  /// No description provided for @chatBackupRestoreSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore chat history'**
  String get chatBackupRestoreSectionTitle;

  /// No description provided for @chatBackupRestoreDesc.
  ///
  /// In en, this message translates to:
  /// **'Restore from a backup file. It merges into this device (deduplicated by message ID).'**
  String get chatBackupRestoreDesc;

  /// No description provided for @chatBackupRestoreAction.
  ///
  /// In en, this message translates to:
  /// **'Restore from file'**
  String get chatBackupRestoreAction;

  /// No description provided for @chatBackupRestoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm restore'**
  String get chatBackupRestoreConfirmTitle;

  /// No description provided for @chatBackupRestoreConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Restoring overwrite-merges local records (deduplicated by message ID) and cannot be undone. Continue?'**
  String get chatBackupRestoreConfirmBody;

  /// No description provided for @chatBackupRestoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Restored {conversations} conversations and {messages} messages'**
  String chatBackupRestoreSuccess(int conversations, int messages);

  /// No description provided for @chatBackupRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed'**
  String get chatBackupRestoreFailed;

  /// No description provided for @chatBackupRestoreInvalid.
  ///
  /// In en, this message translates to:
  /// **'The selected file is not a valid chat history backup'**
  String get chatBackupRestoreInvalid;

  /// No description provided for @gvFaGroupAllowMemberViewAccount.
  ///
  /// In en, this message translates to:
  /// **'Allow members to view others\' accounts'**
  String get gvFaGroupAllowMemberViewAccount;

  /// No description provided for @gvFaForgotMethodEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get gvFaForgotMethodEmail;

  /// No description provided for @gvFaForgotMethodPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get gvFaForgotMethodPhone;

  /// No description provided for @gvFaForgotMethodSecurityQuestion.
  ///
  /// In en, this message translates to:
  /// **'Security question'**
  String get gvFaForgotMethodSecurityQuestion;

  /// No description provided for @gvFaForgotPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get gvFaForgotPhoneHint;

  /// No description provided for @gvFaForgotPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get gvFaForgotPhoneRequired;

  /// No description provided for @gvFaForgotPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get gvFaForgotPhoneInvalid;

  /// No description provided for @gvFaForgotSendSmsCode.
  ///
  /// In en, this message translates to:
  /// **'Send SMS code'**
  String get gvFaForgotSendSmsCode;

  /// No description provided for @gvFaForgotSmsCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent'**
  String get gvFaForgotSmsCodeSent;

  /// No description provided for @gvFaResetMethodToken.
  ///
  /// In en, this message translates to:
  /// **'Reset token (email)'**
  String get gvFaResetMethodToken;

  /// No description provided for @gvFaResetMethodSms.
  ///
  /// In en, this message translates to:
  /// **'SMS code'**
  String get gvFaResetMethodSms;

  /// No description provided for @gvFaResetMethodSecurityQuestion.
  ///
  /// In en, this message translates to:
  /// **'Security question'**
  String get gvFaResetMethodSecurityQuestion;

  /// No description provided for @gvFaResetPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get gvFaResetPhoneHint;

  /// No description provided for @gvFaResetPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get gvFaResetPhoneRequired;

  /// No description provided for @gvFaResetSmsCodeHint.
  ///
  /// In en, this message translates to:
  /// **'SMS verification code'**
  String get gvFaResetSmsCodeHint;

  /// No description provided for @gvFaResetSmsCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the verification code'**
  String get gvFaResetSmsCodeRequired;

  /// No description provided for @gvFaResetUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get gvFaResetUsernameHint;

  /// No description provided for @gvFaResetUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your username'**
  String get gvFaResetUsernameRequired;

  /// No description provided for @gvFaResetSecurityQuestionHint.
  ///
  /// In en, this message translates to:
  /// **'Security question'**
  String get gvFaResetSecurityQuestionHint;

  /// No description provided for @gvFaResetSecurityQuestionRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your security question'**
  String get gvFaResetSecurityQuestionRequired;

  /// No description provided for @gvFaResetSecurityAnswerHint.
  ///
  /// In en, this message translates to:
  /// **'Security answer'**
  String get gvFaResetSecurityAnswerHint;

  /// No description provided for @gvFaResetSecurityAnswerRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your security answer'**
  String get gvFaResetSecurityAnswerRequired;

  /// No description provided for @gvFaDeviceManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Logged-in devices'**
  String get gvFaDeviceManagementTitle;

  /// No description provided for @gvFaDeviceManagementEntry.
  ///
  /// In en, this message translates to:
  /// **'Logged-in devices'**
  String get gvFaDeviceManagementEntry;

  /// No description provided for @gvFaDeviceLoginMethod.
  ///
  /// In en, this message translates to:
  /// **'Login method: {method}'**
  String gvFaDeviceLoginMethod(String method);

  /// No description provided for @gvFaDeviceLoginIp.
  ///
  /// In en, this message translates to:
  /// **'Login IP: {ip}'**
  String gvFaDeviceLoginIp(String ip);

  /// No description provided for @gvFaDeviceType.
  ///
  /// In en, this message translates to:
  /// **'Device type: {type}'**
  String gvFaDeviceType(String type);

  /// No description provided for @gvFaDeviceLastActive.
  ///
  /// In en, this message translates to:
  /// **'Last active: {time}'**
  String gvFaDeviceLastActive(String time);

  /// No description provided for @gvFaDeviceStatus.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String gvFaDeviceStatus(String status);

  /// No description provided for @gvFaDeviceKick.
  ///
  /// In en, this message translates to:
  /// **'Kick out'**
  String get gvFaDeviceKick;

  /// No description provided for @gvFaDeviceLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get gvFaDeviceLogout;

  /// No description provided for @gvFaDeviceKickConfirm.
  ///
  /// In en, this message translates to:
  /// **'Kick out this device?'**
  String get gvFaDeviceKickConfirm;

  /// No description provided for @gvFaDeviceLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Log out of this device?'**
  String get gvFaDeviceLogoutConfirm;

  /// No description provided for @gvFaDeviceEmpty.
  ///
  /// In en, this message translates to:
  /// **'No logged-in devices'**
  String get gvFaDeviceEmpty;

  /// No description provided for @gvFaDeviceLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load devices'**
  String get gvFaDeviceLoadFailed;

  /// No description provided for @gvFaDeviceStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get gvFaDeviceStatusActive;

  /// No description provided for @gvFaDeviceStatusKicked.
  ///
  /// In en, this message translates to:
  /// **'Kicked out'**
  String get gvFaDeviceStatusKicked;

  /// No description provided for @gvFaDeviceStatusLogout.
  ///
  /// In en, this message translates to:
  /// **'Logged out'**
  String get gvFaDeviceStatusLogout;

  /// No description provided for @gvFaLoginMethodPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get gvFaLoginMethodPassword;

  /// No description provided for @gvFaLoginMethodQrCode.
  ///
  /// In en, this message translates to:
  /// **'QR code'**
  String get gvFaLoginMethodQrCode;

  /// No description provided for @gvFaLoginMethodSso.
  ///
  /// In en, this message translates to:
  /// **'SSO'**
  String get gvFaLoginMethodSso;

  /// No description provided for @gvFaLoginMethodVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'SMS code'**
  String get gvFaLoginMethodVerificationCode;

  /// No description provided for @gvMbEdited.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get gvMbEdited;

  /// No description provided for @gvMbEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get gvMbEditAction;

  /// No description provided for @gvMbEditMessage.
  ///
  /// In en, this message translates to:
  /// **'Edit message'**
  String get gvMbEditMessage;

  /// No description provided for @gvMbEditSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get gvMbEditSave;

  /// No description provided for @gvMbEditSuccess.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get gvMbEditSuccess;

  /// No description provided for @gvMbMentionAll.
  ///
  /// In en, this message translates to:
  /// **'All members'**
  String get gvMbMentionAll;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
