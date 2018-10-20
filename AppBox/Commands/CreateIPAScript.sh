#!/bin/sh

#  CreateIPAScript.sh
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

####################################
#            Make IPA              #
####################################
echo "Creating IPA..."

#check either selected xcode is 9 or higher
echo "Creating IPA with Xcode ${7}"
if [[ ${7} -gt 9 || ${7} -eq 9 ]]
then
    "$buildcommand" -exportArchive -archivePath "${4}" -exportPath "${5}" -exportOptionsPlist "${6}" -allowProvisioningUpdates -allowProvisioningDeviceRegistration
else
    "$buildcommand" -exportArchive -archivePath "${4}" -exportPath "${5}" -exportOptionsPlist "${6}"
fi
echo "End of build script."
