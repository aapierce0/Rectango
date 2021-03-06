//
//  DPTableViewTextField.h
//  Digidex Pro
//
//  Created by Avery Pierce on 8/23/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DPTableViewTextFieldType.h"

@interface DPTableViewTextField : UITextField

@property (strong) NSIndexPath *indexPath;
@property DPTableViewTextFieldType type;

@end
