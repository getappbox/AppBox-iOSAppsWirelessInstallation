///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBHandlerTypes.h"
#import "DBTasksImpl.h"
#import "DBTasks.h"
#import <Foundation/Foundation.h>
@class DBBatchUploadData;
@class DBDelegate;
@class DBRequestError;
@class DBRoute;


#pragma mark - RPC-style network task

@interface DBRpcTaskImpl : DBRpcTask

/// The `NSURLSessionTask` that was used to make the request.
@property (nonatomic, readonly) NSURLSessionDataTask * _Nonnull task;

/// The session that was used to make to the request.
@property (nonatomic, readonly) NSURLSession * _Nonnull session;

/// The delegate used manage handler code.
@property (nonatomic, readonly) DBDelegate * _Nonnull delegate;

///
/// `DBRpcTaskImpl` full constructor.
///
/// @param task The `NSURLSessionDataTask` task that initialized the network request.
/// @param session The `NSURLSession` used to make the network request.
/// @param delegate The delegate that manages and executes response code.
/// @param route The static `DBRoute` instance associated with the route to which the request
/// was made. Contains information like route host, response type, etc.). This is used in the deserialization
/// process.
///
/// @return An initialized instance.
///
- (nonnull instancetype)initWithTask:(NSURLSessionDataTask * _Nonnull)task
                             session:(NSURLSession * _Nonnull)session
                            delegate:(DBDelegate * _Nonnull)delegate
                               route:(DBRoute * _Nonnull)route;
@end

#pragma mark - Upload-style network task

@interface DBUploadTaskImpl : DBUploadTask

/// The `NSURLSessionTask` that was used to make the request.
@property (nonatomic, readonly) NSURLSessionUploadTask * _Nonnull task;

/// The session that was used to make to the request.
@property (nonatomic, readonly) NSURLSession * _Nonnull session;

/// The delegate used manage handler code.
@property (nonatomic, readonly) DBDelegate * _Nonnull delegate;

///
/// `DBUploadTask` full constructor.
///
/// @param task The `NSURLSessionDataTask` task that initialized the network request.
/// @param session The `NSURLSession` used to make the network request.
/// @param delegate The delegate that manages and executes response code.
/// @param route The static `DBRoute` instance associated with the route to which the request
/// was made. Contains information like route host, response type, etc.). This is used in the deserialization
/// process.
///
/// @return An initialized instance.
///
- (nonnull instancetype)initWithTask:(NSURLSessionUploadTask * _Nonnull)task
                             session:(NSURLSession * _Nonnull)session
                            delegate:(DBDelegate * _Nonnull)delegate
                               route:(DBRoute * _Nonnull)route;
@end

#pragma mark - Download-style network task (NSURL)

@interface DBDownloadUrlTaskImpl : DBDownloadUrlTask

/// The `NSURLSessionTask` that was used to make the request.
@property (nonatomic, readonly) NSURLSessionDownloadTask * _Nonnull task;

/// The session that was used to make to the request.
@property (nonatomic, readonly) NSURLSession * _Nonnull session;

/// The delegate used manage handler code.
@property (nonatomic, readonly) DBDelegate * _Nonnull delegate;

/// Whether the outputted file should overwrite in the event of a name collision.
@property (nonatomic, readonly) BOOL overwrite;

/// Location to which output content should be downloaded.
@property (nonatomic, readonly, copy) NSURL * _Nonnull destination;

///
/// `DBDownloadUrlTask` full constructor.
///
/// @param task The `NSURLSessionDataTask` task that initialized the network request.
/// @param session The `NSURLSession` used to make the network request.
/// @param delegate The delegate that manages and executes response code.
/// @param route The static `DBRoute` instance associated with the route to which the request
/// was made. Contains information like route host, response type, etc.). This is used in the deserialization
/// process.
/// @param overwrite Whether the outputted file should overwrite in the event of a name collision.
/// @param destination Location to which output content should be downloaded.
///
/// @return An initialized instance.
///
- (nonnull instancetype)initWithTask:(NSURLSessionDownloadTask * _Nonnull)task
                             session:(NSURLSession * _Nonnull)session
                            delegate:(DBDelegate * _Nonnull)delegate
                               route:(DBRoute * _Nonnull)route
                           overwrite:(BOOL)overwrite
                         destination:(NSURL * _Nonnull)destination;
@end

#pragma mark - Download-style network task (NSData)

@interface DBDownloadDataTaskImpl : DBDownloadDataTask

/// The `NSURLSessionTask` that was used to make the request.
@property (nonatomic, readonly) NSURLSessionDownloadTask * _Nonnull task;

/// The session that was used to make to the request.
@property (nonatomic, readonly) NSURLSession * _Nonnull session;

/// The delegate used manage handler code.
@property (nonatomic, readonly) DBDelegate * _Nonnull delegate;

///
/// DBDownloadDataTask full constructor.
///
/// @param task The `NSURLSessionDataTask` task that initialized the network request.
/// @param session The `NSURLSession` used to make the network request.
/// @param delegate The delegate that manages and executes response code.
/// @param route The static `DBRoute` instance associated with the route to which the request
/// was made. Contains information like route host, response type, etc.). This is used in the deserialization
/// process.
///
/// @return An initialized instance.
///
- (nonnull instancetype)initWithTask:(NSURLSessionDownloadTask * _Nonnull)task
                             session:(NSURLSession * _Nonnull)session
                            delegate:(DBDelegate * _Nonnull)delegate
                               route:(DBRoute * _Nonnull)route;
@end

///
/// Dropbox task object for custom batch upload route.
///
/// The batch upload route is a convenience layer over several of our auto-generated API endpoints. For this reason,
/// there is less flexibility and granularity of control. Progress and response handlers are passed directly into this
/// route (rather than installed via this task object) and only `cancel` is available. This task is also specific to
/// only one endpoint, rather than an entire class (style) of endpoints.
///
@interface DBBatchUploadTask : NSObject

///
/// DBBatchUploadTask full constructor.
///
/// @param uploadData relevant to the particular batch upload request.
///
/// @returns A DBBatchUploadTask instance.
///
- (nonnull instancetype)initWithUploadData:(DBBatchUploadData * _Nonnull)uploadData;

///
/// Cancels the current request.
///
- (void)cancel;

@end
