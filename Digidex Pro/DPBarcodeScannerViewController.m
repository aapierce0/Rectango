//
//  DPBarcodeScannerViewController.m
//  Digidex Pro
//
//  Created by Avery Pierce on 8/16/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import "DigidexKit.h"
#import "DPBarcodeScannerViewController.h"
#import "DPDetailTableViewController.h"

#import "DKManagedCard.h"

@interface DPBarcodeScannerViewController () {
    BOOL _tryingURL;
	
	UIView *_cancelScanView;
	
	UIView *_scannedInfoView;
	UIActivityIndicatorView *_scannedInfoActivityIndicatorView;
	UILabel *_scannedInfoLabel;
	UIImageView *_scannedInfoImageView;
	
	NSLayoutConstraint *_cancelButtonVerticalOffsetConstraint;
	NSLayoutConstraint *_scannedInfoViewVerticalOffsetConstraint;
	
	BOOL _scannerIsShown;
	
	NSString *_activeToken;
	
	NSDate *_lastScan;
	
	DKManagedCard *_loadedCard;
	NSURL *_loadedAltURL;
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
	_lastScan = [NSDate distantPast];
	
#if TARGET_IPHONE_SIMULATOR
	[self.debugItemButton setHidden:NO];
	[self.debugItemButton setEnabled:YES];
#endif
	
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
    self.scannerView.layer.masksToBounds = YES;
    
    [self.session startRunning];
	return YES;
	
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection;
{
	// If the last scan was less than 3 seconds ago, ignore this data.
	if ([[NSDate date] timeIntervalSinceDate:_lastScan] < 3)
		return;
	
    NSLog(@"metadataObjectsL %@", metadataObjects);
    for (AVMetadataMachineReadableCodeObject *metadataObject in metadataObjects) {
		
		// Capture the URL
        NSURL *url = [NSURL URLWithString:metadataObject.stringValue];
        if (url != nil) {
			
			// Set the last scan to now.
			_lastScan = [NSDate date];
            [self captureURL:url];
        }
    }
}

-(IBAction)debugCaptureURL:(id)sender;
{

	
	NSURL *bogusURL;
	if (arc4random() % 2 == 0)
		bogusURL = [DPBarcodeScannerViewController bogusURL];
	else
		bogusURL = [NSURL URLWithString:@"http://www.example.org"];
	
	[self captureURL:bogusURL];
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


+ (NSURL*)bogusURL;
{
	NSArray *bogusURLs = @[@"http://bloviations.net/contact/cardData0.json",
						   @"http://bloviations.net/contact/cardData1.json",
						   @"http://bloviations.net/contact/cardData2.json",
						   @"http://bloviations.net/contact/cardData3.json",
						   @"http://bloviations.net/contact/soulful_sparrow.json",
						   @"http://bloviations.net/contact/elgin_history_museum.json"];
	
	NSURL *bogusURL = [NSURL URLWithString:[bogusURLs objectAtIndex:(arc4random() % bogusURLs.count)]];
	return bogusURL;
}


- (IBAction)createBogusCard:(id)sender {
	
	NSURL *bogusURL = [DPBarcodeScannerViewController bogusURL];
    [self processURL:bogusURL token:[self generateToken]];
}

- (IBAction)submitURL:(id)sender {
	
	// Get the URL from the text field, and load it.
	NSURL *enteredURL = [NSURL URLWithString:self.URLTextField.text];
    [self processURL:enteredURL token:[self generateToken]];
}


- (void)captureURL:(NSURL*)url;
{
	if (_scannedInfoView != nil) {
		[_scannedInfoView removeFromSuperview];
		_scannedInfoView = nil;
	}
	
	// Display a view that shows a progress spinner and the scanned URL
	_scannedInfoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
	_scannedInfoView.translatesAutoresizingMaskIntoConstraints = NO;
	_scannedInfoView.backgroundColor = [UIColor whiteColor];
	_scannedInfoView.layer.cornerRadius = 6;
	
	_scannedInfoView.layer.masksToBounds = NO;
	_scannedInfoView.layer.shadowOffset = CGSizeMake(0, -1.0);
	_scannedInfoView.layer.shadowRadius = 2.0;
	_scannedInfoView.layer.shadowOpacity = 0.1;
	
	[self.view insertSubview:_scannedInfoView belowSubview:_cancelScanView];
	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_scannedInfoView]-|" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(_scannedInfoView)]];
	
	NSArray *verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_scannedInfoView(==44)]-(-50)-[_cancelScanView]" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(_scannedInfoView, _cancelScanView)];
	for (NSLayoutConstraint *verticalConstraint in verticalConstraints) {
		// The vertical positioning constraint is -50. If this constraint has a constant of -50, then this is the offset constraint.
		if (verticalConstraint.constant == -50) {
			_scannedInfoViewVerticalOffsetConstraint = verticalConstraint;
			break;
		}
	}
	[self.view addConstraints:verticalConstraints];
	
	
	
