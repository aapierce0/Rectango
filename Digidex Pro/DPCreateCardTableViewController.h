//
//  DPCreateCardTableViewController.h
//  Digidex Pro
//
//  Created by Avery Pierce on 8/22/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DPCreateCardTableViewController : UITableViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate, UITextViewDelegate> {
	UIImage *_cardImage;
	
	NSString *_cardName;
	NSMutableArray *_keyValuePairs;
}

@property (strong) NSArray *initialKeyValuePairs;

- (IBAction)saveData:(id)sender;
- (IBAction)dismiss:(id)sender;
- (IBAction)selectCardImage:(id)sender;

@end
