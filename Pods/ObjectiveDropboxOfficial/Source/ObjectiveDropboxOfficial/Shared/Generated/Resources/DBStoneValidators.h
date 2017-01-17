///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

///
/// Validator functions used by SDK to impose value constraints.
///
@interface DBStoneValidators <T> : NSObject

/// Validator for `NSString` objects. Enforces minimum length and/or maximum length and/or regex pattern.
+ (void (^_Nonnull)(NSString * _Nonnull))stringValidator:(NSNumber * _Nullable)minLength
                                               maxLength:(NSNumber * _Nullable)maxLength
                                                 pattern:(NSString * _Nullable)pattern;

/// Validator for `NSNumber` objects. Enforces minimum value and/or maximum value.
+ (void (^_Nonnull)(NSNumber * _Nonnull))numericValidator:(NSNumber * _Nullable)minValue
                                                maxValue:(NSNumber * _Nullable)maxValue;

/// Validator for `NSArray` objects. Enforces minimum number of items and/or maximum minimum number of items. Method
/// requires a validator block that can validate each item in the array.
+ (void (^_Nonnull)(NSArray<T> * _Nonnull))arrayValidator:(NSNumber * _Nullable)minItems
                                                maxItems:(NSNumber * _Nullable)maxItems
                                           itemValidator:(void (^_Nullable)(T _Nonnull))itemValidator;

/// Wrapper validator for nullable objects. Maintains a reference to the object's normal non-nullable validator.
+ (void (^_Nonnull)(T _Nonnull))nullableValidator:(void (^_Nonnull)(T _Nonnull))internalValidator;

@end
