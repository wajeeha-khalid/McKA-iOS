//
//  OEXAfterLogOutViewController.m
//  edX
//
//  Created by Naveen Katari on 06/01/17.
//  Copyright © 2017 edX. All rights reserved.
//

#import "OEXAfterLogOutViewController.h"
#import "edX-Swift.h"

#import "OEXRouter.h"

@interface OEXAfterLogOutViewController ()

@property (strong, nonatomic) RouterEnvironment* environment;

@end

@implementation OEXAfterLogOutViewController

    -(void)dealloc {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }

- (id)initWithEnvironment:(RouterEnvironment*)environment {
    self = [super initWithNibName:nil bundle:nil];
    if(self != nil) {
        self.environment = environment;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showSignUp) name:@"LoginViewControllerDidClose" object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)signUpButtonAction:(id)sender {
    [self.environment.router showSignUpScreenFromController:self completion:nil];
}
- (IBAction)signInButtonAction:(id)sender {
    [self.environment.router showLoginScreenFromController:self completion:nil];
}

- (void)showSignUp {
    [self signUpButtonAction:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
