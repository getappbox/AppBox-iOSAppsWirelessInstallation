#!/bin/sh

#  XcodeVersion.sh
#  AppBox
#
#  Created by Vineet Choudhary on 12/11/17.
#  Copyright © 2017 Developer Insider. All rights reserved.

#{1} - Xcode Path
#buildcommand
if [[ -z "${1}" ]]
then
    buildcommand="xcodebuild"
else
    buildcommand="${1}/Contents/Developer/usr/bin/xcodebuild"
fi

"$buildcommand" -version | grep Xcode
