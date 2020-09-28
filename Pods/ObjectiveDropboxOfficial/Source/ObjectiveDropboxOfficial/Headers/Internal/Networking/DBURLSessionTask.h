///
/// Copyright (c) 2020 Dropbox, Inc. All rights reserved.
///

#import "DBHandlerTypes.h"
#import <Foundation/Foundation.h>

@class DBURLSessionTaskResponseBlockWrapper;

NS_ASSUME_NONNULL_BEGIN

/// Block that creates the actual API request.
typedef NSURLSessionTask *_Nonnull (^DBURLSessionTaskCreationBlock)(void);

/// Protocol for custom URLSession tasks that are used internally by the DBTask classes.
@protocol DBURLSessionTask <NSObject>

/// The `NSURLSession` used to make the network request.
@property (nonatomic, readonly) NSURLSession *session;

/// Creates a new instance with same initial setup.
- (id<DBURLSessionTask>)duplicate;

/// Cancels the API request.
- (void)cancel;

/// Suspends the API request.
- (void)suspend;

/// Resumes the API request.
- (void)resume;

/// Sets progress handler for the task.
/// @param progressBlock The `DBProgressBlock` that handles task progress.
/// @param queue An optional operation queue on which to execute progress handler code. If not provided, the handler
/// may be executed on any queue.
- (void)setProgressBlock:(DBProgressBlock)progressBlock queue:(nullable NSOperationQueue *)queue;

/// Sets response/completion handler for the task.
/// @param responseBlock The `DBURLSessionTaskResponseBlock` that handles task response.
/// @param queue An optional operation queue on which to execute response handler code. If not provided, the handler
/// may be executed on any queue.
- (void)setResponseBlock:(DBURLSessionTaskResponseBlockWrapper *)responseBlock queue:(nullable NSOperationQueue *)queue;

@end

NS_ASSUME_NONNULL_END
