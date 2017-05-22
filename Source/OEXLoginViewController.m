//
//  OEXLoginViewController.m
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 15/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

@import edXCore;

#import "OEXLoginViewController.h"

#import "edX-Swift.h"

#import <Masonry/Masonry.h>

#import "NSString+OEXValidation.h"
#import "NSJSONSerialization+OEXSafeAccess.h"

#import "OEXAnalytics.h"
#import "OEXAppDelegate.h"
#import "OEXCustomButton.h"
#import "OEXCustomLabel.h"
#import "OEXAuthentication.h"
#import "OEXFBSocial.h"
#import "OEXExternalAuthOptionsView.h"
#import "OEXFacebookAuthProvider.h"
#import "OEXFacebookConfig.h"
#import "OEXFlowErrorViewController.h"
#import "OEXGoogleAuthProvider.h"
#import "OEXGoogleConfig.h"
#import "OEXGoogleSocial.h"
#import "OEXInterface.h"
#import "OEXNetworkConstants.h"
#import "OEXNetworkUtility.h"
#import "OEXSession.h"
#import "OEXUserDetails.h"
#import "OEXUserLicenseAgreementViewController.h"
#import "Reachability.h"
#import "OEXStyles.h"
#import "OEXAfterLogOutViewController.h"
#import "SMFloatingLabelTextField.h"

#define USER_EMAIL @"USERNAME"
#define FORGOT_PASSWORD @"Forgot your password?"
#define SIGN_IN @"SIGN IN"
#define SIGNING_IN @"SIGNING IN..."

@interface OEXLoginViewController () <UIAlertViewDelegate>
{
    CGPoint originalOffset;     // store the offset of the scrollview.
    UITextField* activeField;   // assign textfield object which is in active state.

}
@property (nonatomic, strong) NSString* str_ForgotEmail;
@property (nonatomic, strong) NSString* signInID;
@property (nonatomic, strong) NSString* signInPassword;
@property (nonatomic, assign) BOOL reachable;

@property (weak, nonatomic, nullable) IBOutlet UILabel* lbl_OrSignIn;
@property (weak, nonatomic, nullable) IBOutlet SMFloatingLabelTextField* tf_EmailID;
@property (weak, nonatomic, nullable) IBOutlet SMFloatingLabelTextField* tf_Password;
@property (weak, nonatomic, nullable) IBOutlet UIButton* btn_TroubleLogging;
@property (weak, nonatomic, nullable) IBOutlet UIButton* btn_Login;
@property (weak, nonatomic, nullable) IBOutlet UIImageView* img_Logo;
@property (nonatomic, strong) SpinnerView* activityIndicator;

@property (weak, nonatomic, nullable) IBOutlet NSLayoutConstraint *centerYConstraint;

@property (nonatomic, assign) id <OEXExternalAuthProvider> authProvider;
@property (nonatomic) OEXTextStyle *placeHolderStyle;
@property (nonatomic) OEXMutableTextStyle *buttonsTitleStyle;


@end

@implementation OEXLoginViewController

#pragma mark - NSURLConnection Delegtates

#pragma mark - Init

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.view setUserInteractionEnabled:NO];
}
- (BOOL)isFacebookEnabled {
    return ![OEXNetworkUtility isOnZeroRatedNetwork] && [self.environment.config facebookConfig].enabled;
}

