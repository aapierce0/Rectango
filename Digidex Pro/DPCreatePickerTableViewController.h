//
//  DPCreatePickerTableViewController.h
//  Digidex Pro
//
//  Created by Avery Pierce on 8/29/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import <UIKit/UIKit.h>
@import AddressBookUI;

@interface DPCreatePickerTableViewController : UITableViewController <ABPeoplePickerNavigationControllerDelegate>

- (IBAction)dismiss:(id)sender;

@end
