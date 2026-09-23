# Channel & Secret Chat (Frontend)

> Engineering baseline for the channel (single-direction broadcast) and secret
> chat (E2EE) features in `open_chat_app`. Follows
> [coding_guidelines.md](coding_guidelines.md) and
> [project-conventions.md](generate-gv-chat-flutter/references/project-conventions.md).

## 1. Feature Overview

- **Channel**: one-to-many broadcast conversation. Only the owner publishes;
  subscribers read. Shown with a dedicated conversation-type icon in the chat
  list.
- **Secret chat**: one-to-one E2EE conversation with a lock badge, a safe-code
  (fingerprint) display, and a self-destruct policy (`off/30s/5m/1h/1d`). The
  server stores only ciphertext and never decrypts.

## 2. Models

- `lib/models/channel_models.dart` — `ChannelInfo` (parses snake_case payload;
  `myRole` defaults to `subscriber`, admin counts as owner), channel create
  request/result types.
- `lib/models/secret_chat_models.dart` — `SecretChatInfo` (peer user id,
  handshake state, safe code, destroy policy), secret message types.
- Wire mapping tests: `test/models/channel_secret_models_test.dart`.

## 3. API Client

- Retrofit endpoints are declared in
  `lib/services/generated_im_api_client.dart` (hand-written `.g.dart` kept in
  sync) and delegated through `lib/services/im_api.dart`:

```text
POST   /channels                 create channel
POST   /channels/{id}/subscribe  subscribe
GET    /channels/mine            my channels
GET    /channels/{id}            channel detail (myRole/subscribed/memberCount)
POST   /secret-chats             create secret chat
GET    /secret-chats/mine        my secret chats
GET    /secret-chats/{id}        secret chat detail
POST   /secret-chats/{id}/handshake            submit E2EE public key
POST   /secret-chats/{id}/destroy-policy       set destroy policy
POST   /secret-messages          post ciphertext
GET    /secret-messages          cursor-pull ciphertext by secret chat
```

## 4. UI

- `chat_list_screen.dart` — conversation-type icons for
  `channel`/`secret`/`group`/`private`; channel create dialog (name →
  `ChatProvider.createChannel` → open channel room).
- `chat_room_screen.dart` — channel rooms are read-only for subscribers
  (`readOnly` + hint); secret chat settings sheet shows the E2EE lock, safe-code
  view/copy, self-destruct options, and the "not synced to new devices" hint.
- `contact_detail_screen.dart` — entry to start a secret chat with a contact.
- `gv_chat_bottom_composer.dart` — `readOnly`/`readOnlyHint` for channel
  subscribers.

## 5. Localization

- All new user-facing strings live in `lib/l10n/app_en.arb` /
  `lib/l10n/app_zh.arb`; generated `app_localizations*.dart` are committed and
  regenerated with `flutter gen-l10n` (driven by `l10n.yaml`).
- No hard-coded user-facing text (see `architecture.md` → Text And
  Localization).

## 6. Verification

- `flutter analyze`: 0 issues for this feature set.
- `flutter test`: channel/secret model tests included; full suite green.
- Server contracts are covered by the backend delivery reports (see team
  archive).

## 7. Notes

- E2EE key exchange + client-side encryption/decryption is the remaining
  frontend work; backend device-key registration, ciphertext storage, and the
  timed-destroy engine are ready.
