
#import "OSBarcodeErrors.h"

@implementation OSBarcodeErrors

+ (NSString *)getErrorCode:(ErrorCodes)error {
    switch (error) {
        case kCameraDirectionError:
            return @"OS-PLUG-BARC-0008";
        case kOrientationError:
            return @"OS-PLUG-BARC-0009";
        case kScanningCancelled:
            return @"OS-PLUG-BARC-0006";
        default:
            return @"Unknown";
    }
}

+ (NSString *)getErrorMessage:(ErrorCodes)error {
    switch (error) {
        case kCameraDirectionError:
            return @"Wrong parameter. Camera direction can only be backCamera or frontCamera. Defaults to backCamera.";
        case kOrientationError:
            return @"Wrong parameter. Scan orientation can only be adaptive, portrait or landscape. Defaults to adaptive.";
        case kScanningCancelled:
            return @"Scanning cancelled.";
        default:
            return @"Unknown";
    }
}

+ (NSDictionary *)getErrorDictionary:(ErrorCodes)error {
    NSString* errorCode = [OSBarcodeErrors getErrorCode:error];
    NSString* errorMessage = [OSBarcodeErrors getErrorMessage:error];
    return @{@"code" :errorCode, @"message" :errorMessage};
}


@end
