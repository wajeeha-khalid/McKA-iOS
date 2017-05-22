//
//  ComponentData.h
//  edX
//
//  Created by Naveen Katari on 16/02/17.
//  Copyright © 2017 edX. All rights reserved.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface ComponentData : NSManagedObject

@property (nonatomic, retain) NSString* unitID;
@property (nonatomic, retain) NSString* componentID;
@property (nonatomic, retain) NSNumber* isViewed;
@property (nonatomic, retain) NSString* courseID;
@property (nonatomic, retain) NSNumber* synced;

@end

NS_ASSUME_NONNULL_END

