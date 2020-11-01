#!/bin/bash
#设置系统参数
#一： /etc/sysctl.conf 文件增加内容；并执行sysctl -p 立即生效:
# net.ipv4.tcp_tw_reuse = 1
# net.ipv4.tcp_tw_recycle = 1
# net.ipv4.tcp_timestamps = 1
# net.ipv4.neigh.default.gc_thresh1 = 8192
# net.ipv4.neigh.default.gc_thresh2 = 32768 
# net.ipv4.neigh.default.gc_thresh3 = 65536
#二： /etc/security/limits.conf 增加内容
#  * - nofile  65000
#三： /etc/pam.d/login 增加内容
#  session required /lib/security/pam_limits.so
#!!! 最后重新登录一下 终端连接。sysctl -a 查看步骤一 设置内容是否一致
#   ulimit -a|grep "open file" 看看最后一列数字和设置的 步骤二 要一致

timewait[0]="net.ipv4.tcp_tw_reuse"
timewait[1]="net.ipv4.tcp_tw_recycle"
timewait[2]="net.ipv4.tcp_timestamps"
neighgc[0]="net.ipv4.neigh.default.gc_thresh1"
neighgc[1]="net.ipv4.neigh.default.gc_thresh2"
neighgc[2]="net.ipv4.neigh.default.gc_thresh3"
#设置的对于参数值reuse recycle timestamps gcthred1 2 3  maxopenfile
setvalue=(1 1 1 8192 32768 65536 65000)
  #setvalue=(0 0 0 512 1024 4096 4096)

etcsysctl="/etc/sysctl.conf"
etclimits1="/etc/security/limits.conf"
etclimits2="/etc/pam.d/login"
backpath="/usr/etc/"

function set_value() {
check_path
dtime=`date +%d%H%M%S`;mkdir -p $backpath/$dtime;cp -f $etcsysctl $etclimits1 $etclimits2 $backpath/$dtime
# time_wait; gc arp 优化
for i in ${timewait[@]} ${neighgc[@]}
do
    #echo $i
    sed -i "/^[\t]*${i}/d" $etcsysctl > /dev/null
    sed  -i "/^[ ]*${i}/d" $etcsysctl > /dev/null
done

echo ${timewait[0]}=${setvalue[0]} >> ${etcsysctl}          #数值
echo ${timewait[1]}=${setvalue[1]} >> ${etcsysctl}
echo ${timewait[2]}=${setvalue[2]} >> ${etcsysctl}
echo ${neighgc[0]}=${setvalue[3]} >> ${etcsysctl}
echo ${neighgc[1]}=${setvalue[4]} >> ${etcsysctl}
echo ${neighgc[2]}=${setvalue[5]} >> ${etcsysctl}
sysctl -p /etc/sysctl.conf  > /dev/null 		 #可以立即生效

#ulimit open files优化
linenum=`cat -n  ${etclimits1} |grep -|grep nofile|grep "\*\|root"|awk '{print $1}'`
while [[ $linenum != "" ]];do
    newline=`echo $linenum|awk '{print $1}'`
    sed -i "${newline}d" ${etclimits1}
    linenum=`cat -n  ${etclimits1} |grep -|grep nofile|grep "\*\|root"|awk '{print $1}'`
done
echo "* - nofile ${setvalue[6]} " >> ${etclimits1}
echo "root - nofile ${setvalue[6]} " >> ${etclimits1}

pamlimit=`cat -n ${etclimits2}|grep session |grep required |grep "pam_limits.so"|awk '{print $1}'`
while [[ $pamlimit != "" ]];do
    pamline=`echo $pamlimit|awk '{print $1}'`
    sed -i "${pamline}d" ${etclimits2}
    pamlimit=`cat -n  ${etclimits2} |grep session|grep required|grep "pam_limits.s"|awk '{print $1}'`
done
echo "session required pam_limits.so" >> ${etclimits2}
##需要重新登录session生效
echo -e "\033[31m设置优化参数ok,请重新登录终端ssh使配置其生效,然后执行check;\033[0m"
}


function check_value() {
check_path

ret[0]=`sysctl -a|grep ${timewait[0]}|awk '{print $3}'`  
ret[1]=`sysctl -a|grep ${timewait[1]}|awk '{print $3}'`  
ret[2]=`sysctl -a|grep ${timewait[2]}|awk '{print $3}'`  
ret[3]=`sysctl -a|grep ${neighgc[0]}|awk '{print $3}'`   
ret[4]=`sysctl -a|grep ${neighgc[1]}|awk '{print $3}'`   
ret[5]=`sysctl -a|grep ${neighgc[2]}|awk '{print $3}'`  
ret[6]=`ulimit -a|grep "open file"|awk '{print $4}'` 
clear
echo "check V: ${setvalue[@]}"
[[ ${ret[@]} = "${setvalue[@]}" ]] && echo -e "\033[1;32mcheck value pass;已经启动的程序需要重启才会生效 \033[0m"
[[ ${ret[@]} != "${setvalue[@]}" ]] && echo -e "\033[31mcheck value failed : ${ret[@]} \033[0m"
}
check_path(){
for i in ${etcsysctl} ${etclimits1} ${etclimits2}
do
    [ ! -f $i ] && echo -e "\033[31mNo path:${i};exit \033[0m" && exit
done

}

echo "pls select set(0) or check(1) value func?"
select var in "Set value" "Check value"; do
    break;
done
if [[ $var == "Set value" ]];then
    set_value
elif [[ $var == "Check value" ]];then
    check_value
else
    echo "choice 0 or 1"
fi 
