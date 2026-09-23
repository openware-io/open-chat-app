// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:go_router/go_router.dart' as _i583;
import 'package:open_core/open_core.dart' as _i424;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../core/app_lifecycle_observer.dart' as _i744;
import '../core/local_storage.dart' as _i397;
import '../database/chat_database.dart' as _i267;
import '../providers/app_locale_provider.dart' as _i246;
import '../providers/app_theme_mode_provider.dart' as _i653;
import '../providers/auth_provider.dart' as _i773;
import '../providers/call_provider.dart' as _i861;
import '../providers/chat/chat_local_store.dart' as _i106;
import '../providers/chat_provider.dart' as _i524;
import '../providers/client_release_coordinator.dart' as _i1047;
import '../providers/client_remote_config_provider.dart' as _i96;
import '../providers/friend_provider.dart' as _i666;
import '../providers/group_provider.dart' as _i151;
import '../providers/mini_app_services_provider.dart' as _i14;
import '../repositories/app_preferences_repository.dart' as _i268;
import '../repositories/auth_repository.dart' as _i1002;
import '../repositories/call_repository.dart' as _i369;
import '../repositories/chat_repository.dart' as _i1054;
import '../repositories/client_config_repository.dart' as _i1020;
import '../repositories/client_release_repository.dart' as _i956;
import '../repositories/favorite_repository.dart' as _i245;
import '../repositories/friend_repository.dart' as _i527;
import '../repositories/group_repository.dart' as _i272;
import '../repositories/mini_app_services_repository.dart' as _i523;
import '../services/api_client.dart' as _i933;
import '../services/call_platform_service.dart' as _i100;
import '../services/e2ee/e2ee_manager.dart' as _i890;
import '../services/im_api.dart' as _i819;
import '../services/message_notification_sound_service.dart' as _i1039;
import '../services/push_notification_service.dart' as _i63;
import '../services/socket_service.dart' as _i411;
import 'app_injection_module.dart' as _i975;

