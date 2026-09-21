/// 服务端错误文案的本地化。
///
/// 背景：服务端（im-* 各服务）目前**没有 i18n 机制**，`ApiException` 一律返回英文文案
/// （另有少量历史遗留的硬编码中文），客户端若不翻译，中文界面就会漏出英文、英文界面漏出中文。
///
/// 约定：客户端按「服务端原文」查表翻译。新增服务端文案时必须同步补表，
/// 否则会在对应语言的界面上漏出另一种语言。
library;

/// 当前界面语言是否为中文。由应用语言设置变更时写入，供无 BuildContext 的调用方使用。
bool _zhLocale = true;

void setApiMessageZhLocale(bool zh) => _zhLocale = zh;

bool get apiMessageZhLocale => _zhLocale;

/// 把服务端原始错误文案翻译成当前界面语言；无对应条目时原样返回（避免误翻译）。
///
/// 查表先按原文、再按小写（服务端文案多为首字母大写的句子，
/// 表内英文键统一小写，与既有实现保持一致）。
String localizeServerMessage(String message) {
  final key = message.trim();
  final table = _zhLocale ? _serverMessageZh : _serverMessageEn;
  final hit = table[key] ?? table[key.toLowerCase()];
  if (hit != null) return hit;
  // 校验类错误兜底：框架会给出 "must not be blank" / "must not be null" 等字段校验文案，
  // 甚至把 Java 方法签名整段吐出来（Required request body is missing: public com.gvchat...）。
  // 这类内部细节绝不能直接展示给用户（真机实测：注册页就是这样漏出英文的）。
  final lower = key.toLowerCase();
  if (lower.startsWith('must not be') ||
      lower.startsWith('must be') ||
      lower.contains('required request body is missing') ||
      lower.contains('json parse error') ||
      lower.contains('cannot deserialize') ||
      lower.contains('failed to convert value')) {
    return _zhLocale ? '填写内容不完整或格式不正确' : 'Some fields are missing or invalid';
  }
  return key;
}

/// 币种相关错误码 -> 中文（规范 §2.2 / §3：服务端返回稳定错误码）。
///
/// 错误码比文案稳定，因此按码优先于按文案查表。
const Map<String, String> _currencyErrorCodesZh = {
  'CURRENCY_MISMATCH': '收款币种与订单币种不一致，请核对订单后重试',
  'CURRENCY_PAYMENT_METHOD_UNSUPPORTED':
      '当前租户币种不支持该支付方式（微信/支付宝仅支持人民币）',
  'CURRENCY_SWITCH_BLOCKED_BY_BALANCE':
      '仍存在非零余额的钱包或储值账户，暂时无法切换币种，请联系管理员处理',
  'CURRENCY_UNSUPPORTED': '不支持的币种，请选择人民币或美元',
};

const Map<String, String> _currencyErrorCodesEn = {
  'CURRENCY_MISMATCH':
      'The payment currency does not match the order currency. Please check the order and retry.',
  'CURRENCY_PAYMENT_METHOD_UNSUPPORTED':
      'This payment method is not available for the current tenant currency.',
  'CURRENCY_SWITCH_BLOCKED_BY_BALANCE':
      'The currency cannot be switched while wallet or stored-value balances are non-zero.',
  'CURRENCY_UNSUPPORTED': 'Unsupported currency. Please choose CNY or USD.',
};

/// 按服务端错误码翻译；无对应条目时返回 null（交回文案查表）。
String? localizeErrorCode(String? code) {
  final key = (code ?? '').trim().toUpperCase();
  if (key.isEmpty) return null;
  final table = _zhLocale ? _currencyErrorCodesZh : _currencyErrorCodesEn;
  return table[key];
}

