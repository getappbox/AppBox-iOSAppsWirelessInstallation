//
//  UploadRecord+CoreDataProperties.m
//  
//
//  Created by Vineet Choudhary on 07/02/17.
//
//

#import "UploadRecord+CoreDataProperties.h"

@implementation UploadRecord (CoreDataProperties)

+ (NSFetchRequest<UploadRecord *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"UploadRecord"];
}

@dynamic version;
@dynamic build;
@dynamic shortURL;
@dynamic dbSharedIPAURL;
@dynamic dbSharedManifestURL;
@dynamic dbSharedAppInfoURL;
@dynamic buildType;
@dynamic buildScheme;
@dynamic teamId;
@dynamic keepSameLink;
@dynamic dbDirectroy;
@dynamic dbIPAFullPath;
@dynamic dbManifestFullPath;
@dynamic dbAppInfoFullPath;
@dynamic dbFolderName;
@dynamic mailURL;
@dynamic localBuildPath;

@end
