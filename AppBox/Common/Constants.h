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
#define abMailerBaseURL @"https://appboxapi.github.io/mail"
#define abInstallWebAppBaseURL @"https://tryapp.github.io"
#define abMailGunBaseURL @"https://api.mailgun.net/v3/tryappbox.com/messages"
#define abGitHubReleaseBaseURL @"https://github.com/vineetchoudhary/AppBox-iOSAppsWirelessInstallation/releases/tag/"

//MailGun
#define abMailGunFromEmail @"AppBox Build <mailgun@tryappbox.com>"

//Other URL's
#define abDefaultLatestDownloadURL @"https://tryappbox.github.io/download"
#define abDocumentationURL @"https://iosappswirelessinstallation.codeplex.com/documentation"
#define abLicenseURL @"https://github.com/vineetchoudhary/AppBox-iOSAppsWirelessInstallation#user-content-license"
#define abGitHubLatestRelease @"https://api.github.com/repos/vineetchoudhary/AppBox-iOSAppsWirelessInstallation/releases/latest"
#define abTwitterURL @"https://twitter.com/tryappbox"
#define abSlackImage @"https://s3-us-west-2.amazonaws.com/slack-files2/avatars/2017-04-06/165993935268_ec0c0ba40483382c7192_512.png"
#define abWebHookSetupURL @"https://my.slack.com/apps/new/A0F7XDUAZ-incoming-webhooks"

//AppBox AppStore service. Note: these constanst also need to change in ALAppStore.sh file
#define abALUploadApp @"upload-app"
#define abALValidateApp @"validate-app"
#define abALValidateUser @"validate-user"
#define abiTunesConnectService @"AppBox - iTunesConnect"

//Serives Key
#define abGoogleTiny @"AIzaSyD5c0jmblitp5KMZy2crCbueTU-yB1jMqI"

//notification
#define abSessionLogUpdated @"SessionLogUpdated"
#define abDropBoxLoggedInNotification @"DropBoxLoggedInNotification"
#define abDropBoxLoggedOutNotification @"DropBoxLoggedOutNotification"
#define abBuildRepoNotification @"BuildRepoNotification"
#define abAppBoxReadyToBuildNotification @"AppBoxReadyToBuildNotification"

//messages
#define abKeepSameLinkHelpTitle @"What is keep same link for all future upload?"
#define abKeepSameLinkHelpMessage  @"This feature will keep same short url for all future ipa uploaded with same bundle identifier, this means old ipa url will replaced by new ipa file. You can change the link by providing a \"Custom Dropbox Folder Name\" in \"Other Setting\". \n\nIf this option is enable, you can also download the previous build with same url."
#define abKeepSameLinkReadMoreURL @"https://iosappswirelessinstallation.codeplex.com/wikipage?title=KeepSameLink"

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
    ScriptTypeXcodePath,
    ScriptTypeAppStoreValidation,
    ScriptTypeAppStoreUpload,
} ScriptType;

//CI
#define abExitCodeForUnstableBuild 255


#endif /* Constants_h */
