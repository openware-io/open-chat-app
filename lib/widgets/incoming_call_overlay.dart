import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/open_root_navigator.dart';
import '../providers/call_provider.dart';
import 'open_avatar.dart';

/// Top card matching H5 `IncomingCall.vue`.
class IncomingCallOverlay extends StatelessWidget {
  const IncomingCallOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CallProvider>(
      builder: (_, call, __) {
        if (!call.showIncomingCallBanner) return const SizedBox.shrink();
        final topSafe = MediaQuery.viewPaddingOf(context).top + GvSpacing.sm;
        return Positioned(
          left: 0,
          right: 0,
          top: topSafe,
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: GvSpacing.page),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: double.infinity,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xF21E1E1E),
                    borderRadius: BorderRadius.circular(GvRadii.cardLg),
                    boxShadow: GvShadows.card,
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    borderRadius: BorderRadius.circular(GvRadii.cardLg),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(GvSpacing.page),
                      child: Row(
                        children: [
                          GvAvatar(
                              name: call.remoteUsername ?? '',
                              uid: call.remoteUserId ?? 0,
                              src: call.remoteAvatar,
                              size: 52),
                          const SizedBox(width: GvSpacing.page),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  call.remoteUsername ?? '未知',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400),
                                ),
                                Text(
                                  call.mediaType == 'video' ? '视频通话' : '语音通话',
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.65),
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          _IncomingCallCircleButton(
                            color: const Color(0xFFFF3B30),
                            icon: LucideIcons.phone_off,
                            onTap: () => call.rejectCall(),
                          ),
                          const SizedBox(width: GvSpacing.sm),
                          _IncomingCallCircleButton(
                            color: const Color(0xFF34C759),
                            icon: LucideIcons.phone,
                            onTap: () async {
                              call.suppressIncomingCallBanner();
                              if (kIsWeb) {
                                final prep = await call
                                    .prepareWebLocalMediaInUserGesture();
                                if (prep != CallInitMediaOutcome.success) {
                                  await call.rejectCall();
                                  return;
                                }
                              }
                              final rootCtx = gvRootNavigatorKey.currentContext;
                              if (rootCtx != null && rootCtx.mounted) {
                                GoRouter.of(rootCtx).push('/call', extra: true);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Material 2 下 [IconButton.style] 不生效，用独立 [Material] 画圆形底色。
class _IncomingCallCircleButton extends StatelessWidget {
  const _IncomingCallCircleButton({
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}
