//
//  OEXAudioSummary.h
//  edX
//
//  Created by Ravi Kishore on 18/01/17.
//  Copyright © 2017 edX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OEXDownloadSummaryInterface.h"

NS_ASSUME_NONNULL_BEGIN


@interface OEXAudioSummary : NSObject <OEXDownloadSummaryInterface>

- (id)initWithDictionary:(NSDictionary*)dictionary;

@property (nonatomic, strong, nullable) NSString* audioUrl;     // used to track the Audio URL
@property (nonatomic,strong, nullable) NSString *studentViewUrl;
@property ( nonatomic, assign) BOOL onlyOnWeb;
@property ( nonatomic, assign) BOOL isYoutubeVideo;
@property (nonatomic, assign) double duration;
@property ( nonatomic, copy, nullable) NSNumber* size;   // in bytes
@property ( nonatomic, copy, nullable) NSString* name;
@property (nonatomic, strong, nullable) NSString* audioID;


- (id)initWithDictionary:(NSDictionary*)dictionary studentUrl:(NSString*)studentViewUrl name:(NSString*)name;


@end

NS_ASSUME_NONNULL_END
