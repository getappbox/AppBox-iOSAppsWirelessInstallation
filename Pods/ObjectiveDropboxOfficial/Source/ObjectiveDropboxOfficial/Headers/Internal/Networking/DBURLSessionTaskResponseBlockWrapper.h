///
/// Copyright (c) 2020 Dropbox, Inc. All rights reserved.
///

#import "DBHandlerTypesInternal.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Response handler for DBURLSessionTask.
@interface DBURLSessionTaskResponseBlockWrapper : NSObject

@property (nonatomic, strong, readonly, nullable) DBRpcResponseBlockStorage rpcResponseBlock;
@property (nonatomic, strong, readonly, nullable) DBUploadResponseBlockStorage uploadResponseBlock;
@property (nonatomic, strong, readonly, nullable) DBDownloadResponseBlockStorage downloadResponseBlock;

/// Handler wrapper for RPC tasks.
+ (DBURLSessionTaskResponseBlockWrapper *)withRpcResponseBlock:(DBRpcResponseBlockStorage)responseBlock;
/// Handler wrapper for upload tasks.
+ (DBURLSessionTaskResponseBlockWrapper *)withUploadResponseBlock:(DBUploadResponseBlockStorage)responseBlock;
/// Handler wrapper for download tasks.
+ (DBURLSessionTaskResponseBlockWrapper *)withDownloadResponseBlock:(DBDownloadResponseBlockStorage)responseBlock;

@end

NS_ASSUME_NONNULL_END
