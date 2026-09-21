import Flutter
import AVFoundation
import Network
import UIKit
import UserNotifications
import flutter_webrtc
import WebRTC

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var pushApnsChannel: FlutterMethodChannel?
  private var callPlatformChannel: FlutterMethodChannel?
  private var secureScreenChannel: FlutterMethodChannel?
  private var localNetworkBrowser: NWBrowser?
  private var pendingColdStartNotification: [String: String]?
  private var isSecureEnabled = false
  private let callKitController = IOSCallKitController()
  private let videoPictureInPictureController = IOSVideoCallPictureInPictureController()
  private var ownsCallAudioActivation = false
  private var lastCallForeground: Bool?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    if let info = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
      pendingColdStartNotification = AppDelegate.flattenApnsUserInfo(info)
      clearNotificationBadge()
    }
    registerCaptureObservers()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "com.gv.chat/push_apns",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    pushApnsChannel = channel

    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "register":
        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications()
          result(nil)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let localNetworkChannel = FlutterMethodChannel(
      name: "com.gv.chat/local_network",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    localNetworkChannel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "preflight":
        self?.startLocalNetworkPreflight(result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let callChannel = FlutterMethodChannel(
      name: "com.gv.chat/call_platform",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    callPlatformChannel = callChannel
    callKitController.onHangUp = { [weak self] in
      self?.callPlatformChannel?.invokeMethod("hangUp", arguments: nil)
    }
    videoPictureInPictureController.onModeChanged = { [weak self] active in
      self?.callPlatformChannel?.invokeMethod(
        "pictureInPictureModeChanged",
        arguments: ["inPictureInPicture": active]
      )
    }
    // Returning from iOS PiP intentionally reveals the chat plus the compact
    // in-app call overlay; it must not push the full-screen call route again.
    videoPictureInPictureController.onRestore = nil

    callChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "APP_DELEGATE_RELEASED", message: nil, details: nil))
        return
      }
      switch call.method {
      case "setCallState":
        guard let args = call.arguments as? [String: Any] else {
          result(
            FlutterError(
              code: "INVALID_CALL_STATE",
              message: "Missing call state",
              details: nil
            )
          )
          return
        }
        let active = args["active"] as? Bool ?? false
        let video = args["video"] as? Bool ?? false
        let callPresent = args["callPresent"] as? Bool ?? active
        let outgoing = args["outgoing"] as? Bool ?? false
        let phase = args["phase"] as? String ?? (callPresent ? "connecting" : "idle")
        let callId = args["callId"] as? String ?? ""
        let remoteName = args["remoteName"] as? String ?? ""
        let remoteVideoTrackId = args["remoteVideoTrackId"] as? String ?? ""
        let localVideoTrackId = args["localVideoTrackId"] as? String ?? ""
        let appForeground = (args["appForeground"] as? Bool)
          ?? (UIApplication.shared.applicationState == .active)
        let connectedAtMillis = (args["connectedAtMillis"] as? NSNumber)?.doubleValue ?? 0
        let connectedAt = connectedAtMillis > 0
          ? Date(timeIntervalSince1970: connectedAtMillis / 1000)
          : nil
        if self.lastCallForeground != appForeground {
          self.lastCallForeground = appForeground
          let rtc = RTCAudioSession.sharedInstance()
          NSLog("[CallAudio] foreground=%d phase=%@ rtcActive=%d category=%@ mode=%@",
                appForeground, phase, rtc.isActive, rtc.session.category.rawValue,
                rtc.session.mode.rawValue)
        }

        // Ending system call surfaces must not depend on AVAudioSession
        // deactivation succeeding. In particular, CallKit may still own the
        // session briefly and setActive(false) can throw during that handoff.
        // Clear CallKit and PiP first so no stale call UI survives.
        if !callPresent {
          self.callKitController.update(
            callPresent: false,
            callId: callId,
            outgoing: outgoing,
            phase: phase,
            video: video,
            remoteName: remoteName,
            connectedAt: connectedAt,
            appIsForeground: appForeground
          )
          self.videoPictureInPictureController.update(
            active: false,
            established: false,
            video: video,
            remoteVideoTrackId: ""
          )
          do {
            try self.configureCallAudioSessionIfNeeded(active: false, video: video)
          } catch {
            NSLog("Call audio session deactivation failed: %@", error.localizedDescription)
          }
          result(nil)
          return
        }

        do {
          try self.configureCallAudioSessionIfNeeded(active: active, video: video)
          self.callKitController.update(
            callPresent: callPresent,
            callId: callId,
            outgoing: outgoing,
            phase: phase,
            video: video,
            remoteName: remoteName,
            connectedAt: connectedAt,
            appIsForeground: appForeground
          )
          self.videoPictureInPictureController.update(
            active: callPresent,
            established: phase == "connected",
            video: video,
            remoteVideoTrackId: remoteVideoTrackId,
            localVideoTrackId: localVideoTrackId
          )
          result(nil)
        } catch {
          result(
            FlutterError(
              code: "CALL_AUDIO_SESSION_FAILED",
              message: error.localizedDescription,
              details: nil
            )
          )
        }
      case "enterPictureInPicture":
        result(self.videoPictureInPictureController.start())
      case "showSystemVideoEffects":
        if #available(iOS 15.0, *) {
          AVCaptureDevice.showSystemUserInterface(.videoEffects)
          result(true)
        } else {
          result(false)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let secureChannel = FlutterMethodChannel(
      name: "com.gv.chat/secure_screen",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    secureScreenChannel = secureChannel
    secureChannel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "setSecure":
        let secure = (call.arguments as? [String: Any])?["secure"] as? Bool ?? false
        self?.isSecureEnabled = secure
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    if let pending = self.pendingColdStartNotification {
      pendingColdStartNotification = nil
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
        channel.invokeMethod("onNotificationOpened", arguments: pending)
      }
    }
  }

  /// iOS 无法真正阻止截图/录屏，只能检测后通知 Flutter 端（在私密聊天内提醒）。
  private func registerCaptureObservers() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(didTakeScreenshot),
      name: UIApplication.userDidTakeScreenshotNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(screenCaptureChanged),
      name: UIScreen.capturedDidChangeNotification,
      object: nil
    )
  }

  @objc private func didTakeScreenshot() {
    guard isSecureEnabled else { return }
    secureScreenChannel?.invokeMethod("onCaptureDetected", arguments: ["type": "screenshot"])
  }

  @objc private func screenCaptureChanged() {
    guard isSecureEnabled else { return }
    if UIScreen.main.isCaptured {
      secureScreenChannel?.invokeMethod("onCaptureDetected", arguments: ["type": "recording"])
    }
  }

  private func startLocalNetworkPreflight(_ result: @escaping FlutterResult) {
    guard #available(iOS 14.0, *) else {
      result(nil)
      return
    }

    var completed = false
    func complete(_ value: Any?) {
      guard !completed else { return }
      completed = true
      self.localNetworkBrowser?.cancel()
      self.localNetworkBrowser = nil
      result(value)
    }

    let parameters = NWParameters()
    parameters.includePeerToPeer = true
    let browser = NWBrowser(
      for: .bonjour(type: "_http._tcp", domain: nil),
      using: parameters
    )
    localNetworkBrowser = browser
    browser.stateUpdateHandler = { state in
      switch state {
      case .ready:
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
          complete(nil)
        }
      case .failed(let error):
        complete(
          FlutterError(
            code: "LOCAL_NETWORK_PREFLIGHT_FAILED",
            message: error.localizedDescription,
            details: nil
          )
        )
      case .waiting:
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
          complete(nil)
        }
      default:
        break
      }
    }
    browser.start(queue: .main)
    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
      complete(nil)
    }
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    let hex = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    pushApnsChannel?.invokeMethod("onApnsToken", arguments: hex)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    pushApnsChannel?.invokeMethod("onApnsRegisterFailed", arguments: error.localizedDescription)
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if response.actionIdentifier != UNNotificationDismissActionIdentifier {
      clearNotificationBadge()
      let userInfo = response.notification.request.content.userInfo
      pushApnsChannel?.invokeMethod(
        "onNotificationOpened",
        arguments: AppDelegate.flattenApnsUserInfo(userInfo)
      )
    }
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }

  private func clearNotificationBadge() {
    UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    if #available(iOS 16.0, *) {
      UNUserNotificationCenter.current().setBadgeCount(0, withCompletionHandler: nil)
    } else {
      UIApplication.shared.applicationIconBadgeNumber = 0
    }
  }

  private func configureCallAudioSessionIfNeeded(active: Bool, video: Bool) throws {
    let rtc = RTCAudioSession.sharedInstance()
    rtc.lockForConfiguration()
    defer { rtc.unlockForConfiguration() }
    // Balance only the activation owned by the app. CallKit/WebRTC manage
    // their own activations; do not deactivate their shared session directly.
    if !active {
      if ownsCallAudioActivation {
        try rtc.setActive(false)
        ownsCallAudioActivation = false
      }
      return
    }
    let session = rtc.session
    let mode: AVAudioSession.Mode = video ? .videoChat : .voiceChat
    // Ringtones and media players share this session. Check actual properties
    // instead of trusting a cached "already active" flag after interruptions.
    if session.category != .playAndRecord || session.mode != mode {
      var options: AVAudioSession.CategoryOptions = [.allowBluetooth, .allowBluetoothA2DP]
      if session.category == .playAndRecord {
        options = session.categoryOptions
      } else if video {
        options.insert(.defaultToSpeaker)
      }
      try rtc.setCategory(.playAndRecord, mode: mode, options: options)
    }
    if !rtc.isActive && !callKitController.hasSystemCall && !ownsCallAudioActivation {
      try rtc.setActive(true)
      ownsCallAudioActivation = true
    }
  }

  private static func flattenApnsUserInfo(_ userInfo: [AnyHashable: Any]) -> [String: String] {
    var out: [String: String] = [:]
    for (k, v) in userInfo {
      guard let key = k as? String else { continue }
      if key == "aps" { continue }
      out[key] = String(describing: v)
    }
    return out
  }
}
