# open_chat_app

[中文](README.md) | [English](README.en.md)

Open IM Flutter client, paired with the Open IM server.

## Push notifications (JPush + FCM)

Firebase Cloud Messaging is no longer initialized directly by the app:

- **Android (default)**: JPush plus the FCM vendor channel on devices with Google Play services; reports the JPush Registration ID to the server.
- **Android (local fallback)**: with `--dart-define=OPEN_ANDROID_JPUSH_ENABLED=false`, keep the existing WebSocket alive with a foreground service and skip JPush.
- **iOS**: JPush + APNs token authentication; reports `pushProvider: "jpush"` and the JPush Registration ID.

The Android fallback only works while the process and WebSocket are alive. Production offline delivery uses JPush with the FCM vendor channel.

Android voice/video calls use a full-screen incoming-call notification when the system permits it; otherwise they fall back to a high-priority notification. iOS uses CallKit while the app can receive the call over WebSocket; reliable wake-up after suspension requires PushKit VoIP tokens and APNs VoIP pushes.

### JPush AppKey

1. Add the Android JPush AppKey to `android/local.properties` (never commit real keys). The key must match package `io.openware.openchat`:

```properties
jpush.appKey=your-jpush-appkey
```

2. Android initializes JPush from the manifest `JPUSH_APPKEY`; `OPEN_JPUSH_APPKEY` is optional. iOS still needs the iOS AppKey for Bundle ID `io.openware.openchat`. Example:

```bash
flutter run --dart-define=OPEN_JPUSH_APPKEY=your-jpush-appkey --dart-define=OPEN_ANDROID_JPUSH_ENABLED=true --dart-define=OPEN_JPUSH_PRODUCTION=false
```

`android/app/google-services.json` must use package `io.openware.openchat`.

### Package and debug signing

- Android applicationId: `io.openware.openchat` (independent of the legacy `com.csmimtbshop.com`).
- Debug builds use `android/openchat-debug.jks` (alias `openchat-debug`), never the legacy WV release keystore.
- Release builds use `android/key.properties` when present.
- JPush/Firebase consoles need a new app registered for `io.openware.openchat`.

Use `OPEN_JPUSH_PRODUCTION=true` in production.

### iOS

Enable **Signing & Capabilities → Push Notifications** in Xcode. JPush recommends **Token Authentication (.p8)**; verify Key ID, Team ID and Bundle ID.

For notification tap routing, the server should include:

```json
{
  "chatType": "private",
  "peerId": "123",
  "msgId": "server-message-id"
}
```

Use `"chatType": "group"` for group chats.

## Flutter

- [Flutter getting started](https://docs.flutter.dev/get-started/codelab)
- [Flutter cookbook](https://docs.flutter.dev/cookbook)