/// 服务端英文文案 -> 中文（中文界面）。
const Map<String, String> _serverMessageZh = {
  // 账号 / 登录 / 注册
  'username already exists': '用户名已存在',
  'email already exists': '邮箱已存在',
  'invalid username or password': '用户名或密码错误',
  'invalid credentials': '账号或密码错误',
  'invalid identifier': '账号格式不正确',
  'email is required': '请输入邮箱',
  'username is required': '请输入用户名',
  'password is required': '请输入密码',
  'phone is required': '请输入手机号',
  'verification code is required': '请输入验证码',
  'invalid or expired verification code': '验证码无效或已过期',
  'reset token is required': '重置凭证不能为空',
  'invalid or expired reset token': '重置凭证无效或已过期',
  'security question is required': '请选择密保问题',
  'security answer is required': '请输入密保答案',
  'security question verification failed': '密保验证失败',
  'account disabled': '账号已被禁用',
  'account already cancelled': '账号已注销',
  'account cancellation already in progress': '账号正在注销中',
  'user not found': '用户不存在',
  'user authorization has been revoked': '登录授权已失效，请重新登录',
  'user authorization not found': '未找到登录授权',
  'authentication required': '请先登录',
  'authentication is no longer valid': '登录状态已失效，请重新登录',
  'invalid access_token': '登录凭证无效，请重新登录',
  'missing access_token': '缺少登录凭证，请重新登录',

  // 修改密码 / 资料
  'password incorrect': '当前密码错误',
  'new password must differ from the current password': '新密码不能与当前密码相同',
  'nickname too long': '昵称过长',
  'announcement too long': '公告过长',

  // 好友
  'not friends': '对方不是你的好友',
  'already friends': '你们已经是好友了',
  'cannot add self': '不能添加自己为好友',
  'friend not found': '好友不存在',
  'request not found': '好友申请不存在',
  'request already handled': '该好友申请已处理',
  'recipient disabled group friend requests': '对方已关闭群内添加好友',
  'blocked friend not found': '未找到该拉黑记录',

  // 消息
  'message not found': '消息不存在',
  'chat deletion is disabled': '聊天删除功能已关闭',
  "cannot delete others' message": '不能删除他人的消息',
  'only sender can edit': '只有发送者可以编辑',
  'only sender can recall': '只有发送者可以撤回',
  'only sender or group owner can delete': '只有发送者或群主可以删除',
  'edit window expired': '已超过可编辑时间',
  'edited content is required': '编辑内容不能为空',
  'edited content contains sensitive words': '编辑内容包含敏感词',
  'message content or media is required': '消息内容不能为空',
  'message media is invalid': '消息媒体无效',
  'not allowed to favorite this message': '该消息不支持收藏',
  'message search requires chat type and peer identifier': '搜索需要指定会话类型与会话对象',

  // 群组 / 频道
  'group not found': '群组不存在',
  'group chat is disabled': '群聊功能已关闭',
  'group name too long': '群名称过长',
  'group capacity exceeded': '群成员已达上限',
  'not group member': '你不是该群成员',
    'group is dissolved, no more messages allowed': '群聊已解散，不能继续发消息',
    'group is unavailable': '群聊已解散或不可用',
  'not a group member': '你不是该群成员',
  'member not found': '成员不存在',
  'invalid member user id': '成员账号无效',
  'user is already a member': '该用户已在群内',
  'only owner can dissolve': '只有群主可以解散群',
  'only owner can set role': '只有群主可以设置角色',
  'only owner can perform this action': '只有群主可以执行该操作',
  'only owner can post in this group': '只有群主可以在该群发言',
  'only admin can update group': '只有管理员可以修改群资料',
  'only admin can mute': '只有管理员可以禁言',
  'cannot mute member with equal or higher role': '不能禁言同级或更高级别的成员',
  'cannot remove member': '无法移除该成员',
  'member invitations are disabled': '已关闭群成员邀请',
  'invite link invalid or expired': '邀请链接无效或已过期',
  'invite link expired': '邀请链接已过期',
  'use leave group to transfer ownership': '请使用「退出群聊」转让群主',
  'cannot add yourself as member': '不能把自己添加为成员',
  'channel not found': '频道不存在',
  'not subscribed to channel': '你未订阅该频道',
  'only channel owner can publish': '只有频道主可以发布',
  'only channel owner can manage channel': '只有频道主可以管理频道',

  // 私密聊天 / 私密群聊
  'secret chat is disabled': '私密聊天功能已关闭',
  'secret chat not found': '私密聊天不存在',
  'secret group chat is disabled': '私密群聊功能已关闭',
  'secret group chat not found': '私密群聊不存在',
  'secret group chat is closed': '私密群聊已关闭',
  'secret group chat requires at least 2 members': '私密群聊至少需要 2 名成员',
  'secret message not found': '私密消息不存在',
  'secret group message not found': '私密群消息不存在',
  'not a participant': '你不是该私密会话的参与者',
  'not a participant of this secret chat': '你不是该私密聊天的参与者',
  'not a participant of this secret group': '你不是该私密群聊的参与者',
  'not a member of this secret group': '你不是该私密群成员',
  'cannot create secret chat with yourself': '不能与自己创建私密聊天',
  'invalid destroy policy': '销毁策略无效',

  // 媒体 / 文件
  'media object not found': '文件不存在',
  'media object access denied': '无权访问该文件',
  'media upload session not found': '上传会话不存在',
  'media upload session is unavailable': '上传会话不可用',
  'invalid media upload request': '上传请求无效',
  'invalid media object identifiers': '文件标识无效',
  'too many media upload parts': '上传分片过多',
  'invalid media duration': '媒体时长无效',
  'media duration is not applicable': '该媒体类型不支持时长',
  'file size exceeds limit，': '文件大小超出限制',

  // 举报 / 表情 / 通话
  'report already pending': '举报正在处理中',
  'report not found': '举报不存在',
  'sticker not found': '表情不存在',
  'sticker limit reached': '表情数量已达上限',
  'not allowed to access history': '无权查看该聊天记录',
  'rtc disabled': '通话功能已关闭',
  'rtc ice configuration unavailable': '通话服务暂不可用，请稍后重试',

  // 币种（服务端只给文案、未带 error code 时的兜底）
  'currency mismatch': '收款币种与订单币种不一致，请核对订单后重试',
  'currency not supported': '不支持的币种，请选择人民币或美元',
};

/// 服务端历史硬编码中文 -> 英文（英文界面），避免中英混排。
const Map<String, String> _serverMessageEn = {
  '不支持的上传业务类型': 'Unsupported upload business type',
  '不支持的文件分类': 'Unsupported file category',
  '上传文件不能为空': 'Upload file is required',
  '头像仅支持上传图片文件': 'Avatar only supports image files',
  '文件大小超出限制，': 'File size exceeds limit',
  '系统附件仅支持图片或普通附件': 'System attachments only support images or regular files',
  '已禁用添加群成员为好友': 'Adding group members as friends is disabled',
  '群聊已解散，不能继续发消息': 'This group was dissolved. You can no longer send messages.',
  '预约仅支持上传凭证文件（JPG、PNG、PDF）':
      'Reservations only support voucher files (JPG, PNG, PDF)',
};
