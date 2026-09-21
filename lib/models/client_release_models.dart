class ClientReleaseArtifact {
  const ClientReleaseArtifact(
      {required this.downloadUrl, required this.packageType});
  final String? downloadUrl;
  final String packageType;
  factory ClientReleaseArtifact.fromJson(Map<String, dynamic> json) =>
      ClientReleaseArtifact(
          downloadUrl: json['downloadUrl']?.toString(),
          packageType: json['packageType']?.toString() ?? '');
}

class ClientReleaseTarget {
  const ClientReleaseTarget(
      {required this.version,
      required this.buildNumber,
      required this.releaseNotes,
      required this.storeUrl,
      required this.artifacts});
  final String version;
  final int buildNumber;
  final String releaseNotes;
  final String? storeUrl;
  final List<ClientReleaseArtifact> artifacts;
  factory ClientReleaseTarget.fromJson(Map<String, dynamic> json) =>
      ClientReleaseTarget(
          version: json['version']?.toString() ?? '',
          buildNumber: (json['buildNumber'] as num?)?.toInt() ?? 0,
          releaseNotes: json['releaseNotes']?.toString() ?? '',
          storeUrl: json['storeUrl']?.toString(),
          artifacts: ((json['artifacts'] as List?) ?? const [])
              .whereType<Map>()
              .map((item) => ClientReleaseArtifact.fromJson(
                  Map<String, dynamic>.from(item)))
              .toList());
  String? get launchUrl {
    if (storeUrl?.trim().isNotEmpty == true) return storeUrl;
    final directUrl = artifacts
        .map((item) => item.downloadUrl)
        .whereType<String>()
        .firstWhere((item) => item.trim().isNotEmpty, orElse: () => '');
    return directUrl.isEmpty ? null : directUrl;
  }
}

class ClientReleaseCheckResult {
  const ClientReleaseCheckResult(
      {required this.decision, this.blockReason, this.target});
  final String decision;
  final String? blockReason;
  final ClientReleaseTarget? target;
  bool get requiresUpdate =>
      decision == 'optional_update' ||
      decision == 'mandatory_update' ||
      decision == 'unsupported_client';
  bool get mandatory =>
      decision == 'mandatory_update' || decision == 'unsupported_client';
  factory ClientReleaseCheckResult.fromJson(Map<String, dynamic> json) =>
      ClientReleaseCheckResult(
          decision: json['decision']?.toString() ?? 'no_release',
          blockReason: json['blockReason']?.toString(),
          target: json['target'] is Map
              ? ClientReleaseTarget.fromJson(
                  Map<String, dynamic>.from(json['target'] as Map))
              : null);
}
