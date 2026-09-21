import 'package:freezed_annotation/freezed_annotation.dart';

import '../json/json_int.dart';

part 'im_user.freezed.dart';
part 'im_user.g.dart';

// ignore_for_file: invalid_annotation_target

Object? _readPhone(Map<dynamic, dynamic> json, String key) =>
    json['phone'] ??
    json['mobile'] ??
    json['phone_number'] ??
    json['phoneNumber'];

Object? _readEmail(Map<dynamic, dynamic> json, String key) =>
    json['email'] ?? json['mail'];

Object? _readAvatar(Map<dynamic, dynamic> json, String key) =>
    json['avatar'] ?? json['avatarUrl'];

Object? _readSignature(Map<dynamic, dynamic> json, String key) =>
    json['signature'] ?? json['bio'];

String? _trimNullableString(Object? value) {
  if (value is! String) return null;
  final text = value.trim();
  return text.isEmpty ? null : text;
}

/// 登录态、用户搜索、个人资料接口共用的用户 DTO。
///
/// 生成器负责序列化与 copyWith，字段别名兼容集中在模型层，避免页面和仓库重复处理。
@freezed
abstract class ImUser with _$ImUser {
  const ImUser._();

  @JsonSerializable(includeIfNull: false)
  const factory ImUser({
    @JsonKey(fromJson: jsonIntRequired) required int id,
    @Default('') String username,
    String? nickname,
    @JsonKey(readValue: _readAvatar, fromJson: _trimNullableString)
    String? avatar,
    @JsonKey(readValue: _readSignature, fromJson: _trimNullableString)
    String? signature,
    @JsonKey(readValue: _readPhone, fromJson: _trimNullableString)
    String? phone,
    @JsonKey(readValue: _readEmail, fromJson: _trimNullableString)
    String? email,
  }) = _ImUser;

  factory ImUser.fromJson(Map<String, dynamic> json) => _$ImUserFromJson(json);

  String get displayName =>
      (nickname != null && nickname!.isNotEmpty) ? nickname! : username;
}
