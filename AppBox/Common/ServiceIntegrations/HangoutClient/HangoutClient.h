//
//  HangoutClient.h
//  AppBox
//
//  Created by Vineet Choudhary on 19/03/18.
//  Copyright © 2018 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HangoutClient : NSObject

+ (void)sendMessageForProject:(XCProject *)project completion:(void (^) (BOOL success))completion;

@end
