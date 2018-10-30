#!/bin/sh

#  BuildScript.sh
#  AppBox
#
#  Created by Vineet Choudhary on 01/12/16.
#  Copyright © 2016 Developer Insider. All rights reserved.

# Arguments Descriptions -
#{1} - Project Directory

#Make Archove
#{2} - Project Workspace or XcodeProject -workspace VisualStudioMobileCenterDemo.xcworkspace or -project -vsmcd.xcodeproj
#{3} - Project Scheme - VisualStudioMobileCenterDemo
#{4} - Project Archive Path - /Users/emp195/Desktop/VisualStudioMobileCenterDemoGitHub/VisualStudioMobileCenterDemo/build/VSMCD.xcarchive


#Make IPA
#{4} - Project Archive Path - /Users/emp195/Desktop/VisualStudioMobileCenterDemoGitHub/VisualStudioMobileCenterDemo/build/VSMCD.xcarchive
#{5} - IPA Export Path - /Users/emp195/Desktop/VisualStudioMobileCenterDemoGitHub/VisualStudioMobileCenterDemo/build/
#{6} - IPA Export options plist - /Users/emp195/Desktop/VisualStudioMobileCenterDemoGitHub/VisualStudioMobileCenterDemo/exportoption.plist


#Others
#{7} - Xcode Version
#{8} - xcpretty path
#{9} - Xcode Path

#buildcommand
if [[ -z "${9}" ]]
then
    buildcommand="xcodebuild"
else
    buildcommand="${9}/Contents/Developer/usr/bin/xcodebuild"
fi

#change directory to project
cd "${1}"

################################################
#               Make Archive                   #
################################################

#check if build with xcpretty or not
if [[ "${8}" == "" ]]
then
    echo "XCPretty Disabled..."

    #check either project is Xcode Project or Xcode Workspace
    if [[ "${2}" == *"xcodeproj" ]]
    then
        echo "Building Project..."
        echo "Building Project with Xcode ${7}"

        #check either selected xcode is 9 or higher
        if [[ ${7} -gt 9 || ${7} -eq 9 ]]
        then
            "$buildcommand" clean -project "${2}" -scheme "${3}" archive -archivePath "${4}" -allowProvisioningUpdates -allowProvisioningDeviceRegistration
        else
            "$buildcommand" clean -project "${2}" -scheme "${3}" archive -archivePath "${4}"
        fi

    else
        echo "Building Workspace..."
        echo "Building Project with Xcode ${7}"

        #check either selected xcode is 9 or higher
        if [[ ${7} -gt 9 || ${7} -eq 9 ]]
        then
            "$buildcommand" clean -workspace "${2}" -scheme "${3}" archive -archivePath "${4}" -allowProvisioningUpdates -allowProvisioningDeviceRegistration
        else
            "$buildcommand" clean -workspace "${2}" -scheme "${3}" archive -archivePath "${4}"
        fi
    fi
else
    #check either project is Xcode Project or Xcode Workspace
    if [[ "${2}" == *"xcodeproj" ]]
    then
        echo "Building Project..."
        echo "Building Project with Xcode ${7}"

        #check either selected xcode is 9 or higher
        if [[ ${7} -gt 9 || ${7} -eq 9 ]]
        then
            "$buildcommand" clean -project "${2}" -scheme "${3}" archive -archivePath "${4}" -allowProvisioningUpdates -allowProvisioningDeviceRegistration | "${8}" && exit ${PIPESTATUS[0]}
        else
            "$buildcommand" clean -project "${2}" -scheme "${3}" archive -archivePath "${4}" | "${8}" && exit ${PIPESTATUS[0]}
        fi

    else
        echo "Building Workspace..."
        echo "Building Project with Xcode ${7}"

        #check either selected xcode is 9 or higher
        if [[ ${7} -gt 9 || ${7} -eq 9 ]]
        then
            "$buildcommand" clean -workspace "${2}" -scheme "${3}" archive -archivePath "${4}" -allowProvisioningUpdates -allowProvisioningDeviceRegistration | "${8}" && exit ${PIPESTATUS[0]}
        else
            "$buildcommand" clean -workspace "${2}" -scheme "${3}" archive -archivePath "${4}" | "${8}" && exit ${PIPESTATUS[0]}
        fi
    fi
fi
