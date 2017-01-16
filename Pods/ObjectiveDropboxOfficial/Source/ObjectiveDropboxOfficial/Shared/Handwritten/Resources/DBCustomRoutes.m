///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

#import "DBASYNCLaunchEmptyResult.h"
#import "DBChunkInputStream.h"
#import "DBCustomRoutes.h"
#import "DBFILESCommitInfo.h"
#import "DBFILESUploadSessionCursor.h"
#import "DBFILESUploadSessionFinishArg.h"
#import "DBFILESUploadSessionFinishBatchLaunch.h"
#import "DBFILESUploadSessionLookupError.h"
#import "DBFILESUploadSessionOffsetError.h"
#import "DBFILESUploadSessionStartResult.h"
#import "DBHandlerTypes.h"
#import "DBRequestErrors.h"
#import "DBTasksImpl.h"
#import "DBTasksStorage.h"

// 10 MB file chunk size
static const NSUInteger fileChunkSize = 10 * 1024 * 1024;
static const int timeoutInSec = 200;

@implementation DBBatchUploadData

- (instancetype)init:(NSDictionary<NSURL *, DBFILESCommitInfo *> *)fileUrlsToCommitInfo
       progressBlock:(DBProgressBlock)progressBlock
       responseBlock:(DBBatchUploadResponseBlock)responseBlock
               queue:(NSOperationQueue *)queue {
  self = [super init];
  if (self) {
    // we specifiy a custom queue so that the main thread is not blocked
    _queue = queue;
    [_queue setMaxConcurrentOperationCount:1];

    // we want to make sure all of our file data has been uploaded
    // before we make our final batch commit call to `/upload_session/finish_batch`,
    // but we also don't want to wait for each response before making a
    // succeeding upload call, so we used dispatch groups to wait for all upload
    // calls to return before making our final batch commit call
    _uploadGroup = dispatch_group_create();

    _fileUrlsToCommitInfo = fileUrlsToCommitInfo;
    _finishArgs = [NSMutableArray new];

    _progressBlock = progressBlock;
    _responseBlock = responseBlock;

    _taskStorage = [DBTasksStorage new];
  }
  return self;
}

@end

@interface DBBatchUploadTask ()

@property (nonatomic, readonly) DBBatchUploadData * _Nonnull uploadData;

@end

@implementation DBBatchUploadTask

- (instancetype)initWithUploadData:(DBBatchUploadData *)uploadData {
  self = [super init];
  if (self) {
    _uploadData = uploadData;
  }
  return self;
}

- (void)cancel {
  _uploadData.cancel = YES;
  [_uploadData.taskStorage cancelAllTasks];
}

@end

@implementation DBFILESRoutes (DBCustomRoutes)

- (DBBatchUploadTask *)batchUploadFiles:(NSDictionary<NSURL *, DBFILESCommitInfo *> *)fileUrlsToCommitInfo
                                  queue:(NSOperationQueue *)queue
                          progressBlock:(DBProgressBlock)progressBlock
                          responseBlock:(DBBatchUploadResponseBlock)responseBlock {
  DBBatchUploadData *uploadData = [[DBBatchUploadData alloc] init:fileUrlsToCommitInfo
                                                    progressBlock:progressBlock
                                                    responseBlock:responseBlock
                                                            queue:queue ?: [NSOperationQueue mainQueue]];
  DBBatchUploadTask *uploadTask = [[DBBatchUploadTask alloc] initWithUploadData:uploadData];

  NSArray<NSURL *> *fileUrls = [fileUrlsToCommitInfo allKeys];
  NSMutableDictionary<NSURL *, NSNumber *> *fileUrlsToFileSize = [NSMutableDictionary new];

  NSUInteger totalUploadSize = 0;

  // determine total upload size for progress handler
  for (NSURL *fileUrl in fileUrls) {
    NSNumber *fileSizeObj;
    NSError *fileSizeError;
    [fileUrl getResourceValue:&fileSizeObj forKey:NSURLFileSizeKey error:&fileSizeError];

    if (fileSizeError) {
      [uploadData.queue addOperationWithBlock:^{
        uploadData.responseBlock(nil, nil, [[DBRequestError alloc] initAsClientError:fileSizeError]);
      }];
      return uploadTask;
    }
    NSUInteger fileSize = [fileSizeObj unsignedIntegerValue];

    totalUploadSize += fileSize;
    fileUrlsToFileSize[fileUrl] = @(fileSize);
  }

  uploadData.totalUploadSize = totalUploadSize;

  for (NSURL *fileUrl in fileUrls) {
    NSUInteger fileSize = [fileUrlsToFileSize[fileUrl] unsignedIntegerValue];

    if (!uploadData.cancel) {
      if (fileSize < fileChunkSize) {
        // file is small, so we won't chunk upload it.
        [self startUploadSmallFile:uploadData fileUrl:fileUrl fileSize:fileSize];
      } else {
        // file is somewhat large, so we will chunk upload it, repeatedly querying
        // `/upload_session/append_v2` until the file is uploaded
        [self startUploadLargeFile:uploadData fileUrl:fileUrl fileSize:fileSize];
      }
    } else {
      break;
    }
  }

  // small or large, we query `upload_session/finish_batch` to batch commit
  // uploaded files.
  [self batchFinishUponCompletion:uploadData];

  return uploadTask;
}

