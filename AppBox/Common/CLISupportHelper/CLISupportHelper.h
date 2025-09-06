//
//  CLISupportInstaller.h
//  AppBox
//
//  Created by Vineet Choudhary on 30/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface CLISupportHelper : NSObject

+ (BOOL)install;
+ (BOOL)uninstall;
+ (BOOL)installPromptAfterLogin;

@end

NS_ASSUME_NONNULL_END
