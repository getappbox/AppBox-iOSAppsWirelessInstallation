///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBTasksImpl.h"
#import "DBDelegate.h"
#import "DBHandlerTypes.h"
#import "DBRequestErrors.h"
#import "DBStoneBase.h"
#import "DBTasks+Protected.h"
#import "DBTransportBaseClient.h"
#import "DBURLSessionTaskResponseBlockWrapper.h"

#pragma mark - RPC-style network task

@implementation DBRpcTaskImpl {
  DBRpcTaskImpl *_selfRetained;
  DBRpcResponseBlockImpl _responseBlock;
}

- (instancetype)initWithTask:(id<DBURLSessionTask>)task tokenUid:(NSString *)tokenUid route:(DBRoute *)route {
  self = [super initWithRoute:route tokenUid:tokenUid];
  if (self) {
    _task = task;
    _selfRetained = self;
  }
  return self;
}

- (NSURLSession *)session {
  return _task.session;
}

- (void)cancel {
  [_task cancel];
}

- (void)suspend {
  [_task suspend];
}

- (void)resume {
  [_task resume];
}

- (void)start {
  [_task resume];
}

- (void)cleanup {
  _selfRetained = nil;

  NSOperationQueue *queueToUse = _queue ?: [NSOperationQueue mainQueue];
  [queueToUse addOperationWithBlock:^{
    self->_responseBlock = nil;
  }];
}

- (DBTask *)restart {
  DBRpcTaskImpl *sdkTask =
      [[DBRpcTaskImpl alloc] initWithTask:[_task duplicate] tokenUid:self.tokenUid route:self.route];
  sdkTask.retryCount += 1;
  [sdkTask setResponseBlock:_responseBlock queue:_queue];
  [sdkTask resume];
  return sdkTask;
}

- (DBRpcTask *)setResponseBlock:(DBRpcResponseBlockImpl)responseBlock {
  return [self setResponseBlock:responseBlock queue:nil];
}

- (DBRpcTask *)setResponseBlock:(DBRpcResponseBlockImpl)responseBlock queue:(NSOperationQueue *)queue {
  _responseBlock = responseBlock;
  __weak __typeof(self) weakSelf = self;
  DBRpcResponseBlockStorage storageBlock = [self storageBlockWithResponseBlock:responseBlock
                                                                  cleanupBlock:^{
                                                                    [weakSelf cleanup];
                                                                  }];
  [_task setResponseBlock:[DBURLSessionTaskResponseBlockWrapper withRpcResponseBlock:storageBlock] queue:queue];
  return self;
}

- (DBRpcTask *)setProgressBlock:(DBProgressBlock)progressBlock {
  return [self setProgressBlock:progressBlock queue:nil];
}

- (DBRpcTask *)setProgressBlock:(DBProgressBlock)progressBlock queue:(NSOperationQueue *)queue {
  [_task setProgressBlock:progressBlock queue:queue];
  return self;
}

@end

#pragma mark - Upload-style network task

@implementation DBUploadTaskImpl {
  DBUploadTaskImpl *_selfRetained;
  DBUploadResponseBlockImpl _responseBlock;
}

- (instancetype)initWithTask:(id<DBURLSessionTask>)task tokenUid:(NSString *)tokenUid route:(DBRoute *)route {
  self = [super initWithRoute:route tokenUid:tokenUid];
  if (self) {
    _uploadTask = task;
    _selfRetained = self;
  }
  return self;
}

- (NSURLSession *)session {
  return _uploadTask.session;
}

- (void)cancel {
  [_uploadTask cancel];
}

- (void)suspend {
  [_uploadTask suspend];
}

- (void)resume {
  [_uploadTask resume];
}

- (void)start {
  [_uploadTask resume];
}

- (void)cleanup {
  _selfRetained = nil;

  NSOperationQueue *queueToUse = _queue ?: [NSOperationQueue mainQueue];
  [queueToUse addOperationWithBlock:^{
    self->_responseBlock = nil;
  }];
}

- (DBTask *)restart {
  DBUploadTaskImpl *sdkTask =
      [[DBUploadTaskImpl alloc] initWithTask:[_uploadTask duplicate] tokenUid:self.tokenUid route:self.route];
  sdkTask.retryCount += 1;
  [sdkTask setResponseBlock:_responseBlock queue:_queue];
  [sdkTask resume];
  return sdkTask;
}

- (DBUploadTask *)setResponseBlock:(DBUploadResponseBlockImpl)responseBlock {
  return [self setResponseBlock:responseBlock queue:nil];
}

- (DBUploadTask *)setResponseBlock:(DBUploadResponseBlockImpl)responseBlock queue:(NSOperationQueue *)queue {
  _responseBlock = responseBlock;
  __weak __typeof(self) weakSelf = self;
  DBUploadResponseBlockStorage storageBlock = [self storageBlockWithResponseBlock:responseBlock
                                                                     cleanupBlock:^{
                                                                       [weakSelf cleanup];
                                                                     }];
  [_uploadTask setResponseBlock:[DBURLSessionTaskResponseBlockWrapper withUploadResponseBlock:storageBlock]
                          queue:queue];
  return self;
}

- (DBUploadTask *)setProgressBlock:(DBProgressBlock)progressBlock {
  return [self setProgressBlock:progressBlock queue:nil];
}

- (DBUploadTask *)setProgressBlock:(DBProgressBlock)progressBlock queue:(NSOperationQueue *)queue {
  [_uploadTask setProgressBlock:progressBlock queue:queue];
  return self;
}

@end

#pragma mark - Download-style network task (NSURL)

@implementation DBDownloadUrlTaskImpl {
  DBDownloadUrlTaskImpl *_selfRetained;
  DBDownloadUrlResponseBlockImpl _responseBlock;
  id<DBURLSessionTask> _downloadUrlTask;
}

