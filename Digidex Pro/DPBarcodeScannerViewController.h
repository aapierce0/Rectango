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



- (IBAction)activateScanner:(id)sender;
@property (weak, nonatomic) IBOutlet UIView *scannerView;

@property (weak, nonatomic) IBOutlet UITextField *URLTextField;

- (IBAction)createBogusCard:(id)sender;
- (IBAction)submitURL:(id)sender;
- (IBAction)dismiss;

@end
