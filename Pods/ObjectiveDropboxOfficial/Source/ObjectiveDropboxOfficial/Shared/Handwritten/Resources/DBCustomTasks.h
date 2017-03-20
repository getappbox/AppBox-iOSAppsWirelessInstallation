///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>

@class DBBatchUploadData;

///
/// Dropbox task object for custom batch upload route.
///
/// The batch upload route is a convenience layer over several of our auto-generated API endpoints. For this reason,
/// there is less flexibility and granularity of control. Progress and response handlers are passed directly into this
/// route (rather than installed via this task object) and only `cancel` is available. This task is also specific to
/// only one endpoint, rather than an entire class (style) of endpoints.
///
@interface DBBatchUploadTask : NSObject

///
/// DBBatchUploadTask full constructor.
///
/// @param uploadData relevant to the particular batch upload request.
///
/// @returns A DBBatchUploadTask instance.
///
- (nonnull instancetype)initWithUploadData:(DBBatchUploadData * _Nonnull)uploadData;

///
/// Cancels the current request.
///
- (void)cancel;

@end
