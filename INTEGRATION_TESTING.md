# 集成测试

项目使用 Flutter 官方 `integration_test`。本地执行后会生成 HTML 报告、JSON 汇总、Flutter 原始事件和错误日志。

## 直接运行

先连接一台 Android 手机或启动模拟器，然后在项目根目录执行：

```powershell
dart run tools/run_integration_tests.dart
```

脚本只会从 Android/iOS 设备中选择目标，因此电脑的 Windows 和 Chrome 不会干扰。只有同时连接多台手机或模拟器时，才需要设备 ID：

```powershell
flutter devices
dart run tools/run_integration_tests.dart --device=设备ID
```

需要指定测试环境时，可以把 Flutter 参数直接追加在后面：

```powershell
dart run tools/run_integration_tests.dart --dart-define=GV_API_BASE=https://example.com
```

## 一键全量安全巡检

全量入口会依次执行启动、真实用户聊天流程和全功能安全巡检，并统一生成一份报告：

```powershell
.\tools\run_full_app_tests.ps1 `
  -Device "设备ID" `
  -Username "专用测试账号" `
  -Password "测试密码" `
  -ConversationName "专用测试群"
```

也可以使用更稳定的会话 ID：

```powershell
.\tools\run_full_app_tests.ps1 `
  -Device "设备ID" `
  -Username "专用测试账号" `
  -Password "测试密码" `
  -ChatType group `
  -PeerId "群ID"
```

默认是安全巡检：会真实登录、请求后端、点击页面、输入搜索内容并打开各类表单，但不会发送消息、创建群/频道、修改资料、修改密码或退出登录。

需要验证真实消息发送时增加 `-AllowSend`；需要打开相机扫码页时增加 `-AllowCamera`。这两个选项可能产生服务端数据或系统权限弹窗，只应对专用测试账号和设备开启。

## 报告

每次运行生成一个独立目录：

```text
build/test-reports/integration-年月日-时分秒/
  report.html   可直接打开的测试报告
  report.json   便于 CI 读取的汇总结果
  events.jsonl  Flutter 原始测试事件
  stderr.log    构建及错误日志
```

报告在 `build/` 下，默认不会提交到 Git。

## 添加固定流程

测试文件放在 `integration_test/` 目录：

- `app_startup_test.dart`：验证应用能够正常启动。
- `reviewer_flow_test.dart`：模拟审核人员登录、搜索并点击会话、输入消息；开启真实发送后，还会点击发送、长按刚发送的消息并确认仅从本机删除。
- `full_app_navigation_test.dart`：模拟用户巡检消息入口、频道表单、通讯录、好友申请、建群入口、积分、预约、个人二维码、个人资料、密码、通知、外观和语言设置。

`full_app_navigation_test.dart` 会根据服务端功能开关和设备能力记录跳过项。例如频道功能关闭时，报告中会记录频道表单已跳过；相机扫码默认跳过。

### 安全模式运行审核流程

下面的命令会完成点击和输入，但不会把测试消息发到服务端：

```powershell
dart run tools/run_integration_tests.dart `
  --target=integration_test/reviewer_flow_test.dart `
  "--dart-define=GV_TEST_USERNAME=测试账号" `
  "--dart-define=GV_TEST_PASSWORD=测试密码" `
  "--dart-define=GV_TEST_CONVERSATION_NAME=自动化测试群"
```

如果 App 已经保持登录状态，可以不传账号和密码。如果是全新安装或已退出登录，则必须传入测试账号。

### 允许真实发送

确认目标是专用测试群后，再增加下面的参数：

```powershell
"--dart-define=GV_TEST_ALLOW_SEND=true"
```

完整流程会发送一条带时间戳的文字消息，然后长按并仅从当前测试设备删除。这个“删除”不撤回服务端消息，因此不要对正式工作群开启真实发送。

如果会话名称可能重复，也可以不用名称，改传：

```powershell
"--dart-define=GV_TEST_CHAT_TYPE=group" `
"--dart-define=GV_TEST_PEER_ID=群ID"
```

测试报告中的命令会自动隐藏密码、Token 和密钥，并展示每一步自动操作及发生时间。
