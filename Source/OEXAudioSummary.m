//
//  OEXAudioSummary.m
//  edX
//
//  Created by Ravi Kishore on 18/01/17.
//  Copyright © 2017 edX. All rights reserved.
//

#import "OEXAudioSummary.h"
#import "edX-Swift.h"


@interface OEXAudioSummary ()

//@property (nonatomic, copy) NSString* audioUrl;       
//@property (nonatomic, copy) NSString* studentViewUrl;
//@property (nonatomic, copy) NSString* name;


@end



@implementation OEXAudioSummary

- (id)initWithDictionary:(NSDictionary*)dictionary {
    self = [super init];
    if(self != nil) {
        NSDictionary* summary = [dictionary objectForKey:@"summary"];
        
        // Data from inside summary dictionary
        NSString *url = [summary objectForKey:@"src"];
        if (url == (NSString *)[NSNull null]) {
            self.audioUrl = @"";
        } else {
            self.audioUrl = url;
        }
        self.duration = [OEXSafeCastAsClass([summary objectForKey:@"duration"], NSNumber) doubleValue];
  }
    
    return self;
}


- (id)initWithDictionary:(NSDictionary*)dictionary studentUrl:(NSString*)studentViewUrl name:(NSString*)name
{
    self = [self initWithDictionary:dictionary];
    if(self != nil) {
        self.studentViewUrl = studentViewUrl;
        self.name = name;
    }
    return self;
}



//- (id)initWithVideoID:(NSString *)videoID name:(NSString *)name encodings:(NSDictionary<NSString*, OEXVideoEncoding *> *)encodings {
//    self = [super init];
//    if(self != nil) {
//        self.name = name;
//        self.videoID = videoID;
//        self.encodings = encodings;
//    }
//    return self;
//}

//- (OEXVideoEncoding*)preferredEncoding {
//    for(NSString* name in [OEXVideoEncoding knownEncodingNames]) {
//        OEXVideoEncoding* encoding = self.encodings[name];
//        if (encoding != nil) {
//            return encoding;
//        }
//    }
//    
//    // Don't have a known encoding, so return default encoding
//    return self.defaultEncoding;
//}

- (BOOL) isYoutubeVideo {
//    for(NSString* name in [OEXVideoEncoding knownEncodingNames]) {
//        OEXVideoEncoding* encoding = self.encodings[name];
//        if (encoding) {
//            if ([[encoding name] isEqualToString:OEXVideoEncodingFallback]) {
//                return NO;
//            }
//            else if ([[encoding name] isEqualToString:OEXVideoEncodingMobileLow]) {
//                return NO;
//            }
//            else if ([[encoding name] isEqualToString:OEXVideoEncodingMobileHigh]) {
//                return NO;
//            }
//        }
//    }
    
    return NO;
}

//- (NSString*)videoURL {
//    return self.preferredEncoding.URL;
//}
//
//- (NSNumber*)size {
//    return self.preferredEncoding.size;
//}


- (NSArray*)displayPath {
    NSMutableArray* result = [[NSMutableArray alloc] init];
//    if(self.chapterPathEntry != nil) {
//        [result addObject:self.chapterPathEntry];
//    }
//    if(self.sectionPathEntry) {
//        [result addObject:self.sectionPathEntry];
//    }
    return result;
}

- (NSString*)description {
    return [NSString stringWithFormat:@"<%@: %p, audio_id=%@>", [self class], self, self.audioID];
}

- (NSString* _Nullable) url {
	return _audioUrl;
}


@end
