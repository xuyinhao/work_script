#!/bin/bash
##################################
#功能描述: 通过pod网络ns nc svc ip+port 判断是否可以通信
#2020-07  xuyh
# 注意事项：
# 	1. 需要root在k8s master节点执行
#	2. 安装好对应安装包比如sshpass,nsenter,nc...
##################################

## TODO需求，跑指定的namespace （pod,svc)
##  考虑租户 访问策略  放开策略的才可以测试

#### 可修改变量值
SSHPASS=onceas               #ssh 密码,集群所有节点需要一致|或者自行先免密
declare -i SSHPORT=22        #ssh 端口，集群所有节点需要一致
declare NAMESPACE=""         #定义要测试的namespace，默认为空，表示测试所有namespace. (多个ns用 | 隔开)
			     # 示例值："dual|default|modd|mmapp" ，表示测试这4个ns中所有pod,svc连通信
declare SKIP_NAMESPACE=""    #不测试其pod,svc , 示例"" , 示例"aaa" ,示例"kube-system|app|boc"
declare -i MUL_RUN=0         # 1:每个机器执行自己的pod测试 ||   0:由当前1个机器串行ssh执行测试-会比较慢
# 需要pod2svcLocalcheck.sh 脚本在执行脚本路径下
declare -i SKIP_NO_EP=1      # 1：检查svc没有ep则过滤此svc不进行测试 ||  0:所有含有ip(CLUSTER-IP)的svc都要被测试
declare -i LOCAL_CHECK_SVC=1  # 用本机判断nc,测试svc是否通信，不通信则不记录该svc . pod不会测试此svc  1：检查，0，不检查
declare -i NC_WAIT_TIME=2    #nc wait time,测试 -w 超时(单位:s)
declare -i PASS_RETRY=4      #如果可以nc成功的话，则再继续重复执行这么多次nc通信测试
declare -i SHOW_LOG=1        #测试过程中打印日志，
declare -i DEBUG=0           #打印debug信息的日志

########### 不需要修改 #############
MUL_SCRIPT_NAME="pod2svcLocalcheck.sh"
cpath=$(dirname $0)
fpath=$(
  cd $cpath
  pwd
)
LOG_FILE_FULL_PATH=/var/log/pod2svc
mkdir -p $LOG_FILE_FULL_PATH || $(
  echo "failed init log path,exit"
  exitsh
)
allNodeFilePath=$LOG_FILE_FULL_PATH/.p2s.allnodes
allSvcFilePath=$LOG_FILE_FULL_PATH/.p2s.allsvcip
svcTcpFile=$LOG_FILE_FULL_PATH/.p2s.svcTcp.file
svcUdpFile=$LOG_FILE_FULL_PATH/.p2s.svcUdp.file
svcNodeTcpFile=$LOG_FILE_FULL_PATH/.p2s.svcTcp.file.node
svcNodeUdpFile=$LOG_FILE_FULL_PATH/.p2s.svcUdp.file.node
ScriptPidPath=$LOG_FILE_FULL_PATH/.id
echo $$ >$ScriptPidPath
log_file=${LOG_FILE_FULL_PATH}/info.log
error_file=${LOG_FILE_FULL_PATH}/error.log
error_file_end=${LOG_FILE_FULL_PATH}/error.end.log
error_file_deny=${LOG_FILE_FULL_PATH}/error.deny.log
debug_file=${LOG_FILE_FULL_PATH}/debug.log
SSH_OPTION="-oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null"
#---
if [ "x$SKIP_NAMESPACE" == "x" ];then
  SKIP_NAMESPACE="DEFAULT_NOT_EXSIT_VALUE_2020"
fi
#--
################ function ################
### 日志 ###
log() {
  local logLevel="$1" #info,error
  local message="$2"
  local lineNo="$3"
  local logTime="$(date +'%Y-%m-%d_%T')"
  if [ "$logLevel" == "info" ]; then
    logFile=$log_file
  elif [ "$logLevel" == "debug" ]; then
    logFile=$debug_file
  else
    logFile=$error_file
  fi

  if [ "$logLevel" != "oerror" ]; then
    if [ $SHOW_LOG -eq 1 ] || [ "$logLevel" == "debug" ]; then echo "[${logTime}] ${logLevel}: ${message} (${FUNCNAME[2]};${lineNo})"; fi
  fi

  printf "[${logTime}] ${logLevel}: ${message} (${FUNCNAME[2]};${lineNo})\n" >>"${logFile}" 2>&1
  [ $? -ne 0 ] && return 1
  return 0

}
log_info() {
  local message="$1"
  local lineNo="$2"
  log "info" "$1" "$2"
}
log_debug() {
  local message="$1"
  local lineNo="$2"
  if [ $DEBUG -eq 1 ]; then
    log "debug" "$1" "$2"
  fi
  :
}
log_error() {
  local message="$1"
  local lineNo="$2"
  log "error" "$1" "$2"
}

