//
//  OEXDownloadSummaryInterface.h
//  edX
//
//  Created by Dmitry on 26/04/2017.
//  Copyright © 2017 edX. All rights reserved.
//

#ifndef OEXDownloadSummaryInterface_h
#define OEXDownloadSummaryInterface_h

@protocol OEXDownloadSummaryInterface <NSObject>

- (NSString* _Nullable) url;
- (double) duration;
- (NSNumber* _Nullable) size;
- (NSString* _Nullable) name;

@end

#endif /* OEXDownloadSummaryInterface_h */
