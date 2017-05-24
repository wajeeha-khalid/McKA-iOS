//
//  GVRVideoPlayerInterface.m
//  edX
//
//  Created by Ravi Kishore on 27/12/16.
//  Copyright © 2016 edX. All rights reserved.
//

#import "GVRVideoPlayerInterface.h"
#import <AVFoundation/AVFoundation.h>
#import "OEXHelperVideoDownload.h"
#import "OEXVideoSummary.h"
#import "OEXInterface.h"
#import "OEXAppDelegate.h"
#import "edX-Swift.h"
#import "Logger+OEXObjC.h"
#import "OEXMathUtilities.h"
#import <Masonry/Masonry.h>


NSString* const OEXVRWatchedStateChangedNotification = @"OEXVRWatchedStateChangedNotification";

typedef NS_ENUM(NSInteger, OEXVRPlayState){
    Playing,
    Paused
};

@interface GVRVideoPlayerInterface ()

@property(nonatomic, strong) OEXHelperVideoDownload* currentVideo;
@property(nonatomic, assign) CGRect defaultFrame;
@property(nonatomic) CGFloat lastPlayedTime;
@property(nonatomic, strong) UIButton *playPauseButton;
@property(nonatomic, assign) BOOL isFirstVideoLoad;
@property(nonatomic, strong) UIView *seekBarView;
@property(nonatomic, strong) UISlider *sliderView;
@property(nonatomic, strong) UILabel *playTimeLabel;
@property(nonatomic, strong) NSString *videoDurationText;
@property (nonatomic) OEXVRPlayState vrPlayerState;

@property (nonatomic, strong)NSTimer *controlHideTimer;

@end

@implementation GVRVideoPlayerInterface
{
    BOOL _isPaused;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    APP_DELEGATE.shouldRotate = NO;
    _gvrVideoPlayerVideoView = self.view;
    self.fadeInOnLoad = YES;
    self.isFirstVideoLoad = NO;
    self.didFinishLoading = false;
    //Add observer
    
    //create a Google VR Video View
    [self loadGVRVideoView];
    
    //create a Seekbar View
    self.seekBarView = [[UIView alloc] initWithFrame:CGRectZero];
    self.seekBarView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7f];;
    self.seekBarView.opaque = NO;
    [self.gvrVideoView addSubview:self.seekBarView];
    [ self.gvrVideoView bringSubviewToFront:self.seekBarView ];
    
    //create a Slider View
    self.sliderView = [[UISlider alloc] initWithFrame:CGRectZero];
    [self.sliderView setBackgroundColor:[UIColor clearColor]];
    [self.seekBarView addSubview:self.sliderView];
    [ self.seekBarView bringSubviewToFront:self.sliderView ];

    [ self.sliderView addTarget:self action:@selector(setVideoSeek) forControlEvents:UIControlEventValueChanged ];
    
    //create a Label to show Playtime
    self.playTimeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [self.playTimeLabel setText:@"00:00"];
    [self.playTimeLabel setTextColor:[UIColor whiteColor]];
    [self.playTimeLabel setFont:[UIFont fontWithName:@"American Typewriter" size:12.0]];
    [self.sliderView addSubview:self.playTimeLabel];
    
    self.playPauseButton = [[ UIButton alloc ] init ];
    [ self.playPauseButton setImage: [UIImage imageNamed:@"play_icon"] forState: UIControlStateNormal ];
    [ self.gvrVideoView addSubview:self.playPauseButton ];
    [ self.gvrVideoView bringSubviewToFront:self.playPauseButton ];
    [ self.playPauseButton addTarget:self action:@selector(playPauseVideo) forControlEvents:UIControlEventTouchUpInside ];
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(self.gvrVideoView.frame.size.width/2, self.gvrVideoView.frame.size.height/3,50, 40)];
    self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    [self.gvrVideoView addSubview:self.activityIndicator];
    [ self.gvrVideoView insertSubview:self.activityIndicator aboveSubview:self.playPauseButton ];
    
    self.vrPlayerState = Paused;
    
    // Initally dont show untill video is loaded.
    // [ self.seekBarView  setHidden:YES ];
    

    //Added by Ravi on 24Feb'17 for Scrolling smoothly
    [self.activityIndicator startAnimating];
    [self.view setBackgroundColor:[UIColor blackColor]];
    [self.gvrVideoView setFrame:_gvrVideoPlayerVideoView.bounds];
    [self.view addSubview:self.gvrVideoView];
    [self hideControls];
}

