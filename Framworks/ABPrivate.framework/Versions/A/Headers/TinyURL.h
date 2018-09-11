//
//  TinyURL.h
//  AppBox
//
//  Created by Vineet Choudhary on 02/04/18.
//  Copyright © 2018 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ABPProject.h"

typedef void(^TinyURLShortenerCompletionBlock)(NSURL *shortURL, NSError *error);

@interface TinyURL : NSObject

+(TinyURL *)shared;
-(instancetype)init NS_UNAVAILABLE;
+(instancetype)new NS_UNAVAILABLE;

-(void)shortenURLForProject:(ABPProject *)project completion:(TinyURLShortenerCompletionBlock)completionBlock;

@end
