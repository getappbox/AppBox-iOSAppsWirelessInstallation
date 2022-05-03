//
//  Project+CoreDataClass.h
//  
//
//  Created by Vineet Choudhary on 17/10/17.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CISetting, UploadRecord;

NS_ASSUME_NONNULL_BEGIN

@interface Project : NSManagedObject

+(Project *)addProjectWithXCProject:(XCProject *)xcProject;

@end

NS_ASSUME_NONNULL_END

#import "Project+CoreDataProperties.h"
