#!/bin/sh

#  GetSchemeScript.sh
#  AppBox
#
#  Created by Vineet Choudhary on 30/11/16.
#  Copyright © 2016 Developer Insider. All rights reserved.

cd "${1}"
xcodebuild -list -json
exit
