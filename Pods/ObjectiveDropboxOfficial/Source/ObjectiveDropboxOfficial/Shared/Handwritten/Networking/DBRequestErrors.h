///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

@class DBAUTHAccessError;
@class DBAUTHAuthError;
@class DBAUTHRateLimitError;

#pragma mark - HTTP error

///
/// Http request error.
///
/// Contains relevant information regarding a failed network
/// request. All error types except for DBClientError extend this
/// class as children. Initialized in the event of a generic,
/// unidentified HTTP error.
///
@interface DBRequestHttpError : NSObject

/// The Dropbox request id of the network call. This is useful to Dropbox
/// for debugging issues with Dropbox's SDKs and API. Please include the
/// value of this field when submitting technical support inquiries to
/// Dropbox.
@property (nonatomic, readonly, copy) NSString * _Nonnull requestId;

/// The HTTP response status code of the request.
@property (nonatomic, readonly) NSNumber * _Nonnull statusCode;

/// A string representation of the error body received in the reponse.
/// If for a route-specific error, this field will be the value of the
/// "error_summary" key.
@property (nonatomic, readonly, copy) NSString * _Nonnull errorContent;

///
/// DBRequestHttpError full constructor.
///
/// @param requestId The Dropbox request id of the network call. This is
/// useful to Dropbox for debugging issues with Dropbox's SDKs and API.
/// @param statusCode The HTTP response status code of the request.
/// @param errorContent A string representation of the error body received in the reponse.
/// If for a route-specific error, this field will be the value of the "error_summary" key.
///
/// @return An initialized DBRequestHttpError instance.
///
- (nonnull instancetype)init:(NSString * _Nonnull)requestId
                  statusCode:(NSNumber * _Nonnull)statusCode
                errorContent:(NSString * _Nonnull)errorContent;

///
/// Description method.
///
/// @return A human-readable representation of the current DBRequestHttpError object.
///
- (NSString * _Nonnull)description;

@end

#pragma mark - Bad Input error

///
/// Bad Input request error.
///
/// Contains relevant information regarding a failed network
/// request. Initialized in the event of an HTTP 400 response.
/// Extends DBRequestHttpError.
///
@interface DBRequestBadInputError : DBRequestHttpError

///
/// DBRequestBadInputError full constructor.
///
/// @param requestId The Dropbox request id of the network call. This is
/// useful to Dropbox for debugging issues with Dropbox's SDKs and API.
/// @param statusCode The HTTP response status code of the request.
/// @param errorContent A string representation of the error body received in the reponse.
/// If for a route-specific error, this field will be the value of the "error_summary" key.
///
/// @return An initialized DBRequestBadInputError instance.
///
- (nonnull instancetype)init:(NSString * _Nonnull)requestId
                  statusCode:(NSNumber * _Nonnull)statusCode
                errorContent:(NSString * _Nonnull)errorContent;

///
/// Description method.
///
/// @return A human-readable representation of the current DBRequestBadInputError object.
///
- (NSString * _Nonnull)description;

@end

#pragma mark - Auth error

///
/// Auth request error.
///
/// Contains relevant information regarding a failed network
/// request. Initialized in the event of an HTTP 401 response.
/// Extends DBRequestHttpError.
///
@interface DBRequestAuthError : DBRequestHttpError

/// The structured object returned by the Dropbox API in the event of a 401 auth
/// error.
@property (nonatomic, readonly) DBAUTHAuthError * _Nonnull structuredAuthError;

///
/// DBRequestAuthError full constructor.
///
/// @param requestId The Dropbox request id of the network call. This is
/// useful to Dropbox for debugging issues with Dropbox's SDKs and API.
/// @param statusCode The HTTP response status code of the request.
/// @param errorContent A string representation of the error body received in the reponse.
/// If for a route-specific error, this field will be the value of the "error_summary" key.
/// @param structuredAuthError The structured object returned by the Dropbox API in the
/// event of a 401 auth error.
///
/// @return An initialized DBRequestAuthError instance.
///
- (nonnull instancetype)init:(NSString * _Nonnull)requestId
                  statusCode:(NSNumber * _Nonnull)statusCode
                errorContent:(NSString * _Nonnull)errorContent
         structuredAuthError:(DBAUTHAuthError * _Nonnull)structuredAuthError;

