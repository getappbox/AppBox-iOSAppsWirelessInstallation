//
//  DefaultSettings.m
//  AppBox
//
//  Created by Vineet Choudhary on 08/10/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "DefaultSettings.h"

@implementation DefaultSettings

+(void)setFirstTimeSettings{
    if ([UserData isFirstTime]) {
        [UserData setIsFirstTime:YES];
        [UserData setUploadBitcode:YES];
        [UserData setUploadSymbols:YES];
        [UserData setCompileBitcode:YES];
    }
}

+(void)setEveryStartupSettings{
    
}

@end