- (void) setVrPlayerState:(OEXVRPlayState)vrPlayerState {
    
    switch (vrPlayerState) {
        case Playing:
            [ self hideControls ];
              [ self.playPauseButton setImage:[ UIImage imageNamed:@"pause_icon" ] forState:UIControlStateNormal ];
            [ self.gvrVideoView play ];
            _isPaused = false;
            _vrPlayerState = Playing;
            break;
        case Paused:
            [ self showControls ];
             [ self.playPauseButton setImage:[ UIImage imageNamed:@"play_icon" ] forState:UIControlStateNormal ];
            [ self.gvrVideoView pause ];
            _isPaused = true;
            _vrPlayerState = Paused;
            break;
    }
    
}

- (void)loadGVRVideoView {
    if(!self.gvrVideoView)
    {
        //create a Google VR Video View
        self.gvrVideoView = [[GVRVideoView alloc] initWithFrame:CGRectMake(0.0,0.0, self.view.frame.size.width,self.view.frame.size.height)];
        self.gvrVideoView.delegate = self; //IMPORTANT!
        self.gvrVideoView.enableInfoButton = false;
        self.gvrVideoView.enableFullscreenButton = true;
        self.gvrVideoView.enableCardboardButton = false;
        self.gvrVideoView.enableTouchTracking = true;
        self.gvrVideoView.hidesTransitionView = true;
        self.gvrVideoView.displayMode = kGVRWidgetDisplayModeEmbedded;
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)displayVRPlayerInStereoMode {
    self.gvrVideoView.displayMode = kGVRWidgetDisplayModeFullscreenVR;
}

- (void)setGvrVideoPlayerVideoView:(UIView*)gvrVideoPlayerVideoView {
    _gvrVideoPlayerVideoView = gvrVideoPlayerVideoView;
    [self setViewFromGVRVideoPlayerView:_gvrVideoPlayerVideoView];
}

- (void)playVideoFor:(OEXHelperVideoDownload*)video {

    NSURL* url = [NSURL URLWithString:video.summary.videoURL ];
    
    NSFileManager* filemgr = [NSFileManager defaultManager];
    NSString* path = [video.filePath stringByAppendingPathExtension:@"mp4"];
    
    if([filemgr fileExistsAtPath:path]) {
        url = [NSURL fileURLWithPath:path];
    }
    
    if(video.downloadState == OEXDownloadStateComplete && ![filemgr fileExistsAtPath:path]) {
        return;
    }
    
    self.currentVideo = video;
    
    float timeinterval = [[OEXInterface sharedInterface] lastPlayedIntervalForVideo:video];
    [self playVideoFromURL:url withTitle:video.summary.name timeInterval:timeinterval];
}

- (void)playVideoFromURL:(NSURL*)URL withTitle:(NSString*)title timeInterval:(NSTimeInterval)interval {
    if(!URL) {
        return;
    }
    self.view = _gvrVideoPlayerVideoView;
    [self setGvrVideoPlayerVideoView:_gvrVideoPlayerVideoView];
    [self.gvrVideoView loadFromUrl:URL ofType:kGVRVideoTypeMono];
    //Getting total Playtime from URL
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void) {

            AVURLAsset *sourceAsset = [AVURLAsset URLAssetWithURL:URL options:nil];
             CMTime duration = sourceAsset.duration;

        
        NSUInteger durationSeconds = (long)CMTimeGetSeconds(duration);
        NSUInteger dHours = floor(durationSeconds / 3600);
        NSUInteger dMinutes = floor(durationSeconds % 3600 / 60);
        NSUInteger dSeconds = floor(durationSeconds % 3600 % 60);

		dispatch_async(dispatch_get_main_queue(), ^{
			self.sliderView.minimumValue = 0.0;
			self.sliderView.maximumValue = durationSeconds;
			// NSString *videoDurationText = @"";
			
			if(dHours > 0)
			{
				self.videoDurationText = [NSString stringWithFormat:@"%lu:%02lu:%02lu",(unsigned long)dHours, (unsigned long)dMinutes, (unsigned long)dSeconds];
			}
			else
			{
				self.videoDurationText = [NSString stringWithFormat:@"%02lu:%02lu",(unsigned long)dMinutes, (unsigned long)dSeconds];
			}
		});
        
    });
    
}

