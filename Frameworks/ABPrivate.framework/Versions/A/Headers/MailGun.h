//
//  MailGun.h
//  ABPrivate
//
//  Created by Vineet Choudhary on 26/04/18.
//  Copyright © 2018 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ABPIPAUploadInfo.h"

@interface MailGun : NSObject

+ (void)sendMailWithIPAUploadInfo:(ABPIPAUploadInfo *)ipaUploadInfo complition:(void (^) (BOOL success, NSError *error))complition;

@end
