//
//  MSTeamsClient.h
//  AppBox
//
//  Created by Vineet Choudhary on 19/03/18.
//  Copyright © 2018 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MSTeamsClient : NSObject

+ (void)sendMessageForProject:(XCProject *)project
					  webhook:(NSString *)webhook
					  message:(NSString *)message
				   completion:(void (^) (BOOL success))completion;

@end
