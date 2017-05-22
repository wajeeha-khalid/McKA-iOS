//
//  UnitData+CoreDataProperties.h
//  
//
//  Created by Naveen Katari on 18/02/17.
//
//

#import "UnitData+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface UnitData (CoreDataProperties)

+ (NSFetchRequest<UnitData *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *sequential_id;
@property (nullable, nonatomic, copy) NSNumber *isCompleted;
@property (nullable, nonatomic, copy) NSString *chapter_id;

@end

NS_ASSUME_NONNULL_END
