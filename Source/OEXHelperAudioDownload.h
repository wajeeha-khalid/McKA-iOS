//
//  OEXHelperAudioDownload.h
//  edX
//
//  Created by Ravi Kishore on 23/01/17.
//  Copyright © 2017 edX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OEXConstants.h"
#import "OEXDownloadInterface.h"

NS_ASSUME_NONNULL_BEGIN

@class OEXAudioSummary;

extern double const OEXMaxAudioDownloadProgress;

@interface OEXHelperAudioDownload : NSObject <OEXDownloadInterface>

@property (nonatomic, strong, nullable) OEXAudioSummary* summary;

@property (nonatomic, assign) double downloadProgress;
@property (nonatomic, strong, nullable) NSNumber* size;
@property (nonatomic, strong) NSString* filePath;

@property (nonatomic, assign) BOOL isAudioDownloading;  // used to get if the audio downloading is in progress
@property (nonatomic, assign) OEXDownloadState downloadState;
@property (nonatomic, assign) OEXPlayedState watchedState;
@property (nonatomic, strong, nullable) NSDate* completedDate;
@property (nonatomic, assign) NSTimeInterval lastPlayedInterval;

@property (nonatomic, assign) BOOL isSelected;  // Used only while editing.

@property (nonatomic, strong, nullable) NSString* course_url;
@property (nonatomic, strong, nullable) NSString* course_id;
@property (nonatomic, strong, nullable) NSString* chapterName;
@property (nonatomic, strong, nullable) NSString* sectionName;

@end

NS_ASSUME_NONNULL_END
