//
//  DPDetailCollectionViewController.m
//  Digidex Pro
//
//  Created by Avery Pierce on 8/11/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import "DPDetailCollectionViewController.h"

#import "CHTCollectionViewWaterfallLayout.h"
#import "DKDataStore.h"
#import "DKManagedCard.h"
#import "DPCardCellView.h"

#define CELL_IDENTIFIER @"Business Card"

@interface DPDetailCollectionViewController ()

@end

@implementation DPDetailCollectionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
		self.useLayoutToLayoutNavigationTransitions = YES;
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
	waterfallLayout.columnCount = 1;
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
	return 1;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 2;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	DPCardCellView *cell =
	(DPCardCellView *)[collectionView dequeueReusableCellWithReuseIdentifier:CELL_IDENTIFIER
																forIndexPath:indexPath];
	cell.backgroundColor = [UIColor grayColor];
	
	// Get the card for this index
	DKManagedCard *card = self.selectedCard;
	
	// Add the card image to the cell
	[cell.imageView setImage:card.cardImage];
	
	return cell;
}



#pragma mark - CHTCollectionViewDelegateWaterfallLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	return [self cellSizeForCard:self.selectedCard];
}

- (CGSize)cellSizeForCard:(DKManagedCard*)card {
	
	NSLog(@"Size of cell: %@", NSStringFromCGSize(card.cardImage.size));
	
	// If the size is {0, 0}, then default to something more sensible
	if (CGSizeEqualToSize(CGSizeMake(0, 0), card.cardImage.size)) {
		return CGSizeMake(1260, 756);
	}
	
	return card.cardImage.size;
}

@end
