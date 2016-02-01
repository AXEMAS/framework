//
//  NavigationSectionsManager.h
//  axemas
//
//  Copyright (c) 2013 AXANT. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SectionViewController.h"

@interface NavigationSectionsManager : NSObject

+ (UINavigationController*)makeTabController:(NSDictionary*)data;
+ (UIViewController*)makeApplicationRootController:(NSArray*)tabs;
+ (UIViewController*)makeApplicationRootController:(NSArray*)tabs withSidebar:(NSDictionary*)sidebarData;
+ (UINavigationController*)activeNavigationController;
+ (UIViewController*)activeController;
+ (id)activeSidebarController;
+ (SectionViewController*)sidebarSectionController;
+ (void) setSidebarButtonVisibility:(BOOL)visible;
+ (void)goto:(NSDictionary*)data animated:(BOOL)animated;
+ (void)pushController:(UIViewController*)controller animated:(BOOL)animated;

+ (void)registerDefaultController:(Class)controllerClass;
+ (void)registerController:(Class)controllerClass forRoute:(NSString*)path;
+ (Class)getControllerForRoute:(NSString*)path;


+ (void) showProgressDialog;
+ (void) hideProgressDialog;

+ (void)store: (NSString*) value withKey:(NSString *) key;
+ (NSString *)getValueFrom: (NSString*) key;
+ (void)removeValueFrom: (NSString*) key;

@end
