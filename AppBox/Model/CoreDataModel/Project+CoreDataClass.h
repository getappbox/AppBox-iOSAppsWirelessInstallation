//
//  ABProject+CoreDataClass.h
//  
//
//  Created by Vineet Choudhary on 17/10/17.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CISetting, ABUploadRecord;

NS_ASSUME_NONNULL_BEGIN

@interface ABProject : NSManagedObject

+(ABProject *)addProjectWithXCProject:(XCProject *)xcProject;

@end

NS_ASSUME_NONNULL_END

#import "Project+CoreDataProperties.h"
