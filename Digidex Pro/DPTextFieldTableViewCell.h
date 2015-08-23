//
//  DPTextFieldTableViewCell.h
//  Digidex Pro
//
//  Created by Avery Pierce on 8/23/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DPTableViewTextField;

@interface DPTextFieldTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet DPTableViewTextField *textField;

@end
