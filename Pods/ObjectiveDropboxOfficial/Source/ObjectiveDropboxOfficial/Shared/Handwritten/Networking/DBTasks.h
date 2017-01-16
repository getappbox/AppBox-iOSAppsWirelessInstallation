///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBHandlerTypes.h"
#import <Foundation/Foundation.h>
@class DBBatchUploadData;
@class DBDelegate;
@class DBRequestError;
@class DBRoute;

#pragma mark - Base network task

///
/// Base class for network task wrappers.
///
/// After a network request is made via `DBTransportClient`, a subclass of `DBTask` is returned, from which response and
/// progress handlers can be installed, and the network response paused or cancelled.
///
/// Handlers are executed on the thread specified by the `DBDelegate` instance with which the `DBTask` instance is
/// initialied (more specifically, the delegate queue that the `DBDelegate` uses to execute handler code). By default,
/// this is the main thread, which makes updating UI elements in response handlers convenient.
///
/// While response handlers are not optional, they do not necessarily need to have been installed by the time the SDK
/// has received its server response. If this is the case, completion data will be saved, and the handler will be
/// executed with the completion data upon its installation. Downloaded content will be moved from a temporary location
/// to the final destination when the response handler code is executed.
///
@interface DBTask : NSObject {
@protected
  DBRoute *_route;
}
/// Information about the route to which the request
/// was made.
@property (nonatomic, readonly) DBRoute * _Nonnull route;

- (nonnull instancetype)initWithRoute:(DBRoute * _Nonnull)route;

///
/// Cancels the current request.
///
- (void)cancel;

///
/// Suspends the current request.
///
- (void)suspend;

///
/// Resumes the current request.
///
- (void)resume;

///
/// Starts the current request.
///
- (void)start;

@end

#pragma mark - RPC-style network task

///
/// Dropbox RPC-style Network Task.
///
/// After an RPC network request is made via `DBTransportClient`, a subclass
/// of `DBRpcTask` is returned, from which response and progress handlers
/// can be installed, and the network response paused or cancelled.
///
/// `TResponse` is the generic representation of the route-specific result, and
/// `TError` is the generic representation of the route-specific error.
///
/// Response / error deserialization is performed with this class.
///
@interface DBRpcTask <TResponse, TError> : DBTask

///
/// Installs a response handler for the current request.
///
/// Executes handler on main queue/thread.
///
/// @note Any existing handlers are replaced by the supplied handler.
///
/// @param responseBlock The handler block to be executed in the event of a successful or
/// unsuccessful network request. The first argument is the route-specific result. The second
/// argument is the route-specific error. And the third argument is the more general network
/// error (which includes information like Dropbox request ID, http status code, etc.).
///
/// @return The current `DBRpcTask` instance.
///
- (DBRpcTask<TResponse, TError> * _Nonnull)response:(void (^_Nonnull)(TResponse _Nullable, TError _Nullable,
                                                                      DBRequestError * _Nullable))responseBlock;

///
/// Installs a response handler for the current request with a specific queue on which to execute handler code.
///
/// Executes handler on supplied queue/thread.
///
/// @note Any existing handlers are replaced by the supplied handler.
///
/// @param queue The operation queue on which to execute the response.
/// @param responseBlock The handler block to be executed in the event of a successful or
/// unsuccessful network request. The first argument is the route-specific result. The second
/// argument is the route-specific error. And the third argument is the more general network
/// error (which includes information like Dropbox request ID, http status code, etc.).
///
/// @return The current `DBRpcTask` instance.
///
- (DBRpcTask<TResponse, TError> * _Nonnull)response:(NSOperationQueue * _Nullable)queue
response:(void (^_Nonnull)(TResponse _Nullable, TError _Nullable,
                           DBRequestError * _Nullable))responseBlock;

