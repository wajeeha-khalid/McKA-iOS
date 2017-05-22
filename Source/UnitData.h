//
//  UnitData.h
//  edX
//
//  Created by Naveen Katari on 18/02/17.
//  Copyright © 2017 edX. All rights reserved.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface UnitData : NSManagedObject

@property (nonatomic, retain) NSString* courseID;
@property (nonatomic, retain) NSString* unitID;
@property (nonatomic, retain) NSNumber* isCompleted;
@property (nonatomic, retain) NSString* chapterID;

@end

NS_ASSUME_NONNULL_END
