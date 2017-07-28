//
//  XCArchiveParser.m
//  AppBox
//
//  Created by Vineet Choudhary on 25/07/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "XCArchiveParser.h"

@implementation XCArchiveParser

+(XCArchiveResult *)archiveResultMessageFromString:(NSString *)unformatedMessage{
    XCArchiveResult *xcArchiveResult = [[XCArchiveResult alloc] init];
    xcArchiveResult.completeMessage = unformatedMessage.copy;
    unformatedMessage = unformatedMessage.lowercaseString;
    
    if ([unformatedMessage containsString:@"archive succeeded"]){
        xcArchiveResult.type = XCArchiveResultExportSucceeded;
        [xcArchiveResult.message appendString:@"Creating IPA..."];
    }
    else if ([unformatedMessage containsString:@"archive failed"]){
        xcArchiveResult.type = XCArchiveResultArchiveFailed;
        [xcArchiveResult.message appendString:@"Archive Failed"];
    }
    else if ([unformatedMessage containsString:@"clean succeeded"]){
        xcArchiveResult.type = XCArchiveResultCleanSucceeded;
        [xcArchiveResult.message appendString:@"Archiving..."];
    }
    else if ([unformatedMessage containsString:@"export succeeded"]){
        xcArchiveResult.type = XCArchiveResultExportSucceeded;
        [xcArchiveResult.message appendString:@"Export Succeeded"];
    }
    else if ([unformatedMessage containsString:@"export failed"]){
        xcArchiveResult.type = XCArchiveResultExportFailed;
        [xcArchiveResult.message appendString:@"Export Failed"];
    }
    else if ([unformatedMessage containsString:@"check dependencies"]){
        xcArchiveResult.type = XCArchiveResultTypeCheckDependencies;
        [xcArchiveResult.message appendString:@"Check Dependencies"];
    }
    
    return xcArchiveResult;
}


@end
