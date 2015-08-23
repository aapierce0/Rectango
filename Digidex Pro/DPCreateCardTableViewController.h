//
//  DPCreateCardTableViewController.h
//  Digidex Pro
//
//  Created by Avery Pierce on 8/22/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DPCreateCardTableViewController : UITableViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate> {
	UIImage *_cardImage;
}

@property (weak, nonatomic) IBOutlet UITableViewCell *cardImageViewTableCell;
@property (weak, nonatomic) IBOutlet UIImageView *cardImageView;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextView *detailsTextView;

- (IBAction)saveData:(id)sender;
- (IBAction)dismiss:(id)sender;
- (IBAction)selectCardImage:(id)sender;

@end
