#!/bin/sh

#  PythonServer.sh
#  AppBox
#
#  Created by Vineet Choudhary on 09/09/17.
#  Copyright © 2017 Developer Insider. All rights reserved.

#${1} - Build Directory

cd "${1}"
python -m $(python -c 'import sys; print("http.server 8888" if sys.version_info[:2] > (2,7) else "SimpleHTTPServer 8888")')
#python -m http.server --bind 0.0.0.0 8888
