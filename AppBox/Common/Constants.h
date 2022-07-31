//
//  Constants.h
//  AppBox
//
//  Created by Vineet Choudhary on 28/11/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#ifndef Constants_h
#define Constants_h

//Base URL's
#define abGitHubReleaseBaseURL @"https://github.com/vineetchoudhary/AppBox-iOSAppsWirelessInstallation/releases/tag/"
#define abDropBoxAppBaseURL @"https://www.dropbox.com/home/Apps/AppBox%20-%20Build%2C%20Test%20and%20Distribute%20iOS%20Apps"
#define abDropBoxDirectDownload @"https://dl.dropboxusercontent.com"

//Other URL's
#define abDefaultLatestDownloadURL @"https://getappbox.com/download"
#define abDocumentationURL @"https://docs.getappbox.com"
#define abLicenseURL @"https://github.com/vineetchoudhary/AppBox-iOSAppsWirelessInstallation#user-content-license"
#define abGitHubLatestRelease @"https://api.github.com/repos/vineetchoudhary/AppBox-iOSAppsWirelessInstallation/releases/latest"
#define abTwitterURL @"https://twitter.com/AppBoxHQ"
#define abSlackImage @"https://s3-us-west-2.amazonaws.com/slack-files2/avatars/2017-04-06/165993935268_ec0c0ba40483382c7192_512.png"
#define abWebHookSetupURL @"https://my.slack.com/apps/new/A0F7XDUAZ-incoming-webhooks"

//Help URL
#define abDownloadIPAHelpURL @"https://docs.getappbox.com/Features/downloadipa/"
#define abMoreDetailsHelpURL @"https://docs.getappbox.com/Features/moredetails/"
#define abKeepSameLinkReadMoreURL @"https://docs.getappbox.com/Features/keepsamelink/"
#define abUploadChunkSizeHelpURL @"https://docs.getappbox.com/Features/uploadchunksize/"
#define abMultipleXcodeVersionURL @"https://docs.getappbox.com/FAQs/cimultiplexcodeversion/"
#define abCICDAppStore @"https://docs.getappbox.com/ContinuousIntegration/cicdforappstore/"
#define abShareXcodeProjectSchemeURL @"https://docs.getappbox.com/FAQs/sharexcodeprojectschemes/"
#define abDontShowPerviousBuildURL @"https://docs.getappbox.com/Features/keepsamelink/#3-how-to-keep-the-same-link-but-also-hide-the-previous-version-from-the-installation-page"

//Unique links
static NSString *const UNIQUE_LINK_SHARED = @"uniqueLinkShared";
static NSString *const UNIQUE_LINK_SHORT = @"uniqueLinkShort";
static NSString *const FILE_NAME_UNIQUE_JSON = @"appinfo.json";
static NSString *const FILE_NAME_SHARE_URL = @".appbox_share_value.json";

//notification
#define abDropBoxLoggedInNotification @"DropBoxLoggedInNotification"
#define abDropBoxLoggedOutNotification @"DropBoxLoggedOutNotification"
#define abBuildRepoNotification @"BuildRepoNotification"
#define abUseOpenFilesNotification @"UseOpenFilesNotification"
#define abAppBoxReadyToUseNotification @"AppBoxReadyToBuildNotification"
#define abStopAppBoxLocalServer @"StopAppBoxLocalServer"

//messages
#define abConnectedToInternet @"Connected to the Internet."
#define abNotConnectedToInternet @"Waiting for the Internet Connection."

#define abTeamId @"teamId"
#define abFullName @"fullName"
#define abTeamName @"teamName"
#define abExpiryDate @"expiryDate"

//others
#define abEmptyString @""
#define abTeamIdLength 10
#define abBytesToMB (1024 * 1024)
#define abDropboxOutOfSpaceWarningSize 150
#define abOnErrorMaxRetryCount 3
#define abEndOfSessionLog @"abEndOfSessionLog"

//Under development feature flags
#define abMultiDBAccounts 0


//enums
typedef enum : NSUInteger {
    DBFileTypeIPA,
    DBFileTypeManifest,
    DBFileTypeJson,
} DBFileType;

//CI
#define abExitCodeForInvalidCommand 127
#define abExitCodeForUploadFailed 124
#define abExitCodeUnZipIPAError 121
#define abExitCodeInfoPlistNotFound 120
#define abExitCodeIPAFileNotFound 119
#define abExitCodeUnableToCreateManiFestFile 118
#define abExitCodeForMailFailed 111
#define abExitCodeForSuccess 0

#define abArgsIPA @"ipa="
#define abArgsEmails @"email="
#define abArgsPersonalMessage @"message="
#define abArgsKeepSameLink @"keepsamelink="
#define abArgsDropBoxFolderName @"dbfolder="

//Weakify & Strongify
#define weakify(var) __weak typeof(var) AHKWeak_##var = var;

#define strongify(var) \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
__strong typeof(var) var = AHKWeak_##var; \
_Pragma("clang diagnostic pop")


#endif /* Constants_h */