#仅记录到文件，不管SHOW_LOG是否为1
log_error_o() {
  local message="$1"
  local lineNo="$2"
  log "oerror" "$1" "$2"
}
######-------日志结束---------#########

##强制kill此脚本进程 用于终止脚本
exitsh() {
  kill -9 $(cat $ScriptPidPath) >/dev/null 2>&1
}

## 判断上个函数执行的cmd是否成功，不成功则停止脚本
## flag: 传递 $? . msg :传递 打印日志的信息
checkNeedExist() {
  local flag="$1"
  local msg="$2"
  if [ $flag -ne 0 ]; then
    log_error "check flag not ok, need exit shell.[$msg]"
    exitsh
  fi
}
#check_local_tool(){
#	local toolName=$1
#	which $toolName > /dev/null 2>&1 ;echo $?
#}

### 检查某个机器是否有 某个tool
check_tool_exist() {
  local toolName=$1   #检查的工具名称
  local remoteIp=$2   #被检查的节点域名或者ip
  local allTools="$3" #传入所需软件包，可以不传递
  local sshpwd=${SSHPASS}
  ret=$(sshpass -p${sshpwd} ssh -p $SSHPORT ${SSH_OPTION} $remoteIp "which $toolName > /dev/null 2>&1 ;echo \$?|tail -1" 2>/dev/null)
  if [ $ret -ne 0 ]; then
    log_error "check_remote_tool fail.请确保每个测试主机所需软件包${allTools}安装成功！| toolName=$toolName remoteIp=$remoteIp sshpwd=$SSHPASS"
    exitsh
  fi
  return 0
}

get_k8s_node() {
  if [ "x$NAMESPACE" == "x" ]; then
    allNodeArr=$(kubectl get pod -A -owide | egrep -vw "$SKIP_NAMESPACE" | grep Running | awk '{print $8}' | grep -wv NODE | sort | uniq | xargs)
  else
    allNodeArr=$(kubectl get pod -A -owide| egrep -w "$NAMESPACE"| grep Running | awk '{print $8}' | grep -wv NODE | sort | uniq | xargs)
  fi
  allNodes="${allNodeArr[*]}"
  echo "$allNodes"
}

get_node_pods() {
  local nodeName="$1"
  if [ "x$NAMESPACE" == "x" ]; then
    nodePodArr=$(kubectl get pod -A -owide | egrep -vw "$SKIP_NAMESPACE" | grep ${nodeName} | grep Running | awk '{print $2}' | xargs)
  else
    nodePodArr=$(kubectl get pod -A -owide |egrep -w "$NAMESPACE" | grep ${nodeName} | grep Running | awk '{print $2}' | xargs)
  fi
  nodePods="${nodePodArr[*]}"
  echo "$nodePods"

}

get_containerid() {
  local nodeName="$1"
  local podName="$2"
  local sshpwd=$SSHPASS
  contId="$(sshpass -p${sshpwd} ssh -p $SSHPORT ${SSH_OPTION} ${nodeName} "/usr/bin/docker ps |grep ${podName}|grep -v POD_${podName}" 2>/dev/null | awk '{print $1}' | head -1)"
  if [ "x$contId" == "x" ]; then log_error "Cannot get containerId by pod [$podName] on node [$nodeName]" "$LINENO"; fi
  echo "$contId"
}

get_containerpid() {
  local nodeName="$1"
  local contId="$2"
  local sshpwd=$SSHPASS
  gpid=$(sshpass -p${sshpwd} ssh -p $SSHPORT ${SSH_OPTION} ${nodeName} "docker inspect ${contId}|grep -w Pid" 2>/dev/null | awk '{print $2}' | awk -F ',' '{print $1}' 2>/dev/null)
  if [ "x$gpid" == "x" ]; then log_error "Cannot get containerPid by containerid [$contId] on node [$nodeName]" "$LINENO"; fi
  echo "$gpid"
}

