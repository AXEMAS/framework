//
//  NavigationSectionsManager.m
//  axemas
//
//  Copyright (c) 2013 AXANT. All rights reserved.
//

#import "NavigationSectionsManager.h"
#import "SectionViewController.h"
#import "SWRevealViewController.h"
#import "AXO/AXO/MBProgressHUD.h"
#import "NavigationControllerCustomAnimations.h"

@interface SectionsManagerStatus : NSObject<UINavigationControllerDelegate>

@property (strong, nonatomic) SWRevealViewController *sidebarController;
@property (strong, nonatomic) Class defaultSectionController;
@property (strong, nonatomic) NSMutableDictionary *sectionControllers;
@end

static SectionsManagerStatus *statusInstance = nil;

@implementation SectionsManagerStatus

- (instancetype)init {
    self = [super init];
    if (self) {
        self.sectionControllers = [[NSMutableDictionary alloc] init];
        self.sidebarController = nil;
    }
    return self;
}

+ (SectionsManagerStatus *)sharedInstance {
    if (statusInstance == nil) {
        statusInstance = [[SectionsManagerStatus alloc] init];
    }
    return statusInstance;
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                    animationControllerForOperation:(UINavigationControllerOperation)operation
                                                 fromViewController:(UIViewController*)fromVC
                                                   toViewController:(UIViewController*)toVC {
    if ((operation == UINavigationControllerOperationPop) && [fromVC isKindOfClass:[SectionViewController class]]) {
        SectionViewController *viewController = (SectionViewController*)fromVC;
        if ([viewController.requestedNavigationAnimation isEqualToString:@"fade"])
            return [FadePopAnimator new];
        else if ([viewController.requestedNavigationAnimation isEqualToString:@"slidein"])
            return [SlidePopAnimator new];
    }
    else if ((operation == UINavigationControllerOperationPush) && [toVC isKindOfClass:[SectionViewController class]]) {
        SectionViewController *viewController = (SectionViewController*)toVC;
        if ([viewController.requestedNavigationAnimation isEqualToString:@"fade"])
            return [FadePushAnimator new];
        else if ([viewController.requestedNavigationAnimation isEqualToString:@"slidein"])
            return [SlidePushAnimator new];
    }

    return nil;
}

@end


@implementation NavigationSectionsManager

+ (UINavigationController*)makeTabController:(NSDictionary*)data {
    SectionViewController *viewController = [SectionViewController createWithData:data];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    navController.delegate = [SectionsManagerStatus sharedInstance];
    return navController;
}

+ (void)goto:(NSDictionary*)data animated:(BOOL)animated {
    BOOL replaceView = false;
    SectionViewController *subSection = [SectionViewController createWithData:data];
    
    if([data objectForKey:@"stackMaintainedElements"] != nil){
        replaceView = [self popViewsMaintaining: [[data objectForKey:@"stackMaintainedElements"] intValue]];
    }
    if([data objectForKey:@"stackPopElements"] != nil)
        replaceView = [self popViews: [[data objectForKey:@"stackPopElements"] intValue]];
    
    if(replaceView)
        [[NavigationSectionsManager activeNavigationController] setViewControllers:@[subSection] animated:NO];
    else{   //if from sidebar
        [[NavigationSectionsManager activeNavigationController] pushViewController:subSection animated:animated];
    }
}

+ (void)pushController:(UIViewController*)controller animated:(BOOL)animated{
    [[NavigationSectionsManager activeNavigationController] pushViewController:controller animated:animated];
}

+ (UIViewController*)makeApplicationRootController:(NSArray*)tabs {
    return [NavigationSectionsManager makeApplicationRootController:tabs withSidebar:nil];
}

+ (UIViewController*)makeApplicationRootController:(NSArray*)tabs withSidebar:(NSDictionary*)sidebarData {
    UIViewController *mainApplicationController = nil;
    NSArray *requestedTabs = tabs;
    if (requestedTabs.count > 1) {
        UITabBarController *tabBarController = [[UITabBarController alloc] init];
        NSMutableArray *controllersForTabs = [[NSMutableArray alloc] initWithCapacity:[requestedTabs count]];
        for (NSDictionary *tabData  in requestedTabs) {
            UINavigationController *navController = [NavigationSectionsManager makeTabController:tabData];
            [controllersForTabs addObject:navController];
        }
        
        tabBarController.viewControllers = controllersForTabs;
        mainApplicationController = tabBarController;
    }
    else {
        NSDictionary *rootViewData = [requestedTabs objectAtIndex:0];
        mainApplicationController = [NavigationSectionsManager makeTabController:rootViewData];
    }
    
    if (sidebarData != nil) {
        SWRevealViewController *sidebarControler = [[SWRevealViewController alloc] init];
        [SectionsManagerStatus sharedInstance].sidebarController = sidebarControler;
        
        sidebarControler.rearViewController = [SectionViewController createWithData:sidebarData];
        sidebarControler.frontViewController = mainApplicationController;
        sidebarControler.toggleAnimationType = SWRevealToggleAnimationTypeEaseOut;  // used for iOS6 compatibility
        sidebarControler.rearViewRevealOverdraw = 0;
        
        mainApplicationController = sidebarControler;
    }
    
    return mainApplicationController;
}

+ (UINavigationController*)activeNavigationController {
    UIWindow *mainWindow = [[UIApplication sharedApplication] keyWindow];
    UIViewController *rootController = mainWindow.rootViewController;
    
    if ([rootController isKindOfClass:[SWRevealViewController class]])
        rootController = ((SWRevealViewController*)rootController).frontViewController;
    
    if ([rootController isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabController = (UITabBarController*)rootController;
        return (UINavigationController*)tabController.selectedViewController;
    }
    else {
        return (UINavigationController*)rootController;
    }
}

+ (UIViewController*)activeController {
    UINavigationController *navController = [NavigationSectionsManager activeNavigationController];
    return navController.topViewController;
}

+ (void)registerDefaultController:(Class)controllerClass {
    [SectionsManagerStatus sharedInstance].defaultSectionController = controllerClass;
}

+ (void)registerController:(Class)controllerClass forRoute:(NSString*)path {
    [SectionsManagerStatus sharedInstance].sectionControllers[path] = controllerClass;
}

+ (Class)getControllerForRoute:(NSString*)path {
    id controller = [SectionsManagerStatus sharedInstance].sectionControllers[path];
    
    if (controller == nil)
        controller = [SectionsManagerStatus sharedInstance].defaultSectionController;
    
    return controller;
}

+ (id)activeSidebarController {
    return [SectionsManagerStatus sharedInstance].sidebarController;
}

+ (BOOL) popViews:(NSInteger) viewsToPop{
    NSArray *viewStack = [[NavigationSectionsManager activeNavigationController] viewControllers];
    long limit = MIN(MAX(0, viewsToPop), [viewStack count]);
    BOOL replaceView = ([viewStack count] - limit ) < 1;
    for (int i = 0; i < limit; i++)
        [[NavigationSectionsManager activeNavigationController] popViewControllerAnimated:NO];
    return replaceView;
}

+ (BOOL) popViewsMaintaining:(NSInteger) viewsToMaintain{
    NSArray *viewStack = [[NavigationSectionsManager activeNavigationController] viewControllers];
    BOOL replaceView = viewsToMaintain < 1;
    long count = [viewStack count];
    while (count > MAX(1, viewsToMaintain)){
        [[NavigationSectionsManager activeNavigationController] popViewControllerAnimated:NO];
        count--;
    }
    return replaceView;
}

+ (void) showProgressDialog{
    [MBProgressHUD showHUDAddedTo:[NavigationSectionsManager activeController].view animated:YES];
}

+ (void) hideProgressDialog{
    [MBProgressHUD hideHUDForView:[NavigationSectionsManager activeController].view animated:YES];
}

+ (void)store: (NSString*) value withKey:(NSString *) key{
    NSUserDefaults *defaultsUsers = [NSUserDefaults standardUserDefaults];
    [defaultsUsers setObject:value forKey:key];
    [defaultsUsers synchronize];
}

+ (NSString *)getValueFrom: (NSString*) key{
    NSUserDefaults *defaultsUsers = [NSUserDefaults standardUserDefaults];
    return [defaultsUsers objectForKey:key];
}

+ (void)removeValueFrom: (NSString*) key{
    NSUserDefaults *defaultsUsers = [NSUserDefaults standardUserDefaults];
    [defaultsUsers removeObjectForKey:key];
    [defaultsUsers synchronize];
}

@end
