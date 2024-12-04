//
//  ABUploadRecord+CoreDataClass.m
//  
//
//  Created by Vineet Choudhary on 17/10/17.
//
//

#import "UploadRecord+CoreDataClass.h"

@implementation ABUploadRecord

@dynamic xcProject;

-(XCProject *)xcProject{
    XCProject *xcProject = [[XCProject alloc] init];
    
    //Basic Details
    if (self.project.name){
        xcProject.name = self.project.name;
    }
    if (self.project.bundleIdentifier){
        xcProject.identifer = self.project.bundleIdentifier;
    }
    if (self.version) {
        xcProject.version = self.version;
    }
    if (self.build) {
        xcProject.build = self.build;
    }
    if (self.buildType){
        xcProject.buildType = self.buildType;
    }
    
    //Dropbox path and shared URL
    if (self.dbIPAFullPath) {
        xcProject.dbIPAFullPath = [NSURL URLWithString:self.dbIPAFullPath];
    }
    if (self.dbManifestFullPath) {
        xcProject.dbManifestFullPath = [NSURL URLWithString:self.dbManifestFullPath];
    }
    if (self.dbAppInfoFullPath){
        xcProject.dbAppInfoJSONFullPath = [NSURL URLWithString:self.dbAppInfoFullPath];
    }
    if (self.dbDirectroy){
        xcProject.dbDirectory = [NSURL URLWithString:self.dbDirectroy];
    }
    if (self.dbSharedIPAURL){
        xcProject.ipaFileDBShareableURL = [NSURL URLWithString:self.dbSharedIPAURL];
    }
    if (self.dbSharedManifestURL){
        xcProject.manifestFileSharableURL = [NSURL URLWithString:self.dbSharedManifestURL];
    }
    if (self.dbSharedAppInfoURL){
        xcProject.uniquelinkShareableURL = [NSURL URLWithString:self.dbSharedAppInfoURL];
    }
    if (self.shortURL){
        xcProject.appShortShareableURL = [NSURL URLWithString:self.shortURL];
    }
    
    //Keep Same Link
    xcProject.isKeepSameLinkEnabled = self.keepSameLink.boolValue;

    //Local Path
    if (self.localBuildPath) {
        xcProject.ipaFullPath = [NSURL fileURLWithPath:self.localBuildPath];
    }
    
    return xcProject;
}

@end