- (void)setViewFromGVRVideoPlayerView:(UIView*)gvrVideoPlayerView {
    BOOL wasLoaded = self.isViewLoaded;
    self.view = gvrVideoPlayerView;
    if(!wasLoaded) {
        // Call this manually since if we set self.view ourselves it doesn't ever get called.
        // This whole thing should get factored so that we just always use our own view
        // And owners can add it where they choose and the whole thing goes through the natural
        // view controller APIs
        [self viewDidLoad];
        [self beginAppearanceTransition:true animated:true];
        [self endAppearanceTransition];
    }
    
}


#pragma mark - GVRVideoViewDelegate

- (void)widgetViewDidTap:(GVRWidgetView *)widgetView {
    
    switch (self.vrPlayerState) {
       
        case Playing:
            if ( self.seekBarView.hidden ) {
                [ self temporarilyShowControls ];
            } else {
                
                if ( [ self.controlHideTimer isValid ] ) {
                    [ self.controlHideTimer invalidate ];
                    [ self hideControls ];
                }
            }
            break;
        case Paused :
            if ( self.seekBarView.hidden ) {
                [ self showControls ];
            } else {
                [ self hideControls ];
            }
        default:
            break;
    }
    
}

- (void)widgetView:(GVRWidgetView *)widgetView didLoadContent:(id)content {
    NSLog(@"Finished loading video");
    self.didFinishLoading = true;
    [self.activityIndicator stopAnimating];
    self.vrPlayerState = Paused;
}

- (void)widgetView:(GVRWidgetView *)widgetView didFailToLoadContent:(id)content withErrorMessage:(NSString *)errorMessage {
    NSLog(@"Failed to load video: %@", errorMessage);
    self.didFinishLoading = false;
    self.vrPlayerState = Paused;
    [self.activityIndicator stopAnimating];
    [ self hideControls ];
}

- (void)videoView:(GVRVideoView*)videoView didUpdatePosition:(NSTimeInterval)position {

    NSInteger elapsedTime = (NSInteger)position;
    if(elapsedTime > 0)
    {
        NSInteger seconds = elapsedTime % 60;
        NSInteger minutes = (elapsedTime / 60) % 60;
        NSInteger hours = (elapsedTime / 3600);
        NSString *temp =  [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds];
        
        [self.playTimeLabel setText:temp];
        [self.sliderView setValue:position];
    }
    
    BOOL shouldMarkComplete = [MediaPlaybackDecision shouldMediaPlaybackCompleted:position totalDuration:self.gvrVideoView.duration];
    if (self.currentVideo.watchedState != OEXPlayedStateWatched && shouldMarkComplete) {
        
        // Mark the video as watched
        self.currentVideo.watchedState = OEXPlayedStateWatched;
        [[OEXInterface sharedInterface] markVideoState:OEXPlayedStateWatched
                                              forVideo:self.currentVideo];
        self.currentVideo.watchedState = OEXPlayedStateWatched;

        NSString *blockId = self.currentVideo.summary.videoID;

        if (blockId != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:OEXVRWatchedStateChangedNotification object:nil userInfo:@{ @"blockId": blockId}];
            });
        }
    }
}

// Added by Ravi on 9Mar'17 for status bar displaying in VRMode as well
- (void)widgetView:(GVRWidgetView *)widgetView didChangeDisplayMode:(GVRWidgetDisplayMode)displayMode {
    if(displayMode != kGVRWidgetDisplayModeEmbedded)
    {
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
    }
    else
    {
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
    }
}


#pragma mark video player delegate

- (void)movieTimedOut {
    [self.delegate movieTimedOut];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self.gvrVideoView stop];
    self.gvrVideoView = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [self loadGVRVideoView];
    [super viewWillAppear:animated];
}

