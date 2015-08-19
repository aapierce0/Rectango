//
//  DPBarcodeScannerViewController.m
//  Digidex Pro
//
//  Created by Avery Pierce on 8/16/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import "DPBarcodeScannerViewController.h"

#import "DKManagedCard.h"

@interface DPBarcodeScannerViewController () {
    BOOL _tryingURL;
}

@property AVCaptureDevice *device;
@property AVCaptureDeviceInput *input;
@property AVCaptureSession *session;
@property AVCaptureMetadataOutput *output;
@property AVCaptureVideoPreviewLayer *preview;

@end

@implementation DPBarcodeScannerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _tryingURL = NO;
    
//    [self setupScanner];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    
}

- (void)setupScanner;
{

	
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    self.input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
	
	if (!self.input) {
		
		// Alert the user that the camera is not available, and then bail.
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Camera Not Found"
																	   message:@"Your device does not have a camera, so it will not be able to scan QR Codes"
																preferredStyle:UIAlertControllerStyleAlert];
		
		[alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}]];
		
		[self presentViewController:alert animated:YES completion:^{}];
		
		return;
	}
	
    self.session = [[AVCaptureSession alloc] init];
    
    self.output = [[AVCaptureMetadataOutput alloc] init];
    [self.session addOutput:self.output];
    [self.session addInput:self.input];
    
    [self.output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    self.output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
    
    self.preview = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.preview.frame = self.scannerView.bounds;
    
    AVCaptureConnection *con = self.preview.connection;
    con.videoOrientation = [self videoOrientationForCurrentDeviceOrientation];
    
    [self.scannerView.layer insertSublayer:self.preview atIndex:0];
    
    [self.session startRunning];
	
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection;
{
    NSLog(@"metadataObjectsL %@", metadataObjects);
    for (AVMetadataMachineReadableCodeObject *metadataObject in metadataObjects) {
        NSURL *url = [NSURL URLWithString:metadataObject.stringValue];
        if (url != nil) {
            [self processURL:url];
        }
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation;
{
    self.preview.connection.videoOrientation = [self videoOrientationForCurrentDeviceOrientation];
}

- (AVCaptureVideoOrientation)videoOrientationForCurrentDeviceOrientation;
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    AVCaptureVideoOrientation videoOrientation;
    switch (orientation) {
        case UIDeviceOrientationPortrait:
            videoOrientation = AVCaptureVideoOrientationPortrait;
            break;
        case UIDeviceOrientationLandscapeLeft:
            videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIDeviceOrientationLandscapeRight:
            videoOrientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        default:
            videoOrientation = AVCaptureVideoOrientationPortrait;
            break;
    }
    
    return videoOrientation;
}



- (IBAction)createBogusCard:(id)sender {
    NSArray *bogusURLs = @[@"http://bloviations.net/contact/cardData0.json",
                           @"http://bloviations.net/contact/cardData1.json",
                           @"http://bloviations.net/contact/cardData2.json",
                           @"http://bloviations.net/contact/cardData3.json",
                           @"http://bloviations.net/contact/soulful_sparrow.json",
                           @"http://bloviations.net/contact/elgin_history_museum.json"];
    
    NSURL *bogusURL = [NSURL URLWithString:[bogusURLs objectAtIndex:(arc4random() % bogusURLs.count)]];
    [self processURL:bogusURL];
}

- (IBAction)submitURL:(id)sender {
	
	// Get the URL from the text field, and load it.
	NSURL *enteredURL = [NSURL URLWithString:self.URLTextField.text];
    [self processURL:enteredURL];
}

- (void)processURL:(NSURL*)url;
{
    if (!_tryingURL) {
        
        _tryingURL = YES;
        [DKManagedCard determineDigidexURLFromProvidedURL:url completion:^(NSURL *determinedURL) {
            
            NSLog(@"Provided URL: %@", url);
            NSLog(@"Determined URL: %@", determinedURL);
            
            if (determinedURL != nil) {
                [self dismiss];
                [[UIApplication sharedApplication] openURL:determinedURL];
            }
            
            _tryingURL = NO;
        }];
    }
}

- (IBAction)dismiss;
{
    [self.session stopRunning];
    [self.navigationController popViewControllerAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)activateScanner:(id)sender {
    [self setupScanner];
}
@end
