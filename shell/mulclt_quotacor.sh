dir=/datapool/quota_mfilecor
clients=(mds1 mds2 istore03)
sizetype="small"  	#small: 1M1111_1  1G4k_1 1G1m_1 , 
			#big: 2M1111_10    1G4k_10, 1G1m_10  
			#vbig: 4M1111_100  10G4k_40  20G4m_40  

quotacmd=/LeoCluster/bin/leofs_quotacmd
quotaclt=/LeoCluster/bin/leofs_quotaclt

#clients=(${clients})
clientsnum=${#clients[@]}
function sizetypeset(){
if [ $sizetype == "small" ];then
echo small type
size1="1M 1111 1"
size2="1G 4k 1"
size3="1G 1m 1"
checkb="$((1024+1024*1024*2)) 3"
setb="$((1024+1024*1024*2*2))k 6"

smallarg="d 10 f 10 111 111 30 2"
checks="119 1210"

elif [ $sizetype == "big" ];then
echo big type
size1="2M 1111 10"
size2="1G 4k 10"
size3="1G 1m 10"
checkb="$((1024*2*10+1024*1024*20)) 30"
setb="$((1024*2*10*2+1024*1024*20))k 60"
smallarg="d 10 f 10 1111 1111 40 3"
checks="12043 12210"

elif [ $sizetype == "vbig" ];then
echo very big type
size1="4M 111111 100"
size2="10G 4k 40"
size3="20G 4m 40"
checkb="$((4096*100+1024*1024*10*40+1024*1024*20*40)) 180"
setb="$((4096*100*2+1024*1024*10*40+1024*1024*20*40))k 200"
smallarg="d 10 f 100 111 111 40 3"
checks="12032 122100"

else
	echo "请确认 sizetype 类型大小--"
	exit 0
fi

}
sizetypeset

function bigfile() {
mkdir $dir/quotabfile -p
$quotacmd -d $dir/quotabfile $setb;
flag=$?;sleep 4;if [ $flag -ne 0 ] && [ $flag -ne 255 ];then exit;fi
cltret=`$quotaclt -s $dir/quotabfile|grep " Dir "|awk '{print $7,$9}'`
if [ "$cltret" != "0 0" ];then echo "$dir/quotabfile  not empty"|tee log.step;exit 0;fi
sleep 4;

echo "bigfile write quotabfile "|tee log.step
#Usage:filename optype(1:write, 2:read) filesize(K,M,G,T) blocksize(K,M) thread_num bskip eskip [prefix]
for i in 
python filewr.py  $dir/quotabfile/ff1_$sizetype 1 $size1 0 0 0  >> $dir/logb1m1k 2>&1 &
python filewr.py  $dir/quotabfile/ff3_$sizetype 1 $size3 0 0 0   >> $dir/logb1g1m 2>&1 &
python filewr.py  $dir/quotabfile/ff2_$sizetype 1 $size2 0 0 0  >> $dir/logb1g4k 2>&1
wait
echo "time wait ... "|tee log.step
sleep 4
echo "bigfile read quotabfile "|tee log.step

python filewr.py  $dir/quotabfile/ff1_$sizetype 2 $size1 0 0 0   >> $dir/logb1m1k 2>&1 &
python filewr.py  $dir/quotabfile/ff3_$sizetype 2 $size3 0 0 0  >> $dir/logb1g1m 2>&1 &
python filewr.py  $dir/quotabfile/ff2_$sizetype 2 $size2 0 0 0  >> $dir/logb1g4k 2>&1

cltsret=`$quotaclt -s $dir/quotabfile|grep " Dir "|awk '{print $7,$9}'`
if [ "$cltsret" != "$checkb" ];then echo "check $dir/quotabfile fail: $cltsret"|tee log.step;exit 1;fi
echo check b quota info pass|tee log.step
}
bigfile 


function smallfile() {
mkdir $dir/quotasfile -p
$quotacmd -d $dir/quotasfile 1000g 1000000000;
flag=$?;sleep 4;if [ $flag -ne 0 ] && [ $flag -ne 255 ];then exit;fi
cltret=`$quotaclt -s $dir/quotasfile|grep " Dir "|awk '{print $7,$9}'`
if [ "$cltret" != "0 0" ];then echo "$dir/quotasfile  not empty"|tee log.step;exit 0;fi
sleep 4;
echo "smallfile write quotasfile "|tee log.step
java -jar create.jar /datapool/quota_filecor/quotasfile/ $smallarg 0 0 >> $dir/logs_sm 2>&1 
wait
echo "time wait ... "|tee log.step
sleep 4

echo "smallfile read quotasfile "|tee log.step
java -jar check.jar /datapool/quota_filecor/quotasfile/ $smallarg 0 0 >> $dir/logs_sm 2>&1 

cltsret=`$quotaclt -s $dir/quotasfile|grep " Dir "|awk '{print $7,$9}'`
if [ "$cltsret" != "$checks" ];then echo "check $dir/quotasfile fail: $cltsret"|tee log.step;exit 1;fi
echo check s quota info pass|tee log.step
}
smallfile

