///
/// Copyright (c) 2020 Dropbox, Inc. All rights reserved.
///

#import "DBScopeRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface DBScopeRequest (Protected)

/// String value of DBScopeType.
@property (nonatomic, readonly, copy) NSString *scopeType;
/// Boolean indicating whether to keep all previously granted scopes.
@property (nonatomic, readonly, assign) BOOL includeGrantedScopes;

/// String representation of the scopes, used in URL query. Nil if no scopes requested.
- (nullable NSString *)scopeString;

@end

NS_ASSUME_NONNULL_END
