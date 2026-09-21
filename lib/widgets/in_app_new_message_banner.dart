import 'package:flutter/material.dart';
import 'package:gv_chat_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../providers/chat_provider.dart';

/// 悬浮在顶部的柔和阴影（略强于 [GvShadows.card]，便于「浮在系统/内容之上」的观感）。
List<BoxShadow> get _bannerFloatShadow => const [
      BoxShadow(
        color: Color(0x14000000),
        offset: Offset(0, 2),
        blurRadius: 8,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Color(0x24000000),
        offset: Offset(0, 12),
        blurRadius: 28,
        spreadRadius: -4,
      ),
    ];

/// 应用在前台但不在对应会话时，顶部短时提示「收到新消息」（无交互，由 [ChatProvider] 控显隐与节流）。
class InAppNewMessageBanner extends StatelessWidget {
  const InAppNewMessageBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (_, chat, __) {
        if (!chat.showInAppNewMessageBanner) {
          return const SizedBox.shrink();
        }
        final l10n = AppLocalizations.of(context)!;
        final top = MediaQuery.viewPaddingOf(context).top + GvSpacing.sm;

        return Positioned(
          left: 0,
          right: 0,
          top: top,
          child: IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: GvSpacing.page),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: double.infinity,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(GvRadii.cardLg),
                      boxShadow: _bannerFloatShadow,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: GvSpacing.page,
                        vertical: GvSpacing.sm + 2,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.volume_up_rounded,
                            size: 26,
                            color: AppColors.primary.resolveFrom(context),
                          ),
                          const SizedBox(width: GvSpacing.page),
                          Expanded(
                            child: Text(
                              l10n.bannerNewMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF1C1C1E),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.2,
                              ),
                            ),
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
