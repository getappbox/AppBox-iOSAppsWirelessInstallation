//
//  ProvisioningProfile+CoreDataProperties.m
//  
//
//  Created by Vineet Choudhary on 29/10/17.
//
//

#import "ProvisioningProfile+CoreDataProperties.h"

@implementation ProvisioningProfile (CoreDataProperties)

+ (NSFetchRequest<ProvisioningProfile *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"ProvisioningProfile"];
}

@dynamic uuid;
@dynamic teamId;
@dynamic teamName;
@dynamic expirationDate;
@dynamic buildType;
@dynamic createDate;
@dynamic uploadRecord;
@dynamic provisionedDevices;

@end
