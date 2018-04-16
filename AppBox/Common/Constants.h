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
#define abBranchBaseURL @"https://api.branch.io/v1/url"
#define abInstallWebAppBaseURL @"https://tryapp.github.io"
#define abMailerBaseURL @"https://appboxapi.github.io/mail"
#define abMailGunBaseURL @"https://api.mailgun.net/v3/tryappbox.com/messages"
#define abGitHubReleaseBaseURL @"https://github.com/vineetchoudhary/AppBox-iOSAppsWirelessInstallation/releases/tag/"
//#define abDropBoxAppBaseURL @"https://www.dropbox.com/home/Apps/AppBox%20-%20Powered%20by%20DB"
#define abDropBoxAppBaseURL @"https://www.dropbox.com/home/Apps/AppBox%20-%20Build%2C%20Test%20and%20Distribute%20iOS%20Apps"

//MailGun
#define abMailGunFromEmail @"AppBox Build <mailgun@tryappbox.com>"

//Other URL's
#define abAppBoxAdsURL @"https://appbox-ads.firebaseio.com/ads.json"
#define abDefaultLatestDownloadURL @"https://tryappbox.github.io/download"
#define abDocumentationURL @"https://tryappbox.github.io/help/"
#define abLicenseURL @"https://github.com/vineetchoudhary/AppBox-iOSAppsWirelessInstallation#user-content-license"
#define abGitHubLatestRelease @"https://api.github.com/repos/vineetchoudhary/AppBox-iOSAppsWirelessInstallation/releases/latest"
#define abTwitterURL @"https://twitter.com/tryappbox"
#define abSlackImage @"https://s3-us-west-2.amazonaws.com/slack-files2/avatars/2017-04-06/165993935268_ec0c0ba40483382c7192_512.png"
#define abWebHookSetupURL @"https://my.slack.com/apps/new/A0F7XDUAZ-incoming-webhooks"
#define abShareXcodeProjectSchemeURL @"http://www.tryappbox.com/features/faq/HowToShareXcodeProjectSchemes.html"

//Unique links
static NSString *const UNIQUE_LINK_SHARED = @"uniqueLinkShared";
static NSString *const UNIQUE_LINK_SHORT = @"uniqueLinkShort";
static NSString *const FILE_NAME_UNIQUE_JSON = @"appinfo.json";

//AppBox AppStore service. Note: these constanst also need to change in ALAppStore.sh file
#define abALUploadApp @"upload-app"
#define abALValidateApp @"validate-app"
#define abALValidateUser @"validate-user"
#define abiTunesConnectService @"AppBox - iTunesConnect"
#define abiTunesConnectServiceCI @"AppBox - iTunesConnect - CI"

//Serives Key
#define abGoogleTiny @"AIzaSyD5c0jmblitp5KMZy2crCbueTU-yB1jMqI"

//notification
#define abSessionLogUpdated @"SessionLogUpdated"
#define abDropBoxLoggedInNotification @"DropBoxLoggedInNotification"
#define abDropBoxLoggedOutNotification @"DropBoxLoggedOutNotification"
#define abBuildRepoNotification @"BuildRepoNotification"
#define abUseOpenFilesNotification @"UseOpenFilesNotification"
#define abAppBoxReadyToUseNotification @"AppBoxReadyToBuildNotification"
#define abStopAppBoxLocalServer @"StopAppBoxLocalServer"
#define abAdsLoadCompleted @"AdsLoadCompleted"

//messages
#define abKeepSameLinkHelpTitle @"What is keep same link for all future upload?"
#define abKeepSameLinkHelpMessage  @"This feature will keep same short url for all future ipa uploaded with same bundle identifier, this means old ipa url will replaced by new ipa file. You can change the link by providing a \"Custom Dropbox Folder Name\" in \"Other Setting\". \n\nIf this option is enable, you can also download the previous build with same url."
#define abKeepSameLinkReadMoreURL @"https://tryappbox.github.io/features/keepsamelink/"

#define abConnectedToInternet @"Connected to the Internet."
#define abNotConnectedToInternet @"Waiting for the Internet Connection."

//team id constants
#define abiPhoneDeveloper @"iphone developer"
#define abiPhoneDistribution @"iphone distribution"

#define abTeamId @"teamId"
#define abFullName @"fullName"
#define abTeamName @"teamName"
#define abExpiryDate @"expiryDate"

//default setting
#define abBuildLocation @"~/Desktop"
#define abXcodeLocation @"/Applications/Xcode.app"
#define abAppBoxLocalServerBuildsDirectory @"AppBoxServerBuilds"
#define abApplicationLoaderAppLocation @"/Contents/Applications/Application Loader.app"
#define abApplicationLoaderALToolLocation @"/Contents/Applications/Application Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Versions/A/Support/altool"


//others
#define abEmptyString @""
#define abTeamIdLength 10
#define abBytesToMB (1024 * 1024)
#define abDropboxOutOfSpaceWarningSize 150 
#define abAppInfoFileName @"appinfo.json"
#define abEndOfSessionLog @"abEndOfSessionLog"


//enums
typedef enum : NSUInteger {
    DBFileTypeIPA,
    DBFileTypeManifest,
    DBFileTypeJson,
} DBFileType;

typedef enum : NSUInteger {
    ScriptTypeGetScheme,
    ScriptTypeTeamId,
    ScriptTypeBuild,
    ScriptTypeCreateIPA,
    ScriptTypeXcodePath,
    ScriptTypeAppStoreValidation,
    ScriptTypeAppStoreUpload,
} ScriptType;

//CI
#define abExitCodeForInvalidCommand 127
#define abExitCodeForArchiveFailed 126
#define abExitCodeForExportFailed 125
#define abExitCodeForUploadFailed 124
#define abExitCodeForInvalidAppBoxSettingFile 123 //appbox.plist
#define abExitCodeForInvalidArgumentsXcodeBuild 122
#define abExitCodeForFailedToLoadSchemeInfo 122
#define abExitCodeUnZipIPAError 121
#define abExitCodeInfoPlistNotFound 120
#define abExitCodeIPAFileNotFound 119
#define abExitCodeUnableToCreateManiFestFile 118
#define abExitCodeForXcodeNotFount 117
#define abExitCodeForApplicationLoaderNotFount 116
#define abExitCodeForSchemeNotFound 115
#define abExitCodeForPrivateKeyNotFound 114
#define abExitCodeForAppStoreUploadFailed 113
#define abExitCodeForInvalidITCAccount 112
#define abExitCodeForSuccess 0

#define abArgsWorkspace @"build="
#define abArgsScheme @"scheme="
#define abArgsBuildType @"buildtype="
#define abArgsTeamId @"teamid="


#endif /* Constants_h */
