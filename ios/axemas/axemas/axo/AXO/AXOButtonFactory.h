//
//  AXOButton.h
//  AXO
//
//  Created by Alessandro Molina on 2/10/13.
//  Copyright (c) 2013 AXANT. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AXOButtonFactory : NSObject

+ (UIButton*)buttonWithLook:(NSString*)look;
+ (void)patchButton:(UIButton*)btn withLook:(NSString*)look;
+ (void)replaceNavigationButton:(UIBarButtonItem*)item withImage:(UIImage*)image;
+ (void)replaceNavigationButton:(UIBarButtonItem*)item withImage:(UIImage*)image withImageSelected:(UIImage*)imageSelected withImageHighlighted:(UIImage*)imageHighlighted;
+ (void)patchButton:(UIButton*)button withTitle:(NSString*)title withTitleFont:(UIFont*)font withCornerRadius:(float)cornerRadius withNormalColor:(UIColor*)normalColor withSelectedColor:(UIColor*)selectedColor withDisabledColor:(UIColor*)disabledColor withNormalTextColor:(UIColor*)normalTextColor withSelectedTextColor:(UIColor*)selectedTextColor withDisabledTextColor:(UIColor*)disabledTextColor;
+ (UIView*)customNavigationBarTitleView:(NSString*)title titleImage:(UIImage*)titleImage imageOrigin:(CGPoint)imageOrigin titleLabelColor:(UIColor*)titleLabelColor fontStyle:(UIFont*)fontStyle;

@end
