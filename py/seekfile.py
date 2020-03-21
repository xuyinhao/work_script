#!/usr/bin/python
#!coding=utf8
import sys
if len(sys.argv) != 4:
        print "usgae : filename offset length"
        sys.exit(-1)
filename=sys.argv[1]
f=open(filename,'r')
offset=long(sys.argv[2])
length=long(sys.argv[3])
#print "start offset is :",f.tell()
f.seek(offset,0)
print "Start offset is :",offset
#f.read(length)
print f.read(length)
print "The  length  is :",length
f.close
