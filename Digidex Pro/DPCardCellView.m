//
//  DPCardCellView.m
//  Digidex Pro
//
//  Created by Avery Pierce on 8/11/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import "DPCardCellView.h"

@implementation DPCardCellView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
		[self setHighlighted:NO];
		
		self.layer.masksToBounds = NO;
		
		self.layer.shadowColor = [UIColor blackColor].CGColor;
		self.layer.shadowOffset = CGSizeMake(0, 1.0);
		self.layer.shadowRadius = 1.0;
		self.layer.shadowOpacity = 0.6;
		
		self.layer.borderWidth = 0.0;
    }
    return self;
}

- (void)setSelected:(BOOL)selected;
{
	[super setSelected:selected];
	if (selected) {
		self.layer.borderColor = self.tintColor.CGColor;
		self.layer.borderWidth = 5.0;
	} else {
		self.layer.borderWidth = 0.0;
	}

	
	[self setNeedsDisplay];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
