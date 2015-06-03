//
//  AXOImageTools.m
//  AXO
//
//  Created by Alessandro Molina on 3/13/13.
//  Copyright (c) 2013 AXANT. All rights reserved.
//

#import "AXOImageTools.h"
#import <QuartzCore/QuartzCore.h>
#import <SDWebImage/SDWebImageManager.h>
#import <objc/runtime.h>

static char CellImageDownloaderDelegate_key;

@interface CellImageDownloaderDelegate : NSObject <SDWebImageManagerDelegate> {
    CGSize imageSize;
    BOOL fill;
}

@property (nonatomic, weak) UITableViewCell *cell;

- (void)setSize:(CGSize)size;
- (void)setAspectFill:(BOOL)aspectFill;
+ (CellImageDownloaderDelegate*)getForCell:(UITableViewCell *)cell;
- (void)cancelCurrentImageLoad;
- (void)webImageManager:(SDWebImageManager *)imageManager didProgressWithPartialImage:(UIImage *)image forURL:(NSURL *)url;
- (void)webImageManager:(SDWebImageManager *)imageManager didFinishWithImage:(UIImage *)image;
@end

@implementation CellImageDownloaderDelegate

- (void)setSize:(CGSize)size {
    self->imageSize = size;
}

- (void)setAspectFill:(BOOL)aspectFill{
    self->fill=YES;
}

- (void)cancelCurrentImageLoad
{
    [[SDWebImageManager sharedManager] cancelAll];
}

- (void)webImageManager:(SDWebImageManager *)imageManager didProgressWithPartialImage:(UIImage *)image forURL:(NSURL *)url
{
    self.cell.imageView.image = [AXOImageTools scaleImageKeepAspect:image toSize:self->imageSize];
    [self.cell.imageView setNeedsLayout];
}

- (void)webImageManager:(SDWebImageManager *)imageManager didFinishWithImage:(UIImage *)image
{
    if (self->fill)
        self.cell.imageView.image = [AXOImageTools scaleImageWithAspectFill:image toSize:self->imageSize];
    else
        self.cell.imageView.image = [AXOImageTools scaleImageKeepAspect:image toSize:self->imageSize];
    [self.cell.imageView setNeedsLayout];
}