## 判断svc 是否有ep存在
#Return  [0|有ep, 1|没有ep]
check_svc_filter_noep() {
  local svcIp="$1"
  if [ "x$NAMESPACE" == "x" ]; then
    svcName="$(kubectl get svc -A | egrep -vw "$SKIP_NAMESPACE" | grep -w ${svcIp} | awk '{print $2,"-n",$1}')" #获取 svcName skipNs
  else
    svcName="$(kubectl get svc -A |egrep -w "$NAMESPACE"| grep -w ${svcIp} | awk '{print $2,"-n",$1}')" #获取 svcName 过滤指定 svcNamespace
  fi

  ret="$(kubectl describe svc $svcName | grep Endpoints | awk '{print $2}' | grep \<none\> 2>${error_file})"
  if [ $? -eq 0 ]; then
    log_debug "--svc no ep=none , svcIp:$svcIp  svcName=$svcName ep=$ret " "$LINENO"
    return 1
  fi
  return 0
}

## 获取svc所有ip,(如果 NOEP=1,则会过滤没有ep的svc)
get_svc_allip() {
  if [ "x$NAMESPACE" == "x" ]; then
    allip=$(kubectl get svc -A | egrep -vw "$SKIP_NAMESPACE" | grep -wvE "None|CLUSTER-IP" | awk '{print $4}' 2>$error_file)
  else
    allip=$(kubectl get svc -A |egrep -w "$NAMESPACE"| grep -wvE "None|CLUSTER-IP" | awk '{print $4}' 2>$error_file)
  fi
  if [ $SKIP_NO_EP -ne 0 ]; then
    allip_noep=""
    for i in $allip; do
      check_svc_filter_noep "$i" >$debug_file 2>&1
      [ $? -eq 0 ] && allip_noep="${allip_noep} $i"
    done
    echo "$allip_noep"
  else
    echo "$allip"
  fi
}

get_ports_by_svcip() {
  local svcip="$1"
  if [ "x$NAMESPACE" == "x" ]; then
    svcPort=$(kubectl get svc -A | egrep -vw "$SKIP_NAMESPACE" | grep -wvE "None|CLUSTER-IP" | grep -w ${svcip} | awk '{print $6}' 2>$error_file)
  else
    svcPort=$(kubectl get svc -A |egrep -w "$NAMESPACE"| grep -wvE "None|CLUSTER-IP" | grep -w ${svcip} | awk '{print $6}' 2>$error_file)
  fi
  svcPortsArr="$(echo $svcPort | awk -F ',' '{print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10}')"
  svcPorts=${svcPortsArr[*]}
  echo "${svcPorts}"
}
#每个节点 nc svc 如果都不通，则返回1， 只要有能通的则返回0
local_check_svc() {
  svcip="$1"
  normalPort="$2"
  p_type="$3"
  local sshpwd=$SSHPASS
  for nIp in $(cat $allNodeFilePath); do
    if [ "$p_type" == "UDP" ]; then
      ret=$(sshpass -p$sshpwd ssh -p $SSHPORT ${SSH_OPTION} $nIp "nc -u -w $NC_WAIT_TIME  -z $svcip $normalPort;echo \$?" 2>/dev/null)
      if [ $ret -eq 0 ]; then return 0; fi
    else
      ret=$(sshpass -p$sshpwd ssh -p $SSHPORT ${SSH_OPTION} $nIp "nc -w $NC_WAIT_TIME  -z $svcip $normalPort;echo \$?" 2>/dev/null)
      if [ $ret -eq 0 ]; then return 0; fi
    fi
  done
  log_info "SKIP,all node nc test fail .NOT TEST  $svcip $normalPort $p_type "
  return 1
}

save_svc_ip_and_ports() {
  #svcTcpFile=/tmp/.p2s.svcTcp.file		#临时文件路径，开头已经定义
  #svcUdpFile=/tmp/.p2s.svcUcp.file
  local svcip="$1"
  svcPortType="$(get_ports_by_svcip $svcip)"
  for portType in $svcPortType; do
    normalPort=$(echo $portType | awk -F '/' '{print $1}' | awk -F ':' '{print $1}')
    nodePort=$(echo $portType | awk -F '/' '{print $1}' | awk -F ':' '{print $2}')
    ptype=$(echo $portType | awk -F '/' '{print $2}')
    if [ "$ptype" == "TCP" ]; then
      flag=1 #是否记录svc标识，1记录
      if [ $LOCAL_CHECK_SVC -ne 0 ]; then
        local_check_svc $svcip $normalPort $ptype >/dev/null 2>&1
        #		nc -w $NC_WAIT_TIME  -z $svcip $normalPort >/dev/null 2>&1
        [ $? -ne 0 ] && flag=0 && log_error "LOCAL_CHECK_SVC=$LOCAL_CHECK_SVC , NC tcp Test not ok , Skip $svcip $normalPort ,will not test this svc " && log_info "LOCAL_CHECK_SVC=$LOCAL_CHECK_SVC , NC tcp Test not ok , Skip $svcip $normalPort ,will not test this svc"
      fi

      if [ $flag -eq 1 ]; then
        echo "$svcip" "$normalPort" >>${svcTcpFile}
        if [ "x${nodePort}" != "x" ]; then
          echo "$nodePort" >>${svcNodeTcpFile}
        fi
      fi

    elif [ "$ptype" == "UDP" ]; then
      flag=1 #是否记录svc标识，1记录
      if [ $LOCAL_CHECK_SVC -ne 0 ]; then
        nc -u -w $NC_WAIT_TIME -z $svcip $normalPort >/dev/null 2>&1
        [ $? -ne 0 ] && flag=0 && log_info "LOCAL_CHECK_SVC=$LOCAL_CHECK_SVC , NC udp Test not ok , Skip $svcip $normalPort ,will not test this svc " && log_error "LOCAL_CHECK_SVC=$LOCAL_CHECK_SVC , NC tcp Test not ok , Skip $svcip $normalPort ,will not test this svc "
      fi
      if [ $flag -eq 1 ]; then
        echo "$svcip" "$normalPort" >>${svcUdpFile}
        if [ "x${nodePort}" != "x" ]; then
          echo "$nodePort" >>${svcNodeUdpFile}
        fi
      fi
    else
      log_error "save ptype error. svcIp:$svcip , svcPortType: $svcPortType " "$LINENO"
    fi
  done

}

