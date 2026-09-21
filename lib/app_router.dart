import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app/app_routes.dart';
import 'providers/auth_provider.dart';
import 'shell/main_shell.dart';
import 'screens/add_friend_screen.dart';
import 'screens/call_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/chat_room_screen.dart';
import 'screens/chat_history_search_screen.dart';
import 'screens/forward_message_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/favorite_detail_screen.dart';
import 'screens/recommend_contact_screen.dart';
import 'screens/contact_detail_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/blacklist_screen.dart';
import 'screens/friend_groups_screen.dart';
import 'screens/create_group_screen.dart';
import 'screens/create_secret_group_screen.dart';
import 'screens/friend_requests_screen.dart';
import 'screens/group_info_screen.dart';
import 'screens/invite_group_members_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/services_screen.dart';
import 'screens/ktv_oauth_entry_screen.dart';
import 'screens/mock_service_screen.dart';
import 'models/channel_models.dart';
import 'models/mock_service_category.dart';
import 'models/shared_media_item.dart';
import 'screens/register_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/share_channel_screen.dart';
import 'screens/share_media_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/device_management_screen.dart';
import 'screens/profile_edit_screen.dart';
import 'screens/points_account_binding_screen.dart';
import 'screens/avatar_crop_screen.dart';
import 'l10n/app_localizations.dart';
import 'screens/settings_screen.dart';
import 'screens/notification_settings_screen.dart';
import 'screens/self_destruct_screen.dart';
import 'screens/chat_storage_screen.dart';
import 'screens/chat_backup_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/business/business_login_screen.dart';
import 'screens/business/ktv_cashier_screen.dart';
import 'screens/business/ktv_dashboard_screen.dart';
import 'screens/business/ktv_quick_open_screen.dart';
import 'screens/business/ktv_pending_approval_screen.dart';
import 'screens/business/ktv_settle_screen.dart';
import 'screens/business/ktv_shift_screen.dart';
import 'screens/business/ktv_timing_screen.dart';
import 'core/gv_root_navigator.dart';
import 'core/gv_router_page.dart';
import 'core/namecard_message.dart';
import 'models/chat_message.dart';
import 'models/ktv_models.dart';
import 'models/points_account_binding.dart';