- (BOOL)isGoogleEnabled {
    return ![OEXNetworkUtility isOnZeroRatedNetwork] && [self.environment.config googleConfig].enabled;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    ////Create progrssIndicator as subview to btnCreateAccount
    self.activityIndicator = [[SpinnerView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    self.activityIndicator.hidden = YES;

    [self.btn_Login addSubview:self.activityIndicator];

    [self setTitle:[Strings signInText]];

    NSMutableArray* providers = [[NSMutableArray alloc] init];
    if([self isGoogleEnabled]) {
        [providers addObject:[[OEXGoogleAuthProvider alloc] init]];
    }
    if([self isFacebookEnabled]) {
        [providers addObject:[[OEXFacebookAuthProvider alloc] init]];
    }
    
    if (self.environment.config.isRegistrationEnabled) {
        UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_cancel"] style:UIBarButtonItemStylePlain target:self action:@selector(navigateBack)];
        closeButton.accessibilityLabel = [Strings close];
        self.navigationItem.leftBarButtonItem = closeButton;
    }
    
    [self setExclusiveTouch];

    if ([self isRTL]) {
        [self.btn_TroubleLogging setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
    }
    
    self.tf_EmailID.textAlignment = NSTextAlignmentNatural;
    self.tf_Password.textAlignment = NSTextAlignmentNatural;
    self.img_Logo.isAccessibilityElement = YES;
    self.img_Logo.accessibilityLabel = [[OEXConfig sharedConfig] platformName];
    
    _placeHolderStyle = [[OEXTextStyle alloc] initWithWeight:OEXTextWeightNormal size:OEXTextSizeBase color:[[UIColor alloc] initWithHexString:@"#9B9B9B" alpha:0.51]];
    _buttonsTitleStyle = [[OEXMutableTextStyle alloc] initWithWeight:OEXTextWeightBold size:OEXTextSizeBase color:[[OEXStyles sharedStyles] primaryBaseColor]];
}

- (void)viewDidLayoutSubviews {
    const int progressIndicatorCenterX = [self isRTL] ? 40 : self.btn_Login.frame.size.width - 40;

    self.activityIndicator.center = CGPointMake(progressIndicatorCenterX, self.btn_Login.frame.size.height / 2);
}

- (void)navigateBack {
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setExclusiveTouch {
    self.btn_Login.exclusiveTouch = YES;
    self.btn_TroubleLogging.exclusiveTouch = YES;
    self.view.multipleTouchEnabled = NO;
    self.view.exclusiveTouch = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    //Analytics Screen record
    [[OEXAnalytics sharedAnalytics] trackScreenWithName:@"Login"];

    OEXAppDelegate* appD = (OEXAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.reachable = [appD.reachability isReachable];

    [self.view setUserInteractionEnabled:YES];
    self.view.exclusiveTouch = YES;

    // Scrolling on keyboard hide and show
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setSignInToDefaultState:) name:UIApplicationDidBecomeActiveNotification object:nil];

    //Tap to dismiss keyboard
    UIGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                              action:@selector(tappedToDismiss)];
    [self.view addGestureRecognizer:tapGesture];

    //To set all the components tot default property
    [self setToDefaultProperties];
}

- (NSString*)signInButtonText {
    return SIGN_IN;
}

-(NSString *)signingInText{
    return SIGNING_IN;
}

- (void)handleActivationDuringLogin {
    if(self.authProvider != nil) {
        [self.btn_Login applyButtonStyle:[self.environment.styles filledButtonStyle:[UIColor piqueGreen]] withTitle:[self signInButtonText]];
        [self.activityIndicator stopAnimating];
        self.activityIndicator.hidden = YES;
        [self.view setUserInteractionEnabled:YES];

        self.authProvider = nil;
    }
}

- (void)setSignInToDefaultState:(NSNotification*)notification {
    OEXFBSocial *facebookManager = [[OEXFBSocial alloc]init];
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    if([self.authProvider isKindOfClass:[OEXGoogleAuthProvider class]] && ![[OEXGoogleSocial sharedInstance] handledOpenUrl]) {
        [[OEXGoogleSocial sharedInstance] clearHandler];
        [self handleActivationDuringLogin];
    }
    else if(![facebookManager isLogin] && [self.authProvider isKindOfClass:[OEXFacebookAuthProvider class]]) {
        [self handleActivationDuringLogin];
    }

    self.authProvider = nil;
    [[OEXGoogleSocial sharedInstance] setHandledOpenUrl:NO];
}

- (void)setToDefaultProperties {
    self.automaticallyAdjustsScrollViewInsets = NO;

    self.tf_EmailID.floatingLabelActiveColor = [[UIColor alloc] initWithHexString:@"#B9B9B9" alpha:0.5];
    self.tf_Password.floatingLabelActiveColor = [[UIColor alloc] initWithHexString:@"#B9B9B9" alpha:0.5];

    self.tf_EmailID.floatingLabelFont = [UIFont systemFontOfSize:14];
    self.tf_Password.floatingLabelFont = [UIFont systemFontOfSize:14];

    [self.tf_EmailID setAttributedPlaceholder:[_placeHolderStyle attributedStringWithText:[Strings usernamePlaceholder]]];
    [self.tf_Password setAttributedPlaceholder:[_placeHolderStyle attributedStringWithText:[Strings passwordPlaceholder]]];

    self.tf_EmailID.text = @"";
    self.tf_Password.text = @"";
    self.tf_EmailID.accessibilityLabel = nil;
    self.tf_Password.accessibilityLabel = nil;

    [self.btn_TroubleLogging setTitle:FORGOT_PASSWORD forState:UIControlStateNormal];
    _buttonsTitleStyle.weight = OEXTextWeightNormal;
    _buttonsTitleStyle.size = OEXTextSizeXXSmall;

    [self.activityIndicator stopAnimating];
    self.activityIndicator.hidden = YES;

    NSString* username = [[NSUserDefaults standardUserDefaults] objectForKey:USER_EMAIL];

    if(username) {
        _tf_EmailID.text = username;
        _tf_EmailID.accessibilityLabel = [Strings usernamePlaceholder];
    }

    NSDictionary *regular = @{NSForegroundColorAttributeName: [[UIColor alloc] initWithHexString:@"#626567" alpha:1.0],
                                                    NSFontAttributeName: [UIFont systemFontOfSize:13.0f weight:UIFontWeightRegular]
                                                    };

    NSDictionary *bold = @{NSForegroundColorAttributeName: [[UIColor alloc] initWithHexString:@"#626567" alpha:1.0],
                              NSFontAttributeName: [UIFont systemFontOfSize:13.0f weight:UIFontWeightBold]
                              };

    NSString *text = @"Don’t have an account? Sign up";
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text attributes:regular];

    [attributedString setAttributes:bold range:[text rangeOfString:@"Sign up"]];

    [self.lbl_OrSignIn setAttributedText:attributedString];

    [self.btn_Login applyButtonStyle:[self.environment.styles filledButtonStyle:[UIColor piqueGreen]] withTitle:[self signInButtonText]];
}

- (void)reachabilityDidChange:(NSNotification*)notification {
    id <Reachability> reachability = [notification object];

    if([reachability isReachable]) {
        self.reachable = YES;
    }
    else {
        self.reachable = NO;

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view setUserInteractionEnabled:YES];
        });
        [self.btn_Login applyButtonStyle:[self.environment.styles filledButtonStyle:[UIColor piqueGreen]] withTitle:[self signInButtonText]];
        [self.activityIndicator stopAnimating];
        self.activityIndicator.hidden = YES;
    }
}

