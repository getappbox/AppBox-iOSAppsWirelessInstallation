///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBConstants.h"
#import "DBDelegate.h"
#import "DBSessionData.h"

@interface DBDelegate ()

@property (nonatomic) NSOperationQueue * _Nonnull delegateQueue;
@property (nonatomic) NSMutableDictionary<NSString *, DBSessionData *> * _Nonnull sessionData;

@end

#pragma mark - Initializers

@implementation DBDelegate

- (instancetype)initWithQueue:(NSOperationQueue *)delegateQueue {
  self = [super init];
  if (self) {
    if (delegateQueue) {
      _delegateQueue = delegateQueue;
    } else {
      _delegateQueue = [NSOperationQueue mainQueue];
    }
    [_delegateQueue setMaxConcurrentOperationCount:1];
    _sessionData = [NSMutableDictionary new];
  }
  return self;
}

#pragma mark - Delegate protocol methods

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
  DBSessionData *sessionData = [self sessionDataWithSession:session];
  NSNumber *taskId = @(dataTask.taskIdentifier);

  if (sessionData.responsesData[taskId]) {
    [sessionData.responsesData[taskId] appendData:data];
  } else {
    sessionData.responsesData[taskId] = [NSMutableData dataWithData:data];
  }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
  DBSessionData *sessionData = [self sessionDataWithSession:session];
  NSNumber *taskId = @(task.taskIdentifier);

  if (error && [task isKindOfClass:[NSURLSessionDownloadTask class]]) {
    DBDownloadResponseBlock responseHandler = sessionData.downloadHandlers[taskId];
    if (responseHandler) {
      NSOperationQueue *handlerQueue = sessionData.responseHandlerQueues[taskId];
      if (handlerQueue) {
        [handlerQueue addOperationWithBlock:^{
          responseHandler(nil, task.response, error);
        }];
      } else {
        responseHandler(nil, task.response, error);
      }
      [sessionData.downloadHandlers removeObjectForKey:taskId];
      [sessionData.progressHandlers removeObjectForKey:taskId];
      [sessionData.progressData removeObjectForKey:taskId];
      [sessionData.responsesData removeObjectForKey:taskId];
      [sessionData.responseHandlerQueues removeObjectForKey:taskId];
      [sessionData.progressHandlerQueues removeObjectForKey:taskId];
    } else {
      sessionData.completionData[taskId] = [[DBCompletionData alloc] initWithCompletionData:nil
                                                                           responseMetadata:task.response
                                                                              responseError:error
                                                                                  urlOutput:nil];
    }
  } else if ([task isKindOfClass:[NSURLSessionUploadTask class]]) {
    NSMutableData *responseData = sessionData.responsesData[taskId];
    DBUploadResponseBlock responseHandler = sessionData.uploadHandlers[taskId];
    if (responseHandler) {
      NSOperationQueue *handlerQueue = sessionData.responseHandlerQueues[taskId];
      if (handlerQueue) {
        [handlerQueue addOperationWithBlock:^{
          responseHandler(responseData, task.response, error);
        }];
      } else {
        responseHandler(responseData, task.response, error);
      }
      [sessionData.responsesData removeObjectForKey:taskId];
      [sessionData.uploadHandlers removeObjectForKey:taskId];
      [sessionData.progressHandlers removeObjectForKey:taskId];
      [sessionData.progressData removeObjectForKey:taskId];
      [sessionData.responsesData removeObjectForKey:taskId];
      [sessionData.responseHandlerQueues removeObjectForKey:taskId];
      [sessionData.progressHandlerQueues removeObjectForKey:taskId];
    } else {
      sessionData.completionData[taskId] = [[DBCompletionData alloc] initWithCompletionData:responseData
                                                                           responseMetadata:task.response
                                                                              responseError:error
                                                                                  urlOutput:nil];
    }
  } else if ([task isKindOfClass:[NSURLSessionDataTask class]]) {
    NSMutableData *responseData = sessionData.responsesData[taskId];
    DBRpcResponseBlock responseHandler = sessionData.rpcHandlers[taskId];
    if (responseHandler) {
      NSOperationQueue *handlerQueue = sessionData.responseHandlerQueues[taskId];
      if (handlerQueue) {
        [handlerQueue addOperationWithBlock:^{
          responseHandler(responseData, task.response, error);
        }];
      } else {
        responseHandler(responseData, task.response, error);
      }
      [sessionData.responsesData removeObjectForKey:taskId];
      [sessionData.rpcHandlers removeObjectForKey:taskId];
      [sessionData.progressHandlers removeObjectForKey:taskId];
      [sessionData.progressData removeObjectForKey:taskId];
      [sessionData.responsesData removeObjectForKey:taskId];
      [sessionData.responseHandlerQueues removeObjectForKey:taskId];
      [sessionData.progressHandlerQueues removeObjectForKey:taskId];
    } else {
      sessionData.completionData[taskId] = [[DBCompletionData alloc] initWithCompletionData:responseData
                                                                           responseMetadata:task.response
                                                                              responseError:error
                                                                                  urlOutput:nil];
    }
  }
}

