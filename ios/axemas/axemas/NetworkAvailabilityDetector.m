//
//  NetworkAvailabilityDetector.m
//  axemas
//
//  Copyright (c) 2013 AXANT. All rights reserved.
//

#import "NetworkAvailabilityDetector.h"
#import "Reachability.h"
#import <UIKit/UIAlertView.h>

@interface NetworkAvailabilityDetector ()

@property (strong, nonatomic) Reachability *reachability;
@property (strong, nonatomic) UIAlertView *reachabilityAlert;

@end

@implementation NetworkAvailabilityDetector

- (id)init {
    if ( self = [super init] ) {    
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object: nil];
        
        self.reachability = [Reachability reachabilityForInternetConnection];
        [self checkReachability];
        [self.reachability startNotifier];
    }
    return self;
}

- (void)reachabilityChanged: (NSNotification* )note
{
    Reachability* curReach = [note object];
    NSParameterAssert([curReach isKindOfClass: [Reachability class]]);
    NetworkStatus netStatus = [curReach currentReachabilityStatus];
    switch (netStatus)
    {
        case ReachableViaWWAN:
        {
            [self dismissReachabilityAlert];
            break;
        }
        case ReachableViaWiFi:
        {
            [self dismissReachabilityAlert];
            break;
        }
        case NotReachable:
        {
            [self showReachabilityAlert];
            break;
        }
    }
}

- (void)checkReachability {
    NetworkStatus netStatus = [self.reachability currentReachabilityStatus];
    switch (netStatus)
    {
        case ReachableViaWWAN:
        {
            [self dismissReachabilityAlert];
            break;
        }
        case ReachableViaWiFi:
        {
            [self dismissReachabilityAlert];
            break;
        }
        case NotReachable:
        {
            [self showReachabilityAlert];
            break;
        }
    }
}

- (void)showReachabilityAlert{
    if (self.reachabilityAlert == nil) {
        self.reachabilityAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Available Connection", nil)
                                                            message:NSLocalizedString(@"This application requires a working internet connection, "
                                                                                       "the following dialog will disappear when connection is available", nil)
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles: nil];
        [self.reachabilityAlert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
    }
}

- (void)dismissReachabilityAlert{
    if (self.reachabilityAlert != nil){
        [self.reachabilityAlert dismissWithClickedButtonIndex:0 animated:YES];
        self.reachabilityAlert=nil;
    }
}


@end
