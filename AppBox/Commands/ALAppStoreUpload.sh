#!/bin/sh

#  ALAppStoreUpload.sh
#  AppBox
#
#  Created by Vineet Choudhary on 05/01/17.
#  Copyright © 2017 Developer Insider. All rights reserved.

#{1} - Application Loader Directory
cd "${1}"

# Validate App
#{2} - IPA File Path
#{3} - itunesconnect username
#{4} - itunesconnect password
altool --validate-app -f "${2}" -u "${3}" -p "${4}" --output-format xml


# Upload App
altool --upload-app -f "${2}" -u "${3}" -p "${4}" --output-format xml