///
/// Description method.
///
/// @return A human-readable representation of the current DBRequestAuthError object.
///
- (NSString * _Nonnull)description;

@end

#pragma mark - Access error

///
/// Access request error.
///
/// Contains relevant information regarding a failed network
/// request. Initialized in the event of an HTTP 403 response.
/// Extends DBRequestHttpError.
///
@interface DBRequestAccessError : DBRequestHttpError

/// The structured object returned by the Dropbox API in the event of a 403 access
/// error.
@property (nonatomic, readonly) DBAUTHAccessError * _Nonnull structuredAccessError;

///
/// DBRequestAccessError full constructor.
///
/// @param requestId The Dropbox request id of the network call. This is
/// useful to Dropbox for debugging issues with Dropbox's SDKs and API.
/// @param statusCode The HTTP response status code of the request.
/// @param errorContent A string representation of the error body received in the reponse.
/// If for a route-specific error, this field will be the value of the "error_summary" key.
/// @param structuredAccessError The structured object returned by the Dropbox API in the
/// event of a 403 access error.
///
/// @return An initialized DBRequestAuthError instance.
///
- (nonnull instancetype)init:(NSString * _Nonnull)requestId
                  statusCode:(NSNumber * _Nonnull)statusCode
                errorContent:(NSString * _Nonnull)errorContent
       structuredAccessError:(DBAUTHAccessError * _Nonnull)structuredAccessError;

///
/// Description method.
///
/// @return A human-readable representation of the current DBRequestAccessError object.
///
- (NSString * _Nonnull)description;

@end

#pragma mark - Rate limit error

///
/// Rate limit request error.
///
/// Contains relevant information regarding a failed network
/// request. Initialized in the event of an HTTP 429 response.
/// Extends DBRequestHttpError.
///
@interface DBRequestRateLimitError : DBRequestHttpError

/// The structured object returned by the Dropbox API in the event of a 429
/// rate-limit error.
@property (nonatomic, readonly) DBAUTHRateLimitError * _Nonnull structuredRateLimitError;

/// The number of seconds to wait before making any additional requests in the
/// event of a rate-limit error.
@property (nonatomic, readonly) NSNumber * _Nonnull backoff;

///
/// DBRequestRateLimitError full constructor.
///
/// @param requestId The Dropbox request id of the network call. This is
/// useful to Dropbox for debugging issues with Dropbox's SDKs and API.
/// @param statusCode The HTTP response status code of the request.
/// @param errorContent A string representation of the error body received in the reponse.
/// If for a route-specific error, this field will be the value of the "error_summary" key.
/// @param structuredRateLimitError The structured object returned by the Dropbox API in the
/// event of a 429 rate-limit error.
/// @param backoff The number of seconds to wait before making any additional requests in the
/// event of a rate-limit error.
///
/// @return An initialized DBRequestRateLimitError instance.
///
- (nonnull instancetype)init:(NSString * _Nonnull)requestId
                  statusCode:(NSNumber * _Nonnull)statusCode
                errorContent:(NSString * _Nonnull)errorContent
    structuredRateLimitError:(DBAUTHRateLimitError * _Nonnull)structuredRateLimitError
                     backoff:(NSNumber * _Nonnull)backoff;

///
/// Description method.
///
/// @return A human-readable representation of the current DBRequestRateLimitError object.
///
- (NSString * _Nonnull)description;

@end

#pragma mark - Internal Server error

///
/// Internal Server request error.
///
/// Contains relevant information regarding a failed network
/// request. Initialized in the event of an HTTP 500 response.
/// Extends DBRequestHttpError.
///
@interface DBRequestInternalServerError : DBRequestHttpError

///
/// Description method.
///
/// @return A human-readable representation of the current `DBRequestInternalServerError` object.
///
- (NSString * _Nonnull)description;

