//
//  ProvisionedDevice+CoreDataProperties.m
//  
//
//  Created by Vineet Choudhary on 11/10/18.
//
//

#import "ProvisionedDevice+CoreDataProperties.h"

@implementation ProvisionedDevice (CoreDataProperties)

+ (NSFetchRequest<ProvisionedDevice *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"ProvisionedDevice"];
}

@dynamic deviceId;

@end
