//
//  DPDetailTableViewController.h
//  Digidex Pro
//
//  Created by Avery Pierce on 8/12/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, DPValueActionType) {
    DPValueActionTypePhone,
    DPValueActionTypeEmail,
    DPValueActionTypePodcast,
	DPValueActionTypeStreetAddress,
	DPValueActionTypeWebAddress,
    DPValueActionTypeUnknown,
	DPValueActionTypeNone
};

@class DKManagedCard;

@interface DPDetailTableViewController : UITableViewController

@property DKManagedCard *selectedCard;

@end