- (void)startUploadSmallFile:(DBBatchUploadData *)uploadData fileUrl:(NSURL *)fileUrl fileSize:(NSUInteger)fileSize {
  dispatch_group_enter(uploadData.uploadGroup);

  // immediately close session after first API call
  // because file can be uploaded in one request
  __block DBUploadTask *task = [[self uploadSessionStartUrl:@(YES) inputUrl:fileUrl]
      response:uploadData.queue
      response:^(DBFILESUploadSessionStartResult *result, DBNilObject *routeError, DBRequestError *error) {
        if (result && !routeError) {
          NSString *sessionId = result.sessionId;
          NSNumber *offset = @(fileSize);
          DBFILESUploadSessionCursor *cursor =
              [[DBFILESUploadSessionCursor alloc] initWithSessionId:sessionId offset:offset];
          DBFILESCommitInfo *commitInfo = uploadData.fileUrlsToCommitInfo[fileUrl];
          DBFILESUploadSessionFinishArg *finishArg =
              [[DBFILESUploadSessionFinishArg alloc] initWithCursor:cursor commit:commitInfo];

          // store commit info for this file
          [uploadData.finishArgs addObject:finishArg];

          [self executeProgressHandler:uploadData startBytes:0 endBytes:fileSize];
        } else {
          [uploadData.queue addOperationWithBlock:^{
            uploadData.responseBlock(nil, nil, error);
          }];
        }

        [uploadData.taskStorage removeUploadTask:task];
        dispatch_group_leave(uploadData.uploadGroup);
      }];

  [uploadData.taskStorage addUploadTask:task];
}

- (void)startUploadLargeFile:(DBBatchUploadData *)uploadData fileUrl:(NSURL *)fileUrl fileSize:(NSUInteger)fileSize {
  dispatch_group_enter(uploadData.uploadGroup);

  NSUInteger startBytes = 0;
  NSUInteger endBytes = fileChunkSize;
  DBChunkInputStream *fileChunkInputStream =
      [[DBChunkInputStream alloc] initWithFileUrl:fileUrl startBytes:startBytes endBytes:endBytes];

  // use seperate continue upload queue so we don't block other files from
  // commencing their upload
  NSOperationQueue *chunkUploadContinueQueue = [NSOperationQueue new];

  // do not immediately close session
  __block DBUploadTask *task = [[self uploadSessionStartStream:fileChunkInputStream]
      response:chunkUploadContinueQueue
      response:^(DBFILESUploadSessionStartResult *result, DBNilObject *routeError, DBRequestError *error) {
        if (result && !routeError) {
          [self executeProgressHandler:uploadData startBytes:startBytes endBytes:endBytes];

          NSString *sessionId = result.sessionId;
          [self appendRemainingFileChunks:uploadData fileUrl:fileUrl fileSize:fileSize sessionId:sessionId];

          DBFILESUploadSessionCursor *cursor =
              [[DBFILESUploadSessionCursor alloc] initWithSessionId:sessionId offset:@(fileSize)];
          DBFILESCommitInfo *commitInfo = uploadData.fileUrlsToCommitInfo[fileUrl];
          DBFILESUploadSessionFinishArg *finishArg =
              [[DBFILESUploadSessionFinishArg alloc] initWithCursor:cursor commit:commitInfo];

          // Store commit info for this file
          [uploadData.finishArgs addObject:finishArg];
        } else {
          [uploadData.queue addOperationWithBlock:^{
            uploadData.responseBlock(nil, nil, error);
          }];
        }

        [uploadData.taskStorage removeUploadTask:task];
      }];

  [uploadData.taskStorage addUploadTask:task];
}

