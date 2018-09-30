//
//  Teams+CoreDataProperties.m
//  
//
//  Created by Vineet Choudhary on 30/09/18.
//
//

#import "Teams+CoreDataProperties.h"

@implementation Teams (CoreDataProperties)

+ (NSFetchRequest<Teams *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"Teams"];
}

@dynamic name;
@dynamic about;
@dynamic emails;
@dynamic slackWebHookURL;
@dynamic msTeamsWebHookURL;
@dynamic hangoutWebHookURL;
@dynamic projects;

@end
