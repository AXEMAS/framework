//
//  WebViewController.m
//
//  Copyright (c) 2013 AXANT. All rights reserved.
//

#import "WebViewController.h"
#import "MBProgressHUD.h"

@interface WebViewController ()

@property (nonatomic, strong) NSURLRequest *request;

@end


@implementation WebViewController

+ (UIViewController*)controllerWithUrl:(NSString*)url {
    return [self controllerWithUrl:url andTitle:@""];
}

+ (UIViewController*)controllerWithUrl:(NSString*)url andTitle:(NSString*)title {
    NSString *resourceBundlePath = [[NSBundle mainBundle] pathForResource:@"AXOResources" ofType:@"bundle"];
    NSBundle *resourceBundle = [NSBundle bundleWithPath:resourceBundlePath];
    
    WebViewController *controller = [[WebViewController alloc] initWithNibName:@"WebViewController" bundle:resourceBundle];
    controller.request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    controller.title = title;
    return controller;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [self.webview loadRequest:self.request];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [MBProgressHUD hideHUDForView:self.view animated:NO];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                     message:@"Unable to load content, please try again later."
                                                    delegate:nil
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles:nil];
    [alert show];
}

@end
