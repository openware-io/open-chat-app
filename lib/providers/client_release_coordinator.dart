import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

import '../core/open_app_update_platform.dart';
import '../core/local_storage.dart';
import '../models/client_release_models.dart';
import '../repositories/client_release_repository.dart';

/// Coordinates the startup release decision without coupling it to a screen.
class ClientReleaseCoordinator extends ChangeNotifier {
  ClientReleaseCoordinator(this._repository, this._storage);

  final ClientReleaseRepository _repository;
  final LocalStorage _storage;
  ClientReleaseCheckResult? _result;
  bool _checked = false;
  bool _optionalPrompted = false;

  ClientReleaseCheckResult? get result => _result;
  bool get checked => _checked;
  bool get blocksUsage => _result?.mandatory ?? false;

  /// 是否有新版本可用（含非强制）。用于「我」tab 与设置页的**小红点**。
  ///
  /// 此前该结果只用于强制更新与「弹一次」的可选提示，提示过后界面上再无任何提示，
  /// 发布新版本时用户完全感知不到，必须主动进设置点「检查更新」。
  bool get updateAvailable => _result?.requiresUpdate ?? false;

  /// 有可选更新（非强制）且尚未提示过。
  bool get shouldPromptOptional =>
      _result != null && _result!.requiresUpdate && !_result!.mandatory && !_optionalPrompted;

  void markOptionalPrompted() {
    _optionalPrompted = true;
    notifyListeners();
  }

  Future<void> checkOnLaunch() async {
    final platform = gvClientReleasePlatformKey();
    if (platform == null) {
      _checked = true;
      notifyListeners();
      return;
    }
    try {
      final package = await PackageInfo.fromPlatform();
      final buildNumber = int.tryParse(package.buildNumber.trim()) ?? 0;
      if (buildNumber <= 0) return;
      var installationId = _storage.clientReleaseInstallationId;
      installationId ??= const Uuid().v4();
      await _storage.setClientReleaseInstallationId(installationId);
      _result = await _repository
          .checkRelease(
            platform: platform,
            channel: gvClientReleaseChannelKey(),
            version: package.version,
            buildNumber: buildNumber,
            architecture: 'universal',
            protocolVersion: 'v1',
            installationId: installationId,
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Offline or transient failures must not block startup. A future launch retries.
    } finally {
      _checked = true;
      notifyListeners();
    }
  }
}
