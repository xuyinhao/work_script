#!/usr/bin/python
#-*-coding:utf8-*-
import sys
import os,subprocess
import re
import math
import threading
import multiprocessing

def crt_filelist(filepath):
    logfile = open(filelist,'a+')
    list = os.listdir(filepath)
    for i in range(len(list)):
	ospath = os.path.join(filepath, list[i])
        if os.path.isfile(ospath):
            logfile.write(ospath+'\n')
        if os.path.isdir(ospath):
            crt_filelist(ospath)
    logfile.close()

def getfilegrp(filename):
    p = subprocess.Popen(getgrptool + ' ' + "\""+filename +"\""+" 0", shell=True,stdout=subprocess.PIPE)
    groupinfos = p.stdout.readlines()
 #   print(groupinfos)
    return groupinfos

def filespan(filename):
    p = subprocess.Popen(getleyouttool + ' -s ' +"\""+ filename +"\"", shell=True, stdout=subprocess.PIPE)
    result = p.stdout.readlines()
   # p = re.compile(r'xd, N:(\d+), M:(\d+)')
    p = re.compile(r'single strip, dsknum:(\d+), repnum:(\d+)') #single strip, dsknum:4, repnum:4
    nm = re.findall(p,''.join(result))
 #   print(nm)  #dsknum  #repnum
    return int(nm[0][0]),int(nm[0][1])
   
def getID(pattern,groupinfo):
    disks = [] 
    disks = re.findall(pattern,groupinfo)
    return disks

def get_chk_device(groupinfos,filename):
    num = 0
    n = 0
    istore = []
    pattern = re.compile(r'(\d+)\(\d*')
    
    dsknum,repnum = filespan(filename)
    totle=dsknum*repnum
 #       print(dsknum,repnum)  #拿到strip dsk rep
 #       largest = math.ceil(float(spannum)/istorenum)
    p = re.compile(r'(\(\d+\))')
 #   print(groupinfos)
    num=0
    for groupinfo in groupinfos:
	if groupinfo: print(filename+'\n'+groupinfo)
        disks = getID(pattern,groupinfo)
        tm=[]
	if disks:
	    num+=1
            #print("disk",disks)
	    for j in range(dsknum):
		repnum2=repnum
	        dskb=repnum
		flag=0
		
	        for i in range(0,totle,repnum2):
	        #    print i,repnum2
		   # print(disks[i:repnum2])
		    if len(disks[i:repnum2]) != len(set(disks[i:repnum2])):
			print "error:",filename,num,i,disks[i:repnum2]
			#print "%s's layout error at line %d -- %l!\n" %(filename,j,disks[i:dsknum2] 	
			flag=1
			break
         	    repnum2+=dskb
		if flag==1:break
    if chkistore:
	num=0
	for groupinfo in groupinfos:
	    p = re.compile(r'(\(\d+\))')
            istore = getID(p,groupinfo)
	    if istore:
		num+=1
	       # print(istore)
	    	for j in istore:
		    repnum2=repnum
                    dskb=repnum
		    flag=0
		#print j
	    	    for i in range(0,totle,repnum2):
		#	print(totle,repnum2)
			#print istore[i:repnum2]
			if "(0)" in istore[i:repnum2]:	
				print "error (0)",filename,num,i
				print istore
				flag=1
				break
			#print i,repnum2
			#print istore[i:repnum2]
		        elif len(set(istore[i:repnum2])) != 1:
				flag=1
				print "error istore num",filename,i
				break
			repnum2+=dskb
		    if flag==1:break
		#if flag==1:break
#	if disks:
 #           num += 1
  #          for j in disks:
   #             if disks.count(j) > 1:
    #                print "%s's leyout error at line %d with (%s):%s!\n" % (filename,num,j,disks),
     #               break
      #  if chkistore:
       #     if istore:
        #        for j in istore:
         #           if j == "(0)":
          #               print "%s's leyout error at line %d with istore %s!\n" % (filename,num,j),
           #         if istore.count(j) > largest:
             #           print "%s's leyout error at line %d with istore %s:%s!\n" % (filename,num,j,istore),
            #            break
            
def check_file(files):
    for filename in files:
        f=filename.replace("\n", "")
        grpinfo = getfilegrp(f)
        get_chk_device(grpinfo,f)

if __name__ == "__main__":
    if len(sys.argv) > 3 or len(sys.argv) < 2:
    	print "Usage:%s name[file or dir] [istorenum]" % (sys.argv[0])
        exit(1)
    chkistore = False
    getgrptool = '/LeoCluster/bin/leofs_getgrpinfo'
    getleyouttool = '/LeoCluster/bin/leofslayout3'
    filelist = 'filelists.dir'
    filepath = sys.argv[1]
    if len(sys.argv) == 3:
        chkistore = True
        istorenum = int(sys.argv[2])

    filepath = sys.argv[1]
    if os.path.isfile(filepath):
        check_file([filepath])
    elif os.path.isdir(filepath):
        if os.path.isfile(filelist):
            os.remove(filelist)
        crt_filelist(filepath)
        with open(filelist,'r') as f:
             lines = f.readlines()
             thr = 1 if len(lines)>1 else len(lines)
             try:
                 p = multiprocessing.Pool(thr)
                 for i in range(thr):
#                     threading.Thread(target=check_file,args=(lines[i::thr],),name="thread-"+str(i)).start()
                      p.apply_async(check_file,args=(lines[i::thr],))
                 p.close()
                 p.join()
             except KeyboardInterrupt:
                 print "Caught KeyboardInterrupt, terminating workers!"
                 p.terminate()
                 p.join()

             

