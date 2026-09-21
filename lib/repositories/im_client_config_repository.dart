import '../models/client_remote_settings.dart';
import '../services/im_api.dart';
import 'client_config_repository.dart';

/// 把原始配置 JSON 转成页面可直接消费的设置对象。
class ImClientConfigRepository implements ClientConfigRepository {
  ImClientConfigRepository(this._api);

  final ImApi _api;

  @override
  Future<ClientRemoteSettings> fetchClientSettings() async {
    final json = await _api.getClientConfig();
    return ClientRemoteSettings.fromJson(json);
  }
}
