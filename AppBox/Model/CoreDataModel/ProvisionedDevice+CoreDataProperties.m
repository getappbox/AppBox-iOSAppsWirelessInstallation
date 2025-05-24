//
//  ABProvisionedDevice+CoreDataProperties.m
//  
//
//  Created by Vineet Choudhary on 11/10/18.
//
//

#import "ProvisionedDevice+CoreDataProperties.h"

@implementation ABProvisionedDevice (CoreDataProperties)

+ (NSFetchRequest<ABProvisionedDevice *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"ProvisionedDevice"];
}

@dynamic deviceId;

@end
