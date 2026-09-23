import 'package:go_router/go_router.dart';
import 'package:open_core/open_core.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_router.dart';
import '../core/app_lifecycle_observer.dart';
import '../core/local_storage.dart';
import '../database/chat_database.dart';
import '../providers/app_locale_provider.dart';
import '../providers/app_theme_mode_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/call_provider.dart';
import '../providers/chat/chat_local_store.dart';
import '../providers/chat_provider.dart';
import '../providers/client_remote_config_provider.dart';
import '../providers/client_release_coordinator.dart';
import '../providers/friend_provider.dart';
import '../providers/group_provider.dart';
import '../providers/mini_app_services_provider.dart';
import '../repositories/app_preferences_repository.dart';
import '../repositories/client_release_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/call_repository.dart';
import '../services/call_platform_service.dart';
import '../repositories/chat_repository.dart';
import '../repositories/client_config_repository.dart';
import '../repositories/favorite_repository.dart';
import '../repositories/friend_repository.dart';
import '../repositories/group_repository.dart';
import '../repositories/im_client_release_repository.dart';
import '../repositories/im_auth_repository.dart';
import '../repositories/im_call_repository.dart';
import '../repositories/im_chat_repository.dart';
import '../repositories/im_client_config_repository.dart';
import '../repositories/im_favorite_repository.dart';
import '../repositories/im_friend_repository.dart';
import '../repositories/im_group_repository.dart';
import '../repositories/im_mini_app_services_repository.dart';
import '../repositories/local_app_preferences_repository.dart';
import '../repositories/mini_app_services_repository.dart';
import '../services/api_client.dart';
import '../services/im_api.dart';
import '../services/message_notification_sound_service.dart';
import '../services/push_notification_service.dart';
import '../services/socket_service.dart';
import '../services/e2ee/e2ee_manager.dart';

@module
abstract class AppInjectionModule {
  @preResolve
  Future<SharedPreferences> get sharedPreferences =>
      SharedPreferences.getInstance();

  @lazySingleton
  LocalStorage localStorage(SharedPreferences preferences) =>
      LocalStorage(preferences);

  @lazySingleton
  GvSessionStore sessionStore(LocalStorage storage) => storage;

  @lazySingleton
  ChatDatabase chatDatabase() => ChatDatabase();

  @lazySingleton
  AppPreferencesRepository appPreferencesRepository(LocalStorage storage) =>
      LocalAppPreferencesRepository(storage);

  @lazySingleton
  AppLocaleController appLocaleController(
    AppPreferencesRepository preferences,
  ) =>
      AppLocaleController(preferences);

  @lazySingleton
  AppThemeModeController appThemeModeController(
    AppPreferencesRepository preferences,
  ) =>
      AppThemeModeController(preferences);

  @lazySingleton
  ApiClient apiClient(LocalStorage storage) => ApiClient(storage);

  @lazySingleton
  ImApi imApi(ApiClient apiClient) => ImApi(apiClient);

  @lazySingleton
  SocketService socketService(ApiClient apiClient) => SocketService(apiClient);

  @lazySingleton
  E2eeManager e2eeManager(ImApi imApi, SharedPreferences preferences) =>
      E2eeManager(imApi: imApi, preferences: preferences);

  @lazySingleton
  GvSocketClient socketClient(SocketService socketService) => socketService;

  @lazySingleton
  AuthRepository authRepository(
    LocalStorage storage,
    ImApi imApi,
    ApiClient apiClient,
  ) =>
      ImAuthRepository(storage, imApi, apiClient);

  @lazySingleton
  FriendRepository friendRepository(ImApi imApi) => ImFriendRepository(imApi);

  @lazySingleton
  GroupRepository groupRepository(ImApi imApi) => ImGroupRepository(imApi);

  @lazySingleton
  ChatRepository chatRepository(ImApi imApi) => ImChatRepository(imApi);

  @lazySingleton
  FavoriteRepository favoriteRepository(ImApi imApi) =>
      ImFavoriteRepository(imApi);

  @lazySingleton
  ChatLocalStore chatLocalStore(
    LocalStorage storage,
    ChatDatabase database,
  ) =>
      ChatLocalStore(storage, database);

  @lazySingleton
  CallRepository callRepository(SocketService socketService, ImApi imApi) =>
      ImCallRepository(socketService, imApi);

  @lazySingleton
  ClientConfigRepository clientConfigRepository(ImApi imApi) =>
      ImClientConfigRepository(imApi);

  @lazySingleton
  MiniAppServicesRepository miniAppServicesRepositoryAdapter(
    LocalStorage storage,
    ImApi imApi,
    ApiClient apiClient,
  ) =>
      ImMiniAppServicesRepository(storage, imApi, apiClient);

  @lazySingleton
  ClientReleaseRepository clientReleaseRepository(ImApi imApi) =>
      ImClientReleaseRepository(imApi);

  @lazySingleton
  ClientReleaseCoordinator clientReleaseCoordinator(
    ClientReleaseRepository repository,
    LocalStorage storage,
  ) =>
      ClientReleaseCoordinator(repository, storage);

  @lazySingleton
  AuthProvider authProvider(
    AuthRepository authRepository,
    GvSocketClient socketClient,
  ) =>
      AuthProvider(authRepository, socketClient);

  @lazySingleton
  FriendProvider friendProvider(FriendRepository friendRepository) =>
      FriendProvider(friendRepository);

  @lazySingleton
  GroupProvider groupProvider(GroupRepository groupRepository) =>
      GroupProvider(groupRepository);

  @lazySingleton
  ChatProvider chatProvider(
    ChatLocalStore chatLocalStore,
    ChatRepository chatRepository,
    GvSocketClient socketClient,
    FriendProvider friendProvider,
    GroupProvider groupProvider,
    E2eeManager e2eeManager,
  ) =>
      ChatProvider(
        chatLocalStore,
        chatRepository,
        socketClient,
        friendProvider,
        groupProvider,
        e2eeManager,
      );

  @lazySingleton
  CallPlatformService callPlatformService() => CallPlatformService();

  @lazySingleton
  CallProvider callProvider(
    CallRepository callRepository,
    FriendRepository friendRepository,
    CallPlatformService callPlatformService,
  ) =>
      CallProvider(callRepository, friendRepository, callPlatformService);

  @lazySingleton
  ClientRemoteConfigProvider clientRemoteConfigProvider(
    ClientConfigRepository clientConfigRepository,
  ) =>
      ClientRemoteConfigProvider(clientConfigRepository);

  @lazySingleton
  MiniAppServicesProvider miniAppServicesProvider(
    MiniAppServicesRepository miniAppServicesRepository,
  ) =>
      MiniAppServicesProvider(miniAppServicesRepository);

  @lazySingleton
  PushNotificationService pushNotificationService(
    ImApi imApi,
    AppPreferencesRepository preferences,
  ) =>
      PushNotificationService(imApi, preferences);

  @lazySingleton
  MessageNotificationSoundService messageNotificationSoundService() =>
      MessageNotificationSoundService();

  @lazySingleton
  AppLifecycleObserver appLifecycleObserver(SocketService socketService) =>
      AppLifecycleObserver(socketService);

  @lazySingleton
  GoRouter goRouter(AuthProvider authProvider) => createAppRouter(authProvider);
}