#tcp nc test
# ssh到nodeName节点，再contPid network namespace里执行 nc ip port 测试
# echo:  0:测试通过， 1:测试不通过
TcpTestInNs() {
  local nodeName="$1"
  local contPid="$2"
  local testIp="$3"
  local testPort="$4"
  local sshpwd="$SSHPASS"

  let PASS_RETRY+=1
  for i in $(seq 1 $PASS_RETRY); do
    result=$(sshpass -p$sshpwd ssh -p $SSHPORT ${SSH_OPTION} $nodeName "echo nc -w $NC_WAIT_TIME -z $testIp $testPort|nsenter -n -t $contPid ; echo \$? " 2>/dev/null)
    if [ $result -eq 0 ]; then
      continue
    else
      if [ $i -gt 1 ]; then
        log_error_o "[PASS_RETRY=$i] error [TcpTestInNs cmd : sshpass -p$sshpwd ssh -p $SSHPORT ${SSH_OPTION} $nodeName echo nc -w $NC_WAIT_TIME -z $testIp $testPort|nsenter -n -t $contPid ; echo \$? ]" "$LINENO"
      fi
      break
    fi
  done
  echo $result
}

UdpTestInNs() {
  local nodeName="$1"
  local contPid="$2"
  local testIp="$3"
  local testPort="$4"
  local sshpwd="$SSHPASS"

  #let PASS_RETRY+=1
  PASS_RETRY=2 #udp 固定为1+1
  for i in $(seq 1 $PASS_RETRY); do
    result=$(sshpass -p$sshpwd ssh -p $SSHPORT ${SSH_OPTION} $nodeName "echo nc -u -w $NC_WAIT_TIME -z ${testIp} $testPort|nsenter -n -t $contPid ; echo \$? " 2>/dev/null)
    if [ $result -eq 0 ]; then
      continue
    else
      if [ $i -gt 1 ]; then
        log_error_o "[PASS_RETRY=$i] error [UdpTestInNs cmd : sshpass -p$sshpwd ssh -p $SSHPORT ${SSH_OPTION} $nodeName echo nc -u -w $NC_WAIT_TIME -z $testIp $testPort|nsenter -n -t $contPid ; echo \$? ]" "$LINENO"
      fi
      #			[ "x$result" != "x" ] && log_error_o "$result"
      break
    fi
  done
  echo $result
}

save_node_podpid() {
  declare -a npName=()
  arr_n=0
  arr_np=0
  log_info "start save_node_podpid ... "
  truncate --size 0 $LOG_FILE_FULL_PATH/.p2s.aiopodsinfo
  ##save all pod info
  ##	kubectl get pod -A -owide > /tmp/.allpodinfo
  ###
  for nIp in $(cat $allNodeFilePath); do
    truncate --size 0 $LOG_FILE_FULL_PATH/.p2s.${nIp}.pods $LOG_FILE_FULL_PATH/.p2s.${nIp}.cId $LOG_FILE_FULL_PATH/.p2s.${nIp}.cPid
    get_node_pods "$nIp" >$LOG_FILE_FULL_PATH/.p2s.${nIp}.pods
    for pName in $(cat $LOG_FILE_FULL_PATH/.p2s.${nIp}.pods); do
      get_containerid "$nIp" "$pName" >>$LOG_FILE_FULL_PATH/.p2s.${nIp}.cId
      npName[$arr_n]=$pName
      let arr_n+=1
    done
    for cId in $(cat $LOG_FILE_FULL_PATH/.p2s.${nIp}.cId); do
      cPid=$(get_containerpid "$nIp" "$cId")
      echo "$cPid" >>$LOG_FILE_FULL_PATH/.p2s.${nIp}.cPid
      ###
      #	for pName in `cat $LOG_FILE_FULL_PATH/.p2s.${nIp}.pods` ;do
      echo "[$nIp]:" "${npName[$arr_np]}" "$cId" "$cPid" >>$LOG_FILE_FULL_PATH/.p2s.aiopodsinfo
      log_debug "[$nIp]: ${npName[$arr_np]} $cId  $cPid"
      let arr_np+=1
      #   done
      ###
    done

  done
  log_info "save pod pid to file ok ..."
}

