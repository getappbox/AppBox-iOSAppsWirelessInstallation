///
/// Copyright (c) 2020 Dropbox, Inc. All rights reserved.
///

#import "DBURLSessionTaskResponseBlockWrapper.h"

@interface DBURLSessionTaskResponseBlockWrapper ()

@property (nonatomic, strong, nullable) DBRpcResponseBlockStorage rpcResponseBlock;
@property (nonatomic, strong, nullable) DBUploadResponseBlockStorage uploadResponseBlock;
@property (nonatomic, strong, nullable) DBDownloadResponseBlockStorage downloadResponseBlock;

@end

@implementation DBURLSessionTaskResponseBlockWrapper

+ (DBURLSessionTaskResponseBlockWrapper *)withRpcResponseBlock:(DBRpcResponseBlockStorage)responseBlock {
  DBURLSessionTaskResponseBlockWrapper *wrapper = [[DBURLSessionTaskResponseBlockWrapper alloc] init];
  wrapper.rpcResponseBlock = responseBlock;
  return wrapper;
}

+ (DBURLSessionTaskResponseBlockWrapper *)withUploadResponseBlock:(DBUploadResponseBlockStorage)responseBlock {
  DBURLSessionTaskResponseBlockWrapper *wrapper = [[DBURLSessionTaskResponseBlockWrapper alloc] init];
  wrapper.uploadResponseBlock = responseBlock;
  return wrapper;
}

+ (DBURLSessionTaskResponseBlockWrapper *)withDownloadResponseBlock:(DBDownloadResponseBlockStorage)responseBlock {
  DBURLSessionTaskResponseBlockWrapper *wrapper = [[DBURLSessionTaskResponseBlockWrapper alloc] init];
  wrapper.downloadResponseBlock = responseBlock;
  return wrapper;
}

@end
