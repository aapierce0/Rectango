//
//  DPRootCollectionViewController.m
//  Digidex Pro
//
//  Created by Avery Pierce on 8/10/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import "DPRootCollectionViewController.h"
#import "DigidexKit.h"
#import "DPCardCellView.h"
#import "DPDetailTableViewController.h"

#import "AFNetworking.h"

#define CELL_COUNT 4
#define CELL_IDENTIFIER @"Business Card"
#define HEADER_IDENTIFIER @"WaterfallHeader"
#define FOOTER_IDENTIFIER @"WaterfallFooter"

@interface DPRootCollectionViewController () {
	NSArray *_allCards;
	DKManagedCard *_selectedCard;
}
@property (nonatomic, strong) NSMutableArray *cellSizes;
@end

@implementation DPRootCollectionViewController

@synthesize editingActive = _editingActive;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
		self.useLayoutToLayoutNavigationTransitions = NO;
    }
    return self;
}



- (void)refreshAndSortCards;
{
    
    _allCards = [[[DKDataStore sharedDataStore] allContacts] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        DKManagedCard *card1 = obj1;
        DKManagedCard *card2 = obj2;
        
        NSComparisonResult result = [[card1 guessedName] compare:[card2 guessedName]];
        if (result == NSOrderedSame) {
            result = [[card1.originalURL description]  compare:[card2.originalURL description]];
        }
        
        return result;
    }];
}



- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	
	CHTCollectionViewWaterfallLayout *waterfallLayout = (CHTCollectionViewWaterfallLayout *)self.collectionViewLayout;
	
	waterfallLayout.sectionInset = UIEdgeInsetsMake(8, 8, 8, 8);
    waterfallLayout.headerHeight = 0;
    waterfallLayout.footerHeight = 8;
    waterfallLayout.minimumColumnSpacing = 8;
    waterfallLayout.minimumInteritemSpacing = 8;
	waterfallLayout.columnCount = 2;
	
    [self refreshAndSortCards];
	
	for (DKManagedCard *card in _allCards) {
		[self addListenersForCard:card];
	}
	
	[self disableEditing:nil];
	
}

- (void)viewWillAppear:(BOOL)animated;
{
    [self refreshAndSortCards];
    [self.collectionView reloadData];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/



- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration;
{
	CHTCollectionViewWaterfallLayout *waterfallLayout = (CHTCollectionViewWaterfallLayout *)self.collectionViewLayout;
	
	if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
		waterfallLayout.columnCount = 3;
	} else {
		waterfallLayout.columnCount = 2;
	}
	

}









#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return _allCards.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	DPCardCellView *cell =
	(DPCardCellView *)[collectionView dequeueReusableCellWithReuseIdentifier:CELL_IDENTIFIER
																				forIndexPath:indexPath];
	cell.backgroundColor = [UIColor whiteColor];
	
	// Get the card for this index
	DKManagedCard *card = _allCards[indexPath.item];
	
	// Add the card image to the cell
	if (card.cardThumbnailImage) {
		[cell.imageView setHidden:NO];
		[cell.imageView setImage:card.cardThumbnailImage];
		
		[cell.textLabel setHidden:YES];
	} else {
		[cell.imageView setHidden:YES];
		
		[cell.textLabel setHidden:NO];
		[cell.textLabel setText:[card guessedName]];
		[cell.textLabel setTextColor:self.view.tintColor];
	}
	
	cell.layer.masksToBounds = NO;
	cell.layer.shadowOffset = CGSizeMake(0, 1.0);
	cell.layer.shadowRadius = 1.0;
	cell.layer.shadowOpacity = 0.6;

	
	return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
{
	
	// If editing is not active, then display this card.
	if (!collectionView.allowsMultipleSelection) {
		
		// Immediately deselect this card
		[collectionView deselectItemAtIndexPath:indexPath animated:NO];
		
		UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone"
																 bundle: nil];
		
		DPDetailTableViewController *controller = (DPDetailTableViewController*)[mainStoryboard instantiateViewControllerWithIdentifier: @"DetailViewController"];
		
		DKManagedCard *selectedCard = _allCards[indexPath.item];
		controller.selectedCard = selectedCard;
		
		[self.navigationController pushViewController:controller animated:YES];
	}
}


