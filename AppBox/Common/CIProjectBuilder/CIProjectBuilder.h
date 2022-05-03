//
//  RepoBuilder.h
//  AppBox
//
//  Created by Vineet Choudhary on 07/04/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "XCProject.h"

@interface CIProjectBuilder : NSObject {
    
}

+ (XCProject *)xcProjectWithIPAPath:(NSString *)ipaPath;

@end
