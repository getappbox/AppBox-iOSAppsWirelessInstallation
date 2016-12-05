#!/bin/sh

#  TeamIDScript.sh
#  AppBox
#
#  Created by Vineet Choudhary on 01/12/16.
#  Copyright © 2016 Developer Insider. All rights reserved.

#{1} - Project Directory
cd "${1}"

#Get Build Settings
xcodebuild -showBuildSettings
