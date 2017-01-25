#!/bin/sh

#  ALAppStore.sh
#  AppBox
#
#  Created by Vineet Choudhary on 05/01/17.
#  Copyright © 2017 Developer Insider. All rights reserved.

# Upload App
#{1} - Script Type
#{2} - AL Location
#{3} - IPA File Path
#{4} - itunesconnect username
#{5} - itunesconnect password

if [ "${1}" == "validate-app" ]
    then

    if [ "${5}" == "AppBox - iTunesConnect" ]
        then
            "${2}" --validate-app -f "${3}" -u "${4}" -p @keychain:"${5}" --output-format xml
        else
            "${2}" --validate-app -f "${3}" -u "${4}" -p "${5}" --output-format xml
    fi

elif [ "${1}" == "upload-app" ]
    then

    if [ "${5}" == "AppBox - iTunesConnect" ]
        then
            "${2}" --upload-app -f "${3}" -u "${4}" -p @keychain:"${5}" --output-format xml
        else
            "${2}" --upload-app -f "${3}" -u "${4}" -p "${5}" --output-format xml
    fi

elif [ "${1}" == "validate-user"]
    then

    if [ "${5}" == "AppBox - iTunesConnect" ]
        then
            "${2}" --upload-app -f "${3}" -u "${4}" -p @keychain:"${5}" --output-format xml
        else
            "${2}" --upload-app -f "${3}" -u "${4}" -p "${5}" --output-format xml
    fi
fi
