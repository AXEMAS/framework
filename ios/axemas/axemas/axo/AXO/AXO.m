//
//  AttributesMaster.m
//  AXO
//
//  Created by Alessandro Molina on 2/7/13.
//  Copyright (c) 2013 AXANT. All rights reserved.
//

#import <objc/runtime.h>
#import "AXO.h"
#import "MTNotifications.h"

static char ASSOCIATED_PROPERTIES_KEY;

id Attributes_get(id self, SEL _cmd, NSString *name) {
    NSMutableDictionary *properties = objc_getAssociatedObject(self, &ASSOCIATED_PROPERTIES_KEY);
    return [properties objectForKey:name];
}

void Attributes_set(id self, SEL _cmd, NSString *name, id value) {
    NSMutableDictionary *properties = objc_getAssociatedObject(self, &ASSOCIATED_PROPERTIES_KEY);
    [properties setObject:value forKey:name];
}

@implementation AXO

+ (void)attributize:(id)obj {
    if (!objc_getAssociatedObject(obj, &ASSOCIATED_PROPERTIES_KEY)) {
        NSMutableDictionary *properties = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(obj, &ASSOCIATED_PROPERTIES_KEY, properties, OBJC_ASSOCIATION_RETAIN);
    }
    
    if (![obj respondsToSelector:@selector(get:)]) {
        class_addMethod([obj class], @selector(get:), (IMP)Attributes_get, "@@:@");
        class_addMethod([obj class], @selector(set:toValue:), (IMP)Attributes_set, "v@:@@");
    }
}


+ (void)setAttribute:(NSString*)name toValue:(id)value forObject:(id)obj {
    [AXO attributize:obj];
    Attributes_set(obj, nil, name, value);
}

+ (id)getAttribute:(NSString*)name forObject:(id)obj {
    [AXO attributize:obj];
    return Attributes_get(obj, nil, name);
}

+ (NSString*)escapeStringForRequest:(NSString*)url {
    NSString *u = (__bridge_transfer NSString *) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                         (__bridge  CFStringRef)url,
                                                                                         NULL,
                                                                                         CFSTR(":/?#[]@!$&’()+,;="),
                                                                                         kCFStringEncodingUTF8);
    return u;
}

+ (BOOL)isNull:(id)obj {
    return ((obj != nil) && ([NSNull null] != (NSNull*)obj));
}

+ (id)appDelegate {
    UIApplication *app = [UIApplication sharedApplication];
    return app.delegate;
}

+ (id)appWindow {
    UIApplication *app = [UIApplication sharedApplication];
    return app.delegate.window;
}

+ (void)triggerNotification:(NSString*)event withObject:(id)object {
    [MTNotifications triggerNotification:event withObject:object];
}

+ (id)controllerFromMainStoryboard:(NSString*)controllerId {
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    return [storyBoard instantiateViewControllerWithIdentifier:controllerId];
}

+ (void)alertWithTitle:(NSString*)title body:(NSString*)body {
    [AXO alertWithTitle:title body:body button:nil delegate:nil];
}

+ (void)alertWithTitle:(NSString*)title body:(NSString*)body delegate:(id)delegate {
    [AXO alertWithTitle:title body:body button:nil delegate:delegate];
}

+ (void)alertWithTitle:(NSString*)title body:(NSString*)body button:(NSDictionary*)button delegate:(id)delegate {
    UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:title
                                                     message:body
                                                    delegate:delegate
                                           cancelButtonTitle:[button objectForKey:@"cancelButtonTitle"] ? [button objectForKey:@"cancelButtonTitle"] : @"Ok"
                                           otherButtonTitles:nil];
    for (NSString *btn in [button objectForKey:@"otherButtonTitles"]){
        [alert addButtonWithTitle:btn];
    }
    [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
}


+ (UIImage *)embeddedImageNamed:(NSString *)name fromPool:(NSDictionary*)pool{
    if ([UIScreen mainScreen].scale == 2)
        name = [name stringByAppendingString:@"@2x"];
    

    NSString *base64String = [pool objectForKey:name];
    UIImage *rawImage = [UIImage imageWithData:[AXO decodeBase64:base64String]];
    return [UIImage imageWithCGImage:rawImage.CGImage
                               scale:[UIScreen mainScreen].scale
                         orientation:UIImageOrientationUp];
}

+ (NSData *)decodeBase64:(NSString *)string {
    const char lookup[] = {
        99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
        99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
        99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 62, 99, 99, 99, 63,
        52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 99, 99, 99, 99, 99, 99,
        99,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
        15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 99, 99, 99, 99, 99,
        99, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
        41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 99, 99, 99, 99, 99
    };
    
    NSData *inputData = [string dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    long long inputLength = [inputData length];
    const unsigned char *inputBytes = [inputData bytes];
    
    long long maxOutputLength = (inputLength / 4 + 1) * 3;
    NSMutableData *outputData = [NSMutableData dataWithLength:maxOutputLength];
    unsigned char *outputBytes = (unsigned char *)[outputData mutableBytes];
    
    int accumulator = 0;
    long long outputLength = 0;
    unsigned char accumulated[] = {0, 0, 0, 0};
    for (long long i = 0; i < inputLength; i++) {
        unsigned char decoded = lookup[inputBytes[i] & 0x7F];
        if (decoded != 99) {
            accumulated[accumulator] = decoded;
            if (accumulator == 3) {
                outputBytes[outputLength++] = (accumulated[0] << 2) | (accumulated[1] >> 4);
                outputBytes[outputLength++] = (accumulated[1] << 4) | (accumulated[2] >> 2);
                outputBytes[outputLength++] = (accumulated[2] << 6) | accumulated[3];
            }
            accumulator = (accumulator + 1) % 4;
        }
    }
    
    //handle left-over data
    if (accumulator > 0) outputBytes[outputLength] = (accumulated[0] << 2) | (accumulated[1] >> 4);
    if (accumulator > 1) outputBytes[++outputLength] = (accumulated[1] << 4) | (accumulated[2] >> 2);
    if (accumulator > 2) outputLength++;
    
    //truncate data to match actual output length
    outputData.length = outputLength;
    return outputLength? outputData: nil;
}

+ (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIView *)makeRoundedView:(UIView*)view withRadius:(float)radius {
    view.layer.cornerRadius = radius;
    view.layer.masksToBounds = YES;
    return view;
}


@end
