//
//  DPBarcodeScannerViewController.h
//  Digidex Pro
//
//  Created by Avery Pierce on 8/16/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
@import AddressBookUI;

@interface DPBarcodeScannerViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate, ABPeoplePickerNavigationControllerDelegate, UITextFieldDelegate>

- (IBAction)activateScanner:(id)sender;
@property (weak, nonatomic) IBOutlet UIView *scannerView;

@property (weak, nonatomic) IBOutlet UITextField *URLTextField;

- (IBAction)createBogusCard:(id)sender;
- (IBAction)debugCaptureURL:(id)sender;
- (IBAction)submitURL:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *tapToScanLabel;
@property (weak, nonatomic) IBOutlet UIImageView *tapToScanImageView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *debugItemButton;


@property (weak, nonatomic) IBOutlet UILabel *scanQRCodeLabel;
@property (weak, nonatomic) IBOutlet UIView *scanQRCodeDashedLineView;

- (IBAction)dismiss;

@end
