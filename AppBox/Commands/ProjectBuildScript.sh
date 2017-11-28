#!/bin/sh

#  BuildScript.sh
#  AppBox
#
#  Created by Vineet Choudhary on 01/12/16.
#  Copyright © 2016 Developer Insider. All rights reserved.

#{1} - Project Directory

#Make Archove
#{2} - -workspace VisualStudioMobileCenterDemo.xcworkspace or -project -vsmcd.xcodeproj
#{3} - VisualStudioMobileCenterDemo
#{4} - /Users/emp195/Desktop/VisualStudioMobileCenterDemoGitHub/VisualStudioMobileCenterDemo/build/VSMCD.xcarchive


#Make IPA
#{5} - "/Users/emp195/Desktop/VisualStudioMobileCenterDemoGitHub/VisualStudioMobileCenterDemo/build/VSMCD.xcarchive"
#{6} - /Users/emp195/Desktop/VisualStudioMobileCenterDemoGitHub/VisualStudioMobileCenterDemo/build/
#{7} - /Users/emp195/Desktop/VisualStudioMobileCenterDemoGitHub/VisualStudioMobileCenterDemo/exportoption.plist


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
    if [[ "${7}" > "9" || "${7}" == "9" ]]
    then
        echo "Building Project with Xcode 9"
        xcodebuild clean -project "${2}" -scheme "${3}" archive -archivePath "${4}" -allowProvisioningUpdates -allowProvisioningDeviceRegistration
    else
        echo "Building Project with Xcode 8"
        xcodebuild clean -project "${2}" -scheme "${3}" archive -archivePath "${4}"
    fi

else
    echo "Building Workspace..."

    #check either selected xcode is 9 or higher
    if [[ "${7}" > "9" || "${7}" == "9" ]]
    then
        echo "Building Project with Xcode 9"
        xcodebuild clean -workspace "${2}" -scheme "${3}" archive -archivePath "${4}"
    else
        echo "Building Project with Xcode 8"
        xcodebuild clean -workspace "${2}" -scheme "${3}" archive -archivePath "${4}"
    fi

fi

####################################
#            Make IPA              #
####################################
echo "Creating IPA..."
#check either selected xcode is 9 or higher
if [[ "${7}" > "9" || "${7}" == "9" ]]
then
    echo "Creatomg IPA with Xcode 9"
    xcodebuild -exportArchive -archivePath "${4}" -exportPath "${5}" -exportOptionsPlist "${6}" -allowProvisioningUpdates -allowProvisioningDeviceRegistration
else
    echo "Creatomg IPA with Xcode 8"
    xcodebuild -exportArchive -archivePath "${4}" -exportPath "${5}" -exportOptionsPlist "${6}"
fi
