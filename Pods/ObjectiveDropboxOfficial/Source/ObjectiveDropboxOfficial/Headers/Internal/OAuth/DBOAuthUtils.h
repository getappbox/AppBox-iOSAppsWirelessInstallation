///
/// Copyright (c) 2020 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

@class DBOAuthPKCESession;

NS_ASSUME_NONNULL_BEGIN

/// Contains utility methods used in auth flow. e.g. method to construct URL query.
@interface DBOAuthUtils : NSObject

/// Creates URL query items needed by PKCE code flow.
+ (NSArray<NSURLQueryItem *> *)createPkceCodeFlowParamsForAuthSession:(DBOAuthPKCESession *)authSession;

/// Extracts auth response parameters from URL and removes percent encoding.
/// Response parameters from DAuth via the Dropbox app are in the query component.
+ (NSDictionary<NSString *, NSString *> *)extractDAuthResponseFromUrl:(NSURL *)url;

/// Extracts auth response parameters from URL and removes percent encoding.
/// Response parameters OAuth 2 code flow (RFC6749 4.1.2) are in the query component.
+ (NSDictionary<NSString *, NSString *> *)extractOAuthResponseFromCodeFlowUrl:(NSURL *)url;

/// Extracts auth response parameters from URL and removes percent encoding.
/// Response parameters from OAuth 2 token flow (RFC6749 4.2.2) are in the fragment component.
+ (NSDictionary<NSString *, NSString *> *)extractOAuthResponseFromTokenFlowUrl:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
