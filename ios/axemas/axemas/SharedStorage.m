//
//  SharedStorage.m
//  axemas
//
//  Created by AXANT on 04/06/15.
//  Copyright (c) 2015 axant. All rights reserved.
//

#import "SharedStorage.h"

@implementation SharedStorage

+ (void)store: (NSString*) value withKey:(NSString *) key{
    NSUserDefaults *defaultsUsers = [NSUserDefaults standardUserDefaults];
    [defaultsUsers setObject:value forKey:key];
    [defaultsUsers synchronize];
}

+ (NSString *)getValueFrom: (NSString*) key{
    NSUserDefaults *defaultsUsers = [NSUserDefaults standardUserDefaults];
    return [defaultsUsers objectForKey:key];
}

+ (void)removeValueFrom: (NSString*) key{
    NSUserDefaults *defaultsUsers = [NSUserDefaults standardUserDefaults];
    [defaultsUsers removeObjectForKey:key];
    [defaultsUsers synchronize];
}

@end
