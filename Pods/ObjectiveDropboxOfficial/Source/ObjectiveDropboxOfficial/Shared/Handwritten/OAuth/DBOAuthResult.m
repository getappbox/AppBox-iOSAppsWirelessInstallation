///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBOAuthResult.h"
#import "DBOAuthManager.h"

@implementation DBOAuthResult

@synthesize accessToken = _accessToken;
@synthesize errorType = _errorType;
@synthesize errorDescription = _errorDescription;

#pragma mark - Constructors

+ (DBOAuthErrorType)getErrorType:(NSString *)errorType {
  static NSDictionary<NSString *, NSNumber *> *errorTypeLookup;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    errorTypeLookup = @{
      @"unauthorized_client" : @(DBAuthUnauthorizedClient),
      @"access_denied" : @(DBAuthAccessDenied),
      @"unsupported_response_type" : @(DBAuthUnsupportedResponseType),
      @"invalid_scope" : @(DBAuthInvalidScope),
      @"server_error" : @(DBAuthServerError),
      @"temporarily_unavailable" : @(DBAuthTemporarilyUnavailable),
      @"invalid_request" : @(DBAuthInvalidRequest),
      @"invalid_client" : @(DBAuthInvalidClient),
      @"invalid_grant" : @(DBAuthInvalidGrant),
      @"unsupported_grant_type" : @(DBAuthUnsupportedGrantType),
      @"inconsistent_state" : @(DBAuthInconsistentState),
    };
  });
  return (DBOAuthErrorType)[errorTypeLookup[errorType] intValue] ?: DBAuthUnknown;
}

- (instancetype)initWithSuccess:(DBAccessToken *)accessToken {
  self = [super init];
  if (self) {
    _tag = DBAuthSuccess;
    _accessToken = accessToken;
  }
  return self;
}

- (instancetype)initWithError:(NSString *)errorType errorDescription:(NSString *)errorDescription {
  return [self initWithErrorType:[[self class] getErrorType:errorType] errorDescription:errorDescription];
}

- (instancetype)initWithErrorType:(DBOAuthErrorType)errorType errorDescription:(nullable NSString *)errorDescription {
  self = [super init];
  if (self) {
    _tag = DBAuthError;
    _errorType = errorType;
    _errorDescription = errorDescription;
  }
  return self;
}

- (instancetype)initWithCancel {
  self = [super init];
  if (self) {
    _tag = DBAuthCancel;
  }
  return self;
}

+ (DBOAuthResult *)unknownErrorWithErrorDescription:(NSString *)errorDescription {
  return [[DBOAuthResult alloc] initWithErrorType:DBAuthUnknown errorDescription:errorDescription];
}

#pragma mark - Tag state methods

- (BOOL)isSuccess {
  return _tag == DBAuthSuccess;
}

- (BOOL)isError {
  return _tag == DBAuthError;
}

- (BOOL)isCancel {
  return _tag == DBAuthCancel;
}

#pragma mark - Tag name method

- (NSString *)tagName {
  switch (_tag) {
  case DBAuthSuccess:
    return @"DBAuthSuccess";
  case DBAuthError:
    return @"DBAuthError";
  case DBAuthCancel:
    return @"DBAuthCancel";
  }

  @throw([NSException exceptionWithName:@"InvalidTagEnum" reason:@"Tag has an invalid value." userInfo:nil]);
}

#pragma mark - Instance variable accessors

- (DBAccessToken *)accessToken {
  if (_tag != DBAuthSuccess) {
    [NSException raise:@"IllegalStateException"
                format:@"Invalid tag: required `DBAuthSuccess`, but was %@.", [self tagName]];
  }
  return _accessToken;
}

- (DBOAuthErrorType)errorType {
  if (_tag != DBAuthError) {
    [NSException raise:@"IllegalStateException"
                format:@"Invalid tag: required `DBAuthError`, but was %@.", [self tagName]];
  }
  return _errorType;
}

- (NSString *)errorDescription {
  if (_tag != DBAuthError) {
    [NSException raise:@"IllegalStateException"
                format:@"Invalid tag: required `DBAuthError`, but was %@.", [self tagName]];
  }
  return _errorDescription;
}

- (NSError *)nsError {
  if (_tag != DBAuthError) {
    [NSException raise:@"IllegalStateException"
                format:@"Invalid tag: required `DBAuthError`, but was %@.", [self tagName]];
  }
  return [NSError errorWithDomain:@"com.dropbox.dropbox_sdk_obj_c.oauth.error" code:_errorType userInfo:nil];
}

#pragma mark - Description method

- (NSString *)description {
  switch (_tag) {
  case DBAuthSuccess:
    return [NSString stringWithFormat:@"Success:[Token: %@]", _accessToken.accessToken];
  case DBAuthError:
    return
        [NSString stringWithFormat:@"Error:[ErrorType: %ld ErrorDescription: %@]", (long)_errorType, _errorDescription];
  case DBAuthCancel:
    return [NSString stringWithFormat:@"Cancel:[]"];
  }

  @throw([NSException exceptionWithName:@"InvalidTagEnum" reason:@"Tag has an invalid value." userInfo:nil]);
}

@end
