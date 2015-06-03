//
//  AttributesMaster.h
//  AXO
//
//  Created by Alessandro Molina on 2/7/13.
//  Copyright (c) 2013 AXANT. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AXO : NSObject

/*
 * calling [AXO attributize:obj] on obj will
 * add to obj the [obj get:@"name"] and [obj set:@"name" toValue:otherObj] methods
 * those permit to attach properties to an object at runtime
 */
+ (void)attributize:(id)obj;
+ (void)setAttribute:(NSString*)name toValue:(id)value forObject:(id)obj;
+ (id)getAttribute:(NSString*)name forObject:(id)obj;

/*
 * Given a string will perform escaping so that it can be passed
 * as GET argument to an URL
 */
+ (NSString*)escapeStringForRequest:(NSString*)url;

/*
 * Display an alert box with the given title and body
 */
+ (void)alertWithTitle:(NSString*)title body:(NSString*)body;

/*
 * Display an alert box with the given title, body and set a delegate
 */
+ (void)alertWithTitle:(NSString*)title body:(NSString*)body delegate:(id)delegate;

/*
 * Display an alert box with the given title, body, title button and set a delegate
 */
+ (void)alertWithTitle:(NSString*)title body:(NSString*)body button:(NSDictionary*)button delegate:(id)delegate;

/*
 * Given a Base64 string it returns the corresponding
 * binary data
 */
+ (NSData *)decodeBase64:(NSString *)string;

/*
 * Retrieve an image from a pool of images encoded using base64
 */
+ (UIImage *)embeddedImageNamed:(NSString *)name fromPool:(NSDictionary*)pool;

/*
 * Given an object checks if it's nil or NSNull
 */
+ (BOOL)isNull:(id)obj;

/*
 * Triggers Notifications on Main Thread
 */
+ (void)triggerNotification:(NSString*)event withObject:(id)object;

+ (id)appDelegate;
+ (id)appWindow;
+ (id)controllerFromMainStoryboard:(NSString*)controllerId;

/*
 * Given a Color it return an image 1px * 1px of the given color
 */
+ (UIImage *)imageWithColor:(UIColor *)color;

/*
 * Makes a view rounded
 */
+ (UIView *)makeRoundedView:(UIView*)view withRadius:(float)radius;

@end
