//
//  KeychainHandler+Helper.h
//  AppBox
//
//  Created by Vineet Choudhary on 11/10/18.
//  Copyright © 2018 Developer Insider. All rights reserved.
//

#import "KeychainHandler.h"

NS_ASSUME_NONNULL_BEGIN

@interface KeychainHandler (Helper)

+(OSStatus)unlockSavedKeychain;

@end

NS_ASSUME_NONNULL_END