///
/// Installs a progress handler for the current request.
///
/// Executes handler on main queue/thread.
///
/// @note Any existing handlers are replaced by the supplied handler.
///
/// @param progressBlock The progress block to be executed in the event of a request update.
/// The first argument is the number of bytes sent. The second argument is the number of total
/// bytes sent. And the third argument is the number of total bytes expected to be sent.
///
/// @return The current `DBRpcTask` instance.
///
- (DBRpcTask * _Nonnull)progress:(DBProgressBlock _Nonnull)progressBlock;

///
/// Installs a progress handler for the current request.
///
/// Executes handler on supplied queue/thread.
///
/// @note Any existing handlers are replaced by the supplied handler.
///
/// @param queue The operation queue on which to execute the response.
/// @param progressBlock The progress block to be executed in the event of a request update.
/// The first argument is the number of bytes sent. The second argument is the number of total
/// bytes sent. And the third argument is the number of total bytes expected to be sent.
///
/// @return The current `DBRpcTask` instance.
///
- (DBRpcTask * _Nonnull)progress:(NSOperationQueue * _Nullable)queue progress:(DBProgressBlock _Nonnull)progressBlock;

@end

#pragma mark - Upload-style network task

///
/// Dropbox Upload-style Network Task.
///
/// After an Upload network request is made via `DBTransportClient`, a subclass
/// of `DBUploadTask` is returned, from which response and progress handlers
/// can be installed, and the network response paused or cancelled.
///
/// `TResponse` is the generic representation of the route-specific result, and
/// `TError` is the generic representation of the route-specific error.
///
/// Response / error deserialization is performed with this class.
///
@interface DBUploadTask <TResponse, TError> : DBTask

///
/// Installs a response handler for the current request.
///
/// Executes handler on main queue/thread.
///
/// @note Any existing handlers are replaced by the supplied handler.
///
/// @param responseBlock The handler block to be executed in the event of a successful or
/// unsuccessful network request. The first argument is the route-specific result. The second
/// argument is the route-specific error. And the third argument is the more general network
/// error (which includes information like Dropbox request ID, http status code, etc.).
///
/// @return The current `DBUploadTask` instance.
///
- (DBUploadTask<TResponse, TError> * _Nonnull)response:(void (^_Nonnull)(TResponse _Nullable, TError _Nullable,
                                                                         DBRequestError * _Nullable))responseBlock;

///
/// Installs a response handler for the current request with a specific queue on which to execute handler code.
///
/// Executes handler on supplied queue/thread.
///
/// @note Any existing handlers are replaced by the supplied handler.
///
/// @param queue The operation queue on which to execute the response.
/// @param responseBlock The handler block to be executed in the event of a successful or
/// unsuccessful network request. The first argument is the route-specific result. The second
/// argument is the route-specific error. And the third argument is the more general network
/// error (which includes information like Dropbox request ID, http status code, etc.).
///
/// @return The current `DBUploadTask` instance.
///
- (DBUploadTask<TResponse, TError> * _Nonnull)response:(NSOperationQueue * _Nullable)queue
response:(void (^_Nonnull)(TResponse _Nullable, TError _Nullable,
                           DBRequestError * _Nullable))responseBlock;

///
/// Installs a progress handler for the current request.
///
/// Executes handler on main queue/thread.
///
/// @note Any existing handlers are replaced by the supplied handler.
///
/// @param progressBlock The progress block to be executed in the event of a request update.
/// The first argument is the number of bytes uploaded. The second argument is the number of total
/// bytes uploaded. And the third argument is the number of total bytes expected to be uploaded.
///
/// @return The current `DBUploadTask` instance.
///
- (DBUploadTask * _Nonnull)progress:(DBProgressBlock _Nonnull)progressBlock;

