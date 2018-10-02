//
//  Project+CoreDataProperties.m
//  
//
//  Created by Vineet Choudhary on 30/09/18.
//
//

#import "Project+CoreDataProperties.h"

@implementation Project (CoreDataProperties)

+ (NSFetchRequest<Project *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"Project"];
}

@dynamic bundleIdentifier;
@dynamic name;
@dynamic ciSettings;
@dynamic uploadRecords;
@dynamic teams;

@end
