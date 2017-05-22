//
//  OEXAudioPlayerInterface.m
//  edX
//
//  Created by Ravi on 22/01/17.
//  Copyright © 2017 edX. All rights reserved.
//

#import "OEXAudioPlayerInterface.h"

#import "edX-Swift.h"
#import "Logger+OEXObjC.h"

#import "OEXHelperVideoDownload.h"
#import "OEXInterface.h"
#import "OEXAppDelegate.h"
#import "OEXMathUtilities.h"
#import "OEXStyles.h"
#import "OEXVideoSummary.h"
#import "NSString+OEXCrypto.h"

#import <Masonry/Masonry.h>

@interface OEXAudioPlayerInterface ()
{
    UILabel* labelTitle;
}
@property(nonatomic, assign) CGRect defaultFrame;
@property(nonatomic) CGFloat lastPlayedTime;
@property(nonatomic, strong) OEXHelperAudioDownload* currentAudio;
//@property(nonatomic, strong) OEXHelperVideoDownload* lastPlayedVideo;
@property(nonatomic, strong) NSURL* currentUrl;
@property(nonatomic, strong) UIImageView* bgImageView;



@end

@implementation OEXAudioPlayerInterface

- (void)viewDidLoad {
    [super viewDidLoad];
    _audioPlayerVideoView = self.view;
    self.fadeInOnLoad = YES;
    APP_DELEGATE.shouldRotate = NO;
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    //Add observer
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(exitFullScreenMode:) name:MPMoviePlayerDidExitFullscreenNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterFullScreenMode:) name:MPMoviePlayerDidEnterFullscreenNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackStateChanged:)
                                                 name:MPMoviePlayerPlaybackStateDidChangeNotification object:_moviePlayerController];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackEnded:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification object:_moviePlayerController];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    
    

    
    //create a player
    self.moviePlayerController = [[CLVideoPlayer alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    self.moviePlayerController.view.alpha = 0.f;
    self.moviePlayerController.delegate = self; //IMPORTANT!
    
    self.bgImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    self.bgImageView.image = [UIImage imageNamed:@"audioPodcast"];
    self.bgImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.moviePlayerController.backgroundView addSubview:self.bgImageView];
    
    //create the controls
    CLVideoPlayerControls* movieControls = [[CLVideoPlayerControls alloc] initWithMoviePlayer:self.moviePlayerController style:CLVideoPlayerControlsStyleDefault];
    [movieControls setBarColor:[UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.9]];
    [movieControls setTimeRemainingDecrements:YES];
    
    // Added by Ravi on 21Feb'17 for setting the Image in BackGround
    UIImageView *tempImageView =  [[UIImageView alloc] initWithFrame:CGRectZero];
    tempImageView.image = [UIImage imageNamed:@"audioPodcast"];
    tempImageView.contentMode = UIViewContentModeScaleAspectFill;
    movieControls.activityBackgroundView = tempImageView;

    
    //assign controls
    [self.moviePlayerController setControls:movieControls];
    _shouldRotate = YES;
    self.moviePlayerController.controls.hidesFullSceenButton = YES;
}

- (void) enableFullscreenAutorotation {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
}


