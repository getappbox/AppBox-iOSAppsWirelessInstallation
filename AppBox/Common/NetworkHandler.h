//
//  NetworkHandler.h
//  AppBox
//
//  Created by Vineet Choudhary on 16/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetworkHandler : NSObject

typedef enum : NSUInteger {
    RequestGET,
    RequestPOST,
} RequestType;

+(void)requestWithURL:(NSString *)url withParameters:(id)parmeters andRequestType:(RequestType)requestType andCompletetion:(void (^)(id responseObj, NSError *error))completion;

@end
