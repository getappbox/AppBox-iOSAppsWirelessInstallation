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

+(NSString *)checkALPath:(NSString *)xcodePath;
+(NSString *)checkXCodePath:(NSString *)xcodePath;
+(void)getXCodePathWithCompletion:(void (^) (NSString *xcodePath, NSString *applicationLoaderPath))completion;
+(void)changeDefaultXcodePath:(NSString *)path withCompletion:(void (^) (BOOL success, NSString *error))completion;
+(void)getXcodeVersion:(NSString *)path WithCompletion:(void (^) (BOOL success, XcodeVersion version, NSString *versionString))completion ;

@end
