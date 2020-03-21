lgfs="/opt/loongoop-1.0.0/bin/hadoop fs"
begin=1
end=2
checkrwx()
{
  S_RWX="$1"
  tmprwx="-rw-r--r--"
if [ "$S_RWX" != "$tmprwx" ];then
   echo "$1 check tmprwx  failed " | tee >> error.log
   return 1
fi
}

checkusero()
{
  S_U="$1"
  tmpU="$2"
if [ "$S_U" != "$tmpU" ];then
   echo "$2 check user  failed " | tee >> error.log
   return 1
fi
}

checkgroupo()
{
  S_G="$1"
  tmpG="$2"
if [ "$S_G" != "$tmpG" ];then
   echo "$2 check group  failed " | tee >> error.log
   return 1
fi
}
for i in $(seq $begin $end)
do
allinfo=`$lgfs -ls /r1/file$i`
rwx=`echo $allinfo|awk '{print $1}'`
usero=`echo $allinfo|awk '{print $3}'`
groupo=`echo $allinfo|awk '{print $4}'`

checkrwx $rwx
if [ $? -eq 0 ];then 
	checkusero $usero $i
	if [ $? -eq 0 ];then 
		checkgroupo $groupo $i
		if [ $? -ne 0 ];then echo "[`date`] [Uid:$i] checkgroup failed [allinfo:$allinfo]"|tee -a failed.log ;fi
	else 
		echo "[`date`] [Uid:$i] checkuser failed [allinfo:$allinfo]" | tee -a  failed.log 
	fi
else
	echo [`date`] [Uid:$i] checkrwx failed ,[allinfo:$allinfo]|tee -a failed.log
fi
done