- (void)appendRemainingFileChunks:(DBBatchUploadData *)uploadData
                          fileUrl:(NSURL *)fileUrl
                         fileSize:(NSUInteger)fileSize
                        sessionId:(NSString *)sessionId {
  // use seperate response queue so we don't block response thread
  // with dispatch_semaphore_t
  NSOperationQueue *chunkUploadResponseQueue = [NSOperationQueue new];

  [chunkUploadResponseQueue addOperationWithBlock:^{
    NSUInteger numFileChunks = fileSize / fileChunkSize + 1;
    NSUInteger totalBytesSent = 0;

    dispatch_semaphore_t chunkUploadFinished = dispatch_semaphore_create(0);

    // iterate through all remaining chunks and upload each one sequentially
    for (NSUInteger i = 1; i < numFileChunks; i++) {
      NSUInteger startBytes = fileChunkSize * i;
      NSUInteger endBytes = (i != numFileChunks - 1) ? fileChunkSize * (i + 1) : fileSize;
      DBChunkInputStream *fileChunkInputStream =
          [[DBChunkInputStream alloc] initWithFileUrl:fileUrl startBytes:startBytes endBytes:endBytes];

      totalBytesSent += fileChunkSize;

      DBFILESUploadSessionCursor *cursor =
          [[DBFILESUploadSessionCursor alloc] initWithSessionId:sessionId offset:@(totalBytesSent)];

      BOOL shouldClose = (i != numFileChunks - 1) ? NO : YES;

      [self appendFileChunk:uploadData
                            cursor:cursor
                       shouldClose:shouldClose
              fileChunkInputStream:fileChunkInputStream
          chunkUploadResponseQueue:chunkUploadResponseQueue
               chunkUploadFinished:&chunkUploadFinished
                        retryCount:0];

      // wait until each chunk upload completes before resuming loop iteration
      dispatch_semaphore_wait(chunkUploadFinished, DISPATCH_TIME_FOREVER);

      [self executeProgressHandler:uploadData startBytes:startBytes endBytes:endBytes];
    }
    dispatch_group_leave(uploadData.uploadGroup);
  }];
}

- (void)appendFileChunk:(DBBatchUploadData *)uploadData
                      cursor:(DBFILESUploadSessionCursor *)cursor
                 shouldClose:(BOOL)shouldClose
        fileChunkInputStream:(NSInputStream *)fileChunkInputStream
    chunkUploadResponseQueue:(NSOperationQueue *)chunkUploadResponseQueue
         chunkUploadFinished:(dispatch_semaphore_t *)chunkUploadFinished
                  retryCount:(int)retryCount {
  // close session on final append call
  __block DBUploadTask *task = [
      [self uploadSessionAppendV2Stream:cursor close:@(shouldClose) inputStream:fileChunkInputStream]
      response:chunkUploadResponseQueue
      response:^(DBNilObject *result, DBFILESUploadSessionLookupError *routeError, DBRequestError *error) {
        if (error && !result) {
          if (!routeError) {
            if ([error isRateLimitError]) {
              DBRequestRateLimitError *rateLimitError = [error asRateLimitError];
              double backoffInSeconds = [rateLimitError.backoff doubleValue];
              dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(backoffInSeconds * NSEC_PER_SEC));

              // retry after backoff time
              dispatch_after(delayTime, dispatch_get_main_queue(), ^(void) {
                if (retryCount <= 3) {
                  [self appendFileChunk:uploadData
                                        cursor:cursor
                                   shouldClose:shouldClose
                          fileChunkInputStream:fileChunkInputStream
                      chunkUploadResponseQueue:chunkUploadResponseQueue
                           chunkUploadFinished:chunkUploadFinished
                                    retryCount:retryCount + 1];
                } else {
                  [uploadData.queue addOperationWithBlock:^{
                    uploadData.responseBlock(nil, nil, error);
                  }];
                }
              });
            } else {
              [uploadData.queue addOperationWithBlock:^{
                uploadData.responseBlock(nil, nil, error);
              }];
            }
          } else {
            // if we error here, there's almost certainly a bug with the SDK
            [uploadData.queue addOperationWithBlock:^{
              uploadData.responseBlock(nil, nil, error);
            }];
          }
        }
        [uploadData.taskStorage removeUploadTask:task];
        dispatch_semaphore_signal(*chunkUploadFinished);
      }];

  [uploadData.taskStorage addUploadTask:task];
}