- (void)setViewFromVideoPlayerView:(UIView*)videoPlayerView {
    BOOL wasLoaded = self.isViewLoaded;
    self.view = videoPlayerView;
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

- (void)setVideoPlayerVideoView:(UIView*)audioPlayerVideoView {
    _audioPlayerVideoView = audioPlayerVideoView;
    [self setViewFromVideoPlayerView:_audioPlayerVideoView];
}

- (void)playAudioFor:(OEXHelperAudioDownload*)audio
{
    _currentAudio = audio;

    _moviePlayerController.videoTitle = audio.summary.name;
   // _moviePlayerController.controls.video = video;
    NSURL* url = [NSURL URLWithString:audio.summary.audioUrl];
    
   NSFileManager* filemgr = [NSFileManager defaultManager];
    
    if([audio.filePath length] == 0)
    {
        
        NSString *filePath = [[NSUserDefaults standardUserDefaults]
                                stringForKey:@"audioFilePath"];
        
        audio.filePath = filePath;
    }
    NSMutableString * reqPath= [NSMutableString stringWithString:[audio.filePath stringByDeletingLastPathComponent]];
    [reqPath appendString:@"/"];
    
    
    
    NSArray *dirFiles = [filemgr contentsOfDirectoryAtURL:[NSURL fileURLWithPath:reqPath] includingPropertiesForKeys:[NSArray array] options:0 error:nil];
    NSArray *filteredFiles = [dirFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self.absoluteString ENDSWITH '.mp3'"]];
    
    
    NSString* path = @"";
    
    if([self.reqAudioString length] > 0)
    {
        NSString * str = [self.reqAudioString.oex_md5 stringByAppendingString:@".mp3"];
        [reqPath appendString:str];
    }
    else
    {
        NSString * str = [audio.summary.audioUrl.oex_md5 stringByAppendingString:@".mp3"];
        [reqPath appendString:str];
    }
    
    
    
    
    for(int i = 0;i<[filteredFiles count]; i++ )
    {
        NSURL *tempPath = [filteredFiles objectAtIndex:i];
        
        NSString *temp1 = [[tempPath absoluteString] lastPathComponent];
        NSString *temp2 = [reqPath lastPathComponent];
        
        if([temp1 isEqualToString:temp2])
        {
            path = reqPath;
        }
        
        
    }
    if([filemgr fileExistsAtPath:path]) {
        url = [NSURL fileURLWithPath:path];
    }
    
    if(audio.downloadState == OEXDownloadStateComplete && ![filemgr fileExistsAtPath:path]) {
        return;
    }
    
    float timeinterval = 0.0;//[[OEXInterface sharedInterface] lastPlayedIntervalForVideo:video];
    [self playVideoFromURL:url withTitle:nil timeInterval:timeinterval];
    
}

- (void)playVideoFromURL:(NSURL*)URL withTitle:(NSString*)title timeInterval:(NSTimeInterval)interval;
{
    if(!URL) {
        return;
    }
    
    self.view = _audioPlayerVideoView;
    [self setViewFromVideoPlayerView:_audioPlayerVideoView];
    
    _moviePlayerController.videoTitle = title;
    [_moviePlayerController.view setBackgroundColor:[UIColor blackColor]];
    [_moviePlayerController setContentURL:URL];
    [_moviePlayerController prepareToPlay];
    [_moviePlayerController setAutoPlaying:NO];
    _moviePlayerController.lastPlayedTime = interval;
    [_moviePlayerController play];
    
    float speed = [OEXInterface getOEXVideoSpeed:[OEXInterface getCCSelectedPlaybackSpeed]];
    
    _moviePlayerController.controls.playbackRate = speed;
    [_moviePlayerController setCurrentPlaybackRate:speed];
    if(!_moviePlayerController.isFullscreen) {
        [_moviePlayerController.view setFrame:_audioPlayerVideoView.bounds];
        [self.view addSubview:_moviePlayerController.view];
    }
    
    if(self.fadeInOnLoad) {
        self.moviePlayerController.view.alpha = 0.0f;
        double delayInSeconds = 0.3;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [UIView animateWithDuration:1.0 animations:^{
                self.moviePlayerController.view.alpha = 1.f;
            }];
        });
    }
    else {
        self.moviePlayerController.view.alpha = 1;
    }
}

- (void)setAutoPlaying:(BOOL)playing {
    [self.moviePlayerController setAutoPlaying:playing];
}


#pragma mark video player delegate

- (void)movieTimedOut {
    [self.delegate movieTimedOut];
}

- (void)movieWatched {
    if ( _moviePlayerController.currentPlaybackTime > _moviePlayerController.duration * 0.9) {

        // Mark the video as watched
        self.currentAudio.watchedState = OEXPlayedStateWatched;
        [[OEXInterface sharedInterface] markAudioState:OEXPlayedStateWatched forAudio:self.currentAudio];
        self.currentAudio.watchedState = OEXPlayedStateWatched;

        NSString *blockId = self.currentAudio.summary.studentViewUrl;
        if (blockId != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:OEXVRWatchedStateChangedNotification object:nil userInfo:@{ @"blockId": blockId}];
            });
        }
        
    }
}

