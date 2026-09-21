#import <TargetConditionals.h>

#if TARGET_OS_IPHONE

#import "FlutterRTCCallPictureInPictureController.h"

#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <CoreMedia/CoreMedia.h>
#import <WebRTC/RTCYUVHelper.h>
#import <WebRTC/RTCYUVPlanarBuffer.h>
#import <WebRTC/WebRTC.h>

#import "FlutterWebRTCPlugin.h"

@interface FlutterRTCCallPictureInPictureVideoView : UIView <RTCVideoRenderer>

- (void)flush;

@end

@implementation FlutterRTCCallPictureInPictureVideoView {
  dispatch_queue_t _renderQueue;
  BOOL _framePending;
  CVPixelBufferPoolRef _pixelBufferPool;
  int _poolWidth;
  int _poolHeight;
  NSUInteger _renderedFrames;
}

+ (Class)layerClass {
  return [AVSampleBufferDisplayLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _renderQueue = dispatch_queue_create("com.gv.chat.call-pip-render", DISPATCH_QUEUE_SERIAL);
    _framePending = NO;
    _pixelBufferPool = nil;
    _poolWidth = 0;
    _poolHeight = 0;
    AVSampleBufferDisplayLayer* displayLayer = (AVSampleBufferDisplayLayer*)self.layer;
    displayLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    displayLayer.backgroundColor = UIColor.blackColor.CGColor;
  }
  return self;
}

- (void)dealloc {
  if (_pixelBufferPool != nil) {
    CVPixelBufferPoolRelease(_pixelBufferPool);
    _pixelBufferPool = nil;
  }
}

- (id<RTCI420Buffer>)rotatedBufferForFrame:(RTCVideoFrame*)frame {
  id<RTCI420Buffer> source = [frame.buffer toI420];
  if (frame.rotation == RTCVideoRotation_0) {
    return source;
  }

  int width = source.width;
  int height = source.height;
  if (frame.rotation == RTCVideoRotation_90 || frame.rotation == RTCVideoRotation_270) {
    width = source.height;
    height = source.width;
  }
  id<RTCI420Buffer> rotated = [[RTCI420Buffer alloc] initWithWidth:width height:height];
  [RTCYUVHelper I420Rotate:source.dataY
                srcStrideY:source.strideY
                      srcU:source.dataU
                srcStrideU:source.strideU
                      srcV:source.dataV
                srcStrideV:source.strideV
                      dstY:(uint8_t*)rotated.dataY
                dstStrideY:rotated.strideY
                      dstU:(uint8_t*)rotated.dataU
                dstStrideU:rotated.strideU
                      dstV:(uint8_t*)rotated.dataV
                dstStrideV:rotated.strideV
                     width:source.width
                    height:source.height
                      mode:frame.rotation];
  return rotated;
}

- (BOOL)ensurePixelBufferPoolWithWidth:(int)width height:(int)height {
  if (_pixelBufferPool != nil && _poolWidth == width && _poolHeight == height) {
    return YES;
  }
  if (_pixelBufferPool != nil) {
    CVPixelBufferPoolRelease(_pixelBufferPool);
    _pixelBufferPool = nil;
  }

  NSDictionary* attributes = @{
    (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange),
    (id)kCVPixelBufferWidthKey : @(width),
    (id)kCVPixelBufferHeightKey : @(height),
    (id)kCVPixelBufferIOSurfacePropertiesKey : @{},
  };
  CVReturn status = CVPixelBufferPoolCreate(
      kCFAllocatorDefault,
      NULL,
      (__bridge CFDictionaryRef)attributes,
      &_pixelBufferPool);
  if (status != kCVReturnSuccess || _pixelBufferPool == nil) {
    _pixelBufferPool = nil;
    return NO;
  }
  _poolWidth = width;
  _poolHeight = height;
  return YES;
}

