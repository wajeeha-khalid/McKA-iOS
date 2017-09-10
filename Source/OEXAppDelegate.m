//
//  OEXAppDelegate.m
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 15/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

@import edXCore;

//@import AirshipKit;
#import "UIColor+OEXHex.h"
#import <Crashlytics/Crashlytics.h>
#import <Fabric/Fabric.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <GoogleSignIn/GoogleSignIn.h>
#import <NewRelicAgent/NewRelic.h>
#import <SEGAnalytics.h>

#import "OEXAppDelegate.h"

#import "edX-Swift.h"
#import "Logger+OEXObjC.h"

#import "OEXAuthentication.h"
#import "OEXConfig.h"
#import "OEXDownloadManager.h"
#import "OEXEnvironment.h"
#import "OEXFabricConfig.h"
#import "OEXFacebookConfig.h"
#import "OEXGoogleConfig.h"
#import "OEXGoogleSocial.h"
#import "OEXInterface.h"
#import "OEXNewRelicConfig.h"
#import "OEXPushProvider.h"
#import "OEXPushNotificationManager.h"
#import "OEXPushSettingsManager.h"
#import "OEXRouter.h"
#import "OEXSession.h"
#import "OEXSegmentConfig.h"

@interface OEXAppDelegate () <UIApplicationDelegate>

@property (nonatomic, strong) NSMutableDictionary* dictCompletionHandler;
@property (nonatomic, strong) OEXEnvironment* environment;

@end


@implementation OEXAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
#if DEBUG
    // Skip all this initialization if we're running the unit tests
    // So they can start from a clean state.
    // dispatch_async so that the XCTest bundle (where TestEnvironmentBuilder lives) has already loaded
    if([[NSProcessInfo processInfo].arguments containsObject:@"-UNIT_TEST"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            Class builder = NSClassFromString(@"TestEnvironmentBuilder");
            NSAssert(builder != nil, @"Can't find test environment builder");
            (void)[[builder alloc] init];
        });
        return YES;
    }
    if([[NSProcessInfo processInfo].arguments containsObject:@"-END_TO_END_TEST"]) {
        [[[OEXSession alloc] init] closeAndClearSession];
        [OEXFileUtility nukeUserData];
    }
