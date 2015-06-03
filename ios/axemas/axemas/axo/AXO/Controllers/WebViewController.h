//
//  WebViewController.h
//
//  Copyright (c) 2013 AXANT. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController

@property (nonatomic, strong) IBOutlet UIWebView *webview;

+ (UIViewController*)controllerWithUrl:(NSString*)url;
+ (UIViewController*)controllerWithUrl:(NSString*)url andTitle:(NSString*)title;

@end
