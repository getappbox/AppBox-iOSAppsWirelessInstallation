///
/// Copyright (c) 2020 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, DBScopeType) {
  DBScopeTypeTeam = 0,
  DBScopeTypeUser,
};

/// Contains the information of requested scopes.
@interface DBScopeRequest : NSObject

- (instancetype)init NS_UNAVAILABLE;

///
/// Designated Initializer.
///
/// @param scopeType Type of the requested scopes.
/// @param scopes A list of scope returned by Dropbox server. Each scope correspond to a group of API endpoints.
///        To call one API endpoint you have to obtains the scope first otherwise you will get HTTP 401.
/// @param includeGrantedScopes If false, Dropbox will give you the scopes in scopes array.
///        Otherwise Dropbox server will return a token with all scopes user previously granted your app
///        together with the new scopes.
- (instancetype)initWithScopeType:(DBScopeType)scopeType
                           scopes:(NSArray<NSString *> *)scopes
             includeGrantedScopes:(BOOL)includeGrantedScopes NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
