///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

@class DBAccessToken;
@class DBOAuthResult;
@protocol DBSharedApplication;

#pragma mark - OAuth manager base

///
/// Platform-neutral manager for performing OAuth linking.
///
@interface DBOAuthManager : NSObject

#pragma mark - Shared instance accessors and mutators

///
/// Accessor method for `DBOAuthManager` shared instance.
///
/// Shared instance is used to authenticate users through OAuth2,
/// save access tokens, and retrieve access tokens.
///
/// @return The `DBOAuthManager` shared instance.
///
+ (DBOAuthManager * _Nullable)sharedOAuthManager;

///
/// Mutator method for `DBOAuthManager` shared instance.
///
/// Shared instance is used to authenticate users through OAuth2,
/// save access tokens, and retrieve access tokens.
///
/// @param sharedManager The updated reference to the `DBOAuthManager` shared
/// instance.
///
+ (void)sharedOAuthManager:(DBOAuthManager * _Nonnull)sharedManager;

#pragma mark - Constructors

///
/// `DBOAuthManager` convenience constructor.
///
/// @param appKey The app key from the developer console that identifies this app.
///
/// @return An initialized instance.
///
- (nonnull instancetype)initWithAppKey:(NSString * _Nonnull)appKey;

///
/// `DBOAuthManager` full constructor.
///
/// @param appKey The app key from the developer console that identifies this app.
/// @param host The host of the OAuth web flow.
///
/// @return An initialized instance.
///
- (nonnull instancetype)initWithAppKey:(NSString * _Nonnull)appKey host:(NSString * _Nonnull)host;

#pragma mark - Auth flow methods

///
/// Commences the authorization flow (platform-neutral).
///
/// Interfaces with platform-specific rendering logic via the `DBSharedApplication` protocol.
///
///
/// @param sharedApplication A platform-neutral shared application abstraction for rendering auth flow.
/// @param browserAuth Whether the auth flow should use an external web browser for auth or not. If not,
/// then an in-app webview is used instead.
///
- (void)authorizeFromSharedApplication:(id<DBSharedApplication> _Nonnull)sharedApplication
                           browserAuth:(BOOL)browserAuth;

///
/// Handles a redirect back into the application (from whichever auth flow was being used).
///
/// @param url The redirect URL to attempt to handle.
///
/// - returns nil if SDK cannot handle the redirect URL, otherwise returns an instance of `DBOAuthResult`.
///
- (DBOAuthResult * _Nullable)handleRedirectURL:(NSURL * _Nonnull)url;

#pragma mark - Keychain methods

///
/// Saves an access token to the `DBKeychain` class.
///
/// @param accessToken The access token to save.
///
/// @return Whether the save operation succeeded.
///
- (BOOL)storeAccessToken:(DBAccessToken * _Nonnull)accessToken;

///
/// Utility function to return an arbitrary access token from the `DBKeychain` class, if any exist.
///
/// @return the "first" access token found, if any, otherwise nil.
///
- (DBAccessToken * _Nullable)getFirstAccessToken;

///
/// Retrieves the access token for a particular user from the `DBKeychain` class.
///
/// @param owner The owner of the access token to retrieve. Either `account_id` or `team_id`.
///
/// @return An access token if present, otherwise nil.
///
- (DBAccessToken * _Nullable)getAccessToken:(NSString * _Nonnull)owner;

///
/// Retrieves all stored access tokens from the `DBKeychain` class.
///
/// @return a dictionary mapping owners (via `account_id` or `team_id`) to their access tokens.
///
- (NSDictionary<NSString *, DBAccessToken *> * _Nonnull)getAllAccessTokens;

///
/// Checks if there are any stored access tokens in the `DBKeychain` class.
///
/// @return Whether there are stored access tokens.
///
- (BOOL)hasStoredAccessTokens;

///
/// Deletes a specific access tokens from the `DBKeychain` class.
///
/// @param token The access token to delete.
///
/// @return Whether the delete operation succeeded.
///
- (BOOL)clearStoredAccessToken:(DBAccessToken * _Nonnull)token;

///
/// Deletes all stored access tokens in the `DBKeychain` class.
///
/// @return Whether the batch deletion operation succeeded.
///
- (BOOL)clearStoredAccessTokens;

@end

#pragma mark - OAuth manager base (macOS)

///
/// Platform-specific (macOS) manager for performing OAuth linking.
///
@interface DBDesktopOAuthManager : DBOAuthManager

@end

#pragma mark - OAuth manager base (iOS)

///
/// Platform-specific (iOS) manager for performing OAuth linking.
///
@interface DBMobileOAuthManager : DBOAuthManager

@end

#pragma mark - Access token class

///
/// A Dropbox OAuth2 access token.
///
/// Stores a unique identifying key (`account_id` or `team_id`) for
/// storing in `DBKeychain`.
///
@interface DBAccessToken : NSObject

/// The OAuth2 access token.
@property (nonatomic, readonly, copy) NSString * _Nonnull accessToken;

/// The unique identifier of the access token used for storing in `DBKeychain`.
/// Either the `account_id` (if user app) or the `team_id` if (team app).
@property (nonatomic, readonly, copy) NSString * _Nonnull uid;

///
/// DBAccessToken full constructor.
///
/// @param accessToken The OAuth2 access token retrieved from the auth flow.
/// @param uid The unique identifier used to store in `DBKeychain`.
///
/// @return An initialized instance.
///
- (nonnull instancetype)initWithAccessToken:(NSString * _Nonnull)accessToken uid:(NSString * _Nonnull)uid;

@end
