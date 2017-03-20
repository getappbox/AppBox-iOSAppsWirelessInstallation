///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBDelegate.h"
#import "DBHandlerTypes.h"
#import "DBRequestErrors.h"
#import "DBStoneBase.h"
#import "DBTasks.h"
#import "DBTransportBaseClient+Internal.h"
#import "DBTransportBaseClient.h"

#pragma mark - Base network task

@implementation DBTask : NSObject

- (instancetype)initWithRoute:(DBRoute *)route task:(NSURLSessionTask *)task {
  self = [super init];
  if (self) {
    _task = task;
    _route = route;
  }
  return self;
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

@end

#pragma mark - RPC-style network task

@implementation DBRpcTask

- (DBRpcTask *)setResponseBlock:(DBRpcResponseBlockImpl)responseBlock {
#pragma unused(responseBlock)
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (DBRpcTask *)setResponseBlock:(DBRpcResponseBlockImpl)responseBlock queue:(NSOperationQueue *)queue {
#pragma unused(responseBlock)
#pragma unused(queue)
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (DBRpcTask *)setProgressBlock:(DBProgressBlock)progressBlock {
#pragma unused(progressBlock)
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (DBRpcTask *)setProgressBlock:(DBProgressBlock)progressBlock queue:(NSOperationQueue *)queue {
#pragma unused(progressBlock)
#pragma unused(queue)
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (DBRpcResponseBlockStorage)storageBlockWithResponseBlock:(DBRpcResponseBlockImpl)responseBlock {
  DBRpcResponseBlockStorage storageBlock = ^BOOL(NSData *data, NSURLResponse *response, NSError *clientError) {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    int statusCode = (int)httpResponse.statusCode;
    NSDictionary *httpHeaders = httpResponse.allHeaderFields;

    DBRequestError *dbxError = [DBTransportBaseClient dBRequestErrorWithErrorData:data
                                                                      clientError:clientError
                                                                       statusCode:statusCode
                                                                      httpHeaders:httpHeaders];
    if (dbxError) {
      id routeError = [DBTransportBaseClient statusCodeIsRouteError:statusCode]
                          ? [DBTransportBaseClient routeErrorWithRoute:_route data:data statusCode:statusCode]
                          : nil;
      responseBlock(nil, routeError, dbxError);
      return NO;
    }

    NSError *serializationError;
    id result = [DBTransportBaseClient routeResultWithRoute:_route data:data serializationError:&serializationError];
    if (serializationError) {
      responseBlock(nil, nil, [[DBRequestError alloc] initAsClientError:serializationError]);
      return NO;
    }
    result = !_route.resultType ? [DBNilObject new] : result;
    responseBlock(result, nil, nil);

    return YES;
  };

  return storageBlock;
}

@end

#pragma mark - Upload-style network task

@implementation DBUploadTask

- (DBUploadTask *)setResponseBlock:(DBUploadResponseBlockImpl)responseBlock {
#pragma unused(responseBlock)
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (DBUploadTask *)setResponseBlock:(DBUploadResponseBlockImpl)responseBlock queue:(NSOperationQueue *)queue {
#pragma unused(responseBlock)
#pragma unused(queue)
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (DBUploadTask *)setProgressBlock:(DBProgressBlock)progressBlock {
#pragma unused(progressBlock)
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (DBUploadTask *)setProgressBlock:(DBProgressBlock)progressBlock queue:(NSOperationQueue *)queue {
#pragma unused(progressBlock)
#pragma unused(queue)
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (DBUploadResponseBlockStorage)storageBlockWithResponseBlock:(DBUploadResponseBlockImpl)responseBlock {
  DBUploadResponseBlockStorage storageBlock = ^BOOL(NSData *data, NSURLResponse *response, NSError *clientError) {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    int statusCode = (int)httpResponse.statusCode;
    NSDictionary *httpHeaders = httpResponse.allHeaderFields;

    DBRequestError *dbxError = [DBTransportBaseClient dBRequestErrorWithErrorData:data
                                                                      clientError:clientError
                                                                       statusCode:statusCode
                                                                      httpHeaders:httpHeaders];
    if (dbxError) {
      id routeError = [DBTransportBaseClient statusCodeIsRouteError:statusCode]
                          ? [DBTransportBaseClient routeErrorWithRoute:_route data:data statusCode:statusCode]
                          : nil;
      responseBlock(nil, routeError, dbxError);
      return NO;
    }

    NSError *serializationError;
    id result = [DBTransportBaseClient routeResultWithRoute:_route data:data serializationError:&serializationError];
    if (serializationError) {
      responseBlock(nil, nil, [[DBRequestError alloc] initAsClientError:serializationError]);
      return NO;
    }
    result = !_route.resultType ? [DBNilObject new] : result;
    responseBlock(result, nil, nil);

    return YES;
  };

  return storageBlock;
}

@end

#pragma mark - Download-style network task (NSURL)

@implementation DBDownloadUrlTask

- (DBDownloadUrlTask *)setResponseBlock:(DBDownloadUrlResponseBlockImpl)responseBlock {
#pragma unused(responseBlock)
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (DBDownloadUrlTask *)setResponseBlock:(DBDownloadUrlResponseBlockImpl)responseBlock queue:(NSOperationQueue *)queue {
#pragma unused(responseBlock)
#pragma unused(queue)
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (DBDownloadUrlTask *)setProgressBlock:(DBProgressBlock)progressBlock {
#pragma unused(progressBlock)
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (DBDownloadUrlTask *)setProgressBlock:(DBProgressBlock)progressBlock queue:(NSOperationQueue *)queue {
#pragma unused(progressBlock)
#pragma unused(queue)
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (DBDownloadResponseBlockStorage)storageBlockWithResponseBlock:(DBDownloadUrlResponseBlockImpl)responseBlock {
  DBDownloadResponseBlockStorage storageBlock = ^BOOL(NSURL *location, NSURLResponse *response, NSError *clientError) {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    int statusCode = (int)httpResponse.statusCode;
    NSDictionary *httpHeaders = httpResponse.allHeaderFields;
    NSString *headerString =
        [DBTransportBaseClient caseInsensitiveLookupWithKey:@"Dropbox-API-Result" dictionary:httpHeaders];
    NSData *resultData = headerString ? [headerString dataUsingEncoding:NSUTF8StringEncoding] : nil;

    if (clientError || !resultData) {
      // error data is in response body (downloaded to output tmp file)
      NSData *errorData = location ? [NSData dataWithContentsOfFile:[location path]] : nil;
      DBRequestError *dbxError = [DBTransportBaseClient dBRequestErrorWithErrorData:errorData
                                                                        clientError:clientError
                                                                         statusCode:statusCode
                                                                        httpHeaders:httpHeaders];
      id routeError = [DBTransportBaseClient statusCodeIsRouteError:statusCode]
                          ? [DBTransportBaseClient routeErrorWithRoute:_route data:errorData statusCode:statusCode]
                          : nil;
      responseBlock(nil, routeError, dbxError, _destination);
      return NO;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *destinationPath = [_destination path];

    if ([fileManager fileExistsAtPath:destinationPath]) {
      NSError *fileMoveError;
      if (_overwrite) {
        [fileManager removeItemAtPath:destinationPath error:&fileMoveError];
        if (fileMoveError) {
          responseBlock(nil, nil, [[DBRequestError alloc] initAsClientError:fileMoveError], _destination);
          return NO;
        }
      }
      [fileManager moveItemAtPath:[location path] toPath:destinationPath error:&fileMoveError];
      if (fileMoveError) {
        responseBlock(nil, nil, [[DBRequestError alloc] initAsClientError:fileMoveError], _destination);
        return NO;
      }
    } else {
      NSError *fileMoveError;
      [fileManager moveItemAtPath:[location path] toPath:destinationPath error:&fileMoveError];
      if (fileMoveError) {
        responseBlock(nil, nil, [[DBRequestError alloc] initAsClientError:fileMoveError], _destination);
        return NO;
      }
    }

    NSError *serializationError;
    id result =
        [DBTransportBaseClient routeResultWithRoute:_route data:resultData serializationError:&serializationError];
    if (serializationError) {
      responseBlock(nil, nil, [[DBRequestError alloc] initAsClientError:serializationError], _destination);
      return NO;
    }
    result = !_route.resultType ? [DBNilObject new] : result;
    responseBlock(result, nil, nil, _destination);

    return YES;
  };

  return storageBlock;
}

@end

#pragma mark - Download-style network task (NSData)

@implementation DBDownloadDataTask

- (DBDownloadDataTask *)setResponseBlock:(DBDownloadDataResponseBlockImpl)responseBlock {
#pragma unused(responseBlock)
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (DBDownloadDataTask *)setResponseBlock:(DBDownloadDataResponseBlockImpl)responseBlock
                                   queue:(NSOperationQueue *)queue {
#pragma unused(responseBlock)
#pragma unused(queue)
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (DBDownloadDataTask *)setProgressBlock:(DBProgressBlock)progressBlock {
#pragma unused(progressBlock)
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (DBDownloadDataTask *)setProgressBlock:(DBProgressBlock)progressBlock queue:(NSOperationQueue *)queue {
#pragma unused(progressBlock)
#pragma unused(queue)
  @throw [NSException
      exceptionWithName:NSInternalInconsistencyException
                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
               userInfo:nil];
}

- (DBDownloadResponseBlockStorage)storageBlockWithResponseBlock:(DBDownloadDataResponseBlockImpl)responseBlock {
  DBDownloadResponseBlockStorage storageBlock = ^BOOL(NSURL *location, NSURLResponse *response, NSError *clientError) {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    int statusCode = (int)httpResponse.statusCode;
    NSDictionary *httpHeaders = httpResponse.allHeaderFields;
    NSString *headerString =
        [DBTransportBaseClient caseInsensitiveLookupWithKey:@"Dropbox-API-Result" dictionary:httpHeaders];
    NSData *resultData = headerString ? [headerString dataUsingEncoding:NSUTF8StringEncoding] : nil;

    if (clientError || !resultData) {
      // error data is in response body (downloaded to output tmp file)
      NSData *errorData = location ? [NSData dataWithContentsOfFile:[location path]] : nil;
      DBRequestError *dbxError = [DBTransportBaseClient dBRequestErrorWithErrorData:errorData
                                                                        clientError:clientError
                                                                         statusCode:statusCode
                                                                        httpHeaders:httpHeaders];
      id routeError = [DBTransportBaseClient statusCodeIsRouteError:statusCode]
                          ? [DBTransportBaseClient routeErrorWithRoute:_route data:errorData statusCode:statusCode]
                          : nil;
      responseBlock(nil, routeError, dbxError, nil);
      return NO;
    }

    NSError *serializationError;
    id result =
        [DBTransportBaseClient routeResultWithRoute:_route data:resultData serializationError:&serializationError];
    if (serializationError) {
      responseBlock(nil, nil, [[DBRequestError alloc] initAsClientError:serializationError], nil);
      return NO;
    }
    result = !_route.resultType ? [DBNilObject new] : result;
    responseBlock(result, nil, nil, [NSData dataWithContentsOfFile:[location path]]);
    return YES;
  };

  return storageBlock;
}

@end
