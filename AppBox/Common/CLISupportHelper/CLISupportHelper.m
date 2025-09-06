//
//  CLISupportHelper.h
//  AppBox
//
//  Created by Vineet Choudhary on 30/12/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#import "CLISupportHelper.h"

@implementation CLISupportHelper

+ (BOOL)install {
	return [self runWithScript:@"install.sh"];
}

+ (BOOL)uninstall {
	return [self runWithScript:@"uninstall.sh"];
}

+ (BOOL)runWithScript:(NSString *)script {
	NSString * const kCLIName = @"appboxcli";
	NSString * const kCLIInstallPath = [NSString stringWithFormat:@"/usr/local/bin/%@", kCLIName];

	AuthorizationRef authorization;
	OSStatus status = AuthorizationCreate(NULL, NULL, kAuthorizationFlagDefaults, &authorization);
	if (status == errAuthorizationSuccess) {
		AuthorizationItem items = {kAuthorizationRightExecute, 0, NULL, 0};
		AuthorizationRights rights = {1, &items};
		status = AuthorizationCopyRights(authorization, &rights, NULL, kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagExtendRights | kAuthorizationFlagPreAuthorize, NULL);
		if (status == errAuthorizationSuccess) {
			NSString *sharedSupportPath = NSBundle.mainBundle.sharedSupportPath;
			NSString *installerPath = [sharedSupportPath stringByAppendingPathComponent:script];
			NSString *toolPath = [sharedSupportPath stringByAppendingPathComponent:kCLIName];
			char *arguments[] = {(char*)toolPath.fileSystemRepresentation, (char*)kCLIInstallPath.fileSystemRepresentation, NULL};
			FILE *communicationPipe = NULL;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
			status = AuthorizationExecuteWithPrivileges(authorization, installerPath.fileSystemRepresentation, kAuthorizationFlagDefaults, arguments, &communicationPipe);
#pragma clang diagnostic pop
			if (status == errAuthorizationSuccess) {
				char buffer[128];
				ssize_t count = read(fileno(communicationPipe), buffer, sizeof(buffer));
				NSData *data = [[NSData alloc] initWithBytes:buffer length:count];
				NSString *result = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
				if (![result isEqualToString:@"OK"]) {
					status = -1;  // Code doesn't matter, just not errAuthorizationSuccess
				}
			}
		}
		AuthorizationFree(authorization, kAuthorizationFlagDefaults);
	}
	return status == errAuthorizationSuccess;
}

@end
