///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBStoneValidators.h"

@implementation DBStoneValidators

+ (void (^)(NSString *))stringValidator:(NSNumber *)minLength
                              maxLength:(NSNumber *)maxLength
                                pattern:(NSString *)pattern {

  void (^validator)(NSString *) = ^(NSString *value) {
    if (minLength != nil) {
      if ([value length] < [minLength unsignedIntegerValue]) {
        NSString *exceptionMessage =
            [NSString stringWithFormat:@"\"%@\" must be at least %@ characters", value, [minLength stringValue]];
        [[self class] raiseIllegalStateErrorWithMessage:exceptionMessage];
      }
    }

    if (maxLength != nil) {
      if ([value length] > [maxLength unsignedIntegerValue]) {
        NSString *exceptionMessage =
            [NSString stringWithFormat:@"\"%@\" must be at most %@ characters", value, [minLength stringValue]];
        [[self class] raiseIllegalStateErrorWithMessage:exceptionMessage];
      }
    }

    if (pattern != nil && pattern.length != 0) {
      NSError *error;
      NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
      NSArray *matches = [re matchesInString:value options:0 range:NSMakeRange(0, [value length])];
      if ([matches count] == 0) {
        NSString *exceptionMessage =
            [NSString stringWithFormat:@"\"%@\" must match pattern \"%@\"", value, [re pattern]];
        [[self class] raiseIllegalStateErrorWithMessage:exceptionMessage];
      }
    }
  };

  return validator;
}

+ (void (^)(NSNumber *))numericValidator:(NSNumber *)minValue maxValue:(NSNumber *)maxValue {
  void (^validator)(NSNumber *) = ^(NSNumber *value) {
    if (minValue != nil) {
      if ([value unsignedIntegerValue] < [minValue unsignedIntegerValue]) {
        NSString *exceptionMessage =
            [NSString stringWithFormat:@"\"%@\" must be at least %@", value, [minValue stringValue]];
        [[self class] raiseIllegalStateErrorWithMessage:exceptionMessage];
      }
    }

    if (maxValue != nil) {
      if ([value unsignedIntegerValue] > [maxValue unsignedIntegerValue]) {
        NSString *exceptionMessage =
            [NSString stringWithFormat:@"\"%@\" must be at most %@", value, [maxValue stringValue]];
        [[self class] raiseIllegalStateErrorWithMessage:exceptionMessage];
      }
    }
  };

  return validator;
}

+ (void (^)(NSArray<id> *))arrayValidator:(NSNumber *)minItems
                                 maxItems:(NSNumber *)maxItems
                            itemValidator:(void (^)(id))itemValidator {
  void (^validator)(NSArray<id> *) = ^(NSArray<id> *value) {
    if (minItems != nil) {
      if ([value count] < [minItems unsignedIntegerValue]) {
        NSString *exceptionMessage =
            [NSString stringWithFormat:@"\"%@\" must be at least %@ items", value, [minItems stringValue]];
        [[self class] raiseIllegalStateErrorWithMessage:exceptionMessage];
      }
    }

    if (maxItems != nil) {
      if ([value count] > [maxItems unsignedIntegerValue]) {
        NSString *exceptionMessage =
            [NSString stringWithFormat:@"\"%@\" must be at most %@ items", value, [maxItems stringValue]];
        [[self class] raiseIllegalStateErrorWithMessage:exceptionMessage];
      }
    }

    if (itemValidator != nil) {
      for (id item in value) {
        itemValidator(item);
      }
    }
  };

  return validator;
}

+ (void (^)(NSDictionary<NSString *, id> *))mapValidator:(void (^)(id))itemValidator {
  void (^validator)(NSDictionary<NSString *, id> *) = ^(NSDictionary<NSString *, id> *value) {
    if (itemValidator != nil) {
      for (id key in value) {
        itemValidator(value[key]);
      }
    }
  };

  return validator;
}

+ (void (^)(id))nullableValidator:(void (^)(id))internalValidator {
  void (^validator)(id) = ^(id value) {
    if (value != nil) {
      internalValidator(value);
    }
  };

  return validator;
}

+ (void (^)(id))nonnullValidator:(void (^)(id))internalValidator {
  void (^validator)(id) = ^(id value) {
    if (value == nil) {
      [[self class] raiseIllegalStateErrorWithMessage:@"Value must not be `nil`"];
    }

    if (internalValidator != nil) {
      internalValidator(value);
    }
  };

  return validator;
}

+ (void)raiseIllegalStateErrorWithMessage:(NSString *)message {
  NSString *exceptionMessage =
      [NSString stringWithFormat:@"%@:\n%@", message, [[NSThread callStackSymbols] objectAtIndex:0]];
  [NSException raise:@"IllegalStateException" format:exceptionMessage, nil];
}
@end
