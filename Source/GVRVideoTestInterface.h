//
//  GVRVideoTestInterface.h
//  edX
//
//  Created by Ravi Kishore on 02/01/17.
//  Copyright © 2017 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GVRVideoTestInterface : UIViewController
    
    
@property (nonatomic, strong, nullable) UIView *topView;
@property (nonatomic, strong, nullable) UILabel *topLabel;
    
//player height and width
@property (nonatomic) CGFloat height;
@property (nonatomic) CGFloat width;
    

@end
