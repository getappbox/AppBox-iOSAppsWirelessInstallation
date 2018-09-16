#!/bin/sh

#  BuildScript.sh
#  AppBox
#
#  Created by Vineet Choudhary on 01/12/16.
#  Copyright © 2016 Developer Insider. All rights reserved.

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


#change directory to project
cd "${1}"

################################################
#               Make Archive                   #
################################################

#check either project is Xcode Project or Xcode Workspace
if [[ "${2}" == *"xcodeproj" ]]
then
    echo "Building Project..."

    #check either selected xcode is 9 or higher
    echo "Building Project with Xcode ${7}"
    if [[ ${7} -gt 9 || ${7} -eq 9 ]]
    then
        xcodebuild clean -project "${2}" -scheme "${3}" archive -archivePath "${4}" -allowProvisioningUpdates -allowProvisioningDeviceRegistration | "${8}" && exit ${PIPESTATUS[0]}
    else
        xcodebuild clean -project "${2}" -scheme "${3}" archive -archivePath "${4}" | "${8}" && exit ${PIPESTATUS[0]}
    fi

else
    echo "Building Workspace..."

    #check either selected xcode is 9 or higher
    echo "Building Project with Xcode ${7}"
    if [[ ${7} -gt 9 || ${7} -eq 9 ]]
    then
        xcodebuild clean -workspace "${2}" -scheme "${3}" archive -archivePath "${4}" -allowProvisioningUpdates -allowProvisioningDeviceRegistration | "${8}" && exit ${PIPESTATUS[0]}
    else
        xcodebuild clean -workspace "${2}" -scheme "${3}" archive -archivePath "${4}" | "${8}" && exit ${PIPESTATUS[0]}
    fi

fi
