//
//  DPCreateCardTableViewController.m
//  Digidex Pro
//
//  Created by Avery Pierce on 8/22/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import "DPCreateCardTableViewController.h"

#import "DPImageTableViewCell.h"
#import "DPTextFieldTableViewCell.h"
#import "DPEditableKeyValueTableViewCell.h"
#import "DPLargeButtonTableViewCell.h"
#import "DPTableViewTextField.h"
#import "DPTableViewTextView.h"
#import "DPSelectDataTypeTableViewController.h"
#import "DPChooseImageTableViewCell.h"

#import "AFNetworking.h"
#import "DigidexKit.h"


@interface DPCreateCardTableViewController ()

@end

@implementation DPCreateCardTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.tableView.allowsMultipleSelectionDuringEditing = NO;
	
	_imageSelected = NO;
	_cardImage = nil;
	_cardName = @"";
	
	
	_keyValuePairs = [[NSMutableArray alloc] init];
	if (self.initialKeyValuePairs) {
		
		// Copy the key-value pairs here.
		for (NSDictionary *pair in self.initialKeyValuePairs) {
			
			if ([pair[@"key"] isEqualToString:@"name"]) {
				
				if (pair[@"value"]) {
					_cardName = pair[@"value"];
				}
				
			} else if (pair[@"key"] != nil) {
				
				// Make sure the value isn't nil. If it is, use an empty string instead.
				NSString *value = pair[@"value"];
				if (value == nil)
					value = @"";
				
				NSString *type = pair[@"type"];
				if (type == nil)
					type = @"";
				
				[_keyValuePairs addObject:[@{@"key":pair[@"key"], @"value":value, @"type":type} mutableCopy]];
			}
		}
		
	} else {
		
		// Use default key-value pairs.
		[_keyValuePairs addObject:[@{@"key":@"email address", @"value":@"", @"type":@"email"} mutableCopy]];
		[_keyValuePairs addObject:[@{@"key":@"phone", @"value":@"", @"type": @"phone"} mutableCopy]];
		[_keyValuePairs addObject:[@{@"key":@"", @"value":@""} mutableCopy]];
	}
	
	
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
	
	if (indexPath.section == 0 && _cardImage == nil) {
		
		// This is the height of the "Tap to Choose Image" cell.
		return 130;
		
	} else if (indexPath.section == 0 && _cardImage != nil) {
		// This is the image section... return the aspect height.
		CGFloat newHeight = (tableView.bounds.size.width / _cardImage.size.width) * _cardImage.size.height;
		return newHeight;
		
	} else if (indexPath.section == 1 || indexPath.section - 2 >= _keyValuePairs.count) {
		
		// Name cell
		return 44; // The default single cell height.
	}
	
	// All other cells use the editable key value format.
	// The cell's height varies depending on how much content it contains.
	// TODO: handle soft line wraps too.
	NSDictionary *pair = _keyValuePairs[indexPath.section-2];
	NSArray *components = [pair[@"value"] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	
	if (components.count > 1) {
		return [DPEditableKeyValueTableViewCell defaultMultilineRowHeight];
	} else if ([pair[@"type"] isEqualToString:@"multiline"] || [pair[@"type"] isEqualToString:@"address"]) {
		return [DPEditableKeyValueTableViewCell defaultMultilineRowHeight];
	} else {
		return [DPEditableKeyValueTableViewCell defaultRowHeight];
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	// Return the number of sections.
	
	
	/*
	 1 section for the card view
	 1 section for the name view
	 1 section for each of the other keys in the digidex card
	 1 section for the "add new section" button
	 */
	
	return 1 + 1 + _keyValuePairs.count + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	id cell;
	if (indexPath.section == 0) {
		
		// This is the card view cell...
		if (_cardImage) {
			cell = [tableView dequeueReusableCellWithIdentifier:@"CardCell" forIndexPath:indexPath];
			[[cell cardImageView] setImage:_cardImage];
		} else {
			DPChooseImageTableViewCell *chooseImageCell = [tableView dequeueReusableCellWithIdentifier:@"TapToAddImage" forIndexPath:indexPath];
			chooseImageCell.chooseImageView.tintColor = self.view.tintColor;
			chooseImageCell.chooseTextLabel.textColor = self.view.tintColor;
			cell = chooseImageCell;
		}
		
	} else if (indexPath.section == 1) {
		
		// This is the name cell...
		cell = [tableView dequeueReusableCellWithIdentifier:@"TitleTextCell" forIndexPath:indexPath];
		DPTableViewTextField *cellTextField = (DPTableViewTextField *)[cell textField];
		cellTextField.placeholder = @"John Appleseed";
		cellTextField.delegate = self;
		cellTextField.indexPath = indexPath;
		cellTextField.type = DPTableViewTextFieldTypeName;
		cellTextField.text = _cardName;
		
	} else if (indexPath.section - 2 < _keyValuePairs.count) {
		
		NSDictionary *pair = _keyValuePairs[indexPath.section-2];
		
		// Identify if this field has multiple lines.
		NSString *cellIdentifier = @"KeyValueCell";
		NSArray *components = [pair[@"value"] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
		
		// If the value has more than one line, use the multiline cell
		if (components.count > 1) {
			cellIdentifier = @"LongKeyValueCell";
		}
		
		// Test if this pair is the type "multiline" or "address". If so, use the multiline cell
		if ([pair[@"type"] isEqualToString:@"multiline"] || [pair[@"type"] isEqualToString:@"address"]) {
			cellIdentifier = @"LongKeyValueCell";
		}
		
		// This is a key value cell
		DPEditableKeyValueTableViewCell *keyValueCell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
		
		
		// Get the key-value pair from the array.
		keyValueCell.keyTextField.placeholder = @"field name";
		keyValueCell.keyTextField.text = pair[@"key"];
		keyValueCell.keyTextField.textColor = self.view.tintColor;
		keyValueCell.keyTextField.delegate = self;
		keyValueCell.keyTextField.type = DPTableViewTextFieldTypeKey;
		keyValueCell.keyTextField.indexPath = indexPath;
		
		if (keyValueCell.valueTextView != nil) {
			
			keyValueCell.valueTextView.text = pair[@"value"];
			keyValueCell.valueTextView.delegate = self;
			keyValueCell.valueTextView.type = DPTableViewTextFieldTypeValue;
			keyValueCell.valueTextView.indexPath = indexPath;
			keyValueCell.valueTextView.textContainerInset = UIEdgeInsetsMake(8, 26, 8, 8);
			
			keyValueCell.valueTextView.spellCheckingType = UITextSpellCheckingTypeDefault;
			keyValueCell.valueTextView.autocapitalizationType = UITextAutocapitalizationTypeSentences;
			
			if ([pair[@"type"] isEqualToString:@"address"]) {
				keyValueCell.keyIconImageView.image = [UIImage imageNamed:@"map-outline"];
			} else {
				keyValueCell.keyIconImageView.image = [UIImage imageNamed:@"paper-outline"];
			}
			
		}
		
		if (keyValueCell.valueTextField != nil) {
		

			keyValueCell.valueTextField.text = pair[@"value"];
			keyValueCell.valueTextField.delegate = self;
			keyValueCell.valueTextField.type = DPTableViewTextFieldTypeValue;
			keyValueCell.valueTextField.indexPath = indexPath;
			
			
			// Use a custom keyboard type, if specified.
			if ([pair[@"type"] isEqualToString:@"phone"]) {
				keyValueCell.valueTextField.keyboardType = UIKeyboardTypePhonePad;
				keyValueCell.valueTextField.spellCheckingType = UITextSpellCheckingTypeNo;
				keyValueCell.valueTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
				keyValueCell.valueTextField.placeholder = @"(888) 555-1212";
				keyValueCell.keyIconImageView.image = [UIImage imageNamed:@"telephone-outline"];
			} else if ([pair[@"type"] isEqualToString:@"email"]) {
				keyValueCell.valueTextField.keyboardType = UIKeyboardTypeEmailAddress;
				keyValueCell.valueTextField.spellCheckingType = UITextSpellCheckingTypeNo;
				keyValueCell.valueTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
				keyValueCell.valueTextField.placeholder = @"j.appleseed@example.com";
				keyValueCell.keyIconImageView.image = [UIImage imageNamed:@"email-outline"];
			} else if ([pair[@"type"] isEqualToString:@"URL"]) {
				keyValueCell.valueTextField.keyboardType = UIKeyboardTypeURL;
				keyValueCell.valueTextField.spellCheckingType = UITextSpellCheckingTypeNo;
				keyValueCell.valueTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
				keyValueCell.valueTextField.placeholder = @"http://www.digidex.org";
				keyValueCell.keyIconImageView.image = [UIImage imageNamed:@"safari-outline"];
			} else {
				keyValueCell.valueTextField.keyboardType = UIKeyboardTypeDefault;
				keyValueCell.valueTextField.spellCheckingType = UITextSpellCheckingTypeDefault;
				keyValueCell.valueTextField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
				keyValueCell.valueTextField.placeholder = @"info";
				keyValueCell.keyIconImageView.image = [UIImage imageNamed:@"paper-outline"];
			}
			
		}
		
		cell = keyValueCell;
		
	} else {
		
		// This is the large button view
		cell = [tableView dequeueReusableCellWithIdentifier:@"LargeButtonCell" forIndexPath:indexPath];
		[[cell actionButton] setTitle:@"Add New Section" forState:UIControlStateNormal];
	}
	
    
    return cell;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
	if (indexPath.section == 0) {
		
		// This is the card view cell...
		[self selectCardImage:tableView];
		
	} else if (indexPath.section == 1) {
		
		// This is the name cell...
		
	} else if (indexPath.section - 2 < _keyValuePairs.count) {
		
		// This is a key value cell
		
	} else {
		
		// This is the large button view
		[self performSegueWithIdentifier:@"ChooseSectionStyleSegue" sender:self];
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)createNewFieldWithType:(NSString*)type;
{
	if (type) {
		NSIndexSet *insertIndexSet = [NSIndexSet indexSetWithIndex:_keyValuePairs.count+2];
		
		NSDictionary *newPair = nil;
		if ([type isEqualToString:@"single"] || [type isEqualToString:@"multiline"]) {
			// For generic single and multiline fields, don't include the key.
			newPair = @{@"key":@"", @"value":@"", @"type":type};
		} else {
			newPair = @{@"key":type, @"value":@"", @"type":type};
		}
		
		[_keyValuePairs addObject:[newPair mutableCopy]];
		[self.tableView insertSections:insertIndexSet withRowAnimation:UITableViewRowAnimationFade];
	}

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender;
{
	DPSelectDataTypeTableViewController *selectViewController = (DPSelectDataTypeTableViewController*)[[[segue destinationViewController] viewControllers] firstObject];
	selectViewController.createCardTableViewController = self;
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	
    // Return NO if you do not want the specified item to be editable.
	if (indexPath.section == 0) {
		
		// This is the card view cell...
		return NO;
		
	} else if (indexPath.section == 1) {
		
		// This is the name cell...
		return NO;
		
	} else if (indexPath.section - 2 < _keyValuePairs.count) {
		
		// This is a key value cell
		return YES;
		
	} else {
		
		// This is the large button view
		return NO;
		
	}
	
    return NO;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
		if (indexPath.section == 0) {
			
			// This is the card view cell...
			
		} else if (indexPath.section == 1) {
			
			// This is the name cell...
			
		} else if (indexPath.section - 2 < _keyValuePairs.count) {
			
			// This is a key value cell
			[_keyValuePairs removeObjectAtIndex:indexPath.section-2];
			
		} else {
			
			// This is the large button view
			
		}
		
		NSIndexSet *deletedSectionIndexSet = [NSIndexSet indexSetWithIndex:indexPath.section];
		[tableView deleteSections:deletedSectionIndexSet withRowAnimation:UITableViewRowAnimationAutomatic];
//        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
		
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)saveData:(id)sender {
	
	// end editing of the cell so that changes are committed
	[self.view endEditing:NO];
	
	// Capture all the values in the key value pairs
	NSMutableDictionary *results = [NSMutableDictionary dictionary];
	
	// Loop through the key value array
	NSMutableDictionary *phoneValues = [NSMutableDictionary dictionary];
	NSMutableDictionary *emailValues = [NSMutableDictionary dictionary];
	NSMutableDictionary *addressValues = [NSMutableDictionary dictionary];
	for (NSDictionary *pair in _keyValuePairs) {
		
		if ([pair[@"key"] length] > 0) {
			
			if ([pair[@"type"] isEqualToString:@"phone"]) {
				[phoneValues setObject:pair[@"value"] forKey:pair[@"key"]];
			} else if ([pair[@"type"] isEqualToString:@"email"]) {
				[emailValues setObject:pair[@"value"] forKey:pair[@"key"]];
			} else if ([pair[@"type"] isEqualToString:@"address"]) {
				[addressValues setObject:pair[@"value"] forKey:pair[@"key"]];
			} else {
				[results setObject:pair[@"value"] forKey:pair[@"key"]];
			}
		}
	}
	
	// Map the phone, email, and address groups to their respective keys.
	NSDictionary *nestedFields = @{
								   @"phone":phoneValues,
								   @"email":emailValues,
								   @"address":addressValues
								   };
	
	for (NSString *key in nestedFields) {
		NSDictionary *nestedPairs = nestedFields[key];
		if (nestedPairs.count > 1) {
			[results setObject:nestedPairs forKey:key];
		} else if (nestedPairs.count == 1) {
			NSString *onlyKey = nestedPairs.allKeys[0];
			NSDictionary *onlyValue = nestedPairs[onlyKey];
			[results setObject:onlyValue forKey:onlyKey];
		}
	}
	
	// Also capture the name field.
	[results setObject:_cardName forKey:@"name"];
	
	
	
	
	
	
	// Check to make sure that an image was supplied. If not, tell the user to supply one.
	if (!_imageSelected) {
		
		// Display a dialog to indicate that data is being updated
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"No Image Selected"
																	   message:@"Please select an image for your digidex card before continuing"
																preferredStyle:UIAlertControllerStyleAlert];
		
		[alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}]];
		[self presentViewController:alert animated:YES completion:^{
			
		}];
		return;
	}
	
	
	
	
	
	
	// Create this digidex card locally.
	[[DKDataStore sharedDataStore] addContactWithDictionary:results image:_cardImage];
	
	// dismiss this view controller.
	[self.navigationController dismissViewControllerAnimated:YES completion:^{}];
	


}

- (IBAction)dismiss:(id)sender
{
	// dismiss this view controller.
	[self.navigationController dismissViewControllerAnimated:YES completion:^{
		
	}];
}

- (IBAction)selectCardImage:(id)sender {
	
	// Show the image picker.
	UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
	imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	imagePicker.delegate = self;
	
	[self presentViewController:imagePicker animated:YES completion:^{}];
	
}


#pragma mark - UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
{
	
	// When the user has selected their image, show it in the card image view.
	_cardImage = info[@"UIImagePickerControllerOriginalImage"];
	_imageSelected = YES;
	
	[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
	
	[picker dismissViewControllerAnimated:YES completion:^{}];
}


#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField;
{
	// Get the table view cell;
	if ([textField isKindOfClass:[DPTableViewTextField class]]) {
		DPTableViewTextField *myTextField = (DPTableViewTextField*)textField;
		
	
		if (myTextField.indexPath.section < 2) {
			// This is the name text field
			_cardName = myTextField.text;
			return;
		} else if (myTextField.indexPath.section - 2 < _keyValuePairs.count){
			NSUInteger arrayIndex = myTextField.indexPath.section-2;
			
			if (myTextField.type == DPTableViewTextFieldTypeKey) {
				[_keyValuePairs[arrayIndex] setObject:myTextField.text forKey:@"key"];
			} else {
				[_keyValuePairs[arrayIndex] setObject:myTextField.text forKey:@"value"];
			}
		}
	}
}

- (void)textViewDidEndEditing:(UITextView *)textView;
{
	// Get the table view cell;
	if ([textView isKindOfClass:[DPTableViewTextView class]]) {
		DPTableViewTextView *myTextView = (DPTableViewTextView*)textView;
		
		
		if (myTextView.indexPath.section >= 2) {
			NSUInteger arrayIndex = myTextView.indexPath.section-2;
			
			if (myTextView.type == DPTableViewTextFieldTypeKey) {
				[_keyValuePairs[arrayIndex] setObject:myTextView.text forKey:@"key"];
			} else {
				[_keyValuePairs[arrayIndex] setObject:myTextView.text forKey:@"value"];
			}
		}
	}
}

@end
