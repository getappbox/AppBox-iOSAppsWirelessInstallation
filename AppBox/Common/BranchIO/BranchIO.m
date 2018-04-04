//
//  BranchIO.m
//  AppBox
//
//  Created by Vineet Choudhary on 02/04/18.
//  Copyright © 2018 Developer Insider. All rights reserved.
//

#import "BranchIO.h"

@implementation BranchIO{
    NSInteger retryCount;
}

+(BranchIO *)shared{
    static BranchIO *branch = nil;
    if (branch == nil) {
        branch = [[self alloc] init];
    }
    return branch;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

-(void)shortenURLForProject:(XCProject *)project completion:(TinyURLShortenerCompletionBlock)completionBlock{
    NSDictionary *parameters = @{
                                 @"branch_key": abBranchIOProductionKey,
                                 @"channel": @"Email",
                                 @"feature": @"AppBox-macOS",
                                 @"campaign": @"AppBox-macOS",
                                 @"data": @{
                                         @"$og_title": project.name,
                                         @"$og_description": [NSString stringWithFormat:@"Open this link to install %@ iOS application.", project.name],
                                         @"$og_image_url": abSlackImage,
                                         @"$fallback_url": project.appLongShareableURL.absoluteString,
                                         @"$desktop_url": project.appLongShareableURL.absoluteString,
                                         @"$ios_url": project.appLongShareableURL.absoluteString,
                                         @"$android_url": project.appLongShareableURL.absoluteString,
                                         @"$web_only": @true,
                                         @"bundle_identifier": project.identifer,
                                         @"version_number": project.version,
                                         @"build_number": project.build,
                                         }
                                 };
    
    [NetworkHandler requestWithURL:abBranchBaseURL withParameters:parameters andRequestType:RequestPOST andCompletetion:^(id responseObj, NSInteger httpStatus, NSError *error) {
        if (error) {
            if (httpStatus == HTTP_CONFLICT){
                completionBlock(nil, [Common errorWithDesc:@"URL not available." andCode:httpStatus]);
                return;
            }
            if (retryCount == 3) {
                completionBlock(nil, error);
                return;
            }
            retryCount++;
            [self shortenURLForProject:project completion:completionBlock];
        } else {
            NSError *invalidURL = [Common errorWithDesc:@"Something went wrong." andCode:httpStatus];
            if ([responseObj isKindOfClass:[NSDictionary class]] && [[responseObj allKeys] containsObject:@"url"]){
                NSURL *shortURL = [NSURL URLWithString:[responseObj valueForKey:@"url"]];
                if (shortURL) {
                    NSURL *shortURLHTTP = [NSURL URLWithString:[shortURL.absoluteString stringByReplacingOccurrencesOfString:@"https://" withString:@"http://"]];
                    completionBlock(shortURLHTTP, nil);
                } else {
                    completionBlock(nil, invalidURL);
                }
            } else {
                completionBlock(nil, invalidURL);
            }
        }
    }];
}

@end
