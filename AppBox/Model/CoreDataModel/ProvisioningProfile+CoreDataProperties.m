//
//  ABProvisioningProfile+CoreDataProperties.m
//  
//
//  Created by Vineet Choudhary on 11/10/18.
//
//

#import "ProvisioningProfile+CoreDataProperties.h"

@implementation ABProvisioningProfile (CoreDataProperties)

+ (NSFetchRequest<ABProvisioningProfile *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"ProvisioningProfile"];
}

@dynamic buildType;
@dynamic createDate;
@dynamic expirationDate;
@dynamic teamId;
@dynamic teamName;
@dynamic uuid;
@dynamic provisionedDevices;
@dynamic uploadRecord;

@end
