//
//  ScannerViewController.m
//  BarcodeTestApp
//
//  Created by Carlos Correa on 26/04/2021.
//

#import "ScannerViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <QuartzCore/CoreAnimation.h>

@interface ScannerViewController ()

@property (nonatomic, strong) ZXCapture *capture;
@property (nonatomic, weak) IBOutlet UILabel *informationView;
@property (nonatomic, weak) IBOutlet UIView *movingBar;
@property (nonatomic, weak) IBOutlet UIView *scanRectView;
@property (nonatomic, weak) IBOutlet UILabel *decodedLabel;
@property (nonatomic, weak) CAGradientLayer *gradient;
@property (nonatomic) BOOL scanning;
@property (nonatomic) BOOL isFirstApplyOrientation;
@property (nonatomic) NSString* instructionsText;
@property (nonatomic) NSString* scanButtonTitle;
@property (nonatomic) CameraDirection direction;
@property (nonatomic) ScanOrientation orientation;
@property (nonatomic) bool lineEnabled;
@property (nonatomic) bool scanButtonEnabled;

@end

@implementation ScannerViewController {
    CALayer *frameLayer;
    CGAffineTransform _captureSizeTransform;
}

#pragma mark - View Controller Methods

-(instancetype)initWithScanInstructions:(NSString *)instructions CameraDirection:(CameraDirection)direction ScanOrientation:(ScanOrientation)orientation ScanLine:(bool)lineEnabled ScanButtonEnabled:(bool)buttonEnabled ScanButton:(NSString *)buttonTitle {
    self = [super initWithNibName:@"ScannerViewController" bundle:nil];
    self.instructionsText = instructions;
    self.scanButtonTitle = buttonTitle;
    self.direction = direction;
    self.orientation = orientation;
    self.lineEnabled = lineEnabled;
    self.scanButtonEnabled = buttonEnabled;
    return self;
}

- (void)dealloc {
    [self.capture.layer removeFromSuperlayer];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    switch (self.orientation) {
        case kPortrait:
            [[UIDevice currentDevice] setValue:[NSNumber numberWithInt:UIDeviceOrientationPortrait] forKey:@"orientation"];
            break;
        case kLandscape:
            [[UIDevice currentDevice] setValue:[NSNumber numberWithInt:UIDeviceOrientationPortrait] forKey:@"orientation"];
            break;
        default:
            break;
    }
    
    self.informationView.text = self.instructionsText;
    
    self.capture = [[ZXCapture alloc] init];
    self.capture.sessionPreset = AVCaptureSessionPreset1920x1080;
    switch (self.direction) {
        case kBack:
            self.capture.camera = self.capture.back;
            break;
        case kFront:
            self.capture.camera = self.capture.front;
            break;
        default:
            self.capture.camera = self.capture.back;
            break;
    }
    self.capture.focusMode = AVCaptureFocusModeContinuousAutoFocus;
    self.capture.delegate = self;
    
    self.scanning = NO;
    
    self.scanButton.clipsToBounds = YES;
    self.scanButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.scanButton.titleLabel.text = self.scanButtonTitle;
    self.scanButton.hidden = !self.scanButtonEnabled;
    
    self.movingBar.hidden = !self.lineEnabled;
    self.laserGradient.hidden = !self.lineEnabled;
    
    [self.view.layer insertSublayer:self.capture.layer atIndex:0];
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
}

