//
//  DPChooseImageTableViewCell.h
//  Rectango
//
//  Created by Avery Pierce on 11/1/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DPChooseImageTableViewCell : UITableViewCell

@property (readwrite, weak, nonatomic) IBOutlet UIImageView *chooseImageView;
@property (readwrite, weak, nonatomic) IBOutlet UILabel *chooseTextLabel;

@end
