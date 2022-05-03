///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

#import "DBHandlerTypes.h"
#import "DBTasks.h"
#import "DBTasksImpl.h"
#import "DBURLSessionTaskWithTokenRefresh.h"

@class DBBatchUploadData;
@class DBDelegate;
@class DBRequestError;
@class DBRoute;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - RPC-style network task

@interface DBRpcTaskImpl : DBRpcTask

///
/// `DBRpcTaskImpl` full constructor.
///
/// @param task The `DBURLSessionTask` task that initialized the network request.
/// @param tokenUid Identifies a unique Dropbox account. Used for the multi Dropbox account case where client objects
/// are each associated with a particular Dropbox account.
/// @param route The static `DBRoute` instance associated with the route to which the request was made. Contains
/// information like route host, response type, etc.). This is used in the deserialization process.
///
/// @return An initialized instance.
///
- (instancetype)initWithTask:(id<DBURLSessionTask>)task tokenUid:(nullable NSString *)tokenUid route:(DBRoute *)route;

/// The session that was used to make to the request.
@property (nonatomic, readonly) NSURLSession *session;

/// The `DBURLSessionTask` that was used to make the request.
@property (nonatomic, readonly) id<DBURLSessionTask> task;

@end

#pragma mark - Upload-style network task

@interface DBUploadTaskImpl : DBUploadTask

/// The session that was used to make to the request.
@property (nonatomic, readonly) NSURLSession *session;

/// The `DBURLSessionTask` that was used to make the request.
@property (nonatomic, readonly) id<DBURLSessionTask> uploadTask;

///
/// `DBUploadTask` full constructor.
///
/// @param task The `DBURLSessionTask` task that initialized the network request.
/// @param tokenUid Identifies a unique Dropbox account. Used for the multi Dropbox account case where client objects
/// are each associated with a particular Dropbox account.
/// @param route The static `DBRoute` instance associated with the route to which the request was made. Contains
/// information like route host, response type, etc.). This is used in the deserialization process.
///
/// @return An initialized instance.
///
- (instancetype)initWithTask:(id<DBURLSessionTask>)task tokenUid:(nullable NSString *)tokenUid route:(DBRoute *)route;
@end

#pragma mark - Download-style network task (NSURL)

@interface DBDownloadUrlTaskImpl : DBDownloadUrlTask

/// The session that was used to make to the request.
@property (nonatomic, readonly) NSURLSession *session;

///
/// `DBDownloadUrlTask` full constructor.
///
/// @param task The `NSURLSessionDataTask` task that initialized the network request.
/// @param tokenUid Identifies a unique Dropbox account. Used for the multi Dropbox account case where client objects
/// are each associated with a particular Dropbox account.
/// @param route The static `DBRoute` instance associated with the route to which the request was made. Contains
/// information like route host, response type, etc.). This is used in the deserialization process.
/// @param overwrite Whether the outputted file should overwrite in the event of a name collision.
/// @param destination Location to which output content should be downloaded.
///
/// @return An initialized instance.
///
- (instancetype)initWithTask:(id<DBURLSessionTask>)task
                    tokenUid:(nullable NSString *)tokenUid
                       route:(DBRoute *)route
                   overwrite:(BOOL)overwrite
                 destination:(NSURL *)destination;
@end

#pragma mark - Download-style network task (NSData)

@interface DBDownloadDataTaskImpl : DBDownloadDataTask

/// The session that was used to make to the request.
@property (nonatomic, readonly) NSURLSession *session;

///
/// DBDownloadDataTask full constructor.
///
/// @param task The `NSURLSessionDataTask` task that initialized the network request.
/// @param tokenUid Identifies a unique Dropbox account. Used for the multi Dropbox account case where client objects
/// are each associated with a particular Dropbox account.
/// @param route The static `DBRoute` instance associated with the route to which the request was made. Contains
/// information like route host, response type, etc.). This is used in the deserialization process.
///
/// @return An initialized instance.
///
- (instancetype)initWithTask:(id<DBURLSessionTask>)task tokenUid:(nullable NSString *)tokenUid route:(DBRoute *)route;
@end

NS_ASSUME_NONNULL_END
