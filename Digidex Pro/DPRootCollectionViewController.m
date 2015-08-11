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
#import "DPDetailCollectionViewController.h"

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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
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
	
	_allCards = [[DKDataStore sharedDataStore] allContacts];
	
	for (DKManagedCard *card in _allCards) {
		[self addListenersForCard:card];
	}
	
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender; {
	if ([segue.identifier isEqualToString:@"detailViewController"] && _selectedCard != nil) {
		[(DPDetailCollectionViewController*)segue.destinationViewController setSelectedCard:_selectedCard];
	}
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
	cell.backgroundColor = [UIColor grayColor];
	
	// Get the card for this index
	DKManagedCard *card = _allCards[indexPath.item];
	
	// Add the card image to the cell
	[cell.imageView setImage:card.cardImage];
	
	return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
{
	_selectedCard = _allCards[indexPath.item];
	NSLog(@"Card selected: %@", _selectedCard);
	[self performSegueWithIdentifier:@"detailViewController" sender:self];
}

#pragma mark - CHTCollectionViewDelegateWaterfallLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	return [self cellSizeForCard:_allCards[indexPath.item]];
}

- (CGSize)cellSizeForCard:(DKManagedCard*)card {
	
	NSLog(@"Size of cell: %@", NSStringFromCGSize(card.cardImage.size));
	
	// If the size is {0, 0}, then default to something more sensible
	if (CGSizeEqualToSize(CGSizeMake(0, 0), card.cardImage.size)) {
		return CGSizeMake(1260, 756);
	}
	
	return card.cardImage.size;
}




#pragma mark - IBActions
- (IBAction)createNewCard:(id)sender {
	
	int cardNumber = arc4random() % 4;
	NSString *cardURLString = [NSString stringWithFormat:@"http://bloviations.net/contact/cardData%i.json", cardNumber];
	NSURL *cardURL = [NSURL URLWithString:cardURLString];
	
	DKManagedCard *newCard = [[DKDataStore sharedDataStore] addContactWithURL:cardURL];
	_allCards = [[DKDataStore sharedDataStore] allContacts];
	
	[self.collectionView reloadData];
	[self addListenersForCard:newCard];
}

- (void)addListenersForCard:(DKManagedCard*)card; {
	
	[[NSNotificationCenter defaultCenter] addObserverForName:@"ImageLoaded" object:card queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
		NSUInteger cardIndex = [_allCards indexOfObject:card];
		if (cardIndex != NSNotFound) {
			[self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:cardIndex inSection:0]]];
		}
	}];
}



@end
