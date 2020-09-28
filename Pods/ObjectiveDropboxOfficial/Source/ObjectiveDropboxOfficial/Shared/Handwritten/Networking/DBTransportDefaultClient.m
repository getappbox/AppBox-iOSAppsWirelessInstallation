///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBTransportDefaultClient.h"

#import "DBAccessTokenProvider+Internal.h"
#import "DBDelegate.h"
#import "DBFILESRouteObjects.h"
#import "DBSDKConstants.h"
#import "DBStoneBase.h"
#import "DBTasksImpl.h"
#import "DBTransportBaseClient+Internal.h"
#import "DBTransportBaseHostnameConfig.h"
#import "DBTransportDefaultConfig.h"
#import "DBURLSessionTaskWithTokenRefresh.h"

@implementation DBTransportDefaultClient {
  /// The delegate used to manage execution of all response / error code. By default, this
  /// is an instance of `DBDelegate` with the main thread queue as delegate queue.
  DBDelegate *_delegate;
}

@synthesize session = _session;
@synthesize secondarySession = _secondarySession;
@synthesize longpollSession = _longpollSession;

#pragma mark - Constructors

- (instancetype)initWithAccessToken:(NSString *)accessToken
                           tokenUid:(NSString *)tokenUid
                    transportConfig:(DBTransportDefaultConfig *)transportConfig {
  return [self initWithAccessTokenProvider:[[DBLongLivedAccessTokenProvider alloc] initWithTokenString:accessToken]
                                  tokenUid:tokenUid
                           transportConfig:transportConfig];
}

- (instancetype)initWithAccessTokenProvider:(id<DBAccessTokenProvider>)accessTokenProvider
                                   tokenUid:(NSString *)tokenUid
                            transportConfig:(DBTransportDefaultConfig *)transportConfig {
  self = [super initWithAccessTokenProvider:accessTokenProvider tokenUid:tokenUid transportConfig:transportConfig];
  if (self) {
    _delegateQueue = transportConfig.delegateQueue ?: [NSOperationQueue new];
    _delegateQueue.maxConcurrentOperationCount = 1;
    _delegate = [[DBDelegate alloc] initWithQueue:_delegateQueue];

    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.timeoutIntervalForRequest = 60.0;

    NSOperationQueue *sessionDelegateQueue =
        [self urlSessionDelegateQueueWithName:[NSString stringWithFormat:@"%@ NSURLSession delegate queue",
                                                                         NSStringFromClass(self.class)]];
    _session =
        [NSURLSession sessionWithConfiguration:sessionConfig delegate:_delegate delegateQueue:sessionDelegateQueue];
    _forceForegroundSession = transportConfig.forceForegroundSession ? YES : NO;
    if (!_forceForegroundSession) {
      NSString *backgroundId =
          [NSString stringWithFormat:@"%@.%@", kDBSDKBackgroundSessionId, [NSUUID UUID].UUIDString];
      NSURLSessionConfiguration *backgroundSessionConfig =
          [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:backgroundId];
      if (transportConfig.sharedContainerIdentifier) {
        backgroundSessionConfig.sharedContainerIdentifier = transportConfig.sharedContainerIdentifier;
      }

      NSOperationQueue *secondarySessionDelegateQueue =
          [self urlSessionDelegateQueueWithName:[NSString stringWithFormat:@"%@ Secondary NSURLSession delegate queue",
                                                                           NSStringFromClass(self.class)]];
      _secondarySession = [NSURLSession sessionWithConfiguration:backgroundSessionConfig
                                                        delegate:_delegate
                                                   delegateQueue:secondarySessionDelegateQueue];
    } else {
      _secondarySession = _session;
    }

    NSURLSessionConfiguration *longpollSessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    longpollSessionConfig.timeoutIntervalForRequest = 480.0;

    NSOperationQueue *longpollSessionDelegateQueue =
        [self urlSessionDelegateQueueWithName:[NSString stringWithFormat:@"%@ Longpoll NSURLSession delegate queue",
                                                                         NSStringFromClass(self.class)]];
    _longpollSession = [NSURLSession sessionWithConfiguration:longpollSessionConfig
                                                     delegate:_delegate
                                                delegateQueue:longpollSessionDelegateQueue];
  }
  return self;
}

