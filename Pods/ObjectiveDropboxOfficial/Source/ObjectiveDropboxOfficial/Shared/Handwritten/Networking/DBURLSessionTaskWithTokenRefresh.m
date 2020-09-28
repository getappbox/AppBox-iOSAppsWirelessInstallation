///
/// Copyright (c) 2020 Dropbox, Inc. All rights reserved.
///

#import "DBURLSessionTaskWithTokenRefresh.h"

#import "DBAccessTokenProvider.h"
#import "DBDelegate.h"
#import "DBOAuthResult.h"
#import "DBURLSessionTaskResponseBlockWrapper.h"

@interface DBURLSessionTaskWithTokenRefresh ()

@property (nonatomic, weak) DBDelegate *taskDelegate;
@property (nonatomic, strong) DBURLSessionTaskCreationBlock taskCreationBlock;
@property (nonatomic, strong) id<DBAccessTokenProvider> tokenProvider;
@property (nonatomic, strong) DBProgressBlock progressBlock;
@property (nonatomic, strong) NSOperationQueue *progressQueue;
@property (nonatomic, strong) DBURLSessionTaskResponseBlockWrapper *responseBlockWrapper;
@property (nonatomic, strong) NSOperationQueue *responseQueue;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, strong, nullable) NSURLSessionTask *sessionTask;
@property (nonatomic, assign) BOOL cancelled;
@property (nonatomic, assign) BOOL suspended;
@property (nonatomic, assign) BOOL started;

@end

@implementation DBURLSessionTaskWithTokenRefresh

@synthesize session = _session;

- (instancetype)initWithTaskCreationBlock:(DBURLSessionTaskCreationBlock)taskCreationBlock
                             taskDelegate:(DBDelegate *)taskDelegate
                               urlSession:(NSURLSession *)urlSession
                            tokenProvider:(id<DBAccessTokenProvider>)tokenProvider {
  self = [super init];
  if (self) {
    _taskCreationBlock = taskCreationBlock;
    _taskDelegate = taskDelegate;
    _session = urlSession;
    _tokenProvider = tokenProvider;
    dispatch_queue_attr_t qosAttribute =
        dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0);
    _serialQueue =
        dispatch_queue_create("com.dropbox.dropbox_sdk_obj_c.DBURLSessionTaskWithTokenRefresh.queue", qosAttribute);
  }
  return self;
}

- (id<DBURLSessionTask>)duplicate {
  return [[DBURLSessionTaskWithTokenRefresh alloc] initWithTaskCreationBlock:_taskCreationBlock
                                                                taskDelegate:_taskDelegate
                                                                  urlSession:_session
                                                               tokenProvider:_tokenProvider];
}

- (void)cancel {
  dispatch_async(_serialQueue, ^{
    self->_cancelled = YES;
    [self->_sessionTask cancel];
  });
}

- (void)suspend {
  dispatch_async(_serialQueue, ^{
    self->_suspended = YES;
    [self->_sessionTask suspend];
  });
}

- (void)resume {
  dispatch_async(_serialQueue, ^{
    if (self->_started) {
      [self->_sessionTask resume];
    } else {
      self->_started = YES;
      [self db_start];
    }
  });
}

- (void)setProgressBlock:(DBProgressBlock)progressBlock queue:(NSOperationQueue *)queue {
  dispatch_async(_serialQueue, ^{
    self->_progressBlock = progressBlock;
    self->_progressQueue = queue;
    [self db_setProgressHandlerIfNecessary];
  });
}

- (void)setResponseBlock:(DBURLSessionTaskResponseBlockWrapper *)responseBlockWrapper queue:(NSOperationQueue *)queue {
  dispatch_async(_serialQueue, ^{
    self->_responseBlockWrapper = responseBlockWrapper;
    self->_responseQueue = queue;
    [self db_setResponseHandlerIfNecessary];
  });
}

#pragma mark Private helpers

- (void)db_start {
  DBOAuthCompletion completion = ^(DBOAuthResult *result) {
    dispatch_async(self->_serialQueue, ^{
      [self db_handleTokenRefreshResult:result];
    });
  };

  if (_tokenProvider) {
    [_tokenProvider refreshAccessTokenIfNecessary:completion];
  } else {
    completion(nil);
  }
}

- (void)db_handleTokenRefreshResult:(DBOAuthResult *)result {
  if ([result isError] && result.errorType != DBAuthInvalidGrant) {
    // Refresh failed, due to an error that's not invalid grant, e.g. A refresh request timed out.
    // Complete request with error immediately, so developers could retry and get access token refreshed.
    // Otherwise, the API request may proceed with an expired access token which would lead to
    // a false positive auth error.
    [self db_completeWithError:result.nsError];
  } else {
    // Refresh succeeded or a refresh is not required, i.e. access token is valid, continue request normally.
    // Or
    // Refresh failed due to invalid grant, e.g. refresh token revoked by user.
    // Continue, and the API call would failed with an auth error that developers can handle properly.
    // e.g. Sign out the user upon auth error.
    [self db_initializeSessionTask];
  }
}

- (void)db_initializeSessionTask {
  _sessionTask = _taskCreationBlock();
  [self db_setProgressHandlerIfNecessary];
  [self db_setResponseHandlerIfNecessary];
  if (_cancelled) {
    [_sessionTask cancel];
  } else if (_suspended) {
    [_sessionTask suspend];
  } else if (_started) {
    [_sessionTask resume];
  }
}

- (void)db_setProgressHandlerIfNecessary {
  if (_sessionTask && _progressBlock) {
    [_taskDelegate addProgressHandlerForTaskWithIdentifier:_sessionTask.taskIdentifier
                                                   session:_session
                                           progressHandler:_progressBlock
                                      progressHandlerQueue:_progressQueue];
  }
}

- (void)db_setResponseHandlerIfNecessary {
  if (_sessionTask == nil || _responseBlockWrapper == nil) {
    return;
  }

  if (_responseBlockWrapper.rpcResponseBlock) {
    [_taskDelegate addRpcResponseHandlerForTaskWithIdentifier:_sessionTask.taskIdentifier
                                                      session:_session
                                              responseHandler:_responseBlockWrapper.rpcResponseBlock
                                         responseHandlerQueue:_responseQueue];
  } else if (_responseBlockWrapper.uploadResponseBlock) {
    [_taskDelegate addUploadResponseHandlerForTaskWithIdentifier:_sessionTask.taskIdentifier
                                                         session:_session
                                                 responseHandler:_responseBlockWrapper.uploadResponseBlock
                                            responseHandlerQueue:_responseQueue];
  } else if (_responseBlockWrapper.downloadResponseBlock) {
    [_taskDelegate addDownloadResponseHandlerForTaskWithIdentifier:_sessionTask.taskIdentifier
                                                           session:_session
                                                   responseHandler:_responseBlockWrapper.downloadResponseBlock
                                              responseHandlerQueue:_responseQueue];
  }
}

- (void)db_completeWithError:(NSError *)error {
  NSOperationQueue *queue = _responseQueue ?: [NSOperationQueue mainQueue];
  DBURLSessionTaskResponseBlockWrapper *blockWrapper = _responseBlockWrapper;
  [queue addOperationWithBlock:^{
    if (blockWrapper.rpcResponseBlock) {
      blockWrapper.rpcResponseBlock(nil, nil, error);
    } else if (blockWrapper.uploadResponseBlock) {
      blockWrapper.uploadResponseBlock(nil, nil, error);
    } else if (blockWrapper.downloadResponseBlock) {
      blockWrapper.downloadResponseBlock(nil, nil, error);
    }
  }];
}

@end
