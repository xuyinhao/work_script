#!/usr/bin/python
#-*-coding:utf8-*-
import re,subprocess

def rex(info,listname):
	for i in info:
		tmpinfo=re.findall(r"sd(.)",i)
		listname.append(tmpinfo[0]) 

pr=subprocess.Popen('cat /proc/fs/LeoFS/iStore/devinfo', shell=True,stdout=subprocess.PIPE)
procinfo= pr.stdout.readlines()
pb=[]
rex(procinfo,pb)
#print pb[:]      # dev info
bo=subprocess.Popen('df -h|grep "/boot\|meta"', shell=True,stdout=subprocess.PIPE)
boot=bo.stdout.readlines()
bome=[]
rex(boot,bome)
#print bome[:]    #boot  meta磁盘

p = subprocess.Popen(' fdisk -l|grep "Disk /dev"', shell=True,stdout=subprocess.PIPE)
fdiskinfo = p.stdout.readlines()
fd=[]
rex(fdiskinfo,fd)
#print fd[:]  #fdisk  磁盘

dfdev=subprocess.Popen('df -h|grep "leofs/data"', shell=True,stdout=subprocess.PIPE)
dfdevinfo=dfdev.stdout.readlines()
dfdev=[]
rex(dfdevinfo,dfdev)
#print dfdev[:]   #df 所有磁盘

print("————********fdisk有，devinfo没有的：*********————————")
for i in fd[:]:
	if i in pb[:]:
		pass
	elif i in bome[:]:
		pass
	else:	
		print i
print("-----************----------\n\n")

print("________*******mount有，devinfo没有的*********__________")

for j in dfdev[:]:
	#print j
	if j in pb[:]:
                pass
        elif j in bome[:]:
                pass
        else:
                print j
print("-----************----------")
