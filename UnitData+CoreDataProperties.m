//
//  UnitData+CoreDataProperties.m
//  
//
//  Created by Naveen Katari on 18/02/17.
//
//

#import "UnitData+CoreDataProperties.h"

@implementation UnitData (CoreDataProperties)

+ (NSFetchRequest<UnitData *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"UnitData"];
}

@dynamic sequential_id;
@dynamic isCompleted;
@dynamic chapter_id;

@end
