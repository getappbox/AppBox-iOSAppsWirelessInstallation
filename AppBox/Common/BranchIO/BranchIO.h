//
//  BranchIO.h
//  AppBox
//
//  Created by Vineet Choudhary on 02/04/18.
//  Copyright © 2018 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XCProject;
typedef void(^TinyURLShortenerCompletionBlock)(NSURL *shortURL, NSError *error);

@interface BranchIO : NSObject

+(BranchIO *)shared;
-(instancetype)init NS_UNAVAILABLE;
+(instancetype)new NS_UNAVAILABLE;

-(void)shortenURLForProject:(XCProject *)project completion:(TinyURLShortenerCompletionBlock)completionBlock;

@end
