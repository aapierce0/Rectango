//
//  DPEditableKeyValueTableViewCell.m
//  Digidex Pro
//
//  Created by Avery Pierce on 8/23/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import "DPEditableKeyValueTableViewCell.h"

@implementation DPEditableKeyValueTableViewCell

+ (CGFloat)defaultRowHeight; {
	return 81.0;
}


- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)drawRect:(CGRect)rect;
{
	[super drawRect:rect];
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:0.9 alpha:1.0].CGColor);
	
	// Draw them with a 2.0 stroke width so they are a bit more visible.
	CGContextSetLineWidth(context, 0.5f);
	
	CGContextMoveToPoint(context, 22.0f, floor(rect.size.height/2)+0.25f); //start at this point
	
	CGContextAddLineToPoint(context, rect.size.width, floor(rect.size.height/2)+0.25f); //draw to this point
	
	// and now draw the Path!
	CGContextStrokePath(context);
}



@end
