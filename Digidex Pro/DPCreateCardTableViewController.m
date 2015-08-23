//
//  DPCreateCardTableViewController.m
//  Digidex Pro
//
//  Created by Avery Pierce on 8/22/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import "DPCreateCardTableViewController.h"

#import "AFNetworking.h"

@interface DPCreateCardTableViewController ()

@end

@implementation DPCreateCardTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	self.detailsTextView.textContainerInset = UIEdgeInsetsMake(8, 8, 8, 8);
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

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//#warning Potentially incomplete method implementation.
//    // Return the number of sections.
//    return 0;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//#warning Incomplete method implementation.
//    // Return the number of rows in the section.
//    return 0;
//}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

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
	
	// Convert the text in the text view to an NSDictionary.
	// key1: value1
	// key2: value2
	NSMutableDictionary *results = [NSMutableDictionary dictionary];
	
	NSString *stringDetails = self.detailsTextView.text;
	NSArray *lines = [stringDetails componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	
	for (NSString *line in lines) {
		
		// Split the line at the first colon.
		NSArray *segments = [line componentsSeparatedByString:@":"];
		if (segments.count <= 1) {
			
			// This is an invalid string. Too few segments.
			continue;
		} else {
			
			NSString *key = segments[0];
			NSString *value = segments[1];
			
			[results setObject:value forKey:key];
		}
	}
	
	
	// Also capture the name field.
	[results setObject:self.nameTextField.text forKey:@"name"];
	
	
	
	
	
	// At this point, the file will begin saving. Display the loading dialog.
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Saving..."
																   message:@"\n\n"
															preferredStyle:UIAlertControllerStyleAlert];
	
	UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	
	spinner.center = CGPointMake(130.5, 65.5);
	spinner.color = [UIColor blackColor];
	[spinner startAnimating];
	[alert.view addSubview:spinner];
	[self presentViewController:alert animated:NO completion:nil];
	
	
	
	
	
	
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
	self.cardImageView.image = _cardImage;
	
	[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
	
	[picker dismissViewControllerAnimated:YES completion:^{}];
}

@end
