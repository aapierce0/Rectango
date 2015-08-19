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
	
	UIView *_cancelScanView;
	UIView *_scannedInfoView;
	
	BOOL _scannerIsShown;
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

- (UIStatusBarStyle)preferredStatusBarStyle;
{
	return UIStatusBarStyleLightContent;
}

- (BOOL)setupScanner;
{

	
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    self.input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
	
	if (!self.input) {
		
		// Alert the user that the camera is not available, and then bail.
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Camera Not Found"
																	   message:@"Your device does not have a camera, so it will not be able to scan QR Codes"
																preferredStyle:UIAlertControllerStyleAlert];
		
		[alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}]];
		
//		[self presentViewController:alert animated:YES completion:^{}];
//		return NO;
		return YES;
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
	return YES;
	
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection;
{
    NSLog(@"metadataObjectsL %@", metadataObjects);
    for (AVMetadataMachineReadableCodeObject *metadataObject in metadataObjects) {
		
		// Display a view that shows a progress spinner and the scanned URL
		_scannedInfoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
		_scannedInfoView.translatesAutoresizingMaskIntoConstraints = NO;
		_scannedInfoView.backgroundColor = [UIColor greenColor];
		[self.view addSubview:_scannedInfoView];
		[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_scannedInfoView]-|" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(_scannedInfoView)]];
		[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_scannedInfoView(==100)]-|" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(_scannedInfoView)]];
		
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
	
	if ([self setupScanner] && !_scannerIsShown) {
		
		_scannerIsShown = YES;
		
		// Create a "Cancel" button and place it off the bottom of the screen.
		// It will be animated into view when the Camera takes full screen.
		_cancelScanView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.scrollView.bounds.size.width, 50)];
		_cancelScanView.backgroundColor = [UIColor whiteColor];
		_cancelScanView.center = CGPointMake(_cancelScanView.bounds.size.width/2, self.scrollView.bounds.size.height + (_cancelScanView.bounds.size.height/2));
		
		_cancelScanView.layer.masksToBounds = NO;
		_cancelScanView.layer.shadowOffset = CGSizeMake(0, 1.0);
		_cancelScanView.layer.shadowRadius = 3.0;
		_cancelScanView.layer.shadowOpacity = 0.2;
		
		UILabel *cancelScanLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 20)];
		cancelScanLabel.text = @"Cancel";
		cancelScanLabel.textColor = [UIColor blueColor];
		cancelScanLabel.translatesAutoresizingMaskIntoConstraints = NO;
		
		[_cancelScanView addSubview:cancelScanLabel];
		[_cancelScanView addConstraint:[NSLayoutConstraint constraintWithItem:cancelScanLabel
																	attribute:NSLayoutAttributeCenterX
																	relatedBy:NSLayoutRelationEqual
																	   toItem:cancelScanLabel.superview
																	attribute:NSLayoutAttributeCenterX
																   multiplier:1.f constant:0.f]];
		
		[_cancelScanView addConstraint:[NSLayoutConstraint constraintWithItem:cancelScanLabel
																	attribute:NSLayoutAttributeCenterY
																	relatedBy:NSLayoutRelationEqual
																	   toItem:cancelScanLabel.superview
																	attribute:NSLayoutAttributeCenterY
																   multiplier:1.f constant:0.f]];
		
		[self.view addSubview:_cancelScanView];
		
		
		
		
		UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(deactivateScanner:)];
		[_cancelScanView addGestureRecognizer:tapGesture];
		
		
		self.scannerViewHeightConstraint.constant = self.scrollView.bounds.size.height;
		[self.scrollView setNeedsUpdateConstraints];
		
		self.backButton.enabled = NO;
		
		// Animate the scanner into the full screen
		[UIView animateWithDuration:0.4 animations:^{
			
			[self.scrollView layoutIfNeeded];
			
			// Fade out the auxillery controls
			self.auxView.alpha = 0.0;
			self.backButton.alpha = 0.0;
			
			// Move the cancel view into frame
			_cancelScanView.center = CGPointMake(_cancelScanView.bounds.size.width/2, self.scrollView.bounds.size.height - (_cancelScanView.bounds.size.height/2));
			
		} completion:^(BOOL finished) {
			
		}];
	}
}




- (IBAction)deactivateScanner:(id)sender;
{
	[self.session stopRunning];
	
	self.scannerViewHeightConstraint.constant = 200;
	[self.scrollView setNeedsUpdateConstraints];
	
	// Animate the scanner out of full screen
	[UIView animateWithDuration:0.4 animations:^{
		
		[self.scrollView layoutIfNeeded];
		
		// Fade out the auxillery controls
		self.auxView.alpha = 1.0;
		self.backButton.alpha = 1.0;
		
		// Move the cancel view into frame
		_cancelScanView.center = CGPointMake(_cancelScanView.bounds.size.width/2, self.scrollView.bounds.size.height + (_cancelScanView.bounds.size.height/2));
		_cancelScanView.layer.shadowOpacity = 0.2;
		
	} completion:^(BOOL finished) {
		
		self.backButton.enabled = YES;

		[_cancelScanView removeFromSuperview];
		_cancelScanView = nil;
		_scannerIsShown = NO;
		
	}];
}
@end
