import '../models/client_release_models.dart';

abstract interface class ClientReleaseRepository {
  Future<ClientReleaseCheckResult> checkRelease(
      {required String platform,
      required String channel,
      required String version,
      required int buildNumber,
      required String architecture,
      required String protocolVersion,
      required String installationId});
}
