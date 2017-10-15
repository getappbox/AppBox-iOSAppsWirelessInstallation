//
//  LocalServerHandler.h
//  AppBox
//
//  Created by Vineet Choudhary on 12/08/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LocalServerHandler : NSObject

+(void)startLocalServerWithCompletion:(void (^)(BOOL isOn))completion;
+(void)getLocalIPAddressWithCompletion:(void (^)(NSString *ipAddress))completion;

@end
