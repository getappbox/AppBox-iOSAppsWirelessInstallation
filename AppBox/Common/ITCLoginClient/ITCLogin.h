//
//  ITCLogin.h
//  AppBox
//
//  Created by Vineet Choudhary on 23/03/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ITCLogin : NSObject

+(void)loginWithUserName:(NSString *)username andPassword:(NSString *)password completion:(void (^) (bool success, NSString *message))completion;

@end
