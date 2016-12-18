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
#define MailerBaseURL @"https://tryapp.github.io/mail"
#define GitHubLatestRelease @"https://api.github.com/repos/vineetchoudhary/AppBox-iOSAppsWirelessInstallation/releases/latest"

//dropbox
#define DbRoot kDBRootAppFolder
#define DbAppkey @"86tfx5bu3356fqo"
#define DbScreatkey @"mq4l1damoz8hwrr"

//notification
#define SessionLogUpdated @"SessionLogUpdated"


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
