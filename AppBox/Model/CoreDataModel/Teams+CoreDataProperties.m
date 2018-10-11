//
//  Teams+CoreDataProperties.m
//  
//
//  Created by Vineet Choudhary on 11/10/18.
//
//

#import "Teams+CoreDataProperties.h"

@implementation Teams (CoreDataProperties)

+ (NSFetchRequest<Teams *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"Teams"];
}

@dynamic about;
@dynamic emails;
@dynamic hangoutWebHookURL;
@dynamic msTeamsWebHookURL;
@dynamic name;
@dynamic slackWebHookURL;
@dynamic projects;

@end
