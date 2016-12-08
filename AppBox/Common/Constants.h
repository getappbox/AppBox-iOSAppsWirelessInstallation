//
//  Constants.h
//  AppBox
//
//  Created by Vineet Choudhary on 28/11/16.
//  Copyright © 2016 Developer Insider. All rights reserved.
//

#ifndef Constants_h
#define Constants_h

//dropbox
#define DbRoot kDBRootAppFolder
#define DbAppkey @"86tfx5bu3356fqo"
#define DbScreatkey @"mq4l1damoz8hwrr"

//notification
#define SessionLogUpdated @"SessionLogUpdated"

//enums
typedef enum : NSUInteger {
    FileTypeIPA,
    FileTypeManifest
} FileType;

typedef enum : NSUInteger {
    ScriptTypeGetScheme,
    ScriptTypeTeamId,
    ScriptTypeBuild,
} ScriptType;

#endif /* Constants_h */
