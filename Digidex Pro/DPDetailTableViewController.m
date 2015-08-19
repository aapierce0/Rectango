//
//  DPDetailTableViewController.m
//  Digidex Pro
//
//  Created by Avery Pierce on 8/12/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import "DPDetailTableViewController.h"

#import "DKManagedCard.h"

#import "DPImageTableViewCell.h"
#import "DPTitleTableViewCell.h"
#import "DPDetailTableViewCell.h"
#import "DKDataStore.h"

#define CARD_CELL_IDENTIFIER @"CardCell"
#define TITLE_CELL_IDENTIFIER @"TitleCell"
#define DETAIL_CELL_IDENTIFIER @"DetailCell"

@interface DPDetailTableViewController ()

@end

@implementation DPDetailTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
    [[NSNotificationCenter defaultCenter] addObserverForName:@"ContactLoaded" object:self.selectedCard queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [self.tableView reloadData];
    }];
    
	[[NSNotificationCenter defaultCenter] addObserverForName:@"ImageLoaded" object:self.selectedCard queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        if (!self.isBeingDismissed)
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
	}];
	
	if (self.selectedCard.managedObjectContext == nil) {
		
		NSLog(@"card is not inserted...");
		self.title = @"New Card";
		
		self.navigationItem.rightBarButtonItem =	[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(insertNewCard)];
		self.navigationItem.leftBarButtonItem =		[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelNewCard)];
		
	} else {
		self.title = [self.selectedCard guessedName];
		
        self.navigationItem.leftItemsSupplementBackButton = YES;
        self.navigationItem.leftBarButtonItem =     [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteCard)];
        
        self.navigationItem.rightBarButtonItem =    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareCard)];
        if (!self.selectedCard.originalURL) {
            self.navigationItem.rightBarButtonItem.enabled = NO;
        }
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewCard;
{
	[[DKDataStore sharedDataStore] insertCard:self.selectedCard];
    [self dismiss];
}

- (void)cancelNewCard;
{
    [self dismiss];
}


- (void)deleteCard;
{
	
	// Display a confirmation dialog
	UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
																   message:nil
															preferredStyle:UIAlertControllerStyleActionSheet];
	
	
	// This action will display red, because it is destructive
	UIAlertAction* deleteAction = [UIAlertAction actionWithTitle:@"Delete Card"
														   style:UIAlertActionStyleDestructive
														 handler:^(UIAlertAction * action) {
															 
															 // Delete the card from the data store, and dismiss.
															 [[DKDataStore sharedDataStore] deleteCard:self.selectedCard];
															 [self dismiss];
														  }];
	
	
	// This cancel action will appear separated from the rest of the items
	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
														   style:UIAlertActionStyleCancel
														 handler:^(UIAlertAction * action) {}];
	
	
	// Add the actions to the alert
	[alert addAction:deleteAction];
	[alert addAction:cancelAction];
	

	[self presentViewController:alert animated:YES completion:nil];
}


- (void)shareCard;
{
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[self.selectedCard.digidexURL, self.selectedCard.cardImage] applicationActivities:nil];
    [self presentViewController:activityViewController animated:YES completion:^{
        
    }];
}

- (void)dismiss;
{
    [self.navigationController popViewControllerAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:^{
        self.selectedCard = nil;
    }];
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
	
	
	/*
	 1 section for the card view
	 1 section for the title view
	 1 section for each of the other keys in the digidex card
	 */
	
	return 1 + 1 + self.selectedCard.cardDictionary.allKeys.count;
}

- (NSDictionary *)keyPairForSection:(NSInteger)section;
{
	if (section == 0) {
		
		// This is the card image section. No key pair.
		return nil;
	} else if (section == 1) {
		
		// This is the card title section. No key pair.
		return nil;
	} else {
		
		NSString *keyString = self.selectedCard.cardDictionary.allKeys[section-2];
		id value = self.selectedCard.cardDictionary[keyString];
		
		return @{@"key":keyString, @"value":value};
	}
}

