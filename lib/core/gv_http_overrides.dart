import 'gv_http_overrides_stub.dart'
    if (dart.library.io) 'gv_http_overrides_io.dart' as impl;

void gvSetupHttpOverrides() => impl.gvSetupHttpOverrides();
