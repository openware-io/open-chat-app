import '../models/client_release_models.dart';
import '../services/im_api.dart';
import 'client_release_repository.dart';

class ImClientReleaseRepository implements ClientReleaseRepository {
  ImClientReleaseRepository(this._api);
  final ImApi _api;
  @override
  Future<ClientReleaseCheckResult> checkRelease(
          {required String platform,
          required String channel,
          required String version,
          required int buildNumber,
          required String architecture,
          required String protocolVersion,
          required String installationId}) =>
      _api.checkClientRelease(
          platform: platform,
          channel: channel,
          version: version,
          buildNumber: buildNumber,
          architecture: architecture,
          protocolVersion: protocolVersion,
          installationId: installationId);
}