#pragma mark IBActions

- (IBAction)signUpTapped:(id)sender {

    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"LoginViewControllerDidClose" object:nil];
		[self.environment.router showSignUpScreenFromController:self.parentViewController completion:nil];
    }];
}

- (IBAction)backButtonTapped:(id)sender {
    [self navigateBack];
}

- (IBAction)troubleLoggingClicked:(id)sender {
    if(self.reachable) {
        [self.view setUserInteractionEnabled:NO];

        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:[Strings resetPasswordTitle]
                                                        message:[Strings resetPasswordPopupText]
                                                       delegate:self
                                              cancelButtonTitle:[Strings cancel]
                                              otherButtonTitles:[Strings ok], nil];

        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        UITextField* textfield = [alert textFieldAtIndex:0];
        textfield.keyboardType = UIKeyboardTypeEmailAddress;

        if([self.tf_EmailID.text length] > 0) {
            UITextField* tf = [alert textFieldAtIndex:0];
            [[alert textFieldAtIndex:0] setAttributedPlaceholder:[_placeHolderStyle attributedStringWithText:[Strings emailAddressPrompt]]];
            tf.text = self.tf_EmailID.text;
        }

        alert.tag = 1001;
        [alert show];
    }
    else {
        // error
        
        [[UIAlertController alloc] showAlertWithTitle:[Strings networkNotAvailableTitle]
                                              message:[Strings networkNotAvailableMessageTrouble]
                                     onViewController:self];
    }
}

