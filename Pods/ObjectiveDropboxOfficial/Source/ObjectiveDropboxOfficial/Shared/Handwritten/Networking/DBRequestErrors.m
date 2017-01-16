///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBAUTHAccessError.h"
#import "DBAUTHAuthError.h"
#import "DBAUTHRateLimitError.h"
#import "DBOAuth.h"
#import "DBRequestErrors.h"

#pragma mark - HTTP error

@implementation DBRequestHttpError

- (instancetype)init:(NSString *)requestId statusCode:(NSNumber *)statusCode errorContent:(NSString *)errorContent {
  self = [super init];
  if (self) {
    _requestId = requestId;
    _statusCode = statusCode;
    _errorContent = errorContent;
  }
  return self;
}

- (NSString *)description {
  NSDictionary *values = @{
    @"RequestId" : _requestId ?: @"nil",
    @"StatusCode" : _statusCode ?: @"nil",
    @"ErrorContent" : _errorContent ?: @"nil"
  };
  return [NSString stringWithFormat:@"DropboxHttpError[%@];", values];
}

@end

#pragma mark - Bad Input error

@implementation DBRequestBadInputError

- (instancetype)init:(NSString *)requestId statusCode:(NSNumber *)statusCode errorContent:(NSString *)errorContent {
  return [super init:requestId statusCode:statusCode errorContent:errorContent];
}

- (NSString *)description {
  NSDictionary *values = @{
    @"RequestId" : self.requestId ?: @"nil",
    @"StatusCode" : self.statusCode ?: @"nil",
    @"ErrorContent" : self.errorContent ?: @"nil"
  };
  return [NSString stringWithFormat:@"DropboxBadInputError[%@];", values];
}

@end

#pragma mark - Auth error

@implementation DBRequestAuthError

- (instancetype)init:(NSString *)requestId
             statusCode:(NSNumber *)statusCode
           errorContent:(NSString *)errorContent
    structuredAuthError:(DBAUTHAuthError *)structuredAuthError {
  self = [super init:requestId statusCode:statusCode errorContent:errorContent];
  if (self) {
    _structuredAuthError = structuredAuthError;
  }
  return self;
}

- (NSString *)description {
  NSDictionary *values = @{
    @"RequestId" : self.requestId ?: @"nil",
    @"StatusCode" : self.statusCode ?: @"nil",
    @"ErrorContent" : self.errorContent ?: @"nil",
    @"StructuredAuthError" : [NSString stringWithFormat:@"%@", _structuredAuthError] ?: @"nil"
  };
  return [NSString stringWithFormat:@"DropboxAuthError[%@];", values];
}

@end

#pragma mark - Access error

@implementation DBRequestAccessError

- (instancetype)init:(NSString *)requestId
               statusCode:(NSNumber *)statusCode
             errorContent:(NSString *)errorContent
    structuredAccessError:(DBAUTHAccessError *)structuredAccessError {
  self = [super init:requestId statusCode:statusCode errorContent:errorContent];
  if (self) {
    _structuredAccessError = structuredAccessError;
  }
  return self;
}

- (NSString *)description {
  NSDictionary *values = @{
    @"RequestId" : self.requestId ?: @"nil",
    @"StatusCode" : self.statusCode ?: @"nil",
    @"ErrorContent" : self.errorContent ?: @"nil",
    @"StructuredAccessError" : [NSString stringWithFormat:@"%@", _structuredAccessError] ?: @"nil"
  };
  return [NSString stringWithFormat:@"DropboxAccessError[%@];", values];
}

@end

#pragma mark - Rate Limit error

@implementation DBRequestRateLimitError

- (instancetype)init:(NSString *)requestId
                  statusCode:(NSNumber *)statusCode
                errorContent:(NSString *)errorContent
    structuredRateLimitError:(DBAUTHRateLimitError *)structuredRateLimitError
                     backoff:(NSNumber *)backoff {
  self = [super init:requestId statusCode:statusCode errorContent:errorContent];
  if (self) {
    _structuredRateLimitError = structuredRateLimitError;
    _backoff = backoff;
  }
  return self;
}

- (NSString *)description {
  NSDictionary *values = @{
    @"RequestId" : self.requestId ?: @"nil",
    @"StatusCode" : self.statusCode ?: @"nil",
    @"ErrorContent" : self.errorContent ?: @"nil",
    @"StructuredRateLimitError" : _structuredRateLimitError ?: @"nil",
    @"BackOff" : _backoff ?: @"nil"
  };
  return [NSString stringWithFormat:@"DropboxRateLimitError[%@];", values];
}

@end

#pragma mark - Internal Server error

@implementation DBRequestInternalServerError

- (instancetype)init:(NSString *)requestId statusCode:(NSNumber *)statusCode errorContent:(NSString *)errorContent {
  return [super init:requestId statusCode:statusCode errorContent:errorContent];
}

- (NSString *)description {
  NSDictionary *values = @{
    @"RequestId" : self.requestId ?: @"nil",
    @"StatusCode" : self.statusCode ?: @"nil",
    @"ErrorContent" : self.errorContent ?: @"nil"
  };
  return [NSString stringWithFormat:@"DropboxInternalServerError[%@];", values];
}

