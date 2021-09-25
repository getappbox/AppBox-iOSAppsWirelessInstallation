//
//  AppBoxService+CoreDataProperties.m
//  
//
//  Created by Vineet Choudhary on 25/09/21.
//
//

#import "AppBoxService+CoreDataProperties.h"

@implementation AppBoxService (CoreDataProperties)

+ (NSFetchRequest<AppBoxService *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"AppBoxService"];
}

@dynamic name;
@dynamic accountEmail;
@dynamic accountId;
@dynamic accountAccessKey;
@dynamic baseURL;
@dynamic accountSecretKey;
@dynamic uploadRecords;

@end