///
/// Installs a progress handler for the current request.
///
/// Executes handler on supplied queue/thread.
///
/// @note Any existing handlers are replaced by the supplied handler.
///
/// @param queue The operation queue on which to execute the response.
/// @param progressBlock The progress block to be executed in the event of a request update.
/// The first argument is the number of bytes uploaded. The second argument is the number of total
/// bytes uploaded. And the third argument is the number of total bytes expected to be uploaded.
///
/// @return The current `DBUploadTask` instance.
///
- (DBUploadTask * _Nonnull)progress:(NSOperationQueue * _Nullable)queue progress:(DBProgressBlock _Nonnull)progressBlock;

@end

#pragma mark - Download-style network task (NSURL)

///
/// Dropbox Download-style Network Task (download to `NSURL`).
///
/// After an Upload network request is made via `DBTransportClient`, a subclass
/// of `DBDownloadUrlTask` is returned, from which response and progress handlers
/// can be installed, and the network response paused or cancelled. Note, this class
/// is returned only for download requests with an `NSURL` output.
///
/// `TResponse` is the generic representation of the route-specific result, and
/// `TError` is the generic representation of the route-specific error.
///
/// Response / error deserialization is performed with this class.
///
@interface DBDownloadUrlTask <TResponse, TError> : DBTask

///
/// Installs a response handler for the current request.
///
/// Executes handler on main queue/thread.
///
/// @note Any existing handlers are replaced by the supplied handler. In the event the request returns
/// successfully, but a handler is not yet installed, the downloaded content will be moved to a temporary
/// location (`NSTemporaryDirectory()`) until the response handler is installed, at which point the
/// file content will be moved to its final destination.
///
/// @param responseBlock The handler block to be executed in the event of a successful or
/// unsuccessful network request. The first argument is the route-specific result. The second
/// argument is the route-specific error. And the third argument is the more general network
/// error (which includes information like Dropbox request ID, http status code, etc.). The fourth
/// argument is the output destination to which the file was downloaded.
///
/// @return The current `DBDownloadUrlTask` instance.
///
- (DBDownloadUrlTask<TResponse, TError> * _Nonnull)response:
(void (^_Nonnull)(TResponse _Nullable, TError _Nullable, DBRequestError * _Nullable, NSURL * _Nonnull))responseBlock;

///
/// Installs a response handler for the current request with a specific queue on which to execute handler code.
///
/// Executes handler on supplied queue/thread.
///
/// @note Any existing handlers are replaced by the supplied handler.
///
/// @param queue The operation queue on which to execute the response.
/// @param responseBlock The handler block to be executed in the event of a successful or
/// unsuccessful network request. The first argument is the route-specific result. The second
/// argument is the route-specific error. And the third argument is the more general network
/// error (which includes information like Dropbox request ID, http status code, etc.). The fourth
/// argument is the output destination to which the file was downloaded.
///
/// @return The current `DBDownloadUrlTask` instance.
///
- (DBDownloadUrlTask<TResponse, TError> * _Nonnull)response:(NSOperationQueue * _Nullable)queue
response:(void (^_Nonnull)(TResponse _Nullable, TError _Nullable,
                           DBRequestError * _Nullable,
                           NSURL * _Nonnull))responseBlock;

///
/// Installs a progress handler for the current request.
///
/// Executes handler on main queue/thread.
///
/// @note Any existing handlers are replaced by the supplied handler.
///
/// @param progressBlock The progress block to be executed in the event of a request update.
/// The first argument is the number of bytes downloaded. The second argument is the number of total
/// bytes downloaded. And the third argument is the number of total bytes expected to be downloaded.
///
/// @return The current `DBDownloadUrlTask` instance.
///
- (DBDownloadUrlTask * _Nonnull)progress:(DBProgressBlock _Nonnull)progressBlock;

///
/// Installs a progress handler for the current request.
///
/// Executes handler on supplied queue/thread.
///
/// @note Any existing handlers are replaced by the supplied handler.
///
/// @param queue The operation queue on which to execute the response.
/// @param progressBlock The progress block to be executed in the event of a request update.
/// The first argument is the number of bytes downloaded. The second argument is the number of total
/// bytes downloaded. And the third argument is the number of total bytes expected to be downloaded.
///
/// @return The current `DBDownloadUrlTask` instance.
///
- (DBDownloadUrlTask * _Nonnull)progress:(NSOperationQueue * _Nullable)queue
progress:(DBProgressBlock _Nonnull)progressBlock;

