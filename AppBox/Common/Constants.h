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
#define abMailerBaseURL @"https://tryapp.github.io/mail"
#define abGitHubLatestRelease @"https://api.github.com/repos/vineetchoudhary/AppBox-iOSAppsWirelessInstallation/releases/latest"

//dropbox
#define abDbRoot kDBRootAppFolder
#define abDbAppkey @"86tfx5bu3356fqo"
#define abDbScreatkey @"mq4l1damoz8hwrr"

//notification
#define abSessionLogUpdated @"SessionLogUpdated"

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
