# GV Chat local patch

Source: `flutter_webrtc 1.6.0` from pub.dev.

Android's `MethodCallHandlerImpl.dispose()` now releases every video renderer
before the Flutter engine detaches. This prevents a buffered
`ImageReaderSurfaceProducer` frame from scheduling a frame after `FlutterJNI`
has detached.

iOS includes `FlutterRTCCallPictureInPictureController`, which connects an
active WebRTC video track to AVKit's video-call Picture in Picture surface by
converting frames for `AVSampleBufferDisplayLayer`.

Upstream tracking:

- https://github.com/flutter-webrtc/flutter-webrtc/issues/2110
- https://github.com/flutter/flutter/issues/174859

Remove the `dependency_overrides.flutter_webrtc` entry only after an upstream
release contains an equivalent renderer cleanup.
