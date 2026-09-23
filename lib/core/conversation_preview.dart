import '../l10n/app_localizations.dart';
import '../models/chat_message.dart';

/// Stable values persisted in [Conversation.lastMessage] for recalled messages.
///
/// The conversation cache must not persist text from the locale that happened to
/// be active when the recall arrived. The chat list resolves these values with
/// the current [AppLocalizations] instead.
const String gvConversationRecallSelfPreview =
    '__open_conversation_recall_self__';
const String gvConversationRecallPeerPreview =
    '__open_conversation_recall_peer__';

/// Builds the persisted conversation preview for [message].
String conversationPreviewForMessage(
  ChatMessage message, {
  required int? viewerId,
}) {
  if (!message.isRecalled) return message.previewForConv();
  return viewerId != null && message.from == viewerId
      ? gvConversationRecallSelfPreview
      : gvConversationRecallPeerPreview;
}

/// Resolves persisted preview markers using the locale currently shown by UI.
String localizedConversationPreview(
  AppLocalizations l10n,
  String preview,
) {
  switch (preview) {
    case gvConversationRecallSelfPreview:
      return l10n.chatMessageRecalledSelf;
    case gvConversationRecallPeerPreview:
    case '[消息已撤回]':
      // The bracketed value was persisted by older app versions. Recall events
      // received from another device were the common source of that value.
      return l10n.chatMessageRecalledPeer;
    default:
      return preview;
  }
}
