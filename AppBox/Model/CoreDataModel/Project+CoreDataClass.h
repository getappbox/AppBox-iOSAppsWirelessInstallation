//
//  Project+CoreDataClass.h
//  
//
//  Created by Vineet Choudhary on 08/02/17.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CISetting, UploadRecord;

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    SaveCIDetails,
    SaveUploadDetails,
} SaveDetails;

@interface Project : NSManagedObject

- (Project *)addProjectWithXCProject:(XCProject *)xcProject andSaveDetails:(SaveDetails)saveDetails;

@end

NS_ASSUME_NONNULL_END

#import "Project+CoreDataProperties.h"
