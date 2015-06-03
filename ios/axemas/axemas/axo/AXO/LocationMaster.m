//
//  LocationMaster.m
//  AXO
//
//  Copyright (c) 2014 AXANT. All rights reserved.
//

#import "LocationMaster.h"
#import <UIKit/UIKit.h>
#import "AXO.h"
#import "MTNotifications.h"

NSString *const LocationMasterGotNewLocation = @"LocationMaster:GotNewLocation";
NSString *const LocationMasterRequestNewLocation = @"LocationMaster:RequestNewLocation";

@interface LocationMaster () <CLLocationManagerDelegate> {
    float locationAge;
    CLLocationAccuracy precision;
    bool running;
}

@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation LocationMaster

- (id)init {
    self = [super init];
    if (!self)
        return nil;
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self->locationAge = 5;
    self->precision = kCLLocationAccuracyHundredMeters;
    self->running = NO;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8)
        [self.locationManager requestAlwaysAuthorization];
    
    NSNotificationCenter *notifycenter = [NSNotificationCenter defaultCenter];
    [notifycenter addObserver:self
                     selector:@selector(locationManagerForegroundMode)
                         name:UIApplicationDidBecomeActiveNotification
                       object:nil];
    
    [notifycenter addObserver:self
                     selector:@selector(locationManagerBackgroundMode)
                         name:UIApplicationDidEnterBackgroundNotification
                       object:nil];
    
    [notifycenter addObserver:self
                     selector:@selector(requestNewLocation)
                         name:LocationMasterRequestNewLocation
                       object:nil];
    
    return self;
}

- (void)setLocationAge:(float)seconds withPrecision:(CLLocationAccuracy)accurancy {
    self->locationAge = seconds;
    self->precision = accurancy;
}

- (void)start {
    self->running = YES;
    [self.locationManager startUpdatingLocation];
}

- (void)stop {
    self->running = NO;
    [self.locationManager stopUpdatingLocation];
    [self.locationManager stopMonitoringSignificantLocationChanges];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if (!self->running)
        return;
    
    CLLocation* location = [locations lastObject];
    NSTimeInterval howRecent = [location.timestamp timeIntervalSinceNow];
    if ((abs(howRecent) >= self->locationAge) || (location.horizontalAccuracy > self->precision)) {
        [self.locationManager startUpdatingLocation];
        return;
    }
    
    NSDictionary *myDict = @{
         @"latitude": [NSNumber numberWithDouble:location.coordinate.latitude],
         @"longitude": [NSNumber numberWithDouble:location.coordinate.longitude]
    };
    
    NSLog(@"LocationMaster Valid Location -> latitude %+.6f, longitude %+.6f\n",
          location.coordinate.latitude, location.coordinate.longitude);
    
    [self.locationManager stopUpdatingLocation];
    [self.locationManager startMonitoringSignificantLocationChanges];
    
    [MTNotifications triggerNotification:LocationMasterGotNewLocation withObject:myDict];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"LocationMaster didFailWithError : %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusNotDetermined)
        return;
    
    if (status != kCLAuthorizationStatusAuthorizedAlways) {
        [AXO alertWithTitle:@"Location Services are disabled"
                       body:@"This application requires location services but didn't get permissions to use them"];
    }
}

- (void)requestNewLocation {
    [self.locationManager startUpdatingLocation];
}

-(void)locationManagerForegroundMode {
    if (!self->running)
        return;
    
    NSLog(@"LocationMaster - Entering Foreground");
    [self.locationManager stopMonitoringSignificantLocationChanges];
    [self.locationManager startUpdatingLocation];
}

-(void)locationManagerBackgroundMode {
    if (!self->running)
        return;
    
    NSLog(@"LocationMaster - Going Background");
    [self.locationManager stopUpdatingLocation];
    [self.locationManager startMonitoringSignificantLocationChanges];
}

@end
