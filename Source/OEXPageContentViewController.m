
//
//  OEXPageContentViewController.m
//  edX
//
//  Created by Naveen Katari on 23/12/16.
//  Copyright © 2016 edX. All rights reserved.
//

#import "OEXPageContentViewController.h"

@interface OEXPageContentViewController ()
@property (weak, nonatomic) IBOutlet UILabel *tutorialTextLabel;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;

@end

@implementation OEXPageContentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.backgroundImageView setImage:[UIImage imageNamed:self.imageName]];
    [self.tutorialTextLabel setText:self.tutorialText];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