- (IBAction)loginClicked:(id)sender {
    [self.view setUserInteractionEnabled:NO];

    if(!self.reachable) {
        [[UIAlertController alloc] showAlertWithTitle:[Strings networkNotAvailableTitle]
                                              message:[Strings networkNotAvailableMessage]
                                     onViewController:self
                                                            ];
        
        [self.view setUserInteractionEnabled:YES];

        return;
    }

    //Validation
    if([self.tf_EmailID.text length] == 0) {
        [[UIAlertController alloc] showAlertWithTitle:[Strings floatingErrorLoginTitle]
                                                                message:[Strings enterEmail]
                                                       onViewController:self
                                                            ];

        [self.view setUserInteractionEnabled:YES];
    }
    else if([self.tf_Password.text length] == 0) {
        [[UIAlertController alloc] showAlertWithTitle:[Strings floatingErrorLoginTitle]
                                                                message:[Strings enterPassword]
                                                       onViewController:self
                                                            ];

        [self.view setUserInteractionEnabled:YES];
    }
    else {
        self.signInID = _tf_EmailID.text;
        self.signInPassword = _tf_Password.text;

        [OEXAuthentication requestTokenWithUser:_signInID
                                       password:_signInPassword
                              completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
            [self handleLoginResponseWith:data response:response error:error];
        } ];

        [self.view setUserInteractionEnabled:NO];
        [self.activityIndicator startAnimating];
        self.activityIndicator.hidden = NO;
        [self.btn_Login applyButtonStyle:[self.environment.styles filledButtonStyle:[UIColor piqueGreen]] withTitle:[self signingInText]];
    }
}

- (void)handleLoginResponseWith:(NSData*)data response:(NSURLResponse*)response error:(NSError*)error {
    [[OEXGoogleSocial sharedInstance] clearHandler];

    [self.view setUserInteractionEnabled:YES];

    if(!error) {
        NSHTTPURLResponse* httpResp = (NSHTTPURLResponse*) response;
        if(httpResp.statusCode == 200) {
            [self loginSuccessful];
        }
        else if(httpResp.statusCode >= 400 && httpResp.statusCode <= 500) {
            NSString* errorStr = [Strings invalidUsernamePassword];
                [self loginFailedWithErrorMessage:errorStr title:nil];
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self loginFailedWithErrorMessage:[Strings invalidUsernamePassword] title:nil];
            });
        }
    }
    else {
        [self loginHandleLoginError:error];
    }
    self.authProvider = nil;
}

- (void)externalLoginWithProvider:(id <OEXExternalAuthProvider>)provider {
    self.authProvider = provider;
    if(!self.reachable) {
        [[UIAlertController alloc] showAlertWithTitle:[Strings networkNotAvailableTitle]
                                                                message:[Strings networkNotAvailableMessage]
                                                       onViewController:self
                                                            ];
        self.authProvider = nil;
        return;
    }
    
    OEXURLRequestHandler handler = ^(NSData* data, NSHTTPURLResponse* response, NSError* error) {
        if(!response) {
            [self loginFailedWithErrorMessage:[Strings invalidUsernamePassword] title:nil];
            return;
        }
        self.authProvider = nil;
        
        [self handleLoginResponseWith:data response:response error:error];
    };
    
    [provider authorizeServiceFromController:self
                       requestingUserDetails:NO
                              withCompletion:^(NSString* accessToken, OEXRegisteringUserDetails* details, NSError* error) {
                                  if(accessToken) {
                                      [OEXAuthentication requestTokenWithProvider:provider externalToken:accessToken completion:handler];
                                  }
                                  else {
                                      handler(nil, nil, error);
                                  }
                              }];

    [self.view setUserInteractionEnabled:NO];
    [self.activityIndicator startAnimating];
    self.activityIndicator.hidden = NO;
    [self.btn_Login applyButtonStyle:[self.environment.styles filledButtonStyle:[UIColor piqueGreen]] withTitle:[self signInButtonText]];
}

