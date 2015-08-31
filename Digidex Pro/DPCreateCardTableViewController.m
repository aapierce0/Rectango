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

#import "AFNetworking.h"
#import "DigidexKit.h"


// UPLOAD Maximum is 1.5 MB ~= 1,500,000 B
#define UPLOAD_TARGET_SIZE 1500000.0

@interface UIImage (resizeImage)

+ (UIImage*)imagewithImage:(UIImage*)image scaledByFactor:(CGFloat)scaleFactor;
+ (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize;

@end

@implementation UIImage (resizeImage)

+ (UIImage*)imagewithImage:(UIImage*)image scaledByFactor:(CGFloat)scaleFactor; {
	
	CGSize newSize = CGSizeMake(image.size.width * scaleFactor, image.size.height * scaleFactor);
	return [UIImage imageWithImage:image scaledToSize:newSize];
}

+ (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize; {
	
	UIGraphicsBeginImageContext( newSize );
	[image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
	UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return newImage;
}

@end


@interface DPCreateCardTableViewController ()

@end

@implementation DPCreateCardTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	_cardImage = [UIImage imageNamed:@"uploadPlaceholderImage"];
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
	if (indexPath.section == 0 && _cardImage != nil) {
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
		cell = [tableView dequeueReusableCellWithIdentifier:@"CardCell" forIndexPath:indexPath];
		[[cell cardImageView] setImage:_cardImage];
		
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
			
		}
		
		if (keyValueCell.valueTextField != nil) {
		

			keyValueCell.valueTextField.text = pair[@"value"];
			keyValueCell.valueTextField.delegate = self;
			keyValueCell.valueTextField.type = DPTableViewTextFieldTypeValue;
			keyValueCell.valueTextField.indexPath = indexPath;
			
			
			// Use a custom keyboard type, if specified.
			if ([pair[@"type"] isEqualToString:@"phone"]) {
				keyValueCell.valueTextField.keyboardType = UIKeyboardTypePhonePad;
				keyValueCell.valueTextField.placeholder = @"(888) 555-1212";
			} else if ([pair[@"type"] isEqualToString:@"email"]) {
				keyValueCell.valueTextField.keyboardType = UIKeyboardTypeEmailAddress;
				keyValueCell.valueTextField.placeholder = @"j.appleseed@example.com";
			} else if ([pair[@"type"] isEqualToString:@"URL"]) {
				keyValueCell.valueTextField.keyboardType = UIKeyboardTypeURL;
				keyValueCell.valueTextField.placeholder = @"http://www.digidex.org";
			} else {
				keyValueCell.valueTextField.keyboardType = UIKeyboardTypeDefault;
				keyValueCell.valueTextField.placeholder = @"info";
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
		NSIndexSet *insertIndexSet = [NSIndexSet indexSetWithIndex:_keyValuePairs.count+2];
		[_keyValuePairs addObject:[@{@"key":@"", @"value":@""} mutableCopy]];
		
		[tableView insertSections:insertIndexSet withRowAnimation:UITableViewRowAnimationFade];
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

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
	for (NSDictionary *pair in _keyValuePairs) {
		
		if ([pair[@"key"] length] > 0) {
			[results setObject:pair[@"value"] forKey:pair[@"key"]];
		}
	}
	
	// Also capture the name field.
	[results setObject:_cardName forKey:@"name"];
	
	
	
	
	
	
	// Display a dialog to indicate that data is being updated
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Uploading Image..."
																   message:@"\n\n\n"
															preferredStyle:UIAlertControllerStyleAlert];

	
	
	
	
	
	// The results object will represent the new card.
	NSString *baseURLString = @"http://bloviations.net/digidex";
	
	
	// First, upload the image...
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	
	manager.responseSerializer = [AFHTTPResponseSerializer serializer];
	manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", @"application/json", nil];
	
	manager.requestSerializer = [AFJSONRequestSerializer serializer];
	NSLog(@"manager request serializer: %@", manager.requestSerializer);
	
	__block AFHTTPRequestOperation *activeOperation = [manager POST:[baseURLString stringByAppendingPathComponent:@"uploadImage.php"] parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
		
		// Add the URL to the card image.
		if (_cardImage != nil) {
			
			// Scale the image down so that it isn't huge.
			// We want to scale the image down enough so that it's manageable
			
			NSData *uploadImageData = nil;
			NSData *originalImageData =	UIImagePNGRepresentation(_cardImage);
			
			if (originalImageData.length < UPLOAD_TARGET_SIZE) {
				
				// If the original image is less than the maximum, then we don't need to do anything.
				uploadImageData = originalImageData;
			} else {
				
				// Compute how much the image size needs to be reduced.
				CGFloat fileReductionFactor = UPLOAD_TARGET_SIZE / originalImageData.length;
				
				
				// If you scale a rectangle down by 50% (1/2) in each coordinate, the resulting area is 25% (1/4) of the original.
				// Therefore: The desired image scale factor is approx. the square root of the target size reduction.
				CGFloat imageScaleFactor = sqrtf(fileReductionFactor);
				imageScaleFactor = imageScaleFactor * 0.9; // Reduce it by another 10% for goot measure...
				
				UIImage *scaledImage = [UIImage imagewithImage:_cardImage scaledByFactor:imageScaleFactor];
				uploadImageData = UIImagePNGRepresentation(scaledImage);
			}
			
			[formData appendPartWithFileData:uploadImageData name:@"image" fileName:@"businessCard.png" mimeType:@"image/png"];
		}
		
	} success:^(AFHTTPRequestOperation *operation, id responseObject) {
		
		
		// Update the alert to indicate that the image upload has finished, and we are now creating the digidex record.
		[alert setTitle:@"Creating Record..."];
		
		// The upload was a success. The file's final resting place is at the returned address.
		NSString *imageURL = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
		
		NSMutableDictionary *resultsCopy = [results mutableCopy];
		[resultsCopy setObject:imageURL forKey:@"_cardURL"];
		
		NSDictionary *parameters = [NSDictionary dictionaryWithDictionary:resultsCopy];
		
		
		
		// Submit the JSON request to create the card.
		activeOperation = [manager POST:[baseURLString stringByAppendingPathComponent:@"digidex.php"] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
			
			activeOperation = nil;
			[alert dismissViewControllerAnimated:YES completion:^{}];
			
			// Card returned. Here is the URL for it.
			NSString *cardURLString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
			
			NSURL *cardURL = [NSURL URLWithString:cardURLString];
			DKManagedCard *card = [[DKDataStore sharedDataStore] addContactWithURL:cardURL];
			[card setCachedCardImage:_cardImage];
			
			// dismiss this view controller.
			[self.navigationController dismissViewControllerAnimated:YES completion:^{}];
			
			
		} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			
			// The card creation failed somehow.
			NSLog(@"Error: %@", error);
			
			activeOperation = nil;
			[alert dismissViewControllerAnimated:YES completion:^{}];
		}];
		
		
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		
		// The image upload failed somehow.
		NSLog(@"Error: %@", error);
		
		activeOperation = nil;
		[alert dismissViewControllerAnimated:YES completion:^{}];
	}];
	
	
	
	
	
	// The cancel button on the alert will kill the active request.
	[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
		[activeOperation cancel];
		[alert dismissViewControllerAnimated:YES completion:^{}];
	}]];
	
	[self presentViewController:alert animated:NO completion:nil];
	
	UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	spinner.center = CGPointMake(130.5, 75.5);
	spinner.color = [UIColor blackColor];
	[spinner startAnimating];
	[alert.view addSubview:spinner];

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
		} else {
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
