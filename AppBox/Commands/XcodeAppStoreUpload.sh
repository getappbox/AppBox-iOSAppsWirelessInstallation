#!/bin/sh

#  XcodeAppStoreUpload.sh
#  AppBox
#
#  Created by Vineet Choudhary on 05/01/17.
#  Copyright © 2017 Developer Insider. All rights reserved.

# Upload App
"/Applications/Xcode.app/Contents/Applications/Application Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Versions/A/Support/altool" --upload-app -f "${2}" -u "${3}" -p "${4}" --output-format xml
