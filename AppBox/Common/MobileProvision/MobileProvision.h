//
//  MobileProvision.h
//  AppBox
//
//  Created by Vineet Choudhary on 16/02/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MobileProvision : NSObject

-(NSString *) buildTypeForProvisioning:(NSString *)provisioningPath;

@end
