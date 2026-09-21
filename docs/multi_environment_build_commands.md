# 多环境打包方案

## 当前状态

项目已经具备 Flutter 侧的基础多环境能力：

- 使用 `APP_ENV` 选择环境：`dev`、`test`、`prod`。
- 使用 `EnvConfig` 集中维护不同环境的默认服务地址。
- 保留 `GV_API_BASE` 作为临时覆盖入口，方便本地联调。
- 保留 `GV_WS_URI` 作为 WebSocket 完整地址覆盖入口。
- 保留 `GV_JPUSH_APPKEY` 作为平台推送 AppKey 入口。
- `GV_JPUSH_PRODUCTION` 不传时会按环境自动判断：`prod=true`，`dev/test=false`。
- 新增统一构建脚本 `tools/build.ps1`，日常打包不需要手写长命令。

还没有完成的是原生平台级多环境：

- Android 还没有 `productFlavors`。
- iOS 还没有 `Runner-Dev`、`Runner-Test`、`Runner-Prod` 等 Scheme。
- 不同环境还没有独立包名、Bundle ID、图标、应用名和签名配置。
- 还没有 CI/CD 自动打包流水线。

所以目前是第一阶段：Flutter 环境配置和本地构建脚本已经规范化，原生 flavor / scheme 后续再接。

## 环境默认值

| 环境 | APP_ENV | 默认 API 地址 | 默认 WebSocket 地址 | JPush production |
| --- | --- | --- | --- | --- |
| 开发 | `dev` | `http://192.168.1.3:3000` | `ws://192.168.1.3:3000/ws/im/v1` | `false` |
| 测试 | `test` | `https://test-api.example.com` | `wss://test-api.example.com/ws/im/v1` | `false` |
| 生产 | `prod` | `https://api.dev.example.com` | `wss://api.dev.example.com/ws/im/v1` | `true` |

如果临时要连接其他后端，可以额外传 `-ApiBase` 和 `-WsUri` 覆盖默认地址。

## 推荐打包方式

在项目根目录执行。

### Android 开发 APK

```powershell
.\tools\build.ps1 android dev apk -JPushAppKey "你的Android极光AppKey"
```

### Android 测试 APK

```powershell
.\tools\build.ps1 android test apk -JPushAppKey "你的Android极光AppKey"
```

**USB 真机联调 A380（仅 dev/test）**

当测试 H5 使用局域网 HTTP 地址时，必须显式登记 origin；脚本会拒绝在 `prod` 包中传入该参数：

```powershell
.\tools\build.ps1 android test apk -HybridTestOrigin "http://192.168.31.91:30082"
```

该开关仅让已登记的 `/a380/` 和 `/b/` 页面获得原生 OAuth 桥接。它不会更改 C 端 `saas-a380-c`、B 端 `saas-a380-h5` 的 appId、redirect 白名单或运营角色校验。

### Android 正式 AAB

```powershell
.\tools\build.ps1 android prod appbundle -JPushAppKey "你的Android极光AppKey"
```

### iOS 测试 IPA

```powershell
.\tools\build.ps1 ios test ipa -JPushAppKey "你的iOS极光AppKey"
```

### iOS 正式 IPA

```powershell
.\tools\build.ps1 ios prod ipa -JPushAppKey "你的iOS极光AppKey"
```

### Web 测试包

```powershell
.\tools\build.ps1 web test
```

### Web 正式包

```powershell
.\tools\build.ps1 web prod
```

正式 Web 默认使用：

```text
/uploads/app-web/
```

如需临时覆盖：

```powershell
.\tools\build.ps1 web prod -BaseHref "/custom-path/"
```

### Windows 正式包

```powershell
.\tools\build.ps1 windows prod
```

### HarmonyOS / OpenHarmony HAP

```powershell
.\tools\build.ps1 hap prod
```

## 临时覆盖 API 地址

例如连接预发布环境：

```powershell
.\tools\build.ps1 android test apk -ApiBase "https://staging-api.example.com" -WsUri "wss://staging-api.example.com/ws/im/v1" -JPushAppKey "你的Android极光AppKey"
```

脚本会转换为：

```text
--dart-define=APP_ENV=test
--dart-define=GV_API_BASE=https://staging-api.example.com
--dart-define=GV_WS_URI=wss://staging-api.example.com/ws/im/v1
--dart-define=GV_JPUSH_APPKEY=你的Android极光AppKey
```

## Android 注意事项

Android 原生侧当前还会从 `android/local.properties` 读取 `jpush.appKey`，用于 AndroidManifest 占位符。打 Android 包前需要确认：

```properties
jpush.appKey=你的Android极光AppKey
```

不要把真实 AppKey、签名密码、证书密码提交到 Git。

后续接入 Android `productFlavors` 后，Android 命令会进一步升级为：

```text
flutter build apk --flavor dev --dart-define=APP_ENV=dev
flutter build apk --flavor test --dart-define=APP_ENV=test
flutter build appbundle --flavor prod --dart-define=APP_ENV=prod
```

## iOS 注意事项

iOS 当前只有同一个 Runner Scheme，Bundle ID 为：

```text
com.gv.chat.gvChatApp
```

当前工程里已有 Debug/Release entitlements 和手动签名配置，但还没有 dev/test/prod 三套 Scheme。打 iOS 包时要确保：

- `GV_JPUSH_APPKEY` 使用 iOS 极光应用的 AppKey。
- `APP_ENV=dev/test` 默认使用开发推送环境。
- `APP_ENV=prod` 默认使用生产推送环境。
- Xcode 里的 Bundle ID、Team ID、Provisioning Profile、极光后台 iOS 应用配置保持一致。

后续接入 iOS Scheme 后，目标结构是：

```text
Runner-Dev
Runner-Test
Runner-Prod
```

并分别绑定：

```text
Bundle ID
Display Name
Provisioning Profile
JPush AppKey
APNs production/development
```

## 后续改造顺序

1. Flutter `EnvConfig + APP_ENV`：已完成。
2. `tools/build.ps1` 统一构建入口：已完成。
3. Android `productFlavors`：待做。
4. iOS Schemes / Configurations：待做。
5. CI/CD 自动打包：待做。

flutter run --dart-define=GV_JPUSH_APPKEY=YOUR_JPUSH_APPKEY --dart-define=GV_JPUSH_PRODUCTION=false
flutter build ipa --release \
  --dart-define=APP_ENV=prod \
  --dart-define=GV_API_BASE=https://api.dev.example.com \
  --dart-define=GV_JPUSH_APPKEY=YOUR_JPUSH_APPKEY \
  --dart-define=GV_JPUSH_PRODUCTION=true
  flutter run --release `
  --dart-define=APP_ENV=prod `
  --dart-define=GV_API_BASE=https://api.dev.example.com `
  --dart-define=GV_JPUSH_APPKEY=YOUR_JPUSH_APPKEY `
  --dart-define=GV_JPUSH_PRODUCTION=true
flutter run --release --dart-define=APP_ENV=prod --dart-define=GV_API_BASE=https://api.dev.example.com --dart-define=GV_JPUSH_APPKEY=YOUR_JPUSH_APPKEY --dart-define=GV_JPUSH_PRODUCTION=true