- (void)viewDidAppear:(BOOL)animated{
    [self addGradientToView];
    [self animateMovingBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _laserGradient.hidden = false;
    CGFloat captureRotation = [self getCaptureRotation];
    CGFloat scanRectRotation = [self getScanRotation];
    self.capture.layer.bounds = self.view.bounds;
    self.capture.rotation = scanRectRotation;
    CGAffineTransform transform = CGAffineTransformMakeRotation((CGFloat)(captureRotation / 180 * M_PI));
    [self.capture setTransform:transform];
    [self applyRectOfInterest];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.scanButton.layer.cornerRadius = self.scanButton.bounds.size.height / 2;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations{
    switch (self.orientation) {
        case kAdaptive:
            return UIInterfaceOrientationMaskAll;
        case kPortrait:
            return UIInterfaceOrientationMaskPortrait;
        case kLandscape:
            return UIInterfaceOrientationMaskLandscape;
        default:
            return UIInterfaceOrientationMaskAll;
    }
}

- (void)addGradientToView{
    if(!self.lineEnabled) { return; }
    CAGradientLayer *gradientUp = [CAGradientLayer layer];
    
    gradientUp.colors = @[(id)[UIColor colorWithWhite:1 alpha:0].CGColor,(id)[UIColor whiteColor].CGColor,(id)[UIColor whiteColor].CGColor,(id)[UIColor colorWithWhite:1 alpha:0].CGColor];
    gradientUp.frame = self.laserGradient.bounds;
    gradientUp.locations = @[@0.5, @0.5, @0.5, @0.5];
    
    [_laserGradient.layer insertSublayer:gradientUp atIndex:0];
    
    self.gradient = gradientUp;
}

- (void)animateMovingBar{
    __weak ScannerViewController* weakSelf = self;
    [CATransaction begin];
    [CATransaction setAnimationDuration:8.0];
    
    [UIView animateKeyframesWithDuration:4.0 delay:0.0 options: UIViewKeyframeAnimationOptionRepeat | UIViewKeyframeAnimationOptionAutoreverse | UIViewKeyframeAnimationOptionCalculationModeLinear animations:^{
        [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0 animations:^{
            weakSelf.movingBarTopConstraint.constant = 0;
            [weakSelf.scanRectView layoutIfNeeded];
        }];
        [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:1 animations:^{
            weakSelf.movingBarTopConstraint.constant = weakSelf.scanRectView.bounds.size.height-3;
            [weakSelf.scanRectView layoutIfNeeded];
        }];
    } completion:nil];
    
    CAKeyframeAnimation* keyAnimation = [CAKeyframeAnimation animationWithKeyPath:@"locations"];
    NSArray* fromValues = @[@0.5, @0.5, @0.5, @0.5];
    NSArray* goingDownDrag = @[@0.0, @0.35, @0.5, @0.5];
    NSArray* goingUpDrag = @[@0.5, @0.5, @0.65, @1.0];
    keyAnimation.values = @[fromValues, goingDownDrag, fromValues, goingUpDrag, fromValues];
    keyAnimation.keyTimes = @[@0.0, @0.3, @0.5, @0.8, @1.0];
    //keyAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    keyAnimation.repeatCount = HUGE_VAL;
    [self.gradient addAnimation:keyAnimation forKey:@"locations"];
    [CATransaction commit];
    
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    __weak ScannerViewController* weakSelf = self;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [weakSelf applyOrientation:context.transitionDuration];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
        [weakSelf applyRectOfInterest];
        [self animateMovingBar];
    }];
}

#pragma mark - Private
- (void)applyOrientation:(CGFloat)animationTime {
    CGFloat captureRotation = [self getCaptureRotation];
    __weak ScannerViewController* weakSelf = self;
    [UIView animateWithDuration:animationTime animations:^{
        CGAffineTransform transform = CGAffineTransformMakeRotation((CGFloat)(captureRotation / 180 * M_PI));
        [weakSelf.capture setTransform:transform];
        weakSelf.gradient.frame = weakSelf.laserGradient.bounds;
    }];
}

-(CGFloat)getCaptureRotation {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            return 0;
        case UIInterfaceOrientationLandscapeLeft:
            return 90;
        case UIInterfaceOrientationLandscapeRight:
            return 270;
        case UIInterfaceOrientationPortraitUpsideDown:
            return 180;
        default:
            return 90;
    }
}

-(CGFloat)getScanRotation {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            return 90;
        case UIInterfaceOrientationLandscapeLeft:
            return 180;
        case UIInterfaceOrientationLandscapeRight:
            return 0;
        case UIInterfaceOrientationPortraitUpsideDown:
            return 270;
        default:
            return 0;
    }
}

- (void)applyRectOfInterest {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGFloat scaleVideoX, scaleVideoY;
    CGFloat videoSizeX, videoSizeY;
    CGRect transformedVideoRect = [self.view convertRect:self.scanRectView.frame fromView:self.scanRectView.superview];
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
        
        // Convert CGPoint under portrait mode to map with orientation of image
        // because the image will be cropped before rotate
        // reference: https://github.com/TheLevelUp/ZXingObjC/issues/222
        CGFloat realX = transformedVideoRect.origin.x;
        CGFloat realY = self.capture.layer.frame.size.height - transformedVideoRect.size.height - transformedVideoRect.origin.y;
        CGFloat realWidth = transformedVideoRect.size.width;
        CGFloat realHeight = transformedVideoRect.size.height;
        transformedVideoRect = CGRectMake(realX, realY, realWidth, realHeight);
    }
    
    _captureSizeTransform = CGAffineTransformMakeScale(1.0/scaleVideoX, 1.0/scaleVideoY);
    self.capture.scanRect = [[UIScreen mainScreen] bounds];
    CGRect rct = CGRectApplyAffineTransform(transformedVideoRect, _captureSizeTransform);
    self.capture.scanRect = rct;
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
    self.scanning = self.scanButtonEnabled ? self.scanning : YES;
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
    
    [self dissmissVC: result.text];
    
    //  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    //    self.scanning = YES;
    //    [self.capture start];
    //  });
}

- (IBAction)closeBtnPressed:(id)sender {
    [self dissmissVC:@"User closed before getting a result"];
}

- (IBAction)scanBtnPressed:(id)sender {
    // Vibrate
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    self.scanning = !self.scanning;
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


