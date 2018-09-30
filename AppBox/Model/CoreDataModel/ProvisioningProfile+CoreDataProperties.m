//
//  ProvisioningProfile+CoreDataProperties.m
//  
//
//  Created by Vineet Choudhary on 30/09/18.
//
//

#import "ProvisioningProfile+CoreDataProperties.h"

@implementation ProvisioningProfile (CoreDataProperties)

+ (NSFetchRequest<ProvisioningProfile *> *)fetchRequest {
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
