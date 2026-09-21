import '../models/client_remote_settings.dart';

/// 客户端远程配置边界。
abstract interface class ClientConfigRepository {
  Future<ClientRemoteSettings> fetchClientSettings();
}