- (void)URLSession:(NSURLSession *)session
                        task:(NSURLSessionTask *)task
             didSendBodyData:(int64_t)bytesSent
              totalBytesSent:(int64_t)totalBytesSent
    totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
  DBSessionData *sessionData = [self sessionDataWithSession:session];
  NSNumber *taskId = @(task.taskIdentifier);

  if ([task isKindOfClass:[NSURLSessionDataTask class]]) {
    DBProgressBlock progressHandler = sessionData.progressHandlers[taskId];
    if (progressHandler) {
      NSOperationQueue *handlerQueue = sessionData.progressHandlerQueues[taskId];
      if (handlerQueue) {
        [handlerQueue addOperationWithBlock:^{
          progressHandler(bytesSent, totalBytesSent, totalBytesExpectedToSend);
        }];
      } else {
        progressHandler(bytesSent, totalBytesSent, totalBytesExpectedToSend);
      }
    } else {
      sessionData.progressData[taskId] = [[DBProgressData alloc] initWithProgressData:bytesSent
                                                                       totalCommitted:totalBytesSent
                                                                     expectedToCommit:totalBytesExpectedToSend];
    }
  }
}

- (void)URLSession:(NSURLSession *)session
                 downloadTask:(NSURLSessionDownloadTask *)downloadTask
                 didWriteData:(int64_t)bytesWritten
            totalBytesWritten:(int64_t)totalBytesWritten
    totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
  DBSessionData *sessionData = [self sessionDataWithSession:session];
  NSNumber *taskId = @(downloadTask.taskIdentifier);

  DBProgressBlock progressHandler = sessionData.progressHandlers[taskId];
  if (progressHandler) {
    NSOperationQueue *handlerQueue = sessionData.progressHandlerQueues[taskId];
    if (handlerQueue) {
      [handlerQueue addOperationWithBlock:^{
        progressHandler(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
      }];
    } else {
      progressHandler(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
    }
  } else {
    sessionData.progressData[taskId] = [[DBProgressData alloc] initWithProgressData:bytesWritten
                                                                     totalCommitted:totalBytesWritten
                                                                   expectedToCommit:totalBytesExpectedToWrite];
  }
}

- (void)URLSession:(NSURLSession *)session
                 downloadTask:(NSURLSessionDownloadTask *)downloadTask
    didFinishDownloadingToURL:(NSURL *)location {
  DBSessionData *sessionData = [self sessionDataWithSession:session];
  NSNumber *taskId = @(downloadTask.taskIdentifier);

  DBDownloadResponseBlock responseHandler = sessionData.downloadHandlers[taskId];
  if (responseHandler) {
    NSOperationQueue *handlerQueue = sessionData.responseHandlerQueues[taskId];
    if (handlerQueue) {
      NSString *tmpOutputPath = [self moveFileToTempStorage:location];
      [handlerQueue addOperationWithBlock:^{
        responseHandler([NSURL URLWithString:tmpOutputPath], downloadTask.response, nil);
      }];
    } else {
      responseHandler(location, downloadTask.response, nil);
    }
    [sessionData.downloadHandlers removeObjectForKey:taskId];
    [sessionData.progressHandlers removeObjectForKey:taskId];
    [sessionData.progressData removeObjectForKey:taskId];
    [sessionData.responsesData removeObjectForKey:taskId];
    [sessionData.responseHandlerQueues removeObjectForKey:taskId];
    [sessionData.progressHandlerQueues removeObjectForKey:taskId];
  } else {
    NSString *tmpOutputPath = [self moveFileToTempStorage:location];
    sessionData.completionData[taskId] =
        [[DBCompletionData alloc] initWithCompletionData:nil
                                        responseMetadata:downloadTask.response
                                           responseError:nil
                                               urlOutput:[NSURL URLWithString:tmpOutputPath]];
  }
}

- (NSString *)moveFileToTempStorage:(NSURL *)startingLocation {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *tmpOutputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSUUID UUID].UUIDString];

  NSError *fileMoveError;
  [fileManager moveItemAtPath:[startingLocation path] toPath:tmpOutputPath error:&fileMoveError];
  if (fileMoveError) {
    NSLog(@"Error moving file to temporary storage location: %@", fileMoveError);
  }

  return tmpOutputPath;
}

