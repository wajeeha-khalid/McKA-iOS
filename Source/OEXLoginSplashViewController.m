//
//  LoginSplashViewController.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 16/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXLoginSplashViewController.h"

#import "edX-Swift.h"

#import "OEXRouter.h"
#import "OEXSession.h"

@interface OEXLoginSplashViewController ()

    @property (strong, nonatomic) IBOutlet UIButton* signInButton;
    @property (strong, nonatomic) IBOutlet UIButton* signUpButton;

    @property (strong, nonatomic) RouterEnvironment* environment;

    @end

@implementation OEXLoginSplashViewController

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

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showSignUp) name:@"LoginViewControllerDidClose" object:nil];

    [self.signInButton setTitle:[Strings loginSplashSignIn] forState:UIControlStateNormal];
    [self.signUpButton applyButtonStyle:[self.environment.styles filledPrimaryButtonStyle] withTitle:[Strings loginSplashSignUp]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (IBAction)showLogin:(id)sender {
    [self.environment.router showLoginScreenFromController:self completion:nil];
}

- (IBAction)showRegistration:(id)sender {
    [self.environment.router showSignUpScreenFromController:self completion:nil];
}

- (void)showSignUp {
    [self showRegistration:nil];
}

- (BOOL) shouldAutorotate {
    return false;
}

- (UIInterfaceOrientationMask) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}
    
    @end