	// Add a progress indicator to the scanned view...
	_scannedInfoActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	_scannedInfoActivityIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
	[_scannedInfoView addSubview:_scannedInfoActivityIndicatorView];
	

	_scannedInfoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
	_scannedInfoLabel.translatesAutoresizingMaskIntoConstraints = NO;
	_scannedInfoLabel.text = [url absoluteString];
	_scannedInfoLabel.font = [UIFont systemFontOfSize:14];
	_scannedInfoLabel.textAlignment = NSTextAlignmentLeft;
	_scannedInfoLabel.textColor = [UIColor grayColor];
	[_scannedInfoView addSubview:_scannedInfoLabel];
	
	
	_scannedInfoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
	_scannedInfoImageView.translatesAutoresizingMaskIntoConstraints = NO;
	_scannedInfoImageView.contentMode = UIViewContentModeScaleAspectFit;
	[_scannedInfoView addSubview:_scannedInfoImageView];
	
	
	[_scannedInfoView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(12)-[_scannedInfoActivityIndicatorView]-(8)-[_scannedInfoLabel]-(>=8)-|" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(_scannedInfoActivityIndicatorView, _scannedInfoLabel)]];
	[_scannedInfoView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(12)-[_scannedInfoImageView(22)]" options:NSLayoutFormatAlignAllCenterY metrics:nil views:NSDictionaryOfVariableBindings(_scannedInfoImageView)]];
	[_scannedInfoView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[_scannedInfoActivityIndicatorView]-|" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(_scannedInfoActivityIndicatorView)]];
	[_scannedInfoView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[_scannedInfoLabel]-|" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(_scannedInfoLabel)]];
	[_scannedInfoView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[_scannedInfoImageView]-|" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(_scannedInfoImageView)]];
	[_scannedInfoActivityIndicatorView startAnimating];
	[_scannedInfoActivityIndicatorView setHidesWhenStopped:YES];
	
	
	[self.view layoutIfNeeded];
	
	
	// If the info view is tapped, launch the respective view
	UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(infoViewTapped:)];
	[_scannedInfoView addGestureRecognizer:tapGestureRecognizer];
	
	
	
	[UIView animateWithDuration:0.8 delay:0.0 usingSpringWithDamping:0.6 initialSpringVelocity:0.1 options:kNilOptions animations:^{
		if (_scannedInfoViewVerticalOffsetConstraint != nil) {
			_scannedInfoViewVerticalOffsetConstraint.constant = 16;
			[self.view layoutIfNeeded];
		}
	} completion:^(BOOL finished) {
		
	}];
	
	[self processURL:url token:[self generateToken]];
}

- (void)infoViewTapped:(UIGestureRecognizer*)gestureRecognizer;
{
	if (_loadedCard) {
		
		DPDetailTableViewController *detailViewController = [[UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"DetailViewController"];
		detailViewController.selectedCard = _loadedCard;
		detailViewController.title = @"New Card";
		
		UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:detailViewController];
		
		[self presentViewController:navigationController animated:YES completion:^{
		}];
	} else if (_loadedAltURL) {
		[[UIApplication sharedApplication] openURL:_loadedAltURL];
	}
}

- (void)processURL:(NSURL*)url token:(NSString*)token;
{
	_activeToken = token;
	
	_loadedCard = nil;
	_loadedAltURL = nil;
	
	[DKManagedCard determineDigidexURLFromProvidedURL:url completion:^(NSURL *determinedURL) {
		
		// If the user attempted to load something else, ignore this data.
		if (![_activeToken isEqualToString:token])
			return;
		
		[_scannedInfoActivityIndicatorView stopAnimating];
		
		[_scannedInfoLabel setTextAlignment:NSTextAlignmentCenter];
		[_scannedInfoLabel setTextColor:self.view.tintColor];
		[_scannedInfoLabel setFont:[UIFont systemFontOfSize:16]];
		
		if (determinedURL != nil) {
			
			_loadedCard = [[DKDataStore sharedDataStore] makeTransientContactWithURL:url];
			
			[_scannedInfoLabel setText:[determinedURL absoluteString]];
			
			[_scannedInfoImageView setImage:[UIImage imageNamed:@"digidex-card-outline"]];
			[_scannedInfoImageView setTintColor:self.view.tintColor];
			
			
			// When the contact is loaded, update the name.
			[[NSNotificationCenter defaultCenter] addObserverForName:@"ContactLoaded" object:_loadedCard queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
				
				// If the user attempted to load something else, ignore this data.
				if (![_activeToken isEqualToString:token])
					return;
				
				[_scannedInfoLabel setText:[_loadedCard guessedName]];
			}];
		} else {
			
			_loadedAltURL = url;
			[_scannedInfoLabel setText:[url absoluteString]];
			
			[_scannedInfoImageView setImage:[UIImage imageNamed:@"safari-outline"]];
			[_scannedInfoImageView setTintColor:self.view.tintColor];
		
		}
		
	}];
}

- (IBAction)dismiss;
{
    [self.session stopRunning];
    [self.navigationController popViewControllerAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}

- (NSString*)generateToken;
{
	NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
	NSMutableString *randomString = [NSMutableString stringWithCapacity: 10];
	
	for (int i=0; i<10; i++) {
		[randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((uint)[letters length])]];
	}
	
	return randomString;
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
	
    if (_scannerIsShown)
        return; // The scanner is already shown. Turn back.
    
	if ([self setupScanner]) {
		
		_scannerIsShown = YES;
		
		// Create a "Cancel" button and place it off the bottom of the screen.
		// It will be animated into view when the Camera takes full screen.
		_cancelScanView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.scrollView.bounds.size.width, 50)];
		_cancelScanView.translatesAutoresizingMaskIntoConstraints = NO;
		_cancelScanView.backgroundColor = [UIColor whiteColor];
		
		_cancelScanView.layer.masksToBounds = NO;
		_cancelScanView.layer.shadowOffset = CGSizeMake(0, -1.0);
		_cancelScanView.layer.shadowRadius = 5.0;
		_cancelScanView.layer.shadowOpacity = 0.2;
		
		
		UILabel *cancelScanLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 20)];
		cancelScanLabel.text = @"Cancel";
        cancelScanLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
		cancelScanLabel.textColor = self.view.tintColor;
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
		
