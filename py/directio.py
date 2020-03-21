#!/usr/bin/python
import os,sys
import time
fd = os.open('dd1', os.O_TRUNC|os.O_RDWR|os.O_CREAT)
os.write(fd,"aaaaaaaaaaaaaaaaaaa")
with open("dd1.t",'w') as f:
	f.write("fffffffffffffff")
while [ 1 ]:
	pass
