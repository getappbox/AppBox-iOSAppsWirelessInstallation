//
//  JenkinsHandler.m
//  AppBox
//
//  Created by Vineet Choudhary on 09/05/18.
//  Copyright © 2018 Developer Insider. All rights reserved.
//

#import "JenkinsHandler.h"

const NSString *jenkinsWorkspaceDir = @"workspace";
const NSString *jenkinsJobsDir = @"jobs";
const NSString *artifactsRootDir = @"/builds";
const NSString *lastSuccessfulBuildShortcut = @"/lastSuccessfulBuild";
const NSString *artifactsDir = @"/builds";

@implementation JenkinsHandler

+(void)test{
    XCProject *project = [[XCProject alloc] init];
    [project setProjectFullPath:[NSURL URLWithString:@"/Users/emp195/.jenkins/workspace/ourValues-iOS/Vbreathe.xcworkspace"]];
    [[self class] copyArtifactsInBuildFolderForProject:project];
}

+(BOOL)copyArtifactsInBuildFolderForProject:(XCProject *)project {
    NSMutableArray *projectPathComponents = [[NSMutableArray alloc] initWithArray:[project.projectFullPath pathComponents]];
    [projectPathComponents removeLastObject];
    if ([projectPathComponents containsObject:jenkinsWorkspaceDir]) {
        [projectPathComponents replaceObjectAtIndex:[projectPathComponents indexOfObject:jenkinsWorkspaceDir] withObject:jenkinsJobsDir];
        [projectPathComponents addObjectsFromArray:@[artifactsRootDir, lastSuccessfulBuildShortcut]];
        NSURL *aliasPath = [NSURL fileURLWithPathComponents:projectPathComponents];
        NSError *error;
        NSData *bookmarkData = [NSURL bookmarkDataWithContentsOfURL:aliasPath error:&error];
        NSDictionary<NSURLResourceKey, id> *resources = [NSURL resourceValuesForKeys:@[NSURLPathKey, NSURLIsAliasFileKey] fromBookmarkData:bookmarkData];
        if ([resources.allKeys containsObject:NSURLPathKey]) {
            NSURL *path = [NSURL URLWithString:[resources valueForKey:NSURLPathKey]];
            BOOL isDirectory = NO;
            BOOL artifactsPathExists = [[NSFileManager defaultManager] fileExistsAtPath:path.absoluteString isDirectory:&isDirectory];
            BOOL ipaFileExists = [[NSFileManager defaultManager] fileExistsAtPath:project.ipaFullPath.absoluteString];
            BOOL buildArchiveExists = [[NSFileManager defaultManager] fileExistsAtPath:project.buildArchivePath.absoluteString];
            BOOL exportOptionExists = [[NSFileManager defaultManager] fileExistsAtPath:project.exportOptionsPlistPath.absoluteString];
            if (artifactsPathExists && isDirectory && ipaFileExists && buildArchiveExists && exportOptionExists){
                NSError *error;
                [[NSFileManager defaultManager] copyItemAtURL:path toURL:project.ipaFullPath error:&error];
                [[NSFileManager defaultManager] copyItemAtURL:path toURL:project.exportOptionsPlistPath error:&error];
                [[NSFileManager defaultManager] copyItemAtURL:path toURL:project.buildArchivePath error:&error];
                return YES;
            } else {
                return NO;
            }
        } else {
            return NO;
        }
    } else {
        return NO;
    }
}

@end
