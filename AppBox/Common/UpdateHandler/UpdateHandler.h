//
//  UpdateHandler.h
//  AppBox
//
//  Created by Vineet Choudhary on 30/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Sparkle/Sparkle.h>

@interface UpdateHandler : NSObject

+ (void)showAlreadyUptoDateAlert;
+ (void)showUpdateAlertWithUpdateURL:(NSURL *)url;
+ (void)isNewVersionAvailableCompletion:(void (^)(bool available, NSURL *url))completion;

@end
