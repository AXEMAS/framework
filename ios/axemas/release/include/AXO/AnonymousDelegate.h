//
//  AnonymousDelegate.h
//  AXO
//
//  Copyright (c) 2014 AXANT. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AnonymousDelegate : NSObject

- (void)setBlock:(void*)block forMethod:(SEL)selector withSignature:(NSString*)signature;

@end