- (CMSampleBufferRef)createSampleBufferForFrame:(RTCVideoFrame*)frame
    CF_RETURNS_RETAINED {
  id<RTCI420Buffer> i420 = [self rotatedBufferForFrame:frame];
  if (![self ensurePixelBufferPoolWithWidth:i420.width height:i420.height]) {
    return nil;
  }

  CVPixelBufferRef pixelBuffer = nil;
  CVReturn pixelStatus = CVPixelBufferPoolCreatePixelBuffer(
      kCFAllocatorDefault,
      _pixelBufferPool,
      &pixelBuffer);
  if (pixelStatus != kCVReturnSuccess || pixelBuffer == nil) {
    return nil;
  }

  CVPixelBufferLockBaseAddress(pixelBuffer, 0);
  uint8_t* destinationY = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
  size_t destinationYStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
  uint8_t* destinationUV = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
  size_t destinationUVStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
  [RTCYUVHelper I420ToNV12:i420.dataY
                srcStrideY:i420.strideY
                      srcU:i420.dataU
                srcStrideU:i420.strideU
                      srcV:i420.dataV
                srcStrideV:i420.strideV
                      dstY:destinationY
                dstStrideY:(int)destinationYStride
                     dstUV:destinationUV
               dstStrideUV:(int)destinationUVStride
                     width:i420.width
                    height:i420.height];
  CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

  CMVideoFormatDescriptionRef formatDescription = nil;
  OSStatus formatStatus = CMVideoFormatDescriptionCreateForImageBuffer(
      kCFAllocatorDefault,
      pixelBuffer,
      &formatDescription);
  if (formatStatus != noErr || formatDescription == nil) {
    CVPixelBufferRelease(pixelBuffer);
    return nil;
  }

  CMSampleTimingInfo timing = {
    .duration = kCMTimeInvalid,
    .presentationTimeStamp = CMTimeMake(frame.timeStampNs, 1000000000),
    .decodeTimeStamp = kCMTimeInvalid,
  };
  CMSampleBufferRef sampleBuffer = nil;
  OSStatus sampleStatus = CMSampleBufferCreateReadyWithImageBuffer(
      kCFAllocatorDefault,
      pixelBuffer,
      formatDescription,
      &timing,
      &sampleBuffer);
  CFRelease(formatDescription);
  CVPixelBufferRelease(pixelBuffer);
  if (sampleStatus != noErr || sampleBuffer == nil) {
    return nil;
  }

  CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, YES);
  if (attachments != nil && CFArrayGetCount(attachments) > 0) {
    CFMutableDictionaryRef attachment =
        (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
    CFDictionarySetValue(
        attachment,
        kCMSampleAttachmentKey_DisplayImmediately,
        kCFBooleanTrue);
  }
  return sampleBuffer;
}

- (void)renderFrame:(RTCVideoFrame*)frame {
  if (frame == nil) {
    return;
  }
  @synchronized(self) {
    if (_framePending) {
      return;
    }
    _framePending = YES;
  }

  __weak FlutterRTCCallPictureInPictureVideoView* weakSelf = self;
  dispatch_async(_renderQueue, ^{
    FlutterRTCCallPictureInPictureVideoView* strongSelf = weakSelf;
    if (strongSelf == nil) {
      return;
    }
    CMSampleBufferRef sampleBuffer = [strongSelf createSampleBufferForFrame:frame];
    dispatch_async(dispatch_get_main_queue(), ^{
      FlutterRTCCallPictureInPictureVideoView* mainSelf = weakSelf;
      if (mainSelf != nil && sampleBuffer != nil) {
        AVSampleBufferDisplayLayer* displayLayer =
            (AVSampleBufferDisplayLayer*)mainSelf.layer;
        if (displayLayer.status == AVQueuedSampleBufferRenderingStatusFailed) {
          [displayLayer flush];
        }
        if (displayLayer.readyForMoreMediaData) {
          [displayLayer enqueueSampleBuffer:sampleBuffer];
          mainSelf->_renderedFrames++;
        }
        if (mainSelf->_renderedFrames % 150 == 0 &&
            UIApplication.sharedApplication.applicationState != UIApplicationStateActive) {
          NSLog(@"[CallPiP] background frames delivered=%lu", (unsigned long)mainSelf->_renderedFrames);
        }
      }
      if (sampleBuffer != nil) {
        CFRelease(sampleBuffer);
      }
      if (mainSelf != nil) {
        @synchronized(mainSelf) {
          mainSelf->_framePending = NO;
        }
      }
    });
  });
}

- (void)setSize:(CGSize)size {
  // The display layer derives its dimensions from each CMSampleBuffer.
}

- (void)flush {
  dispatch_async(dispatch_get_main_queue(), ^{
    AVSampleBufferDisplayLayer* displayLayer = (AVSampleBufferDisplayLayer*)self.layer;
    [displayLayer flushAndRemoveImage];
  });
}

@end

@interface FlutterRTCCallPictureInPictureController () <AVPictureInPictureControllerDelegate>
@end

@implementation FlutterRTCCallPictureInPictureController {
  __weak UIView* _sourceView;
  FlutterRTCCallPictureInPictureVideoView* _videoView;
  AVPictureInPictureVideoCallViewController* _contentViewController;
  AVPictureInPictureController* _pictureInPictureController;
  RTCVideoTrack* _videoTrack;
  BOOL _active;
  BOOL _video;
}

- (instancetype)initWithSourceView:(UIView*)sourceView {
  self = [super init];
  if (self) {
    _sourceView = sourceView;
    _active = NO;
    _video = NO;
    [self preparePictureInPictureController];
  }
  return self;
}

