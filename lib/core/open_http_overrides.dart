import 'open_http_overrides_stub.dart'
    if (dart.library.io) 'open_http_overrides_io.dart' as impl;

void gvSetupHttpOverrides() => impl.gvSetupHttpOverrides();
