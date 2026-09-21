import 'local_network_preflight_stub.dart'
    if (dart.library.io) 'local_network_preflight_io.dart' as impl;

class LocalNetworkPreflight {
  LocalNetworkPreflight._();

  static Future<void> requestIfNeeded() =>
      impl.requestLocalNetworkPreflightIfNeeded();
}
