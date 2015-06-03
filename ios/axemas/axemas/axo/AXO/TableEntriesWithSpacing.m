//
//  TableEntriesWithSpacing.m
//  AXO
//
//  Created by Alessandro Molina on 3/28/13.
//  Copyright (c) 2013 AXANT. All rights reserved.
//

#import "TableEntriesWithSpacing.h"

@implementation TableEntriesWithSpacing

- (int)numberOfRows {
    return [self.entries count]*2;
}

- (id)entryAtRow:(int)row {
    return [self.entries objectAtIndex:row / 2];
}

- (CGFloat)heightForRow:(int)row withRowHeight:(CGFloat)height orSpacing:(CGFloat)spacing {
    if ((row % 2) == 0)
        return height;
    else
        return spacing;
}

- (UITableViewCell *)cellOrSpacingForTable:(UITableView*)table atRow:(int)row {
    if ((row % 2)) {
        UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:@"CellSpacingSeparator"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CellSpacingSeparator"];
            [cell.contentView setAlpha:0];
            [cell setUserInteractionEnabled:NO];
        }
        return cell;
    }
    return nil;
}

@end
