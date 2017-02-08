//
//  UploadRecord+CoreDataProperties.m
//  
//
//  Created by Vineet Choudhary on 08/02/17.
//
//

#import "UploadRecord+CoreDataProperties.h"

@implementation UploadRecord (CoreDataProperties)

+ (NSFetchRequest<UploadRecord *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"UploadRecord"];
}

@dynamic build;
@dynamic buildScheme;
@dynamic buildType;
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
@dynamic shortURL;
@dynamic teamId;
@dynamic version;
@dynamic datetime;

@end
