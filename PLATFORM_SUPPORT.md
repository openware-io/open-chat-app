# 各端系统版本与运行环境支持说明

本文档根据**当前仓库配置**与 **Flutter 3.41 stable**（`pubspec.yaml` 约束）整理，描述可安装/可构建的最低环境。实际下限可能随 **Flutter SDK 升级**或**插件变更**而变化，发版前请以 `flutter doctor` 与各端构建结果为准。

---

## 总览

| 平台 | 最低用户系统版本（安装/运行） | 主要依据 |
|------|------------------------------|-----------|
| **Android** | **API 24（Android 7.0）** | `android/app/build.gradle` 使用 `minSdkVersion = flutter.minSdkVersion`；Flutter 工具链默认 `minSdkVersion = 24`（见下文「Android 详情」） |
| **iOS** | **iOS 15.0** | `ios/Podfile` 的 `platform :ios, '15.0'` 与 `post_install` 中 `IPHONEOS_DEPLOYMENT_TARGET = 15.0`，以及 `ios/Runner.xcodeproj/project.pbxproj` |
| **macOS** | **建议以 11.0 为下限**（见「macOS 详情」） | `macos/Podfile`：`platform :osx, '10.15'`；`macos/Runner.xcodeproj`：`MACOSX_DEPLOYMENT_TARGET = 10.14`（两处需对齐时取较高版本更稳） |
| **Windows** | **Windows 10 64 位**（官方 Flutter 桌面要求；具体内部版本以 Flutter 文档为准） | 仓库内未单独写死系统版本；遵循 [Flutter Windows 桌面说明](https://docs.flutter.dev/platform-integration/windows/building) |
| **Web** | 无单一「最低 OS」 | 依赖现代浏览器（ESM、Canvas/WebGL 等）；本项目含 `web/` 目标，未在仓库中声明具体浏览器最低版本 |

本仓库**未包含** `linux/` 工程目录，**未对 Linux 桌面打包**做项目级配置说明。

---

## Android 详情

| 项 | 值 | 说明 |
|----|-----|------|
| `minSdkVersion` | **24** | 由 Flutter Gradle 插件提供的 `flutter.minSdkVersion` 注入；当前 **Flutter 3.41** 默认定义在 Flutter SDK 的 `FlutterExtension`（与 `gradle_utils.dart` 约定一致） |
| `compileSdk` | **36** | `android/app/build.gradle` |
| `targetSdk` | **36** | `targetSdk = flutter.targetSdkVersion`（随 Flutter 默认） |
| Java | **17** | `sourceCompatibility` / `targetCompatibility`、`jvmTarget` |
| NDK | Flutter 默认 | 通过 `ndkVersion = flutter.ndkVersion` |

工程注释说明：`record` 等能力需要 **API 23+**，当前默认 **24** 满足该要求。

---

## iOS 详情

| 项 | 值 |
|----|-----|
| 部署目标 | **iOS 15.0** |
| 配置位置 | `ios/Podfile`（`platform :ios` 与 `post_install`）、`ios/Runner.xcodeproj/project.pbxproj` |

Podfile 注释：`Firebase iOS SDK` 等与 **iOS 15** 的最低要求需与 Xcode 部署目标一致。

---

## macOS 详情

| 配置来源 | 声明版本 |
|----------|-----------|
| `macos/Podfile` | `platform :osx, '10.15'` |
| `macos/Runner.xcodeproj/project.pbxproj` | `MACOSX_DEPLOYMENT_TARGET = 10.14` |

**建议：** 将 Xcode 工程中的 `MACOSX_DEPLOYMENT_TARGET` 与 Podfile 统一为 **同一版本**（例如均为 **10.15**），避免 CocoaPods 与主目标的最低系统不一致带来的链接或运行时问题。对外说明「最低 macOS」时，可取 **两者中的较高者**（当前即 **10.15**）。

---

## Windows 详情

- 仓库 `windows/CMakeLists.txt` 使用 **C++17**（`cxx_std_17`），不包含显式的 Windows 内部版本号 floor。
- Flutter 官方对 Windows 桌面应用的一般要求是 **64 位 Windows 10 及以上**；具体请以当前使用的 Flutter 版本的官网说明为准。

---

## Web 详情

- 存在 `web/index.html` 等 Web 资源，未在项目中固定「最低浏览器版本」。
- 若需对外承诺支持矩阵，建议在集成测试或文档中补充浏览器与版本的冒烟范围。

---

## 开发侧 SDK 约束（非终端用户）

| 项 | 约束（摘自 `pubspec.yaml`） |
|----|-----------------------------|
| Dart SDK | `>=3.4.4 <4.0.0` |
| Flutter | `>=3.29.0`（注释中与 `mobile_scanner` 等依赖对齐） |

---

## 如何自行核验

- **Android：** 构建前在 `android/app/build.gradle` 确认 `minSdkVersion`；或在 Android Studio / `gradlew` 合并后的 manifest 中查看 `uses-sdk`。
- **iOS / macOS：** Xcode → Target → *Deployment*，或与 `Podfile`/`project.pbxproj` 对照。
- **环境：** 在项目根目录执行 `flutter doctor -v`，确认本机 Flutter 版本与各平台工具链。

---

*生成依据：仓库内 Gradle / Podfile / Xcode 工程文件，以及本机 Flutter SDK `packages/flutter_tools/gradle/.../FlutterExtension.kt` 中的默认 `minSdkVersion`（当前为 24）。*
