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
#import "DPCreateCardTableViewController.h"

#import "DKManagedCard.h"


@interface DPBarcodeScannerViewController () {
    BOOL _tryingURL;
	
	
	UIView *_scannedInfoView;
	UIActivityIndicatorView *_scannedInfoActivityIndicatorView;
	UILabel *_scannedInfoLabel;
	UIImageView *_scannedInfoImageView;
	UIImageView *_scannedCardImageView;
	
	// This variable will be animated when the a scanned info view appears.
	// The scanned info view starts outside of the scanner preview, then jumps
	// in like toast coming out of a toaster.
	NSLayoutConstraint *_scannedInfoViewVerticalOffsetConstraint;
	NSLayoutConstraint *_scannedCardImageViewVerticalOffsetConstraint;
	
	// This layout constraint represents the overall height of the bottom view,
	// including the entire text field.
	IBOutlet NSLayoutConstraint *_bottomViewHeight;
	CGFloat _bottomViewConstraintStartingHeight;
	
	// These variables are used to track whether or not a URL should be processed.
	NSString *_activeToken;
	NSDate *_lastScan;
	
	// These variables represent the currently loaded item, whether it's a card or a URL.
	DKManagedCard *_loadedCard;
	NSURL *_loadedAltURL;
	
	NSURL *_lastCapturedURL;
}

@property AVCaptureDevice *device;
@property AVCaptureDeviceInput *input;
@property AVCaptureSession *session;
@property AVCaptureMetadataOutput *output;
@property AVCaptureVideoPreviewLayer *preview;

@end









@implementation DPBarcodeScannerViewController


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}


// This view controller should not include a navigation bar.
// These two methods will cause the navigation bar to appear on child view controllers.
- (void)viewWillAppear:(BOOL)animated {
	[self.navigationController setNavigationBarHidden:YES animated:animated];
	[super viewWillAppear:animated];
}
- (void)viewWillDisappear:(BOOL)animated {
	[self.navigationController setNavigationBarHidden:NO animated:animated];
	[super viewWillDisappear:animated];
}

// The content of this view controller should be visisble beneath the status bar.
- (UIStatusBarStyle)preferredStatusBarStyle;
{
	return UIStatusBarStyleLightContent;
}


- (IBAction)dismiss;
{
	[self.URLTextField resignFirstResponder];
	[self.session stopRunning];
	[self.navigationController popViewControllerAnimated:YES];
	[self dismissViewControllerAnimated:YES completion:^{
	}];
}







#pragma mark - Initialization

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _tryingURL = NO;
	_lastScan = [NSDate distantPast];
	
#if TARGET_IPHONE_SIMULATOR
	[self.debugItemButton setHidden:NO];
	[self.debugItemButton setEnabled:YES];
#endif
    
	
	self.edgesForExtendedLayout = UIRectEdgeNone;
	
	self.tapToScanLabel.textColor = [UIColor lightGrayColor];
	self.tapToScanImageView.tintColor = [UIColor lightGrayColor];
	
	
	AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
	switch (authStatus) {
		case AVAuthorizationStatusAuthorized:
			// Immediately start the scanner
            [self setupScanner];
			break;
		case AVAuthorizationStatusDenied:
			self.tapToScanLabel.text = @"Camera access denied.\nGo to System Settings > Rectango to enable.";
			break;
		case AVAuthorizationStatusRestricted:
			self.tapToScanLabel.text = @"Camera access restricted.";
			break;
		case AVAuthorizationStatusNotDetermined:
			// The user may tap to grant permission
			break;
		default:
			break;
	}
	
	
	_bottomViewConstraintStartingHeight = _bottomViewHeight.constant;
	
	
	// We want to be notified if the keyboard appears, so we have a chance to move the text field up into view.
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillShow:)
												 name:UIKeyboardWillShowNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillHide:)
												 name:UIKeyboardWillHideNotification
											   object:nil];
}







#pragma mark - Keyboard animations

