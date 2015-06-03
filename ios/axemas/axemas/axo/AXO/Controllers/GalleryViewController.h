//
//  GalleryViewController.h
//  AXO
//
//  Created by Simone Marzola on 9/16/13.
//  Copyright (c) 2013 AXANT. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GalleryViewController : UIViewController <UIGestureRecognizerDelegate> {
    NSUInteger imagesPerRow;
    NSUInteger leftMargin;
    
}

@property (nonatomic, strong) NSArray *images;
@property (nonatomic, strong) NSArray *imagesUrl;
@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;

+ (GalleryViewController*)controllerWithImagesPredicate:(NSArray* (^)(void))predicate;

@end
