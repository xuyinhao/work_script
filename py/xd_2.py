#!/usr/bin/python
import sys,time
import os,subprocess
import re
import math
import threading
import multiprocessing
import threadpool

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
    p = subprocess.Popen(getgrptool + ' ' + filename +" 0", shell=True,stdout=subprocess.PIPE)
    groupinfos = p.stdout.readlines()
    return groupinfos

def filespan(filename):
    p = subprocess.Popen(getleyouttool + ' -s ' + filename, shell=True, stdout=subprocess.PIPE)
    result = p.stdout.readlines()
    p = re.compile(r'xd, N:(\d+), M:(\d+)')
    nm = re.findall(p,''.join(result))
    return int(nm[0][0]) + int(nm[0][1])
   
def getID(pattern,groupinfo):
    disks = [] 
    disks = re.findall(pattern,groupinfo)
    return disks

def get_chk_device(groupinfos,filename):
    num = 0
    n = 0
    istore = []
    pattern = re.compile(r'(\d+)\(\d*')
    if chkistore:
        spannum = filespan(filename)
        largest = math.ceil(float(spannum)/istorenum)
        p = re.compile(r'(\(\d+\))')
    for groupinfo in groupinfos:
        disks = getID(pattern,groupinfo)
        if chkistore:
            istore = getID(p,groupinfo)
	if disks:
            num += 1
            for j in disks:
                if disks.count(j) > 1:
                    print "%s's leyout error at line %d with (%s):%s!\n" % (filename,num,j,disks),
                    break
        if chkistore:
            if istore:
                for j in istore:
                    if j == "(0)":
                         print "%s's leyout error at line %d with istore %s!\n" % (filename,num,j),
                    if istore.count(j) > largest:
                        print "%s's leyout error at line %d with istore %s:%s!\n" % (filename,num,j,istore),
                        break
            
def check_file(files):
    #for filename in files:
    filename=files
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
    filelist = 'filelists.a'
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
             #thr = 10 if len(lines)>10 else len(lines)
             try:
               #  p = multiprocessing.Pool(thr)
               #  for i in lines:
#                     threading.Thread(target=check_file,args=(lines[i::thr],),name="thread-"+str(i)).start()
               #       p.apply_async(check_file,args=(i,))
               #  p.close()
               #  p.join()
        	start_time = time.time()
        	pool = threadpool.ThreadPool(10)
        	requests = threadpool.makeRequests(check_file, lines)
        	[pool.putRequest(req) for req in requests]
        	pool.wait()
        	print '%d second'% (time.time()-start_time) 
             except KeyboardInterrupt:
                 print "Caught KeyboardInterrupt, terminating workers!"
                 p.terminate()
                 p.join()

             

