#import "MTNotifications.h"

static MTNotifications *notification_ = nil;

@interface MTNotifications ()

- (NSNotificationCenter*)notificationCenter;
- (void)performTriggerNotification:(NSDictionary*)eventInfo;
+ (MTNotifications*)instance;

@end

@implementation MTNotifications

+ (MTNotifications*)instance {
    if (notification_ == nil)
        notification_ = [MTNotifications new];
    return notification_;
}

- (void)performTriggerNotification:(NSDictionary*)eventInfo {
    [self.notificationCenter postNotificationName:[eventInfo objectForKey:@"event"]
                                           object:[eventInfo objectForKey:@"object"]];
}


+ (void)triggerNotification:(NSString*)event withObject:(id)object {
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    [data setObject:event forKey:@"event"];
    if (object)
        [data setObject:object forKey:@"object"];
    
    [[MTNotifications instance] performSelectorOnMainThread:@selector(performTriggerNotification:)
                                                 withObject:data
                                              waitUntilDone:NO];
}

- (NSNotificationCenter*)notificationCenter {
    return [NSNotificationCenter defaultCenter];
}

@end