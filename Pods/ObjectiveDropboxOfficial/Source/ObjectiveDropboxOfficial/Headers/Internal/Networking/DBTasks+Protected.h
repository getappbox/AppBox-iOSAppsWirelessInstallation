///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBHandlerTypesInternal.h"
#import "DBTasks.h"
#import <Foundation/Foundation.h>

@class DBRoute;

@interface DBRpcTask (Protected)

- (DBRpcResponseBlockStorage _Nonnull)storageBlockWithResponseBlock:(DBRpcResponseBlockImpl _Nonnull)responseBlock;

@end

@interface DBUploadTask (Protected)

- (DBUploadResponseBlockStorage _Nonnull)storageBlockWithResponseBlock:
    (DBUploadResponseBlockImpl _Nonnull)responseBlock;

@end

@interface DBDownloadUrlTask (Protected)

- (DBDownloadResponseBlockStorage _Nonnull)storageBlockWithResponseBlock:
    (DBDownloadUrlResponseBlockImpl _Nonnull)responseBlock;

@end

@interface DBDownloadDataTask (Protected)

- (DBDownloadResponseBlockStorage _Nonnull)storageBlockWithResponseBlock:
    (DBDownloadDataResponseBlockImpl _Nonnull)responseBlock;

@end
