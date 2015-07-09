//
//  FirstViewController.m
//  axemas
//
//  Copyright (c) 2013 AXANT. All rights reserved.
//

#import "SectionViewController.h"
#import "AXO/AXO/MBProgressHUD.h"
#import "AXO/AXO/AXOButtonFactory.h"
#import "Reachability.h"
#import "AXMSectionController.h"
#import "NavigationSectionsManager.h"
#import <objc/runtime.h>
#import "SWRevealViewController.h"
#import "SharedStorage.h"

@interface AXMWebView : UIWebView

@property (nonatomic, weak) AXMSectionController *sectionController;

-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event;
@end

@implementation AXMWebView

-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.sectionController == nil)
        return YES;
    
    return [self.sectionController isInsideWebView:point withEvent:event];
}

@end


@interface AXMDialogDelegate: NSObject <UIAlertViewDelegate>

@property (nonatomic, strong) SectionViewController *controller;
@property (nonatomic, strong) WVJBResponseCallback callback;

- (instancetype)initWithCallback:(WVJBResponseCallback)callback withController:(SectionViewController*)controller;
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

@end


@interface SectionViewController () {
    BOOL loaded;
}

@property (strong, nonatomic) NSURLRequest *request;
@property (strong, nonatomic, setter=setSectionViewController:) AXMSectionController *sectionController;
@property (strong, nonatomic) NSMutableArray *dialogDelegates;
@property (strong, nonatomic) NSString *pushAnimation;

@end



@implementation SectionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    NSString *resourceBundlePath = [[NSBundle mainBundle] pathForResource:@"axemas" ofType:@"bundle"];
    NSBundle *resourceBundle = [NSBundle bundleWithPath:resourceBundlePath];
    
    self = [super initWithNibName:@"SectionViewController" bundle:resourceBundle];
    if (self) {
        self->loaded = YES;
        self.pushAnimation = nil;
    }
    return self;
}

- (void)reachabilityChanged: (NSNotification* )note {
    Reachability* curReach = [note object];
    NSParameterAssert([curReach isKindOfClass: [Reachability class]]);
    
    if ([curReach currentReachabilityStatus] != NotReachable) {
        if ((!self->loaded) || ([self.request.HTTPMethod isEqualToString:@"GET"]))
        [self forceContentLoad];
    }
}

-(void) rightClickOnNavBarItem {
    [self.registeredSectionController navigationbarRightButtonAction];
}

+ (SectionViewController*)createWithData:(NSDictionary*)data {
    SectionViewController *viewController = [[SectionViewController alloc] initWithNibName:@"SectionViewController"
                                                                                    bundle:nil];
    
    if (data[@"toggleSidebarIcon"]) {
        SWRevealViewController *activeSidebarController = [NavigationSectionsManager activeSidebarController];
        UIBarButtonItem *revealButtonItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                             style:UIBarButtonItemStyleBordered
                                                                            target:activeSidebarController
                                                                            action:@selector(revealToggle:)];
        [AXOButtonFactory replaceNavigationButton:revealButtonItem withImage:[UIImage imageNamed:data[@"toggleSidebarIcon"]]];
        
        viewController.navigationItem.leftBarButtonItem = revealButtonItem;
        //viewController.navigationItem.leftBarButtonItem.customView.hidden=YES;
    }
    
    if (data[@"actionBarRightIcon"]) {
        UIImage* ticket_image = [UIImage imageNamed:data[@"actionBarRightIcon"]];
        CGRect frameimg = CGRectMake(0, 0, ticket_image.size.width/2, ticket_image.size.height/2);
        UIButton *rightButton = [[UIButton alloc] initWithFrame:frameimg];
        [rightButton setBackgroundImage:ticket_image forState:UIControlStateNormal];
        [rightButton addTarget:viewController action:@selector(rightClickOnNavBarItem)
             forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *rigthBarButton =[[UIBarButtonItem alloc] initWithCustomView:rightButton];
        viewController.navigationItem.rightBarButtonItem = rigthBarButton;
        viewController.navigationItem.rightBarButtonItem.customView.hidden = NO;
        
    }
    
    [viewController setupWithData:data];
    return viewController;
}

- (void)setSectionViewController:(AXMSectionController*)controller {
    self->_sectionController = controller;
    ((AXMWebView*)self.webView).sectionController = controller;
}

