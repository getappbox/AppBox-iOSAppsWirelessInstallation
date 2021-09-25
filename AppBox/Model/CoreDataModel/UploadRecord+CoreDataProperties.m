//
//  UploadRecord+CoreDataProperties.m
//  
//
//  Created by Vineet Choudhary on 25/09/21.
//
//

#import "UploadRecord+CoreDataProperties.h"

@implementation UploadRecord (CoreDataProperties)

+ (NSFetchRequest<UploadRecord *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"UploadRecord"];
}

@dynamic build;
@dynamic buildType;
@dynamic datetime;
@dynamic dbAppInfoFullPath;
@dynamic dbDirectroy;
@dynamic dbFolderName;
@dynamic dbIPAFullPath;
@dynamic dbManifestFullPath;
@dynamic dbSharedAppInfoURL;
@dynamic dbSharedIPAURL;
@dynamic dbSharedManifestURL;
@dynamic keepSameLink;
@dynamic localBuildPath;
@dynamic mailURL;
@dynamic projectPath;
@dynamic shortURL;
@dynamic teamId;
@dynamic version;
@dynamic project;
@dynamic provisioningProfile;
@dynamic service;

@end
