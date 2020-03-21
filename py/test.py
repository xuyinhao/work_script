#!/bin/env python
import re
import sys
pathstr=sys.argv[1]
print("path: "+str(pathstr))

s= re.match("^\.{1,2}$",pathstr)
print s,type(s)
