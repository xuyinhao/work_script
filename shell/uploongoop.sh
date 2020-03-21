#!/bin/sh

##########################
## 说明：
##  测试使用工具。
##  升级更新loongoop时使用
#########################
declare OLD_LGP_HOME_PATH="/loongoop/loongoop-1.0.4-v2.7.2"
declare	NEW_LGP_HOME_PATH="/loongoop/loongoop-1.0.5-v2.7.2"
declare CONF_CP_NAME=(core-site.xml mapred-site.xml yarn-site.xml \
				leofs-site.xml hdfs-site.xml hadoop-env.sh slaves) 
log()
{
	logTime=$(date +'%Y-%m-%d_%T')
	echo "$logTime : $@"|/usr/bin/tee -a /tmp/loongoop_update.log 2>&1
	return 0
}
check_path_exist()
{
	local V_PATH="$1"
	if [ ! -d $V_PATH ];then
		log "ERROR This path [$V_PATH] is not exist! Pls check it!"
		exit 1
	fi
}
check_file_exist()
{
    local V_PATH="$1"
    if [ ! -f $V_PATH ];then
        log "ERROR" "This file [$V_PATH] is not exist! Pls check it!"
        exit 1
    fi
}

cp_conf()
{
	OLD_CONF="$1"
	NEW_CONF="$2"
	check_file_exist $OLD_CONF
#	check_file_exist $NEW_CONF
	cp -a $OLD_CONF $NEW_CONF
}

function updata_lgp {
	check_path_exist "$OLD_LGP_HONE_PATH"
	check_path_exist "$NEW_LGP_HOME_PATH"
	for i in $(seq 0 $((${#CONF_CP_NAME[@]}-1)))
	do
		cp_conf "${OLD_LGP_HOME_PATH}/etc/hadoop/${CONF_CP_NAME[${i}]}" "${NEW_LGP_HOME_PATH}/etc/hadoop/" 
		[ $? -ne 0 ] && log "ERROR:" "cp [${CONF_CP_NAME[${i}]}] conf failed. $LINENO " && exit 1
		log "INFO:" "cp [${CONF_CP_NAME[${i}]}]  conf ok"
	done
}
updata_lgp
#date
#echo  ${#CONF_CP_NAME[@]}
