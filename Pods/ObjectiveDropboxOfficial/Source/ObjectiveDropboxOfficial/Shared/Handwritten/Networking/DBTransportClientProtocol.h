///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

#import "DBSerializableProtocol.h"

@class DBDelegate;
@class DBDownloadDataTask;
@class DBDownloadUrlTask;
@class DBError;
@class DBRoute;
@class DBRpcTask;
@class DBUploadTask;

@protocol DBTransportClient <NSObject>

#pragma mark - RPC-style request

///
/// Request to RPC-style endpoint.
///
/// @param route The static `DBRoute` instance associated with the route. Contains information
/// like route host, response type, etc.
/// @param arg The unserialized route argument to pass. Must conform to the `DBSerializable`
/// protocol.
///
/// @return A `DBRpcTask` where response and progress handlers can be added, and the request can
/// be halted or cancelled.
///
- (DBRpcTask * _Nonnull)requestRpc:(DBRoute * _Nonnull)route arg:(id<DBSerializable> _Nullable)arg;

#pragma mark - Upload-style request (NSURL)

///
/// Request to Upload-style endpoint (via `NSURL`).
///
/// @param route The static `DBRoute` instance associated with the route. Contains information
/// like route host, response type, etc.
/// @param arg The unserialized route argument to pass. Must conform to the `DBSerializable`
/// protocol.
/// @param input The location of the file to upload. NSURLSession supports background uploads
/// for this input type, so by default, all requests of this type will be made in the background.
///
/// @return A `DBUploadTask` where response and progress handlers can be added, and the request can
/// be halted or cancelled.
///
- (DBUploadTask * _Nonnull)requestUpload:(DBRoute * _Nonnull)route
                                    arg:(id<DBSerializable> _Nullable)arg
                               inputUrl:(NSURL * _Nonnull)input;

#pragma mark - Upload-style request (NSData)

///
/// Request to Upload-style endpoint (via `NSData`).
///
/// @param route The static `DBRoute` instance associated with the route. Contains information
/// like route host, response type, etc.
/// @param arg The unserialized route argument to pass. Must conform to the `DBSerializable`
/// protocol.
/// @param input The location of the file to upload. NSURLSession does not support background
/// uploads for this input type, so by default, all requests of this type will be made in the foreground.
///
/// @return A `DBUploadTask` where response and progress handlers can be added, and the request can
/// be halted or cancelled.
///
- (DBUploadTask * _Nonnull)requestUpload:(DBRoute * _Nonnull)route
                                    arg:(id<DBSerializable> _Nullable)arg
                              inputData:(NSData * _Nonnull)input;

#pragma mark - Upload-style request (NSInputStream)

///
/// Request to Upload-style endpoint (via `NSInputStream`).
///
/// @param route The static `DBRoute` instance associated with the route. Contains information
/// like route host, response type, etc.
/// @param arg The unserialized route argument to pass. Must conform to the `DBSerializable`
/// protocol.
/// @param input The location of the file to upload. `NSURLSession` does not support background
/// uploads for this input type, so by default, all requests of this type will be made in the foreground.
///
/// @return A `DBUploadTask` where response and progress handlers can be added, and the request can
/// be halted or cancelled.
///
- (DBUploadTask * _Nonnull)requestUpload:(DBRoute * _Nonnull)route
                                    arg:(id<DBSerializable> _Nullable)arg
                            inputStream:(NSInputStream * _Nonnull)input;

#pragma mark - Download-style request (NSURL)

///
/// Request to Download-style endpoint (via `NSURL` output type).
///
/// @param route The static `DBRoute` instance associated with the route. Contains information
/// like route host, response type, etc.
/// @param arg The unserialized route argument to pass. Must conform to the `DBSerializable`
/// protocol.
/// @param overwrite Whether the outputted file should overwrite in the event of a name collision.
/// @param destination Location to which output content should be downloaded.
///
/// @return A `DBDownloadUrlTask` where response and progress handlers can be added, and the request can
/// be halted or cancelled.
///
- (DBDownloadUrlTask * _Nonnull)requestDownload:(DBRoute * _Nonnull)route
                                           arg:(id<DBSerializable> _Nullable)arg
                                     overwrite:(BOOL)overwrite
                                   destination:(NSURL * _Nonnull)destination;

#pragma mark - Download-style request (NSData)

///
/// Request to Download-style endpoint (with `NSData` output type).
///
/// @param route The static `DBRoute` instance associated with the route. Contains information
/// like route host, response type, etc.
/// @param arg The unserialized route argument to pass. Must conform to the `DBSerializable`
/// protocol. Note, this return type is different from the return type of `requestDownload:arg`.
///
/// @return A `DBDownloadDataTask` where response and progress handlers can be added, and the request can
/// be halted or cancelled. Note, this return type is different from the return type of
/// `requestDownload:arg:overwrite:destination`.
///
- (DBDownloadDataTask * _Nonnull)requestDownload:(DBRoute * _Nonnull)route arg:(id<DBSerializable> _Nullable)arg;

@end
