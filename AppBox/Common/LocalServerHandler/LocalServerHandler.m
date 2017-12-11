//
//  LocalServerHandler.m
//  AppBox
//
//  Created by Vineet Choudhary on 12/08/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "LocalServerHandler.h"

@implementation LocalServerHandler

+(void)getLocalIPAddressWithCompletion:(void (^)(NSString *ipAddress))completion{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *ipAddresses = [[NSHost currentHost] addresses];
        for (NSString *ipAddress in ipAddresses) {
            if ([ipAddress componentsSeparatedByString:@"."].count == 4) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(ipAddress);
                });
                return;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(@"Not Connected.");
            return;
        });
    });
}

+(void)setupAppBoxInstallationServices:(void (^)(BOOL isSuccess))completion{
    NSString *appBoxWebServicePath = [[NSBundle mainBundle] pathForResource:@"appbox" ofType:@"zip"];
    [SSZipArchive unzipFileAtPath:appBoxWebServicePath toDestination:NSTemporaryDirectory() overwrite:YES password:nil progressHandler:^(NSString * _Nonnull entry, unz_file_info zipInfo, long entryNumber, long total) {
        [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"%@-%@-%@",[NSNumber numberWithLong:entryNumber], [NSNumber numberWithLong:total], entry]];
    } completionHandler:^(NSString * _Nonnull path, BOOL succeeded, NSError * _Nullable error) {
        completion(succeeded);
    }];
}


@end