@end

#pragma mark - Client error

@implementation DBRequestClientError

- (instancetype)init:(NSError *)nsError {
  self = [super init];
  if (self) {
    _nsError = nsError;
  }
  return self;
}

- (NSString *)description {
  NSDictionary *values = @{ @"NSError" : _nsError ?: @"nil" };
  return [NSString stringWithFormat:@"DropboxClientError[%@];", values];
}

@end

#pragma mark - DBRequestError generic error

@implementation DBRequestError

#pragma mark - Constructors

- (instancetype)initAsHttpError:(NSString *)requestId
                     statusCode:(NSNumber *)statusCode
                   errorContent:(NSString *)errorContent {
  return [self init:DBRequestErrorHttp
                     requestId:requestId
                    statusCode:statusCode
                  errorContent:errorContent
           structuredAuthError:nil
         structuredAccessError:nil
      structuredRateLimitError:nil
                       backoff:nil
                       nsError:nil];
}

- (instancetype)initAsBadInputError:(NSString *)requestId
                         statusCode:(NSNumber *)statusCode
                       errorContent:(NSString *)errorContent {
  return [self init:DBRequestErrorBadInput
                     requestId:requestId
                    statusCode:statusCode
                  errorContent:errorContent
           structuredAuthError:nil
         structuredAccessError:nil
      structuredRateLimitError:nil
                       backoff:nil
                       nsError:nil];
}

- (instancetype)initAsAuthError:(NSString *)requestId
                     statusCode:(NSNumber *)statusCode
                   errorContent:(NSString *)errorContent
            structuredAuthError:(DBAUTHAuthError *)structuredAuthError {
  return [self init:DBRequestErrorAuth
                     requestId:requestId
                    statusCode:statusCode
                  errorContent:errorContent
           structuredAuthError:structuredAuthError
         structuredAccessError:nil
      structuredRateLimitError:nil
                       backoff:nil
                       nsError:nil];
}

- (instancetype)initAsAccessError:(NSString *)requestId
                       statusCode:(NSNumber *)statusCode
                     errorContent:(NSString *)errorContent
            structuredAccessError:(DBAUTHAccessError *)structuredAccessError {
  return [self init:DBRequestErrorAuth
                     requestId:requestId
                    statusCode:statusCode
                  errorContent:errorContent
           structuredAuthError:nil
         structuredAccessError:structuredAccessError
      structuredRateLimitError:nil
                       backoff:nil
                       nsError:nil];
}

- (instancetype)initAsRateLimitError:(NSString *)requestId
                          statusCode:(NSNumber *)statusCode
                        errorContent:(NSString *)errorContent
            structuredRateLimitError:(DBAUTHRateLimitError *)structuredRateLimitError
                             backoff:(NSNumber *)backoff {
  return [self init:DBRequestErrorRateLimit
                     requestId:requestId
                    statusCode:statusCode
                  errorContent:errorContent
           structuredAuthError:nil
         structuredAccessError:nil
      structuredRateLimitError:structuredRateLimitError
                       backoff:backoff
                       nsError:nil];
}

- (instancetype)initAsInternalServerError:(NSString *)requestId
                               statusCode:(NSNumber *)statusCode
                             errorContent:(NSString *)errorContent {
  return [self init:DBRequestErrorInternalServer
                     requestId:requestId
                    statusCode:statusCode
                  errorContent:errorContent
           structuredAuthError:nil
         structuredAccessError:nil
      structuredRateLimitError:nil
                       backoff:nil
                       nsError:nil];
}

- (instancetype)initAsClientError:(NSError *)nsError {
  return [self init:DBRequestErrorClient
                     requestId:nil
                    statusCode:nil
                  errorContent:nil
           structuredAuthError:nil
         structuredAccessError:nil
      structuredRateLimitError:nil
                       backoff:nil
                       nsError:nsError];
}

- (instancetype)init:(DBRequestErrorTag)tag
                   requestId:(NSString *)requestId
                  statusCode:(NSNumber *)statusCode
                errorContent:(NSString *)errorContent
         structuredAuthError:(DBAUTHAuthError *)structuredAuthError
       structuredAccessError:(DBAUTHAccessError *)structuredAccessError
    structuredRateLimitError:(DBAUTHRateLimitError *)structuredRateLimitError
                     backoff:(NSNumber *)backoff
                     nsError:(NSError *)nsError {
  self = [super init];
  if (self) {
    _tag = tag;
    _requestId = requestId;
    _statusCode = statusCode;
    _errorContent = errorContent;
    _structuredAuthError = structuredAuthError;
    _structuredAccessError = structuredAccessError;
    _structuredRateLimitError = structuredRateLimitError;
    _backoff = backoff;
    _nsError = nsError;
  }
  return self;
}

#pragma mark - Tag state methods

- (BOOL)isHttpError {
  return _tag == DBRequestErrorHttp;
}

- (BOOL)isBadInputError {
  return _tag == DBRequestErrorBadInput;
}

- (BOOL)isAuthError {
  return _tag == DBRequestErrorAuth;
}