#pragma mark notification methods

- (void)playbackStateChanged:(NSNotification*)notification {
    switch([_moviePlayerController playbackState])
    {
        case MPMoviePlaybackStateStopped:
            OEXLogInfo(@"VIDEO", @"Stopped");
            // Calclulate end of movie id seen more than 90%
            if (_moviePlayerController.currentPlaybackTime > _moviePlayerController.duration * 0.9) {

                // Mark the video as watched
                self.currentAudio.watchedState = OEXPlayedStateWatched;
                [[OEXInterface sharedInterface] markAudioState:OEXPlayedStateWatched forAudio:self.currentAudio];
                self.currentAudio.watchedState = OEXPlayedStateWatched;

                NSString *blockId = self.currentAudio.summary.studentViewUrl;
                if (blockId != nil) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:OEXVRWatchedStateChangedNotification object:nil userInfo:@{ @"blockId": blockId}];
                    });
                }
            }
            break;
        case MPMoviePlaybackStatePlaying:
            OEXLogInfo(@"VIDEO", @"Playing");
            break;
        case MPMoviePlaybackStatePaused:
            OEXLogInfo(@"VIDEO", @"Paused");
            if (_moviePlayerController.currentPlaybackTime > _moviePlayerController.duration * 0.9) {

                // Mark the video as watched
                self.currentAudio.watchedState = OEXPlayedStateWatched;
                [[OEXInterface sharedInterface] markAudioState:OEXPlayedStateWatched forAudio:self.currentAudio];
                self.currentAudio.watchedState = OEXPlayedStateWatched;

                NSString *blockId = self.currentAudio.summary.studentViewUrl;
                if (blockId != nil) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:OEXVRWatchedStateChangedNotification object:nil userInfo:@{ @"blockId": blockId}];
                    });
                }

            }
            break;
        case MPMoviePlaybackStateInterrupted:
            OEXLogInfo(@"VIDEO", @"Interrupted");
            break;
        case MPMoviePlaybackStateSeekingForward:
            OEXLogInfo(@"VIDEO", @"Seeking Forward");
            break;
        case MPMoviePlaybackStateSeekingBackward:
            OEXLogInfo(@"VIDEO", @"Seeking Backward");
            break;
    }
}

- (void)playbackEnded:(NSNotification*)notification {
    int reason = [[[notification userInfo] valueForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    if(reason == MPMovieFinishReasonPlaybackEnded) {
        //NSLog(@"Reason: movie finished playing");

        // Mark the video as watched
        self.currentAudio.watchedState = OEXPlayedStateWatched;
        [[OEXInterface sharedInterface] markAudioState:OEXPlayedStateWatched forAudio:self.currentAudio];
        self.currentAudio.watchedState = OEXPlayedStateWatched;

        NSString *blockId = self.currentAudio.summary.studentViewUrl;
        if (blockId != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:OEXVRWatchedStateChangedNotification object:nil userInfo:@{ @"blockId": blockId}];
            });
        }

    }
    else if(reason == MPMovieFinishReasonUserExited) {
        //NSLog(@"Reason: user hit done button");
    }
    else if(reason == MPMovieFinishReasonPlaybackError) {
        //NSLog(@"Reason: error --> VideoPlayerInterface.m");
        [self.moviePlayerController.view removeFromSuperview];
    }
}

- (void)willResignActive:(NSNotification*)notification {
    [self.moviePlayerController.controls hideOptionsAndValues];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    APP_DELEGATE.shouldRotate = NO;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [_moviePlayerController setShouldAutoplay:NO];
    
    // There appears to be an OS bug on iOS 8
    // where if you don't call "stop" before a movie player view disappears
    // it can cause a crash
    // See http://stackoverflow.com/questions/31188035/overreleased-mpmovieplayercontroller-under-arc-in-ios-sdk-8-4-on-ipad
    if([UIDevice isOSVersionAtLeast9]) {
        [_moviePlayerController pause];
    }
    else {
        [_moviePlayerController stop];
    }
    _shouldRotate = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //[_moviePlayerController setShouldAutoplay:YES];
    _shouldRotate = YES;
}

 //Added by Ravi on 13Feb2017 to stop autoplay
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
     [_moviePlayerController setShouldAutoplay:NO];
}



