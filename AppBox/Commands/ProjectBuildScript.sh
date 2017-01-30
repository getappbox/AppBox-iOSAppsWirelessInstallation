#!/bin/sh

#  BuildScript.sh
#  AppBox
#
#  Created by Vineet Choudhary on 01/12/16.
#  Copyright © 2016 Developer Insider. All rights reserved.

#{1} - Project Directory
cd "${1}"

if [[ "${2}" == *"xcodeproj" ]]
then

#Make Archove
#{2} - -workspace VisualStudioMobileCenterDemo.xcworkspace or -project -vsmcd.xcodeproj
#{3} - VisualStudioMobileCenterDemo
#{4} - /Users/emp195/Desktop/VisualStudioMobileCenterDemoGitHub/VisualStudioMobileCenterDemo/build/VSMCD.xcarchive

echo "Building Project..."
xcodebuild clean -project "${2}" -scheme "${3}" archive -archivePath "${4}"

else

echo "Building Workspace..."
xcodebuild clean -workspace "${2}" -scheme "${3}" archive -archivePath "${4}"

fi


#Make IPA
#{5} - "/Users/emp195/Desktop/VisualStudioMobileCenterDemoGitHub/VisualStudioMobileCenterDemo/build/VSMCD.xcarchive"
#{6} - /Users/emp195/Desktop/VisualStudioMobileCenterDemoGitHub/VisualStudioMobileCenterDemo/build/
#{7} - /Users/emp195/Desktop/VisualStudioMobileCenterDemoGitHub/VisualStudioMobileCenterDemo/exportoption.plist

echo "Creating IPA..."
xcodebuild -exportArchive -archivePath "${5}" -exportPath "${6}" -exportOptionsPlist "${7}"
