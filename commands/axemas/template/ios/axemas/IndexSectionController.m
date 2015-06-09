//
//  HomeSectionController.m
//  axemas
//
//  Created by Alessandro Molina on 4/10/14.
//  Copyright (c) 2014 AXANT. All rights reserved.
//

#import "IndexSectionController.h"
#import "WebViewJavascriptBridge.h"
#import "NavigationSectionsManager.h"
#import "MapViewController.h"
#import "NativeViewController.h"
#import "SWRevealViewController.h"

@implementation IndexSectionController

- (void)sectionWillLoad {
    [self.section.bridge registerHandler:@"open-sidebar-from-native" handler:^(id data, WVJBResponseCallback responseCallback) {
        [[NavigationSectionsManager activeSidebarController] revealToggleAnimated:YES];
        
        if (responseCallback) {
            responseCallback(nil);
        }
    }];
    
    [self.section.bridge registerHandler:@"send-device-name-from-native-to-js" handler:^(id data, WVJBResponseCallback responseCallback) {
        
        NSDictionary * datum  = @{@"name":[[UIDevice currentDevice] name],
                                  @"other":[[UIDevice currentDevice] systemVersion]};
        
        [self.section.bridge callHandler:@"display-device-model" data:datum responseCallback:^(id responseData) {
            // empty
        }];

        
        if (responseCallback) {
            responseCallback(nil);
        }
    }];
    
    [self.section.bridge registerHandler:@"push-native-section" handler:^(id data, WVJBResponseCallback responseCallback) {
        
        [NavigationSectionsManager pushController:[[NativeViewController alloc] init] animated:YES];
        
        
        if (responseCallback) {
            responseCallback(nil);
        }
    }];
}

@end