- (void)videoPlayerShouldRotate {
    [_moviePlayerController setShouldAutoplay:NO];
    _shouldRotate = YES;
}

- (void)orientationChanged:(NSNotification*)notification {
    if(_shouldRotate) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(manageOrientation) object:nil];
        
        if(![self isVerticallyCompact]) {
            [self manageOrientation];
        }
        else {
            [self performSelector:@selector(manageOrientation) withObject:nil afterDelay:0.8];
        }
    }
}

- (void)manageOrientation {
    if(!((self.moviePlayerController.playbackState == MPMoviePlaybackStatePlaying) || self.moviePlayerController.playbackState == MPMoviePlaybackStatePaused ) && !_moviePlayerController.isFullscreen) {
        return;
    }
    
    UIInterfaceOrientation deviceOrientation = [self currentOrientation];
    
    if(deviceOrientation == UIInterfaceOrientationPortrait) {      // PORTRAIT MODE
        if(self.moviePlayerController.fullscreen) {
            [_moviePlayerController setFullscreen:NO withOrientation:UIInterfaceOrientationPortrait];
            _moviePlayerController.controlStyle = MPMovieControlStyleNone;
            [_moviePlayerController.controls setStyle:CLVideoPlayerControlsStyleEmbedded];
        }
    }   //LANDSCAPE MODE
    else if(deviceOrientation == UIDeviceOrientationLandscapeLeft || deviceOrientation == UIInterfaceOrientationLandscapeRight) {
        [_moviePlayerController setFullscreen:YES withOrientation:deviceOrientation animated:YES forceRotate:YES];
        _moviePlayerController.controlStyle = MPMovieControlStyleNone;
        [_moviePlayerController.controls setStyle:CLVideoPlayerControlsStyleFullscreen];
    }
    
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)exitFullScreenMode:(NSNotification*)notification {
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)enterFullScreenMode:(NSNotification*)notification {
    [self setNeedsStatusBarAppearanceUpdate];
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
    
    [self.bgImageView setFrame:self.defaultFrame];
    [self.bgImageView setContentMode:UIViewContentModeScaleAspectFill];
    self.bgImageView.clipsToBounds = true;
    //only manage the movie player frame when it's not in fullscreen. when in fullscreen, the frame is automatically managed
    
    if(self.moviePlayerController.isFullscreen) {
        return;
    }
    
    //you MUST use [CLMoviePlayerController setFrame:] to adjust frame, NOT [CLMoviePlayerController.view setFrame:]
    [self.moviePlayerController setFrame:self.defaultFrame];
}

- (void)moviePlayerWillMoveFromWindow {
    //movie player must be readded to this view upon exiting fullscreen mode.
    
    if(![self.view.subviews containsObject:self.moviePlayerController.view]) {
        [self.view addSubview:self.moviePlayerController.view];
    }
    
    //you MUST use [CLMoviePlayerController setFrame:] to adjust frame, NOT [CLMoviePlayerController.view setFrame:]
    //NSLog(@"set frame from  player delegate ");
    [self.moviePlayerController setFrame:self.defaultFrame];
}

- (void) audioPlayerTapped:(UIGestureRecognizer *) sender {
    if([self.delegate respondsToSelector:@selector(audioPlayerTapped:)]) {
        [self.delegate audioPlayerTapped:sender];
    }
}

- (BOOL)prefersStatusBarHidden {
    return [self.moviePlayerController isFullscreen];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [OEXStyles sharedStyles].standardStatusBarStyle;
}

- (BOOL)hidesNextPrev {
    return self.moviePlayerController.controls.hidesNextPrev;
}

- (void)setHidesNextPrev:(BOOL)hidesNextPrev {
    [self.moviePlayerController.controls setHidesNextPrev:hidesNextPrev];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    _moviePlayerController.delegate = nil;
}


@end