- (void)addProgressHandler:(NSURLSessionTask *)task
                   session:(NSURLSession *)session
           progressHandler:(void (^)(int64_t, int64_t, int64_t))handler
      progressHandlerQueue:(NSOperationQueue *)handlerQueue {
  NSNumber *taskId = @(task.taskIdentifier);

  [_delegateQueue addOperationWithBlock:^{
    DBSessionData *sessionData = [self sessionDataWithSession:session];
    // there is a handler queued to be executed
    DBProgressData *progressData = sessionData.progressData[taskId];
    if (progressData) {
      NSOperationQueue *handlerQueue = sessionData.progressHandlerQueues[taskId];
      if (handlerQueue) {
        [handlerQueue addOperationWithBlock:^{
          handler(progressData.committed, progressData.totalCommitted, progressData.expectedToCommit);
        }];
      } else {
        handler(progressData.committed, progressData.totalCommitted, progressData.expectedToCommit);
      }
      [sessionData.progressData removeObjectForKey:taskId];
    } else {
      sessionData.progressHandlers[taskId] = handler;
      if (handlerQueue) {
        sessionData.progressHandlerQueues[taskId] = handlerQueue;
      }
    }
  }];
}

#pragma mark - Add RPC-style handler

- (void)addRpcResponseHandler:(NSURLSessionTask *)task
                      session:(NSURLSession *)session
              responseHandler:(DBRpcResponseBlock)handler
         responseHandlerQueue:(NSOperationQueue *)handlerQueue {
  NSNumber *taskId = @(task.taskIdentifier);
  DBSessionData *sessionData = [self sessionDataWithSession:session];

  [_delegateQueue addOperationWithBlock:^{
    DBCompletionData *completionData = sessionData.completionData[taskId];
    if (completionData) {
      NSOperationQueue *handlerQueue = sessionData.responseHandlerQueues[taskId];
      if (handlerQueue) {
        [handlerQueue addOperationWithBlock:^{
          handler(completionData.responseBody, completionData.responseMetadata, completionData.responseError);
        }];
      } else {
        handler(completionData.responseBody, completionData.responseMetadata, completionData.responseError);
      }
      [sessionData.progressData removeObjectForKey:taskId];
      [sessionData.completionData removeObjectForKey:taskId];
      [sessionData.rpcHandlers removeObjectForKey:taskId];
      [sessionData.progressHandlers removeObjectForKey:taskId];
      [sessionData.responseHandlerQueues removeObjectForKey:taskId];
      [sessionData.progressHandlerQueues removeObjectForKey:taskId];
    } else {
      sessionData.rpcHandlers[taskId] = handler;
      if (handlerQueue) {
        sessionData.responseHandlerQueues[taskId] = handlerQueue;
      }
    }
  }];
}

