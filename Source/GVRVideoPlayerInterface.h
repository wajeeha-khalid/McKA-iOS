//
//  GVRVideoPlayerInterface.h
//  edX
//
//  Created by Ravi Kishore on 27/12/16.
//  Copyright © 2016 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GVRVideoView.h"
#import "OEXHelperVideoDownload.h"
#import "CLVideoPlayer.h"

NS_ASSUME_NONNULL_BEGIN

/// Fires when a vidoes wathched state changes
extern NSString* const OEXVRWatchedStateChangedNotification;


@protocol GVRVideoPlayerInterfaceDelegate <NSObject>

- (void)movieTimedOut;

- (void)videoPlayerTapped:(UIGestureRecognizer*) sender;

@end


@interface GVRVideoPlayerInterface : UIViewController <GVRVideoViewDelegate,CLVideoPlayerControllerDelegate>

@property(nonatomic, weak, nullable) id <GVRVideoPlayerInterfaceDelegate>  delegate;

@property (nonatomic, weak, nullable) UIView* gvrVideoPlayerVideoView;
@property (nonatomic, strong, nullable) GVRVideoView *gvrVideoView;
@property (nonatomic, strong, nullable) UIActivityIndicatorView *activityIndicator;
@property (assign, nonatomic) BOOL fadeInOnLoad;
@property (nonatomic, strong, nullable) CLVideoPlayer* moviePlayerController;
@property(nonatomic) BOOL shouldRotate;
@property (nonatomic) BOOL didFinishLoading;

//player height and width
@property (nonatomic) CGFloat height;
@property (nonatomic) CGFloat width;


- (void)playVideoFor:(OEXHelperVideoDownload*)video;
- (void) displayVRPlayerInStereoMode;
- (void) gvrVideoPlayerShouldRotate;


@end
NS_ASSUME_NONNULL_END
