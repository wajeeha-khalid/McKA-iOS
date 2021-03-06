//
//  OEXRouter.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/29/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Masonry/Masonry.h>

#import "edX-Swift.h"

#import "OEXRouter.h"

#import "OEXAnalytics.h"
#import "OEXConfig.h"
#import "OEXFindCoursesViewController.h"
#import "OEXInterface.h"
#import "OEXLoginSplashViewController.h"
#import "OEXPushSettingsManager.h"
#import "OEXRegistrationViewController.h"
#import "OEXSession.h"
#import "OEXDownloadViewController.h"
#import "OEXMyVideosSubSectionViewController.h"
#import "OEXMyVideosViewController.h"
#import "OEXCourse.h"
#import "SWRevealViewController.h"
#import "OEXFTUEViewController.h"
#import "OEXAfterLogOutViewController.h"

static OEXRouter* sSharedRouter;

NSString* OEXSideNavigationChangedStateNotification = @"OEXSideNavigationChangedStateNotification";
NSString* OEXSideNavigationChangedStateKey = @"OEXSideNavigationChangedStateKey";

@interface OEXRouter () <
OEXRegistrationViewControllerDelegate, LoginViewControllerDelegate
>

@property (strong, nonatomic) UIStoryboard* mainStoryboard;
@property (strong, nonatomic) RouterEnvironment* environment;

@property (strong, nonatomic) SingleChildContainingViewController* containerViewController;
@property (strong, nonatomic) UIViewController* currentContentController;

@property (strong, nonatomic) RevealViewController* revealController;
@property (strong, nonatomic) void(^registrationCompletion)(void);

@end

@implementation OEXRouter

+ (void)setSharedRouter:(OEXRouter*)router {
    sSharedRouter = router;
}

+ (instancetype)sharedRouter {
    return sSharedRouter;
}

- (id)initWithEnvironment:(RouterEnvironment *)environment {
    self = [super init];
    if(self != nil) {
        environment.router = self;
        self.mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        self.environment = environment;
        self.containerViewController = [[SingleChildContainingViewController alloc] initWithNibName:nil bundle:nil];
    }
    return self;
}

- (id)init {
    return [self initWithEnvironment:nil];
}

- (void)openInWindow:(UIWindow*)window {
    window.rootViewController = self.containerViewController;
    window.tintColor = [self.environment.styles primaryBaseColor];
    
    OEXUserDetails* currentUser = self.environment.session.currentUser;
    if(currentUser == nil) {
        [self showSplash];
    } else {
        [self showLoggedInContent];
    }
}

- (void)removeCurrentContentController {
    [self.currentContentController willMoveToParentViewController:nil];
    [self.currentContentController.view removeFromSuperview];
    [self.currentContentController removeFromParentViewController];
    self.currentContentController = nil;
}

- (void)makeContentControllerCurrent:(UIViewController*)controller {
    [self.containerViewController addChildViewController:controller];
    [self.containerViewController.view addSubview:controller.view];
    [controller.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.containerViewController.view);
    }];
    
    [controller didMoveToParentViewController:self.containerViewController];
    self.currentContentController = controller;
}

- (void)showLoggedInContent {
    [self removeCurrentContentController];
    
    // Added By Naveen on 9Mar'17 for FTUE Screens.
     [[NSUserDefaults standardUserDefaults] setBool:YES forKey:FIRST_TIME_USER_KEY];
    
    OEXUserDetails* currentUser = self.environment.session.currentUser;
    [self.environment.analytics identifyUser:currentUser];
    
    [ UAirship push ].userPushNotificationsEnabled = true;
    
    self.revealController = [self.mainStoryboard instantiateViewControllerWithIdentifier:@"SideNavigationContainer"];
    self.revealController.delegate = self.revealController;
    [self showMyCoursesAnimated:NO pushingCourseWithID:nil];
    
    UIViewController* rearController = [self.mainStoryboard instantiateViewControllerWithIdentifier:@"RearViewController"];
    [self.revealController setDrawerViewController:rearController animated:NO];
    [self makeContentControllerCurrent:self.revealController];
}

- (void)showLoginScreenFromController:(UIViewController*)controller completion:(void(^)(void))completion {
    [self presentViewController:self.loginViewController fromController:[controller topMostController] completion:completion];
}


- (void)showSignUpScreenFromController:(UIViewController*)controller completion:(void(^)(void))completion {
    self.registrationCompletion = completion;
    OEXRegistrationViewController* registrationController = [[OEXRegistrationViewController alloc] initWithEnvironment:self.environment];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:registrationController];
    registrationController.delegate = self;
    
    [self presentViewController:navController fromController:[controller topMostController] completion:nil];
}

- (void)presentViewController:(UIViewController*)controller fromController:(UIViewController*)fromController completion:(void(^)(void))completion {
    if (fromController == nil) {
        fromController = self.containerViewController;
    }

    [fromController presentViewController:controller animated:YES completion:completion];
}

- (void)showLoggedOutScreen {
    [self showLoginScreenFromController:nil completion:^{
        [self showSplash];
    }];
    
}

- (void)showAnnouncementsForCourseWithID:(NSString *)courseID {
    UINavigationController* navigation = OEXSafeCastAsClass(self.revealController.frontViewController, UINavigationController);
    CourseAnnouncementsViewController* currentController = OEXSafeCastAsClass(navigation.topViewController, CourseAnnouncementsViewController);
    BOOL showingChosenCourse = [currentController.courseID isEqual:courseID];
    
    if(!showingChosenCourse) { 
        CourseAnnouncementsViewController* announcementController = [[CourseAnnouncementsViewController alloc] initWithEnvironment:self.environment courseID:courseID];
        [navigation pushViewController:announcementController animated:YES];
    }
}