#pragma mark - Utility methods

- (NSOperationQueue *)urlSessionDelegateQueueWithName:(NSString *)queueName {
  NSOperationQueue *sessionDelegateQueue = [[NSOperationQueue alloc] init];
  sessionDelegateQueue.maxConcurrentOperationCount = 1; // [Michael Fey, 2017-05-16] From the NSURLSession
                                                        // documentation: "The queue should be a serial queue, in order
                                                        // to ensure the correct ordering of callbacks."
  sessionDelegateQueue.name = queueName;
  sessionDelegateQueue.qualityOfService = NSQualityOfServiceUtility;
  return sessionDelegateQueue;
}

#pragma mark - RPC-style request

- (DBRpcTaskImpl *)requestRpc:(DBRoute *)route arg:(id<DBSerializable>)arg {
  NSURLSession *sessionToUse = _session;
  // longpoll requests have a much longer timeout period than other requests
  if (route.host == DBRouteHostNotify) {
    sessionToUse = _longpollSession;
  }

  DBURLSessionTaskCreationBlock taskCreationBlock = ^{
    NSURL *requestUrl = [self urlWithRoute:route];
    NSString *serializedArg = [[self class] serializeStringWithRoute:route routeArg:arg];
    NSDictionary *headers = [self headersWithRouteInfo:route.attrs serializedArg:serializedArg];
    // RPC request submits argument in request body
    NSData *serializedArgData = [[self class] serializeDataWithRoute:route routeArg:arg];
    NSURLRequest *request =
        [[self class] requestWithHeaders:headers url:requestUrl content:serializedArgData stream:nil];
    return [sessionToUse dataTaskWithRequest:request];
  };

  id<DBURLSessionTask> taskWithTokenRefresh =
      [[DBURLSessionTaskWithTokenRefresh alloc] initWithTaskCreationBlock:taskCreationBlock
                                                             taskDelegate:_delegate
                                                               urlSession:sessionToUse
                                                            tokenProvider:self.accessTokenProvider];
  DBRpcTaskImpl *rpcTask = [[DBRpcTaskImpl alloc] initWithTask:taskWithTokenRefresh tokenUid:self.tokenUid route:route];
  [rpcTask resume];
  return rpcTask;
}

#pragma mark - Upload-style request (NSURL)

- (DBUploadTaskImpl *)requestUpload:(DBRoute *)route arg:(id<DBSerializable>)arg inputUrl:(NSString *)input {
  NSURLSession *sessionToUse = _secondarySession;
  DBURLSessionTaskCreationBlock taskCreationBlock = ^{
    NSURL *inputUrl = [NSURL fileURLWithPath:input];
    NSURL *requestUrl = [self urlWithRoute:route];
    NSString *serializedArg = [[self class] serializeStringWithRoute:route routeArg:arg];
    NSDictionary *headers = [self headersWithRouteInfo:route.attrs serializedArg:serializedArg];
    NSURLRequest *request = [[self class] requestWithHeaders:headers url:requestUrl content:nil stream:nil];
    return [sessionToUse uploadTaskWithRequest:request fromFile:inputUrl];
  };
  id<DBURLSessionTask> taskWithTokenRefresh =
      [[DBURLSessionTaskWithTokenRefresh alloc] initWithTaskCreationBlock:taskCreationBlock
                                                             taskDelegate:_delegate
                                                               urlSession:sessionToUse
                                                            tokenProvider:self.accessTokenProvider];

  DBUploadTaskImpl *uploadTask =
      [[DBUploadTaskImpl alloc] initWithTask:taskWithTokenRefresh tokenUid:self.tokenUid route:route];
  [uploadTask resume];
  return uploadTask;
}

#pragma mark - Upload-style request (NSData)

