//
//  DPBarcodeScannerViewController.h
//  Digidex Pro
//
//  Created by Avery Pierce on 8/16/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface DPBarcodeScannerViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate>


@property (weak, nonatomic) IBOutlet UIView *scannerView;

@property (weak, nonatomic) IBOutlet UITextField *URLTextField;

- (IBAction)submitURL:(id)sender;
- (IBAction)dismiss;

@end
