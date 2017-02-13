//
//  GitRepoDetails.h
//  AppBox
//
//  Created by Vineet Choudhary on 08/02/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GitRepoDetails : NSObject

@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *origin;
@property (nonatomic, strong) NSMutableArray *branchs;

@end