- (void)keyboardWillShow:(NSNotification*)notification;
{
	NSDictionary *info = [notification userInfo];
	CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
	
	// The height of the textfeild is 30 pts, and it has 8pts of spacing above and below.
	// 30 + 8 + 8
	NSInteger animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] integerValue];
	[self animateBottomViewHeight:MAX(_bottomViewConstraintStartingHeight, kbSize.height + 30 + 8 + 8) duration:animationDuration];
}

- (void)keyboardWillHide:(NSNotification*)notification
{
	NSDictionary *info = [notification userInfo];
	NSInteger animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] integerValue];
	[self animateBottomViewHeight:_bottomViewConstraintStartingHeight duration:animationDuration];
}

- (void)animateBottomViewHeight:(CGFloat)value duration:(NSTimeInterval)duration;
{
	[self.view layoutIfNeeded];
	
	[UIView animateWithDuration:duration animations:^{
		
		// Don't make it shorter than 165pts
		_bottomViewHeight.constant = value;
		[self.view layoutIfNeeded];
	}];
}











#pragma mark - UITextField delegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField;
{
	NSLog(@"Text did end");
	NSURL *URL = [NSURL URLWithString:[textField text]];
	[self captureURL:URL];
}











#pragma mark - Camera Setup

- (IBAction)activateScanner:(id)sender {
	
	AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
	if (authStatus == AVAuthorizationStatusNotDetermined) {
		[AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setupScanner];
            });
		}];
	}
	
    if (!self.session.isRunning && [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusAuthorized) {
		[self setupScanner];
	}
}

- (IBAction)deactivateScanner:(id)sender;
{
}

