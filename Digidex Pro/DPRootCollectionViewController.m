//
//  DPRootCollectionViewController.m
//  Digidex Pro
//
//  Created by Avery Pierce on 8/10/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import "DPRootCollectionViewController.h"
#import "DigidexKit.h"

#define CELL_COUNT 4
#define CELL_IDENTIFIER @"Business Card"
#define HEADER_IDENTIFIER @"WaterfallHeader"
#define FOOTER_IDENTIFIER @"WaterfallFooter"

@interface DPRootCollectionViewController () {
	NSArray *_allCards;
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
	
	_allCards = [[DKDataStore sharedDataStore] allContacts];
	NSLog(@"All Cards %@", _allCards);
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

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return _allCards.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewCell *cell =
	(UICollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:CELL_IDENTIFIER
																				forIndexPath:indexPath];
	cell.backgroundColor = [UIColor grayColor];
	
	// Empty the Cell
	for (UIView *subview in cell.subviews) {
		[subview removeFromSuperview];
	}
	
	// Get the card for this index
	DKManagedCard *card = _allCards[indexPath.item];
	
	// Add the card image to the cell
	UIImageView *imageView = [[UIImageView alloc] initWithFrame:cell.bounds];
	[imageView setImage:card.cardImage];
	[cell addSubview:imageView];
	
	NSLog(@"Card: %@", card);
	
	return cell;
}

#pragma mark - CHTCollectionViewDelegateWaterfallLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	return [self cellSizeForCard:_allCards[indexPath.item]];
}

- (CGSize)cellSizeForCard:(DKManagedCard*)card {
	return card.cardImage.size;
}




#pragma mark - IBActions
- (IBAction)createNewCard:(id)sender {
	
	int cardNumber = arc4random() % 4;
	NSString *cardURLString = [NSString stringWithFormat:@"http://bloviations.net/contact/cardData%i.json", cardNumber];
	NSURL *cardURL = [NSURL URLWithString:cardURLString];
	
	[[DKDataStore sharedDataStore] addContactWithURL:cardURL];
	_allCards = [[DKDataStore sharedDataStore] allContacts];
	[self.collectionView reloadData];
}



@end
