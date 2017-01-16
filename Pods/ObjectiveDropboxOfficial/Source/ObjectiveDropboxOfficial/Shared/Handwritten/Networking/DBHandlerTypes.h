///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

typedef void (^DBProgressBlock)(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite);

typedef void (^DBRpcResponseBlock)(NSData * _Nullable, NSURLResponse * _Nullable, NSError * _Nullable);

typedef void (^DBUploadResponseBlock)(NSData * _Nullable, NSURLResponse * _Nullable, NSError * _Nullable);

typedef void (^DBDownloadResponseBlock)(NSURL * _Nullable, NSURLResponse * _Nullable, NSError * _Nullable);
