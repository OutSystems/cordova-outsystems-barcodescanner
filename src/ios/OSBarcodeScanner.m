#import "OSBarcodeScanner.h"
#import "CDVBarcodeOptions.h"
#import "ScannerViewController.h"

@implementation OSBarcodeScanner

CDVInvokedUrlCommand* cdvCommand;

- (void)scan:(CDVInvokedUrlCommand*)command
{
    CDVBarcodeOptions* options = [CDVBarcodeOptions parseOptions: [command argumentAtIndex:0 withDefault:@{@"":@""} andClass:[NSDictionary class]]];
    
    cdvCommand = command;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                          selector:@selector(notificationHandler:)
                                          name:@"barcode reader finished" object:nil];
    
    CameraDirection directionEnum;
    
    if([options.cameraDirection isEqualToString:@"1"]) {
        directionEnum = kBack;
    } else if([options.cameraDirection isEqualToString:@"2"]){
        directionEnum = kFront;
    } else {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR messageAsString:@"Wrong parameter camera direction can only be backCamera or frontCamera. Defaults to backCamera."];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:cdvCommand.callbackId];
        return;
    }
    
    ScanOrientation orientationEnum;
    
    if([options.scanOrientation isEqualToString:@"3"]) {
        orientationEnum = kAdaptive;
    } else if([options.scanOrientation isEqualToString:@"1"]) {
        orientationEnum = kPortrait;
    } else if([options.scanOrientation isEqualToString:@"2"]) {
        orientationEnum = kLandscape;
    } else {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR messageAsString:@"Wrong parameter scan orientation can only be adaptive, portrait or landscape. Defaults to adaptive."];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:cdvCommand.callbackId];
        return;
    }

    UIViewController* scannerViewController = [[ScannerViewController alloc] initWithScanInstructions:options.scanInstructions CameraDirection:directionEnum ScanOrientation:orientationEnum ScanLine:options.scanLine ScanButtonEnabled:options.scanButton ScanButton:options.scanButtonText];
    
    if (@available(iOS 13.0, *)) {
                [scannerViewController setModalPresentationStyle: UIModalPresentationFullScreen];
            }
    [self.viewController presentViewController:scannerViewController animated:true completion:nil];
}

-(void)notificationHandler:(NSNotification *)notice{
    NSString *str = [notice object];
    CDVPluginResult* pluginResult = nil;
    if (str != nil && [str length] > 0 && !([str isEqual: @"User closed before getting a result"])) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: str];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT messageAsString: str];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:cdvCommand.callbackId];
}

@end
