///
/// Copyright (c) 2020 Dropbox, Inc. All rights reserved.
///

#import "DBScopeRequest.h"

@interface DBScopeRequest ()

@property (nonatomic, readonly) NSString *scopeType;
@property (nonatomic, readonly, assign) BOOL includeGrantedScopes;
@property (nonatomic, readonly) NSArray<NSString *> *scopes;

@end

@implementation DBScopeRequest

- (instancetype)initWithScopeType:(DBScopeType)scopeType
                           scopes:(NSArray<NSString *> *)scopes
             includeGrantedScopes:(BOOL)includeGrantedScopes {
  self = [super init];
  if (self) {
    _scopeType = [DBScopeRequest stringFromScopeType:scopeType];
    _scopes = scopes;
    _includeGrantedScopes = includeGrantedScopes;
  }
  return self;
}

- (NSString *)scopeString {
  if (_scopes.count == 0) {
    return nil;
  } else {
    return [_scopes componentsJoinedByString:@" "];
  }
}

+ (NSString *)stringFromScopeType:(DBScopeType)scopeType {
  switch (scopeType) {
  case DBScopeTypeTeam:
    return @"team";
  case DBScopeTypeUser:
    return @"user";
  }
}

@end
