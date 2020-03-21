if [ $# -ne 1 ];then
	echo input dir
	exit 1
fi


dir=$1/`hostname`
log=${dir}.log

checklog(){
	grep -i err $log |grep -v check
	if [ $? -eq 0 ];then
		echo something error. exit!
		exit 1
	fi
}



for  i in {1..100}
do
/datapool/filewr.py ${dir}big 1 $((8*1024*1024*1024)) 1048676 20 0 0 $i >> $log
/datapool/filewr.py ${dir}big 2 $((8*1024*1024*1024)) 1048676 20 0 0 $i >> $log
checklog
done
