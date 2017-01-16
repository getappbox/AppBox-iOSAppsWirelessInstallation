///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBDelegate.h"
#import "DBHandlerTypes.h"
#import "DBRequestErrors.h"
#import "DBStoneBase.h"
#import "DBTasksImpl.h"
#import "DBTransportClientBase.h"

#pragma mark - RPC-style network task

@implementation DBRpcTaskImpl

- (instancetype)initWithTask:(NSURLSessionDataTask *)task
                     session:(NSURLSession *)session
                    delegate:(DBDelegate *)delegate
                       route:(DBRoute *)route {
  self = [super initWithRoute:route];
  if (self) {
    _task = task;
    _session = session;
    _delegate = delegate;
  }
  return self;
}

- (DBRpcTask *)response:(void (^)(id, id, DBRequestError *))responseBlock {
  return [self response:nil response:responseBlock];
}

- (DBRpcTask *)response:(NSOperationQueue *)queue response:(void (^)(id, id, DBRequestError *))responseBlock {
  DBRpcResponseBlock wrapperBlock = ^(NSData *data, NSURLResponse *response, NSError *clientError) {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    int statusCode = (int)httpResponse.statusCode;
    NSDictionary *httpHeaders = httpResponse.allHeaderFields;
    
    DBRequestError *dbxError = [DBTransportClientBase dBRequestErrorWithErrorData:data
                                                                      clientError:clientError
                                                                       statusCode:statusCode
                                                                      httpHeaders:httpHeaders];
    if (dbxError) {
      id routeError = [DBTransportClientBase statusCodeIsRouteError:statusCode]
      ? [DBTransportClientBase routeErrorWithRouteData:_route data:data statusCode:statusCode]
      : nil;
      return responseBlock(nil, routeError, dbxError);
    }
    
    NSError *serializationError;
    id result =
    [DBTransportClientBase routeResultWithRouteData:_route data:data serializationError:&serializationError];
    if (serializationError) {
      responseBlock(nil, nil, [[DBRequestError alloc] initAsClientError:serializationError]);
      return;
    }
    result = !_route.resultType ? [DBNilObject new] : result;
    responseBlock(result, nil, nil);
  };
  
  [_delegate addRpcResponseHandler:_task session:_session responseHandler:wrapperBlock responseHandlerQueue:queue];
  
  return self;
}

- (DBRpcTask *)progress:(DBProgressBlock)progressBlock {
  return [self progress:nil progress:progressBlock];
}

- (DBRpcTask *)progress:(NSOperationQueue *)queue progress:(DBProgressBlock)progressBlock {
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
  self = [super initWithRoute:route];
  if (self) {
    _task = task;
    _session = session;
    _delegate = delegate;
  }
  return self;
}

- (DBUploadTask *)response:(void (^)(id, id, DBRequestError *))responseBlock {
  return [self response:nil response:responseBlock];
}

- (DBUploadTask *)response:(NSOperationQueue *)queue response:(void (^)(id, id, DBRequestError *))responseBlock {
  DBUploadResponseBlock wrapperBlock = ^(NSData *data, NSURLResponse *response, NSError *clientError) {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    int statusCode = (int)httpResponse.statusCode;
    NSDictionary *httpHeaders = httpResponse.allHeaderFields;
    
    DBRequestError *dbxError = [DBTransportClientBase dBRequestErrorWithErrorData:data
                                                                      clientError:clientError
                                                                       statusCode:statusCode
                                                                      httpHeaders:httpHeaders];
    if (dbxError) {
      id routeError = [DBTransportClientBase statusCodeIsRouteError:statusCode]
      ? [DBTransportClientBase routeErrorWithRouteData:_route data:data statusCode:statusCode]
      : nil;
      return responseBlock(nil, routeError, dbxError);
    }
    
    NSError *serializationError;
    id result =
    [DBTransportClientBase routeResultWithRouteData:_route data:data serializationError:&serializationError];
    if (serializationError) {
      responseBlock(nil, nil, [[DBRequestError alloc] initAsClientError:serializationError]);
      return;
    }
    result = !_route.resultType ? [DBNilObject new] : result;
    responseBlock(result, nil, nil);
  };
  
  [_delegate addUploadResponseHandler:_task session:_session responseHandler:wrapperBlock responseHandlerQueue:queue];
  
  return self;
}

- (DBUploadTask *)progress:(DBProgressBlock)progressBlock {
  return [self progress:nil progress:progressBlock];
}

- (DBUploadTask *)progress:(NSOperationQueue *)queue progress:(DBProgressBlock)progressBlock {
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
  self = [super initWithRoute:route];
  if (self) {
    _task = task;
    _session = session;
    _delegate = delegate;
    _overwrite = overwrite;
    _destination = destination;
  }
  return self;
}

- (DBDownloadUrlTask *)response:(void (^)(id, id, DBRequestError *dbxError, NSURL *))responseBlock {
  return [self response:nil response:responseBlock];
}

