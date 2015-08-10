//
//  DPRootCollectionViewController.m
//  Digidex Pro
//
//  Created by Avery Pierce on 8/10/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import "DPRootCollectionViewController.h"

#define CELL_COUNT 30
#define CELL_IDENTIFIER @"Business Card"
#define HEADER_IDENTIFIER @"WaterfallHeader"
#define FOOTER_IDENTIFIER @"WaterfallFooter"

@interface DPRootCollectionViewController ()
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

- (NSMutableArray *)cellSizes {
	if (!_cellSizes) {
		_cellSizes = [NSMutableArray array];
		for (NSInteger i = 0; i < CELL_COUNT; i++) {
			CGSize size = CGSizeMake(arc4random() % 50 + 50, arc4random() % 50 + 50);
			_cellSizes[i] = [NSValue valueWithCGSize:size];
		}
	}
	return _cellSizes;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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
	return CELL_COUNT;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 2;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewCell *cell =
	(UICollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:CELL_IDENTIFIER
																				forIndexPath:indexPath];
	cell.backgroundColor = [UIColor grayColor];
	return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
	UICollectionReusableView *reusableView = nil;
	
//	if ([kind isEqualToString:CHTCollectionElementKindSectionHeader]) {
//		reusableView = [collectionView dequeueReusableSupplementaryViewOfKind:kind
//														  withReuseIdentifier:HEADER_IDENTIFIER
//																 forIndexPath:indexPath];
//	} else if ([kind isEqualToString:CHTCollectionElementKindSectionFooter]) {
//		reusableView = [collectionView dequeueReusableSupplementaryViewOfKind:kind
//														  withReuseIdentifier:FOOTER_IDENTIFIER
//																 forIndexPath:indexPath];
//	}
//	
//	return reusableView;

	return reusableView;
}

#pragma mark - CHTCollectionViewDelegateWaterfallLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	return [self.cellSizes[indexPath.item] CGSizeValue];
}

@end
