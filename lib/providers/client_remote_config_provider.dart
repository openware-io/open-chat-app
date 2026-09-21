import 'package:flutter/foundation.dart';

import '../models/client_remote_settings.dart';
import '../repositories/client_config_repository.dart';

/// 登录后拉取服务端 `system_configs` 的客户端可见子集（`GET /config/client`）。
class ClientRemoteConfigProvider extends ChangeNotifier {
  ClientRemoteConfigProvider(this._repository);

  final ClientConfigRepository _repository;

  ClientRemoteSettings _settings = ClientRemoteSettings.defaults;
  bool _loaded = false;
  bool _announcementShownThisSession = false;

  ClientRemoteSettings get settings => _settings;

  bool get loaded => _loaded;

  /// 任务栏 / 多任务标题等。
  String get appDisplayName => _settings.app.name.trim().isNotEmpty
      ? _settings.app.name.trim()
      : 'WV Chat';

  bool get privateChatEnabled => _settings.feature.privateChatEnabled;

  bool get groupChatEnabled => _settings.feature.groupChatEnabled;

  bool get recallEnabled => _settings.feature.recallEnabled;

  bool get readReceiptEnabled => _settings.feature.readReceiptEnabled;

  bool get voiceCallEnabled => _settings.feature.voiceCallEnabled;

  bool get videoCallEnabled => _settings.feature.videoCallEnabled;

  /// 频道（单向广播）能力开关。
  bool get channelEnabled => _settings.feature.channelEnabled;

  /// 私密聊天（E2EE 形态）能力开关。
  bool get secretChatEnabled => _settings.feature.secretChatEnabled;

  /// 私密群聊（逐成员 E2EE）能力开关。
  bool get secretGroupChatEnabled => _settings.feature.secretGroupChatEnabled;

  /// 私密群聊删除所有人/撤回开关。
  bool get groupDeleteEveryoneEnabled =>
      _settings.feature.groupDeleteEveryoneEnabled;

  /// 私密群聊编辑消息开关。
  bool get groupEditMessageEnabled => _settings.feature.groupEditMessageEnabled;

  /// 私密群聊匿名发言开关。
  bool get groupAnonymityEnabled => _settings.feature.groupAnonymityEnabled;

  /// 私密群聊邀请链接开关。
  bool get groupInviteLinkEnabled => _settings.feature.groupInviteLinkEnabled;

  /// 私密群聊置顶/公告开关。
  bool get groupPinnedEnabled => _settings.feature.groupPinnedEnabled;

  /// 删除聊天/撤回/删除消息/清空聊天总开关。
  bool get chatDeleteEnabled => _settings.feature.chatDeleteEnabled;

  /// 群成员隐私保护：隐藏非好友群成员的昵称/头像（平台级开关，admin 后台控制）。
  bool get hideGroupMemberInfo => _settings.feature.hideGroupMemberInfo;

  ClientRtcBlock get rtc => _settings.rtc;

  ClientUploadBlock get upload => _settings.upload;

  ClientPushBlock get push => _settings.push;

  /// 非空且本会话尚未展示过系统公告时返回正文（展示后请调 [markAnnouncementConsumed]）。
  String? peekAnnouncementForDialog() {
    final a = _settings.app.announcement.trim();
    if (a.isEmpty || _announcementShownThisSession) return null;
    return a;
  }

  void markAnnouncementConsumed() {
    _announcementShownThisSession = true;
    notifyListeners();
  }

  void resetSessionFlags() {
    _announcementShownThisSession = false;
    notifyListeners();
  }

  /// 登出或未登录：恢复默认，避免短暂显示上一账号配置。
  void resetToDefaults() {
    _settings = ClientRemoteSettings.defaults;
    _loaded = false;
    _announcementShownThisSession = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    try {
      _settings = await _repository.fetchClientSettings();
      _loaded = true;
    } catch (_) {
      _settings = ClientRemoteSettings.defaults;
      _loaded = false;
    }
    notifyListeners();
  }
}
