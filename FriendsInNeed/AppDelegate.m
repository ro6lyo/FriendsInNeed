//
//  AppDelegate.m
//  FriendsInNeed
//
//  Created by Milen on 21/11/15.
//  Copyright © 2015 г. Milen. All rights reserved.
//

#import "AppDelegate.h"
#import "Backendless.h"
#import "FINMapVC.h"
#import "FINMenuVC.h"
#import "FINDataManager.h"
#import "FINGlobalConstants.pch"
#import <ViewDeck/ViewDeck.h>
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>


@interface AppDelegate ()

@property (weak, nonatomic) FINMapVC *mapVC;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL r = [[FBSDKApplicationDelegate sharedInstance] application:application
                                    didFinishLaunchingWithOptions:launchOptions];
    
    [backendless initApp:BCKNDLSS_APP_ID APIKey:BCKNDLSS_IOS_API_KEY];
    [backendless.userService setStayLoggedIn:YES];
    [backendless.data mapTableToClass:@"Users" type:[BackendlessUser class]];
    
    [[Crashlytics sharedInstance] setDebugMode:YES];
    [Fabric with:@[[Crashlytics class]]];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // Override point for customization after application launch.
    FINMapVC *mapVC = [[FINMapVC alloc] initWithNibName:nil bundle:nil];
    [[UINavigationBar appearance] setBarTintColor:kCustomOrange];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    [[UINavigationBar appearance] setTranslucent:NO];
     UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:mapVC];
    
    FINMenuVC *menuVC = [[FINMenuVC alloc] initWithNibName:nil bundle:nil];
    
    CGFloat maxMenuWidth = self.window.frame.size.width - 60;
    CGFloat menuWidth = 315;
    menuWidth = menuWidth < maxMenuWidth ? menuWidth : maxMenuWidth;
    
    menuVC.preferredContentSize = CGSizeMake(menuWidth, self.window.frame.size.height);
    
    IIViewDeckController *viewDeckController = [[IIViewDeckController alloc] initWithCenterViewController:navController
                                                                                      leftViewController:menuVC];
    
    self.window.rootViewController = viewDeckController;
    [self.window makeKeyAndVisible];
    _mapVC = mapVC;
    
    
    [self registerForLocalNotifications];
    
    
    UILocalNotification *notification = [launchOptions objectForKey:@"UIApplicationLaunchOptionsLocalNotificationKey"];
    NSString *focusSignalID = [notification.userInfo objectForKey:kNotificationSignalID];
    if (focusSignalID)
    {        
        [_mapVC setFocusSignalID:focusSignalID];
    }
    
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    @try {
        [backendless initAppFault];
    }
    @catch (Fault *fault) {
        NSLog(@"didFinishLaunchingWithOptions: %@", fault);
    }
    return r;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBSDKAppEvents activateApp];
}
   
- (BOOL)application:(UIApplication *)application
                openURL:(NSURL *)url
                options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
        
        BOOL result = [[FBSDKApplicationDelegate sharedInstance] application:application
                                                                      openURL:url
                                                            sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
                                                                   annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
    
    /*Doesnt work as shown in BackendlessUser tutorial
    when this function gets called accsess token is stil nil
     so we gonna do it differently 
     */
//        FBSDKAccessToken *token = [FBSDKAccessToken currentAccessToken];
//        @try {
//            BackendlessUser *user = [backendless.userService loginWithFacebookSDK:token fieldsMapping:nil];
//            NSLog(@"USER: %@", user);
//        }
//        @catch (Fault *fault) {
//            NSLog(@"openURL: %@", fault);
//        }
        return result;
    
    }
//- (BOOL)application:(UIApplication *)application
//            openURL:(NSURL *)url
//  sourceApplication:(NSString *)sourceApplication
//         annotation:(id)annotation {
//    BOOL result = [[FBSDKApplicationDelegate sharedInstance]
//                   application:application
//                   openURL:url
//                   sourceApplication:sourceApplication
//                   annotation:annotation];
//
//    FBSDKAccessToken *token = [FBSDKAccessToken currentAccessToken];
//     NSLog(@"openURL: %@", token);
//    NSLog(result ? @"Yes" : @"No");
//
//
//    @try {
//       BackendlessUser *user = [backendless.userService loginWithFacebookSDK:token fieldsMapping:nil];
//       NSLog(@"USER: %@", user);
//    }
//    @catch (Fault *fault) {
//        NSLog(@"openURL: %@", fault);
//    }
//    return result;
//}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    NSString *focusSignalID = [notification.userInfo objectForKey:kNotificationSignalID];
    [_mapVC setFocusSignalID:focusSignalID];
}

#pragma mark - Custom methods
- (void)registerForLocalNotifications
{
    UIMutableUserNotificationCategory *reminderCategory = [UIMutableUserNotificationCategory new];
    reminderCategory.identifier = @"ReminderCategory";
    [reminderCategory setActions:nil forContext:UIUserNotificationActionContextDefault];
    
    NSSet *categories = [NSSet setWithObjects:reminderCategory, nil];
    UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    UIUserNotificationSettings *userNotificationSettings = [UIUserNotificationSettings settingsForTypes:types categories:categories];
    [[UIApplication sharedApplication] registerUserNotificationSettings:userNotificationSettings];
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [[FINDataManager sharedManager] getNewSignalsForLastLocationWithCompletionHandler:completionHandler];
}
    
    
    

@end
