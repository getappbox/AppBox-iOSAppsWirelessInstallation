//
//  GitHandler.m
//  AppBox
//
//  Created by Vineet Choudhary on 30/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "GitHandler.h"

@implementation GitHandler

+(GitRepoDetails *)getGitBranchesForProjectURL:(NSURL *)projectURL{
    projectURL = [projectURL URLByDeletingLastPathComponent];
    if (projectURL.pathComponents.count == 1){
        return nil;
    }
    NSURL *gitConfigURL = [[projectURL URLByAppendingPathComponent:@".git"] URLByAppendingPathComponent:@"config"];
    NSString *contentofConfig = [NSString stringWithContentsOfURL:gitConfigURL encoding:NSASCIIStringEncoding error:nil];
    if (contentofConfig.length > 0){
        GitRepoDetails *gitRepoDetails = [[GitRepoDetails alloc] init];
        [gitRepoDetails setPath:[projectURL resourceSpecifier]];
        [contentofConfig enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
            NSLog(@"%@",line);
            if ([line containsString:@"[branch \""]) {
                NSString *branch = [[line componentsSeparatedByString:@"\""] objectAtIndex:1];
                [gitRepoDetails.branchs addObject:branch];
            }else if ([line containsString:@"url = "]){
                [gitRepoDetails setOrigin: [[line componentsSeparatedByString:@"url = "] lastObject]];
            }
        }];
        return gitRepoDetails;
    }else{
        return [GitHandler getGitBranchesForProjectURL:projectURL];
    }
    return nil;
}

@end
