//
//  FirstViewController.h
//  axemas
//
//  Copyright (c) 2013 AXANT. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WebViewJavascriptBridge.h"


@interface SectionViewController : UIViewController <UIWebViewDelegate>

@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) WebViewJavascriptBridge *bridge;

- (id)registeredSectionController;
- (void)setupWithData:(NSDictionary*)data;
+ (SectionViewController*)createWithData:(NSDictionary*)data;
+ (NSString*)activeSidebarIconName;
- (void)forceContentLoad;
- (NSString*)requestedNavigationAnimation;

@end
