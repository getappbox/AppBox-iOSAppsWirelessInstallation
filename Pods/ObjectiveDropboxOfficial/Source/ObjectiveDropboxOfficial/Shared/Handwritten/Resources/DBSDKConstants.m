///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

/// Constants for the SDK should go here.

#import <Foundation/Foundation.h>

#import "DBSDKConstants.h"

NSString *const kDBSDKVersion = @"4.0.0";
NSString *const kDBSDKDefaultUserAgentPrefix = @"OfficialDropboxObjCSDKv2";
NSString *const kDBSDKForegroundSessionId = @"com.dropbox.dropbox_sdk_obj_c_foreground";
NSString *const kDBSDKBackgroundSessionId = @"com.dropbox.dropbox_sdk_obj_c_background";

// BEGIN DEBUG CONSTANTS
BOOL const kDBSDKDebug = NO;           // Should never be `YES` in production
NSString *const kDBSDKDebugHost = nil; // `"dbdev"`, if using EC, or "{user_name}-dbx"`, if dev box.
                                       // Should never be non-`nil` in production.
// END DEBUG CONSTANTS

NSString *const kDBSDKCSERFKey = @"kDBSDKCSERFKeyObjCSDK";
