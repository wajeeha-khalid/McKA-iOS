//
//  GVRVideoTestInterface.m
//  edX
//
//  Created by Ravi Kishore on 02/01/17.
//  Copyright © 2017 edX. All rights reserved.
//

#import "GVRVideoTestInterface.h"

@interface GVRVideoTestInterface ()

@end

@implementation GVRVideoTestInterface

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
   self.view.backgroundColor = [UIColor greenColor];
    self.topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 60)];
    self.topView.backgroundColor = [UIColor colorWithRed:240.0/255.0 green:243.0/255.0 blue:245.0/255.0 alpha:1.0];
    self.topLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    NSString *topMessage = @"\n                   Data usage warning  \nWe recommend you to connect to Wi-Fi \n               before straming the video";
    self.topLabel.text =topMessage;
    self.topLabel.textColor = [UIColor blackColor];
    self.topLabel.font = [UIFont systemFontOfSize:12.0];
    self.topLabel.numberOfLines = 0;
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithAttributedString: self.topLabel.attributedText];
    [self.topView addSubview:self.topLabel];
    
    NSRange range1 = [topMessage rangeOfString:@"Data usage warning"];
    NSRange range2 = [topMessage rangeOfString:@"We recommend you to connect to Wi-Fi"];
    NSRange range3 = [topMessage rangeOfString:@"before straming the video"];
    
    
    [text addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:range1];
    [text addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:253.0/255.0 green:41.0/255.0 blue:199.0/255.0 alpha:1.0] range:range2];
    [text addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:253.0/255.0 green:41.0/255.0 blue:199.0/255.0 alpha:1.0] range:range3];
    
    self.topLabel.attributedText = text;
    
    [self.topLabel setTranslatesAutoresizingMaskIntoConstraints:NO];

    
    [self.view addSubview:self.topView];
    
    NSLayoutConstraint *leadingConstraint= [NSLayoutConstraint constraintWithItem:self.topView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.topLabel attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0];
    NSLayoutConstraint *topConstraint= [NSLayoutConstraint constraintWithItem:self.topView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLabel attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
    [self.topView addConstraints:@[leadingConstraint,topConstraint]];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