		[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(0)-[_cancelScanView]-(0)-|" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(_cancelScanView)]];
		NSArray *verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_cancelScanView(==50)]-(-50)-|" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(_cancelScanView)];
		for (NSLayoutConstraint *verticalConstraint in verticalConstraints) {
			// The vertical positioning constraint is -50. If this constraint has a constant of -50, then this is the offset constraint.
			if (verticalConstraint.constant == -50) {
				_cancelButtonVerticalOffsetConstraint = verticalConstraint;
				break;
			}
		}
		
		[self.view addConstraints:verticalConstraints];
		[self.view layoutIfNeeded];
		
		
		UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(deactivateScanner:)];
		[_cancelScanView addGestureRecognizer:tapGesture];
		
		
		self.scannerViewHeightConstraint.constant = self.scrollView.bounds.size.height;
		[self.scrollView setNeedsUpdateConstraints];
		
		self.backButton.enabled = NO;
        self.preview.opacity = 0.0;
        
        self.scrollView.scrollEnabled = NO;
		
		// Animate the scanner into the full screen
		[UIView animateWithDuration:0.4 animations:^{
			
			[self.scrollView layoutIfNeeded];
            self.preview.frame = self.scannerView.bounds;
            self.preview.opacity = 1.0;
			
			// Fade out the auxillery controls
			self.auxView.alpha = 0.0;
			self.backButton.alpha = 0.0;
            self.tapToScanLabel.alpha = 0.0;
			
			// Move the cancel view into frame
			_cancelScanView.layer.shadowOpacity = 0.6;
			if (_cancelButtonVerticalOffsetConstraint != nil) {
				_cancelButtonVerticalOffsetConstraint.constant = 0;
				[self.view layoutIfNeeded];
			}
			
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
        self.tapToScanLabel.alpha = 1.0;
        self.preview.opacity = 0.0;
		
		// Move the cancel view into frame
		_cancelScanView.layer.shadowOpacity = 0.2;
		if (_cancelButtonVerticalOffsetConstraint != nil) {
			_cancelButtonVerticalOffsetConstraint.constant = -50;
		}
		
		if (_scannedInfoViewVerticalOffsetConstraint != nil) {
			_scannedInfoViewVerticalOffsetConstraint.constant = -50;
		}
		
		[self.view layoutIfNeeded];
		
	} completion:^(BOOL finished) {
		
		self.backButton.enabled = YES;

		[_cancelScanView removeFromSuperview];
		_cancelScanView = nil;
		_cancelButtonVerticalOffsetConstraint = nil;
		_scannerIsShown = NO;
		
		if (_scannedInfoView != nil) {
			[_scannedInfoView removeFromSuperview];
			_scannedInfoView = nil;
			_scannedInfoViewVerticalOffsetConstraint = nil;
		}
		
		
        
        [self.preview removeFromSuperlayer];
        self.scrollView.scrollEnabled = YES;
		
	}];
}
@end