- (void)setupWithData:(NSDictionary*)data {
    NSString *title = data[@"title"];
    NSString *icon = data[@"icon"];
    NSString *icon_selected = data[@"icon_selected"];
    NSString *showTabBarTitle = data[@"show_tab_bar_title"];
    NSString *plainUrl = data[@"url"];
    NSString *urlWithoutParams = data[@"url"];
    NSURL *url = [NSURL URLWithString: plainUrl];
    
    if ([plainUrl rangeOfString:@"://"].location == NSNotFound) {
        NSArray* urlSplitted = [plainUrl componentsSeparatedByString: @"?"];
        urlWithoutParams = [urlSplitted objectAtIndex: 0];
        NSString *filePath = [[NSBundle mainBundle] pathForResource:urlWithoutParams ofType:nil];
        url = [NSURL fileURLWithPath:filePath];
        
        // Add query parameters back
        NSRange r = [plainUrl rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"?#"] options:0];
        if (r.location != NSNotFound) {
            NSString* queryAndOrFragment = [plainUrl substringFromIndex:r.location];
            url = [NSURL URLWithString:queryAndOrFragment relativeToURL:url];
        }
    }
    
    Class sectionControllerClass = [NavigationSectionsManager getControllerForRoute:urlWithoutParams];
    NSLog(@"Section controller: %@ -> %p", plainUrl, sectionControllerClass);
    if (sectionControllerClass != nil) {
        AXMSectionController *sectionController = [sectionControllerClass alloc];
        self.sectionController = [sectionController initWithSection:self];
    }
    
    self->loaded = NO;
    self.title = title;
    
    self.tabBarItem.image = [[UIImage imageNamed:icon]imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    self.tabBarItem.selectedImage = [[UIImage imageNamed:icon_selected]imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    if (![showTabBarTitle  isEqual: @"true"]) {
        [self.tabBarItem setTitle:@""];
        self.tabBarItem.imageInsets = UIEdgeInsetsMake(5, 0, -5, 0);
    }
    
    self.request = [NSURLRequest requestWithURL:url];
    self.pushAnimation = data[@"animation"];
}

- (void)forceContentLoad {
    self->loaded = NO;
    self.webView.hidden = YES;
    [MBProgressHUD hideHUDForView:self.view animated:NO];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    if (self.sectionController) {
        [self.sectionController sectionWillLoad];
    }
    
    [self.webView loadRequest:self.request];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.webView.scrollView.bounces = NO;
    
    if(!self.webView.scalesPageToFit){
        [self removeWebViewDoubleTapGestureRecognizer:self.webView];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    if (!self->loaded)
        [self forceContentLoad];
    
    //Call sectionViewWillAppear
    if (self.sectionController) {
        [self.sectionController sectionViewWillAppear];
    }
}

- (void)removeWebViewDoubleTapGestureRecognizer:(UIView *)view
{
    for (UIGestureRecognizer *recognizer in [view gestureRecognizers]) {
        if ([recognizer isKindOfClass:[UITapGestureRecognizer class]] && [(UITapGestureRecognizer *)recognizer numberOfTapsRequired] == 2) {
            [view removeGestureRecognizer:recognizer];
        }
    }
    for (UIView *subview in view.subviews) {
        [self removeWebViewDoubleTapGestureRecognizer:subview];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if (![self.title length])
        self.title = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    
    [self.webView stringByEvaluatingJavaScriptFromString:
     [NSString stringWithFormat:@"document.systemVersion = %f", [[[UIDevice currentDevice] systemVersion] floatValue]]];
    
    if (!self->loaded) {
        self->loaded = YES;
        
        if (self.sectionController) {
            [self.sectionController sectionDidLoad];
        }
        
        self.webView.hidden = NO;
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        
        [self.bridge callHandler:@"ready" data:@{@"url": self.request.URL.absoluteString} responseCallback:^(id responseData) {
            NSLog(@"Page handled ready event with: %@", responseData);
        }];
    }
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType != UIWebViewNavigationTypeLinkClicked)
    return YES;
    
    if ([request.URL.absoluteString isEqualToString:self.request.URL.absoluteString])
    return NO;
    
    NSDictionary *data = @{@"title":@"", @"url":request.URL.absoluteString};
    SectionViewController *subSection = [SectionViewController createWithData:data];
    [self.navigationController pushViewController:subSection animated:YES];
    return NO;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    self.webView.suppressesIncrementalRendering = YES;
    self.dialogDelegates = [[NSMutableArray alloc] init];
    
    self.bridge = [WebViewJavascriptBridge bridgeForWebView:self.webView webViewDelegate:self handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"Received message from javascript: %@", data);
        responseCallback(nil);
    }];
    [self.bridge registerHandler:@"showProgressHUD" handler:^(id none, WVJBResponseCallback responseCallback) {
        [MBProgressHUD showHUDAddedTo:[NavigationSectionsManager activeController].view animated:YES];
        responseCallback(nil);
    }];
    [self.bridge registerHandler:@"hideProgressHUD" handler:^(id none, WVJBResponseCallback responseCallback) {
        [MBProgressHUD hideHUDForView:[NavigationSectionsManager activeController].view animated:YES];
        responseCallback(nil);
    }];
    [self.bridge registerHandler:@"goto" handler:^(id data, WVJBResponseCallback responseCallback) {
        [NavigationSectionsManager goto:data animated:YES];
        responseCallback(nil);
    }];
    [self.bridge registerHandler:@"gotoFromSidebar" handler:^(id data, WVJBResponseCallback responseCallback) {
        [NavigationSectionsManager goto:data animated:NO];
        [[NavigationSectionsManager activeSidebarController] revealToggleAnimated:YES];
        responseCallback(nil);
    }];
    
    [self.bridge registerHandler:@"storeData" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSDictionary * dataDict = (NSDictionary*)data;
        NSLog(@"storeData: %@",dataDict);
        [SharedStorage store:[dataDict objectForKey:@"value"] withKey:[dataDict objectForKey:@"key"]];
        responseCallback(nil);
    }];
        
    [self.bridge registerHandler:@"fetchData" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSString * key = (NSString*) data;
        NSLog(@"fetchData: %@",key);

        NSMutableDictionary *mutableParameters = [[NSMutableDictionary alloc] init];
        NSString *value = [SharedStorage getValueFrom:key];
        if (value) {
            [mutableParameters setObject:value forKey:key];
        } else {
            [mutableParameters setObject:@"" forKey:key];
        }
        responseCallback(mutableParameters);
    }];
    
    [self.bridge registerHandler:@"removeData" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSString * key = (NSString*)data;
        NSLog(@"removeData: %@", key);
        
        [SharedStorage removeValueFrom:key];
        responseCallback(nil);
    }];
    [self.bridge registerHandler:@"dialog" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSDictionary *dialogInfo = (NSDictionary*)data;
        
        NSArray *buttons = data[@"buttons"];
        NSString *firstButton = buttons.count >= 1 ? buttons[0] : nil;
        NSString *secondButton = buttons.count >= 2 ? buttons[1] : nil;
        NSString *thirdButton = buttons.count >= 3 ? buttons[2] : nil;
        
        AXMDialogDelegate *dialogDelegate = [[AXMDialogDelegate alloc] initWithCallback:responseCallback
                                                                         withController:self];
        [self.dialogDelegates addObject:dialogDelegate];
        
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:dialogInfo[@"title"]
                                                         message:[NSString stringWithFormat:@"%@", dialogInfo[@"message"]]
                                                        delegate:dialogDelegate
                                               cancelButtonTitle:firstButton
                                               otherButtonTitles:secondButton,
                               thirdButton,
                               nil
                               ];
        [alert show];
    }];
    
    
}

- (id)registeredSectionController {
    return self.sectionController;
}

- (NSString*)requestedNavigationAnimation {
    return self.pushAnimation;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end


@implementation AXMDialogDelegate

- (instancetype)initWithCallback:(WVJBResponseCallback)callback withController:(SectionViewController*)controller {
    self = [super init];
    if (self) {
        self.controller = controller;
        self.callback = callback;
    }
    return self;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    //self.callback(@{@"button": [NSNumber numberWithInt:buttonIndex]});
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    //Dismiss alert and spinner is present dismiss spinner
    [MBProgressHUD hideHUDForView:[NavigationSectionsManager activeController].view animated:YES];
    
    self.callback(@{@"button": [NSNumber numberWithInt:buttonIndex]});
    [self.controller.dialogDelegates removeObject:self];
}

@end
