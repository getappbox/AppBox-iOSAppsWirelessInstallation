//
//  GitHandler.m
//  AppBox
//
//  Created by Vineet Choudhary on 30/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "GitHandler.h"

@implementation GitHandler

+(NSArray *)getGitBranchesForProjectPath:(NSString *)projectPath{
    NSString *configPath = [[projectPath stringByAppendingPathComponent:@".git"] stringByAppendingPathComponent:@"config"];
    NSURL *gitConfigURL = [NSURL URLWithString:configPath];
    NSString *contentofConfig = [NSString stringWithContentsOfURL:gitConfigURL encoding:NSASCIIStringEncoding error:nil];
    if (contentofConfig.length > 0){
        __block NSMutableArray *branchesList = [[NSMutableArray alloc] init];
        __block NSString *gitURL;
        [contentofConfig enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
            NSLog(@"%@",line);
            if ([line containsString:@"[branch \""]) {
                NSString *branch = [[line componentsSeparatedByString:@"\""] objectAtIndex:1];
                [branchesList addObject:branch];
            }else if ([line containsString:@"url = "]){
                gitURL = [[line componentsSeparatedByString:@"url = "] lastObject];
            }
        }];
    }
    return nil;
}

@end
