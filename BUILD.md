# 各端打包命令

> **发版（Android 直装 APK）不是只看这里，先读 [`gv_im_server/docs/standards/15_CLIENT_RELEASE_SKILL.md`](../gv_im_server/docs/standards/15_CLIENT_RELEASE_SKILL.md) 并运行 `tools/release.ps1`**；本文档是打包命令的权威来源，其中「发布 APK = `flutter build apk --release`」「AAB 仅用于 Google Play」。

在项目根目录 `gv_chat_app/` 下执行。默认使用 [AppConfig](lib/core/config.dart) 中的接口地址；若需指定其它服务端，在所有命令中追加相同的 `--dart-define` 即可。

## 环境与通用参数

- **Flutter**：与本项目 `pubspec.yaml` 中 `environment.flutter` 要求一致（建议稳定版）。
- **覆盖 API 基址**（不含末尾 `/`）：
  ```bash
  --dart-define=GV_API_BASE=https://your-host.example.com
  ```
- **内网 HTTPS 自签名（仅建议内测）**：
  ```bash
  --dart-define=GV_TRUST_SELF_SIGNED=true
  ```

以下示例默认不写 `dart-define` 时，使用编译进工程的默认值（见 `lib/core/config.dart`）。

---

## Android

**调试 APK**

```bash
flutter build apk --debug
```

**发布 APK**（单架构可减小体积，按需选用 `--split-per-abi`）

```bash
flutter build apk --release
```

输出目录：`build/app/outputs/flutter-apk/`

**Google Play 上架用 AAB**

```bash
flutter build appbundle --release
```

输出目录：`build/app/outputs/bundle/release/`

---

## iOS

须在 **macOS** 上安装 Xcode，并完成证书与描述文件配置（参见 Apple 开发者文档）。

**命令行打 IPA**

```bash
flutter build ipa --release --dart-define=GV_JPUSH_APPKEY=你的iOS极光AppKey --dart-define=GV_JPUSH_PRODUCTION=true
```

输出目录：`build/ios/ipa/`（具体文件名以生成为准）

也可打开 `ios/Runner.xcworkspace`，在 Xcode 中 **Product → Archive** 再分发。

**Bundle ID**：`com.gv.chat.gvChatApp`（见 `ios/Runner.xcodeproj/project.pbxproj`）

离线推送使用极光 JPush。iOS 极光后台请配置 Token Authentication（`.p8`），并确保 Key ID、Team ID、Bundle ID 与该 AppKey 绑定的应用一致。

---

## Web

**默认站点部署在根路径**

```bash
flutter build web --release
```

输出目录：`build/web/`

**部署在子路径**（例如站点为 `https://example.com/uploads/app-web/` 时，需与反向代理 `try_files` 回退到 `index.html` 一致）

```bash
flutter build web --release --base-href /uploads/app-web/
```

---

## Windows

```bash
flutter build windows --release
```

输出目录：`build/windows/x64/runner/Release/`（以本机架构为准）

---

## macOS

```bash
flutter build macos --release
```

须在 **macOS** 上执行；首次构建前需满足 Xcode 与 CocoaPods 要求（`macos/Podfile`）。

输出目录：`build/macos/Build/Products/Release/`（或通过 Xcode 工程查看生成产物）

---

## 鸿蒙 HarmonyOS / OpenHarmony（HAP）

鸿蒙侧使用 **支持 OpenHarmony 的 Flutter SDK**（与 [flutter.dev](https://flutter.dev) 默认稳定版可能不同）。请先安装 **DevEco Studio / OHOS SDK**，将 `flutter doctor -v` 中 OpenHarmony 相关项配置为通过；具体版本与下载请以华为/OpenHarmony 官方文档为准。

**工程是否已有 `ohos/` 目录**

- 若还没有：在项目根目录为现有工程添加鸿蒙模块（**建议先提交 Git 再执行**，避免覆盖冲突）：
  ```bash
  flutter create --platforms ohos .
  ```
- 本仓库若已包含 `ohos/`，可直接构建。

**调试 HAP**

```bash
flutter build hap --debug
```

**发布 HAP**

```bash
flutter build hap --release
```

**指定目标 CPU（按 SDK 文档可选）**

```bash
flutter build hap --release --target-platform ohos-arm64
```

**与 Android 相同，可附带 API 等 `dart-define`**

```bash
flutter build hap --release --dart-define=GV_API_BASE=https://dv380.com
```

**产物路径**（以工程 `ohos` 模块默认配置为准，常见如下）

```text
ohos/entry/build/default/outputs/default/entry-default-signed.hap
```

**安装到设备**（需 `hdc` 可用、`USB 调试` 或网络连接正常）

```bash
hdc -t <deviceId> install <hap文件路径>
```

**真机/模拟器运行**

```bash
flutter devices
flutter run --debug -d <device_id>
```

环境变量示例（以你本机 DevEco 安装路径为准）：`DEVECO_SDK_HOME`、`JAVA_HOME`（多为 JDK 17）、以及工具链要求的 `PATH`。

---

## 本地运行（非打包）

```bash
flutter pub get
flutter run
```

**Web 调试**

```bash
flutter run -d chrome
```

**指定设备**

```bash
flutter devices
flutter run -d <device_id>
```

---

## 带自定义 API 的发布示例

```bash
flutter build apk --release --dart-define=GV_API_BASE=https://dv380.com
flutter build ipa --release --dart-define=GV_API_BASE=https://dv380.com --dart-define=GV_JPUSH_APPKEY=你的iOS极光AppKey --dart-define=GV_JPUSH_PRODUCTION=true
flutter build web --release --dart-define=GV_API_BASE=https://dv380.com --base-href /uploads/app-web/
flutter build hap --release --dart-define=GV_API_BASE=https://dv380.com
```

（`GV_API_BASE` 请勿带末尾 `/`。）
