///
/// Copyright (c) 2020 Dropbox, Inc. All rights reserved.
///

#import "DBTasks.h"
#import "DBURLSessionTask.h"
#import <Foundation/Foundation.h>

@protocol DBAccessTokenProvider;

NS_ASSUME_NONNULL_BEGIN

/// A class that wraps a network request that calls Dropbox API.
/// This class will first attempt to refresh the access token and conditionally proceed to the actual API call.
@interface DBURLSessionTaskWithTokenRefresh : NSObject <DBURLSessionTask>

- (instancetype)init NS_UNAVAILABLE;

/// Designated Initializer.
///
/// @param taskCreationBlock The block that creates the actual API request.
/// @param taskDelegate The delegate used manage request handler code.
/// @param urlSession The `NSURLSession` used to make the API network request.
/// @param tokenProvider The `DBAccessTokenProvider` object to perform token refresh.
///
- (instancetype)initWithTaskCreationBlock:(DBURLSessionTaskCreationBlock)taskCreationBlock
                             taskDelegate:(nullable DBDelegate *)taskDelegate
                               urlSession:(NSURLSession *)urlSession
                            tokenProvider:(id<DBAccessTokenProvider>)tokenProvider NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
