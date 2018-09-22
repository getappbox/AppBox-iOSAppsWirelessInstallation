//
//  DBManager.h
//  ABPrivate
//
//  Created by Vineet Choudhary on 25/04/18.
//  Copyright © 2018 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DBManager : NSObject

@property(nonatomic, strong) NSString *bundleId;
@property(nonatomic, strong) NSString *appName;
@property(nonatomic, strong) NSString *version;
@property(nonatomic, strong) NSString *userId;

+(NSString *)gaKey;
-(NSString *)getDBKey;
-(void)registerUserId:(NSString *)userId;
@end
