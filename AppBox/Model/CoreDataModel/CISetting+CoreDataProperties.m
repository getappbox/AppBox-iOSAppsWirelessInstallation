//
//  CISetting+CoreDataProperties.m
//  
//
//  Created by Vineet Choudhary on 30/09/18.
//
//

#import "CISetting+CoreDataProperties.h"

@implementation CISetting (CoreDataProperties)

+ (NSFetchRequest<CISetting *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"CISetting"];
}

@dynamic branchName;
@dynamic buildScheme;
@dynamic buildType;
@dynamic dbFolderName;
@dynamic emailAddress;
@dynamic keepSameLink;
@dynamic personalMessage;
@dynamic projectPath;
@dynamic shutdownMac;
@dynamic teamId;
@dynamic project;

@end
