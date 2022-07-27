#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ErrorCodes) {
    kCameraDirectionError,
    kOrientationError,
    kScanningCancelled,
};

@interface OSBarcodeErrors : NSObject

+ (NSString *)getErrorCode:(ErrorCodes)error;
+ (NSString *)getErrorMessage:(ErrorCodes)error;
+ (NSDictionary *)getErrorDictionary:(ErrorCodes)error;

@end