+ (CellImageDownloaderDelegate*)getForCell:(UITableViewCell *)cell {
    CellImageDownloaderDelegate *delegate = objc_getAssociatedObject(cell, &CellImageDownloaderDelegate_key);
    if (delegate == nil) {
        delegate = [CellImageDownloaderDelegate new];
        delegate.cell = cell;
        delegate->fill = NO;
        objc_setAssociatedObject(cell, &CellImageDownloaderDelegate_key, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return delegate;
}

@end

@implementation AXOImageTools

+ (UIImage *)scaleImage:(UIImage *)image toSize:(CGSize)newSize {
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0f);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (UIImage *)scaleImageKeepAspect:(UIImage *)image toSize:(CGSize)newSize {
    CGRect image_rect;
    
    float ratio = image.size.width/image.size.height;
    if (ratio >= 1) {
        float image_height = newSize.width / ratio;
        float image_center_y = (newSize.height - image_height) / 2;
        image_rect = CGRectMake(0, image_center_y, newSize.width, image_height);
    }
    else {
        float image_width = newSize.width * ratio;
        float image_center_x = (newSize.width - image_width) / 2;
        image_rect = CGRectMake(image_center_x, 0, image_width, newSize.height);
    }
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0f);
    [image drawInRect:image_rect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (UIImage *)scaleImageWithAspectFill:(UIImage *)image toSize:(CGSize)newSize {
    CGRect image_rect;
    
    float ratio = image.size.width/image.size.height;
    if (ratio <= 1) {
        float image_height = newSize.width / ratio;
        float image_center_y = (newSize.height - image_height) / 2;
        image_rect = CGRectMake(0, image_center_y, newSize.width, image_height);
    }
    else {
        float image_width = newSize.width * ratio;
        float image_center_x = (newSize.width - image_width) / 2;
        image_rect = CGRectMake(image_center_x, 0, image_width, newSize.height);
    }
    
    UIGraphicsBeginImageContextWithOptions(newSize, YES, 0.0f);
    [image drawInRect:image_rect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}


//Retrocompatibilità
+ (void)asyncDownloadImageForCell:(UITableViewCell *)cell withPlaceHolder:(UIImage *)placeholder fromUrl:(NSURL *)url
{
    [self asyncDownloadImageForCell:cell withPlaceHolder:placeholder withCornerRadius:0.0 withAspectFill:NO fromUrl:url loadFromCache:NO];
   
}
+ (void)asyncDownloadImageForCell:(UITableViewCell *)cell withPlaceHolder:(UIImage *)placeholder withCornerRadius:(CGFloat)cornerRadius fromUrl:(NSURL *)url {
    [self asyncDownloadImageForCell:cell withPlaceHolder:placeholder withCornerRadius:0.0 withAspectFill:NO fromUrl:url loadFromCache:NO];
}
+ (void)asyncDownloadImageForCell:(UITableViewCell *)cell withPlaceHolder:(UIImage *)placeholder withCornerRadius:(CGFloat)cornerRadius withAspectFill:(BOOL)aspectFill fromUrl:(NSURL *)url {
    [self  asyncDownloadImageForCell:cell withPlaceHolder:placeholder withCornerRadius:cornerRadius withAspectFill:aspectFill fromUrl:url loadFromCache:NO];
}

//Metodi cache
+ (void)asyncDownloadImageForCell:(UITableViewCell *)cell withPlaceHolder:(UIImage *)placeholder fromUrl:(NSURL *)url loadFromCache:(BOOL)useCache {
    [self asyncDownloadImageForCell:cell withPlaceHolder:placeholder withCornerRadius:0.0 withAspectFill:NO fromUrl:url loadFromCache:useCache];
}

+ (void)asyncDownloadImageForCell:(UITableViewCell *)cell withPlaceHolder:(UIImage *)placeholder withCornerRadius:(CGFloat)cornerRadius fromUrl:(NSURL *)url loadFromCache:(BOOL)useCache{
    [self asyncDownloadImageForCell:cell withPlaceHolder:placeholder withCornerRadius:cornerRadius withAspectFill:NO fromUrl:url loadFromCache:useCache];
}

+ (void)asyncDownloadImageForCell:(UITableViewCell *)cell withPlaceHolder:(UIImage *)placeholder withCornerRadius:(CGFloat)cornerRadius withAspectFill:(BOOL)aspectFill fromUrl:(NSURL *)url loadFromCache:(BOOL)useCache{

    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    CellImageDownloaderDelegate *downloadDelegate = [CellImageDownloaderDelegate getForCell:cell];
    
    //[downloadDelegate cancelCurrentImageLoad];
    if (url) {
        if(aspectFill)
            [downloadDelegate setAspectFill:aspectFill];

        [downloadDelegate setSize:placeholder.size];
        cell.imageView.image = placeholder;
        cell.imageView.layer.cornerRadius = cornerRadius;
        cell.imageView.layer.masksToBounds = YES;
        
        
        if(useCache) {
            //Use cache
            [manager downloadImageWithURL:url options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                {
                }
            } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                {//SDImageCacheTypeDisk
                    if(image){
                        cell.imageView.image = [self scaleImage:image toSize:placeholder.size];
                    }
                }
            }
             ];
        }
        else {
            //Download again the image
            [manager downloadImageWithURL:url options:SDWebImageRefreshCached progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                {
                    //NSLog(@"Download in corso di : %@",url);
                }
            } completed:^(UIImage *image, NSError *error, SDImageCacheType SDImageCacheTypeNone, BOOL finished, NSURL *imageURL) {
                {
                    //NSLog(@"CompletedUrl : %@", imageURL);
                    if(image){
                        cell.imageView.image = [self scaleImage:image toSize:placeholder.size];
                    }
                    else
                        NSLog(@"Download error : %@",error);
                }
            }
             ];
        }
    }
}

+ (UIColor*)RGBcolorWithRed:(int)red green:(int)green blue:(int)blue alpha:(CGFloat)alpha {
    return [UIColor colorWithRed:red/255.0f green:green/255.0f blue:blue/255.0f alpha:alpha];
}


@end