#pragma mark - Add Upload-style handler

- (void)addUploadResponseHandler:(NSURLSessionTask *)task
                         session:(NSURLSession *)session
                 responseHandler:(void (^)(NSData *, NSURLResponse *, NSError *))handler
            responseHandlerQueue:(NSOperationQueue *)handlerQueue {
  NSNumber *taskId = @(task.taskIdentifier);
  DBSessionData *sessionData = [self sessionDataWithSession:session];

  [_delegateQueue addOperationWithBlock:^{
    DBCompletionData *completionData = sessionData.completionData[taskId];
    if (completionData) {
      NSOperationQueue *handlerQueue = sessionData.responseHandlerQueues[taskId];
      if (handlerQueue) {
        [handlerQueue addOperationWithBlock:^{
          handler(completionData.responseBody, completionData.responseMetadata, completionData.responseError);
        }];
      } else {
        handler(completionData.responseBody, completionData.responseMetadata, completionData.responseError);
      }
      [sessionData.progressData removeObjectForKey:taskId];
      [sessionData.completionData removeObjectForKey:taskId];
      [sessionData.uploadHandlers removeObjectForKey:taskId];
      [sessionData.progressHandlers removeObjectForKey:taskId];
      [sessionData.responseHandlerQueues removeObjectForKey:taskId];
      [sessionData.progressHandlerQueues removeObjectForKey:taskId];
    } else {
      sessionData.uploadHandlers[taskId] = handler;
      if (handlerQueue) {
        sessionData.responseHandlerQueues[taskId] = handlerQueue;
      }
    }
  }];
}

#pragma mark - Add Download-style handler

- (void)addDownloadResponseHandler:(NSURLSessionTask *)task
                           session:(NSURLSession *)session
                   responseHandler:(void (^)(NSURL *, NSURLResponse *, NSError *))handler
              responseHandlerQueue:(NSOperationQueue *)handlerQueue {
  NSNumber *taskId = @(task.taskIdentifier);
  DBSessionData *sessionData = [self sessionDataWithSession:session];

  [_delegateQueue addOperationWithBlock:^{
    DBCompletionData *completionData = sessionData.completionData[taskId];
    if (completionData) {
      NSOperationQueue *handlerQueue = sessionData.responseHandlerQueues[taskId];
      if (handlerQueue) {
        [handlerQueue addOperationWithBlock:^{
          handler(completionData.urlOutput, completionData.responseMetadata, completionData.responseError);
        }];
      } else {
        handler(completionData.urlOutput, completionData.responseMetadata, completionData.responseError);
      }
      [sessionData.progressData removeObjectForKey:taskId];
      [sessionData.completionData removeObjectForKey:taskId];
      [sessionData.downloadHandlers removeObjectForKey:taskId];
      [sessionData.progressHandlers removeObjectForKey:taskId];
      [sessionData.responseHandlerQueues removeObjectForKey:taskId];
      [sessionData.progressHandlerQueues removeObjectForKey:taskId];
    } else {
      sessionData.downloadHandlers[taskId] = handler;
      if (handlerQueue) {
        sessionData.responseHandlerQueues[taskId] = handlerQueue;
      }
    }
  }];
}

- (NSString *)sessionIdWithSession:(NSURLSession *)session {
  return session.configuration.identifier ?: kForegroundId;
}

- (DBSessionData *)sessionDataWithSession:(NSURLSession *)session {
  NSString *sessionId = [self sessionIdWithSession:session];
  if (!_sessionData[sessionId]) {
    _sessionData[sessionId] = [[DBSessionData alloc] initWithSessionId:sessionId];
  }
  return _sessionData[sessionId];
}

@end
