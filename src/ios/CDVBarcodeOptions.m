/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

#import "CDVBarcodeOptions.h"

#import <objc/runtime.h>

@implementation CDVBarcodeOptions

- (id)init
{
    if (self = [super init]) {
        // default values
        self.scanLine = YES;
        self.scanButton = YES;
        self.cameraDirection = @"backCamera";
        self.scanOrientation = @"portrait";
        self.scanInstructions = @"";
        self.scanButtonText = @"Scan";
    }

    return self;
}

+ (CDVBarcodeOptions*)parseOptions:(NSDictionary*)options
{
    CDVBarcodeOptions* obj = [[CDVBarcodeOptions alloc] init];

    if([options objectForKey: @"scan_line"] != nil) {
        obj.scanLine = (BOOL)[options objectForKey: @"scan_line"];
    }
    if([options objectForKey: @"scan_button"] != nil) {
        obj.scanButton = (BOOL)[options objectForKey: @"scan_button"];
    }
    if([options objectForKey: @"scan_orientation"] != nil) {
        obj.scanOrientation = (NSString*)[options objectForKey: @"scan_orientation"];
    }
    if([options objectForKey: @"scan_instructions"] != nil) {
        obj.scanInstructions = (NSString*)[options objectForKey: @"scan_instructions"];
    }
    if([options objectForKey: @"scan_button_text"] != nil) {
        obj.scanButtonText = (NSString*)[options objectForKey: @"scan_button_text"];
    }
    if([options objectForKey: @"camera_direction"] != nil) {
        obj.cameraDirection = (NSString*)[options objectForKey: @"camera_direction"];
    }

    return obj;
}

@end