- (void)gvrVideoPlayerShouldRotate {
    //[_moviePlayerController setShouldAutoplay:YES];
    _shouldRotate = NO;
}

- (void)viewDidLayoutSubviews {
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        _width = 700.f;
        _height = 535.f;
    }
    else {
        if (!_width)
            _width = self.view.frame.size.width;
        
        if ([self isVerticallyCompact]) {
            if (!_height)
                _height = [[UIScreen mainScreen] bounds].size.height - 84; // height of nav n toolbar
            
        }
        else {
            if (!_height)
                _height = 220;
        }
        
    }
    //calulate the frame on every rotation, so when we're returning from fullscreen mode we'll know where to position the movie player
    self.defaultFrame = CGRectMake(self.view.frame.size.width / 2 - _width / 2, 0, _width, _height);
    
    [ self.playPauseButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.gvrVideoView);
        make.height.equalTo(@50);
        make.width.equalTo(@50);
    }];
    [self.gvrVideoView setFrame:self.defaultFrame];
    self.activityIndicator.center = self.gvrVideoView.center;
    [self.seekBarView setFrame:CGRectMake(0.0,self.gvrVideoView.frame.size.height - 50,self.gvrVideoView.frame.size.width - 50 ,50)];
    //[self.sliderView setFrame:CGRectMake(15.0,10,self.seekBarView.frame.size.width - 120,30)];
    [ self.sliderView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.seekBarView.mas_leading).offset(15);
        make.centerY.equalTo(self.seekBarView.mas_centerY);
        make.trailing.equalTo(self.playTimeLabel.mas_leading).offset(-10);
    }];
    //[self.playTimeLabel setFrame:CGRectMake(self.seekBarView.frame.size.width - 110,10,100,10)];
    [ self.playTimeLabel sizeToFit ];
    [ self.playTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.seekBarView.mas_centerY);
        make.trailing.equalTo(self.seekBarView.mas_trailing).offset(-10);
    }];
}

- (void)moviePlayerWillMoveFromWindow {
    if(![self.view.subviews containsObject:self.moviePlayerController.view]) {
        [self.view addSubview:self.moviePlayerController.view];
    }
    
    [self.gvrVideoView setFrame:self.defaultFrame];
}

- (void) videoPlayerTapped:(UIGestureRecognizer *) sender {
    if([self.delegate respondsToSelector:@selector(videoPlayerTapped:)]) {
        [self.delegate videoPlayerTapped:sender];
    }
}


#pragma mark Video Control Actions

- (void) setVideoSeek {

    [self.gvrVideoView pause];
    double seekVal = [ NSNumber numberWithFloat:self.sliderView.value ].doubleValue;

    NSLog(@"****************Seeking to : %f*******************",seekVal );
    [self.gvrVideoView seekTo: seekVal ];
    [self.gvrVideoView play];
}

- (void) playPauseVideo {
    
    if ( self.vrPlayerState == Paused )
    {
        
        if(self.isFirstVideoLoad == NO)
        {
            self.isFirstVideoLoad = YES;
        }
        
        self.vrPlayerState = Playing;
        
        if (self.currentVideo.watchedState == OEXPlayedStateUnwatched) {
            [[OEXInterface sharedInterface] markVideoState:OEXPlayedStatePartiallyWatched
                                                  forVideo:self.currentVideo];
            self.currentVideo.watchedState = OEXPlayedStatePartiallyWatched;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:OEXVRWatchedStateChangedNotification object:nil];
            });
        }
    }
    else
    {
        
        self.vrPlayerState = Paused;
        
    }
    
}

- (void)temporarilyShowControls {
    
    [ self showControls ];
    
    self.controlHideTimer = [ NSTimer scheduledTimerWithTimeInterval:5.0 target:self
                                                            selector:@selector(hideControls)
                                                            userInfo:nil
                                                             repeats:false ];
}

- (void)hideControls {
    [self.playPauseButton setHidden:YES];
    [self.seekBarView setHidden:YES];
}

- (void)showControls {
    [self.playPauseButton setHidden:NO];
    [self.seekBarView setHidden:NO];
    
}

@end
