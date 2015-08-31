//
//  DPCreatePickerTableViewController.m
//  Digidex Pro
//
//  Created by Avery Pierce on 8/29/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import "DPCreatePickerTableViewController.h"
#import "DPCreateCardTableViewController.h"


@interface DPCreatePickerTableViewController ()

@end

@implementation DPCreatePickerTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
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

- (IBAction)dismiss:(id)sender
{
	// dismiss this view controller.
	[self.navigationController dismissViewControllerAnimated:YES completion:^{
		
	}];
}

- (IBAction)importFromContacts:(id)sender
{
	ABPeoplePickerNavigationController *peoplePicker = [[ABPeoplePickerNavigationController alloc] init];
	peoplePicker.peoplePickerDelegate = self;
	[self presentViewController:peoplePicker animated:YES completion:^{
		
	}];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
	if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:@"Import From Contacts"]) {
		[self importFromContacts:self];
	}
}


#pragma mark - ABPeoplePickerDelegate methods
- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker didSelectPerson:(ABRecordRef)person;
{
	
	// Capture this metadata from the contact
	NSString *name = (__bridge NSString*)ABRecordCopyCompositeName(person);
	
	
	
	NSArray *singleStringKeys =	@[@{@"organization":	@(kABPersonOrganizationProperty)},
								  @{@"job title":		@(kABPersonJobTitleProperty)},
								  @{@"department":		@(kABPersonDepartmentProperty)}];
	
	NSArray *multiStringKeys =	@[@{@"URL":				@(kABPersonURLProperty)},
								  @{@"email":			@(kABPersonEmailProperty)},
								  @{@"phone":			@(kABPersonPhoneProperty)}];
	
	
	
	NSMutableArray *keyValuePairs = [@[@{@"key":@"name", @"value": name}] mutableCopy];
	
	
	for (NSDictionary *keyValuePair in singleStringKeys) {
		
		NSString *key = keyValuePair.allKeys[0];
		NSString *stringValue = (__bridge NSString *)(ABRecordCopyValue(person, [keyValuePair[key] intValue]));
		
		if (stringValue && [stringValue length] > 0)
			[keyValuePairs addObject:@{@"key":key, @"value":stringValue}];
		
	}
	
	for (NSDictionary *keyValuePair in multiStringKeys) {
		
		NSString *key = keyValuePair.allKeys[0];
		ABMultiValueRef multiValue = ABRecordCopyValue(person, [keyValuePair[key] intValue]);
		long count = ABMultiValueGetCount(multiValue);
		for (int i = 0; i < count; i++) {
			
			CFStringRef label = ABMultiValueCopyLabelAtIndex(multiValue, i);
			NSString *localizedLabel = (__bridge NSString *)(ABAddressBookCopyLocalizedLabel(label));
			
			NSString *value = (__bridge NSString *)ABMultiValueCopyValueAtIndex(multiValue, i);
			
			if (value && [value length] > 0) {
				[keyValuePairs addObject:@{@"key":[NSString stringWithFormat:@"%@ %@", localizedLabel, key], @"value":value, @"type":key}];
			}
		}
	}
	
	
	// Address is a special case...
	ABMultiValueRef addresses = ABRecordCopyValue(person, kABPersonAddressProperty);
	long addressCount = ABMultiValueGetCount(addresses);
	for (int i = 0; i < addressCount; i++) {
		
		CFStringRef label = ABMultiValueCopyLabelAtIndex(addresses, i);
		NSString *localizedLabel = (__bridge NSString*)ABAddressBookCopyLocalizedLabel(label);
		
		CFDictionaryRef address = ABMultiValueCopyValueAtIndex(addresses, i);
		
		NSString *street =	CFDictionaryGetValue(address, kABPersonAddressStreetKey);
		NSString *city =	CFDictionaryGetValue(address, kABPersonAddressCityKey);
		NSString *state =	CFDictionaryGetValue(address, kABPersonAddressStateKey);
		NSString *zip =		CFDictionaryGetValue(address, kABPersonAddressZIPKey);
		NSString *country = CFDictionaryGetValue(address, kABPersonAddressCountryKey);
		
		NSString *addressString = [NSString stringWithFormat:@"%@\n%@, %@ %@\n%@", street, city, state, zip, country];
		
		[keyValuePairs addObject:@{@"key": [NSString stringWithFormat:@"%@ %@", localizedLabel, @"address"], @"value": addressString}];
	}

	
	
	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone"
															 bundle: nil];
	
	DPCreateCardTableViewController *controller = (DPCreateCardTableViewController*)[mainStoryboard instantiateViewControllerWithIdentifier: @"CreateCardTableViewController"];
	controller.initialKeyValuePairs = [keyValuePairs copy];
	
	[self.navigationController pushViewController:controller animated:YES];
	
}

/*
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return 0;
}
*/
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

@end