- (BOOL)setupScanner;
{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (authStatus) {
        case AVAuthorizationStatusDenied:
            self.tapToScanLabel.text = @"Camera access denied.\nGo to System Settings > Rectango to enable.";
            return NO;
        case AVAuthorizationStatusRestricted:
            self.tapToScanLabel.text = @"Camera access restricted.";
            return NO;
        default:
            break;
    }
    
    
    
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    self.input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
	
	// If there is no input device, then we fail.
	if (!self.input) {
		self.tapToScanLabel.text = @"No Camera Available";
		return NO;
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
    
    // Remove the camera image and the "tap to scan" label from the view.
    [self.tapToScanLabel removeFromSuperview];
    [self.tapToScanImageView removeFromSuperview];
    
	return YES;
	
}

// When the user interface rotates, be sure to update the orientation of the preview.
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation;
{
	if (self.preview && self.preview.connection)
		self.preview.connection.videoOrientation = [self videoOrientationForCurrentDeviceOrientation];
}
- (void)viewDidLayoutSubviews;
{
    self.preview.frame = self.scannerView.bounds;
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









#pragma mark - User Inputs

// This method is called when the camera detects a QR code.
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection;
{
	// If the last scan was less than 2 seconds ago, ignore this data.
	if ([[NSDate date] timeIntervalSinceDate:_lastScan] < 2)
		return;
	
	
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


// This is called from the text field
- (IBAction)submitURL:(id)sender {
	
	// Get the URL from the text field, and load it.
	NSURL *enteredURL = [NSURL URLWithString:self.URLTextField.text];
    [self processURL:enteredURL token:[self generateToken]];
}







#pragma mark - URL Processing

- (void)captureURL:(NSURL*)url;
{
	// If the URL is empty, bail out.
	if ([[url absoluteString] length] == 0)
		return;
	
	
	// If this URL doesn't have a scheme, add the HTTP scheme.
	NSLog(@"URL scheme: %@", url.scheme);
	if (!url.scheme) {
		url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", url]];
	}
	
	
	if ([url isEqual:_lastCapturedURL])
		return;
	
	_lastCapturedURL = url;
	
	
	
	if (_scannedInfoView != nil) {
		
		// Capture a reference to this old view.
		UIView *oldScannedInfoView = _scannedInfoView;
		NSLayoutConstraint *oldLayoutConstraint = _scannedInfoViewVerticalOffsetConstraint;
		
		// Capture a reference to the old card view
		UIView *oldCardImageView = _scannedCardImageView;
		NSLayoutConstraint *oldCardLayoutConstraint = _scannedCardImageViewVerticalOffsetConstraint;
		
		// nil out the instance variables. We're starting over!
		_scannedInfoView = nil;
		_scannedInfoViewVerticalOffsetConstraint = nil;
		_scannedCardImageView = nil;
		_scannedCardImageViewVerticalOffsetConstraint = nil;
		
		
		[self.view layoutIfNeeded];
		
		[UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
			
			NSInteger verticalMovement = 60;
			
			oldScannedInfoView.alpha = 0.0;
			oldLayoutConstraint.constant += verticalMovement;
			
			if (oldCardImageView != nil) {
				oldCardImageView.alpha = 0.0;
			}
			
			if (oldCardLayoutConstraint != nil) {
				oldCardLayoutConstraint.constant += verticalMovement;
			}
			
			[self.view layoutIfNeeded];
		} completion:^(BOOL finished) {
			[oldScannedInfoView removeFromSuperview];
		}];
		
		
		
	}
	
	// Display a view that shows a progress spinner and the scanned URL
	_scannedInfoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
	_scannedInfoView.translatesAutoresizingMaskIntoConstraints = NO;
	_scannedInfoView.backgroundColor = [UIColor whiteColor];
	_scannedInfoView.layer.cornerRadius = 6;
	
	_scannedInfoView.layer.masksToBounds = NO;
	_scannedInfoView.layer.shadowOffset = CGSizeMake(0, -1.0);
	_scannedInfoView.layer.shadowRadius = 2.0;
	_scannedInfoView.layer.shadowOpacity = 0.2;
	
	[self.scannerView addSubview:_scannedInfoView];
	[self.scannerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_scannedInfoView]-|" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(_scannedInfoView)]];
	
	NSArray *verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_scannedInfoView(==44)]-(-50)-|" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(_scannedInfoView)];
	for (NSLayoutConstraint *verticalConstraint in verticalConstraints) {
		// The vertical positioning constraint is -50. If this constraint has a constant of -50, then this is the offset constraint.
		if (verticalConstraint.constant == -50) {
			_scannedInfoViewVerticalOffsetConstraint = verticalConstraint;
			break;
		}
	}
	[self.scannerView addConstraints:verticalConstraints];
	
	
	
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
	
	
	
	
	// If the info view is tapped, launch the respective view
	UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(infoViewTapped:)];
	[_scannedInfoView addGestureRecognizer:tapGestureRecognizer];
	
	
	[self.view layoutIfNeeded];
	
	[UIView animateWithDuration:0.8 delay:0.0 usingSpringWithDamping:0.6 initialSpringVelocity:0.1 options:kNilOptions animations:^{
		if (_scannedInfoViewVerticalOffsetConstraint != nil) {
			_scannedInfoViewVerticalOffsetConstraint.constant = 16;
			[self.view layoutIfNeeded];
		}
	} completion:^(BOOL finished) {
		
	}];
	
	[self processURL:url token:[self generateToken]];
}

// This utility function will generate a random string.
// This random string is used to uniquely identify
- (NSString*)generateToken;
{
	NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
	NSMutableString *randomString = [NSMutableString stringWithCapacity: 10];
	
	for (int i=0; i<10; i++) {
		[randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((uint)[letters length])]];
	}
	
	return randomString;
}

