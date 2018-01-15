//
//  XCArchiveResult.h
//  AppBox
//
//  Created by Vineet Choudhary on 25/07/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    XCArchiveResultCleanSucceeded,
    XCArchiveResultArchiveFailed,
    XCArchiveResultArchiveSucceeded,
    XCArchiveResultExportFailed,
    XCArchiveResultExportSucceeded,
    XCArchiveResultTypeCheckPrint
} XCArchiveResultType;

@interface XCArchiveResult : NSObject

@property(nonatomic, assign) XCArchiveResultType type;
@property(nonatomic, strong) NSMutableString *message;
@property(nonatomic, strong) NSString *completeMessage;

@end
