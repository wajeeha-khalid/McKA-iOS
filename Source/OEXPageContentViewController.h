//
//  OEXPageContentViewController.h
//  edX
//
//  Created by Naveen Katari on 23/12/16.
//  Copyright © 2016 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OEXPageContentViewController : UIViewController

@property NSUInteger pageIndex;
@property (strong, nonatomic) NSString *imageName;
@property (strong, nonatomic) NSString *tutorialText;

@end