@end

#pragma mark - Download-style network task (NSData)

///
/// Dropbox Download Network Task (download to `NSData`).
///
/// After an Upload network request is made via `DBTransportClient`, a subclass
/// of `DBDownloadDataTask` is returned, from which response and progress handlers
/// can be installed, and the network response paused or cancelled. Note, this class
/// is returned only for download requests with an `NSData` output.
///
/// `TResponse` is the generic representation of the route-specific result, and
/// `TError` is the generic representation of the route-specific error.
///
/// Response / error deserialization is performed with this class.
///
@interface DBDownloadDataTask <TResponse, TError> : DBTask

///
/// Installs a response handler for the current request.
///
/// Executes handler on main queue/thread.
///
/// @note Any existing handlers are replaced by the supplied handler.
///
/// @param responseBlock The handler block to be executed in the event of a successful or
/// unsuccessful network request. The first argument is the route-specific result. The second
/// argument is the route-specific error. And the third argument is the more general network
/// error (which includes information like Dropbox request ID, http status code, etc.). The fourth
/// argument is the output `NSData` object in memory, to which the file was downloaded.
///
/// @return The current `DBDownloadDataTask` instance.
///
- (DBDownloadDataTask<TResponse, TError> * _Nonnull)response:
(void (^_Nonnull)(TResponse _Nullable, TError _Nullable, DBRequestError * _Nullable, NSData * _Nonnull))responseBlock;

///
/// Installs a response handler for the current request with a specific queue on which to execute handler code.
///
/// Executes handler on supplied queue/thread.
///
/// @note Any existing handlers are replaced by the supplied handler.
///
/// @param queue The operation queue on which to execute the response.
/// @param responseBlock The handler block to be executed in the event of a successful or
/// unsuccessful network request. The first argument is the route-specific result. The second
/// argument is the route-specific error. And the third argument is the more general network
/// error (which includes information like Dropbox request ID, http status code, etc.). The fourth
/// argument is the output `NSData` object in memory, to which the file was downloaded.
///
/// @return The current `DBDownloadDataTask` instance.
///
- (DBDownloadDataTask<TResponse, TError> * _Nonnull)response:(NSOperationQueue * _Nullable)queue
response:(void (^_Nonnull)(TResponse _Nullable, TError _Nullable,
                           DBRequestError * _Nullable,
                           NSData * _Nonnull))responseBlock;

///
/// Installs a progress handler for the current request.
///
/// Executes handler on main queue/thread.
///
/// @note Any existing handlers are replaced by the supplied handler.
///
/// @param progressBlock The progress block to be executed in the event of a request update.
/// The first argument is the number of bytes downloaded. The second argument is the number of total
/// bytes downloaded. And the third argument is the number of total bytes expected to be downloaded.
///
/// @return The current `DBDownloadDataTask` instance.
///
- (DBDownloadDataTask * _Nonnull)progress:(DBProgressBlock _Nonnull)progressBlock;

///
/// Installs a progress handler for the current request.
///
/// Executes handler on supplied queue/thread.
///
/// @note Any existing handlers are replaced by the supplied handler.
///
/// @param queue The operation queue on which to execute the response.
/// @param progressBlock The progress block to be executed in the event of a request update.
/// The first argument is the number of bytes downloaded. The second argument is the number of total
/// bytes downloaded. And the third argument is the number of total bytes expected to be downloaded.
///
/// @return The current `DBDownloadDataTask` instance.
///
- (DBDownloadDataTask * _Nonnull)progress:(NSOperationQueue * _Nullable)queue
progress:(DBProgressBlock _Nonnull)progressBlock;

@end
