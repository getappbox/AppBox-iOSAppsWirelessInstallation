//
//  DBErrorHandler.h
//  AppBox
//
//  Created by Vineet Choudhary on 17/10/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DBErrorHandler : NSObject

+(void)handleNetworkErrorWith:(DBRequestError *)networkError;
+(void)handleDeleteErrorWith:(DBFILESDeleteError *)deleteError;
+(void)handleUploadErrorWith:(DBFILESUploadError *)uploadError;
+(void)handleUploadSessionLookupError:(DBFILESUploadSessionLookupError *)error;
+(void)handleUploadSessionFinishError:(DBFILESUploadSessionFinishError *)error;

@end
