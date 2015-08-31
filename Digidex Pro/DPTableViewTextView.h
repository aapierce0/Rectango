//
//  DPTableViewTextView.h
//  Digidex Pro
//
//  Created by Avery Pierce on 8/30/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DPTableViewTextFieldType.h"

@interface DPTableViewTextView : UITextView

@property (strong) NSIndexPath *indexPath;
@property DPTableViewTextFieldType type;

@end
