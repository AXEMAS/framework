//
//  SharedStorage.h
//  axemas
//
//  Created by AXANT on 04/06/15.
//  Copyright (c) 2015 axant. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SharedStorage : NSObject

+ (void)store: (NSString*) value withKey:(NSString *) key;
+ (NSString *)getValueFrom: (NSString*) key;
+ (void)removeValueFrom: (NSString*) key;

@end
