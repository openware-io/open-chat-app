# open_chat_app

GV Chat Flutter 客户端，与 gv_chat_server 配套。

## 消息通知（极光 JPush + Google FCM）

本项目已移除 **Firebase Cloud Messaging**。移动端策略为：

- **Android（当前默认）**：使用极光 JPush，并在支持 Google Play 服务的设备上启用 FCM 厂商通道；向服务端上报极光 Registration ID。
- **Android（本地调试回退）**：显式传入 `--dart-define=GV_ANDROID_JPUSH_ENABLED=false` 时，使用前台服务保活现有 WebSocket，不初始化或注册极光。
- **iOS**：极光 JPush + APNs Token Authentication，向服务端上报 `pushProvider: "jpush"` 与极光 **Registration ID**。

Android 本地调试回退依赖应用进程和 WebSocket 仍然存活，用户强制停止应用或系统彻底杀死进程后无法继续收消息；正式离线通知使用配置好 FCM 厂商通道的极光。

Android 后台收到语音或视频来电时会使用全屏来电通知：系统授权后可点亮锁屏并直接进入接听页；未授权或系统不允许全屏展示时自动降级为普通高优先级来电通知。Android 14 及以上首次使用可能打开“全屏通知”系统授权页。

iOS 已接入 CallKit：App 仍能通过 WebSocket 收到来电时会显示系统来电界面。若要在 App 被系统挂起或杀死后仍可靠唤醒，需要另外配置 PushKit VoIP token，并由服务端通过 APNs 发送 VoIP Push。

### 极光 AppKey 配置

1. 在 **`android/local.properties`**（请勿把真实密钥提交到 Git）末尾增加 Android 极光应用 **AppKey**（须与控制台里该包名 `com.csmimtbshop.com` 一致）：

```properties
jpush.appKey=你的极光AppKey
```

2. Android 会从 Manifest 的 `JPUSH_APPKEY` 初始化极光；`GV_JPUSH_APPKEY` 可选。iOS 仍需传入极光控制台里 Bundle ID `com.gv.chat.gvChatApp` 对应的 iOS 应用 AppKey。显式指定 Android AppKey 的运行示例：

```bash
flutter run --dart-define=GV_JPUSH_APPKEY=你的极光AppKey --dart-define=GV_ANDROID_JPUSH_ENABLED=true --dart-define=GV_JPUSH_PRODUCTION=false
```

Google FCM 配置文件位于 `android/app/google-services.json`，包名必须为 `com.csmimtbshop.com`。项目通过 Google Services Gradle 插件和极光 FCM 插件生成并注册 FCM 客户端配置。

生产环境请将 `GV_JPUSH_PRODUCTION=true`（与极光控制台、「正式 / 开发」推送环境一致）。

### iOS

在 Xcode 中启用 **Signing & Capabilities → Push Notifications**；若需静默刷新可保留 **Background Modes → Remote notifications**。极光后台 iOS 证书建议使用 **Token Authentication (.p8)**，并确认 Key ID、Team ID、Bundle ID 与当前应用一致。

离线通知点击跳聊天室依赖服务端在极光通知 `extras` 中下发会话定位字段，推荐格式：

```json
{
  "chatType": "private",
  "peerId": "123",
  "msgId": "server-message-id"
}
```

群聊使用：

```json
{
  "chatType": "group",
  "peerId": "456",
  "msgId": "server-message-id"
}
```

服务端推送渠道与密钥说明见同工作区 **`gv_chat_server/push-channels-integration.md`**（若仓库分列，请指向对应路径）。

---

## Flutter 入门

- [Flutter 入门](https://docs.flutter.dev/get-started/codelab)
- [Flutter 范例](https://docs.flutter.dev/cookbook)
