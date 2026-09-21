import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'app_service_locator.config.dart';

final GetIt gvServiceLocator = GetIt.instance;

@InjectableInit(
  initializerName: r'$initAppServiceLocator',
  preferRelativeImports: true,
  asExtension: false,
)
Future<GetIt> configureAppServiceLocator(GetIt getIt) =>
    $initAppServiceLocator(getIt);
