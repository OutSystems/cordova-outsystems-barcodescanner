//
//  ScannerViewController.m
//  BarcodeTestApp
//
//  Created by Carlos Correa on 26/04/2021.
//

#import "ScannerViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <QuartzCore/CoreAnimation.h>
#import "OSBarcodeErrors.h"

@interface ScannerViewController ()

@property (nonatomic, strong) ZXCapture *capture;
@property (nonatomic, weak) IBOutlet UILabel *informationView;
@property (nonatomic, weak) IBOutlet UIView *movingBar;
@property (nonatomic, weak) IBOutlet UIView *scanRectView;
@property (nonatomic, weak) IBOutlet UILabel *decodedLabel;
@property (nonatomic, weak) UIView *captureView;
@property (nonatomic, weak) CAGradientLayer *gradient;
@property (nonatomic) BOOL scanning;
@property (nonatomic) BOOL isFirstApplyOrientation;
@property (nonatomic) NSString* instructionsText;
@property (nonatomic) NSString* scanButtonTitle;
@property (nonatomic) CameraDirection direction;
@property (nonatomic) ScanOrientation orientation;
@property (nonatomic) bool lineEnabled;
@property (nonatomic) bool scanButtonEnabled;
@property (nonatomic) NSString* scanType;

@end

@implementation ScannerViewController {
    CALayer *frameLayer;
    CGAffineTransform _captureSizeTransform;
}

#pragma mark - View Controller Methods

-(instancetype)initWithScanInstructions:(NSString *)instructions CameraDirection:(CameraDirection)direction ScanOrientation:(ScanOrientation)orientation ScanLine:(bool)lineEnabled ScanButtonEnabled:(bool)buttonEnabled ScanButton:(NSString *)buttonTitle ScanType:(NSString *)scanType{
    self = [super initWithNibName:nil bundle:nil];
    self.instructionsText = instructions;
    self.scanButtonTitle = buttonTitle;
    self.direction = direction;
    self.orientation = orientation;
    self.lineEnabled = lineEnabled;
    self.scanButtonEnabled = buttonEnabled;
    self.scanType = scanType;
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
    
    self.scanning = NO;
    self.capture.delegate = self;
    
    self.scanButton.layer.cornerRadius = 25;
    self.scanButton.clipsToBounds = YES;
    self.scanButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.scanButton setTitle:self.scanButtonTitle forState:UIControlStateNormal];
    self.scanButton.hidden = !self.scanButtonEnabled;
    
    self.movingBar.hidden = !self.lineEnabled;
    self.laserGradient.hidden = !self.lineEnabled;
    
    self.view.backgroundColor = UIColor.blackColor;
    
    UIView* cap = [[UIView alloc] init];
    [cap setTranslatesAutoresizingMaskIntoConstraints:false];
    [self.view addSubview:cap];
    [[cap.topAnchor constraintEqualToAnchor:self.view.topAnchor] setActive:YES];
    [[cap.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor] setActive:YES];
    [[cap.rightAnchor constraintEqualToAnchor:self.view.rightAnchor] setActive:YES];
    [[cap.leftAnchor constraintEqualToAnchor:self.view.leftAnchor] setActive:YES];
    [cap.layer addSublayer:self.capture.layer];
    
    [self.view sendSubviewToBack:cap];
    self.captureView = cap;
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    self.capture.layer.frame = self.view.bounds;
    
    CGFloat scanRectRotation = [self getScanRotation];
    self.capture.rotation = scanRectRotation;
   
    self.capture.layer.frame = self.view.bounds;
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    [self applyRectOfInterest:orientation];
    [self addGradientToView];
    [self animateMovingBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    CGFloat captureRotation = [self getCaptureRotation];
    CGAffineTransform transform = CGAffineTransformMakeRotation((CGFloat)(captureRotation / 180 * M_PI));
    [self.capture setTransform:transform];
    self.capture.layer.frame = UIScreen.mainScreen.bounds;
    _laserGradient.hidden = false;
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
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        [weakSelf applyRectOfInterest:orientation];
        [weakSelf animateMovingBar];
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
            captureRotation = 0;
            scanRectRotation = 90;
            break;
    }
    
    [self applyRectOfInterest:orientation];
    
    CGFloat angleRadius = captureRotation / 180 * M_PI;
    CGAffineTransform transform = CGAffineTransformMakeRotation(angleRadius);
    
    [self.capture setTransform:transform];
    [self.capture setRotation:scanRectRotation];
    self.capture.layer.frame = self.view.frame;
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
            return 0;
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
            return 90;
    }
}

- (void)applyRectOfInterest:(UIInterfaceOrientation)orientation {
    CGRect transformedScanRect;
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        transformedScanRect = CGRectMake(_scanView.frame.origin.y,
                                         _scanView.frame.origin.x,
                                         _scanView.frame.size.height,
                                         _scanView.frame.size.width);
    } else {
        transformedScanRect = _scanView.frame;
    }
    
    CGRect metadataOutputRect = [(AVCaptureVideoPreviewLayer *) _capture.layer metadataOutputRectOfInterestForRect:transformedScanRect];
    CGRect rectOfInterest = [_capture.output rectForMetadataOutputRectOfInterest:metadataOutputRect];
    _capture.scanRect = rectOfInterest;
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
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id item, NSDictionary *unused) {
        return ![item isKindOfClass:NSNull.class];
    }];
    NSArray *resultPoints = [result.resultPoints filteredArrayUsingPredicate:predicate];
    
    for (ZXResultPoint *resultPoint in resultPoints) {
        CGPoint cgPoint = CGPointMake(resultPoint.x, resultPoint.y);
        CGPoint transformedPoint = CGPointApplyAffineTransform(cgPoint, inverse);
        transformedPoint = [self.scanRectView convertPoint:transformedPoint toView:self.scanRectView.window];
        NSValue* windowPointValue = [NSValue valueWithCGPoint:transformedPoint];
        location = [NSString stringWithFormat:@"%@ (%f, %f)", location, transformedPoint.x, transformedPoint.y];
        [points addObject:windowPointValue];
    }
    
    // Display information about the result onscreen.
    NSString *display = [NSString stringWithFormat:@"Scanned!\nContents:%@", result.text];
    [self.decodedLabel performSelectorOnMainThread:@selector(setText:) withObject:display waitUntilDone:YES];
    
    // Vibrate
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    
    [self dissmissVC: result.text];
}

- (IBAction)closeBtnPressed:(id)sender {
    [self dissmissVC: [OSBarcodeErrors getErrorMessage:kScanningCancelled]];
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
    
    //raise notification about dismiss
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"barcode reader finished"
     object:message];
}

@end


