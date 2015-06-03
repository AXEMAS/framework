//
//  P2MNotifications.h
//  AXO
//
//  Copyright (c) 2013 Axant. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MTNotifications : NSObject

+ (void)triggerNotification:(NSString*)event withObject:(id)object;

@end