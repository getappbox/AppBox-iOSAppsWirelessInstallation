//
//  SlackClient.h
//  AppBox
//
//  Created by Vineet Choudhary on 10/04/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SlackClient : NSObject

+ (void)sendMessageForProject:(XCProject *)project completion:(void (^) (BOOL success))completion;

@end
