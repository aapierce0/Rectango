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

#import "AFNetworking.h"

@interface DPCreateCardTableViewController ()

@end

@implementation DPCreateCardTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	_cardImage = [UIImage imageNamed:@"uploadPlaceholderImage"];
	_cardName = @"";
	
	_keyValuePairs = [[NSMutableArray alloc] init];
	[_keyValuePairs addObject:[@{@"key":@"email address", @"value":@""} mutableCopy]];
	[_keyValuePairs addObject:[@{@"key":@"phone", @"value":@""} mutableCopy]];
	[_keyValuePairs addObject:[@{@"key":@"", @"value":@""} mutableCopy]];
	
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
	}
	
	return 44;
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
		
	} else if (indexPath.section - 2 < _keyValuePairs.count) {
		
		// This is a key value cell
		DPEditableKeyValueTableViewCell *keyValueCell = [tableView dequeueReusableCellWithIdentifier:@"KeyValueCell" forIndexPath:indexPath];
		
		// Get the key-value pair from the array.
		NSDictionary *pair = _keyValuePairs[indexPath.section-2];
		keyValueCell.keyTextField.placeholder = @"field name";
		keyValueCell.keyTextField.text = pair[@"key"];
		keyValueCell.keyTextField.textColor = self.view.tintColor;
		keyValueCell.keyTextField.delegate = self;
		keyValueCell.keyTextField.type = DPTableViewTextFieldTypeKey;
		keyValueCell.keyTextField.indexPath = indexPath;
		
		keyValueCell.valueTextField.placeholder = @"info";
		keyValueCell.valueTextField.text = pair[@"value"];
		keyValueCell.valueTextField.delegate = self;
		keyValueCell.valueTextField.type = DPTableViewTextFieldTypeValue;
		keyValueCell.valueTextField.indexPath = indexPath;
		
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
	
	
	
	
	
	// At this point, the file will begin saving. Display the loading dialog.
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Uploading..."
																   message:@"\n\n\n"
															preferredStyle:UIAlertControllerStyleAlert];
	
	
	[self presentViewController:alert animated:NO completion:nil];
	
	UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	spinner.center = CGPointMake(130.5, 65.5);
	spinner.color = [UIColor blackColor];
	[spinner startAnimating];
	[alert.view addSubview:spinner];
	
	
	
	
	
	// The results object will represent the new card.
	NSString *baseURLString = @"http://bloviations.net/digidex";
	
	
	// First, upload the image...
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	
	manager.responseSerializer = [AFHTTPResponseSerializer serializer];
	manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", @"application/json", nil];
	
	manager.requestSerializer = [AFJSONRequestSerializer serializer];
	NSLog(@"manager request serializer: %@", manager.requestSerializer);
	
	[manager POST:[baseURLString stringByAppendingPathComponent:@"uploadImage.php"] parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
		
		// Add the URL to the card image.
		if (_cardImage != nil) {
			NSData *PNGImageData = UIImagePNGRepresentation(_cardImage);
			[formData appendPartWithFileData:PNGImageData name:@"image" fileName:@"businesCard" mimeType:@"image/png"];
		}
		
	} success:^(AFHTTPRequestOperation *operation, id responseObject) {
		
		// The upload was a success. The file's final resting place is at the returned address.
		NSString *imageURL = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
		
		NSMutableDictionary *resultsCopy = [results mutableCopy];
		[resultsCopy setObject:imageURL forKey:@"_cardURL"];
		
		NSDictionary *parameters = [NSDictionary dictionaryWithDictionary:resultsCopy];
		
		
		
		// Submit the JSON request to create the card.
		[manager POST:[baseURLString stringByAppendingPathComponent:@"digidex.php"] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
			
			[alert dismissViewControllerAnimated:YES completion:^{}];
			
			// Card returned. Here is the URL for it.
			NSString *cardURLString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
			NSLog(@"card creation success! %@", cardURLString);
			
			// dismiss this view controller.
			[self.navigationController dismissViewControllerAnimated:YES completion:^{
				
				// Show the card right away...
				NSURL *cardURL = [NSURL URLWithString:cardURLString];
				[[UIApplication sharedApplication] openURL:cardURL];
			}];
			
			
		} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			
			// The card creation failed somehow.
			NSLog(@"Error: %@", error);
			
			[alert dismissViewControllerAnimated:YES completion:^{}];
		}];
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		
		// The image upload failed somehow.
		NSLog(@"Error: %@", error);
		
		[alert dismissViewControllerAnimated:YES completion:^{}];
	}];
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

@end
