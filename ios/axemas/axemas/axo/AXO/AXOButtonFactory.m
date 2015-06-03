//
//  AXOButton.m
//  AXO
//
//  Created by Alessandro Molina on 2/10/13.
//  Copyright (c) 2013 AXANT. All rights reserved.
//

#import "AXOButtonFactory.h"
#import "AXO.h"
#import <QuartzCore/QuartzCore.h>

static NSDictionary *EmbeddedImages = nil;

@implementation AXOButtonFactory

+ (void)replaceNavigationButton:(UIBarButtonItem*)item withImage:(UIImage*)image {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0.0, 0.0, image.size.width, image.size.height);
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:item.target
               action:item.action
     forControlEvents:UIControlEventTouchUpInside];
    
    item.customView = button;
}

+ (void)replaceNavigationButton:(UIBarButtonItem*)item withImage:(UIImage*)image withImageSelected:(UIImage*)imageSelected withImageHighlighted:(UIImage*)imageHighlighted{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0.0, 0.0, image.size.width, image.size.height);
    [button setImage:image forState:UIControlStateNormal];
    [button setImage:imageSelected forState:UIControlStateSelected];
    [button setImage:imageHighlighted forState:UIControlStateHighlighted];
    [button addTarget:item.target
               action:item.action
     forControlEvents:UIControlEventTouchUpInside];
    
    item.customView = button;
}

+ (UIView*)customNavigationBarTitleView:(NSString*)title
                             titleImage:(UIImage*)titleImage
                            imageOrigin:(CGPoint)imageOrigin
                        titleLabelColor:(UIColor*)titleLabelColor
                              fontStyle:(UIFont*)fontStyle
{
    UIImageView * viewImage;
    UIView * navBarTitleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    UILabel * titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(viewImage.frame.size.width + 20, 10, 150, 24)];
    [titleLabel setText:title];
    
    if(titleImage){
        viewImage = [[UIImageView alloc] initWithImage:titleImage];
        [viewImage setFrame:CGRectMake(imageOrigin.x,imageOrigin.y,viewImage.frame.size.width, viewImage.frame.size.height)];
    }
    
    
    
    if(fontStyle)
        [titleLabel setFont:fontStyle];
    
    if(titleImage)
        [navBarTitleView addSubview:viewImage];
    if(titleLabel)
        [navBarTitleView addSubview:titleLabel];
    
    if(titleLabelColor)
        [titleLabel setTextColor:titleLabelColor];
    
    return navBarTitleView;
}


+ (UIButton*)buttonWithLook:(NSString*)look {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [AXOButtonFactory patchButton:btn withLook:look];
    return btn;
}

+ (void)patchButton:(UIButton*)btn withLook:(NSString*)look {
    NSString *highlightedLook = [NSString stringWithFormat:@"%@Highlight", look];
    
    UIEdgeInsets btnInsets = UIEdgeInsetsMake(18, 18, 18, 18);
    UIImage *normalBtnBackground = [[AXO embeddedImageNamed:look
                                                   fromPool:EmbeddedImages] resizableImageWithCapInsets:btnInsets];
    UIImage *highlightedBtnBackfround = [[AXO embeddedImageNamed:highlightedLook
                                                        fromPool:EmbeddedImages] resizableImageWithCapInsets:btnInsets];
    
    [btn setBackgroundImage:normalBtnBackground forState:UIControlStateNormal];
    [btn setBackgroundImage:highlightedBtnBackfround forState:UIControlStateHighlighted];
    
    if ([look hasPrefix:@"dark"])
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

+ (void)patchButton:(UIButton*)button withTitle:(NSString*)title withTitleFont:(UIFont*)font withCornerRadius:(float)cornerRadius withNormalColor:(UIColor*)normalColor withSelectedColor:(UIColor*)selectedColor withDisabledColor:(UIColor*)disabledColor withNormalTextColor:(UIColor*)normalTextColor withSelectedTextColor:(UIColor*)selectedTextColor withDisabledTextColor:(UIColor*)disabledTextColor{
    [button.layer setCornerRadius:cornerRadius];
    button.layer.masksToBounds =YES;
    [button setBackgroundImage:[AXO imageWithColor:normalColor] forState:UIControlStateNormal];
    [button setTitleColor:normalTextColor forState:UIControlStateNormal];
    [button.titleLabel setFont:font];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitle:title forState:UIControlStateHighlighted];
    [button setTitle:title forState:UIControlStateSelected];
    [button setTitle:title forState:UIControlStateDisabled];
    if (selectedColor != nil){
        [button setTitleColor:selectedTextColor forState:UIControlStateHighlighted];
        [button setTitleColor:selectedTextColor forState:UIControlStateSelected];
        [button setBackgroundImage:[AXO imageWithColor:selectedColor] forState:UIControlStateHighlighted];
        [button setBackgroundImage:[AXO imageWithColor:selectedColor] forState:UIControlStateSelected];
    }
    if (disabledColor != nil) {
        [button setBackgroundImage:[AXO imageWithColor:disabledColor] forState:UIControlStateDisabled];
        [button setTitleColor:disabledTextColor forState:UIControlStateDisabled];
    }
}

