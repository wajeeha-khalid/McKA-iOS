//
//  OEXDownloadInterface.h
//  edX
//
//  Created by Dmitry on 26/04/2017.
//  Copyright © 2017 edX. All rights reserved.
//

#ifndef OEXDownloadInterface_h
#define OEXDownloadInterface_h

typedef NS_ENUM(NSInteger, OEXDownloadType) {
	OEXDownloadTypeAudio,
	OEXDownloadTypeVideo,
};

#import "OEXDownloadSummaryInterface.h"

@protocol OEXDownloadInterface <NSObject>

@property (nonatomic, assign) double downloadProgress;
@property (nonatomic, assign) OEXDownloadState downloadState;
@property (nonatomic, strong, nullable) NSNumber* size;

- (id<OEXDownloadSummaryInterface> _Nullable) summary;
- (OEXDownloadType) type;

@end

#endif /* OEXDownloadInterface_h */
