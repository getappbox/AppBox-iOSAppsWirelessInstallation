//
//  ABUploadRecord+CoreDataClass.m
//  
//
//  Created by Vineet Choudhary on 17/10/17.
//
//

#import "UploadRecord+CoreDataClass.h"

@implementation ABUploadRecord

@dynamic ipaUploadInfo;

-(IPAUploadInfo *)ipaUploadInfo{
    IPAUploadInfo *ipaUploadInfo = [[IPAUploadInfo alloc] init];
    
    //Basic Details
    if (self.project.name){
        ipaUploadInfo.name = self.project.name;
    }
    if (self.project.bundleIdentifier){
        ipaUploadInfo.identifer = self.project.bundleIdentifier;
    }
    if (self.version) {
        ipaUploadInfo.version = self.version;
    }
    if (self.build) {
        ipaUploadInfo.build = self.build;
    }
    if (self.buildType){
        ipaUploadInfo.buildType = self.buildType;
    }
    
    //Dropbox path and shared URL
    if (self.dbIPAFullPath) {
        ipaUploadInfo.dbIPAFullPath = [NSURL URLWithString:self.dbIPAFullPath];
    }
    if (self.dbManifestFullPath) {
        ipaUploadInfo.dbManifestFullPath = [NSURL URLWithString:self.dbManifestFullPath];
    }
    if (self.dbAppInfoFullPath){
        ipaUploadInfo.dbAppInfoJSONFullPath = [NSURL URLWithString:self.dbAppInfoFullPath];
    }
    if (self.dbDirectroy){
        ipaUploadInfo.dbDirectory = [NSURL URLWithString:self.dbDirectroy];
    }
    if (self.dbSharedIPAURL){
        ipaUploadInfo.ipaFileDBShareableURL = [NSURL URLWithString:self.dbSharedIPAURL];
    }
    if (self.dbSharedManifestURL){
        ipaUploadInfo.manifestFileSharableURL = [NSURL URLWithString:self.dbSharedManifestURL];
    }
    if (self.dbSharedAppInfoURL){
        ipaUploadInfo.uniquelinkShareableURL = [NSURL URLWithString:self.dbSharedAppInfoURL];
    }
    if (self.shortURL){
        ipaUploadInfo.appShortShareableURL = [NSURL URLWithString:self.shortURL];
    }
    
    //Keep Same Link
    ipaUploadInfo.isKeepSameLinkEnabled = self.keepSameLink.boolValue;

    //Local Path
    if (self.localBuildPath) {
        ipaUploadInfo.ipaFullPath = [NSURL fileURLWithPath:self.localBuildPath];
    }
    
    return ipaUploadInfo;
}

@end
