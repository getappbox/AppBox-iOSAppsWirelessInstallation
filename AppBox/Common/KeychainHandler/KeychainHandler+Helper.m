//
//  KeychainHandler+Helper.m
//  AppBox
//
//  Created by Vineet Choudhary on 11/10/18.
//  Copyright © 2018 Developer Insider. All rights reserved.
//

#import "KeychainHandler+Helper.h"

@implementation KeychainHandler (Helper)

+(OSStatus)unlockSavedKeychain {
    NSString *keychainPassword = [SAMKeychain passwordForService:abmacOSKeyChainService account:abmacOSKeyChainAccount];
    NSString *keychainPath = [UserData keychainPath] ? [UserData keychainPath] : @"";
    keychainPassword = keychainPassword ? keychainPassword : @"";
    OSStatus status = [[self class] unlockKeyChain:keychainPath withPassword:keychainPassword];
    NSString *error = [[self class] errorMessageForStatus:status];
    
    [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Keychain Unlock Status - %@", error]];
    
    return status;
}

@end