+ (void)initialize {
    EmbeddedImages = @{
      @"darkBlackButton": @"iVBORw0KGgoAAAANSUhEUgAAACQAAAAkCAYAAADhAJiYAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAA2hpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMC1jMDYxIDY0LjE0MDk0OSwgMjAxMC8xMi8wNy0xMDo1NzowMSAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD0ieG1wLmRpZDowMjgwMTE3NDA3MjA2ODExOTQ1NzgzMzdBREQ0MTI4MCIgeG1wTU06RG9jdW1lbnRJRD0ieG1wLmRpZDpGOUEyN0NGQTRBMzIxMUUxQjEwMDk3Qjk3MzYxNjRCOSIgeG1wTU06SW5zdGFuY2VJRD0ieG1wLmlpZDpGOUEyN0NGOTRBMzIxMUUxQjEwMDk3Qjk3MzYxNjRCOSIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgQ1M1LjEgTWFjaW50b3NoIj4gPHhtcE1NOkRlcml2ZWRGcm9tIHN0UmVmOmluc3RhbmNlSUQ9InhtcC5paWQ6MDM4MDExNzQwNzIwNjgxMTk0NTc4MzM3QURENDEyODAiIHN0UmVmOmRvY3VtZW50SUQ9InhtcC5kaWQ6MDI4MDExNzQwNzIwNjgxMTk0NTc4MzM3QURENDEyODAiLz4gPC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+IDw/eHBhY2tldCBlbmQ9InIiPz46wBEPAAABc0lEQVR42uyYvWqDUBTHz/UjWA3BKVTsKqUU8wAugrtbl0z6AH2A9gka586lY6B0Kdl9hQ5Z8gAxgpOBkNKo194TLKVrh2sK98Af8S7/H+djOEeCn/CZ3pjWTC0nrTtPv21bQJEO5s627QfXdcGyLBgOh8Ajdrsd5HkOy+USsiy7Z0AzBPIJIel0OpUopXA4HKBpGi5AsizDYDAASZJgPp9TBuTLmqa9eJ53gY9VVQFC8Qr0Qk9Mwng8JkVRXCl1XV/run6sX59hGAYwlgkCGYqi9A6EDEcW/Okb5heYAPqXQDxHXZRMlEyUTGRIZOhPQKeWISrGXjS1KJkomQA6YSC27H+wjfEMF/8+AwdLVdVPYlnWisFcjkajXoG22y1+VlIURc9ZllG8QHwfjXgLvTebDY3j+Imwh/MwDB/TNL0xTRPwEoKLP49grQL7/R7KsoQgCF4Xi8UtdE09SZJk5jjOOwMqgdNJD73QE72RAbP1JcAANUNuuLjeG40AAAAASUVORK5CYII=",
      @"darkBlackButton@2x": @"iVBORw0KGgoAAAANSUhEUgAAAEgAAABICAYAAABV7bNHAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAA2hpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMC1jMDYxIDY0LjE0MDk0OSwgMjAxMC8xMi8wNy0xMDo1NzowMSAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD0ieG1wLmRpZDowMjgwMTE3NDA3MjA2ODExOTQ1NzgzMzdBREQ0MTI4MCIgeG1wTU06RG9jdW1lbnRJRD0ieG1wLmRpZDo4NEMxODlDRjRBMzMxMUUxQjEwMDk3Qjk3MzYxNjRCOSIgeG1wTU06SW5zdGFuY2VJRD0ieG1wLmlpZDo4NEMxODlDRTRBMzMxMUUxQjEwMDk3Qjk3MzYxNjRCOSIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgQ1M1LjEgTWFjaW50b3NoIj4gPHhtcE1NOkRlcml2ZWRGcm9tIHN0UmVmOmluc3RhbmNlSUQ9InhtcC5paWQ6QzZGOTJENDAwODIxNjgxMTk0NTc4MzM3QURENDEyODAiIHN0UmVmOmRvY3VtZW50SUQ9InhtcC5kaWQ6MDI4MDExNzQwNzIwNjgxMTk0NTc4MzM3QURENDEyODAiLz4gPC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+IDw/eHBhY2tldCBlbmQ9InIiPz4B8cQmAAADSElEQVR42uycT0sbURTFb2YmY2JU/MckEBcVi1FKSykl3UQXUghkJxTaLhS66BcotCh12YW00E/QrZDS6lIoggt1U2mldCOEKnEhhDASI2rsOJreO05KKjaBbgoz58BJZuZlc3+c+95A4Cp0tVT2OHuO/YVts6ses+3WNufWqlarVbrsq5Rgf/YgkGaWmhOXAQUuwXnGfsUOG4ZBg4ODFI/Hqbe3lxRFIS/p/PycTNOk3d1dyuVyVCwW5XGFPcNg3tZ+Vw/oNfu5XAwPD9PY2JjnoDSCtby8TJubm7VHbxjSi3pAD9lZuchkMjQwMEDHx8dUqVTo9PSULMvyJBhd1ykYDFI4HKbW1lba2tqixcXF2vIjhvReAOnsbXZ8dHTUSc/e3p5noTSC1dPT46RoZWVFHv1g35AeeiBw+vr6qL+/nwqFgu/giKRmqV0YCAvWdWGj8j4zzVG6OTQ0RKqq/vVo84OkdtlWZO+VzZu/LUXTtHuyGIlECLpQe3v7xcugqqYU3sGjctPS0gIyrkKhkPNt23ZM4w8nOpwkX7dXvQKBQK3lggpwNJZWv0FBDQARADVJEFigxf5F2KSRICQICQIgtBgSBEBoMQgJAiC0GBIEQGgxJAiAILQYEgRAAIQ9CAkCIF8Bwl/PzRIEFmgxAMIxjwQBEFoMCQIgCC2GBAEQWgwJQoKQIACC0GJIEBKEBP3fBOm6LvMq6OzsDDRcyagKUTAY/KlFIpGyZVlh27Z9M6ujmWQch6itra2kxGIxGUtBR0dHIOOqxkLYKMlkcl1uDg4O6KoBQ360sBAJm0ChULifSCTmyuWywcSoq6vL1+kplUrODI+Ojg4zl8s9VqLR6PbExMSCLMrC4eHhxd/QPrTULgxEk5OTH4VNgCMlO/P4yMjI07W1tbQsdnZ2Ei/+nkDgBwmY/f195zqVSn1aXV19x5cLCkOQM21jaWnpQyaTWeCTzJYf7uzsOHE7OTnxLBSpTWrM5/MOHKldGAgLXv4qJz7VvSgm2U/m5+en3ZPNV0PepOZsNvtSGLgs/hzyxjdyfYt9m8lqU1NTd5jkXdM0jWKxeM2LCTIMI9/d3W2m0+n12dnZjVAoJKMDv7G/u+DolwADAOj7mRW6BkyWAAAAAElFTkSuQmCC",
      @"darkBlackButtonHighlight": @"iVBORw0KGgoAAAANSUhEUgAAACQAAAAkCAYAAADhAJiYAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAA2hpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMC1jMDYxIDY0LjE0MDk0OSwgMjAxMC8xMi8wNy0xMDo1NzowMSAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD0ieG1wLmRpZDowMjgwMTE3NDA3MjA2ODExOTQ1NzgzMzdBREQ0MTI4MCIgeG1wTU06RG9jdW1lbnRJRD0ieG1wLmRpZDozNEMxOTA1MzRBMzMxMUUxQjEwMDk3Qjk3MzYxNjRCOSIgeG1wTU06SW5zdGFuY2VJRD0ieG1wLmlpZDozNEMxOTA1MjRBMzMxMUUxQjEwMDk3Qjk3MzYxNjRCOSIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgQ1M1LjEgTWFjaW50b3NoIj4gPHhtcE1NOkRlcml2ZWRGcm9tIHN0UmVmOmluc3RhbmNlSUQ9InhtcC5paWQ6MDM4MDExNzQwNzIwNjgxMTk0NTc4MzM3QURENDEyODAiIHN0UmVmOmRvY3VtZW50SUQ9InhtcC5kaWQ6MDI4MDExNzQwNzIwNjgxMTk0NTc4MzM3QURENDEyODAiLz4gPC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+IDw/eHBhY2tldCBlbmQ9InIiPz5I3ZPxAAABnElEQVR42uzYO27CQBAG4FkD5mFegiLmAChFJJdpfQHuAMcgJwgcIsoBUuUCaaNUkahyAAooQOYVbB525vdiJSVK4d3CI43A1XyaNTK/iX7L5X7lnnJHKfX0MtONoojQ4oIZ1uv1R9u2qVarkWmalEYdDgfabDY0m81ovV4/MGgEkCuEeHMcx4DwfD5TGIapgAzDoFwuRzyfJpNJyPNdUSqVPngz9/xJKmu/39N8Pn/Pn06nu0KhEJ+fysJtwhYHIAsrUw2CAZY8LlRj/lYGugqU1s88O7LsyLIjyzaUbeg/D1l42u22FpjFYiFBrVZLC9ByuZSgZrOpBcjzPAlqNBpagFarlQQhaehQSCAxqFqtagHabrcSZFmWFqDdbidB5XJZCxCiUAxSncmS8n1fgorFohagIAgkKK0sf03Wj0FIrjrU8Xgkwdv55qe9Fnc1p9dAdDqdLw75t4iyKgv/OGAx+v3+M1+EyQsjhR0OBoMnfLF7vd4LkLwlJY3ZMLDlJlmXMx6PR91u97NSqXiU0is9zMJMzIYBm/oRYAD1z4T1UEJBYQAAAABJRU5ErkJggg==",
      @"darkBlackButtonHighlight@2x": @"iVBORw0KGgoAAAANSUhEUgAAAEgAAABICAYAAABV7bNHAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAA2hpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMC1jMDYxIDY0LjE0MDk0OSwgMjAxMC8xMi8wNy0xMDo1NzowMSAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD0ieG1wLmRpZDowMjgwMTE3NDA3MjA2ODExOTQ1NzgzMzdBREQ0MTI4MCIgeG1wTU06RG9jdW1lbnRJRD0ieG1wLmRpZDo4NEMxODlDQjRBMzMxMUUxQjEwMDk3Qjk3MzYxNjRCOSIgeG1wTU06SW5zdGFuY2VJRD0ieG1wLmlpZDo4NEMxODlDQTRBMzMxMUUxQjEwMDk3Qjk3MzYxNjRCOSIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgQ1M1LjEgTWFjaW50b3NoIj4gPHhtcE1NOkRlcml2ZWRGcm9tIHN0UmVmOmluc3RhbmNlSUQ9InhtcC5paWQ6QzZGOTJENDAwODIxNjgxMTk0NTc4MzM3QURENDEyODAiIHN0UmVmOmRvY3VtZW50SUQ9InhtcC5kaWQ6MDI4MDExNzQwNzIwNjgxMTk0NTc4MzM3QURENDEyODAiLz4gPC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+IDw/eHBhY2tldCBlbmQ9InIiPz7rzIOPAAACzklEQVR42uycz4sScRjGX8dx1nVccQV/wF4MgzkEsUQYhMdAkOjSQnVYIfoPgsKoYwcp6L9YMFg7dAr8C9pDRBdRUjyKCqKLO9uka++rMzC2ZZ2d54FHnO/o4f3wvO93LvP10Z/lZ99jH7AN9r69tkmasb+yG+xj9sf5fD77nz8KkM/succsNRsMidz2/QbnKfs1e1vXdYrH4xSJRCgUCpHP59uo+EjxZ2dnNB6Pqd/v02QykWWT/YrvvXN+5676DfuZfBEwmUxm46Csg9VqtRagbL3lteduQA/YlUV/GQbt7u7SdDoly7Lo4uKCZrPZRoLx+/2kKAppmkaqqtJwOKRGo+HcfsiQ3gsgjd1m76XT6UV6JHqbCmUdLBklkqJOpyNL39nXFHun2pNZE41G6fT01HNwFlsa1yy1CwNhwboqbFSO2F1po52dHTJNk7wuYSAsZHgLG4V775bckD6Eltra2nLaLqdyepJOD8o0h5YsRLxRpRT+0OVCpjlkP/vYjzccmIDqfhaALgux+YeQICQICUKCkCAAQoshQQAEQGgxJAiA0GJIEAChxZAgCIAACDMICQIgAMIMQoIgAEKLIUEABECYQUgQAAEQAGEGIUEAhBZDggAILYYEQUgQEgRAaDEkCAlCgryRIE3T8C74XxQIBH6ouq6PLMvaRoIuKxwOD5VUKtVGi63KYSFs1Gw2e1Kv128D0GVAwsbX7XbvGIZxNBqNEvK+uFeOxFkHRxyJRAbNZvORkkwm24eHhx/cN71uUbFYPBY2sqCw7+dyuU/kOrKKk+Qpu2sXFszkQNg4sbpimuaTQqFQVRTlp9cgOfVK7cJAWAiTlbnMF1n242q1+sLe2Tx1yJvUXKlUXgoDm8XqIW98Id+vs/fPz8/VUql0o1ar3RwMBoler5fexIGcSCQ6sVhskM/nT8rl8pdgMDil5dGB32xw9EuAAQDKhDoxql8bdQAAAABJRU5ErkJggg=="};
}

@end
