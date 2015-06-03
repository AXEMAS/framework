//
//  AXO.h
//  AXO
//
//  Created by Alessandro Molina on 2/7/13.
//  Copyright (c) 2013 AXANT. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSDictionary*(^AXOScheduledActivityCallback)(id, NSDictionary *info);

@interface AXOScheduledActivity : NSObject

- (id)init;
- (void)fireAndForget;
- (void)schedule:(NSTimeInterval)seconds;
- (void)stop;
- (void)enableSpinner;

- (void)registerOnComplete:(AXOScheduledActivityCallback)callback;
- (void)registerAction:(AXOScheduledActivityCallback)callback;

//Provided by [AXO attributize]
- (id)get:(NSString*)name;
- (void)set:(NSString*)name toValue:(id)value;

@end
