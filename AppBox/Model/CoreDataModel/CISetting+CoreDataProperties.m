//
//  CISetting+CoreDataProperties.m
//  
//
//  Created by Vineet Choudhary on 17/10/17.
//
//

#import "CISetting+CoreDataProperties.h"

@implementation CISetting (CoreDataProperties)

+ (NSFetchRequest<CISetting *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"CISetting"];
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
