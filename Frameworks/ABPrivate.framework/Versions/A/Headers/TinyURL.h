//
//  TinyURL.h
//  AppBox
//
//  Created by Vineet Choudhary on 02/04/18.
//  Copyright © 2018 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ABPIPAUploadInfo.h"

typedef void(^TinyURLShortenerCompletionBlock)(NSURL *shortURL, NSError *error);

@interface TinyURL : NSObject

+(TinyURL *)shared;
-(instancetype)init NS_UNAVAILABLE;
+(instancetype)new NS_UNAVAILABLE;

-(void)shortenURLWithIPAUploadInfo:(ABPIPAUploadInfo *)ipaUploadInfo completion:(TinyURLShortenerCompletionBlock)completionBlock;

@end