@end

#pragma mark - Client error

///
/// Client side request error.
///
/// Contains relevant information regarding a failed network
/// request. Initialized in the event of a client-side error,
/// like an invalid url host, or making a request when not connected
/// to the internet.
///
@interface DBRequestClientError : NSObject

/// The client-side `NSError` object returned from the failed response.
@property (nonatomic, readonly) NSError * _Nonnull nsError;

///
/// `DBRequestClientError` full constructor.
///
/// An example of such an error might be if you attempt to make a request and are
/// not connected to the internet.
///
/// @param nsError The client-side `NSError` object returned from the failed response.
///
/// @return An initialized `DBRequestClientError` instance.
///
- (nonnull instancetype)init:(NSError * _Nonnull)nsError;

///
/// Description method.
///
/// @return A human-readable representation of the current `DBRequestClientError` object.
///
- (NSString * _Nonnull)description;

@end

#pragma mark - DBRequestError generic error

///
/// Base class for generic network request error (as opposed to route-specific
/// error).
///
/// This class is represented almost like a Stone "Union" object. As one object,
/// it can represent a number of error "states" (see all of the values of
/// `DBRequestErrorType`). To handle each error type, call each of the
/// `is<TAG_STATE>` methods until you determine the current tag state, then
/// call the corresponding `as<TAG_STATE>` method to return an instance of the
/// appropriate error type.
///
/// For example:
///
/// @code
/// ```
/// if ([dbxError isHTTPError]) {
///     DBHttpError *httpError = [dbxError asHttpError];
/// } else if ([dbxError isBadInputError]) { ........
/// ```
/// @endcode
///
@interface DBRequestError : NSObject

#pragma mark - Tag type definition

/// Represents the possible error types that can be returned from network requests.
typedef NS_ENUM(NSInteger, DBRequestErrorTag) {
  /// Errors produced at the HTTP layer.
  DBRequestErrorHttp,

  /// Errors due to bad input parameters to an API Operation.
  DBRequestErrorBadInput,

  /// Errors due to invalid authentication credentials.
  DBRequestErrorAuth,

  /// Errors due to invalid permission to access.
  DBRequestErrorAccess,

  /// Error caused by rate limiting.
  DBRequestErrorRateLimit,

  /// Errors due to a problem on Dropbox.
  DBRequestErrorInternalServer,

  /// Errors due to a problem on the client-side of the SDK.
  DBRequestErrorClient,
};

#pragma mark - Instance variables

/// Current state of the `DBRequestError` object type.
@property (nonatomic, readonly) DBRequestErrorTag tag;

/// The Dropbox request id of the network call. This is useful to Dropbox
/// for debugging issues with Dropbox's SDKs and API. Please include the
/// value of this field when submitting technical support inquiries to
/// Dropbox.
@property (nonatomic, readonly, copy) NSString * _Nullable requestId;

/// The HTTP response status code of the request.
@property (nonatomic, readonly) NSNumber * _Nullable statusCode;

/// A string representation of the error body received in the reponse.
/// If for a route-specific error, this field will be the value of the
/// "error_summary" key.
@property (nonatomic, readonly, copy) NSString * _Nullable errorContent;

/// The structured object returned by the Dropbox API in the event of a 401 auth
/// error.
@property (nonatomic, readonly) DBAUTHAuthError * _Nullable structuredAuthError;

/// The structured object returned by the Dropbox API in the event of a 403 access
/// error.
@property (nonatomic, readonly) DBAUTHAccessError * _Nullable structuredAccessError;

/// The structured object returned by the Dropbox API in the event of a 429
/// rate-limit error.
@property (nonatomic, readonly) DBAUTHRateLimitError * _Nullable structuredRateLimitError;

/// The number of seconds to wait before making any additional requests in the
/// event of a rate-limit error.
@property (nonatomic, readonly) NSNumber * _Nullable backoff;

/// The client-side `NSError` object returned from the failed response.
@property (nonatomic, readonly) NSError * _Nullable nsError;

