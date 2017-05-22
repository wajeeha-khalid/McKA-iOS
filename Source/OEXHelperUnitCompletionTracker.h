//
//  OEXHelperUnitCompletionTracker.h
//  edX
//
//  Created by Naveen Katari on 18/02/17.
//  Copyright © 2017 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OEXHelperUnitCompletionTracker : NSObject

@property (nonatomic, strong, nullable) NSString *unitID;
@property (nonatomic, strong, nullable) NSString *courseID;
@property (nonatomic, strong, nullable) NSString *chapterID;
@property (nonatomic, assign) BOOL isCompleted;

@end
