#!/usr/bin/env python3
"""
   given a exiv2 dump, find the Image timestamp
"""

import sys
import re

sin = sys.stdin.read()
patt = r'^Image timestamp : \d+:\d+:\d+ (\d+):\d+\d+'
hr = re.findall(patt, sin, re.MULTILINE)
if len(hr) > 0:
    hr = int(hr[0])
    if hr == 12:
        hr = "12pm"
    elif hr == 0:
        hr = "12am"
    elif hr > 12:
        hr = "{}pm".format(hr - 12)
    else:
        hr = "{}am".format(hr)
    print(hr)
else:
    print("XXX")
#
# done.
