///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

#import "DBSerializableProtocol.h"
#import "DBTransportClientBase.h"
#import "DBTransportClientProtocol.h"

@class DBDelegate;
@class DBDownloadDataTask;
@class DBDownloadUrlTask;
@class DBRequestError;
@class DBRoute;
@class DBRpcTask;
@class DBUploadTask;

///
/// The networking client for the User and Business API.
///
/// Normally, one networking client should instantiated per access token and session /
/// background session pair. By default, all Upload-style and Download-style requests are
/// made via a background session (except when uploading via `NSInputStream` or `NSData`,
/// or downloading to `NSData`, in which case, it is not possible) and all RPC-style request
/// are made using a foreground session.
///
/// Requests are made via one of the request methods below. The request is launched,
/// and a `DBTask` object is returned, from which response and progress handlers
/// can be added directly. By default, these handlers are added / executed using the main thread
/// queue and executed in a thread-safe manner (unless a custom delegate queue is supplied via
/// the `DBTransportClient` constructor). The `DBDelegate` class then retrieves the appropriate
/// handler and executes it.
///
/// While response handlers are not optional, they do not necessarily need to have been installed
/// by the time the SDK has received its server response. If this is the case, completion data will
/// be saved, and the handler will be executed with the completion data upon its installation.
/// Downloaded content will be moved from a temporary location to the final destination when the
/// response handler code is executed.
///
/// Argument serialization is performed with this class.
///
@interface DBTransportClient : DBTransportClientBase <DBTransportClient>

/// The delegate used to manage execution of all response / error code. By default, this
/// is an instance of `DBDelegate` with the main thread queue as delegate queue.
@property (nonatomic, readonly) DBDelegate * _Nonnull delegate;

/// A serial delegate queue used for executing blocks of code that touch state
/// shared across threads (mainly the request handlers storage).
@property (nonatomic, readonly) NSOperationQueue * _Nonnull delegateQueue;

/// The foreground session used to make all foreground requests (RPC style requests, upload
/// from `NSData` and `NSInputStream`, and download to `NSData`).
@property (nonatomic) NSURLSession * _Nonnull session;

/// The background session used to make all background requests (Upload and Download style
/// requests, except for upload from `NSData` and `NSInputStream`, and download to `NSData`).
@property (nonatomic) NSURLSession * _Nonnull backgroundSession;

/// The Dropbox OAuth2 access token used to make requests.
@property (nonatomic, copy) NSString * _Nullable accessToken;

#pragma mark - Constructors

///
/// `DBTransportClient` convenience constructor.
///
/// @param accessToken The Dropbox OAuth2 access token used to make requests.
///
/// @return An initialized `DBTransportClient` instance.
///
- (nonnull instancetype)initWithAccessToken:(NSString * _Nonnull)accessToken;

///
/// `DBTransportClient` convenience constructor.
///
/// @param accessToken The Dropbox OAuth2 access token used to make requests.
/// @param selectUser An additional authentication header field used when a team app with
/// the appropriate permissions "performs" user actions on behalf of a team member.
///
/// @return An initialized `DBTransportClient` instance.
///
- (nonnull instancetype)initWithAccessToken:(NSString * _Nullable)accessToken selectUser:(NSString * _Nullable)selectUser;

- (nonnull instancetype)initWithForceForegroundSession;

///
/// `DBTransportClient` full constructor.
///
/// @param accessToken The Dropbox OAuth2 access token used to make requests.
/// @param selectUser An additional authentication header field used when a team app with
/// the appropriate permissions "performs" user actions on behalf of a team member.
/// @param userAgent The user agent included in all requests. A general, non-unique identifier
/// useful for server analytics.
/// @param delegateQueue The queue used by `DBDelegate` for safely executing response code. If
/// nil, then `DBTransportClient` defaults to using the main queue. This must be a serial queue.
/// @param appKey The app key of the Dropbox API app being used. Used for "app" auth for certain routes.
/// @param appSecret The app secret of the Dropbox API app being used. Used for "app" auth for certain routes.
///
/// @return An initialized `DBTransportClient` instance.
///
- (nonnull instancetype)initWithAccessToken:(NSString * _Nullable)accessToken
                                 selectUser:(NSString * _Nullable)selectUser
                                  userAgent:(NSString * _Nullable)userAgent
                              delegateQueue:(NSOperationQueue * _Nullable)delegateQueue
                                     appKey:(NSString * _Nullable)appKey
                                  appSecret:(NSString * _Nullable)appSecret;

- (nonnull instancetype)initWithAccessToken:(NSString * _Nullable)accessToken
                                 selectUser:(NSString * _Nullable)selectUser
                                  userAgent:(NSString * _Nullable)userAgent
                              delegateQueue:(NSOperationQueue * _Nullable)delegateQueue
                     forceForegroundSession:(BOOL)forceForegroundSession
                                     appKey:(NSString * _Nullable)appKey
                                  appSecret:(NSString * _Nullable)appSecret;

@end
