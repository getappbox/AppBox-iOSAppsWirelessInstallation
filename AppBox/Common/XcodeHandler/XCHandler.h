//
//  XCHandler.h
//  AppBox
//
//  Created by Vineet Choudhary on 27/03/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    XcodeVersionNone = 0,
    XcodeVersion8 = 8,
    XcodeVersion9 = 9
} XcodeVersion;

@interface XCHandler : NSObject

+(void)getXCodePathWithCompletion:(void (^) (NSString *xcodePath, NSString *applicationLoaderPath))completion;
+(void)changeDefaultXcodePath:(NSString *)path withCompletion:(void (^) (BOOL success, NSString *error))completion;
+(void)getXcodeVersionWithCompletion:(void (^) (BOOL success, XcodeVersion version, NSString *versionString))completion;

@end
