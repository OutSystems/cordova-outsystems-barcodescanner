//
//  ScannerViewController.m
//  BarcodeTestApp
//
//  Created by Carlos Correa on 26/04/2021.
//

#import "ScannerViewController.h"
#import <AudioToolbox/AudioToolbox.h>

@interface ScannerViewController ()

@property (nonatomic, strong) ZXCapture *capture;
@property (nonatomic, weak) IBOutlet UIView *scanRectView;
@property (nonatomic, weak) IBOutlet UILabel *decodedLabel;
@property (nonatomic) BOOL scanning;
@property (nonatomic) BOOL isFirstApplyOrientation;

@end

@implementation ScannerViewController {
  CALayer *frameLayer;
  CGAffineTransform _captureSizeTransform;
}

#pragma mark - View Controller Methods

- (void)dealloc {
  [self.capture.layer removeFromSuperlayer];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.capture = [[ZXCapture alloc] init];
    self.capture.sessionPreset = AVCaptureSessionPreset1920x1080;
    self.capture.camera = self.capture.back;
    self.capture.focusMode = AVCaptureFocusModeContinuousAutoFocus;
    self.capture.delegate = self;
    
    self.scanning = NO;
    
    self.scanButton.layer.cornerRadius = 30;
    self.scanButton.clipsToBounds = YES;
    self.scanButton.imageEdgeInsets = UIEdgeInsetsMake(0, 100, 0, 0);
    
    [self.view.layer addSublayer:self.capture.layer];
    [self.view bringSubviewToFront:self.scanRectView];
    [self.view bringSubviewToFront:self.blurFrame];
    [self.view bringSubviewToFront:self.externalView];
    [self.view bringSubviewToFront:self.decodedLabel];
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]
       addObserver:self selector:@selector(orientationChanged:)
       name:UIDeviceOrientationDidChangeNotification
       object:[UIDevice currentDevice]];
    
}

- (void)viewDidAppear:(BOOL)animated{
    [self animateMovingBar];
    [self addGradientToView];
}

- (void)viewWillAppear:(BOOL)animated {
//  [super viewWillAppear:animated];

}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  
  if (_isFirstApplyOrientation) return;
  _isFirstApplyOrientation = TRUE;
  [self applyOrientation];
}

- (void)addGradientToView{
    CAGradientLayer *gradientUp = [CAGradientLayer layer];
    CAGradientLayer *gradientDown = [CAGradientLayer layer];

    gradientUp.frame = _laserGradientUp.bounds;
    gradientUp.colors = @[(id)[UIColor colorWithWhite:1 alpha:0].CGColor,(id)[UIColor whiteColor].CGColor];
    gradientDown.frame = _laserGradientUp.bounds;
    gradientDown.colors = @[(id)[UIColor whiteColor].CGColor, (id)[UIColor colorWithWhite:1 alpha:0].CGColor];

    [_laserGradientUp.layer insertSublayer:gradientUp atIndex:0];
    [_laserGradientDown.layer insertSublayer:gradientDown atIndex:0];
}

- (void)animateMovingBar{
    
    [UIView animateKeyframesWithDuration:2.0 delay:0.0 options:UIViewKeyframeAnimationOptionAutoreverse | UIViewKeyframeAnimationOptionRepeat animations:^{
        [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:1 animations:^{
            self.movingBarTopConstraint.constant = 0;
            [self->_scanRectView layoutIfNeeded];
        }];
        [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:1 animations:^{
            self.movingBarTopConstraint.constant = self->_scanRectView.bounds.size.height-3;
            [self->_scanRectView layoutIfNeeded];
        }];
    } completion:nil];
}

- (void) orientationChanged:(NSNotification *)note
{
    [self animateMovingBar];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
  [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
  [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
  } completion:^(id<UIViewControllerTransitionCoordinatorContext> context)
   {
     [self applyOrientation];
   }];
}

#pragma mark - Private
- (void)applyOrientation {
  UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
  float scanRectRotation;
  float captureRotation;
  
  switch (orientation) {
    case UIInterfaceOrientationPortrait:
      captureRotation = 0;
      scanRectRotation = 90;
      break;
    case UIInterfaceOrientationLandscapeLeft:
      captureRotation = 90;
      scanRectRotation = 180;
      break;
    case UIInterfaceOrientationLandscapeRight:
      captureRotation = 270;
      scanRectRotation = 0;
      break;
    case UIInterfaceOrientationPortraitUpsideDown:
      captureRotation = 180;
      scanRectRotation = 270;
      break;
    default:
      captureRotation = 90;
      scanRectRotation = 0;
      break;
  }
  self.capture.layer.frame = self.view.frame;
    self.capture.rotation = scanRectRotation;
    CGAffineTransform transform = CGAffineTransformMakeRotation((CGFloat)(captureRotation / 180 * M_PI));
  [self.capture setTransform:transform];
  [self applyRectOfInterest:orientation];
}

