//
//  AnonymousDelegate.m
//  AXO
//
//  Copyright (c) 2014 AXANT. All rights reserved.
//

#import <objc/runtime.h>
#import "AnonymousDelegate.h"

@implementation AnonymousDelegate

- (void)setBlock:(void*)block forMethod:(SEL)selector withSignature:(NSString*)signature {
    Class selfClass	= self.class;
    Class subclass = selfClass;
    
    NSString *prefix = [NSString stringWithFormat:@"AnonymousDelegate_%p_", self];
    NSString *className = [NSString stringWithUTF8String:object_getClassName(self)];
        
    if (![className hasPrefix:prefix])	{
        NSString *name = [NSString stringWithFormat:@"%@%@", prefix, className];
        subclass = (Class)objc_allocateClassPair(selfClass, name.UTF8String, 0);
            
        if (subclass == NULL) {
            NSLog(@"AnonymousDelegate - Could not create subclass");
            return;
        }
        
        objc_registerClassPair(subclass);
        object_setClass(self,  subclass);
    }
    
    Method m = class_getInstanceMethod(selfClass, selector);
    char const *methodSignature = NULL;
    if (m != NULL) {
        methodSignature = method_getTypeEncoding(m);
    }
    else {
        if (signature == nil) {
            NSLog(@"AnonymousDelegate - SIGNATURE IS REQUIRED WHEN ADDING A NEW METHOD");
            return;
        }
        methodSignature = [signature UTF8String];
    }
    
    NSLog(@"AnonymousDelegate - method %@ with signature %s", NSStringFromSelector(selector), methodSignature);
    IMP imp = imp_implementationWithBlock((__bridge id)block);
    class_addMethod(subclass, selector, imp, methodSignature);
}

@end