GoRouter createAppRouter(AuthProvider auth) {
  return GoRouter(
    navigatorKey: gvRootNavigatorKey,
    initialLocation: AppRoutes.chats,
    refreshListenable: auth,
    redirect: (context, state) {
      final loggedIn = auth.isLoggedIn;
      final loc = state.matchedLocation;

      // B端（business）为独立分组：B端登录页游客可访问，KTV 各页暂不接 B端鉴权，
      // 直接放行，避免被 C端登录守卫拦到 /login。
      if (loc.startsWith(AppRoutes.businessPrefix)) {
        return null;
      }

      final guest = loc == AppRoutes.login ||
          loc == AppRoutes.register ||
          loc == AppRoutes.forgotPassword ||
          loc == AppRoutes.resetPassword;
      if (!loggedIn && !guest) return AppRoutes.login;
      if (loggedIn && guest) return AppRoutes.chats;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) => gvTransitionPage(
          state,
          LoginScreen(
            initialUsername:
                state.extra is String ? state.extra as String : null,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) => gvTransitionPage(
          state,
          const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) => gvTransitionPage(
          state,
          const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) => gvTransitionPage(
          state,
          ResetPasswordScreen(
            initialToken: state.uri.queryParameters['token'],
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.businessLogin,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) => gvTransitionPage(
          state,
          const BusinessLoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.ktvDashboard,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) => gvTransitionPage(
          state,
          const KtvDashboardScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.ktvQuickOpen,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) => gvTransitionPage(
          state,
          KtvQuickOpenScreen(
            args: state.extra is KtvSessionArgs
                ? state.extra as KtvSessionArgs
                : null,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.ktvTiming,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) => gvTransitionPage(
          state,
          KtvTimingScreen(
            args: state.extra is KtvSessionArgs
                ? state.extra as KtvSessionArgs
                : null,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.ktvSettle,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) => gvTransitionPage(
          state,
          KtvSettleScreen(
            args: state.extra is KtvSessionArgs
                ? state.extra as KtvSessionArgs
                : null,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.ktvCashier,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) => gvTransitionPage(
          state,
          KtvCashierScreen(
            args: state.extra is KtvSessionArgs
                ? state.extra as KtvSessionArgs
                : null,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.ktvShift,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) => gvTransitionPage(
          state,
          const KtvShiftScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.ktvPendingApproval,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) => gvTransitionPage(
          state,
          KtvPendingApprovalScreen(
            args: state.extra is KtvPendingApprovalArgs
                ? state.extra as KtvPendingApprovalArgs
                : null,
          ),
        ),
      ),
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, navigationShell) => gvTransitionPage(
          state,
          MainShell(navigationShell: navigationShell),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.chats,
                pageBuilder: (context, state) => gvTransitionPage(
                  state,
                  const ChatListScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.contacts,
                pageBuilder: (context, state) => gvTransitionPage(
                  state,
                  const ContactsScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.services,
                pageBuilder: (context, state) => gvTransitionPage(
                  state,
                  const ServicesScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                pageBuilder: (context, state) => gvTransitionPage(
                  state,
                  const ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.serviceDemo,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) => gvTransitionPage(
          state,
          MockServiceScreen(
            category: MockServiceCategory.fromWireName(
              state.pathParameters['category'] ?? '',
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.ktvOAuth,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) => gvTransitionPage(
          state,
          const KtvOAuthEntryScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.chat,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) {
          final extra = state.extra;
          return gvTransitionPage(
            state,
            ChatRoomScreen(
              chatType: state.pathParameters['chatType']!,
              peerId: state.pathParameters['peerId']!,
              anchorMsgId: state.uri.queryParameters['msg'],
              anchorSeedMessage: extra is ChatMessage ? extra : null,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.forwardMessage,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) {
          final ex = state.extra;
          if (ex is! ChatMessage) {
            return gvTransitionPage(
              state,
              Scaffold(
                body: Center(
                  child: Text(
                    AppLocalizations.of(context)!.routeInvalidArguments,
                  ),
                ),
              ),
            );
          }
          return gvTransitionPage(
            state,
            ForwardMessageScreen(message: ex),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.shareChannel,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) {
          final ex = state.extra;
          if (ex is! ChannelInfo) {
            return gvTransitionPage(
              state,
              Scaffold(
                body: Center(
                  child: Text(
                    AppLocalizations.of(context)!.routeInvalidArguments,
                  ),
                ),
              ),
            );
          }
          return gvTransitionPage(
            state,
            ShareChannelScreen(channel: ex),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.shareMedia,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) {
          final ex = state.extra;
          if (ex is! List || ex.isEmpty || ex.first is! SharedMediaItem) {
            return gvTransitionPage(
              state,
              Scaffold(
                body: Center(
                  child: Text(
                    AppLocalizations.of(context)!.routeInvalidArguments,
                  ),
                ),
              ),
            );
          }
          final items = ex.cast<SharedMediaItem>();
          return gvTransitionPage(
            state,
            ShareMediaScreen(items: items),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.recommendContact,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) {
          final ex = state.extra;
          if (ex is! NamecardPayload) {
            return gvTransitionPage(
              state,
              Scaffold(
                body: Center(
                  child: Text(
                    AppLocalizations.of(context)!.routeInvalidArguments,
                  ),
                ),
              ),
            );
          }
          return gvTransitionPage(
            state,
            RecommendContactScreen(card: ex),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.contactsAdd,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) => gvTransitionPage(
          state,
          const AddFriendScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.contactsRequests,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) => gvTransitionPage(
          state,
          const FriendRequestsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.friendGroups,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) => gvTransitionPage(
          state,
          const FriendGroupsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.settingsBlacklist,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) => gvTransitionPage(
          state,
          const BlacklistScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.contactDetail,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final bool fromGroup;
          final int? sourceGroupId;
          final bool hideAccountDetails;
          final bool hideFriendRequest;
          if (extra is ({
            bool fromGroup,
            int? sourceGroupId,
            bool hideAccountDetails,
            bool hideFriendRequest
          })) {
            fromGroup = extra.fromGroup;
            sourceGroupId = extra.sourceGroupId;
            hideAccountDetails = extra.hideAccountDetails;
            hideFriendRequest = extra.hideFriendRequest;
          } else if (extra is ({bool fromGroup, int? sourceGroupId})) {
            fromGroup = extra.fromGroup;
            sourceGroupId = extra.sourceGroupId;
            hideAccountDetails = false;
            hideFriendRequest = false;
          } else {
            fromGroup = extra == true;
            sourceGroupId = null;
            hideAccountDetails = false;
            hideFriendRequest = false;
          }
          return gvTransitionPage(
            state,
            ContactDetailScreen(
              id: state.pathParameters['id']!,
              fromGroup: fromGroup,
              sourceGroupId: sourceGroupId,
              hideAccountDetails: hideAccountDetails,
              hideFriendRequest: hideFriendRequest,
            ),
          );
        },
        routes: [
          GoRoute(
            path: AppRoutes.chatHistorySegment,
            parentNavigatorKey: gvRootNavigatorKey,
            pageBuilder: (context, state) => gvTransitionPage(
              state,
              ChatHistorySearchScreen(
                peerId: state.pathParameters['id']!,
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.groupsCreate,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) => gvTransitionPage(
          state,
          const CreateGroupScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.secretGroupsCreate,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) => gvTransitionPage(
          state,
          const CreateSecretGroupScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.groupInvite,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) => gvTransitionPage(
          state,
          InviteGroupMembersScreen(
            groupId: state.pathParameters['id']!,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.groupDetail,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) => gvTransitionPage(
          state,
          GroupInfoScreen(id: state.pathParameters['id']!),
        ),
        routes: [
          GoRoute(
            path: AppRoutes.chatHistorySegment,
            parentNavigatorKey: gvRootNavigatorKey,
            pageBuilder: (context, state) => gvTransitionPage(
              state,
              ChatHistorySearchScreen(
                peerId: state.pathParameters['id']!,
                chatType: 'group',
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.settings,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) => gvTransitionPage(
          state,
          const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.favorites,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) => gvTransitionPage(
          state,
          const FavoritesScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.favoriteDetail,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) {
          final ex = state.extra;
          if (ex is! ChatMessage) {
            return gvTransitionPage(
              state,
              Scaffold(
                body: Center(
                  child: Text(
                    AppLocalizations.of(context)!.routeInvalidArguments,
                  ),
                ),
              ),
            );
          }
          return gvTransitionPage(
            state,
            FavoriteDetailScreen(message: ex),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.settingsProfile,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) => gvTransitionPage(
          state,
          const ProfileEditScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.settingsPointsAccount,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) => gvTransitionPage(
          state,
          PointsAccountBindingScreen(
            initialBinding: state.extra is PointsAccountBinding
                ? state.extra as PointsAccountBinding
                : null,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.avatarCrop,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final Widget child;
          if (extra is GvSquareCropExtra) {
            child = AvatarCropScreen(
              imageBytes: extra.imageBytes,
              title: extra.title,
              confirmButtonText: extra.confirmButtonText,
              stickerCrop: extra.stickerCrop,
            );
          } else if (extra is Uint8List) {
            child = AvatarCropScreen(imageBytes: extra);
          } else {
            child = Scaffold(
              body: Center(
                child: Text(
                  AppLocalizations.of(context)!.avatarCropMissingData,
                ),
              ),
            );
          }
          return gvTransitionPage(state, child);
        },
      ),
      GoRoute(
        path: AppRoutes.settingsPassword,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) => gvTransitionPage(
          state,
          const ChangePasswordScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.settingsDevices,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) => gvTransitionPage(
          state,
          const DeviceManagementScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.notificationSettings,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) => gvTransitionPage(
          state,
          const NotificationSettingsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.selfDestruct,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) => gvTransitionPage(
          state,
          const SelfDestructScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.chatStorage,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) => gvTransitionPage(
          state,
          const ChatStorageScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.chatBackup,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) => gvTransitionPage(
          state,
          const ChatBackupScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.scan,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) => gvTransitionPage(
          state,
          const ScanScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.call,
        parentNavigatorKey: gvRootNavigatorKey,
        pageBuilder: (context, state) => gvNoTransitionPage(
          state,
          CallScreen(answerIncoming: state.extra == true),
        ),
      ),
    ],
  );
}
