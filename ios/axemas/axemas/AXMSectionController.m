//
//  AXMSectionController.m
//  axemas
//
//  Copyright (c) 2014 AXANT. All rights reserved.
//

#import "AXMSectionController.h"

@implementation AXMSectionController

- (instancetype)initWithSection:(SectionViewController*)section {
    self = [super init];
    if (self) {
        self.section = section;
        [self sectionOnViewCreate:section.view];
    }
    return self;
}

- (void)sectionDidLoad {
    
}

- (void)sectionWillLoad {
    
}

- (void)sectionViewWillAppear {

}

- (void)sectionOnViewCreate:(UIView *)view {
    
}

- (BOOL)isInsideWebView:(CGPoint)point withEvent:(UIEvent*)event {
    return YES;
}

- (void) navigationbarRightButtonAction {

}

@end