- (UIBarButtonItem*)showNavigationBarItem {
    UIBarButtonItem* item = [[UIBarButtonItem alloc] initWithImage:[UIImage MenuIcon] style:UIBarButtonItemStylePlain target:self action:@selector(showSidebar:)];
    item.accessibilityLabel = [Strings accessibilityMenu];
    item.accessibilityIdentifier = @"navigation-bar-button";
    
    return item;
}

- (void)showSidebar:(id)sender {
    [self.revealController toggleDrawerAnimated:YES];
}

- (void)showContentStackWithRootController:(UIViewController*)controller animated:(BOOL)animated {
    controller.navigationItem.leftBarButtonItem = [self showNavigationBarItem];
    NSAssert( self.revealController != nil, @"oops! must have a revealViewController" );
    
    [controller.view addGestureRecognizer:self.revealController.panGestureRecognizer];
    UINavigationController* navigationController = [[ForwardingNavigationController alloc] initWithRootViewController:controller];
    [self.revealController pushFrontViewController:navigationController animated:animated];
}

- (void)showDownloadsFromViewController:(UIViewController*)controller {
    OEXDownloadViewController* vc = [[UIStoryboard storyboardWithName:@"OEXDownloadViewController" bundle:nil] instantiateViewControllerWithIdentifier:@"OEXDownloadViewController"];
    [controller.navigationController pushViewController:vc animated:YES];
}

- (void)showVideoSubSectionFromViewController:(UIViewController*) controller forCourse:(OEXCourse*) course withCourseData:(NSMutableArray*) courseData{
    OEXMyVideosSubSectionViewController* vc = [[UIStoryboard storyboardWithName:@"OEXMyVideosSubSectionViewController" bundle:nil] instantiateViewControllerWithIdentifier:@"MyVideosSubsection"];
    vc.course = course;
    vc.arr_CourseData = courseData;
    vc.environment = self.environment;
    [controller.navigationController pushViewController:vc animated:YES];
}

- (void)showMyVideos {
    OEXMyVideosViewController* videoController = [[UIStoryboard storyboardWithName:@"OEXMyVideosViewController" bundle:nil]instantiateViewControllerWithIdentifier:@"MyVideos"];
    NSAssert( self.revealController != nil, @"oops! must have a revealViewController" );
    videoController.environment = self.environment;
    [self showContentStackWithRootController:videoController animated:YES];
}

- (void)showMySettings {
    OEXMySettingsViewController* controller = [[OEXMySettingsViewController alloc] initWithNibName:nil bundle:nil];
    [self showContentStackWithRootController:controller animated:YES];
}

-(void)showLicensingTerms {
    
    OEXWebViewController *controller = [[OEXWebViewController alloc] initWithNibName:nil bundle:nil];
    controller.navigationControllerTitle = Strings.licensingTerms;
    NSString *htmlFile = [[NSBundle mainBundle] pathForResource:@"EULA" ofType:@"htm"];
    controller.requestToLoad = [  NSURLRequest requestWithURL:  [ NSURL fileURLWithPath:htmlFile ] ];
    
    [self showContentStackWithRootController:controller animated:YES];
}

- (void)showAccountSettings{
    OEXWebViewController *controller = [[OEXWebViewController alloc] initWithNibName:nil bundle:nil];
    
    controller.navigationControllerTitle = ACCOUNT_SETTINGS;
    NSString *urlString = [ NSString stringWithFormat:@"%@%@", [ [ OEXConfig sharedConfig] apiHostURL] , URL_ACCOUNT_SETTINGS ];
    NSURL *url  = [ NSURL URLWithString:urlString  ];
    NSString *authValue = [[ NSString stringWithFormat:@"%@", [ OEXAuthentication authHeaderForApiAccess ]  ] stringByReplacingOccurrencesOfString:@"Bearer" withString:@"" ];
    
    NSMutableURLRequest *accountSettingsRequest = [ NSMutableURLRequest requestWithURL:url ];
    [ accountSettingsRequest setValue:authValue forHTTPHeaderField:@"Authorization" ];
    
    controller.requestToLoad = accountSettingsRequest;
    [self showContentStackWithRootController:controller animated:YES];
    
}

#pragma Delegate Implementations

- (void)registrationViewControllerDidRegister:(OEXRegistrationViewController *)controller completion:(void (^)(void))completion {
    [self showLoggedInContent];
    [controller dismissViewControllerAnimated:YES completion:completion];
    if (self.registrationCompletion) {
        self.registrationCompletion();
        self.registrationCompletion = nil;
    }
}

- (void)loginViewControllerDidLogin:(LoginViewController *)loginController {
    if(self.environment.session.currentUser) {
        [BrandingThemes.shared applyThemeWithFileName:self.environment.session.currentUser.companyId];
        [OEXStyles.sharedStyles applyGlobalAppearance];
    }

    [self showLoggedInContent];
    [loginController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Testing

@end

@implementation OEXRouter(Testing)

- (NSArray*)t_navigationHierarchy {
    return OEXSafeCastAsClass(self.revealController.frontViewController, UINavigationController).viewControllers ?: @[];
}

- (BOOL)t_showingLogin {
    return [self.currentContentController isKindOfClass:[OEXLoginSplashViewController class]];
}

- (BOOL)t_hasDrawerController {
    return self.revealController.drawerViewController != nil;
}

@end
