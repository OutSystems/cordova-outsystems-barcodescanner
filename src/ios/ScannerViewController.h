//
//  ScannerViewController.h
//  BarcodeTestApp
//
//  Created by Carlos Correa on 26/04/2021.
//

#import <UIKit/UIKit.h>
#import <ZXingObjC/ZXingObjC.h>
#import <Cordova/CDV.h>

typedef NS_ENUM(NSUInteger, CameraDirection) {
    kFront,
    kBack
};

typedef NS_ENUM(NSUInteger, ScanOrientation) {
    kAdaptive,
    kPortrait,
    kLandscape
};

@interface ScannerViewController : UIViewController <ZXCaptureDelegate>
@property (weak, nonatomic) IBOutlet UIButton *scanButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *laserDownTrailingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *laserUpTrailingConstraint;
@property (weak, nonatomic) IBOutlet UIView *laserGradient;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *movingBarTopConstraint;
@property (weak, nonatomic) IBOutlet UIView *externalView;
@property (weak, nonatomic) IBOutlet UIView *blurFrame;
-(instancetype)initWithScanInstructions:(NSString*)instructions CameraDirection:(CameraDirection)direction ScanOrientation:(ScanOrientation)orientation ScanLine:(bool)lineEnabled ScanButtonEnabled:(bool)buttonEnabled ScanButton:(NSString*)buttonTitle ScanType:(NSString*)scanType;
- (IBAction)flashBtnPressed:(id)sender;
- (IBAction)scanBtnPressed:(id)sender;
- (IBAction)closeBtnPressed:(id)sender;

@end
