//
//  RepoBuilder.h
//  AppBox
//
//  Created by Vineet Choudhary on 07/04/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "IPAUploadInfo.h"

@interface CLIIPAUpload : NSObject {
    
}

+ (IPAUploadInfo *)ipaUploadInfoWithIPAPath:(NSString *)ipaPath;

@end
