//
//  DownloadManager.h
//  edXVideoLocker
//
//  Created by Abhishek Bhagat on 10/11/14.
//  Copyright (c) 2014-2016 edX. All rights reserved.
//

#import "VideoData.h"
#import "AudioData.h"

NS_ASSUME_NONNULL_BEGIN

@protocol OEXDownloadManagerProtocol <NSObject>

@optional
- (void)downloadTaskDidComplete:(NSURLSessionDownloadTask*)task;
- (void)downloadAlreadyInProgress:(NSURLSessionDownloadTask*)task;
- (void)downloadTask:(NSURLSessionDownloadTask*)task didCOmpleteWithError:(NSError*)error;
//-(void)downloadTaskDidComplete:(NSURLSessionDownloadTask *)task tmpLocation:(NSString *)locatoin;
@end

@interface OEXDownloadManager : NSObject
@property(nonatomic, weak, nullable) id <OEXDownloadManagerProtocol>delegate;

+ (OEXDownloadManager*)sharedManager;

#pragma mark Background requests

- (void)downloadVideoForObject:(VideoData*)video withCompletionHandler:(void (^)(NSURLSessionDownloadTask* downloadTask))completionHandler;

//-(void)cancelDownloadForVideo:(VideoData *)video;

- (void)cancelDownloadForVideo:(VideoData*)video completionHandler:(void (^)(BOOL success))completionHandler;
- (void)cancelDownloadForAudio:(AudioData*)audio completionHandler:(void (^)(BOOL success))completionHandler;

//#warning method not implemented
//-(void)pauseAllDownloadsForUser:(NSString *)user completionHandler:(void (^)(void))completionHandler;

- (void)cancelAllDownloadsForUser:(NSString*)user completionHandler:(void (^)(void))completionHandler;
- (void)cancelAllAudioDownloadsForUser:(NSString*)user completionHandler:(void (^)(void))completionHandler; // Added by Ravi on 31Jan'17 for Audio Podcast Download.

- (void)deactivateWithCompletionHandler:(void (^)(void))completionHandler;

- (void)resumePausedDownloads;

- (void)activateDownloadManager;

//Added By Ravi on 30Jan'17 for Audio Podcast download
- (void)downloadAudioForObject:(AudioData*)audio withCompletionHandler:(void (^)(NSURLSessionDownloadTask* downloadTask))completionHandler;

@end

NS_ASSUME_NONNULL_END
