//
//  CISetting+CoreDataProperties.m
//  
//
//  Created by Vineet Choudhary on 07/02/17.
//
//

#import "CISetting+CoreDataProperties.h"

@implementation CISetting (CoreDataProperties)

+ (NSFetchRequest<CISetting *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"CISetting"];
}

@dynamic branchName;
@dynamic buildType;
@dynamic keepSameLink;
@dynamic emailAddress;
@dynamic personalMessage;
@dynamic shutdownMac;
@dynamic buildScheme;
@dynamic teamId;

@end
