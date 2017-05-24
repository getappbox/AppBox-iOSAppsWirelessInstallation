//
//  XCHandler.h
//  AppBox
//
//  Created by Vineet Choudhary on 27/03/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XCHandler : NSObject

+(void)getXCodePathWithCompletion:(void (^) (NSString *xcodePath, NSString *applicationLoaderPath))completion;

@end
