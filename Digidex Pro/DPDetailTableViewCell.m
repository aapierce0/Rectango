//
//  DPDetailTableViewCell.m
//  Digidex Pro
//
//  Created by Avery Pierce on 8/12/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import "DPDetailTableViewCell.h"

@implementation DPDetailTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