save_svc_info() {
  log_info "start save_svc_info ..."
  truncate --size 0 $svcTcpFile $svcUdpFile $svcNodeTcpFile $svcNodeUdpFile || $(
    echo "truncate svcTcp Udp file faile ,need exit"
    exitsh
  )
  echo $(get_svc_allip) >$allSvcFilePath
  for svcIp in $(cat $allSvcFilePath); do
    save_svc_ip_and_ports "$svcIp"
  done
  test -f $svcTcpFile && test -f $svcUdpFile && log_info "save svc ip port to file ok ..."
}

check_ssh_scp() {
  local remoteIp="$1"
  local sshpwd="$SSHPASS"

  #check ssh common to other nodes
  ssh_ret=$(sshpass -p${sshpwd} ssh -p $SSHPORT ${SSH_OPTION} $remoteIp "whoami" 2>/dev/null)
  if [ $? -ne 0 ]; then
    log_error "ssh to other nodes check fail.  remoteIp=$remoteIp sshpwd=$SSHPASS return:$ssh_ret"
    exitsh
  fi
  scp_ret=$(
    touch /tmp/.tmp123
    sshpass -p${sshpwd} scp -P $SSHPORT ${SSH_OPTION} /tmp/.tmp123 ${remoteIp}:/tmp/ 2>/dev/null
  )
  if [ $? -ne 0 ]; then
    log_error "scp to other nodes check fail . remoteIp=$remoteIp sshpwd=$SSHPASS return:$ssh_ret"
    exitsh
  fi
  return 0
}
init_and_check() {
  log_info "start init_and_check ..."
  localNeedTools="sshpass"
  allNeedTools="nc nsenter"
  ##创建本机日志目录,打包旧日志记录
  mkdir -p $LOG_FILE_FULL_PATH || $(
    echo "failed init log path,exit"
    exitsh
  )
  if [ -f "$log_file" -o -f "$error_file" -o -f "$debug_file" ]; then
    tlog=$(tar zcf ${LOG_FILE_FULL_PATH}/log.$(date +'%Y-%m-%d_%H-%M-%S').tgz ${LOG_FILE_FULL_PATH}/*.log 2>&1)
    [ $? -ne 0 ] && echo "tar zcf log file failed [$tlog]"
    log_debug "tar zcf log.tgz  ${LOG_FILE_FULL_PATH}/*.log"
  fi
  truncate --size 0 "$log_file" "$error_file" "$debug_file"

  ##检查本机需要的特有的基本工具
  for i in $localNeedTools; do
    ret=$(which sshpass >/dev/null)
    checkNeedExist $? "Current node no tool sshpass . $ret [$LINENO]"
  done

  echo $(get_k8s_node) >$allNodeFilePath #获取所有node节点
  ##检查本机到别的机器，ssh,scp 命令可行性
  for nIp in $(cat $allNodeFilePath); do
    check_ssh_scp $nIp
  done

  #检查机器所需的工具，没有则退出脚本
  for tname in $allNeedTools; do
    for nIp in $(cat $allNodeFilePath); do
      check_tool_exist "$tname" "$nIp" "$allNeedTools"
      checkNeedExist $? "${nIp} no tool $tname [$LINENO]"
    done
  done
  #检查mul 脚本
  if [ $MUL_RUN -eq 1 ]; then
    if [ ! -f $fpath/$MUL_SCRIPT_NAME ]; then
      log_error "Run with multi , but test$fpath/$MUL_SCRIPT_NAME not found  , exit."
      exitsh
    fi
  fi
  log_info "init_and check ok... "
}
#multi测试时候需要用到，分发文件到别的节点
scp_files_to_other() {
  local sshpwd=$SSHPASS
  log_info "scp container pid, svctcp ,svcudp file to others ."
  for nIp in $(cat $allNodeFilePath); do
    log_info "scp to $nIp"
    ret1=$(sshpass -p${sshpwd} scp -P $SSHPORT ${SSH_OPTION} $LOG_FILE_FULL_PATH/.p2s.${nIp}.cPid ${nIp}:/tmp/.p2s.cPid 2>/dev/null)
    ret2=$(sshpass -p${sshpwd} scp -P $SSHPORT ${SSH_OPTION} $LOG_FILE_FULL_PATH/.p2s.svcTcp.file ${nIp}:/tmp/.p2s.svcTcp.file 2>/dev/null)
    ret3=$(sshpass -p${sshpwd} scp -P $SSHPORT ${SSH_OPTION} $LOG_FILE_FULL_PATH/.p2s.svcUdp.file ${nIp}:/tmp/.p2s.svcUdp.file 2>/dev/null)
    ret4=$(sshpass -p${sshpwd} scp -P $SSHPORT ${SSH_OPTION} $fpath/$MUL_SCRIPT_NAME ${nIp}:/tmp/$MUL_SCRIPT_NAME 2>/dev/null)
    ret5=$(sshpass -p${sshpwd} scp -P $SSHPORT ${SSH_OPTION} $LOG_FILE_FULL_PATH/.p2s.aiopodsinfo ${nIp}:/tmp/.p2s.aiopodsinfo 2>/dev/null)
  done
  [ $? -ne 0 ] && $(
    echo "scp error ,exit "
    exitsh
  )
  log_info "scp finished"
}
#multi测试用到，检查运行线程个数
check_thread() {
  local nodeIp="$1"
  local threadName="$2"
  local sshpwd=$SSHPASS
  threadnum=$(sshpass -p${sshpwd} ssh -p $SSHPORT ${SSH_OPTION} $nodeIp "ps -ef | grep $threadName | grep -v grep |grep -v Es | wc -l" 2>/dev/null)
  return $threadnum
}
#检查线程是否执行，直到线程不存在
check_clts_threads() {
  local threadName="$1"
  for ip in $(cat $allNodeFilePath); do
    while [ true ]; do
      check_thread $ip $threadName
      if [ $? != 0 ]; then
        sleep 50
        log_info "check [$threadName] on node [$ip] not finished,next turn "
      else
        log_info "check [$threadName] on node [$ip] finished "
        break
      fi
    done
  done
  log_info "check [$threadName] on all node finished "
}
#mul测试用到，当ctrl+c停止当前脚本后，需要 手动kill其他节点的
multnode_kill_task() {
  #	isexit=$1		# 1退出， 0 不退出
  local sshpwd=$SSHPASS
  for nIp in $(cat $allNodeFilePath); do
    log_info "$nIp kill task /tmp/$MUL_SCRIPT_NAME "
    ret=$(sshpass -p${sshpwd} ssh -p $SSHPORT ${SSH_OPTION} $nIp "pgrep -lf $MUL_SCRIPT_NAME|awk '{print \$1}'|xargs kill -9  >/dev/null 2>&1 && pgrep -lf $MUL_SCRIPT_NAME|awk '{print \$1}'|xargs kill -9  >/dev/null 2>&1") >/dev/null 2>&1
  done
  #	if [ "x$isexit" == "x" ];then
  #		exitsh
  #	else
  #		:
  #	fi
}
multnode_exec_check() {
  local sshpwd=$SSHPASS
  multnode_kill_task
  scp_files_to_other
  #每个机器并发执行 各自nc脚本
  for nIp in $(cat $allNodeFilePath); do
    log_info "$nIp exec /tmp/$MUL_SCRIPT_NAME "
    sret1=$(sshpass -p${sshpwd} ssh -p $SSHPORT ${SSH_OPTION} $nIp "sh /tmp/$MUL_SCRIPT_NAME $PASS_RETRY $NC_WAIT_TIME " 2>/dev/null) &
  done

  #检查每个机器是否把脚本都执行完成
  check_clts_threads "$MUL_SCRIPT_NAME"

  #把日志发到本机目录下
  for nIp in $(cat $allNodeFilePath); do
    logret_i=$(sshpass -p${sshpwd} scp -P $SSHPORT ${SSH_OPTION} $nIp:/tmp/.p2s.info.log /tmp/.p2s.info.log.$nIp 2>/dev/null)
    logret_e=$(sshpass -p${sshpwd} scp -P $SSHPORT ${SSH_OPTION} $nIp:/tmp/.p2s.error.log /tmp/.p2s.error.log.$nIp 2>/dev/null)
    cat /tmp/.p2s.info.log.$nIp >>$log_file
    cat /tmp/.p2s.error.log.$nIp >>$error_file
  done
}

#TcpTestInNs
#    local nodeName="$1"
#    local contPid="$2"
#    local testIp="$3"
#    local testPort="$4"
get_podinfo_bycPid_onNode() {
  local cPid="$1"   #container pid
  local nodeIp="$2" #hostname
  #	podInfo=$(cat $LOG_FILE_FULL_PATH/.p2s.aiopodsinfo|grep -w "$nodeIp" |grep -w  $cPid|awk '{for(i=2;i<=NF;++i) printf $i " "}')		#排除第一列
  podInfo=$(cat $LOG_FILE_FULL_PATH/.p2s.aiopodsinfo | grep -w "$nodeIp" | grep -w $cPid)
  echo "$podInfo"
}
#get_podinfo_bycPid_onNode "20121" "master50.example.com" ;exit 2

common_svctest() {
  local testType="$1" ## TCP ,UDP , TcpNode ,UdpNode
  local nIp="$2"
  local svcIp="$3"
  local svcPort="$4"
  local sshpwd=$SSHPASS

  #	for nIp in `cat $allNodeFilePath`;do
  log_debug "-- nodeip:$nIp , ---- " "$LINENO"
  for cPid in $(cat $LOG_FILE_FULL_PATH/.p2s.${nIp}.cPid); do
    #如果Pid不存在，进程不存在则不进行测试了
    pid_e=$(sshpass -p$sshpwd ssh -p $SSHPORT ${SSH_OPTION} $nIp "ps -ef|grep -w $cPid|grep -v grep|wc -l" 2>/dev/null)
    if [ $pid_e -eq 0 ]; then
      log_info "Container not fount , NOT TEST. $nIp , $cPid ,$svcIp ,$svcPort"
      return 1
    fi

    if [ "$testType" == "TCP" -o "$testType" == "tcp" ]; then
      check_result=$(TcpTestInNs "$nIp" "$cPid" "$svcIp" "$svcPort")
    elif [ "$testType" == "UDP" -o "$testType" == "udp" ]; then
      check_result=$(UdpTestInNs "$nIp" "$cPid" "$svcIp" "$svcPort")
    else
      log_error "testType Not support now,exit"
      exitsh
    fi

    log_debug "check_result:$check_result .cmd: ${testType}TestInNs nodeIp:$nIp containerPid:$cPid svcIp:$svcIp svcPort:$svcPort" "$LINENO"

    if [ "x$check_result" == "x" ]; then
      g_log="$(get_podinfo_bycPid_onNode $cPid $nIp)"
      log_error "[NULL] --- ${testType}TestInNs $g_log  $svcIp $svcPort"
    elif [ $check_result -eq 1 ]; then
      g_log="$(get_podinfo_bycPid_onNode $cPid $nIp)"
      log_error "[$check_result] --- ${testType}TestInNs  $g_log $svcIp $svcPort "
    elif [ $check_result -eq 0 ]; then
      g_log="$(get_podinfo_bycPid_onNode $cPid $nIp)"
      log_info "[$check_result] --- ${testType}TestInNs  $g_log $svcIp $svcPort"
    else
      g_log="$(get_podinfo_bycPid_onNode $cPid $nIp)"
      log_error "[-1] --- ${testType}TestInNs  $g_log $svcIp $svcPort"
    fi
  done
  return 0
  #   done
}
check_pod2svc() {
  log_info "start check_pod2svc ..."
  # svcTcp ip+port
  local sshpwd=$SSHPASS
  OLD_IFS=$IFS #保存当前分隔符
  IFS=$'\n'    #一行为一个 条目（换行符）
  for i in $(cat $svcTcpFile); do
    IFS=$'\n' #一行为一个 条目（换行符）
    svcIp=$(echo $i | awk '{print $1}')
    svcPort=$(echo $i | awk '{print $2}')
    IFS=$OLD_IFS
    log_info "---Test svc tcp ip:[$svcIp] , port:[$svcPort]---"
    protocol=tcp
    for nIp in $(cat $allNodeFilePath); do
      log_debug "-- nodeip:$nIp , ---- " "$LINENO"
      ##判断节点是否通信不通，则直接记录失败
      nret=$(sshpass -p$sshpwd ssh -p $SSHPORT ${SSH_OPTION} $nIp "nc -w 2 -z $svcIp $svcPort ;echo \$?" 2>/dev/null)
      if [ $nret -eq 1 ]; then
        log_error "NODE CHECK FAIL!!! SKIP. $nIp tcp $svcIp $svcPort"
        continue
      fi
      common_svctest "TCP" "$nIp" "$svcIp" "$svcPort"
    done
  done

  #svcUdp ip+port
  OLD_IFS=$IFS #保存当前分隔符
  IFS=$'\n'    #一行为一个 条目（换行符）
  for i in $(cat $svcUdpFile); do
    IFS=$'\n' #一行为一个 条目（换行符）
    svcIp=$(echo $i | awk '{print $1}')
    svcPort=$(echo $i | awk '{print $2}')
    IFS=$OLD_IFS
    log_info "---Test svc udp ip:[$svcIp] , port:[$svcPort]---"
    protocol=udp
    for nIp in $(cat $allNodeFilePath); do
      log_debug "-- nodeip:$nIp , ---- " "$LINENO"
      ##判断节点是否通信不通，则直接记录失败
      nret=$(sshpass -p$sshpwd ssh -p $SSHPORT ${SSH_OPTION} $nIp "nc -u -w 2 -z $svcIp $svcPort ;echo \$?" 2>/dev/null)
      if [ $nret -eq 1 ]; then
        log_error "NODE CHECK FAIL!!! SKIP. $nIp udp  $svcIp $svcPort"
        continue
      fi

      common_svctest "UDP" "$nIp" "$svcIp" "$svcPort"
    done
  done
  log_info " --- check_pod2svc finished ~ "
}
#日志过滤，去掉因为网络策略 产生的错误
log_check() {
  logfile="$1"
  log_check_type="$2" #检查error的日志，检查info的日志
  kubectl get pod -A -owide >/tmp/.allpodinfo
  [ $? -ne 0 ] && log_error "kubectl get pod -A  -owide Error ,exit" && exitsh
  FABRIC_ADMIN="/opt/cni/bin/fabric-admin"
  log_info "[$logfile $log_check_type]  traffic , by tenant check:"
  OLD_IFS=$IFS #保存当前分隔符
  IFS=$'\n'    #一行为一个 条目（换行符）
  for i in $(cat $logfile); do
    IFS=$'\n' #一行为一个 条目（换行符）
    if [[ "$i" =~ " TCPTestInNs " ]]; then
      protocol="tcp"
    elif [[ "$i" =~ " UDPTestInNs " ]]; then
      protocol="udp"
    else
      protocol="NULL"
      #		if [[ "$log_check_type" == "info" ]];then
      #			echo 1 > /dev/null
      #		else
      echo "$i" >>$error_file_end
      #		fi
      continue
    fi
    srcPod=$(echo $i | awk '{print $7}')
    srcIp="$(cat /tmp/.allpodinfo | grep $srcPod | awk '{print $7}')"
    dstIp=$(echo $i | awk '{print $10}')
    dstPort=$(echo $i | awk '{print $11}')
    IFS=$OLD_IFS
    if [ "x$srcIp" == "x" ]; then
      log_info "skip srcPod $srcPod check srcIP get:[$srcIp]"
      continue
    fi
    if [ "$log_check_type" == "info" ]; then
      check_np="$($FABRIC_ADMIN trace np --src $srcIp --dst $dstIp --dst-port $dstPort --protocol $protocol | grep -w PERMITTED 2>&1)"
    else
      check_np="$($FABRIC_ADMIN trace np --src $srcIp --dst $dstIp --dst-port $dstPort --protocol $protocol | grep -w REJECTED 2>&1)"
    fi
    if [ "x$check_np" == "x" ]; then
      echo "$i" >>$error_file_end
    fi
    if [ "$log_check_type" == "error" ]; then
      if [ "x$check_np" != "x" ]; then
        echo "[$i]" "DENIED" >>$error_file_deny
      fi
    fi
  done
  log_info "[$logfile $log_check_type]  traffic , by tenant check ok , see log: $error_file_end"

}
save() {
  init_and_check   #初始化环境
  save_node_podpid #保存node和pod,podPid
  save_svc_info    #保存svc 信息

}
check() {
  if [ $MUL_RUN -eq 0 ]; then #执行nc check MUL_RUN=0，当前机器循环执行测试，时间长单请求
    check_pod2svc
  else
    multnode_exec_check # MUL_RUN !=0 ，每个node ,根据自己机器的pod 进行 nc check测试
  fi

  truncate --size 0 $error_file_end $error_file_deny
  log_check "$error_file" "error"
  #    log_check "$log_file" "info"
}
usage() {
  echo """    请输入参数:
	$0 a : 直接跑所有测试 (包含 s,c)
	$0 s : 初始化环境并保存要测试的相关信息. 调试修改用
	$0 c : 进行check pod to svc 测试.根据save出的结果进行check
"""
}
#################---MAIN---##################
#[ $# -ne 1 ] && usage  && exit

if [ "$1" == "k" ]; then
  multnode_kill_task
  exit 0
fi

save
check

############################################
