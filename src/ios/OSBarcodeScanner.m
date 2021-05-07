#import "OSBarcodeScanner.h"
#import "ScannerViewController.h"

@implementation OSBarcodeScanner

CDVInvokedUrlCommand* cdvCommand;

- (void)scan:(CDVInvokedUrlCommand*)command
{
    cdvCommand = command;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                          selector:@selector(notificationHandler:)
                                          name:@"barcode reader finished" object:nil];

    UIViewController* scannerViewController = [[ScannerViewController alloc] initWithNibName:@"ScannerViewController" bundle:nil];
    
    if (@available(iOS 13.0, *)) {
                [scannerViewController setModalPresentationStyle: UIModalPresentationFullScreen];
            }
    [self.viewController presentViewController:scannerViewController animated:true completion:nil];
}

-(void)notificationHandler:(NSNotification *)notice{
    NSString *str = [notice object];
    CDVPluginResult* pluginResult = nil;
    if (str != nil && [str length] > 0 && !([str isEqual: @"error"])) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:str];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:cdvCommand.callbackId];
}


@end
