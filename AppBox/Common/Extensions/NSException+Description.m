//
//  NSException+Description.m
//  AppBox
//
//  Created by Vineet Choudhary on 04/12/24.
//  Copyright © 2024 Developer Insider. All rights reserved.
//

#import "NSException+Description.h"

@implementation NSException (Description)

-(NSString *)abDescription {
	return [NSString stringWithFormat:@"\n\nName: %@\nReason: %@\nUserInfo: %@", self.name, self.reason, self.userInfo];
}

@end
