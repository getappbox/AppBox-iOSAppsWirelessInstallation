///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

#import "DBHandlerTypes.h"
#import "DBTasks.h"
#import "DBTasksImpl.h"

@class DBBatchUploadData;
@class DBDelegate;
@class DBRequestError;
@class DBRoute;

#pragma mark - RPC-style network task

@interface DBRpcTaskImpl : DBRpcTask

/// The `NSURLSessionTask` that was used to make the request.
@property (nonatomic, readonly) NSURLSessionDataTask * _Nonnull dataTask;

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
/// @param route The static `DBRoute` instance associated with the route to which the request was made. Contains
/// information like route host, response type, etc.). This is used in the deserialization process.
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
@property (nonatomic, readonly) NSURLSessionUploadTask * _Nonnull uploadTask;

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
/// @param route The static `DBRoute` instance associated with the route to which the request was made. Contains
/// information like route host, response type, etc.). This is used in the deserialization process.
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
@property (nonatomic, readonly) NSURLSessionDownloadTask * _Nonnull downloadUrlTask;

/// The session that was used to make to the request.
@property (nonatomic, readonly) NSURLSession * _Nonnull session;

/// The delegate used manage handler code.
@property (nonatomic, readonly) DBDelegate * _Nonnull delegate;

///
/// `DBDownloadUrlTask` full constructor.
///
/// @param task The `NSURLSessionDataTask` task that initialized the network request.
/// @param session The `NSURLSession` used to make the network request.
/// @param delegate The delegate that manages and executes response code.
/// @param route The static `DBRoute` instance associated with the route to which the request was made. Contains
/// information like route host, response type, etc.). This is used in the deserialization process.
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
@property (nonatomic, readonly) NSURLSessionDownloadTask * _Nonnull downloadDataTask;

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
/// @param route The static `DBRoute` instance associated with the route to which the request was made. Contains
/// information like route host, response type, etc.). This is used in the deserialization process.
///
/// @return An initialized instance.
///
- (nonnull instancetype)initWithTask:(NSURLSessionDownloadTask * _Nonnull)task
                             session:(NSURLSession * _Nonnull)session
                            delegate:(DBDelegate * _Nonnull)delegate
                               route:(DBRoute * _Nonnull)route;
@end
