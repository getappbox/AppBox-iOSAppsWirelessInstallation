///
/// Copyright (c) 2020 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

@class DBScopeRequest;

NS_ASSUME_NONNULL_BEGIN

/// PKCE data for OAuth 2 Authorization Code Flow.
@interface DBPkceData : NSObject

// A random string generated for each code flow.
@property (nonatomic, readonly) NSString *codeVerifier;
// A string derived from codeVerifier by using BASE64URL-ENCODE(SHA256(ASCII(code_verifier))).
@property (nonatomic, readonly) NSString *codeChallenge;
// The hash method used to generate codeChallenge.
@property (nonatomic, readonly) NSString *codeChallengeMethod;

@end

/// Object that contains all the necessary data of an OAuth 2 Authorization Code Flow with PKCE.
@interface DBOAuthPKCESession : NSObject

// The scope request for this auth session.
@property (nonatomic, readonly, nullable) DBScopeRequest *scopeRequest;
// PKCE data generated for this auth session.
@property (nonatomic, readonly) DBPkceData *pkceData;
// A string of colon-delimited options/state - used primarily to indicate if the token type to be returned.
@property (nonatomic, readonly) NSString *state;
// Token access type, hardcoded to "offline" to indicate short-lived access token + refresh token.
@property (nonatomic, readonly) NSString *tokenAccessType;
// Type of the auth response, hardcoded to "code" to indicate code flow.
@property (nonatomic, readonly) NSString *responseType;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithScopeRequest:(nullable DBScopeRequest *)scopeRequest NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
