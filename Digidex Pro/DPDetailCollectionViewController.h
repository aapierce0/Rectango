//
//  DPDetailCollectionViewController.h
//  Digidex Pro
//
//  Created by Avery Pierce on 8/11/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CHTCollectionViewWaterfallLayout.h"

@class DKManagedCard;

@interface DPDetailCollectionViewController : UICollectionViewController <CHTCollectionViewDelegateWaterfallLayout>

@property (strong) DKManagedCard *selectedCard;

@end