- (DBUploadTaskImpl *)requestUpload:(DBRoute *)route arg:(id<DBSerializable>)arg inputData:(NSData *)input {
  NSURLSession *sessionToUse = _session;
  DBURLSessionTaskCreationBlock taskCreationBlock = ^{
    NSURL *requestUrl = [self urlWithRoute:route];
    NSString *serializedArg = [[self class] serializeStringWithRoute:route routeArg:arg];
    NSDictionary *headers = [self headersWithRouteInfo:route.attrs serializedArg:serializedArg];

    NSURLRequest *request = [[self class] requestWithHeaders:headers url:requestUrl content:nil stream:nil];

    return [sessionToUse uploadTaskWithRequest:request fromData:input];
  };
  id<DBURLSessionTask> taskWithTokenRefresh =
      [[DBURLSessionTaskWithTokenRefresh alloc] initWithTaskCreationBlock:taskCreationBlock
                                                             taskDelegate:_delegate
                                                               urlSession:sessionToUse
                                                            tokenProvider:self.accessTokenProvider];

  DBUploadTaskImpl *uploadTask =
      [[DBUploadTaskImpl alloc] initWithTask:taskWithTokenRefresh tokenUid:self.tokenUid route:route];
  [uploadTask resume];
  return uploadTask;
}

#pragma mark - Upload-style request (NSInputStream)

- (DBUploadTaskImpl *)requestUpload:(DBRoute *)route arg:(id<DBSerializable>)arg inputStream:(NSInputStream *)input {
  NSURLSession *sessionToUse = _session;
  DBURLSessionTaskCreationBlock taskCreationBlock = ^{
    NSURL *requestUrl = [self urlWithRoute:route];
    NSString *serializedArg = [[self class] serializeStringWithRoute:route routeArg:arg];
    NSDictionary *headers = [self headersWithRouteInfo:route.attrs serializedArg:serializedArg];
    NSURLRequest *request = [[self class] requestWithHeaders:headers url:requestUrl content:nil stream:input];
    return [sessionToUse uploadTaskWithStreamedRequest:request];
  };
  id<DBURLSessionTask> taskWithTokenRefresh =
      [[DBURLSessionTaskWithTokenRefresh alloc] initWithTaskCreationBlock:taskCreationBlock
                                                             taskDelegate:_delegate
                                                               urlSession:sessionToUse
                                                            tokenProvider:self.accessTokenProvider];
  DBUploadTaskImpl *uploadTask =
      [[DBUploadTaskImpl alloc] initWithTask:taskWithTokenRefresh tokenUid:self.tokenUid route:route];
  [uploadTask resume];
  return uploadTask;
}

#pragma mark - Download-style request (NSURL)

- (DBDownloadUrlTask *)requestDownload:(DBRoute *)route
                                   arg:(id<DBSerializable>)arg
                             overwrite:(BOOL)overwrite
                           destination:(NSURL *)destination {
  return [self requestDownload:route
                           arg:arg
                     overwrite:overwrite
                   destination:destination
               byteOffsetStart:nil
                 byteOffsetEnd:nil];
}

- (DBDownloadUrlTask *)requestDownload:(DBRoute *)route
                                   arg:(id<DBSerializable>)arg
                             overwrite:(BOOL)overwrite
                           destination:(NSURL *)destination
                       byteOffsetStart:(NSNumber *)byteOffsetStart
                         byteOffsetEnd:(NSNumber *)byteOffsetEnd {
  NSURLSession *sessionToUse = _secondarySession;
  DBURLSessionTaskCreationBlock taskCreationBlock = ^{
    NSURL *requestUrl = [self urlWithRoute:route];
    NSString *serializedArg = [[self class] serializeStringWithRoute:route routeArg:arg];
    NSDictionary *headers = [self headersWithRouteInfo:route.attrs
                                         serializedArg:serializedArg
                                       byteOffsetStart:byteOffsetStart
                                         byteOffsetEnd:byteOffsetEnd];

    NSURLRequest *request = [[self class] requestWithHeaders:headers url:requestUrl content:nil stream:nil];

    return [sessionToUse downloadTaskWithRequest:request];
  };
  id<DBURLSessionTask> taskWithTokenRefresh =
      [[DBURLSessionTaskWithTokenRefresh alloc] initWithTaskCreationBlock:taskCreationBlock
                                                             taskDelegate:_delegate
                                                               urlSession:sessionToUse
                                                            tokenProvider:self.accessTokenProvider];
  DBDownloadUrlTaskImpl *downloadTask = [[DBDownloadUrlTaskImpl alloc] initWithTask:taskWithTokenRefresh
                                                                           tokenUid:self.tokenUid
                                                                              route:route
                                                                          overwrite:overwrite
                                                                        destination:destination];
  [downloadTask resume];
  return downloadTask;
}

