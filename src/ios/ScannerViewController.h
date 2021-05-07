//
//  ScannerViewController.h
//  BarcodeTestApp
//
//  Created by Carlos Correa on 26/04/2021.
//

#import <UIKit/UIKit.h>
#import <ZXingObjC/ZXingObjC.h>
#import <Cordova/CDV.h>

@interface ScannerViewController : UIViewController <ZXCaptureDelegate>
@property (weak, nonatomic) IBOutlet UIButton *scanButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *laserDownTrailingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *laserUpTrailingConstraint;
@property (weak, nonatomic) IBOutlet UIView *laserGradientUp;
@property (weak, nonatomic) IBOutlet UIView *laserGradientDown;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *movingBarTopConstraint;
@property (weak, nonatomic) IBOutlet UIView *externalView;
@property (weak, nonatomic) IBOutlet UIView *blurFrame;
- (IBAction)flashBtnPressed:(id)sender;
- (IBAction)scanBtnPressed:(id)sender;
- (IBAction)closeBtnPressed:(id)sender;

@end
