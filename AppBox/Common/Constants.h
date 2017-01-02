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
#define abDefaultLatestDownloadURL @"https://tryappbox.github.io/download"
#define abGitHubLatestRelease @"https://api.github.com/repos/vineetchoudhary/AppBox-iOSAppsWirelessInstallation/releases/latest"

//Serives Key
#define abDbRoot kDBRootAppFolder
#define abDbAppkey @"mzwu8mq9xdtilpr"
#define abDbScreatkey @"le27tu0m54mjlc0"
#define abGoogleTiny @"AIzaSyD5c0jmblitp5KMZy2crCbueTU-yB1jMqI"

//notification
#define abSessionLogUpdated @"SessionLogUpdated"
#define abGmailLoggedOutNotification @"GmailLoggedOutNotification"
#define abDropBoxLoggedOutNotification @"DropBoxLoggedOutNotification"

//messages
#define abKeepSameLinkHelpTitle @"What is keep same link for all future upload?"
#define abKeepSameLinkHelpMessage  @"This feature will keep same short url for all future build/ipa uploaded with same bundle identifier, this means old build/ipa url will replaced by new ipa file. You can change the link by changing the Dropbox app folder name below. \n\nIf this option is enable, you can also download the previous build with same url."
#define abKeepSameLinkReadMoreURL @"https://iosappswirelessinstallation.codeplex.com/wikipage?title=KeepSameLink"

//team id constants
#define abiPhoneDeveloper @"iphone developer"
#define abiPhoneDistribution @"iphone distribution"
#define abFullName @"fullName"
#define abTeamName @"teamName"
#define abTeamId @"teamId"

//others
#define abEmptyString @""


//enums
typedef enum : NSUInteger {
    FileTypeIPA,
    FileTypeManifest,
    FileTypeJson,
} FileType;

typedef enum : NSUInteger {
    ScriptTypeGetScheme,
    ScriptTypeTeamId,
    ScriptTypeBuild,
} ScriptType;

#endif /* Constants_h */