- (void)loginHandleLoginError:(NSError*)error {
    if(error.code == -1003 || error.code == -1009 || error.code == -1005) {
        [self loginFailedWithErrorMessage:[Strings invalidUsernamePassword] title:nil];
    }
    else {
        if(error.code == 401) {
            [[OEXGoogleSocial sharedInstance] clearHandler];

            // MOB - 1110 - Social login error if the user's account is not linked with edX.
            if(self.authProvider != nil) {
                [self loginFailedWithServiceName: self.authProvider.displayName];
            }
        }
        else {
            [self loginFailedWithErrorMessage:[error localizedDescription] title: nil];
        }
    }
}

- (void)loginFailedWithServiceName:(NSString*)serviceName {
    NSString* platform = self.environment.config.platformName;
    NSString* destination = self.environment.config.platformDestinationName;
    NSString* title = [Strings serviceAccountNotAssociatedTitleWithService:serviceName platformName:platform];
    NSString* message = [Strings serviceAccountNotAssociatedMessageWithService:serviceName platformName:platform destinationName:destination];
    [self loginFailedWithErrorMessage:message title:title];
}

- (void)loginFailedWithErrorMessage:(NSString*)errorStr title:(NSString*)title {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    if(title) {
        [[UIAlertController alloc] showAlertWithTitle:title
                                      message:errorStr
                             onViewController:self];
    }
    else {
        [[UIAlertController alloc] showAlertWithTitle:[Strings floatingErrorLoginTitle]
                                      message:errorStr
                             onViewController:self];
    }

    [self.activityIndicator stopAnimating];
    self.activityIndicator.hidden = YES;
    [self.btn_Login applyButtonStyle:[self.environment.styles filledButtonStyle:[UIColor piqueGreen]] withTitle:[self signInButtonText]];

    [self.view setUserInteractionEnabled:YES];

    [self tappedToDismiss];
}

- (void)loginSuccessful {
    //set global auth
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:YES forKey:FIRST_TIME_USER_KEY];
    
    [userDefaults setBool:NO forKey:FTUE]; // Changed to NO as for every login coach marks are not required.

    
    if([_tf_EmailID.text length] > 0) {
        // Set the language to blank
        [OEXInterface setCCSelectedLanguage:@""];
        [[NSUserDefaults standardUserDefaults] setObject:_tf_EmailID.text forKey:USER_EMAIL];
        // Analytics User Login
        [[OEXAnalytics sharedAnalytics] trackUserLogin:[self.authProvider backendName] ?: @"Password"];
    }
    [self tappedToDismiss];
    [self.activityIndicator stopAnimating];
    self.activityIndicator.hidden = YES;

    //Launch next view
    [self didLogin];
}

- (void)didLogin {
    [self.delegate loginViewControllerDidLogin:self];
}

#pragma mark UI

- (void)tappedToDismiss {
    [_tf_EmailID resignFirstResponder];
    [_tf_Password resignFirstResponder];
}

#pragma mark UIAlertView Delegate

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self.view setUserInteractionEnabled:YES];

    if(alertView.tag == 1001) {
        UITextField* EmailtextField = [alertView textFieldAtIndex:0];

        if(buttonIndex == 1) {
            if([EmailtextField.text length] == 0 || ![EmailtextField.text oex_isValidEmailAddress]) {
                [[UIAlertController alloc] showAlertWithTitle:[Strings floatingErrorTitle] message:[Strings invalidEmailMessage] onViewController:self];
            }
            else {
                self.str_ForgotEmail = [[NSString alloc] init];

                self.str_ForgotEmail = EmailtextField.text;

                [self.view setUserInteractionEnabled:NO];

                [[UIAlertController alloc] showAlertWithTitle:[Strings resetPasswordTitle]
                                              message:[Strings waitingForResponse]
                                     onViewController:self];
                [self resetPassword];
            }
        }
    }
}