- (void)preparePictureInPictureController {
  if (![AVPictureInPictureController isPictureInPictureSupported] || _sourceView == nil) {
    return;
  }
  _videoView = [[FlutterRTCCallPictureInPictureVideoView alloc] initWithFrame:CGRectZero];
  _videoView.translatesAutoresizingMaskIntoConstraints = NO;
  _contentViewController = [[AVPictureInPictureVideoCallViewController alloc] init];
  _contentViewController.preferredContentSize = CGSizeMake(720, 1280);
  _contentViewController.view.backgroundColor = UIColor.blackColor;
  [_contentViewController.view addSubview:_videoView];
  [NSLayoutConstraint activateConstraints:@[
    [_videoView.leadingAnchor constraintEqualToAnchor:_contentViewController.view.leadingAnchor],
    [_videoView.trailingAnchor constraintEqualToAnchor:_contentViewController.view.trailingAnchor],
    [_videoView.topAnchor constraintEqualToAnchor:_contentViewController.view.topAnchor],
    [_videoView.bottomAnchor constraintEqualToAnchor:_contentViewController.view.bottomAnchor],
  ]];

  AVPictureInPictureControllerContentSource* contentSource =
      [[AVPictureInPictureControllerContentSource alloc]
          initWithActiveVideoCallSourceView:_sourceView
                     contentViewController:_contentViewController];
  _pictureInPictureController =
      [[AVPictureInPictureController alloc] initWithContentSource:contentSource];
  _pictureInPictureController.delegate = self;
  _pictureInPictureController.canStartPictureInPictureAutomaticallyFromInline = NO;
}

- (void)updateWithActive:(BOOL)active
                   video:(BOOL)video
      remoteVideoTrackId:(NSString*)remoteVideoTrackId
       localVideoTrackId:(NSString*)localVideoTrackId {
  dispatch_async(dispatch_get_main_queue(), ^{
    self->_active = active;
    self->_video = video;
    self->_pictureInPictureController.canStartPictureInPictureAutomaticallyFromInline =
        active && video;
    [self updateMultitaskingCameraAccessEnabled:active && video];

    if (!active || !video) {
      [self setVideoTrack:nil];
      [self stopPictureInPicture];
      return;
    }

    FlutterWebRTCPlugin* plugin = [FlutterWebRTCPlugin sharedSingleton];
    RTCMediaStreamTrack* candidate = nil;
    if (remoteVideoTrackId.length > 0) {
      candidate = [plugin remoteTrackForId:remoteVideoTrackId];
    }
    if (![candidate isKindOfClass:[RTCVideoTrack class]] && localVideoTrackId.length > 0) {
      candidate = [plugin trackForId:localVideoTrackId peerConnectionId:nil];
    }
    [self setVideoTrack:[candidate isKindOfClass:[RTCVideoTrack class]]
                            ? (RTCVideoTrack*)candidate
                            : nil];
  });
}

- (void)setVideoTrack:(RTCVideoTrack*)videoTrack {
  if (_videoTrack == videoTrack) {
    return;
  }
  if (_videoTrack != nil) {
    [_videoTrack removeRenderer:_videoView];
  }
  _videoTrack = videoTrack;
  [_videoView flush];
  if (_videoTrack != nil) {
    [_videoTrack addRenderer:_videoView];
  }
}

- (void)updateMultitaskingCameraAccessEnabled:(BOOL)enabled {
  FlutterWebRTCPlugin* plugin = [FlutterWebRTCPlugin sharedSingleton];
  RTCCameraVideoCapturer* capturer = plugin.videoCapturer;
  if (capturer == nil) {
    return;
  }
  if (@available(iOS 16.0, *)) {
    AVCaptureSession* captureSession = capturer.captureSession;
    if (captureSession.multitaskingCameraAccessSupported) {
      captureSession.multitaskingCameraAccessEnabled = enabled;
    }
  }
}

- (BOOL)startPictureInPicture {
  if (_pictureInPictureController.isPictureInPictureActive) {
    return YES;
  }
  if (!_active || !_video || _videoTrack == nil || _pictureInPictureController == nil ||
      !_pictureInPictureController.isPictureInPicturePossible) {
    return NO;
  }
  [_pictureInPictureController startPictureInPicture];
  return YES;
}

- (void)stopPictureInPicture {
  if (_pictureInPictureController.isPictureInPictureActive) {
    [_pictureInPictureController stopPictureInPicture];
  }
}

- (void)dispose {
  [self stopPictureInPicture];
  [self setVideoTrack:nil];
  _pictureInPictureController.delegate = nil;
  _pictureInPictureController = nil;
  _contentViewController = nil;
  _videoView = nil;
}

- (void)pictureInPictureControllerDidStartPictureInPicture:
    (AVPictureInPictureController*)pictureInPictureController {
  if (self.onPictureInPictureChanged != nil) {
    self.onPictureInPictureChanged(YES);
  }
}

- (void)pictureInPictureControllerDidStopPictureInPicture:
    (AVPictureInPictureController*)pictureInPictureController {
  if (self.onPictureInPictureChanged != nil) {
    self.onPictureInPictureChanged(NO);
  }
}

- (void)pictureInPictureController:(AVPictureInPictureController*)pictureInPictureController
    failedToStartPictureInPictureWithError:(NSError*)error {
  NSLog(@"GV Chat video call PiP failed: %@", error.localizedDescription);
  if (self.onPictureInPictureChanged != nil) {
    self.onPictureInPictureChanged(NO);
  }
}

- (void)pictureInPictureController:(AVPictureInPictureController*)pictureInPictureController
    restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:
        (void (^)(BOOL restored))completionHandler {
  if (self.onRestoreRequested != nil) {
    self.onRestoreRequested();
  }
  completionHandler(YES);
}

@end

#endif
