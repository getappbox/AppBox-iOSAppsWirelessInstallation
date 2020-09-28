///
/// Copyright (c) 2020 Dropbox, Inc. All rights reserved.
///

#import "DBOAuthUtils.h"

#import "DBOAuthConstants.h"
#import "DBOAuthPKCESession.h"
#import "DBScopeRequest+Protected.h"

@implementation DBOAuthUtils

+ (NSArray<NSURLQueryItem *> *)createPkceCodeFlowParamsForAuthSession:(DBOAuthPKCESession *)authSession {
  NSMutableArray<NSURLQueryItem *> *params = [NSMutableArray new];
  DBScopeRequest *scopeRequest = authSession.scopeRequest;
  NSString *scopeString = scopeRequest.scopeString;
  if (scopeString) {
    [params addObject:[NSURLQueryItem queryItemWithName:kDBScopeKey value:scopeString]];
  }
  if (scopeRequest.includeGrantedScopes) {
    [params addObject:[NSURLQueryItem queryItemWithName:kDBIncludeGrantedScopesKey value:scopeRequest.scopeType]];
  }
  DBPkceData *pkceData = authSession.pkceData;
  [params addObjectsFromArray:@[
    [NSURLQueryItem queryItemWithName:kDBCodeChallengeKey value:pkceData.codeChallenge],
    [NSURLQueryItem queryItemWithName:kDBCodeChallengeMethodKey value:pkceData.codeChallengeMethod],
    [NSURLQueryItem queryItemWithName:kDBTokenAccessTypeKey value:authSession.tokenAccessType],
    [NSURLQueryItem queryItemWithName:kDBResponseTypeKey value:authSession.responseType],
  ]];
  return params;
}

// Extracts auth response parameters from URL and removes percent encoding.
// Response parameters from DAuth via the Dropbox app are in the query component.
+ (NSDictionary<NSString *, NSString *> *)extractDAuthResponseFromUrl:(NSURL *)url {
  return [self extractQueryParamsFromUrl:url.absoluteString];
}

// Extracts auth response parameters from URL and removes percent encoding.
// Response parameters OAuth 2 code flow (RFC6749 4.1.2) are in the query component.
+ (NSDictionary<NSString *, NSString *> *)extractOAuthResponseFromCodeFlowUrl:(NSURL *)url {
  return [self extractQueryParamsFromUrl:url.absoluteString];
}

// Extracts auth response parameters from URL and removes percent encoding.
// Response parameters from OAuth 2 token flow (RFC6749 4.2.2) are in the fragment component.
+ (NSDictionary<NSString *, NSString *> *)extractOAuthResponseFromTokenFlowUrl:(NSURL *)url {
  NSURLComponents *components = [[NSURLComponents alloc] initWithString:url.absoluteString];
  if (components.fragment) {
    // Create a query only URL string and extract its individual query parameters.
    return [self extractQueryParamsFromUrl:[NSString stringWithFormat:@"?%@", components.fragment]];
  } else {
    return @{};
  }
}

/// Extracts auth response parameters from URL and removes percent encoding.
+ (NSDictionary<NSString *, NSString *> *)extractQueryParamsFromUrl:(NSString *)url {
  NSURLComponents *components = [[NSURLComponents alloc] initWithString:url];
  NSMutableDictionary<NSString *, NSString *> *dict = [NSMutableDictionary new];
  for (NSURLQueryItem *item in components.queryItems) {
    [dict setValue:item.value forKey:item.name];
  }
  return dict;
}

@end
