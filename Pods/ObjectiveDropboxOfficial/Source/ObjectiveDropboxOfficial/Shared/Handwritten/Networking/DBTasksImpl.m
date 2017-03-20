///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBDelegate.h"
#import "DBHandlerTypes.h"
#import "DBRequestErrors.h"
#import "DBStoneBase.h"
#import "DBTasks+Protected.h"
#import "DBTasksImpl.h"
#import "DBTransportBaseClient.h"

#pragma mark - RPC-style network task

@implementation DBRpcTaskImpl

- (instancetype)initWithTask:(NSURLSessionDataTask *)task
                     session:(NSURLSession *)session
                    delegate:(DBDelegate *)delegate
                       route:(DBRoute *)route {
  self = [super initWithRoute:route task:task];
  if (self) {
    _dataTask = task;
    _session = session;
    _delegate = delegate;
  }
  return self;
}

- (DBRpcTask *)setResponseBlock:(DBRpcResponseBlockImpl)responseBlock {
  return [self setResponseBlock:responseBlock queue:nil];
}

- (DBRpcTask *)setResponseBlock:(DBRpcResponseBlockImpl)responseBlock queue:(NSOperationQueue *)queue {
  DBRpcResponseBlockStorage storageBlock = [self storageBlockWithResponseBlock:responseBlock];
  [_delegate addRpcResponseHandler:_task session:_session responseHandler:storageBlock responseHandlerQueue:queue];
  return self;
}

- (DBRpcTask *)setProgressBlock:(DBProgressBlock)progressBlock {
  return [self setProgressBlock:progressBlock queue:nil];
}

- (DBRpcTask *)setProgressBlock:(DBProgressBlock)progressBlock queue:(NSOperationQueue *)queue {
  [_delegate addProgressHandler:_task session:_session progressHandler:progressBlock progressHandlerQueue:queue];
  return self;
}

@end

#pragma mark - Upload-style network task

@implementation DBUploadTaskImpl

- (instancetype)initWithTask:(NSURLSessionUploadTask *)task
                     session:(NSURLSession *)session
                    delegate:(DBDelegate *)delegate
                       route:(DBRoute *)route {
  self = [super initWithRoute:route task:task];
  if (self) {
    _uploadTask = task;
    _session = session;
    _delegate = delegate;
  }
  return self;
}

- (DBUploadTask *)setResponseBlock:(DBUploadResponseBlockImpl)responseBlock {
  return [self setResponseBlock:responseBlock queue:nil];
}

- (DBUploadTask *)setResponseBlock:(DBUploadResponseBlockImpl)responseBlock queue:(NSOperationQueue *)queue {
  DBUploadResponseBlockStorage storageBlock = [self storageBlockWithResponseBlock:responseBlock];
  [_delegate addUploadResponseHandler:_task session:_session responseHandler:storageBlock responseHandlerQueue:queue];

  return self;
}

- (DBUploadTask *)setProgressBlock:(DBProgressBlock)progressBlock {
  return [self setProgressBlock:progressBlock queue:nil];
}

- (DBUploadTask *)setProgressBlock:(DBProgressBlock)progressBlock queue:(NSOperationQueue *)queue {
  [_delegate addProgressHandler:_task session:_session progressHandler:progressBlock progressHandlerQueue:queue];
  return self;
}

@end

#pragma mark - Download-style network task (NSURL)

@implementation DBDownloadUrlTaskImpl

- (instancetype)initWithTask:(NSURLSessionDownloadTask *)task
                     session:(NSURLSession *)session
                    delegate:(DBDelegate *)delegate
                       route:(DBRoute *)route
                   overwrite:(BOOL)overwrite
                 destination:(NSURL *)destination {
  self = [super initWithRoute:route task:task];
  if (self) {
    _downloadUrlTask = task;
    _session = session;
    _delegate = delegate;
    _overwrite = overwrite;
    _destination = destination;
  }
  return self;
}

- (DBDownloadUrlTask *)setResponseBlock:(DBDownloadUrlResponseBlockImpl)responseBlock {
  return [self setResponseBlock:responseBlock queue:nil];
}

- (DBDownloadUrlTask *)setResponseBlock:(DBDownloadUrlResponseBlockImpl)responseBlock queue:(NSOperationQueue *)queue {
  DBDownloadResponseBlockStorage storageBlock = [self storageBlockWithResponseBlock:responseBlock];
  [_delegate addDownloadResponseHandler:_task session:_session responseHandler:storageBlock responseHandlerQueue:queue];

  return self;
}

- (DBDownloadUrlTask *)setProgressBlock:(DBProgressBlock)progressBlock {
  return [self setProgressBlock:progressBlock queue:nil];
}

- (DBDownloadUrlTask *)setProgressBlock:(DBProgressBlock)progressBlock queue:(NSOperationQueue *)queue {
  [_delegate addProgressHandler:_task session:_session progressHandler:progressBlock progressHandlerQueue:queue];
  return self;
}

@end

#pragma mark - Download-style network task (NSData)

@implementation DBDownloadDataTaskImpl

- (instancetype)initWithTask:(NSURLSessionDownloadTask *)task
                     session:(NSURLSession *)session
                    delegate:(DBDelegate *)delegate
                       route:(DBRoute *)route {
  self = [super initWithRoute:route task:task];
  if (self) {
    _downloadDataTask = task;
    _session = session;
    _delegate = delegate;
  }
  return self;
}

- (DBDownloadDataTask *)setResponseBlock:(DBDownloadDataResponseBlockImpl)responseBlock {
  return [self setResponseBlock:responseBlock queue:nil];
}

- (DBDownloadDataTask *)setResponseBlock:(DBDownloadDataResponseBlockImpl)responseBlock
                                   queue:(NSOperationQueue *)queue {
  DBDownloadResponseBlockStorage storageBlock = [self storageBlockWithResponseBlock:responseBlock];
  [_delegate addDownloadResponseHandler:_task session:_session responseHandler:storageBlock responseHandlerQueue:queue];

  return self;
}

- (DBDownloadDataTask *)setProgressBlock:(DBProgressBlock)progressBlock {
  return [self setProgressBlock:progressBlock queue:nil];
}

- (DBDownloadDataTask *)setProgressBlock:(DBProgressBlock)progressBlock queue:(NSOperationQueue *)queue {
  [_delegate addProgressHandler:_task session:_session progressHandler:progressBlock progressHandlerQueue:queue];
  return self;
}

@end
