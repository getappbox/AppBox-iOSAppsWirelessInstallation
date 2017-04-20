#!/bin/sh

#  InstallPrivateKey.sh
#  AppBox
#
#  Created by Vineet Choudhary on 10/04/17.
#  Copyright © 2017 Developer Insider. All rights reserved.

# ${1} - Certificate path
# ${2} - Password

if [[ "${1}" == *"p12" ]]
then


echo "Installing certificate..."
security import ${1} -k ~/Library/Keychains/login.keychain -P ${2} -T /usr/bin/codesign

else

echo "Installing Mobile Provision..."
open ${1}

fi
