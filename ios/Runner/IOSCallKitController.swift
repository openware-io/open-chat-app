import AVFoundation
import CallKit
import Foundation
import WebRTC

/// Mirrors outgoing/accepted calls into CallKit for background call controls.
/// Pending incoming calls use JPush plus Flutter's answer UI, not CallKit.
/// This is a User Notifications flow, not a PushKit VoIP push handler.
final class IOSCallKitController: NSObject, CXProviderDelegate {
  var onHangUp: (() -> Void)?

  private let provider: CXProvider
  private let callController = CXCallController()
  private var uuid: UUID?
  private var currentCallId = ""
  private var currentPhase = "idle"
  private var currentVideo = false
  private var currentConnectedAt: Date?
  var hasSystemCall: Bool { uuid != nil }

  override init() {
    let appName = (Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
      ?? (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String)
      ?? "GV Chat"
    let configuration = CXProviderConfiguration(localizedName: appName)
    configuration.maximumCallGroups = 1
    configuration.maximumCallsPerCallGroup = 1
    configuration.supportedHandleTypes = [.generic]
    configuration.supportsVideo = true
    configuration.includesCallsInRecents = false
    provider = CXProvider(configuration: configuration)
    super.init()
    provider.setDelegate(self, queue: .main)
  }

  func update(
    callPresent: Bool,
    callId: String,
    outgoing: Bool,
    phase: String,
    video: Bool,
    remoteName: String,
    connectedAt: Date?,
    appIsForeground: Bool
  ) {
    dispatchPrecondition(condition: .onQueue(.main))

    guard callPresent else {
      endCurrentCall()
      return
    }

    let resolvedCallId = callId.isEmpty ? "current-call" : callId
    currentVideo = video
    currentConnectedAt = connectedAt

    // Notification taps can arrive before Flutter reports foreground=true.
    // Never register an unanswered incoming call, regardless of lifecycle:
    // otherwise the notification tap creates a second, system answer UI.
    // Register accepted calls while still in the foreground. Waiting until
    // Home causes an audio-session ownership change at the suspension boundary.
    let awaitingAppAnswer = !outgoing && phase == "incoming"
    if awaitingAppAnswer {
      if uuid != nil {
        endCurrentCall()
      }
      currentCallId = resolvedCallId
      currentPhase = phase
      return
    }

    let previousPhase = currentPhase
    var createdSystemCall = false
    if currentCallId != resolvedCallId || uuid == nil {
      if uuid != nil {
        endCurrentCall()
      }
      currentCallId = resolvedCallId
      let newUUID = UUID()
      uuid = newUUID
      createdSystemCall = true
      NSLog("[CallAudio] register system controls phase=%@ foreground=%d", phase, appIsForeground)
      let update = makeUpdate(video: video, remoteName: remoteName)
      let action = CXStartCallAction(
        call: newUUID,
        handle: update.remoteHandle ?? CXHandle(type: .generic, value: remoteName)
      )
      action.isVideo = video
      request(CXTransaction(action: action))
      provider.reportCall(with: newUUID, updated: update)
    } else if let uuid {
      provider.reportCall(with: uuid, updated: makeUpdate(video: video, remoteName: remoteName))
    }

    if phase == "connected",
       !createdSystemCall,
       previousPhase != "connected",
       let uuid {
      provider.reportOutgoingCall(with: uuid, connectedAt: connectedAt ?? Date())
    }
    currentPhase = phase
  }

  private func makeUpdate(video: Bool, remoteName: String) -> CXCallUpdate {
    let update = CXCallUpdate()
    let name = remoteName.trimmingCharacters(in: .whitespacesAndNewlines)
    update.localizedCallerName = name.isEmpty ? "通话中" : name
    update.remoteHandle = CXHandle(type: .generic, value: name.isEmpty ? "GV Chat" : name)
    update.hasVideo = video
    update.supportsDTMF = false
    update.supportsHolding = false
    update.supportsGrouping = false
    update.supportsUngrouping = false
    return update
  }

  private func request(_ transaction: CXTransaction) {
    callController.request(transaction) { error in
      if let error {
        NSLog("CallKit transaction failed: %@", error.localizedDescription)
      }
    }
  }

  private func endCurrentCall() {
    guard let uuid else {
      resetState()
      return
    }
    provider.reportCall(with: uuid, endedAt: Date(), reason: .remoteEnded)
    resetState()
  }

  private func resetState() {
    uuid = nil
    currentCallId = ""
    currentPhase = "idle"
    currentVideo = false
    currentConnectedAt = nil
  }

  func providerDidReset(_ provider: CXProvider) {
    resetState()
  }

  func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
    guard action.callUUID == uuid else {
      action.fail()
      return
    }
    let rtc = RTCAudioSession.sharedInstance()
    rtc.lockForConfiguration()
    do {
      let mode: AVAudioSession.Mode = currentVideo ? .videoChat : .voiceChat
      var options: AVAudioSession.CategoryOptions = [.allowBluetooth, .allowBluetoothA2DP]
      if rtc.session.category == .playAndRecord {
        options = rtc.session.categoryOptions
      } else if currentVideo {
        options.insert(.defaultToSpeaker)
      }
      try rtc.setCategory(.playAndRecord, mode: mode, options: options)
      rtc.unlockForConfiguration()
    } catch {
      rtc.unlockForConfiguration()
      NSLog("[CallAudio] start configuration failed: %@", error.localizedDescription)
      action.fail()
      return
    }
    provider.reportOutgoingCall(with: action.callUUID, startedConnectingAt: Date())
    action.fulfill()
    if currentPhase == "connected" {
      provider.reportOutgoingCall(with: action.callUUID, connectedAt: currentConnectedAt ?? Date())
    }
  }

  func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
    guard action.callUUID == uuid else {
      action.fail()
      return
    }
    resetState()
    action.fulfill()
    onHangUp?()
  }

  func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
    // Clears WebRTC's interrupted flag when CallKit activates the session.
    // A CallKit interruption does not always produce a matching ended event.
    let rtc = RTCAudioSession.sharedInstance()
    rtc.audioSessionDidActivate(audioSession)
    rtc.isAudioEnabled = true
    NSLog("[CallAudio] CallKit activated category=%@ mode=%@ rate=%.0f",
          audioSession.category.rawValue, audioSession.mode.rawValue, audioSession.sampleRate)
  }

  func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
    RTCAudioSession.sharedInstance().audioSessionDidDeactivate(audioSession)
    NSLog("[CallAudio] CallKit deactivated")
  }
}
