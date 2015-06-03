//
//  GalleryViewController.m
//  AXO
//
//  Created by Simone Marzola on 9/16/13.
//  Copyright (c) 2013 AXANT. All rights reserved.
//

#import "GalleryViewController.h"
#import "WebViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>

#define IMAGE_SIZE CGSizeMake(110.f, 100.f)
#define IMAGE_PADDING 3.f

@interface GalleryViewController ()

@end

@implementation GalleryViewController

+ (GalleryViewController*)controllerWithImagesPredicate:(NSArray* (^)(void))predicate{
    NSString *resourceBundlePath = [[NSBundle mainBundle] pathForResource:@"AXOResources" ofType:@"bundle"];
    NSBundle *resourceBundle = [NSBundle bundleWithPath:resourceBundlePath];
    
    GalleryViewController *controller = [[GalleryViewController alloc] initWithNibName:@"GalleryViewController" bundle:resourceBundle];
    NSArray *images = predicate();
    if (![images count] || [images[0] isKindOfClass:[UIImageView class]]){
        controller.images = images;
        controller.imagesUrl = @[];
    }else if ([images[0] isKindOfClass:[NSString class]]){
        controller.imagesUrl = images;
        __block NSMutableArray* mutableImages = [NSMutableArray array];
        [images enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            UIImageView *imgView = [[UIImageView alloc]init];
            int imgWidth = floor(IMAGE_SIZE.width)*2;
            int imgHeight = floor(IMAGE_SIZE.height)*2;
            NSString *urlWithSize = [NSString stringWithFormat:@"%@?width=%d&height=%d", obj, imgWidth, imgHeight];
            
            imgView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:urlWithSize]]];

            [mutableImages addObject:imgView];
        }];
        controller.images = mutableImages;
    }else{
        NSLog(@"Invalid image type: %@", NSStringFromClass([images[0] class]));
        controller.images = @[];
    }
    return controller;
}

- (void)calcDrawingConstants{
    CGFloat contentWidth = self.view.frame.size.width;
    CGSize imageSize = IMAGE_SIZE;
    self->imagesPerRow = floor(contentWidth/(imageSize.width+IMAGE_PADDING));
    self->leftMargin = floor((contentWidth-(imageSize.width*imagesPerRow+IMAGE_PADDING*(imagesPerRow-1)))/2);
}

- (void)drawImages{
    float scrollViewHeight = 0;
    for (int idx=0; idx < [self.images count]; idx++){
        UIImageView *image = self.images[idx];
        int column = idx%(self->imagesPerRow);
        int row = floor(idx/(self->imagesPerRow));
        float origin_x = column*IMAGE_SIZE.width + self->leftMargin + IMAGE_PADDING*column;
        float origin_y = row*IMAGE_SIZE.height + IMAGE_PADDING*(row+1);
        float newScrollViewHeight = origin_y + IMAGE_SIZE.height + IMAGE_PADDING;
        if (newScrollViewHeight > scrollViewHeight){
            scrollViewHeight = newScrollViewHeight;
        }
        
        [image setContentMode:UIViewContentModeScaleAspectFill];
        [image setClipsToBounds:YES];
        [image setFrame:CGRectMake(origin_x, origin_y, IMAGE_SIZE.width, IMAGE_SIZE.height)];
        
        image.tag = idx;
        
        image.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tappedImage:)];
        tap.delegate = self;
        [image addGestureRecognizer:tap];
        
        [self.scrollView addSubview:image];
    }
    [self.scrollView setContentSize:CGSizeMake(self.view.frame.size.width, scrollViewHeight)];
}

- (void)tappedImage:(UIGestureRecognizer*)sender{
    NSString *url = self.imagesUrl[sender.view.tag];
    UIViewController *controller = [WebViewController controllerWithUrl:url];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)viewWillAppear:(BOOL)animated{
    if (!self->imagesPerRow){
        [self calcDrawingConstants];
    }
    self.title = @"Gallery";
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self drawImages];
}

- (void)viewWillDisappear:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