#pragma mark - CHTCollectionViewDelegateWaterfallLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	return [self cellSizeForCard:_allCards[indexPath.item]];
}

- (CGSize)cellSizeForCard:(DKManagedCard*)card {
	
	// If the size is {0, 0}, then default to something more sensible
	if (CGSizeEqualToSize(CGSizeMake(0, 0), card.cardImageSize)) {
		return CGSizeMake(1260, 656);
	}
	
	return card.cardImageSize;
}









#pragma mark - toggle editing
- (IBAction)enableEditing:(id)sender;
{
	_editingActive = YES;
	self.collectionView.allowsMultipleSelection = YES;
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(disableEditing:)];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteSelectedCards:)];
}

- (IBAction)disableEditing:(id)sender;
{
	_editingActive = NO;
	self.collectionView.allowsMultipleSelection = NO;
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Select" style:UIBarButtonItemStylePlain target:self action:@selector(enableEditing:)];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"plus-outline"] style:UIBarButtonItemStylePlain target:self action:@selector(presentCardScanner:)];
	
	// mark all of the cells as deselected
	NSArray *selectedIndexPaths = [self.collectionView indexPathsForSelectedItems];
	for (NSIndexPath *selectedIndexPath in selectedIndexPaths) {
		[self.collectionView deselectItemAtIndexPath:selectedIndexPath animated:YES];
	}
}








#pragma mark - IBActions

- (IBAction)presentCardScanner:(id)sender;
{
	[self performSegueWithIdentifier:@"cardScannerSegue" sender:sender];
}

- (void)addListenersForCard:(DKManagedCard*)card; {
	
	[[NSNotificationCenter defaultCenter] addObserverForName:@"ThumbnailGenerated" object:card queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
		NSUInteger cardIndex = [_allCards indexOfObject:card];
		if (cardIndex != NSNotFound) {
			[self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:cardIndex inSection:0]]];
		}
	}];
}



- (IBAction)deleteSelectedCards:(id)sender;
{
	// Display a confirmation dialog
	UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
																   message:nil
															preferredStyle:UIAlertControllerStyleActionSheet];
	
	
	// This action will display red, because it is destructive
	NSArray *selectedIndexPaths = [self.collectionView indexPathsForSelectedItems];
	
	UIAlertAction* deleteAction = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Delete %li %@", selectedIndexPaths.count, (selectedIndexPaths.count == 1 ? @"Card" : @"Cards")]
														   style:UIAlertActionStyleDestructive
														 handler:^(UIAlertAction * action) {
															 
															 // Delete the selected cards...
															 NSArray *selectedIndexPaths = [self.collectionView indexPathsForSelectedItems];
															 for (NSIndexPath *selectedIndexPath in selectedIndexPaths) {
																 DKManagedCard *selectedCard = _allCards[selectedIndexPath.item];
																 [[DKDataStore sharedDataStore] deleteCard:selectedCard];
															 }
															 
															 [self refreshAndSortCards];
															 [self.collectionView deleteItemsAtIndexPaths:selectedIndexPaths];
															 [self disableEditing:sender];
														 }];
	
	
	// This cancel action will appear separated from the rest of the items
	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
														   style:UIAlertActionStyleCancel
														 handler:^(UIAlertAction * action) {}];
	
	
	// Add the actions to the alert
	[alert addAction:deleteAction];
	[alert addAction:cancelAction];
	
	alert.popoverPresentationController.barButtonItem = sender;
	
	
	[self presentViewController:alert animated:YES completion:nil];
}





@end