- (void)queryJobStatus:(DBBatchUploadData *)uploadData asyncJobId:(NSString *)asyncJobId retryCount:(int)retryCount {
  [[self uploadSessionFinishBatchCheck:asyncJobId] response:^(DBFILESUploadSessionFinishBatchJobStatus *result,
                                                              DBASYNCPollError *routeError, DBRequestError *error) {
    if (result) {
      if ([result isInProgress]) {
        sleep(1);
        if (retryCount <= timeoutInSec) {
          [self queryJobStatus:uploadData asyncJobId:asyncJobId retryCount:retryCount + 1];
        } else {
          NSString *errorMessage =
              [NSString stringWithFormat:@"Result polling took > %d seconds. Timing out.", timeoutInSec];
          NSMutableDictionary *userInfo = [NSMutableDictionary new];
          userInfo[NSUnderlyingErrorKey] = errorMessage;
          NSError *timeoutError =
              [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:userInfo];
          [uploadData.queue addOperationWithBlock:^{
            uploadData.responseBlock(nil, nil, [[DBRequestError alloc] initAsClientError:timeoutError]);
          }];
        }
      } else if ([result isComplete]) {
        [uploadData.queue addOperationWithBlock:^{
          uploadData.responseBlock(result, nil, nil);
        }];
      }
    } else if (error) {
      if (!routeError) {
        if ([error isRateLimitError]) {
          DBRequestRateLimitError *rateLimitError = [error asRateLimitError];
          double backoffInSeconds = [rateLimitError.backoff doubleValue];
          dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(backoffInSeconds * NSEC_PER_SEC));

          // retry after backoff time
          dispatch_after(delayTime, dispatch_get_main_queue(), ^(void) {
            [self queryJobStatus:uploadData asyncJobId:asyncJobId retryCount:retryCount];
          });
        } else {
          [uploadData.queue addOperationWithBlock:^{
            uploadData.responseBlock(nil, nil, error);
          }];
        }
      } else {
        [uploadData.queue addOperationWithBlock:^{
          uploadData.responseBlock(nil, routeError, error);
        }];
      }
    }
  }];
}

- (void)batchFinishUponCompletion:(DBBatchUploadData *)uploadData {
  // wait for all upload calls to complete and then batch "finish" all uploaded files
  // with one call to `upload_session/finish_batch`
  dispatch_group_notify(uploadData.uploadGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    [[self uploadSessionFinishBatch:uploadData.finishArgs]
        response:^(DBFILESUploadSessionFinishBatchLaunch *result, DBNilObject *routeError, DBRequestError *error) {
          if (result && !routeError) {
            if ([result isAsyncJobId]) {
              sleep(1);
              [self queryJobStatus:uploadData asyncJobId:result.asyncJobId retryCount:2];
            }
          } else {
            [uploadData.queue addOperationWithBlock:^{
              uploadData.responseBlock(nil, nil, error);
            }];
          }
        }];
  });
}

- (void)executeProgressHandler:(DBBatchUploadData *)uploadData
                    startBytes:(NSUInteger)startBytes
                      endBytes:(NSUInteger)endBytes {
  if (!uploadData.progressBlock) {
    return;
  }
  NSUInteger amountUploaded = endBytes - startBytes;
  uploadData.totalUploadedSoFar += amountUploaded;
  [uploadData.queue addOperationWithBlock:^{
    uploadData.progressBlock(amountUploaded, uploadData.totalUploadedSoFar, uploadData.totalUploadSize);
  }];
}

- (NSFileHandle *)fileHandle:(DBBatchUploadData *)uploadData fileUrl:(NSURL *)fileUrl {
  NSError *fileHandleError;
  NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingFromURL:fileUrl error:&fileHandleError];

  if (fileHandleError) {
    [uploadData.queue addOperationWithBlock:^{
      uploadData.responseBlock(nil, nil, [[DBRequestError alloc] initAsClientError:fileHandleError]);
    }];
    return nil;
  }

  return fileHandle;
}

@end
