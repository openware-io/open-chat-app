/// 聊天记录自动清理策略（`GET/PUT /users/me/self-destruct`）。
/// 注意：该策略只清除聊天记录，不会注销账号（账号仍可正常登录）。
///
/// [policy] 取值：`off` / `1mo` / `3mo` / `6mo` / `1yr`；
/// [selfDestructAt] / [lastLoginAt] 为 ISO 时间串，未设置时为 null。
class SelfDestructPolicy {
  const SelfDestructPolicy({
    required this.policy,
    this.selfDestructAt,
    this.lastLoginAt,
  });

  factory SelfDestructPolicy.fromJson(Map<String, dynamic> json) =>
      SelfDestructPolicy(
        policy: json['policy']?.toString() ?? 'off',
        selfDestructAt: _nullableString(json['selfDestructAt']),
        lastLoginAt: _nullableString(json['lastLoginAt']),
      );

  final String policy;
  final String? selfDestructAt;
  final String? lastLoginAt;

  /// 是否已开启自毁（policy 非 off）。
  bool get enabled => policy != 'off';
}

String? _nullableString(Object? value) {
  final s = value?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}
