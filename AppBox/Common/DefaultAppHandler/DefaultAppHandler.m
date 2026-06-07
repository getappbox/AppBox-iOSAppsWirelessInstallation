//
//  DefaultAppHandler.m
//  AppBox
//
//  Created by Vineet Choudhary on 07/06/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

#import "DefaultAppHandler.h"

NSNotificationName const ABDefaultIPAHandlerDidChangeNotification = @"ABDefaultIPAHandlerDidChangeNotification";

@implementation DefaultAppHandler

+ (BOOL)isDefaultIPAHandler {
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    CFStringRef defaultHandler = LSCopyDefaultRoleHandlerForContentType(CFSTR("com.apple.itunes.ipa"), kLSRolesAll);
    if (defaultHandler == NULL) return NO;
    BOOL isDefault = [(__bridge_transfer NSString *)defaultHandler isEqualToString:bundleId];
    return isDefault;
}

+ (void)setAsDefaultIPAHandler {
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    BOOL wasPreviouslyDefault = [self isDefaultIPAHandler];
    
    OSStatus status = LSSetDefaultRoleHandlerForContentType(CFSTR("com.apple.itunes.ipa"), kLSRolesAll, (__bridge CFStringRef)bundleId);
    if (status != noErr) {
        DDLogError(@"Failed to set AppBox as default IPA handler (error %d).", (int)status);
    } else {
        DDLogInfo(@"AppBox set as default application for .ipa files.");
    }
    
    // Observe app becoming active to detect when system popup closes
    [self observeAppActivationWithPreviousState:wasPreviouslyDefault];
}

+ (void)removeAsDefaultIPAHandler {
    NSString *appBoxBundleId = [[NSBundle mainBundle] bundleIdentifier];
    BOOL wasPreviouslyDefault = [self isDefaultIPAHandler];
    
    // Find all handlers for IPA content type and pick the first one that isn't AppBox
    CFArrayRef allHandlers = LSCopyAllRoleHandlersForContentType(CFSTR("com.apple.itunes.ipa"), kLSRolesAll);
    if (allHandlers != NULL) {
        NSArray *handlers = (__bridge_transfer NSArray *)allHandlers;
        for (NSString *handler in handlers) {
            if (![handler isEqualToString:appBoxBundleId]) {
                OSStatus status = LSSetDefaultRoleHandlerForContentType(CFSTR("com.apple.itunes.ipa"), kLSRolesAll, (__bridge CFStringRef)handler);
                if (status == noErr) {
                    DDLogInfo(@"Default IPA handler change requested to: %@", handler);
                    break;
                }
            }
        }
    } else {
        // Fallback: set Archive Utility as default since IPA is a ZIP archive
        OSStatus status = LSSetDefaultRoleHandlerForContentType(CFSTR("com.apple.itunes.ipa"), kLSRolesAll, CFSTR("com.apple.archiveutility"));
        if (status == noErr) {
            DDLogInfo(@"Default IPA handler change requested to Archive Utility.");
        } else {
            DDLogError(@"Failed to remove AppBox as default IPA handler (error %d).", (int)status);
        }
    }
    
    // Observe app becoming active to detect when system popup closes
    [self observeAppActivationWithPreviousState:wasPreviouslyDefault];
}

#pragma mark - Private

+ (void)observeAppActivationWithPreviousState:(BOOL)wasPreviouslyDefault {
    // Wait 2 seconds for system popup to appear, then poll every 0.5s for state change
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Post the current real status immediately
        BOOL isNowDefault = [self isDefaultIPAHandler];
        [[NSNotificationCenter defaultCenter]
            postNotificationName:ABDefaultIPAHandlerDidChangeNotification
            object:nil
            userInfo:@{@"isDefault": @(isNowDefault)}];
        
        // Then keep polling every 0.5s until state changes or timeout (30s)
        __block NSInteger attempts = 0;
        __block BOOL lastKnownState = isNowDefault;
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES block:^(NSTimer *t) {
            attempts++;
            BOOL currentState = [self isDefaultIPAHandler];
            
            if (currentState != lastKnownState) {
                lastKnownState = currentState;
                [[NSNotificationCenter defaultCenter]
                    postNotificationName:ABDefaultIPAHandlerDidChangeNotification
                    object:nil
                    userInfo:@{@"isDefault": @(currentState)}];
            }
            
            // Stop after state changed from original or timeout
            if (currentState != wasPreviouslyDefault || attempts >= 60) {
                [t invalidate];
                DDLogInfo(@"IPA handler state resolved: was=%d, now=%d (attempts=%ld)", wasPreviouslyDefault, currentState, (long)attempts);
            }
        }];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    });
}

@end
