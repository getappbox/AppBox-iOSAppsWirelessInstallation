///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBCustomDatatypes.h"
#import "DBCustomTasks.h"
#import "DBTasksStorage.h"

@implementation DBBatchUploadTask {
  DBBatchUploadData * _Nonnull _uploadData;
}

- (instancetype)initWithUploadData:(DBBatchUploadData *)uploadData {
  self = [super init];
  if (self) {
    _uploadData = uploadData;
  }
  return self;
}

- (void)cancel {
  _uploadData.cancel = YES;
  [_uploadData.taskStorage cancelAllTasks];
}

@end
