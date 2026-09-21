import 'package:flutter/material.dart';
import 'package:gv_ui/gv_ui.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/gv_automation_keys.dart';
import '../models/friend_models.dart';
import '../providers/chat_provider.dart';
import '../providers/friend_provider.dart';
import '../widgets/gv_nav_bar.dart';

Future<void> _acceptRequestAndSendGreeting(
  BuildContext context,
  FriendProvider friend,
  FriendRequestItem request,
) async {
  try {
    await friend.handleRequest(request.id, 'accepted');
  } catch (_) {
    return;
  }
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context)!;
  context.read<ChatProvider>().sendMessage(
        '${request.fromUserId}',
        'private',
        'text',
        l10n.friendAcceptAutoGreeting,
      );
}

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendProvider>().loadPendingRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final f = context.watch<FriendProvider>();

    return Scaffold(
      key: GvAutomationKeys.friendRequestsScreen,
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: GvNavBar(title: l10n.contactsNewFriends, showBack: true),
      body: f.pendingRequests.isEmpty
          ? Center(
              child: Text(l10n.contactsFriendRequestsEmpty,
                  style: const TextStyle(color: AppColors.textSecondary)))
          : ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: f.pendingRequests.length,
              itemBuilder: (_, i) {
                final r = f.pendingRequests[i];
                return _RequestTile(request: r, friend: f, l10n: l10n);
              },
            ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({
    required this.request,
    required this.friend,
    required this.l10n,
  });

  final FriendRequestItem request;
  final FriendProvider friend;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final handling = friend.isHandlingRequest(request.id);
    return GvCardShell(
      borderRadius: BorderRadius.circular(GvRadii.card),
      child: Material(
        color: AppColors.bgWhite.resolveFrom(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.contactsFriendRequestLine(
                        request.requesterDisplayLabel.isNotEmpty
                            ? request.requesterDisplayLabel
                            : '${request.fromUserId}',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w400),
                    ),
                    if ((request.message ?? '').isNotEmpty)
                      Text(request.message!,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger.resolveFrom(context),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: handling
                        ? null
                        : () => friend.handleRequest(request.id, 'rejected'),
                    child: Text(l10n.contactsFriendRequestReject),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    style: TextButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: handling
                        ? null
                        : () => _acceptRequestAndSendGreeting(
                              context,
                              friend,
                              request,
                            ),
                    child: handling
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.contactsFriendRequestAccept),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
