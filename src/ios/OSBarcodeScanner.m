#import "OSBarcodeScanner.h"
#import "ScannerViewController.h"

@implementation OSBarcodeScanner

- (void)scan:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    NSString* echo = [command.arguments objectAtIndex:0];

    UIViewController* scannerViewController = [[ScannerViewController alloc] initWithNibName:@"ScannerViewController" bundle:nil];
    
    [self.viewController setModalPresentationStyle:UIModalPresentationFullScreen];
    [self.viewController presentViewController:scannerViewController animated:true completion:nil];
    
    if (echo != nil && [echo length] > 0) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:echo];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


@end
