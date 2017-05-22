//
//  OEXHelperOfflineTracker.h
//  edX
//
//  Created by Naveen Katari on 17/02/17.
//  Copyright © 2017 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OEXHelperOfflineTracker : NSObject

@property (nonatomic, strong, nullable) NSString *title;
@property (nonatomic, strong, nullable) NSString *unitID;
@property (nonatomic, strong, nullable) NSString *componentID;
@property (nonatomic, strong, nullable) NSString *courseID;
@property (nonatomic, assign) BOOL isViewed;
@property (nonatomic, assign) BOOL updated;

@end
