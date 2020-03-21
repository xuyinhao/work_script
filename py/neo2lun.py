#!/usr/bin/env python
#coding:utf-8

#在main函数修改参数
import urllib
import urllib2
import cookielib
import json
import time
import subprocess
class Neo_web(object):
    def __init__(self):
        self.cj = cookielib.CookieJar()     # 初始化一个cookie补全，用于存储cookie
        self.handler = urllib2.HTTPCookieProcessor(self.cj) # 创建一个cookie处理器
        self.opener = urllib2.build_opener(self.handler) # 创建一个功能强大的opener

    def post_response(self,url,post): # post提交
        post_data = urllib.urlencode(post) # 编码post数据为标准html格式
        req = urllib2.Request(url,post_data) # 做为data参数传给Request对象,由request做post数据隐式提交,此处也可以写成data=post_data
        response = self.opener.open(req) # 登陆网站，获取返回结果
        print response.url

    def get_response(self,url,post):  # get方式提交数据
        print('url:'+str(url)+'  postdataL:'+ str(post))
        get = urllib.urlencode(post)  # 将提交的数据编码成html标准格式
        response = self.opener.open(url,get)  # 将标准的编码数据放到url后面，变成真正的url地址
      #  print(response.read())
        try:
            JsData = json.loads(response.read())
            return JsData['datas']
        except Exception as e:
            return False
def add_target(loginurl,logininfo,targetname,layout,repnum,disknum):
    aa=Neo_web()
    aa.post_response(loginurl,logininfo)

    argrep={'targetName': targetname,
         'reservationOther': 'false',
         'reservation': 'false',
         'provisioning': 'true',
         'setFileLayout': 'true',
         'type': layout,
         'repNumber': repnum,
         'diskSpanNumber':disknum}

    aa.post_response(url+'/lfsmanage/iscsiconfig/addIscsiTarget.do',argrep)
def add_lun(targetname,loginurl,logininfo,spannum,spansize,blksize,size):
     #添加LUN
    aa=Neo_web()
    aa.post_response(loginurl,logininfo)
    for bs in blksize:
       # print('bs:'+bs)
        for sn in spannum:
        #    print('sn'+sn)
            for sz in spansize:
         #       print('ss'+sz)
                lunname='py_testlun_'+str(bs)+'_'+str(size)+'_'+str(sn)+'_'+str(sz)
                size+=1
                time.sleep(1)
                print(lunname)
                arglun1={'targetName':targetname,
                        'lunName':lunname,
                        'blockSize':bs,
                        'size':size,
                        'unit':'GB',
                        'writeCache':'false',
                        'allocate':'false',
                        'spannum':sn,
                        'spansize':sz}
                # aa=kaoqin_login()
                # aa.post_response(loginurl,logininfo)
                aa.post_response(url+'/lfsmanage/iscsiconfig/addIscsiLun2.do',arglun1)
def iscsi_u():
	subprocess.Popen('iscsiadm -m session -u',shell=True)
	#time.sleep(1)
	subprocess.Popen('iscsiadm -m session -u',shell=True)
	#print('logout all iscsi session')
	subprocess.Popen('iscsiadm -m session',shell=True)
def iscsi_login(ip,targetname):
	cmd='iscsiadm -m discovery -t st -p '+str(ip)+'|grep '+targetname+"|awk 'BEGIN{ORS=\"\"}{print $2}'"
	return_code=subprocess.Popen(cmd,shell=True,stdout=subprocess.PIPE)
	re=return_code.stdout.readlines()
	if  len(re) < 1 :	
		print("Not find Target :  %s --> has some errors. CMD:%s " %(targetname,cmd))
		exit(1)
	print(str(''.join(re)))
	time.sleep(1)
	cmd2='iscsiadm -m node -T '+str(''.join(re))+ ' -p ' +str(ip)+' -l'
	print(cmd2)
	subprocess.Popen(cmd2,shell=True)
def get_iscsi_dev():
	cmd='lsblk |grep disk|grep -v " 8:"|grep -v "leo"'+"|awk '{print $1}'"
        return_code=subprocess.Popen(cmd,shell=True,stdout=subprocess.PIPE)
        re=return_code.stdout.readlines()
	print(''.join(re))

if __name__ == '__main__':
    url="http://13.10.12.31"    #managerd节点
    iscsitarget='13.10.12.30' #连接的 target server
    loginurl=url+'/login.do'
    header={'User-Agent':'Apache-HttpClient/4.5.3 (Java/1.8.0_131)','Content-Type':'application/x-www-form-urlencoded'}
    logininfo={'username':'admin','password':'admin'}
    #layout='rep';repnum='2';disknum=''   #leoraid,xd,rep
    layout='xd';repnum='1';disknum='2'   #leoraid,xd,rep
    size=150
    blksize=['512']
    spannum=['1','2','4','8','16']
   # spansize=['65536','131072','262144','67108864','134217728','536870912']  #spansize=[64K,128K，256K，64M，128M，512M]
    spansize=['131072','262144','33554432','67108864','134217728']
    targetname='pytest'+layout+disknum+repnum    #无需更改
    #退出当前所有session
#    iscsi_u()
    #添加target
    add_target(loginurl,logininfo,targetname,layout,repnum,disknum)
    #添加lun
    add_lun(targetname,loginurl,logininfo,spannum,spansize,blksize,size)
#    print("wait 20s... target,lun creating");time.sleep(20)
	
#    iscsi_login(iscsitarget,targetname)
#    get_iscsi_dev()

