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
    else{
        xcArchiveResult.type = XCArchiveResultTypeCheckPrint;
        if ([unformatedMessage containsString:@"check dependencies"]){
            [xcArchiveResult.message appendString:@"Check Dependencies"];
        }
        else if ([unformatedMessage containsString:@"clean.remove"]) {
            [self appendLastPathComponentIn:@"Clean" from:xcArchiveResult];
        }
        else if ([unformatedMessage containsString:@"compilec"]) {
            [self appendLastPathComponentIn:@"CompileC" from:xcArchiveResult];
        }
        else if ([unformatedMessage containsString:@"compilestoryboard"]) {
            [self appendLastPathComponentIn:@"Compile Storyboard" from:xcArchiveResult];
        }
        else if ([unformatedMessage containsString:@"compileassetcatalog"]) {
            [self appendLastPathComponentIn:@"Compile Asset Catalog" from:xcArchiveResult];
        }
        else if ([unformatedMessage containsString:@"compilestoryboard"]) {
            [self appendLastPathComponentIn:@"Compile Storyboard" from:xcArchiveResult];
        }
        else if ([unformatedMessage containsString:@"processinfoplistfile"]) {
            [self appendLastPathComponentIn:@"Process info.plist File" from:xcArchiveResult];
        }
        else if ([unformatedMessage containsString:@"generatedsymfile"]) {
            [self appendLastPathComponentIn:@"Generate DSYM File" from:xcArchiveResult];
        }
        else if ([unformatedMessage containsString:@"linkstoryboards"]) {
            [xcArchiveResult.message appendString:@"Linking Storyboards"];
        }
        else if ([unformatedMessage containsString:@"processproductpackaging"]) {
            [xcArchiveResult.message appendString:@"Process Product Packaging"];
        }
        else if ([unformatedMessage containsString:@"touch"]) {
            [self appendLastPathComponentIn:@"Touch" from:xcArchiveResult];
        }
        else if ([unformatedMessage containsString:@"codesign"]) {
            [unformatedMessage enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
                if ([line containsString:@"signing identity"] || [line containsString:@"provisioning profile"]){
                    [xcArchiveResult.message appendString:line];
                }
            }];
        }
        else if ([unformatedMessage containsString:@"validate"]) {
            [xcArchiveResult.message appendString:@"Validating"];
        }
        else if ([unformatedMessage containsString:@"building project..."]) {
            [xcArchiveResult.message appendString:xcArchiveResult.completeMessage];
        }
    }
    return xcArchiveResult;
}

+(void)appendLastPathComponentIn:(NSString *)string from:(XCArchiveResult *)result{
    NSString *firstLine = [[result.completeMessage componentsSeparatedByString:@"\n"] firstObject];
    if (firstLine){
        NSString *lastObject = [[firstLine componentsSeparatedByString:@"/"] lastObject];
        if (lastObject){
            [result.message appendFormat:@"%@ : %@",string, lastObject.capitalizedString];
        }
    }
}


@end