#pragma mark - Download-style request (NSData)

- (DBDownloadDataTask *)requestDownload:(DBRoute *)route arg:(id<DBSerializable>)arg {
  return [self requestDownload:route arg:arg byteOffsetStart:nil byteOffsetEnd:nil];
}

- (DBDownloadDataTask *)requestDownload:(DBRoute *)route
                                    arg:(id<DBSerializable>)arg
                        byteOffsetStart:(NSNumber *)byteOffsetStart
                          byteOffsetEnd:(NSNumber *)byteOffsetEnd {
  NSURLSession *sessionToUse = _secondarySession;
  DBURLSessionTaskCreationBlock taskCreationBlock = ^{
    NSURL *requestUrl = [self urlWithRoute:route];
    NSString *serializedArg = [[self class] serializeStringWithRoute:route routeArg:arg];
    NSDictionary *headers = [self headersWithRouteInfo:route.attrs
                                         serializedArg:serializedArg
                                       byteOffsetStart:byteOffsetStart
                                         byteOffsetEnd:byteOffsetEnd];
    NSURLRequest *request = [[self class] requestWithHeaders:headers url:requestUrl content:nil stream:nil];
    return [sessionToUse downloadTaskWithRequest:request];
  };
  id<DBURLSessionTask> taskWithTokenRefresh =
      [[DBURLSessionTaskWithTokenRefresh alloc] initWithTaskCreationBlock:taskCreationBlock
                                                             taskDelegate:_delegate
                                                               urlSession:sessionToUse
                                                            tokenProvider:self.accessTokenProvider];
  DBDownloadDataTaskImpl *downloadTask =
      [[DBDownloadDataTaskImpl alloc] initWithTask:taskWithTokenRefresh tokenUid:self.tokenUid route:route];
  [downloadTask resume];
  return downloadTask;
}

- (DBTransportDefaultConfig *)duplicateTransportConfigWithAsMemberId:(NSString *)asMemberId {
  return [[DBTransportDefaultConfig alloc] initWithAppKey:self.appKey
                                                appSecret:self.appSecret
                                                userAgent:self.userAgent
                                               asMemberId:asMemberId
                                            delegateQueue:_delegateQueue
                                   forceForegroundSession:_forceForegroundSession];
}

- (DBTransportDefaultConfig *)duplicateTransportConfigWithPathRoot:(DBCOMMONPathRoot *)pathRoot {
  return [[DBTransportDefaultConfig alloc] initWithAppKey:self.appKey
                                                appSecret:self.appSecret
                                           hostnameConfig:nil
                                              redirectURL:nil
                                                userAgent:self.userAgent
                                               asMemberId:self.asMemberId
                                                 pathRoot:pathRoot
                                        additionalHeaders:nil
                                            delegateQueue:_delegateQueue
                                   forceForegroundSession:_forceForegroundSession
                                sharedContainerIdentifier:nil];
}

#pragma mark - Session accessors and mutators

- (NSURLSession *)session {
  @synchronized(self) {
    return _session;
  }
}

- (void)setSession:(NSURLSession *)session {
  @synchronized(self) {
    _session = session;
  }
}

- (NSURLSession *)secondarySession {
  @synchronized(self) {
    return _secondarySession;
  }
}

- (void)setSecondarySession:(NSURLSession *)secondarySession {
  @synchronized(self) {
    _secondarySession = secondarySession;
  }
}

- (NSURLSession *)longpollSession {
  @synchronized(self) {
    return _longpollSession;
  }
}

- (void)setLongpollSession:(NSURLSession *)longpollSession {
  @synchronized(self) {
    _longpollSession = longpollSession;
  }
}

@end