- (DBDownloadUrlTask *)response:(NSOperationQueue *)queue
                       response:(void (^)(id, id, DBRequestError *dbxError, NSURL *))responseBlock {
  DBDownloadResponseBlock wrapperBlock = ^(NSURL *location, NSURLResponse *response, NSError *clientError) {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    int statusCode = (int)httpResponse.statusCode;
    NSDictionary *httpHeaders = httpResponse.allHeaderFields;
    NSString *headerString = [DBTransportClientBase caseInsensitiveLookup:@"Dropbox-API-Result" dictionary:httpHeaders];
    NSData *resultData = headerString ? [headerString dataUsingEncoding:NSUTF8StringEncoding] : nil;
    
    if (clientError || !resultData) {
      // error data is in response body (downloaded to output tmp file)
      NSData *errorData = location ? [NSData dataWithContentsOfFile:[location path]] : nil;
      DBRequestError *dbxError = [DBTransportClientBase dBRequestErrorWithErrorData:errorData
                                                                        clientError:clientError
                                                                         statusCode:statusCode
                                                                        httpHeaders:httpHeaders];
      id routeError = [DBTransportClientBase statusCodeIsRouteError:statusCode]
      ? [DBTransportClientBase routeErrorWithRouteData:_route data:errorData statusCode:statusCode]
      : nil;
      return responseBlock(nil, routeError, dbxError, _destination);
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *destinationPath = [_destination path];
    
    if ([fileManager fileExistsAtPath:destinationPath]) {
      NSError *fileMoveError;
      if (_overwrite) {
        [fileManager removeItemAtPath:destinationPath error:&fileMoveError];
        if (fileMoveError) {
          responseBlock(nil, nil, [[DBRequestError alloc] initAsClientError:fileMoveError], _destination);
          return;
        }
      }
      [fileManager moveItemAtPath:[location path] toPath:destinationPath error:&fileMoveError];
      if (fileMoveError) {
        responseBlock(nil, nil, [[DBRequestError alloc] initAsClientError:fileMoveError], _destination);
        return;
      }
    } else {
      NSError *fileMoveError;
      [fileManager moveItemAtPath:[location path] toPath:destinationPath error:&fileMoveError];
      if (fileMoveError) {
        responseBlock(nil, nil, [[DBRequestError alloc] initAsClientError:fileMoveError], _destination);
        return;
      }
    }
    
    NSError *serializationError;
    id result =
    [DBTransportClientBase routeResultWithRouteData:_route data:resultData serializationError:&serializationError];
    if (serializationError) {
      responseBlock(nil, nil, [[DBRequestError alloc] initAsClientError:serializationError], _destination);
      return;
    }
    result = !_route.resultType ? [DBNilObject new] : result;
    responseBlock(result, nil, nil, _destination);
  };
  
  [_delegate addDownloadResponseHandler:_task session:_session responseHandler:wrapperBlock responseHandlerQueue:queue];
  
  return self;
}

- (DBDownloadUrlTask *)progress:(DBProgressBlock)progressBlock {
  return [self progress:nil progress:progressBlock];
}

- (DBDownloadUrlTask *)progress:(NSOperationQueue *)queue progress:(DBProgressBlock)progressBlock {
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
  self = [super initWithRoute:route];
  if (self) {
    _task = task;
    _session = session;
    _delegate = delegate;
  }
  return self;
}

- (DBDownloadDataTask *)response:(void (^)(id, id, DBRequestError *dbxError, NSData *))responseBlock {
  return [self response:nil response:responseBlock];
}

- (DBDownloadDataTask *)response:(NSOperationQueue *)queue
                        response:(void (^)(id, id, DBRequestError *dbxError, NSData *))responseBlock {
  DBDownloadResponseBlock wrapperBlock = ^(NSURL *location, NSURLResponse *response, NSError *clientError) {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    int statusCode = (int)httpResponse.statusCode;
    NSDictionary *httpHeaders = httpResponse.allHeaderFields;
    NSString *headerString = [DBTransportClientBase caseInsensitiveLookup:@"Dropbox-API-Result" dictionary:httpHeaders];
    NSData *resultData = headerString ? [headerString dataUsingEncoding:NSUTF8StringEncoding] : nil;
    
    if (clientError || !resultData) {
      // error data is in response body (downloaded to output tmp file)
      NSData *errorData = location ? [NSData dataWithContentsOfFile:[location path]] : nil;
      DBRequestError *dbxError = [DBTransportClientBase dBRequestErrorWithErrorData:errorData
                                                                        clientError:clientError
                                                                         statusCode:statusCode
                                                                        httpHeaders:httpHeaders];
      id routeError = [DBTransportClientBase statusCodeIsRouteError:statusCode]
      ? [DBTransportClientBase routeErrorWithRouteData:_route data:errorData statusCode:statusCode]
      : nil;
      return responseBlock(nil, routeError, dbxError, nil);
    }
    
    NSError *serializationError;
    id result =
    [DBTransportClientBase routeResultWithRouteData:_route data:resultData serializationError:&serializationError];
    if (serializationError) {
      responseBlock(nil, nil, [[DBRequestError alloc] initAsClientError:serializationError], nil);
      return;
    }
    result = !_route.resultType ? [DBNilObject new] : result;
    responseBlock(result, nil, nil, [NSData dataWithContentsOfFile:[location path]]);
  };
  
  [_delegate addDownloadResponseHandler:_task session:_session responseHandler:wrapperBlock responseHandlerQueue:queue];
  
  return self;
}

- (DBDownloadDataTask *)progress:(DBProgressBlock)progressBlock {
  return [self progress:nil progress:progressBlock];
}

- (DBDownloadDataTask *)progress:(NSOperationQueue *)queue progress:(DBProgressBlock)progressBlock {
  [_delegate addProgressHandler:_task session:_session progressHandler:progressBlock progressHandlerQueue:queue];
  return self;
}

@end