- (void)processURL:(NSURL*)url token:(NSString*)token;
{
	// Capture the provided token here.
	// If the user tries to scan a new address, this will be overwritten, and we will know to ignore the old notifications.
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
			
			_loadedCard = [[DKDataStore sharedDataStore] makeTransientContactWithURL:determinedURL];
			
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
			
			
			// When the card image is loaded, display it with a toaster animation
			[[NSNotificationCenter defaultCenter] addObserverForName:@"ImageLoaded" object:_loadedCard queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
				
				// If the user attempted to load something else, ignore this data.
				if (![_activeToken isEqualToString:token])
					return;
				
				_scannedCardImageView = [[UIImageView alloc] initWithImage:_loadedCard.cardImage];
				_scannedCardImageView.translatesAutoresizingMaskIntoConstraints = NO;
				_scannedCardImageView.backgroundColor = [UIColor whiteColor];
				_scannedCardImageView.layer.cornerRadius = 6;
				
				_scannedCardImageView.layer.masksToBounds = NO;
				_scannedCardImageView.layer.shadowOffset = CGSizeMake(0, -1.0);
				_scannedCardImageView.layer.shadowRadius = 2.0;
				_scannedCardImageView.layer.shadowOpacity = 0.2;
				
				[self.scannerView insertSubview:_scannedCardImageView belowSubview:_scannedInfoView];
				[self.scannerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=20)-[_scannedCardImageView]-(>=20)-|" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(_scannedCardImageView)]];
				
				NSArray *verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_scannedCardImageView(<=120)]-(-100)-|" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(_scannedCardImageView)];
				for (NSLayoutConstraint *verticalConstraint in verticalConstraints) {
					// The vertical positioning constraint is -50. If this constraint has a constant of -50, then this is the offset constraint.
					if (verticalConstraint.constant == -100) {
						_scannedCardImageViewVerticalOffsetConstraint = verticalConstraint;
						break;
					}
				}
				[self.scannerView addConstraints:verticalConstraints];
				
				
				// Make sure the card is centered in the view
				NSLayoutConstraint *centerXConstraint = [NSLayoutConstraint constraintWithItem:_scannedCardImageView
																					 attribute:NSLayoutAttributeCenterX
																					 relatedBy:NSLayoutRelationEqual
																						toItem:self.scannerView
																					 attribute:NSLayoutAttributeCenterX
																					multiplier:1
																					  constant:0];
				[self.scannerView addConstraint:centerXConstraint];
				
				
				// Make sure to enfore the aspect ratio
				CGFloat aspectRatio = _loadedCard.cardImageSize.width / _loadedCard.cardImageSize.height;
				NSLayoutConstraint *aspectRatioConstraint =[NSLayoutConstraint constraintWithItem:_scannedCardImageView
																						attribute:NSLayoutAttributeWidth
																						relatedBy:NSLayoutRelationEqual
																						   toItem:_scannedCardImageView
																						attribute:NSLayoutAttributeHeight
																					   multiplier:aspectRatio
																						 constant:0.0f];
				[_scannedCardImageView addConstraint:aspectRatioConstraint];
				
				
				[self.view layoutIfNeeded];
				
				[UIView animateWithDuration:1.0 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.1 options:kNilOptions animations:^{
					if (_scannedCardImageViewVerticalOffsetConstraint != nil) {
						_scannedCardImageViewVerticalOffsetConstraint.constant = 50;
						[self.view layoutIfNeeded];
					}
				} completion:^(BOOL finished) {
					
				}];
				
			}];
		} else {
			
			_loadedAltURL = url;
			[_scannedInfoLabel setText:[url absoluteString]];
			
			[_scannedInfoImageView setImage:[UIImage imageNamed:@"safari-outline"]];
			[_scannedInfoImageView setTintColor:self.view.tintColor];
		
		}
		
	}];
}

- (void)infoViewTapped:(UIGestureRecognizer*)gestureRecognizer;
{
	if (_loadedCard) {
		
		DPDetailTableViewController *detailViewController = [[UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"DetailViewController"];
		detailViewController.selectedCard = _loadedCard;
		detailViewController.title = @"New Card";
		
		[self.navigationController pushViewController:detailViewController animated:YES];
		
	} else if (_loadedAltURL) {
		[[UIApplication sharedApplication] openURL:_loadedAltURL];
	}
}










#pragma mark - Debug Methods

// This method spoofs a captured URL
-(IBAction)debugCaptureURL:(id)sender;
{
	NSURL *bogusURL;
	if (arc4random() % 2 == 0)
		bogusURL = [DPBarcodeScannerViewController bogusURL];
	else
		bogusURL = [NSURL URLWithString:@"http://digidex.org/"];
	
	[self captureURL:bogusURL];
}

- (IBAction)createBogusCard:(id)sender {
	
	NSURL *bogusURL = [DPBarcodeScannerViewController bogusURL];
	[self processURL:bogusURL token:[self generateToken]];
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


@end
