import 'package:open_core/open_core.dart';

/// 多端登录设备会话（对应后端 DeviceSessionResponse）。
class DeviceSession {
  const DeviceSession({
    required this.id,
    required this.deviceId,
    this.deviceType,
    this.deviceName,
    this.loginIp,
    this.loginMethod,
    this.lastActiveAt,
    this.lastActiveIp,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String deviceId;
  final String? deviceType;
  final String? deviceName;
  final String? loginIp;
  final String? loginMethod;
  final DateTime? lastActiveAt;
  final String? lastActiveIp;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory DeviceSession.fromJson(Map<String, dynamic> json) {
    return DeviceSession(
      id: jsonInt(json['id']) ?? 0,
      deviceId: _str(json['deviceId'] ?? json['device_id']),
      deviceType: _str(json['deviceType'] ?? json['device_type']),
      deviceName: _str(json['deviceName'] ?? json['device_name']),
      loginIp: _str(json['loginIp'] ?? json['login_ip']),
      loginMethod: _str(json['loginMethod'] ?? json['login_method']),
      lastActiveAt: parseUtcDateTime(
        json['lastActiveAt'] ?? json['last_active_at'],
      ),
      lastActiveIp: _str(json['lastActiveIp'] ?? json['last_active_ip']),
      status: _str(json['status']),
      createdAt: parseUtcDateTime(json['createdAt'] ?? json['created_at']),
      updatedAt: parseUtcDateTime(json['updatedAt'] ?? json['updated_at']),
    );
  }

  static String _str(Object? value) {
    if (value == null) return '';
    final text = value.toString().trim();
    return text;
  }
}
