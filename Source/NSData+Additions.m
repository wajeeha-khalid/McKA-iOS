//
//  NSData+Additions.m
//  edX
//
//  Created by Konstantinos Angistalis on 12/04/2017.
//  Copyright © 2017 edX. All rights reserved.
//

#import "NSData+Additions.h"

@implementation NSData (Additions)

- (BOOL)isValidJPEG
{
    if (self.length < 2) return NO;
    
    NSInteger totalBytes = self.length;
    const char *bytes = (const char*)[self bytes];
    
    return (bytes[0] == (char)0xff &&
            bytes[1] == (char)0xd8 &&
            bytes[totalBytes-2] == (char)0xff &&
            bytes[totalBytes-1] == (char)0xd9);
}

@end
