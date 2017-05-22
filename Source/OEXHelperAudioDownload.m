//
//  OEXHelperAudioDownload.m
//  edX
//
//  Created by Ravi Kishore on 23/01/17.
//  Copyright © 2017 edX. All rights reserved.
//

#import "OEXHelperAudioDownload.h"
#import "OEXAudioSummary.h"


double const OEXMaxAudioDownloadProgress = 100;

@implementation OEXHelperAudioDownload

- (NSString*)description {
    return [NSString stringWithFormat:@"<%@: %p, audio_id=%@>", [self class], self, self.summary.studentViewUrl];
}

- (OEXDownloadType) type {
	return OEXDownloadTypeAudio;
}

@end