- (instancetype)initWithTask:(id<DBURLSessionTask>)task
                    tokenUid:(NSString *)tokenUid
                       route:(DBRoute *)route
                   overwrite:(BOOL)overwrite
                 destination:(NSURL *)destination {
  self = [super initWithRoute:route tokenUid:tokenUid];
  if (self) {
    _downloadUrlTask = task;
    _overwrite = overwrite;
    _destination = destination;
    _selfRetained = self;
  }
  return self;
}

- (NSURLSession *)session {
  return _downloadUrlTask.session;
}

- (void)cancel {
  [_downloadUrlTask cancel];
}

- (void)suspend {
  [_downloadUrlTask suspend];
}

- (void)resume {
  [_downloadUrlTask resume];
}

- (void)start {
  [_downloadUrlTask resume];
}

- (void)cleanup {
  _selfRetained = nil;

  NSOperationQueue *queueToUse = _queue ?: [NSOperationQueue mainQueue];
  [queueToUse addOperationWithBlock:^{
    self->_responseBlock = nil;
  }];
}

- (DBTask *)restart {
  DBDownloadUrlTaskImpl *sdkTask = [[DBDownloadUrlTaskImpl alloc] initWithTask:[_downloadUrlTask duplicate]
                                                                      tokenUid:self.tokenUid
                                                                         route:self.route
                                                                     overwrite:_overwrite
                                                                   destination:_destination];
  sdkTask.retryCount += 1;
  [sdkTask setResponseBlock:_responseBlock queue:_queue];
  [sdkTask resume];
  return sdkTask;
}

- (DBDownloadUrlTask *)setResponseBlock:(DBDownloadUrlResponseBlockImpl)responseBlock {
  return [self setResponseBlock:responseBlock queue:nil];
}

- (DBDownloadUrlTask *)setResponseBlock:(DBDownloadUrlResponseBlockImpl)responseBlock queue:(NSOperationQueue *)queue {
  _responseBlock = responseBlock;
  __weak __typeof(self) weakSelf = self;
  DBDownloadResponseBlockStorage storageBlock = [self storageBlockWithResponseBlock:responseBlock
                                                                       cleanupBlock:^{
                                                                         [weakSelf cleanup];
                                                                       }];

  [_downloadUrlTask setResponseBlock:[DBURLSessionTaskResponseBlockWrapper withDownloadResponseBlock:storageBlock]
                               queue:queue];
  return self;
}

- (DBDownloadUrlTask *)setProgressBlock:(DBProgressBlock)progressBlock {
  return [self setProgressBlock:progressBlock queue:nil];
}

- (DBDownloadUrlTask *)setProgressBlock:(DBProgressBlock)progressBlock queue:(NSOperationQueue *)queue {
  [_downloadUrlTask setProgressBlock:progressBlock queue:queue];
  return self;
}

@end

#pragma mark - Download-style network task (NSData)

@implementation DBDownloadDataTaskImpl {
  DBDownloadDataTaskImpl *_selfRetained;
  DBDownloadDataResponseBlockImpl _responseBlock;
  id<DBURLSessionTask> _downloadDataTask;
}

- (instancetype)initWithTask:(id<DBURLSessionTask>)task tokenUid:(NSString *)tokenUid route:(DBRoute *)route {
  self = [super initWithRoute:route tokenUid:tokenUid];
  if (self) {
    _downloadDataTask = task;
    _selfRetained = self;
  }
  return self;
}

- (NSURLSession *)session {
  return _downloadDataTask.session;
}

- (void)cancel {
  [_downloadDataTask cancel];
}

- (void)suspend {
  [_downloadDataTask suspend];
}

- (void)resume {
  [_downloadDataTask resume];
}

- (void)start {
  [_downloadDataTask resume];
}

- (void)cleanup {
  _selfRetained = nil;

  NSOperationQueue *queueToUse = _queue ?: [NSOperationQueue mainQueue];
  [queueToUse addOperationWithBlock:^{
    self->_responseBlock = nil;
  }];
}

- (DBTask *)restart {
  DBDownloadDataTaskImpl *sdkTask = [[DBDownloadDataTaskImpl alloc] initWithTask:[_downloadDataTask duplicate]
                                                                        tokenUid:self.tokenUid
                                                                           route:self.route];
  sdkTask.retryCount += 1;
  [sdkTask setResponseBlock:_responseBlock queue:_queue];
  [sdkTask resume];
  return sdkTask;
}

- (DBDownloadDataTask *)setResponseBlock:(DBDownloadDataResponseBlockImpl)responseBlock {
  return [self setResponseBlock:responseBlock queue:nil];
}

- (DBDownloadDataTask *)setResponseBlock:(DBDownloadDataResponseBlockImpl)responseBlock
                                   queue:(NSOperationQueue *)queue {
  _responseBlock = responseBlock;
  __weak __typeof(self) weakSelf = self;
  DBDownloadResponseBlockStorage storageBlock = [self storageBlockWithResponseBlock:responseBlock
                                                                       cleanupBlock:^{
                                                                         [weakSelf cleanup];
                                                                       }];
  [_downloadDataTask setResponseBlock:[DBURLSessionTaskResponseBlockWrapper withDownloadResponseBlock:storageBlock]
                                queue:queue];
  return self;
}

- (DBDownloadDataTask *)setProgressBlock:(DBProgressBlock)progressBlock {
  return [self setProgressBlock:progressBlock queue:nil];
}

- (DBDownloadDataTask *)setProgressBlock:(DBProgressBlock)progressBlock queue:(NSOperationQueue *)queue {
  [_downloadDataTask setProgressBlock:progressBlock queue:queue];
  return self;
}

@end
