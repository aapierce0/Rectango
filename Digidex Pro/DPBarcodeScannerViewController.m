//
//  DPBarcodeScannerViewController.m
//  Digidex Pro
//
//  Created by Avery Pierce on 8/16/15.
//  Copyright (c) 2015 Avery Pierce. All rights reserved.
//

#import "DPBarcodeScannerViewController.h"

@interface DPBarcodeScannerViewController ()

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
    
    [self setupScanner];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)setupScanner;
{
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    self.input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    self.session = [[AVCaptureSession alloc] init];
    
    self.output = [[AVCaptureMetadataOutput alloc] init];
    [self.session addOutput:self.output];
    [self.session addInput:self.input];
    
    [self.output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    self.output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
    
    self.preview = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.preview.frame = self.view.bounds;
    
    AVCaptureConnection *con = self.preview.connection;
    con.videoOrientation = [self videoOrientationForCurrentDeviceOrientation];
    
    [self.view.layer insertSublayer:self.preview atIndex:0];
    
    [self.session startRunning];
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection;
{
    NSLog(@"metadataObjectsL %@", metadataObjects);
    for (AVMetadataMachineReadableCodeObject *metadataObject in metadataObjects) {
        NSURL *url = [NSURL URLWithString:metadataObject.stringValue];
        if (url != nil) {
            [self.session stopRunning];
            
            [self dismiss];
            [[UIApplication sharedApplication] openURL:url];
            if ([url.scheme isEqualToString:@"digidex"]) {
            } else {
            }
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

@end
