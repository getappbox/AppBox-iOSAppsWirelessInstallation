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

+(BOOL)copyArtifactsInBuildFolderForProject:(XCProject *)project {
    NSMutableArray *projectPathComponents = [[NSMutableArray alloc] initWithArray:[project.projectFullPath.resourceSpecifier pathComponents]];
    [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Path - %@", project.projectFullPath.resourceSpecifier]];
    if ([projectPathComponents.lastObject isEqualToString:@"/"]){
        [projectPathComponents removeLastObject];
    }
    [projectPathComponents removeLastObject];
    if ([projectPathComponents containsObject:jenkinsWorkspaceDir]) {
        [projectPathComponents replaceObjectAtIndex:[projectPathComponents indexOfObject:jenkinsWorkspaceDir] withObject:jenkinsJobsDir];
        [projectPathComponents addObjectsFromArray:@[artifactsRootDir, lastSuccessfulBuildShortcut, artifactsDir]];
        NSURL *path = [NSURL fileURLWithPathComponents:projectPathComponents];
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtURL:path withIntermediateDirectories:YES attributes:nil error:&error];
        BOOL ipaFileExists = [[NSFileManager defaultManager] fileExistsAtPath:project.ipaFullPath.resourceSpecifier];
        BOOL buildArchiveExists = [[NSFileManager defaultManager] fileExistsAtPath:project.buildArchivePath.resourceSpecifier];
        BOOL exportOptionExists = [[NSFileManager defaultManager] fileExistsAtPath:project.exportOptionsPlistPath.resourceSpecifier];
        if (ipaFileExists && buildArchiveExists && exportOptionExists){
            NSString *newIPAPath = [path.resourceSpecifier stringByAppendingString:project.ipaFullPath.lastPathComponent];
            [[NSFileManager defaultManager] copyItemAtPath:project.ipaFullPath.resourceSpecifier toPath:newIPAPath error:&error];
            
            NSString *newArchivePath = [path.resourceSpecifier stringByAppendingString:project.buildArchivePath.lastPathComponent];
            [[NSFileManager defaultManager] copyItemAtPath:project.buildArchivePath.resourceSpecifier toPath:newArchivePath error:&error];
            
            NSString *newExportPath = [path.resourceSpecifier stringByAppendingString:project.exportOptionsPlistPath.lastPathComponent];
            [[NSFileManager defaultManager] copyItemAtPath:project.exportOptionsPlistPath.resourceSpecifier toPath:newExportPath error:&error];
            return YES;
        } else {
            return NO;
        }
        
    } else {
        return NO;
    }
}

@end