#pragma mark - Constructors

///
/// `DBRequestError` convenience constructor.
///
/// Initializes the `DBRequestError` object with all the required state for representing a generic
/// HTTP error.
///
/// @param requestId The Dropbox request id of the network call. This is
/// useful to Dropbox for debugging issues with Dropbox's SDKs and API.
/// @param statusCode The HTTP response status code of the request.
/// @param errorContent A string representation of the error body received in the reponse.
/// If for a route-specific error, this field will be the value of the "error_summary" key.
///
/// @return An initialized `DBRequestError` instance with HTTP error state.
///
- (nonnull instancetype)initAsHttpError:(NSString * _Nullable)requestId
                             statusCode:(NSNumber * _Nullable)statusCode
                           errorContent:(NSString * _Nullable)errorContent;

///
/// DBRequestError convenience constructor.
///
/// Initializes the `DBRequestError` with all the required state for representing a Bad
/// Input error.
///
/// @param requestId The Dropbox request id of the network call. This is
/// useful to Dropbox for debugging issues with Dropbox's SDKs and API.
/// @param statusCode The HTTP response status code of the request.
/// @param errorContent A string representation of the error body received in the reponse.
/// If for a route-specific error, this field will be the value of the "error_summary" key.
///
/// @return An initialized `DBRequestError` instance with Bad Input error state.
///
- (nonnull instancetype)initAsBadInputError:(NSString * _Nullable)requestId
                                 statusCode:(NSNumber * _Nullable)statusCode
                               errorContent:(NSString * _Nullable)errorContent;

///
/// DBRequestError convenience constructor.
///
/// Initializes the `DBRequestError` with all the required state for representing an Auth
/// error.
///
/// @param requestId The Dropbox request id of the network call. This is
/// useful to Dropbox for debugging issues with Dropbox's SDKs and API.
/// @param statusCode The HTTP response status code of the request.
/// @param errorContent A string representation of the error body received in the reponse.
/// If for a route-specific error, this field will be the value of the "error_summary" key.
/// @param structuredAuthError The structured object returned by the Dropbox API in the
/// event of a 401 auth error.
///
/// @return An initialized `DBRequestError` instance with Auth error state.
///
- (nonnull instancetype)initAsAuthError:(NSString * _Nullable)requestId
                             statusCode:(NSNumber * _Nullable)statusCode
                           errorContent:(NSString * _Nullable)errorContent
                    structuredAuthError:(DBAUTHAuthError * _Nonnull)structuredAuthError;

///
/// DBRequestError convenience constructor.
///
/// Initializes the `DBRequestError` with all the required state for representing an Access
/// error.
///
/// @param requestId The Dropbox request id of the network call. This is
/// useful to Dropbox for debugging issues with Dropbox's SDKs and API.
/// @param statusCode The HTTP response status code of the request.
/// @param errorContent A string representation of the error body received in the reponse.
/// If for a route-specific error, this field will be the value of the "error_summary" key.
/// @param structuredAccessError The structured object returned by the Dropbox API in the
/// event of a 403 access error.
///
/// @return An initialized `DBRequestError` instance with Auth error state.
///
- (nonnull instancetype)initAsAccessError:(NSString * _Nullable)requestId
                               statusCode:(NSNumber * _Nullable)statusCode
                             errorContent:(NSString * _Nullable)errorContent
                    structuredAccessError:(DBAUTHAccessError * _Nonnull)structuredAccessError;

///
/// DBRequestError convenience constructor.
///
/// Initializes the `DBRequestError` with all the required state for representing a
/// Rate Limit error.
///
/// @param requestId The Dropbox request id of the network call. This is
/// useful to Dropbox for debugging issues with Dropbox's SDKs and API.
/// @param statusCode The HTTP response status code of the request.
/// @param errorContent A string representation of the error body received in the reponse.
/// If for a route-specific error, this field will be the value of the "error_summary" key.
/// @param structuredRateLimitError The structured object returned by the Dropbox API in the
/// event of a 429 rate-limit error.
/// @param backoff The number of seconds to wait before making any additional requests in the
/// event of a rate-limit error.
///
/// @return An initialized `DBRequestError` instance with Rate Limit error state.
///
- (nonnull instancetype)initAsRateLimitError:(NSString * _Nullable)requestId
                                  statusCode:(NSNumber * _Nullable)statusCode
                                errorContent:(NSString * _Nullable)errorContent
                    structuredRateLimitError:(DBAUTHRateLimitError * _Nonnull)structuredRateLimitError
                                     backoff:(NSNumber * _Nonnull)backoff;

