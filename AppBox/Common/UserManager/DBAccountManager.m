//
//  DBAccountManager.m
//  AppBox
//
//  Created by Vineet Choudhary on 25/09/21.
//  Copyright © 2021 Developer Insider. All rights reserved.
//

#import "DBAccountManager.h"

static NSString *const abDBAccountService = @"AppBox Linked Dropbox Account";

@implementation DBAccountManager

+ (NSArray *)getAllDBAccounts {
	NSMutableArray *filteredDBAccounts = [[NSMutableArray alloc] init];
	NSArray *dbAccounts = [SAMKeychain accountsForService:abDBAccountService];
	for (NSDictionary *dbAccount in dbAccounts) {
		if ([dbAccount.allKeys containsObject:kSAMKeychainAccountKey]) {
			[filteredDBAccounts addObject:dbAccount];
		}
	}
	
	return  filteredDBAccounts;
}

@end
