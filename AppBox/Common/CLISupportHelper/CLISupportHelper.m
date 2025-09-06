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
		// Save app version as CLI version
		NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
		[UserData setCLIVersion:appVersion];

		// Show success alert
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText: @"Success"];
		[alert setInformativeText:@"AppBox CLI tool installed successfully.\n\nYou can use it from terminal using the command \"appboxcli\"."];
		[alert setAlertStyle:NSAlertStyleInformational];
		[alert addButtonWithTitle:@"OK"];
		[alert addButtonWithTitle:@"Learn More"];
		if ([alert runModal] == NSAlertSecondButtonReturn){
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:abAppBoxCLIHelpURL]];
		}
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

+ (BOOL)installPromptAfterLogin {
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setMessageText: @"Install CLI Tool"];
	[alert setInformativeText:@"Do you want to install AppBox CLI tool to use AppBox from terminal?"];
	[alert setAlertStyle:NSAlertStyleInformational];
	[alert addButtonWithTitle:@"Install"];
	[alert addButtonWithTitle:@"Not Now"];
	if ([alert runModal] == NSAlertFirstButtonReturn){
		return [self install];
	} else {
		NSAlert *laterInstallOption = [[NSAlert alloc] init];
		[laterInstallOption setMessageText: @"You can install AppBox CLI tool later from the \"CLI\" menu bar option."];
		[laterInstallOption setAlertStyle:NSAlertStyleInformational];
		[laterInstallOption addButtonWithTitle:@"OK"];
		return NO;
	}
}

+ (BOOL)updatePromptAfterVersionUpdate {
	NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
	NSString *cliVersion = [UserData cliVersion];
	if (appVersion == cliVersion || cliVersion.isEmpty) {
		return NO;
	}

	BOOL hasNewCLIVersion = YES;
	if (![NSFileManager.defaultManager fileExistsAtPath:abCLIPath] || !hasNewCLIVersion) {
		return NO;
	}

	NSAlert *alert = [[NSAlert alloc] init];
	[alert setMessageText: @"Update CLI Tool"];
	[alert setInformativeText:@"A newer version of AppBox CLI tool is available. You must update it to use with the latest version of AppBox."];
	[alert setAlertStyle:NSAlertStyleInformational];
	[alert addButtonWithTitle:@"Update"];
	[alert addButtonWithTitle:@"Uninstall"];
	if ([alert runModal] == NSAlertFirstButtonReturn){
		if ([self runScript:@"update.sh"]) {
			[UserData setCLIVersion:appVersion];
			[Common showAlertWithTitle:@"Success" andMessage:@"AppBox CLI tool updated successfully."];
			return YES;
		} else {
			[Common showAlertWithTitle:@"Error" andMessage:@"Failed to update AppBox CLI tool."];
			return NO;
		}
	} else {
		if ([self uninstall]) {
			return YES;
		} else {
			return [self updatePromptAfterVersionUpdate];
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
