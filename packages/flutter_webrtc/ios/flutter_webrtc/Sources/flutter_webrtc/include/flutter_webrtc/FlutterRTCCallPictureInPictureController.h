#import <TargetConditionals.h>

#if TARGET_OS_IPHONE

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// iOS 15+ Picture in Picture surface backed by the active WebRTC video track.
///
/// Frames are rendered through AVSampleBufferDisplayLayer, which is the AVKit
/// supported path for video-call PiP content.
API_AVAILABLE(ios(15.0))
@interface FlutterRTCCallPictureInPictureController : NSObject

@property(nonatomic, copy, nullable) dispatch_block_t onRestoreRequested;
@property(nonatomic, copy, nullable) void (^onPictureInPictureChanged)(BOOL active);

- (instancetype)initWithSourceView:(UIView*)sourceView
    NS_SWIFT_NAME(init(sourceView:));

- (void)updateWithActive:(BOOL)active
                   video:(BOOL)video
      remoteVideoTrackId:(nullable NSString*)remoteVideoTrackId
       localVideoTrackId:(nullable NSString*)localVideoTrackId
    NS_SWIFT_NAME(update(active:video:remoteVideoTrackId:localVideoTrackId:));

- (BOOL)startPictureInPicture;
- (void)stopPictureInPicture;
- (void)dispose;

@end

NS_ASSUME_NONNULL_END

#endif
