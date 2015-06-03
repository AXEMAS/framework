//
//  AXOChoicePicker.h
//  AXO
//
//  Created by Alessandro Molina on 2/10/13.
//  Copyright (c) 2013 AXANT. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^AXOChoicePickerBlock)(NSString*);

@interface AXOChoicePicker : NSObject <UIPickerViewDataSource, UIPickerViewDelegate>

- (id)initWithTitle:(NSString*)title options:(NSArray*)options onSelect:(AXOChoicePickerBlock)onSelect;
- (void)show;
- (void)selectOption:(NSString*)option;
- (void)setOptionsList:(NSArray*)options;
- (NSString*)selectedOption;

@end
