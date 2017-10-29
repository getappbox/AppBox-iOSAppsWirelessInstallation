//
//  ProvisionedDevice+CoreDataProperties.m
//  
//
//  Created by Vineet Choudhary on 29/10/17.
//
//

#import "ProvisionedDevice+CoreDataProperties.h"

@implementation ProvisionedDevice (CoreDataProperties)

+ (NSFetchRequest<ProvisionedDevice *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"ProvisionedDevice"];
}

@dynamic deviceId;

@end
