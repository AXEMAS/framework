//
//  AXOChoicePicker.m
//  AXO
//
//  Created by Alessandro Molina on 2/10/13.
//  Copyright (c) 2013 AXANT. All rights reserved.
//

#import "AXOChoicePicker.h"
#import "UIKit/UIKit.h"

#define PICKER_VIEW_TAG 9832

@interface AXOChoicePicker () {
    int _selected;
}

@property (nonatomic, readwrite, strong) UIActionSheet *view;
@property (atomic, readwrite, strong) NSArray *options;
@property (nonatomic, readwrite, strong) UIPickerView *pickerView;
@property (nonatomic, readwrite, copy) AXOChoicePickerBlock onSelect;

@end

@implementation AXOChoicePicker

- (id)initWithTitle:(NSString*)title options:(NSArray*)options onSelect:(AXOChoicePickerBlock)onSelect; {
    self = [super init];
	if (self) {
        self->_selected = -1;
        self.options = options;
        self.onSelect = onSelect;
        self.view = [[UIActionSheet alloc] initWithTitle:title
                                                delegate:nil
                                       cancelButtonTitle:nil
                                  destructiveButtonTitle:nil
                                       otherButtonTitles:nil];

        [self.view setActionSheetStyle:UIActionSheetStyleDefault];
        
        CGRect pickerFrame = CGRectMake(0, 40, 0, 0);
        
        self.pickerView = [[UIPickerView alloc] initWithFrame:pickerFrame];
        self.pickerView.showsSelectionIndicator = YES;
        self.pickerView.dataSource = self;
        self.pickerView.delegate = self;
        self.pickerView.tag = PICKER_VIEW_TAG;
                
        [self.view addSubview:self.pickerView];
        
        UISegmentedControl *addButton = [[UISegmentedControl alloc]
                                         initWithItems:[NSArray arrayWithObject:NSLocalizedString(@"Ok",@"")]];
        addButton.momentary = YES;
        addButton.frame = CGRectMake(260, 7.0f, 50.0f, 30.0f);
        addButton.segmentedControlStyle = UISegmentedControlStyleBar;
        addButton.tintColor = [UIColor colorWithRed:70.0/255 green:121.0/255 blue:227.0/255 alpha:1.0];
        [addButton addTarget:self
                      action:@selector(confirmSelection:)
            forControlEvents:UIControlEventValueChanged];
        [self.view addSubview:addButton];
        
        UISegmentedControl *closeButton = [[UISegmentedControl alloc]
                                           initWithItems:[NSArray arrayWithObject:NSLocalizedString(@"Cancel",@"")]];
        closeButton.momentary = YES;
        closeButton.frame = CGRectMake(10, 7.0f, 50.0f, 30.0f);
        closeButton.segmentedControlStyle = UISegmentedControlStyleBar;
        closeButton.tintColor = [UIColor blackColor];
        [closeButton addTarget:self
                        action:@selector(justCloseActionSheet:)
              forControlEvents:UIControlEventValueChanged];
        [self.view addSubview:closeButton];
    }
    return self;
}

- (void)show {
    if (self->_selected == -1)
        [self.pickerView selectRow:0 inComponent:0 animated:NO];
    else
        [self.pickerView selectRow:self->_selected inComponent:0 animated:NO];
    [self.view showInView:[[UIApplication sharedApplication] keyWindow]];
    [self.view setBounds:CGRectMake(0, 0, 320, 485)];
}

- (void)selectOption:(NSString*)option {
    self->_selected = -1;
    NSUInteger selectedIndex = [self.options indexOfObject:option];
    if (selectedIndex != NSNotFound) {
        [self.pickerView selectRow:selectedIndex inComponent:0 animated:NO];
        self->_selected = selectedIndex;
    }
}

- (void)setOptionsList:(NSArray *)options {
    self.options = options;
    self->_selected = -1;
    [self.pickerView reloadAllComponents];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [self.options count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [self.options objectAtIndex:row];
}

- (void)confirmSelection:(UIButton*)sender {
    self->_selected = [self.pickerView selectedRowInComponent:0];
    if (self.onSelect)
        self.onSelect(self.selectedOption);
    [self.view dismissWithClickedButtonIndex:0 animated:YES];
}

- (void)justCloseActionSheet:(UIButton*)sender {
    [self.view dismissWithClickedButtonIndex:0 animated:YES];
}

- (NSString*)selectedOption {
    if (self->_selected < 0)
        return nil;
    return [self.options objectAtIndex:self->_selected];
}

@end
