//
//  DPRootCollectionViewController.h
//  Digidex Pro
//
//  Created by Avery Pierce on 8/10/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CHTCollectionViewWaterfallLayout.h"

@interface DPRootCollectionViewController : UICollectionViewController <CHTCollectionViewDelegateWaterfallLayout>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *addNewCardBarButtonItem;
@property (readonly) BOOL editingActive;

@end
