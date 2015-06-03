//
//  LocationMaster.h
//  AXO
//
//  Copyright (c) 2014 AXANT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

extern NSString *const LocationMasterGotNewLocation;
extern NSString *const LocationMasterRequestNewLocation;


@interface LocationMaster : NSObject

- (id)init;
- (void)setLocationAge:(float)seconds withPrecision:(CLLocationAccuracy)precision;
- (void)start;
- (void)stop;

@end
