//
//  UpdateHandler.m
//  AppBox
//
//  Created by Vineet Choudhary on 30/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "UpdateHandler.h"

@implementation UpdateHandler

//MARK: - Homebrew Detection

+ (BOOL)isInstalledViaHomebrew {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // Check Apple Silicon Homebrew path
    if ([fileManager fileExistsAtPath:@"/opt/homebrew/Caskroom/appbox"]) {
        return YES;
    }
    // Check Intel Homebrew path
    if ([fileManager fileExistsAtPath:@"/usr/local/Caskroom/appbox"]) {
        return YES;
    }
    return NO;
}

//MARK: - Check for update

+ (void)showHomebrewUpdateAlert {
    NSString *command = @"brew upgrade --cask appbox";
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"New Version Available"];
    [alert setInformativeText:@"A newer version of \"AppBox\" is available.\n\nSince you installed AppBox via Homebrew, please run this command in Terminal:"];
    [alert setAlertStyle:NSAlertStyleInformational];
    [alert setAccessoryView:[self commandTextFieldWithString:command width:250]];
    [alert addButtonWithTitle:@"Copy & Close"];
    [alert addButtonWithTitle:@"Release Notes"];
    [alert addButtonWithTitle:@"Close"];
    NSModalResponse response = [alert runModal];
    if (response == NSAlertFirstButtonReturn) {
        [[NSPasteboard generalPasteboard] clearContents];
        [[NSPasteboard generalPasteboard] setString:command forType:NSPasteboardTypeString];
    } else if (response == NSAlertSecondButtonReturn) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:abGitHubLatestReleaseURL]];
    }
}

+ (void)showUpdateAlertWithUpdateURL:(NSURL *)url{
    NSString *command = @"curl -s https://getappbox.com/install.sh | bash";
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"New Version Available"];
    [alert setInformativeText:@"A newer version of \"AppBox\" is available.\n\nTo update, run this command in Terminal:"];
    [alert setAlertStyle:NSAlertStyleInformational];
	[alert setAccessoryView:[self commandTextFieldWithString:command width:400]];
    [alert addButtonWithTitle:@"Copy & Close"];
    [alert addButtonWithTitle:@"Release Notes"];
    [alert addButtonWithTitle:@"Close"];
    NSModalResponse response = [alert runModal];
    if (response == NSAlertFirstButtonReturn){
        [[NSPasteboard generalPasteboard] clearContents];
        [[NSPasteboard generalPasteboard] setString:command forType:NSPasteboardTypeString];
    } else if (response == NSAlertSecondButtonReturn) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:abGitHubLatestReleaseURL]];
    }
}

+ (NSView *)commandTextFieldWithString:(NSString *)command width:(CGFloat)width {
    NSTextField *textField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, width, 20)];
    [textField setStringValue:[NSString stringWithFormat:@"%@", command]];
    [textField setEditable:NO];
    [textField setSelectable:YES];
    [textField setBordered:YES];
    [textField setBezelStyle:NSTextFieldRoundedBezel];
    [textField setFont:[NSFont monospacedSystemFontOfSize:12.0 weight:NSFontWeightMedium]];
    [textField setBackgroundColor:[NSColor controlBackgroundColor]];
    [textField setAlignment:NSTextAlignmentCenter];
    return textField;
}

+ (void)showAlreadyUptoDateAlert{
    NSString *versionString = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
    [Common showAlertWithTitle:@"You’re up-to-date!" andMessage:[NSString stringWithFormat:@"AppBox %@ is currently the newest version available.", versionString]];
}

+ (void)isNewVersionAvailableCompletion:(void (^)(bool available, NSURL *url))completion{
    @try {
        DDLogDebug(@"Checking for new version...");
        
        if ([self isInstalledViaHomebrew]) {
            // Check Homebrew API for latest available version
            [NetworkHandler requestWithURL:abHomebrewCaskAPI withParameters:nil andRequestType:RequestGET andCompletetion:^(id responseObj, NSInteger httpStatus, NSError *error) {
                @try {
                    if (error == nil && [responseObj isKindOfClass:[NSDictionary class]] &&
                        [((NSDictionary *)responseObj).allKeys containsObject:@"version"]) {
                        
                        NSString *latestVersion = [responseObj valueForKey:@"version"];
                        NSString *versionString = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
                        if (!versionString || !latestVersion) {
                            completion(false, nil);
                            return;
                        }
                        
                        DDLogDebug(@"Current Version - %@ <=> Homebrew Latest Version - %@", versionString, latestVersion);
                        
                        NSString *cleanLatest = [self extractVersionString:latestVersion];
						NSString *cleanCurrent = [self extractVersionString:versionString];
                        NSComparisonResult result = [cleanLatest compare:cleanCurrent options:NSNumericSearch];
                        
                        completion((result == NSOrderedDescending), nil);
                    } else {
                        // Homebrew API failed — fallback to GitHub release check
                        DDLogInfo(@"Homebrew API failed, falling back to GitHub release check.");
                        [self checkGitHubReleaseWithCompletion:completion];
                    }
                }
                @catch (NSException *exception) {
                    DDLogError(@"Exception %@",exception.abDescription);
                    [self checkGitHubReleaseWithCompletion:completion];
                }
            }];
        } else {
            [self checkGitHubReleaseWithCompletion:completion];
        }
    } @catch (NSException *exception) {
        completion(false, nil);
		DDLogInfo(@"Exception %@",exception.abDescription);
    }
}

+ (void)checkGitHubReleaseWithCompletion:(void (^)(bool available, NSURL *url))completion {
    [NetworkHandler requestWithURL:abGitHubLatestRelease withParameters:nil andRequestType:RequestGET andCompletetion:^(id responseObj, NSInteger httpStatus, NSError *error) {
        @try {
            if (error == nil && [responseObj isKindOfClass:[NSDictionary class]] &&
                [((NSDictionary *)responseObj).allKeys containsObject:@"tag_name"] &&
                [((NSDictionary *)responseObj).allKeys containsObject:@"html_url"]){
                
                NSString *tag = [responseObj valueForKey:@"tag_name"];
                NSString *versionString = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
                if (!versionString || !tag) {
                    completion(false, nil);
                    return;
                }
                
                DDLogDebug(@"Current Version - %@ <=> GitHub Latest Version - %@", versionString, tag);
                
                NSString *latestVersion = [self extractVersionString:tag];
                NSString *currentVersion = [self extractVersionString:versionString];
                NSComparisonResult result = [latestVersion compare:currentVersion options:NSNumericSearch];
                
                completion((result == NSOrderedDescending), [NSURL URLWithString:[responseObj valueForKey:@"html_url"]]);
            } else {
                completion(false, nil);
            }
        }
        @catch (NSException *exception) {
            DDLogError(@"Exception %@",exception.abDescription);
            completion(false, nil);
        }
    }];
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