- (NSDictionary *)keyPairForIndexPath:(NSIndexPath*)indexPath;
{
	// Get the key pair for this section. It might be nil...
	NSDictionary *sectionKeyPair = [self keyPairForSection:indexPath.section];
	if (sectionKeyPair == nil) {
		return nil;
	}
	
	id value = sectionKeyPair[@"value"];
	if ([value isKindOfClass:[NSString class]]) {
		
		return sectionKeyPair;
		
		
	} else if ([value isKindOfClass:[NSDictionary class]]) {
		
		// Use the row number to determine which sub-key to use.
		NSString *subKey = [(NSDictionary*)value allKeys][indexPath.row];
		id subValue = ((NSDictionary*)value)[subKey];
		
		return @{@"key":subKey, @"value":[subValue description]};
		
		
	} else if ([value isKindOfClass:[NSArray class]]) {
		
		// Use the row number to determine which item of this array to use
		NSString *subKey = [NSString stringWithFormat:@"%li.", (long)indexPath.row];
		id subValue = ((NSArray*)value)[indexPath.row];
		
		return @{@"key":subKey, @"value":[subValue description]};
		
		
	} else {
		
		return sectionKeyPair;
		
	}
	
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
	
	if (section == 0) {
	
		// The card view section only contains one cell
		return 1;
	} else if (section == 1) {
		
		// The title view section only contains one cell
		return 1;
	} else {
		
		// The other cells contain as many rows as it has data for that key.
		NSDictionary *keyPair = [self keyPairForSection:section];
		id value = keyPair[@"value"];
		
		if ([value isKindOfClass:[NSString class]]) {
			
			// Simple fields that are only a string will just be the one row.
			return 1;
			
		} else if ([value isKindOfClass:[NSDictionary class]]) {
			
			// Complex fields that contain an object or array (such as assorted phone numbers) will contain a row for each item
			return [(NSDictionary*)value allKeys].count;
			
		} else if ([value isKindOfClass:[NSArray class]]) {
			
			return [(NSArray *)value count];
			
		} else {
			return 0;
		}
	}
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	
	UITableViewCell *cell;
	if (indexPath.section == 0) {
		
		// Set the image cell to the card's image
		DPImageTableViewCell *imageCell = (DPImageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CARD_CELL_IDENTIFIER forIndexPath:indexPath];
		imageCell.cardImageView.image = self.selectedCard.cardImage;
		cell = imageCell;
		
	} else if (indexPath.section == 1) {
		
		// Get the cards name and subtitle
		DPTitleTableViewCell *titleCell = (DPTitleTableViewCell *)[tableView dequeueReusableCellWithIdentifier:TITLE_CELL_IDENTIFIER forIndexPath:indexPath];
		titleCell.titleLabel.text = [self.selectedCard guessedName];
		titleCell.subtitleLabel.text = [self.selectedCard guessedOrganization];
		cell = titleCell;
		
	} else {
		
		// This is a key/value cell.
		DPDetailTableViewCell *detailCell = (DPDetailTableViewCell *)[tableView dequeueReusableCellWithIdentifier:DETAIL_CELL_IDENTIFIER forIndexPath:indexPath];
		
		
		NSDictionary *keyPair = [self keyPairForIndexPath:indexPath];
		detailCell.keyLabel.text = keyPair[@"key"];
		detailCell.valueLabel.text = keyPair[@"value"];		
		
		// Get the number of lines of the detail
		NSUInteger lines = [[keyPair[@"value"] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] count];
		detailCell.valueLabel.numberOfLines = lines;
		
		cell = detailCell;
	}
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
	if (indexPath.section == 0) {
		
		// Set the height so that the image fits without any distortion
		CGSize imageSize = self.selectedCard.cardImage.size;
		CGFloat cellWidth = tableView.bounds.size.width;
		
		// If the image size is zero, provide a sensible default...
		if (CGSizeEqualToSize(imageSize, CGSizeMake(0, 0))) {
			imageSize = CGSizeMake(1260, 570);
		}
		
		CGFloat scalingFactor = cellWidth / imageSize.width;
		return scalingFactor * imageSize.height;
		
		
	} else if (indexPath.section == 1) {
		return 60;
	} else {
		
		
		// Get the data for this cell
		NSDictionary *keyPair = [self keyPairForIndexPath:indexPath];
		NSUInteger lines = [[keyPair[@"value"] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] count];
		
		return (20 * lines) + 20;
	}
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;
{
	if (section == 0) {
		return nil;
	} else if (section == 1) {
		return nil;
	} else {
		
		NSString *key = self.selectedCard.cardDictionary.allKeys[section-2];
		id value = self.selectedCard.cardDictionary[key];
		if ([value isKindOfClass:[NSString class]]) {
			
			// Simple string values have their key listed in the table cell, not the header
			return nil;
		} else if ([value isKindOfClass:[NSDictionary class]]) {
			
			// Complex fields should display the parent key as a header. Each of the sub-keys will be visible in the table cell.
			return key;
		} else if ([value isKindOfClass:[NSArray class]]) {
			
			// Complex fields should display the parent key as a header. Each of the sub-keys will be visible in the table cell.
			return key;
		} else {
			return nil;
		}
	}
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
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
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
