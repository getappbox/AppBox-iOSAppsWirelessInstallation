//
//  ABProject+CoreDataProperties.m
//  
//
//  Created by Vineet Choudhary on 11/10/18.
//
//

#import "Project+CoreDataProperties.h"

@implementation ABProject (CoreDataProperties)

+ (NSFetchRequest<ABProject *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"ABProject"];
}

@dynamic bundleIdentifier;
@dynamic name;
@dynamic ciSettings;
@dynamic uploadRecords;

@end
