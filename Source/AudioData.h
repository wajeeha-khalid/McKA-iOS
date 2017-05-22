//
//  AudioData.h
//  edX
//
//  Created by Ravi Kishore on 30/01/17.
//  Copyright © 2017 edX. All rights reserved.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface AudioData : NSManagedObject

@property (nonatomic, retain) NSNumber* download_state;
@property (nonatomic, retain) NSDate* downloadCompleteDate;
@property (nonatomic, retain) NSString* duration;
@property (nonatomic, retain) NSString* filePath;
@property (nonatomic, retain) NSString* size;
@property (nonatomic, retain) NSString* title;
@property (nonatomic, retain) NSString* audio_id;
@property (nonatomic, retain) NSString* audio_url;
@property (nonatomic, retain) NSString* chapter_name;
@property (nonatomic, retain) NSNumber* played_state;
@property (nonatomic, retain) NSString* section_name;
@property (nonatomic, retain) NSString* course_id;



@end

NS_ASSUME_NONNULL_END