///
/// `DBRequestError` convenience constructor.
///
/// Initializes the `DBRequestError` with all the required state for representing an
/// Internal Server error.
///
/// @param requestId The Dropbox request id of the network call. This is
/// useful to Dropbox for debugging issues with Dropbox's SDKs and API.
/// @param statusCode The HTTP response status code of the request.
/// @param errorContent A string representation of the error body received in the reponse.
/// If for a route-specific error, this field will be the value of the "error_summary" key.
///
/// @return An initialized `DBRequestError` instance with Internal Server error state.
///
- (nonnull instancetype)initAsInternalServerError:(NSString * _Nullable)requestId
                                       statusCode:(NSNumber * _Nullable)statusCode
                                     errorContent:(NSString * _Nullable)errorContent;

///
/// `DBRequestError` convenience constructor.
///
/// Initializes the `DBRequestError` with all the required state for representing an "OS" error.
/// An example of such an error might be if you attempt to make a request and are not
/// connected to the internet.
///
/// @param nsError The client-side `NSError` object returned from the failed response.
///
///
/// @return An initialized `DBRequestError` instance with Client error state.
///
- (nonnull instancetype)initAsClientError:(NSError * _Nullable)nsError;

///
/// `DBRequestError` full constructor.
///
/// @param requestId The Dropbox request id of the network call. This is
/// useful to Dropbox for debugging issues with Dropbox's SDKs and API.
/// @param statusCode The HTTP response status code of the request.
/// @param errorContent A string representation of the error body received in the reponse.
/// If for a route-specific error, this field will be the value of the "error_summary" key.
/// @param structuredAuthError The structured object returned by the Dropbox API in the
/// event of a 401 auth error.
/// @param structuredAccessError The structured object returned by the Dropbox API in the
/// event of a 403 access error.
/// @param structuredRateLimitError The structured object returned by the Dropbox API in the
/// event of a 429 rate-limit error.
/// @param backoff The number of seconds to wait before making any additional requests in the
/// event of a rate-limit error.
/// @param nsError The client-side NSError object returned from the failed response.
///
/// @return An initialized `DBRequestError` instance.
///
- (nonnull instancetype)init:(DBRequestErrorTag)tag
                   requestId:(NSString * _Nullable)requestId
                  statusCode:(NSNumber * _Nullable)statusCode
                errorContent:(NSString * _Nullable)errorContent
         structuredAuthError:(DBAUTHAuthError * _Nullable)structuredAuthError
       structuredAccessError:(DBAUTHAccessError * _Nullable)structuredAccessError
    structuredRateLimitError:(DBAUTHRateLimitError * _Nullable)structuredRateLimitError
                     backoff:(NSNumber * _Nullable)backoff
                     nsError:(NSError * _Nullable)nsError;

#pragma mark - Tag state methods

///
/// Retrieves whether the error's current tag state has value "http_error".
///
/// @return Whether the union's current tag state has value "http_error".
///
- (BOOL)isHttpError;

///
/// Retrieves whether the error's current tag state has value "bad_input_error".
///
/// @return Whether the union's current tag state has value "bad_input_error".
///
- (BOOL)isBadInputError;

///
/// Retrieves whether the error's current tag state has value "auth_error".
///
/// @return Whether the union's current tag state has value "auth_error".
///
- (BOOL)isAuthError;

///
/// Retrieves whether the error's current tag state has value "access_error".
///
/// @return Whether the union's current tag state has value "access_error".
///
- (BOOL)isAccessError;