- (void)applyRectOfInterest:(UIInterfaceOrientation)orientation {
  CGFloat scaleVideoX, scaleVideoY;
  CGFloat videoSizeX, videoSizeY;
    CGRect transformedVideoRect = self.scanRectView.frame;
  if([self.capture.sessionPreset isEqualToString:AVCaptureSessionPreset1920x1080]) {
    videoSizeX = 1080;
    videoSizeY = 1920;
  } else {
    videoSizeX = 720;
    videoSizeY = 1280;
  }
  if(UIInterfaceOrientationIsPortrait(orientation)) {
    scaleVideoX = self.capture.layer.frame.size.width / videoSizeX;
    scaleVideoY = self.capture.layer.frame.size.height / videoSizeY;
    
    // Convert CGPoint under portrait mode to map with orientation of image
    // because the image will be cropped before rotate
    // reference: https://github.com/TheLevelUp/ZXingObjC/issues/222
    CGFloat realX = transformedVideoRect.origin.y;
    CGFloat realY = self.capture.layer.frame.size.width - transformedVideoRect.size.width - transformedVideoRect.origin.x;
    CGFloat realWidth = transformedVideoRect.size.height;
    CGFloat realHeight = transformedVideoRect.size.width;
    transformedVideoRect = CGRectMake(realX, realY, realWidth, realHeight);
  } else {
      scaleVideoX = self.capture.layer.frame.size.width / videoSizeY;
      scaleVideoY = self.capture.layer.frame.size.height / videoSizeX;
  }
  
  _captureSizeTransform = CGAffineTransformMakeScale(1.0/scaleVideoX, 1.0/scaleVideoY);
    self.capture.scanRect = [[UIScreen mainScreen] bounds];
    self.capture.scanRect = CGRectApplyAffineTransform(transformedVideoRect, _captureSizeTransform);
    self.capture.layer.frame = UIScreen.mainScreen.bounds;
}

#pragma mark - Private Methods

- (NSString *)barcodeFormatToString:(ZXBarcodeFormat)format {
  switch (format) {
    case kBarcodeFormatAztec:
      return @"Aztec";
      
    case kBarcodeFormatCodabar:
      return @"CODABAR";
      
    case kBarcodeFormatCode39:
      return @"Code 39";
      
    case kBarcodeFormatCode93:
      return @"Code 93";
      
    case kBarcodeFormatCode128:
      return @"Code 128";
      
    case kBarcodeFormatDataMatrix:
      return @"Data Matrix";
      
    case kBarcodeFormatEan8:
      return @"EAN-8";
      
    case kBarcodeFormatEan13:
      return @"EAN-13";
      
    case kBarcodeFormatITF:
      return @"ITF";
      
    case kBarcodeFormatPDF417:
      return @"PDF417";
      
    case kBarcodeFormatQRCode:
      return @"QR Code";
      
    case kBarcodeFormatRSS14:
      return @"RSS 14";
      
    case kBarcodeFormatRSSExpanded:
      return @"RSS Expanded";
      
    case kBarcodeFormatUPCA:
      return @"UPCA";
      
    case kBarcodeFormatUPCE:
      return @"UPCE";
      
    case kBarcodeFormatUPCEANExtension:
      return @"UPC/EAN extension";
      
    default:
      return @"Unknown";
  }
}

#pragma mark - ZXCaptureDelegate Methods

- (void)captureCameraIsReady:(ZXCapture *)capture {
//  self.scanning = YES;
}

- (void)captureResult:(ZXCapture *)capture result:(ZXResult *)result {
  if (!self.scanning) return;
  if (!result) return;
  
  // We got a result.
  [self.capture stop];
  self.scanning = NO;
  
  // Display found barcode location
  CGAffineTransform inverse = CGAffineTransformInvert(_captureSizeTransform);
  NSMutableArray *points = [[NSMutableArray alloc] init];
  NSString *location = @"";
  for (ZXResultPoint *resultPoint in result.resultPoints) {
    CGPoint cgPoint = CGPointMake(resultPoint.x, resultPoint.y);
    CGPoint transformedPoint = CGPointApplyAffineTransform(cgPoint, inverse);
    transformedPoint = [self.scanRectView convertPoint:transformedPoint toView:self.scanRectView.window];
    NSValue* windowPointValue = [NSValue valueWithCGPoint:transformedPoint];
    location = [NSString stringWithFormat:@"%@ (%f, %f)", location, transformedPoint.x, transformedPoint.y];
    [points addObject:windowPointValue];
  }
  
  // Display information about the result onscreen.
//  NSString *formatString = [self barcodeFormatToString:result.barcodeFormat];
  NSString *display = [NSString stringWithFormat:@"Scanned!\nContents:%@", result.text];
  [self.decodedLabel performSelectorOnMainThread:@selector(setText:) withObject:display waitUntilDone:YES];
  
  // Vibrate
  AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
  
    [self dissmissVC:result.text];
    
//  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//    self.scanning = YES;
//    [self.capture start];
//  });
}

- (IBAction)closeBtnPressed:(id)sender {
//    [self dismissViewControllerAnimated:true completion:nil];
    [self dissmissVC:@"error"];
}

- (IBAction)scanBtnPressed:(id)sender {
    // Vibrate
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    self.scanning = !self.scanning;
//    if (self.scanning) {
//        self.scanButton.backgroundColor = [UIColor darkGrayColor];
//    } else {
//        self.scanButton.backgroundColor = [UIColor lightGrayColor];
//    }
}

- (IBAction)flashBtnPressed:(id)sender {
    self.capture.torch = !self.capture.torch;
}

-(void)dissmissVC:(NSString*)message{
    [self dismissViewControllerAnimated:true completion:nil];
    NSLog(@"DismissViewController");

    //raise notification about dismiss
    [[NSNotificationCenter defaultCenter]
          postNotificationName:@"barcode reader finished"
                        object:message];
}

@end
