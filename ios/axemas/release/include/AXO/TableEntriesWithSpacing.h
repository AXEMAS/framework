//
//  TableEntriesWithSpacing.h
//  AXO
//
//  Created by Alessandro Molina on 3/28/13.
//  Copyright (c) 2013 AXANT. All rights reserved.
//

#import <UIKit/UIKit.h>

/* Provides an easy way to create tables with spacing between rows */
@interface TableEntriesWithSpacing : NSObject

@property (nonatomic, strong) NSArray *entries;

- (int)numberOfRows;
- (id)entryAtRow:(int)row;
- (CGFloat)heightForRow:(int)row withRowHeight:(CGFloat)height orSpacing:(CGFloat)spacing;
- (UITableViewCell *)cellOrSpacingForTable:(UITableView*)table atRow:(int)row;

@end