#endif

    // logout user automatically if server changed
    [[[ServerChangedChecker alloc] init] logoutIfServerChanged];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    [self setupGlobalEnvironment];
    [self.environment.session performMigrations];

    [self.environment.router openInWindow:self.window];
    [application setStatusBarStyle:UIStatusBarStyleLightContent];
    // Bootstrapping the Urban Airship SDK with values from AirshipConfig.plist
    [UAirship takeOff];
    
    
    //Added by Ravi on 10Mar'17 to show coach marks only if user lauches for first time.
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if([[[userDefaults dictionaryRepresentation] allKeys] containsObject:FTUE]){
        
        [userDefaults setBool:NO forKey:FTUE];
    }
    else
    {
         [userDefaults setBool:YES forKey:FTUE];
    }

    [NSURLProtocol registerClass:[WebViewLocalLoadingProtocol class]];
    return [[FBSDKApplicationDelegate sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
}

-(UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window{
    if (self.shouldRotate)
        return UIInterfaceOrientationMaskAllButUpsideDown;
    else
        return UIInterfaceOrientationMaskPortrait;
}
//- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window{
//    if (self.shouldRotate)
//        return UIInterfaceOrientationMaskAllButUpsideDown;
//    else
//        return UIInterfaceOrientationMaskPortrait;
//    
////    UIViewController *topController = self.window.rootViewController;
////    
////    return [topController supportedInterfaceOrientations];
//}


- (BOOL)application:(UIApplication*)application openURL:(NSURL*)url sourceApplication:(NSString*)sourceApplication annotation:(id)annotation {
    BOOL handled = false;
    if (self.environment.config.facebookConfig.enabled) {
        handled = [[FBSDKApplicationDelegate sharedInstance] application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
        if(handled) {
            return handled;
        }

    }
    
    if (self.environment.config.googleConfig.enabled){
        handled = [[GIDSignIn sharedInstance] handleURL:url sourceApplication:sourceApplication annotation:annotation];
        [[OEXGoogleSocial sharedInstance] setHandledOpenUrl:YES];
    }
   
    return handled;
}

#pragma mark Push Notifications

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [self.environment.pushNotificationManager didReceiveRemoteNotificationWithUserInfo:userInfo];
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    [self.environment.pushNotificationManager didReceiveLocalNotificationWithUserInfo:notification.userInfo];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [self.environment.pushNotificationManager didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [self.environment.pushNotificationManager didFailToRegisterForRemoteNotificationsWithError:error];
}

#pragma mark Background Downloading

- (void)application:(UIApplication*)application handleEventsForBackgroundURLSession:(NSString*)identifier completionHandler:(void (^)())completionHandler {
    [OEXDownloadManager sharedManager];
    [self addCompletionHandler:completionHandler forSession:identifier];
}

- (void)addCompletionHandler:(void (^)())handler forSession:(NSString*)identifier {
    if(!_dictCompletionHandler) {
        _dictCompletionHandler = [[NSMutableDictionary alloc] init];
    }
    if([self.dictCompletionHandler objectForKey:identifier]) {
        OEXLogError(@"DOWNLOADS", @"Error: Got multiple handlers for a single session identifier.  This should not happen.\n");
    }
    [self.dictCompletionHandler setObject:handler forKey:identifier];
}

- (void)callCompletionHandlerForSession:(NSString*)identifier {
    dispatch_block_t handler = [self.dictCompletionHandler objectForKey: identifier];
    if(handler) {
        [self.dictCompletionHandler removeObjectForKey: identifier];
        OEXLogInfo(@"DOWNLOADS", @"Calling completion handler for session %@", identifier);
        //[self presentNotification];
        handler();
    }
}

#pragma mark Environment

- (void)setupGlobalEnvironment {
    [UserAgentOverrideOperation overrideUserAgent:nil];
    
    self.environment = [[OEXEnvironment alloc] init];
    [self.environment setupEnvironment];

    OEXConfig* config = self.environment.config;

    //Logging
    [DebugMenuLogger setup];

    //Rechability
    self.reachability = [[InternetReachability alloc] init];
    [_reachability startNotifier];

    //SegmentIO
    OEXSegmentConfig* segmentIO = [config segmentConfig];
    if(segmentIO.apiKey && segmentIO.isEnabled) {
        [SEGAnalytics setupWithConfiguration:[SEGAnalyticsConfiguration configurationWithWriteKey:segmentIO.apiKey]];
    }

    //NewRelic Initialization with edx key
    OEXNewRelicConfig* newrelic = [config newRelicConfig];
    if(newrelic.apiKey && newrelic.isEnabled) {
        [NewRelicAgent enableCrashReporting:NO];
        [NewRelicAgent startWithApplicationToken:newrelic.apiKey];
    }

    //Initialize Fabric
    OEXFabricConfig* fabric = [config fabricConfig];
    if(fabric.appKey && fabric.isEnabled) {
        [Fabric with:@[CrashlyticsKit]];
    }

    [[UIActivityIndicatorView appearance] setTintColor:[UIColor piqueGreen]];

    // Initialise the custom HTTP Cache
#if DEBUG
    EVURLCache.LOGGING = true; // We want to see all caching actions
#endif
    
    EVURLCache.MAX_AGE = @"2592000"; // cache age increased to 30 days
    EVURLCache.MAX_FILE_SIZE = 26; // We want more than the default: 2^26 = 64MB
    EVURLCache.MAX_CACHE_SIZE = 30; // We want more than the default: 2^30 = 1GB
    
    [EVURLCache filter:^BOOL(NSURLRequest * _Nonnull request) {
        // Allow only URLs from HTML types from the API host to be cached on disk

        if ([request.HTTPMethod isEqualToString:@"POST"] && request.HTTPBody != nil) {
//            NSString *postString = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
//
//            NSDictionary *postParams = [NSJSONSerialization JSONObjectWithData:request.HTTPBody options:0 error:nil];
//
//            if (postParams[@"current_step"] != nil) {
//                NSString *currentStep = postParams[@"current_step"];
//                NSLog(@"Current step: %@", currentStep);
//
//                if ([currentStep isEqualToString:@"COMPLETE"]) {
//                    //chat has been completed
//                }
//            }
//            NSLog(@"%@", postString);
        }
        if ([request.URL.absoluteString containsString:@"/handler/chat_complete"]) {
            NSLog(@"%@", request.URL.path);

            NSString *path = request.URL.path;
            if (path != nil && path.length > 0) {

                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ChatCompletedNotification" object:nil userInfo:@{@"blockId": [[path stringByReplacingOccurrencesOfString:@"/handler/chat_complete" withString:@""] lastPathComponent]}];
                });

            }
        }
        if (([request.URL.host isEqualToString:config.apiHostURL.host])
            && ([request.URL.path containsString:@"type@html"] ||
                [request.URL.path containsString:@"type@chat"] ||
                [request.URL.path rangeOfString:@"i4x://.*/chat/" options:NSRegularExpressionSearch].location != NSNotFound ||
                [request.URL.path rangeOfString:@"i4x://.*/html/" options:NSRegularExpressionSearch].location != NSNotFound ||
                [[request.allHTTPHeaderFields objectForKey:@"Referer"] containsString:@"type@html"] ||
                [[request.allHTTPHeaderFields objectForKey:@"Referer"] containsString:@"type@chat"] ||
                [[request.allHTTPHeaderFields objectForKey:@"Referer"] rangeOfString:@"i4x://.*/chat/" options:NSRegularExpressionSearch].location != NSNotFound ||
                [[request.allHTTPHeaderFields objectForKey:@"Referer"] rangeOfString:@"i4x://.*/html/" options:NSRegularExpressionSearch].location != NSNotFound )) {
                return YES;
            } else if ([request.URL.path containsString:@"type@chat"] ||
                       [request.URL.path rangeOfString:@"i4x://.*/chat/" options:NSRegularExpressionSearch].location != NSNotFound ||
                       [[request.allHTTPHeaderFields objectForKey:@"Referer"] containsString:@"type@chat"] ||
                       [[request.allHTTPHeaderFields objectForKey:@"Referer"] rangeOfString:@"i4x://.*/chat/" options:NSRegularExpressionSearch].location != NSNotFound ) {
                return YES;
            } else if (([[request.allHTTPHeaderFields objectForKey:@"Referer"] containsString:@"type@html"] ||
                        [[request.allHTTPHeaderFields objectForKey:@"Referer"] rangeOfString:@"i4x://.*/html/" options:NSRegularExpressionSearch].location != NSNotFound)
                       && ([request.URL.pathExtension isEqualToString:@"jpg"] || [request.URL.pathExtension isEqualToString:@"png"])) {
                // Aloow images from other servers
                return YES;
            } else {
                return NO;
            }
    }];
    
    [EVURLCache activate];
    NetworkRequestLoader *loader = [[NetworkRequestLoader alloc] initWithSession:[NSURLSession sharedSession]];
    CachedRequestLoader *cachedLoader = [[CachedRequestLoader alloc] initWithCache:[EVURLCache sharedURLCache] loader:loader];
    [WebViewLoadingProtocol setRequestLoader:cachedLoader];
    [NSURLProtocol registerClass:[WebViewLoadingProtocol class]];
    
}

@end
