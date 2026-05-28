//
//  UpdateHandler.m
//  AppBox
//
//  Created by Vineet Choudhary on 30/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "UpdateHandler.h"

@implementation UpdateHandler

//MARK: - Check for update

+ (void)showUpdateAlertWithUpdateURL:(NSURL *)url{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText: @"New Version Available"];
    [alert setInformativeText:@"A newer version of the \"AppBox\" is available. Do you want to update it? \n\n\n"];
	[alert setAlertStyle:NSAlertStyleInformational];
    [alert addButtonWithTitle:@"YES"];
    [alert addButtonWithTitle:@"NO"];
    if ([alert runModal] == NSAlertFirstButtonReturn){
        [[NSWorkspace sharedWorkspace] openURL:url];
    }
}

+ (void)showAlreadyUptoDateAlert{
    NSString *versionString = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
    [Common showAlertWithTitle:@"You’re up-to-date!" andMessage:[NSString stringWithFormat:@"AppBox %@ is currently the newest version available.", versionString]];
}

+ (void)isNewVersionAvailableCompletion:(void (^)(bool available, NSURL *url))completion{
    @try {
        DDLogDebug(@"Checking for new version...");
        [NetworkHandler requestWithURL:abGitHubLatestRelease withParameters:nil andRequestType:RequestGET andCompletetion:^(id responseObj, NSInteger httpStatus, NSError *error) {
            //handle error and check for all required keys
			@try {
				if (error == nil && [responseObj isKindOfClass:[NSDictionary class]] &&
					[((NSDictionary *)responseObj).allKeys containsObject:@"tag_name"] &&
					[((NSDictionary *)responseObj).allKeys containsObject:@"html_url"]){
					
					//get tag name, because it's always be latest version
					NSString *tag = [responseObj valueForKey:@"tag_name"];
					
					//get version string from bundle info.plist
					NSString *versionString = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
					if (!versionString || !tag) {
						completion(false, nil);
						return;
					}
					
					//log current and latest version
					DDLogDebug(@"Current Version - %@ <=> Latest Version - %@", versionString, tag);
					
					// Use proper numeric version comparison
					NSString *latestVersion = [self extractVersionString:tag];
					NSString *currentVersion = [self extractVersionString:versionString];
					NSComparisonResult result = [latestVersion compare:currentVersion options:NSNumericSearch];
					
					//return result based on version strings
					completion((result == NSOrderedDescending), [NSURL URLWithString:[responseObj valueForKey:@"html_url"]]);
				}else{
					completion(false, nil);
				}
			}
			@catch (NSException *exception) {
				DDLogError(@"Exception %@",exception.abDescription);
			}
        }];
    } @catch (NSException *exception) {
        completion(false, nil);
		DDLogInfo(@"Exception %@",exception.abDescription);
    }
}

+ (NSString *)extractVersionString:(NSString *)input {
    if (!input) return @"0";
    // Remove everything except digits and dots
    NSMutableString *version = [NSMutableString string];
    BOOL foundDigit = NO;
    for (NSUInteger i = 0; i < input.length; i++) {
        unichar c = [input characterAtIndex:i];
        if (c >= '0' && c <= '9') {
            [version appendFormat:@"%C", c];
            foundDigit = YES;
        } else if (c == '.' && foundDigit) {
            [version appendFormat:@"%C", c];
        }
    }
    // Remove trailing dot if any
    if (version.length > 0 && [version characterAtIndex:version.length - 1] == '.') {
        [version deleteCharactersInRange:NSMakeRange(version.length - 1, 1)];
    }
    return version.length > 0 ? [version copy] : @"0";
}


@end
