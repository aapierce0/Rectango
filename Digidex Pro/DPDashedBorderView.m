//
//  DPDashedBorderView.m
//  Rectango
//
//  Created by Avery Pierce on 11/13/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import "DPDashedBorderView.h"

@implementation DPDashedBorderView {
	CAShapeLayer *_border;
}

- (void)awakeFromNib;
{
	_border = [CAShapeLayer layer];
	_border.strokeColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.6].CGColor;
	_border.lineWidth = 3.0f;
	_border.fillColor = nil;
	_border.lineDashPattern = @[@8, @8];
	[self.layer addSublayer:_border];
}

- (void)layoutSubviews;
{
	_border.path = [UIBezierPath bezierPathWithRect:self.bounds].CGPath;
	_border.frame = self.bounds;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
