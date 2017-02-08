//
//  CISetting+CoreDataProperties.m
//  
//
//  Created by Vineet Choudhary on 08/02/17.
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
@dynamic emailAddress;
@dynamic keepSameLink;
@dynamic personalMessage;
@dynamic shutdownMac;
@dynamic teamId;

@end