// initializes the registration of main-scope dependencies inside of GetIt
Future<_i174.GetIt> $initAppServiceLocator(
  _i174.GetIt getIt, {
  String? environment,
  _i526.EnvironmentFilter? environmentFilter,
}) async {
  final gh = _i526.GetItHelper(
    getIt,
    environment,
    environmentFilter,
  );
  final appInjectionModule = _$AppInjectionModule();
  await gh.factoryAsync<_i460.SharedPreferences>(
    () => appInjectionModule.sharedPreferences,
    preResolve: true,
  );
  gh.lazySingleton<_i267.ChatDatabase>(() => appInjectionModule.chatDatabase());
  gh.lazySingleton<_i100.CallPlatformService>(
      () => appInjectionModule.callPlatformService());
  gh.lazySingleton<_i1039.MessageNotificationSoundService>(
      () => appInjectionModule.messageNotificationSoundService());
  gh.lazySingleton<_i397.LocalStorage>(
      () => appInjectionModule.localStorage(gh<_i460.SharedPreferences>()));
  gh.lazySingleton<_i106.ChatLocalStore>(
      () => appInjectionModule.chatLocalStore(
            gh<_i397.LocalStorage>(),
            gh<_i267.ChatDatabase>(),
          ));
  gh.lazySingleton<_i424.GvSessionStore>(
      () => appInjectionModule.sessionStore(gh<_i397.LocalStorage>()));
  gh.lazySingleton<_i268.AppPreferencesRepository>(() =>
      appInjectionModule.appPreferencesRepository(gh<_i397.LocalStorage>()));
  gh.lazySingleton<_i933.ApiClient>(
      () => appInjectionModule.apiClient(gh<_i397.LocalStorage>()));
  gh.lazySingleton<_i819.ImApi>(
      () => appInjectionModule.imApi(gh<_i933.ApiClient>()));
  gh.lazySingleton<_i411.SocketService>(
      () => appInjectionModule.socketService(gh<_i933.ApiClient>()));
  gh.lazySingleton<_i1002.AuthRepository>(
      () => appInjectionModule.authRepository(
            gh<_i397.LocalStorage>(),
            gh<_i819.ImApi>(),
            gh<_i933.ApiClient>(),
          ));
  gh.lazySingleton<_i523.MiniAppServicesRepository>(
      () => appInjectionModule.miniAppServicesRepositoryAdapter(
            gh<_i397.LocalStorage>(),
            gh<_i819.ImApi>(),
            gh<_i933.ApiClient>(),
          ));
  gh.lazySingleton<_i527.FriendRepository>(
      () => appInjectionModule.friendRepository(gh<_i819.ImApi>()));
  gh.lazySingleton<_i272.GroupRepository>(
      () => appInjectionModule.groupRepository(gh<_i819.ImApi>()));
  gh.lazySingleton<_i1054.ChatRepository>(
      () => appInjectionModule.chatRepository(gh<_i819.ImApi>()));
  gh.lazySingleton<_i245.FavoriteRepository>(
      () => appInjectionModule.favoriteRepository(gh<_i819.ImApi>()));
  gh.lazySingleton<_i1020.ClientConfigRepository>(
      () => appInjectionModule.clientConfigRepository(gh<_i819.ImApi>()));
  gh.lazySingleton<_i956.ClientReleaseRepository>(
      () => appInjectionModule.clientReleaseRepository(gh<_i819.ImApi>()));
  gh.lazySingleton<_i246.AppLocaleController>(() => appInjectionModule
      .appLocaleController(gh<_i268.AppPreferencesRepository>()));
  gh.lazySingleton<_i653.AppThemeModeController>(() => appInjectionModule
      .appThemeModeController(gh<_i268.AppPreferencesRepository>()));
  gh.lazySingleton<_i151.GroupProvider>(
      () => appInjectionModule.groupProvider(gh<_i272.GroupRepository>()));
  gh.lazySingleton<_i14.MiniAppServicesProvider>(() => appInjectionModule
      .miniAppServicesProvider(gh<_i523.MiniAppServicesRepository>()));
  gh.lazySingleton<_i424.GvSocketClient>(
      () => appInjectionModule.socketClient(gh<_i411.SocketService>()));
  gh.lazySingleton<_i744.AppLifecycleObserver>(
      () => appInjectionModule.appLifecycleObserver(gh<_i411.SocketService>()));
  gh.lazySingleton<_i369.CallRepository>(
      () => appInjectionModule.callRepository(
            gh<_i411.SocketService>(),
            gh<_i819.ImApi>(),
          ));
  gh.lazySingleton<_i1047.ClientReleaseCoordinator>(
      () => appInjectionModule.clientReleaseCoordinator(
            gh<_i956.ClientReleaseRepository>(),
            gh<_i397.LocalStorage>(),
          ));
  gh.lazySingleton<_i63.PushNotificationService>(
      () => appInjectionModule.pushNotificationService(
            gh<_i819.ImApi>(),
            gh<_i268.AppPreferencesRepository>(),
          ));
  gh.lazySingleton<_i96.ClientRemoteConfigProvider>(() => appInjectionModule
      .clientRemoteConfigProvider(gh<_i1020.ClientConfigRepository>()));
  gh.lazySingleton<_i890.E2eeManager>(() => appInjectionModule.e2eeManager(
        gh<_i819.ImApi>(),
        gh<_i460.SharedPreferences>(),
      ));
  gh.lazySingleton<_i666.FriendProvider>(
      () => appInjectionModule.friendProvider(gh<_i527.FriendRepository>()));
  gh.lazySingleton<_i861.CallProvider>(() => appInjectionModule.callProvider(
        gh<_i369.CallRepository>(),
        gh<_i527.FriendRepository>(),
        gh<_i100.CallPlatformService>(),
      ));
  gh.lazySingleton<_i773.AuthProvider>(() => appInjectionModule.authProvider(
        gh<_i1002.AuthRepository>(),
        gh<_i424.GvSocketClient>(),
      ));
  gh.lazySingleton<_i524.ChatProvider>(() => appInjectionModule.chatProvider(
        gh<_i106.ChatLocalStore>(),
        gh<_i1054.ChatRepository>(),
        gh<_i424.GvSocketClient>(),
        gh<_i666.FriendProvider>(),
        gh<_i151.GroupProvider>(),
        gh<_i890.E2eeManager>(),
      ));
  gh.lazySingleton<_i583.GoRouter>(
      () => appInjectionModule.goRouter(gh<_i773.AuthProvider>()));
  return getIt;
}

class _$AppInjectionModule extends _i975.AppInjectionModule {}
