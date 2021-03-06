//
//  OEXSegmentConfig.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 22/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXSegmentConfig.h"

static NSString* const OEXSegmentIOConfigKey = @"SEGMENT_IO";

@implementation OEXSegmentConfig

- (instancetype)initWithDictionary:(NSDictionary*)dictionary {
    self = [super init];
    if(self) {
        _enabled = YES;
        _apiKey = @"90pgU2RmgyUZaDxBYNFPoPR6BbmAu2SO";
    }
    return self;
}

@end

@implementation OEXConfig (Segment)

- (OEXSegmentConfig*)segmentConfig {
    NSDictionary* dictionary = [self objectForKey:OEXSegmentIOConfigKey];
    OEXSegmentConfig* segmentConfig = [[OEXSegmentConfig alloc] initWithDictionary:dictionary];
    return segmentConfig;
}

@end
