//
//  GVRTransitionView.h
//  edX
//
//  Created by Suman Roy on 15/02/17.
//  Copyright © 2017 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GVRTransitionCounterView : UIView

- (void) startCountdownFrom: (int)timer withCompletion:( void (^) () )completion;

@end
