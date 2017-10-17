//
//  Project+CoreDataProperties.m
//  
//
//  Created by Vineet Choudhary on 17/10/17.
//
//

#import "Project+CoreDataProperties.h"

@implementation Project (CoreDataProperties)

+ (NSFetchRequest<Project *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"Project"];
}

@dynamic bundleIdentifier;
@dynamic name;
@dynamic ciSettings;
@dynamic uploadRecords;

@end
