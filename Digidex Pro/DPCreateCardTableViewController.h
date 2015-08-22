//
//  DPCreateCardTableViewController.h
//  Digidex Pro
//
//  Created by Avery Pierce on 8/22/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DPCreateCardTableViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UIImageView *cardImageView;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextView *detailsTextView;

- (IBAction)saveData:(id)sender;
- (IBAction)dismiss:(id)sender;

@end
