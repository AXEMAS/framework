//
//  AppDelegate.m
//  axemas
//
//  Copyright (c) 2013 AXANT. All rights reserved.
//

#import "AppDelegate.h"
#import "NavigationSectionsManager.h"
#import "NetworkAvailabilityDetector.h"
#import "IndexSectionController.h"

@interface AppDelegate ()

@property (nonatomic, strong) NetworkAvailabilityDetector *networkDetector;

@end

@implementation AppDelegate

//TODO: Aggiungere Reachability per popup quando rete non disponibile

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.networkDetector = [[NetworkAvailabilityDetector alloc] init];
    
    [NavigationSectionsManager registerController:[IndexSectionController class] forRoute:@"www/index.html"];

    
    self.rootController = [NavigationSectionsManager makeApplicationRootController:@[@{@"url":@"www/index.html",
                                                                                       @"title":@"Home",
                                                                                       @"toggleSidebarIcon":@"slide_icon"}]
                                                                       withSidebar:@{@"url":@"www/sidebar.html"}];

    self.window.rootViewController = self.rootController;
    [self.window makeKeyAndVisible];
        
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
}
*/

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed
{
}
*/

@end
