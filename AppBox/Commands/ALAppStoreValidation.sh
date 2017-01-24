#!/bin/sh

#  ALAppStoreValidation.sh
#  AppBox
#
#  Created by Vineet Choudhary on 24/01/17.
#  Copyright © 2017 Developer Insider. All rights reserved.

# Validate App
#{1} - IPA File Path
#{2} - itunesconnect username
#{3} - itunesconnect password
"/Applications/Xcode.app/Contents/Applications/Application Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Versions/A/Support/altool" --validate-app -f "${1}" -u "${2}" -p "${3}" --output-format xml
