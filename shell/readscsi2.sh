if [ "$#" != "2" ];then echo "需要输入写入次数 文件名(设备名) ";exit;fi
writecmd=/datapool/test_write_single_char
readcmd=/datapool/test_read_find_hole 
filepath=/datapool/f1
filepath=$2
dlog=/tmp/wscsi.log.`date "+%d%H%M%S"`

holes=$((30*1024))
writes=$((31*1024))
holesn1=$(($holes*${1} + $writes*${1}))
echo totle size : $(($holes*${1} + $writes*${1}))
echo sleep 10s
sleep 1
function write() {

for((i=0;i<${1};i++))
do
#let holesn2=$holesn1+$holes;
let holesn2=$holesn1+$holes;
$writecmd  $filepath  $holesn2 $writes a > /tmp/step 2>&1
#let holesn2=$holesn1+$holes;
echo "Hole Range: $holesn1 -- $(($holesn2-1)), len: $holes"|tee -a ${dlog}.w
let holesn1=$holesn2+$writes
done
echo "last size : $holesn1"
}
function checkok() {

if [ "$1" != "0" ];then
 echo "cmd check  erro";exit;
fi
}
function check() {
echo "check "
holesn1=$(($holes*${1} + $writes*${1}))

for((i=0;i<${1};i++))
do
#let holesn2=$holesn1+$holes;
let holesn2=$holesn1+$holes;
$readcmd  $filepath  $holesn2 $writes a >> ${dlog}.r
#let holesn2=$holesn1+$holes;
#echo "Hole Range: $holesn1 -- $(($holesn2-1)), len: $holes"|tee -a ${dlog}.w
let holesn1=$holesn2+$writes
done
grep -i "Data error" ${dlog}.r
#$readcmd $filepath 0 $holesn1 a  >> ${dlog}.r.b
#grep "Hole Range"  ${dlog}.r.b >> ${dlog}.r
#dret=`diff ${dlog}.r ${dlog}.w`
#checkok $?
#echo "$dret"
}

#write $@
check $@

