///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///
/// Auto-generated by Stone, do not modify.
///

#import <Foundation/Foundation.h>

#import "DBSerializableProtocol.h"

@class DBTEAMRemoveCustomQuotaResult;
@class DBTEAMUserSelectorArg;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - API Object

///
/// The `RemoveCustomQuotaResult` union.
///
/// User result for setting member custom quota.
///
/// This class implements the `DBSerializable` protocol (serialize and
/// deserialize instance methods), which is required for all Obj-C SDK API route
/// objects.
///
@interface DBTEAMRemoveCustomQuotaResult : NSObject <DBSerializable, NSCopying>

#pragma mark - Instance fields

/// The `DBTEAMRemoveCustomQuotaResultTag` enum type represents the possible tag
/// states with which the `DBTEAMRemoveCustomQuotaResult` union can exist.
typedef NS_ENUM(NSInteger, DBTEAMRemoveCustomQuotaResultTag) {
  /// Successfully removed user.
  DBTEAMRemoveCustomQuotaResultSuccess,

  /// Invalid user (not in team).
  DBTEAMRemoveCustomQuotaResultInvalidUser,

  /// (no description).
  DBTEAMRemoveCustomQuotaResultOther,

};

/// Represents the union's current tag state.
@property (nonatomic, readonly) DBTEAMRemoveCustomQuotaResultTag tag;

/// Successfully removed user. @note Ensure the `isSuccess` method returns true
/// before accessing, otherwise a runtime exception will be raised.
@property (nonatomic, readonly) DBTEAMUserSelectorArg *success;

/// Invalid user (not in team). @note Ensure the `isInvalidUser` method returns
/// true before accessing, otherwise a runtime exception will be raised.
@property (nonatomic, readonly) DBTEAMUserSelectorArg *invalidUser;

#pragma mark - Constructors

///
/// Initializes union class with tag state of "success".
///
/// Description of the "success" tag state: Successfully removed user.
///
/// @param success Successfully removed user.
///
/// @return An initialized instance.
///
- (instancetype)initWithSuccess:(DBTEAMUserSelectorArg *)success;

///
/// Initializes union class with tag state of "invalid_user".
///
/// Description of the "invalid_user" tag state: Invalid user (not in team).
///
/// @param invalidUser Invalid user (not in team).
///
/// @return An initialized instance.
///
- (instancetype)initWithInvalidUser:(DBTEAMUserSelectorArg *)invalidUser;

///
/// Initializes union class with tag state of "other".
///
/// @return An initialized instance.
///
- (instancetype)initWithOther;

- (instancetype)init NS_UNAVAILABLE;

#pragma mark - Tag state methods

///
/// Retrieves whether the union's current tag state has value "success".
///
/// @note Call this method and ensure it returns true before accessing the
/// `success` property, otherwise a runtime exception will be thrown.
///
/// @return Whether the union's current tag state has value "success".
///
- (BOOL)isSuccess;

///
/// Retrieves whether the union's current tag state has value "invalid_user".
///
/// @note Call this method and ensure it returns true before accessing the
/// `invalidUser` property, otherwise a runtime exception will be thrown.
///
/// @return Whether the union's current tag state has value "invalid_user".
///
- (BOOL)isInvalidUser;

///
/// Retrieves whether the union's current tag state has value "other".
///
/// @return Whether the union's current tag state has value "other".
///
- (BOOL)isOther;

///
/// Retrieves string value of union's current tag state.
///
/// @return A human-readable string representing the union's current tag state.
///
- (NSString *)tagName;

@end

#pragma mark - Serializer Object

///
/// The serialization class for the `DBTEAMRemoveCustomQuotaResult` union.
///
@interface DBTEAMRemoveCustomQuotaResultSerializer : NSObject

///
/// Serializes `DBTEAMRemoveCustomQuotaResult` instances.
///
/// @param instance An instance of the `DBTEAMRemoveCustomQuotaResult` API
/// object.
///
/// @return A json-compatible dictionary representation of the
/// `DBTEAMRemoveCustomQuotaResult` API object.
///
+ (nullable NSDictionary *)serialize:(DBTEAMRemoveCustomQuotaResult *)instance;

///
/// Deserializes `DBTEAMRemoveCustomQuotaResult` instances.
///
/// @param dict A json-compatible dictionary representation of the
/// `DBTEAMRemoveCustomQuotaResult` API object.
///
/// @return An instantiation of the `DBTEAMRemoveCustomQuotaResult` object.
///
+ (DBTEAMRemoveCustomQuotaResult *)deserialize:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END