///
/// Retrieves whether the error's current tag state has value "rate_limit_error".
///
/// @return Whether the union's current tag state has value "rate_limit_error".
///
- (BOOL)isRateLimitError;

///
/// Retrieves whether the error's current tag state has value "internal_server_error".
///
/// @return Whether the union's current tag state has value "internal_server_error".
///
- (BOOL)isInternalServerError;

///
/// Retrieves whether the error's current tag state has value "client_error".
///
/// @return Whether the union's current tag state has value "client_error".
///
- (BOOL)isClientError;

#pragma mark - Error subtype retrieval methods

///
/// Creates a `DBRequestHttpError` instance based on the data in the current `DBRequestError`
/// instance.
///
/// @note Will throw error if current `DBRequestError` instance tag state is not
/// "http_error". Should only use after checking if `isHttpError` returns true
/// for the current `DBRequestError` instance.
///
/// @return An initialized `DBRequestHttpError` instance.
///
- (DBRequestHttpError * _Nonnull)asHttpError;

///
/// Creates a `DBRequestBadInputError` instance based on the data in the current `DBRequestError`
/// instance.
///
/// @note Will throw error if current `DBRequestError` instance tag state is not
/// "bad_input_error". Should only use after checking if `isBadInputError` returns true
/// for the current `DBRequestError` instance.
///
/// @return An initialized `DBRequestBadInputError`.
///
- (DBRequestBadInputError * _Nonnull)asBadInputError;

///
/// Creates a DBRequestAuthError instance based on the data in the current `DBRequestError`
/// instance.
///
/// @note Will throw error if current `DBRequestError` instance tag state is not
/// "auth_error". Should only use after checking if `isAuthError` returns true
/// for the current `DBRequestError` instance.
///
/// @return An initialized `DBRequestAuthError` instance.
///
- (DBRequestAuthError * _Nonnull)asAuthError;

///
/// Creates a DBRequestAccessError instance based on the data in the current `DBRequestError`
/// instance.
///
/// @note Will throw error if current `DBRequestError` instance tag state is not
/// "auth_error". Should only use after checking if `isAccessError` returns true
/// for the current `DBRequestError` instance.
///
/// @return An initialized `DBRequestAccessError` instance.
///
- (DBRequestAuthError * _Nonnull)asAccessError;

///
/// Creates a `DBRequestRateLimitError` instance based on the data in the current `DBRequestError`
/// instance.
///
/// @note Will throw error if current `DBRequestError` instance tag state is not
/// "rate_limit_error". Should only use after checking if `isRateLimitError` returns true
/// for the current `DBRequestError` instance.
///
/// @return An initialized `DBRequestRateLimitError` instance.
///
- (DBRequestRateLimitError * _Nonnull)asRateLimitError;

///
/// Creates a `DBRequestInternalServerError` instance based on the data in the
/// current `DBRequestError` instance.
///
/// @note Will throw error if current `DBRequestError` instance tag state
/// is not "internal_server_error". Should only use after checking if `isInternalServerError`
/// returns true for the current `DBRequestError` instance.
///
/// @return An initialized `DBHttpError` instance.
///
- (DBRequestInternalServerError * _Nonnull)asInternalServerError;

///
/// Creates a `DBRequestClientError` instance based on the data in the current `DBRequestError`
/// instance.
///
/// @note Will throw error if current `DBRequestError` instance tag state is not
/// "client_error". Should only use after checking if `isClientError` returns true
/// for the current `DBRequestError` instance.
///
/// @return An initialized `DBRequestClientError` instance.
///
- (DBRequestClientError * _Nonnull)asClientError;

#pragma mark - Tag name method

///
/// Retrieves string value of union's current tag state.
///
/// @return A human-readable string representing the `DBRequestError` object's current tag
/// state.
///
- (NSString * _Nonnull)tagName;

#pragma mark - Description method

///
/// Description method.
///
/// @return A human-readable representation of the current `DBRequestError` object.
///
- (NSString * _Nonnull)description;

@end
