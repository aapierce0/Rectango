//
//  DPEditableKeyValueTableViewCell.h
//  Digidex Pro
//
//  Created by Avery Pierce on 8/23/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DPTableViewTextField;
@class DPTableViewTextView;

@interface DPEditableKeyValueTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *keyIconImageView;
@property (weak, nonatomic) IBOutlet DPTableViewTextField *keyTextField;
@property (weak, nonatomic) IBOutlet DPTableViewTextField *valueTextField;
@property (weak, nonatomic) IBOutlet DPTableViewTextView *valueTextView;

+ (CGFloat)defaultRowHeight;
+ (CGFloat)defaultMultilineRowHeight;

@end
