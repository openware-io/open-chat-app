import AVKit
import Flutter
import UIKit
import flutter_webrtc

/// A single native PiP pipeline shared with the WebRTC plugin. Its
/// AVSampleBufferDisplayLayer keeps rendering without Flutter/Metal frames.
final class IOSVideoCallPictureInPictureController: NSObject {
  var onModeChanged: ((Bool) -> Void)?
  var onRestore: (() -> Void)?

  private let sourceView = UIView(frame: CGRect(x: 0, y: 0, width: 2, height: 2))
  private var controller: FlutterRTCCallPictureInPictureController?
  private var eligible = false
  private var remoteTrackId = ""
  private var localTrackId = ""
  private var startGeneration = 0

  override init() {
    super.init()
    sourceView.backgroundColor = .clear
    sourceView.isUserInteractionEnabled = false
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(applicationDidEnterBackground),
      name: UIApplication.didEnterBackgroundNotification,
      object: nil
    )
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
    controller?.dispose()
  }

  func update(
    active: Bool,
    established: Bool,
    video: Bool,
    remoteVideoTrackId: String,
    localVideoTrackId: String = ""
  ) {
    dispatchPrecondition(condition: .onQueue(.main))
    eligible = active && established && video
    remoteTrackId = remoteVideoTrackId
    localTrackId = localVideoTrackId
    if !eligible {
      startGeneration += 1
      controller?.update(active: false, video: false,
                         remoteVideoTrackId: nil, localVideoTrackId: nil)
      return
    }
    configureIfNeeded()
    controller?.update(active: true, video: true,
                       remoteVideoTrackId: remoteTrackId, localVideoTrackId: localTrackId)
  }

  private func configureIfNeeded() {
    guard controller == nil, AVPictureInPictureController.isPictureInPictureSupported() else {
      return
    }
    let window = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first(where: \.isKeyWindow)
    guard let window else { return }
    sourceView.frame = CGRect(x: window.bounds.maxX - 2, y: window.bounds.maxY - 2,
                              width: 2, height: 2)
    window.addSubview(sourceView)
    let controller = FlutterRTCCallPictureInPictureController(sourceView: sourceView)
    controller.onPictureInPictureChanged = { [weak self] active in
      NSLog("[CallPiP] active=%d", active)
      self?.onModeChanged?(active)
    }
    controller.onRestoreRequested = { [weak self] in self?.onRestore?() }
    self.controller = controller
  }

  @discardableResult
  func start() -> Bool {
    guard eligible else { return false }
    configureIfNeeded()
    startGeneration += 1
    return attemptStart(generation: startGeneration, attempt: 0)
  }

  private func attemptStart(generation: Int, attempt: Int) -> Bool {
    guard eligible, generation == startGeneration else { return false }
    // Track lookup and AVKit readiness can finish after the lifecycle event.
    controller?.update(active: true, video: true,
                       remoteVideoTrackId: remoteTrackId, localVideoTrackId: localTrackId)
    if controller?.startPictureInPicture() == true { return true }
    guard attempt < 5 else {
      NSLog("[CallPiP] start unavailable after readiness retries")
      return false
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15 * Double(attempt + 1)) {
      [weak self] in
      _ = self?.attemptStart(generation: generation, attempt: attempt + 1)
    }
    return false
  }

  @objc private func applicationDidEnterBackground() {
    _ = start()
  }
}