- (void)resetPassword {
    [OEXAuthentication resetPasswordWithEmailId:self.str_ForgotEmail completionHandler:^(NSData* data, NSURLResponse* response, NSError* error)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
                [self.view setUserInteractionEnabled:YES];
                [[OEXFlowErrorViewController sharedInstance] animationUp];

                if(!error) {
                    NSHTTPURLResponse* httpResp = (NSHTTPURLResponse*) response;
                    if(httpResp.statusCode == 200) {
                        [[[UIAlertView alloc] initWithTitle:[Strings resetPasswordConfirmationTitle]
                                                    message:[Strings resetPasswordConfirmationMessage]

                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:[Strings ok], nil] show];
                    }
                    else if(httpResp.statusCode <= 400 && httpResp.statusCode < 500) {
                        NSDictionary* dictionary = [NSJSONSerialization oex_JSONObjectWithData:data error:nil];
                        NSString* responseStr = [[dictionary objectForKey:@"email"] firstObject];
                        [[UIAlertController alloc]
                         showAlertWithTitle:[Strings floatingErrorTitle]
                                    message:responseStr onViewController:self];
                    }
                    else if(httpResp.statusCode >= 500) {
                        NSString* responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                        [[UIAlertController alloc] showAlertWithTitle:[Strings floatingErrorTitle] message:responseStr onViewController:self];
                        
                    }
                }
                else {
                    [[UIAlertController alloc]
                     showAlertWithTitle:[Strings floatingErrorTitle] message:[error localizedDescription] onViewController:self];
                }
            });
    }];
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
    UITouch* touch = [touches anyObject];
    if([[touch view] isKindOfClass:[UIButton class]]) {
        [self.view setUserInteractionEnabled:NO];
    }
}

#pragma mark TextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField*)textField;
{
    if(textField == self.tf_EmailID) {
        [self.tf_Password becomeFirstResponder];
    }
    else {
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, self.btn_Login);
        [textField resignFirstResponder];
    }

    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([textField isEqual:_tf_EmailID] && [textField.text isEqualToString:@""] && string.length > 0) {
        textField.accessibilityLabel = [Strings usernamePlaceholder];
    }
    else if([textField isEqual:_tf_EmailID] && [string isEqualToString:@""] && textField.text.length == 1) {
        textField.accessibilityLabel = nil;
    }
    
    
    if ([textField isEqual:_tf_Password] && [textField.text isEqualToString:@""] && string.length > 0) {
        textField.accessibilityLabel = [Strings passwordPlaceholder];
    }
    else if([textField isEqual:_tf_Password] && [string isEqualToString:@""] && textField.text.length == 1) {
        textField.accessibilityLabel = nil;
    }
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField*)textField {
    activeField = textField;
}

#pragma mark - Scolling on Keyboard Hide/Show

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification {
    // Calculating the height of the keyboard and the scrolling offset of the textfield
    // And scrolling on the calculated offset to make it visible

    NSDictionary *userInfo = [aNotification userInfo];
    CGRect kbRect = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    kbRect = [self.view convertRect:kbRect toView:nil];

    [UIView beginAnimations:nil context:NULL];

    [UIView setAnimationDuration:[userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue]];
    self.centerYConstraint.constant = -kbRect.size.height/2;

    [self.view layoutIfNeeded];

    [UIView commitAnimations];
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification {

    NSDictionary *userInfo = [aNotification userInfo];

    [UIView beginAnimations:nil context:NULL];

    [UIView setAnimationDuration:[userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue]];
    self.centerYConstraint.constant = 0;

    [self.view layoutIfNeeded];

    [UIView commitAnimations];
}

- (BOOL) isRTL {
    return [UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [OEXStyles sharedStyles].standardStatusBarStyle;
}

- (BOOL) shouldAutorotate {
    return false;
}

- (UIInterfaceOrientationMask) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
