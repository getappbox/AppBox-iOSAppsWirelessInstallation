///
/// Copyright (c) 2020 Dropbox, Inc. All rights reserved.
///

#import "DBOAuthPKCESession.h"

#import "DBScopeRequest+Protected.h"
#import <CommonCrypto/CommonDigest.h>

@implementation DBPkceData

- (instancetype)init {
  self = [super init];
  if (self) {
    _codeVerifier = [DBPkceData randomStringOfLength:128];
    _codeChallenge = [DBPkceData codeChallengeFromCodeVerifier:_codeVerifier];
    _codeChallengeMethod = @"S256";
  }
  return self;
}

+ (NSString *)randomStringOfLength:(NSUInteger)length {
  static NSString *alphanumerics = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  NSMutableString *randomString = [NSMutableString stringWithCapacity:length];
  for (NSUInteger i = 0; i < length; i++) {
    [randomString
        appendFormat:@"%c", [alphanumerics characterAtIndex:arc4random_uniform((uint32_t)alphanumerics.length)]];
  }
  return randomString;
}

+ (NSString *)codeChallengeFromCodeVerifier:(NSString *)codeVerifier {
  // Creates code challenge according to [RFC7636 4.2] (https://tools.ietf.org/html/rfc7636#section-4.2)
  // 1. Covert code verifier to ascii encoded string.
  // 2. Compute the SHA256 hash of the ascii string.
  // 3. Base64 encode the resulting hash.
  // 4. Make the Base64 string URL safe by replacing a few characters. (https://tools.ietf.org/html/rfc4648#section-5)
  const char *asciiString = [codeVerifier cStringUsingEncoding:NSASCIIStringEncoding];
  NSData *data = [NSData dataWithBytes:asciiString length:strlen(asciiString)];
  unsigned char digest[CC_SHA256_DIGEST_LENGTH] = {0};
  CC_SHA256(data.bytes, (CC_LONG)data.length, digest);
  NSData *sha256Data = [NSData dataWithBytes:digest length:CC_SHA256_DIGEST_LENGTH];
  NSString *base64String = [sha256Data base64EncodedStringWithOptions:kNilOptions];
  base64String = [base64String stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
  base64String = [base64String stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
  base64String = [base64String stringByReplacingOccurrencesOfString:@"=" withString:@""];
  return base64String;
}

@end

@implementation DBOAuthPKCESession

- (instancetype)initWithScopeRequest:(DBScopeRequest *)scopeRequest {
  self = [super init];
  if (self) {
    _scopeRequest = scopeRequest;
    _pkceData = [[DBPkceData alloc] init];
    _tokenAccessType = @"offline";
    _responseType = @"code";
    _state = [DBOAuthPKCESession createStateWithPkceData:_pkceData
                                            scopeRequest:scopeRequest
                                         tokenAccessType:_tokenAccessType];
  }
  return self;
}

+ (NSString *)createStateWithPkceData:(DBPkceData *)pkceData
                         scopeRequest:(nullable DBScopeRequest *)scopeRequest
                      tokenAccessType:(NSString *)tokenAccessType {
  NSMutableArray<NSString *> *state =
      [@[ @"oauth2code", pkceData.codeChallenge, pkceData.codeChallengeMethod, tokenAccessType ] mutableCopy];
  if (scopeRequest) {
    NSString *scopeString = [scopeRequest scopeString];
    if (scopeString) {
      [state addObject:scopeString];
    }
    if (scopeRequest.includeGrantedScopes) {
      [state addObject:scopeRequest.scopeType];
    }
  }
  return [state componentsJoinedByString:@":"];
}

@end