- (BOOL)isAccessError {
  return _tag == DBRequestErrorAccess;
}

- (BOOL)isRateLimitError {
  return _tag == DBRequestErrorRateLimit;
}

- (BOOL)isInternalServerError {
  return _tag == DBRequestErrorInternalServer;
}

- (BOOL)isClientError {
  return _tag == DBRequestErrorClient;
}

#pragma mark - Error subtype retrieval methods

- (DBRequestHttpError * _Nonnull)asHttpError {
  if (![self isHttpError]) {
    [NSException raise:@"IllegalStateException"
                format:@"Invalid tag: required `DBRequestErrorHttp`, but was %@.", [self tagName]];
  }
  return [[DBRequestHttpError alloc] init:_requestId statusCode:_statusCode errorContent:_errorContent];
}

- (DBRequestBadInputError * _Nonnull)asBadInputError {
  if (![self isBadInputError]) {
    [NSException raise:@"IllegalStateException"
                format:@"Invalid tag: required `DBRequestErrorBadInput`, but was %@.", [self tagName]];
  }
  return [[DBRequestBadInputError alloc] init:_requestId statusCode:_statusCode errorContent:_errorContent];
}

- (DBRequestAuthError * _Nonnull)asAuthError {
  if (![self isAuthError]) {
    [NSException raise:@"IllegalStateException"
                format:@"Invalid tag: required `DBRequestErrorAuth`, but was %@.", [self tagName]];
  }
  return [[DBRequestAuthError alloc] init:_requestId
                               statusCode:_statusCode
                             errorContent:_errorContent
                      structuredAuthError:_structuredAuthError];
}

- (DBRequestAccessError * _Nonnull)asAccessError {
  if (![self isAccessError]) {
    [NSException raise:@"IllegalStateException"
                format:@"Invalid tag: required `DBRequestErrorAccess`, but was %@.", [self tagName]];
  }
  return [[DBRequestAccessError alloc] init:_requestId
                                 statusCode:_statusCode
                               errorContent:_errorContent
                      structuredAccessError:_structuredAccessError];
}

- (DBRequestRateLimitError * _Nonnull)asRateLimitError {
  if (![self isRateLimitError]) {
    [NSException raise:@"IllegalStateException"
                format:@"Invalid tag: required `DBRequestErrorRateLimit`, but was %@.", [self tagName]];
  }
  return [[DBRequestRateLimitError alloc] init:_requestId
                                    statusCode:_statusCode
                                  errorContent:_errorContent
                      structuredRateLimitError:_structuredRateLimitError
                                       backoff:_backoff];
}

- (DBRequestInternalServerError * _Nonnull)asInternalServerError {
  if (![self isInternalServerError]) {
    [NSException raise:@"IllegalStateException"
                format:@"Invalid tag: required `DBRequestErrorInternalServer`, but was %@.", [self tagName]];
  }
  return [[DBRequestInternalServerError alloc] init:_requestId statusCode:_statusCode errorContent:_errorContent];
}

- (DBRequestClientError * _Nonnull)asClientError {
  if (![self isClientError]) {
    [NSException raise:@"IllegalStateException"
                format:@"Invalid tag: required `DBRequestErrorClient`, but was %@.", [self tagName]];
  }
  return [[DBRequestClientError alloc] init:_nsError];
}

#pragma mark - Tag name method

- (NSString *)tagName {
  switch (_tag) {
  case DBRequestErrorHttp:
    return @"DBRequestErrorHttp";
  case DBRequestErrorBadInput:
    return @"DBRequestErrorBadInput";
  case DBRequestErrorAuth:
    return @"DBRequestErrorAuth";
  case DBRequestErrorAccess:
    return @"DBRequestErrorAccess";
  case DBRequestErrorRateLimit:
    return @"DBRequestErrorRateLimit";
  case DBRequestErrorInternalServer:
    return @"DBRequestErrorInternalServer";
  case DBRequestErrorClient:
    return @"DBRequestErrorClient";
  }

  @throw([NSException exceptionWithName:@"InvalidTagEnum" reason:@"Tag has an invalid value." userInfo:nil]);
}

#pragma mark - Description method

- (NSString *)description {
  switch (_tag) {
  case DBRequestErrorHttp:
    return [NSString stringWithFormat:@"%@", [self asHttpError]];
  case DBRequestErrorBadInput:
    return [NSString stringWithFormat:@"%@", [self asBadInputError]];
  case DBRequestErrorAuth:
    return [NSString stringWithFormat:@"%@", [self asAuthError]];
  case DBRequestErrorAccess:
    return [NSString stringWithFormat:@"%@", [self asAccessError]];
  case DBRequestErrorRateLimit:
    return [NSString stringWithFormat:@"%@", [self asRateLimitError]];
  case DBRequestErrorInternalServer:
    return [NSString stringWithFormat:@"%@", [self asInternalServerError]];
  case DBRequestErrorClient:
    return [NSString stringWithFormat:@"%@", [self asClientError]];
  }

  return [NSString stringWithFormat:@"GenericDropboxError[%@];", [self tagName]];
}

@end
