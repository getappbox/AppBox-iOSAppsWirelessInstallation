#!/bin/sh

#  PythonServer.sh
#  AppBox
#
#  Created by Vineet Choudhary on 09/09/17.
#  Copyright © 2017 Developer Insider. All rights reserved.

#${1} - Build Directory

cd "${1}"

python3 -m http.server --bind 0.0.0.0 8000
