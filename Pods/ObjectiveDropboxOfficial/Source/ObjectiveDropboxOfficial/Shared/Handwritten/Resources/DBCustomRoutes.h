///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

///
/// Custom client-side routes for the `Files` namespace
///

#import "DBASYNCPollError.h"
#import "DBFILESRoutes.h"
#import "DBFILESUploadSessionFinishBatchJobStatus.h"
#import "DBHandlerTypes.h"
@class DBBatchUploadTask;
@class DBTasksStorage;
@class DBTransportClient;

/// Special custom response block for batch upload.
typedef void (^DBBatchUploadResponseBlock)(DBFILESUploadSessionFinishBatchJobStatus * _Nullable,
                                           DBASYNCPollError * _Nullable, DBRequestError * _Nullable);

///
/// Stores data for a particular batch upload attempt.
///
@interface DBBatchUploadData : NSObject

/// The queue on which most response handling is performed.
@property (nonatomic, readonly) NSOperationQueue * _Nonnull queue;

/// The dispatch group that pairs upload requests with upload responses
/// so that we can wait for all request/response pairs to complete
/// before batch committing. In this way, we can start many upload
/// requests (for files under the chunk limit), without waiting for
/// the corresponding response.
@property (nonatomic, readonly) dispatch_group_t _Nonnull uploadGroup;

/// A client-supplied parameter that maps the file urls of the files to upload
/// to the corresponding commit info objects.
@property (nonatomic, readonly) NSDictionary<NSURL *, DBFILESCommitInfo *> * _Nonnull fileUrlsToCommitInfo;

/// List of finish args (which include commit info, cursor, etc.) which the SDK
/// maintains and passes to `upload_session/finish_batch`.
@property (atomic, readonly) NSMutableArray<DBFILESUploadSessionFinishArg *> * _Nonnull finishArgs;

/// The progress block that is periodically executed once a file upload is complete.
@property (nonatomic, readonly) DBProgressBlock _Nullable progressBlock;

/// The response block that is executed once all file uploads and the final batch commit
/// is complete.
@property (nonatomic, readonly) DBBatchUploadResponseBlock _Nonnull responseBlock;

/// The total size of all the files to upload. Used to return progress data to the client.
@property (nonatomic) NSUInteger totalUploadSize;

/// The total size of all the file content upload so far. Used to return progress data to
/// the client.
@property (atomic) NSUInteger totalUploadedSoFar;

/// The flag that determines whether upload continues or not.
@property (atomic) BOOL cancel;

/// The container object that stores all upload / download task objects for cancelling.
@property (nonatomic) DBTasksStorage * _Nonnull taskStorage;

@end

///
/// Extension of routes in the `Files` namespace.
///
/// These routes serve as a convenience layer built on top of our
/// auto-generated routes.
///
@interface DBFILESRoutes (DBCustomRoutes)

///
/// Batch uploads small and large files.
///
/// This is a custom route built as a convenience layer over several Dropbox endpoints.
/// Files will not only be batch uploaded, but large files will also automatically be
/// chunk-uploaded to the Dropbox server, for maximum efficiency.
///
/// @note The interface of this route does not have the same structure as other routes in the SDK.
/// Here, a special `DBBatchUploadTask` object is returned. Progress and response handlers are passed
/// in directly to the route, rather than installed via this response object.
///
/// @param fileUrlsToCommitInfo Map from the file urls of the files to upload
/// to the corresponding commit info objects.
/// @param queue The operation queue to execute progress / response handlers on. Main queue if `nil` is passed.
/// @param progressBlock The progress block that is periodically executed once a file
/// upload is complete. It's important to note that this progress handler will update only
/// when a file or file chunk is successfully uploaded. It will not give the client any
/// progress notifications once all of the file data is uploaded, but not yet committed. Once
/// the batch commit call is made, the client will have to simply wait for the server to commit
/// all of the uploaded data, until the response handler is called.
/// @param responseBlock The response block that is executed once all file uploads and the final
/// batch commit is complete.
///
/// @returns Special `DBBatchUploadTask` that exposes cancellation method.
///
- (DBBatchUploadTask * _Nonnull)batchUploadFiles:
                                   (NSDictionary<NSURL *, DBFILESCommitInfo *> * _Nonnull)fileUrlsToCommitInfo
                                          queue:(NSOperationQueue * _Nullable)queue
                                  progressBlock:(DBProgressBlock _Nullable)progressBlock
                                  responseBlock:(DBBatchUploadResponseBlock _Nonnull)responseBlock;

@end
