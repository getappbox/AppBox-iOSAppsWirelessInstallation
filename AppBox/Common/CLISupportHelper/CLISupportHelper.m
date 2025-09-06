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
	if ([self runScript:@"install.sh"]) {
		[Common showAlertWithTitle:@"Success" andMessage:@"AppBox CLI tool installed successfully."];
		return YES;
	}else{
		[Common showAlertWithTitle:@"Error" andMessage:@"Failed to install AppBox CLI tool."];
		return NO;
	}
}

+ (BOOL)uninstall {
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setMessageText: @"Are you sure?"];
	[alert setInformativeText:@"Do you want to uninstall AppBox CLI tool?"];
	[alert setAlertStyle:NSAlertStyleInformational];
	[alert addButtonWithTitle:@"Yes"];
	[alert addButtonWithTitle:@"No"];
	if ([alert runModal] == NSAlertFirstButtonReturn){
		NSError *error;
		if ([self runScript:@"uninstall.sh"]){
			[Common showAlertWithTitle:@"Success" andMessage:@"AppBox CLI tool uninstalled successfully."];
			return YES;
		}else{
			[Common showAlertWithTitle:@"Error" andMessage:[NSString stringWithFormat:@"Failed to uninstall AppBox CLI tool.\n\n%@", error.localizedDescription]];
			return NO;
		}
	} else {
		return NO;
	}
}
}

+ (BOOL)runScript:(NSString *)script {
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
